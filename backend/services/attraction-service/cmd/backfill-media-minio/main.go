package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"html"
	"io"
	"mime"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	defaultFileManagerHTTPURL = "http://localhost:8083"
	defaultUserAgent          = "FlyFyMediaBackfill/1.0"
	nilUUID                   = "00000000-0000-0000-0000-000000000000"
	maxImageBytes             = 20 * 1024 * 1024
)

type mediaRow struct {
	MediaID      uuid.UUID
	AttractionID uuid.UUID
	AuthorUserID uuid.UUID
	Title        string
	ExternalURL  string
	SourceURL    string
}

type attractionTarget struct {
	AttractionID    uuid.UUID
	AuthorUserID    uuid.UUID
	Title           string
	SearchTitle     string
	MediaCount      int
	NextPosition    int
	ExistingSources map[string]struct{}
}

type commonsCandidate struct {
	Title       string
	DownloadURL string
	SourceURL   string
	Credit      string
	License     string
}

type createUploadResponse struct {
	FileID    string `json:"fileId"`
	ObjectKey string `json:"objectKey"`
	Status    string `json:"status"`
}

func main() {
	var (
		fileManagerURL = flag.String("file-manager-url", envOr("FILE_MANAGER_HTTP_URL", defaultFileManagerHTTPURL), "file-manager HTTP base URL")
		databaseURL    = flag.String("database-url", envOr("ATTRACTION_DATABASE_URL", ""), "attraction-service PostgreSQL URL")
		userAgent      = flag.String("user-agent", envOr("BACKFILL_USER_AGENT", defaultUserAgent), "HTTP User-Agent for source image downloads")
		limit          = flag.Int("limit", envIntOr("BACKFILL_LIMIT", 0), "maximum media rows to process; 0 means all")
		force          = flag.Bool("force", envBoolOr("BACKFILL_FORCE", false), "re-upload rows even when file_id is already set")
		dryRun         = flag.Bool("dry-run", envBoolOr("BACKFILL_DRY_RUN", false), "log planned changes without uploading or updating data")
		minMedia       = flag.Int("commons-min-media-per-attraction", envIntOr("COMMONS_MIN_MEDIA_PER_ATTRACTION", 0), "minimum total media items per attraction after importing verified Wikimedia Commons images; 0 disables discovery")
	)
	flag.Parse()

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Minute)
	defer cancel()

	dsn := strings.TrimSpace(*databaseURL)
	if dsn == "" {
		dsn = attractionDatabaseURLFromEnv()
	}

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		fatalf("connect attraction database: %v", err)
	}
	defer pool.Close()

	rows, err := loadRows(ctx, pool, *force, *limit)
	if err != nil {
		fatalf("load attraction media rows: %v", err)
	}
	client := &http.Client{Timeout: 90 * time.Second}
	migrated := 0
	for _, row := range rows {
		fmt.Printf("Backfilling %s (%s)\n", row.Title, row.MediaID)
		if *dryRun {
			fmt.Printf("  dry-run: would mirror %s\n", row.ExternalURL)
			continue
		}

		fileID, err := mirrorOne(ctx, client, strings.TrimRight(*fileManagerURL, "/"), strings.TrimSpace(*userAgent), row)
		if err != nil {
			fatalf("backfill %s (%s): %v", row.Title, row.MediaID, err)
		}

		if err = updateAttractionMedia(ctx, pool, row.MediaID, fileID); err != nil {
			fatalf("update attraction media %s: %v", row.MediaID, err)
		}

		migrated++
		fmt.Printf("  stored in file-manager as %s\n", fileID)
	}

	fmt.Printf("Backfill complete: %d/%d media rows mirrored to MinIO.\n", migrated, len(rows))

	if *minMedia > 0 {
		added, err := importCommonsMedia(ctx, pool, client, strings.TrimRight(*fileManagerURL, "/"), strings.TrimSpace(*userAgent), *minMedia, *dryRun)
		if err != nil {
			fatalf("import Wikimedia Commons media: %v", err)
		}
		fmt.Printf("Commons import complete: %d new media rows added.\n", added)
	} else if len(rows) == 0 {
		fmt.Println("No attraction media rows need MinIO backfill.")
	}
}

func loadRows(ctx context.Context, pool *pgxpool.Pool, force bool, limit int) ([]mediaRow, error) {
	query := `
		SELECT
			m.id,
			m.attraction_id,
			a.author_user_id,
			COALESCE(t.title, m.attraction_id::text) AS title,
			m.external_url,
			m.source_url
		FROM attraction_media m
		JOIN attractions a ON a.id = m.attraction_id
		LEFT JOIN attraction_translations t ON t.attraction_id = a.id AND t.locale = 'ru'
		WHERE m.external_url <> ''
		  AND ($1::boolean OR m.file_id = $2::uuid)
		  AND a.deleted_at IS NULL
		ORDER BY title, m.position, m.id`
	args := []any{force, nilUUID}
	if limit > 0 {
		query += " LIMIT $3"
		args = append(args, limit)
	}

	rows, err := pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]mediaRow, 0)
	for rows.Next() {
		var row mediaRow
		if err = rows.Scan(
			&row.MediaID,
			&row.AttractionID,
			&row.AuthorUserID,
			&row.Title,
			&row.ExternalURL,
			&row.SourceURL,
		); err != nil {
			return nil, err
		}
		result = append(result, row)
	}
	return result, rows.Err()
}

func mirrorOne(ctx context.Context, client *http.Client, fileManagerURL string, userAgent string, row mediaRow) (uuid.UUID, error) {
	body, contentType, originalName, err := downloadImage(ctx, client, row, userAgent)
	if err != nil {
		return uuid.Nil, err
	}

	upload, err := createUploadRequest(ctx, client, fileManagerURL, row, originalName, contentType, len(body))
	if err != nil {
		return uuid.Nil, err
	}

	fileID, err := uuid.Parse(upload.FileID)
	if err != nil {
		return uuid.Nil, fmt.Errorf("parse file-manager file id %q: %w", upload.FileID, err)
	}

	if err = uploadBinary(ctx, client, fileManagerURL, row.AuthorUserID, fileID, body, contentType); err != nil {
		return uuid.Nil, err
	}
	if err = completeUpload(ctx, client, fileManagerURL, row.AuthorUserID, fileID); err != nil {
		return uuid.Nil, err
	}
	return fileID, nil
}

func downloadImage(ctx context.Context, client *http.Client, row mediaRow, userAgent string) ([]byte, string, string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, row.ExternalURL, nil)
	if err != nil {
		return nil, "", "", err
	}
	req.Header.Set("User-Agent", userAgent)
	req.Header.Set("Accept", "image/avif,image/webp,image/apng,image/*,*/*;q=0.8")

	resp, err := client.Do(req)
	if err != nil {
		return nil, "", "", fmt.Errorf("download source image: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		snippet, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return nil, "", "", fmt.Errorf("download source image: status %d: %s", resp.StatusCode, strings.TrimSpace(string(snippet)))
	}

	limited := io.LimitReader(resp.Body, maxImageBytes+1)
	body, err := io.ReadAll(limited)
	if err != nil {
		return nil, "", "", fmt.Errorf("read source image: %w", err)
	}
	if len(body) == 0 {
		return nil, "", "", errors.New("source image is empty")
	}
	if len(body) > maxImageBytes {
		return nil, "", "", fmt.Errorf("source image exceeds %d bytes", maxImageBytes)
	}

	contentType := normalizedImageContentType(resp.Header.Get("Content-Type"), body)
	if contentType == "" {
		return nil, "", "", fmt.Errorf("source did not return an image content type: %q", resp.Header.Get("Content-Type"))
	}

	originalName := originalNameFor(row, contentType)
	return body, contentType, originalName, nil
}

func createUploadRequest(
	ctx context.Context,
	client *http.Client,
	fileManagerURL string,
	row mediaRow,
	originalName string,
	contentType string,
	sizeBytes int,
) (*createUploadResponse, error) {
	payload := map[string]any{
		"originalName": originalName,
		"contentType":  contentType,
		"sizeBytes":    sizeBytes,
		"purpose":      "ATTRACTION_MEDIA",
		"visibility":   "PUBLIC",
		"ownerType":    "ATTRACTION",
		"ownerId":      row.AttractionID.String(),
	}

	encoded, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, fileManagerURL+"/v1/files/upload-requests", bytes.NewReader(encoded))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-Id", row.AuthorUserID.String())
	req.Header.Set("Idempotency-Key", "attraction-media-minio-"+row.MediaID.String())

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("create upload request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("create upload request: status %d: %s", resp.StatusCode, readSmallBody(resp.Body))
	}

	var out createUploadResponse
	if err = json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, fmt.Errorf("decode upload request response: %w", err)
	}
	if strings.TrimSpace(out.FileID) == "" {
		return nil, errors.New("file-manager returned empty fileId")
	}
	return &out, nil
}

func uploadBinary(
	ctx context.Context,
	client *http.Client,
	fileManagerURL string,
	authorUserID uuid.UUID,
	fileID uuid.UUID,
	body []byte,
	contentType string,
) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodPut, fileManagerURL+"/v1/files/"+fileID.String()+"/binary", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("X-User-Id", authorUserID.String())

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("upload binary: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("upload binary: status %d: %s", resp.StatusCode, readSmallBody(resp.Body))
	}
	return nil
}

func completeUpload(
	ctx context.Context,
	client *http.Client,
	fileManagerURL string,
	authorUserID uuid.UUID,
	fileID uuid.UUID,
) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, fileManagerURL+"/v1/files/"+fileID.String()+"/complete", nil)
	if err != nil {
		return err
	}
	req.Header.Set("X-User-Id", authorUserID.String())

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("complete upload: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("complete upload: status %d: %s", resp.StatusCode, readSmallBody(resp.Body))
	}
	return nil
}

func updateAttractionMedia(ctx context.Context, pool *pgxpool.Pool, mediaID uuid.UUID, fileID uuid.UUID) error {
	tag, err := pool.Exec(
		ctx,
		`UPDATE attraction_media
		 SET file_id = $1, external_url = ''
		 WHERE id = $2`,
		fileID,
		mediaID,
	)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return fmt.Errorf("expected to update 1 row, updated %d", tag.RowsAffected())
	}
	return nil
}

func importCommonsMedia(
	ctx context.Context,
	pool *pgxpool.Pool,
	client *http.Client,
	fileManagerURL string,
	userAgent string,
	minMedia int,
	dryRun bool,
) (int, error) {
	targets, err := loadAttractionTargets(ctx, pool)
	if err != nil {
		return 0, err
	}

	added := 0
	for _, target := range targets {
		missing := minMedia - target.MediaCount
		if missing <= 0 {
			continue
		}

		fmt.Printf("Discovering Commons media for %s: need %d more\n", target.Title, missing)
		candidates, err := discoverCommonsCandidates(ctx, client, userAgent, target, missing)
		if err != nil {
			return added, err
		}
		if len(candidates) < missing {
			return added, fmt.Errorf("only found %d/%d usable Commons images for %s", len(candidates), missing, target.Title)
		}

		for _, candidate := range candidates[:missing] {
			row := mediaRow{
				MediaID:      deterministicMediaID(target.AttractionID, candidate.SourceURL),
				AttractionID: target.AttractionID,
				AuthorUserID: target.AuthorUserID,
				Title:        target.Title,
				ExternalURL:  candidate.DownloadURL,
				SourceURL:    candidate.SourceURL,
			}

			if dryRun {
				fmt.Printf("  dry-run: would add %s\n", candidate.SourceURL)
				continue
			}

			fileID, err := mirrorOne(ctx, client, fileManagerURL, userAgent, row)
			if err != nil {
				return added, fmt.Errorf("mirror %s for %s: %w", candidate.SourceURL, target.Title, err)
			}

			if err = insertAttractionMedia(ctx, pool, row.MediaID, target.AttractionID, fileID, candidate, target.NextPosition); err != nil {
				return added, fmt.Errorf("insert media %s for %s: %w", candidate.SourceURL, target.Title, err)
			}

			target.NextPosition++
			target.MediaCount++
			target.ExistingSources[candidate.SourceURL] = struct{}{}
			added++
			fmt.Printf("  added %s as %s\n", candidate.SourceURL, fileID)
		}
		time.Sleep(2 * time.Second)
	}

	if !dryRun {
		if err := normalizeMediaPositions(ctx, pool); err != nil {
			return added, err
		}
	}

	return added, nil
}

func loadAttractionTargets(ctx context.Context, pool *pgxpool.Pool) ([]attractionTarget, error) {
	rows, err := pool.Query(ctx, `
		SELECT
			a.id,
			a.author_user_id,
			COALESCE(ru.title, en.title, a.id::text) AS title,
			COALESCE(en.title, ru.title, a.id::text) AS search_title,
			COUNT(m.id)::int AS media_count,
			COALESCE(MAX(m.position), -1)::int + 1 AS next_position,
			COALESCE(ARRAY_AGG(m.source_url) FILTER (WHERE m.source_url <> ''), ARRAY[]::text[]) AS source_urls
		FROM attractions a
		LEFT JOIN attraction_translations ru ON ru.attraction_id = a.id AND ru.locale = 'ru'
		LEFT JOIN attraction_translations en ON en.attraction_id = a.id AND en.locale = 'en'
		LEFT JOIN attraction_media m ON m.attraction_id = a.id
		WHERE a.deleted_at IS NULL
		GROUP BY a.id, a.author_user_id, ru.title, en.title
		ORDER BY title`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	targets := make([]attractionTarget, 0)
	for rows.Next() {
		var target attractionTarget
		var sources []string
		if err = rows.Scan(
			&target.AttractionID,
			&target.AuthorUserID,
			&target.Title,
			&target.SearchTitle,
			&target.MediaCount,
			&target.NextPosition,
			&sources,
		); err != nil {
			return nil, err
		}

		target.ExistingSources = make(map[string]struct{}, len(sources))
		for _, source := range sources {
			source = strings.TrimSpace(source)
			if source != "" {
				target.ExistingSources[source] = struct{}{}
			}
		}
		targets = append(targets, target)
	}
	return targets, rows.Err()
}

func discoverCommonsCandidates(
	ctx context.Context,
	client *http.Client,
	userAgent string,
	target attractionTarget,
	needed int,
) ([]commonsCandidate, error) {
	candidates := make([]commonsCandidate, 0, needed)
	seen := make(map[string]struct{}, len(target.ExistingSources)+needed)
	for source := range target.ExistingSources {
		seen[source] = struct{}{}
	}

	for _, candidate := range curatedCommonsCandidatesFor(target.SearchTitle) {
		if _, ok := seen[candidate.SourceURL]; ok {
			continue
		}
		candidates = append(candidates, candidate)
		seen[candidate.SourceURL] = struct{}{}
		if len(candidates) >= needed {
			return candidates, nil
		}
	}

	for i, query := range commonsQueriesFor(target.SearchTitle) {
		if i > 0 {
			time.Sleep(1500 * time.Millisecond)
		}
		found, err := searchCommonsCandidates(ctx, client, userAgent, query, seen, needed-len(candidates))
		if err != nil {
			return candidates, fmt.Errorf("search Commons for %s using %q: %w", target.Title, query, err)
		}
		for _, candidate := range found {
			candidates = append(candidates, candidate)
			seen[candidate.SourceURL] = struct{}{}
			if len(candidates) >= needed {
				return candidates, nil
			}
		}
	}

	return candidates, nil
}

func curatedCommonsCandidatesFor(searchTitle string) []commonsCandidate {
	filesByTitle := map[string][]string{
		"Big Almaty Lake": {
			"Big Almaty Lake 2014.jpg",
			"Big Almaty Lake Winter.jpg",
			"Big Almaty Lake on 29 Aug 2019.jpg",
		},
		"Medeu Alpine Skating Rink": {
			"AlmaAtaMedeu.jpg",
			"Медео, верхушка плотины.jpg",
			"Medeobanen1.jpg",
		},
		"Shymbulak Ski Resort": {
			"Shymbulak, Almaty (P1180189).jpg",
			"Shymbulak, Almaty (P1180179).jpg",
			"Shymbulak, Almaty (P1180181).jpg",
		},
		"Aksu-Zhabagly Nature Reserve": {
			"Aksu-Zhabagly Nature Reserve.jpg",
			"Aksu Jabagly 2.JPG",
			"Aksu Jabgly 3.JPG",
		},
		"Ulytau Reserve-Museum": {
			"Dzhuchi khan mausoleum.jpg",
			"Жошы хан кесенесі.jpg",
			"Dzhuchi khan mausoleum (cropped).jpg",
		},
		"Ancient Taraz Historical and Cultural Center": {
			"Model of Ancient Taraz (5611934896).jpg",
			"Taraz Hill fort.JPG",
			"Syr Darya Oblast. Aulie-Ata. Bazaar Square WDL10902.png",
		},
		"Kolsai Lakes": {
			"Kolsai lake.jpg",
			"Kolsai lakes.Mountains.jpg",
			"Kolsai lakes.jpg",
		},
		"Mausoleum of Khoja Ahmed Yasawi": {
			"Mausoleum of Khoja Ahmed Yasawi in Turkistan 3.jpg",
			"Mausoleum of Khoja Ahmed Yasawi in Hazrat-e Turkestan, Kazakhstan.jpg",
			"Mausoleum of Khoja Ahmed Yasavi in Turkestan, Kazakhstan.jpg",
		},
		"Bayterek Tower": {
			"Baiterek.jpg",
			"Astana-2021-10 - 12.jpg",
			"View from Bayterek tower.jpg",
		},
		"Altyn-Emel National Park": {
			"Altyn Emel 1.jpg",
			"Казахстан, нацпарк Алтын Эмель, саксаул (5).jpg",
			"Altyn Emel 2022 March 05.jpg",
		},
		"Bayanaul National Park": {
			"Bayanaul National Park.jpg",
			"Bayanaul National Reserve Park Grove.jpg",
			"Bayanaul National Reserve Park Stone Monument.jpg",
		},
		"Burabay National Park": {
			"Borovoe1.jpg",
			"Burabay winter.jpg",
			"Окжетпес Боровое.jpg",
		},
		"Katon-Karagay National Park": {
			"Beautiful view of the mountains (Katon-Karagay).jpg",
			"Katon Ridge, Altai mountains. Katon-Karagay, East Kazakhstan region. June 2025.jpg",
			"Rakhmanovskie Klyuchi.jpg",
		},
		"Lake Alakol": {
			"Alakol District, Kazakhstan - panoramio (3).jpg",
			"Озеро Алаколь возле Кабанбай (Жарбулак) сверху.jpg",
			"Urzhar mouth Alakol Lake ESA365539.jpg",
		},
		"Lake Balkhash": {
			"Balkhash lake, september 2020.jpg",
			"LakeBalkhash colorful.jpg",
			"Караойский заказник, берег Балхаша сверху (4).jpg",
		},
		"Lake Kaindy": {
			"Kaindy lake.jpg",
			"Kaindy lake south-east Kazakhstan.jpg",
			"Зеркальный Каинды.jpg",
		},
		"Tamgaly Petroglyphs": {
			"Petroglyphs in Tamgaly, Kazakhstan 01.jpg",
			"Petroglyphs in Tamgaly, Kazakhstan 02.jpg",
			"Tamgaly main petroglyph.jpg",
		},
		"Saryarka Steppe and Lakes": {
			"Sunset in Korgalzhyn Nature Reserve.jpg",
			"Korgalzhinskiy Nature Reserve.JPG",
			"New Born Saiga in Korgalzhyn Reserve.jpg",
		},
		"Bozjyra Tract": {
			"Bozzhyra valley, Mangistau region, Kazakhstan.jpg",
			"Boszhira tract. Kazakhstan, Mangistau. November 2024.jpg",
			"Aurora outlier, Boszhira tract. Kazakhstan, Mangistau. November 2024.jpg",
		},
		"Charyn Canyon": {
			"Charyn Canyon, Kazakhstan 01.jpg",
			"Charyn Canyon, Kazakhstan 03.jpg",
			"Charyn Canyon, Kazakhstan 04.jpg",
		},
	}

	fileNames := filesByTitle[strings.TrimSpace(searchTitle)]
	candidates := make([]commonsCandidate, 0, len(fileNames))
	for _, fileName := range fileNames {
		candidates = append(candidates, commonsCandidateForFileName(fileName))
	}
	return candidates
}

func commonsCandidateForFileName(fileName string) commonsCandidate {
	filePageName := strings.ReplaceAll(strings.TrimSpace(fileName), " ", "_")
	downloadName := url.PathEscape(strings.TrimSpace(fileName))
	return commonsCandidate{
		Title:       "File:" + filePageName,
		DownloadURL: "https://commons.wikimedia.org/wiki/Special:FilePath/" + downloadName + "?width=1600",
		SourceURL:   "https://commons.wikimedia.org/wiki/File:" + filePageName,
		Credit:      "Wikimedia Commons contributors",
		License:     "See Wikimedia Commons source page",
	}
}

func commonsQueriesFor(searchTitle string) []string {
	title := strings.TrimSpace(searchTitle)
	queries := []string{title + " Kazakhstan"}
	aliases := map[string][]string{
		"Medeu Alpine Skating Rink": {
			"Medeo Kazakhstan",
			"Medeu skating rink Almaty",
		},
		"Shymbulak Ski Resort": {
			"Shymbulak Almaty",
			"Chimbulak Kazakhstan",
		},
		"Ulytau Reserve-Museum": {
			"Ulytau Kazakhstan",
			"Jochi Khan mausoleum Kazakhstan",
			"Alasha Khan mausoleum Kazakhstan",
			"Terekty Aulie Ulytau",
		},
		"Ancient Taraz Historical and Cultural Center": {
			"Ancient Taraz Kazakhstan",
			"Taraz Kazakhstan archaeology",
		},
		"Bayterek Tower": {
			"Baiterek Astana",
			"Bayterek Tower Astana",
			"Baiterek monument Astana",
		},
		"Burabay National Park": {
			"Borovoe Kazakhstan",
			"Burabay Kazakhstan",
		},
		"Saryarka Steppe and Lakes": {
			"Korgalzhyn Nature Reserve Kazakhstan",
			"Korgalzhyn lakes Kazakhstan",
			"Saryarka Kazakhstan",
		},
		"Bozjyra Tract": {
			"Bozzhyra Kazakhstan",
			"Bozjyra Mangystau",
		},
		"Tamgaly Petroglyphs": {
			"Tamgaly petroglyphs Kazakhstan",
			"Petroglyphs in Tamgaly Kazakhstan",
			"Tanbaly Kazakhstan",
		},
		"Katon-Karagay National Park": {
			"Katon Karagay Kazakhstan",
			"Katon-Karagay National Park",
		},
		"Lake Alakol": {
			"Lake Alakol Kazakhstan",
			"Alakol lake Kazakhstan",
		},
		"Lake Balkhash": {
			"Lake Balkhash Kazakhstan",
			"Balkhash lake Kazakhstan",
		},
		"Lake Kaindy": {
			"Kaindy lake Kazakhstan",
			"Lake Kaindy Kazakhstan",
		},
		"Charyn Canyon": {
			"Charyn Canyon Kazakhstan",
			"Valley of Castles Charyn",
		},
	}
	queries = append(queries, aliases[title]...)

	deduped := queries[:0]
	seen := map[string]struct{}{}
	for _, query := range queries {
		query = strings.TrimSpace(query)
		if query == "" {
			continue
		}
		if _, ok := seen[query]; ok {
			continue
		}
		seen[query] = struct{}{}
		deduped = append(deduped, query)
	}
	return deduped
}

func searchCommonsCandidates(
	ctx context.Context,
	client *http.Client,
	userAgent string,
	query string,
	existingSources map[string]struct{},
	needed int,
) ([]commonsCandidate, error) {
	endpoint, err := url.Parse("https://commons.wikimedia.org/w/api.php")
	if err != nil {
		return nil, err
	}

	params := endpoint.Query()
	params.Set("action", "query")
	params.Set("generator", "search")
	params.Set("gsrnamespace", "6")
	params.Set("gsrsearch", query)
	params.Set("gsrlimit", "24")
	params.Set("prop", "imageinfo")
	params.Set("iiprop", "url|mime|size|extmetadata")
	params.Set("iiurlwidth", "1600")
	params.Set("format", "json")
	endpoint.RawQuery = params.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint.String(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", userAgent)
	req.Header.Set("Accept", "application/json")

	var decoded commonsSearchResponse
	if err = doCommonsSearchRequest(ctx, client, req, &decoded); err != nil {
		return nil, err
	}

	pages := make([]commonsPage, 0, len(decoded.Query.Pages))
	for _, page := range decoded.Query.Pages {
		pages = append(pages, page)
	}
	sort.SliceStable(pages, func(i, j int) bool {
		return pages[i].Index < pages[j].Index
	})

	candidates := make([]commonsCandidate, 0, needed)
	seen := make(map[string]struct{}, len(existingSources))
	for source := range existingSources {
		seen[source] = struct{}{}
	}

	for _, page := range pages {
		if len(page.ImageInfo) == 0 || rejectedCommonsTitle(page.Title) {
			continue
		}

		info := page.ImageInfo[0]
		if !strings.HasPrefix(strings.ToLower(info.Mime), "image/") {
			continue
		}
		if !hasUsableCommonsDimensions(info) {
			continue
		}

		sourceURL := strings.TrimSpace(info.DescriptionURL)
		if sourceURL == "" {
			continue
		}
		if _, ok := seen[sourceURL]; ok {
			continue
		}

		downloadURL := strings.TrimSpace(info.ThumbURL)
		if downloadURL == "" {
			downloadURL = strings.TrimSpace(info.URL)
		}
		if downloadURL == "" {
			continue
		}

		candidate := commonsCandidate{
			Title:       page.Title,
			DownloadURL: downloadURL,
			SourceURL:   sourceURL,
			Credit:      commonsCredit(info.ExtMetadata),
			License:     commonsLicense(info.ExtMetadata),
		}
		candidates = append(candidates, candidate)
		seen[sourceURL] = struct{}{}
		if len(candidates) >= needed {
			break
		}
	}

	return candidates, nil
}

func doCommonsSearchRequest(
	ctx context.Context,
	client *http.Client,
	req *http.Request,
	out *commonsSearchResponse,
) error {
	const maxAttempts = 4
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		cloned := req.Clone(ctx)
		resp, err := client.Do(cloned)
		if err != nil {
			if attempt < maxAttempts {
				time.Sleep(commonsRetryDelay(attempt, 0))
				continue
			}
			return err
		}

		if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= http.StatusInternalServerError {
			retryAfter := retryAfterDelay(resp.Header.Get("Retry-After"))
			snippet := readSmallBody(resp.Body)
			_ = resp.Body.Close()
			if attempt < maxAttempts {
				time.Sleep(commonsRetryDelay(attempt, retryAfter))
				continue
			}
			return fmt.Errorf("status %d: %s", resp.StatusCode, snippet)
		}

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			snippet := readSmallBody(resp.Body)
			_ = resp.Body.Close()
			return fmt.Errorf("status %d: %s", resp.StatusCode, snippet)
		}

		err = json.NewDecoder(resp.Body).Decode(out)
		_ = resp.Body.Close()
		if err != nil {
			return err
		}
		return nil
	}
	return errors.New("Commons search exhausted retries")
}

func commonsRetryDelay(attempt int, retryAfter time.Duration) time.Duration {
	if retryAfter > 0 {
		return retryAfter
	}
	return time.Duration(attempt*attempt) * 3 * time.Second
}

func retryAfterDelay(value string) time.Duration {
	value = strings.TrimSpace(value)
	if value == "" {
		return 0
	}
	seconds, err := strconv.Atoi(value)
	if err != nil || seconds <= 0 {
		return 0
	}
	return time.Duration(seconds) * time.Second
}

func insertAttractionMedia(
	ctx context.Context,
	pool *pgxpool.Pool,
	mediaID uuid.UUID,
	attractionID uuid.UUID,
	fileID uuid.UUID,
	candidate commonsCandidate,
	position int,
) error {
	_, err := pool.Exec(
		ctx,
		`INSERT INTO attraction_media (
			id, attraction_id, file_id, external_url, source_url, credit, license, media_type, position, created_at
		)
		VALUES ($1, $2, $3, '', $4, $5, $6, 'PHOTO', $7, NOW())
		ON CONFLICT (id) DO UPDATE SET
			file_id = EXCLUDED.file_id,
			external_url = '',
			source_url = EXCLUDED.source_url,
			credit = EXCLUDED.credit,
			license = EXCLUDED.license,
			media_type = EXCLUDED.media_type,
			position = EXCLUDED.position`,
		mediaID,
		attractionID,
		fileID,
		candidate.SourceURL,
		candidate.Credit,
		candidate.License,
		position,
	)
	return err
}

func normalizeMediaPositions(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		WITH ranked AS (
			SELECT
				id,
				ROW_NUMBER() OVER (
					PARTITION BY attraction_id
					ORDER BY position, created_at, id
				)::int - 1 AS normalized_position
			FROM attraction_media
		)
		UPDATE attraction_media m
		SET position = ranked.normalized_position
		FROM ranked
		WHERE m.id = ranked.id
		  AND m.position <> ranked.normalized_position`)
	return err
}

type commonsSearchResponse struct {
	Query struct {
		Pages map[string]commonsPage `json:"pages"`
	} `json:"query"`
}

type commonsPage struct {
	Title     string             `json:"title"`
	Index     int                `json:"index"`
	ImageInfo []commonsImageInfo `json:"imageinfo"`
}

type commonsImageInfo struct {
	URL            string                    `json:"url"`
	ThumbURL       string                    `json:"thumburl"`
	DescriptionURL string                    `json:"descriptionurl"`
	Mime           string                    `json:"mime"`
	Width          int                       `json:"width"`
	Height         int                       `json:"height"`
	ExtMetadata    map[string]commonsMetaVal `json:"extmetadata"`
}

type commonsMetaVal struct {
	Value any `json:"value"`
}

func deterministicMediaID(attractionID uuid.UUID, sourceURL string) uuid.UUID {
	return uuid.NewSHA1(uuid.NameSpaceURL, []byte(attractionID.String()+"|"+sourceURL))
}

func rejectedCommonsTitle(title string) bool {
	title = strings.ToLower(strings.TrimSpace(title))
	if title == "" {
		return true
	}
	normalized := strings.NewReplacer("_", " ", "-", " ", ".", " ").Replace(title)
	normalized = strings.Join(strings.Fields(normalized), " ")
	rejected := []string{
		" svg",
		" gif",
		" map",
		" locator",
		" logo",
		" emblem",
		" flag",
		" coat of arms",
		" region in kazakhstan",
		" region png",
		" district kazakhstan",
		" district in kazakhstan",
		" district png",
		" oblast",
		" administrative",
		" banner",
		" mironov",
		" chp ",
		" crew visit ",
		" tamgaly tas",
		" tulipa ",
		" prangos ",
		" lactarius ",
		" spathularia ",
		" ceratomegilla ",
		" mushroom",
		" fungi",
		"route",
		"schema",
		"diagram",
	}
	for _, token := range rejected {
		if strings.Contains(normalized, token) {
			return true
		}
	}
	return false
}

func hasUsableCommonsDimensions(info commonsImageInfo) bool {
	if info.Width == 0 || info.Height == 0 {
		return true
	}
	shortSide := info.Width
	longSide := info.Height
	if shortSide > longSide {
		shortSide, longSide = longSide, shortSide
	}
	return shortSide >= 450 && longSide >= 900
}

var htmlTagPattern = regexp.MustCompile(`<[^>]*>`)

func commonsCredit(metadata map[string]commonsMetaVal) string {
	for _, key := range []string{"Artist", "Credit"} {
		value := cleanCommonsText(metadataValue(metadata, key))
		if value != "" && !strings.EqualFold(value, "own work") {
			return value
		}
	}
	return "Wikimedia Commons contributors"
}

func commonsLicense(metadata map[string]commonsMetaVal) string {
	for _, key := range []string{"LicenseShortName", "UsageTerms"} {
		value := cleanCommonsText(metadataValue(metadata, key))
		if value != "" {
			return value
		}
	}
	return "See Wikimedia Commons source page"
}

func metadataValue(metadata map[string]commonsMetaVal, key string) string {
	if metadata == nil {
		return ""
	}
	value := metadata[key].Value
	if value == nil {
		return ""
	}
	switch typed := value.(type) {
	case string:
		return typed
	case float64:
		return strconv.FormatFloat(typed, 'f', -1, 64)
	case bool:
		return strconv.FormatBool(typed)
	default:
		return fmt.Sprint(typed)
	}
}

func cleanCommonsText(value string) string {
	value = htmlTagPattern.ReplaceAllString(value, "")
	value = html.UnescapeString(value)
	value = strings.Join(strings.Fields(value), " ")
	return strings.TrimSpace(value)
}

func normalizedImageContentType(raw string, body []byte) string {
	contentType := strings.ToLower(strings.TrimSpace(raw))
	if idx := strings.Index(contentType, ";"); idx >= 0 {
		contentType = strings.TrimSpace(contentType[:idx])
	}
	if strings.HasPrefix(contentType, "image/") {
		return contentType
	}

	sniffSize := len(body)
	if sniffSize > 512 {
		sniffSize = 512
	}
	detected := strings.ToLower(http.DetectContentType(body[:sniffSize]))
	if idx := strings.Index(detected, ";"); idx >= 0 {
		detected = strings.TrimSpace(detected[:idx])
	}
	if strings.HasPrefix(detected, "image/") {
		return detected
	}
	return ""
}

func originalNameFor(row mediaRow, contentType string) string {
	for _, candidate := range []string{row.SourceURL, row.ExternalURL} {
		name := fileNameFromURL(candidate)
		if name != "" {
			return ensureAllowedImageExtension(name, contentType)
		}
	}

	slug := strings.ToLower(row.Title)
	slug = strings.NewReplacer(" ", "-", "_", "-", ":", "", ",", "", "'", "").Replace(slug)
	if strings.TrimSpace(slug) == "" {
		slug = row.MediaID.String()
	}
	return ensureAllowedImageExtension(slug, contentType)
}

func fileNameFromURL(raw string) string {
	parsed, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		return ""
	}
	escapedBase := path.Base(parsed.EscapedPath())
	if escapedBase == "." || escapedBase == "/" {
		return ""
	}
	name, err := url.PathUnescape(escapedBase)
	if err != nil {
		name = escapedBase
	}
	name = strings.TrimPrefix(name, "File:")
	name = strings.TrimSpace(name)
	if name == "" || name == "." || name == "/" {
		return ""
	}
	return name
}

func ensureAllowedImageExtension(name string, contentType string) string {
	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(name), "."))
	switch ext {
	case "jpg", "jpeg", "png", "webp":
		return name
	}

	extensions, _ := mime.ExtensionsByType(contentType)
	for _, ext := range extensions {
		normalized := strings.ToLower(strings.TrimPrefix(ext, "."))
		switch normalized {
		case "jpg", "jpeg", "png", "webp":
			return strings.TrimSuffix(name, filepath.Ext(name)) + "." + normalized
		}
	}
	return strings.TrimSuffix(name, filepath.Ext(name)) + ".jpg"
}

func attractionDatabaseURLFromEnv() string {
	host := envOr("POSTGRES_HOST", "localhost")
	port := envOr("POSTGRES_PORT", "5441")
	user := envOr("POSTGRES_USER", "attraction_service")
	password := envOr("POSTGRES_PASSWORD", "attraction_secret_dev")
	db := envOr("POSTGRES_DB", "attraction_service_db")
	sslMode := envOr("POSTGRES_SSLMODE", "disable")
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", user, password, host, port, db, sslMode)
}

func envOr(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func envIntOr(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func envBoolOr(key string, fallback bool) bool {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func readSmallBody(body io.Reader) string {
	data, _ := io.ReadAll(io.LimitReader(body, 1024))
	return strings.TrimSpace(string(data))
}

func fatalf(format string, args ...any) {
	_, _ = fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
