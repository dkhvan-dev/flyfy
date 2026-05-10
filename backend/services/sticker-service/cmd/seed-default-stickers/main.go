package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	"image/color"
	"image/color/palette"
	imagedraw "image/draw"
	"image/gif"
	"io"
	"log"
	"math"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/config"
)

const (
	stickerCanvasSize  = 512
	stickerContentType = "image/gif"
	stickerFileExt     = "gif"
	stickerFrameCount  = 18
	systemOwnerType    = "ORGANIZATION"
	systemOwnerID      = "00000000-0000-0000-0000-000000000001"
)

type stickerDefinition struct {
	GroupSlug       string
	GroupTitle      map[string]string
	GroupOrder      int
	PackSlug        string
	PackTitle       map[string]string
	PackDescription map[string]string
	PackOrder       int
	Key             string
	Emoji           string
	Keywords        []string
	FallbackName    string
	DurationMS      int
	SortOrder       int
	Background      color.RGBA
	Accent          color.RGBA
	Dark            color.RGBA
}

type seedAsset struct {
	SeedKey   string
	PackID    uuid.UUID
	StickerID uuid.UUID
	FileID    uuid.UUID
	Checksum  string
	SizeBytes int64
}

type seeder struct {
	db    *pgxpool.Pool
	files *fileManagerClient
}

type fileManagerClient struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatalf("connect sticker postgres: %v", err)
	}
	defer pool.Close()

	s := &seeder{
		db: pool,
		files: &fileManagerClient{
			baseURL:       strings.TrimRight(cfg.FileManager.BaseURL, "/"),
			internalToken: cfg.FileManager.EffectiveInternalServiceToken(cfg.Security.InternalServiceToken),
			httpClient:    &http.Client{Timeout: cfg.FileManager.Timeout},
		},
	}

	if err = s.run(ctx); err != nil {
		log.Fatalf("seed default stickers: %v", err)
	}
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		return nil, err
	}
	poolConfig.MaxConns = cfg.DB.MaxConns
	poolConfig.MinConns = cfg.DB.MinConns
	poolConfig.MaxConnLifetime = cfg.DB.ParsedMaxConnLifetime()
	poolConfig.MaxConnIdleTime = cfg.DB.ParsedMaxConnIdleTime()

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, err
	}
	if err = pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return pool, nil
}

func (s *seeder) run(ctx context.Context) error {
	if err := s.ensureSeedRegistry(ctx); err != nil {
		return err
	}

	definitions := defaultStickerDefinitions()
	coverStickerIDs := map[uuid.UUID]uuid.UUID{}
	activeSeedKeys := make([]string, 0, len(definitions))
	activePackSlugs := make([]string, 0, len(definitions))
	seenPackSlugs := map[string]struct{}{}

	for _, def := range definitions {
		activeSeedKeys = append(activeSeedKeys, def.Key)
		if _, ok := seenPackSlugs[def.PackSlug]; !ok {
			seenPackSlugs[def.PackSlug] = struct{}{}
			activePackSlugs = append(activePackSlugs, def.PackSlug)
		}

		groupID, err := s.ensureGroup(ctx, def)
		if err != nil {
			return fmt.Errorf("ensure sticker group %q: %w", def.GroupSlug, err)
		}
		packID, err := s.ensurePack(ctx, groupID, def)
		if err != nil {
			return fmt.Errorf("ensure sticker pack %q: %w", def.PackSlug, err)
		}

		body, err := renderStickerAnimation(def)
		if err != nil {
			return fmt.Errorf("render sticker %q: %w", def.Key, err)
		}

		stickerID, err := s.ensureSticker(ctx, packID, def, body)
		if err != nil {
			return fmt.Errorf("ensure sticker %q: %w", def.Key, err)
		}
		if coverStickerIDs[packID] == uuid.Nil {
			coverStickerIDs[packID] = stickerID
		}
	}

	for packID, coverStickerID := range coverStickerIDs {
		if _, err := s.db.Exec(ctx, `
			UPDATE sticker_packs
			SET cover_sticker_id = $1, updated_at = NOW()
			WHERE id = $2
		`, coverStickerID, packID); err != nil {
			return fmt.Errorf("update default pack cover: %w", err)
		}
	}

	if err := s.deactivateRetiredSeedStickers(ctx, activeSeedKeys); err != nil {
		return err
	}
	if err := s.deactivateRetiredOfficialPacks(ctx, activePackSlugs); err != nil {
		return err
	}

	log.Printf("seeded %d official sticker packs", len(coverStickerIDs))
	return nil
}

func (s *seeder) ensureSeedRegistry(ctx context.Context) error {
	_, err := s.db.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS sticker_seed_assets (
			seed_key TEXT PRIMARY KEY,
			pack_id UUID NOT NULL REFERENCES sticker_packs(id) ON DELETE CASCADE,
			sticker_id UUID NOT NULL REFERENCES stickers(id) ON DELETE CASCADE,
			file_id UUID NOT NULL,
			checksum_sha256 CHAR(64) NOT NULL,
			created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
			updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		)
	`)
	if err != nil {
		return fmt.Errorf("ensure sticker seed registry: %w", err)
	}
	return nil
}

func (s *seeder) ensureGroup(ctx context.Context, def stickerDefinition) (uuid.UUID, error) {
	title, err := json.Marshal(def.GroupTitle)
	if err != nil {
		return uuid.Nil, err
	}

	var groupID uuid.UUID
	err = s.db.QueryRow(ctx, `
		INSERT INTO sticker_groups (
			slug, title, display_order, status, created_at, updated_at
		)
		VALUES ($1, $2::jsonb, $3, 'ACTIVE', NOW(), NOW())
		ON CONFLICT (slug) DO UPDATE SET
			title = EXCLUDED.title,
			display_order = EXCLUDED.display_order,
			status = 'ACTIVE',
			updated_at = NOW()
		RETURNING id
	`, def.GroupSlug, string(title), def.GroupOrder).Scan(&groupID)
	if err != nil {
		return uuid.Nil, fmt.Errorf("upsert sticker group: %w", err)
	}
	return groupID, nil
}

func (s *seeder) ensurePack(ctx context.Context, groupID uuid.UUID, def stickerDefinition) (uuid.UUID, error) {
	title, err := json.Marshal(def.PackTitle)
	if err != nil {
		return uuid.Nil, err
	}
	description, err := json.Marshal(def.PackDescription)
	if err != nil {
		return uuid.Nil, err
	}

	var packID uuid.UUID
	err = s.db.QueryRow(ctx, `
		INSERT INTO sticker_packs (
			group_id, slug, type, visibility, status, is_official, version,
			owner_user_id, title, description, sort_order, published_at, created_at, updated_at
		)
		VALUES (
			$1, $2, 'SYSTEM', 'PUBLIC', 'ACTIVE', TRUE, 1,
			NULL, $3::jsonb, $4::jsonb, $5, NOW(), NOW(), NOW()
		)
		ON CONFLICT (slug) DO UPDATE SET
			group_id = EXCLUDED.group_id,
			type = 'SYSTEM',
			visibility = 'PUBLIC',
			status = 'ACTIVE',
			is_official = TRUE,
			version = sticker_packs.version + 1,
			owner_user_id = NULL,
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			sort_order = EXCLUDED.sort_order,
			published_at = COALESCE(sticker_packs.published_at, NOW()),
			updated_at = NOW()
		RETURNING id
	`, groupID, def.PackSlug, string(title), string(description), def.PackOrder).Scan(&packID)
	if err != nil {
		return uuid.Nil, fmt.Errorf("upsert official sticker pack: %w", err)
	}
	return packID, nil
}

func (s *seeder) ensureSticker(ctx context.Context, packID uuid.UUID, def stickerDefinition, body []byte) (uuid.UUID, error) {
	checksum := sha256Hex(body)

	asset, err := s.findSeedAsset(ctx, def.Key)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, err
	}

	if err == nil {
		asset.SizeBytes = int64(len(body))
		if asset.PackID != packID || asset.Checksum != checksum {
			fileID, uploadErr := s.files.uploadSticker(ctx, def, body, checksum)
			if uploadErr != nil {
				return uuid.Nil, uploadErr
			}
			asset.PackID = packID
			asset.FileID = fileID
			asset.Checksum = checksum
		}
		if upsertErr := s.upsertStickerAndSeedAsset(ctx, asset, def); upsertErr != nil {
			return uuid.Nil, upsertErr
		}
		return asset.StickerID, nil
	}

	fileID, err := s.files.uploadSticker(ctx, def, body, checksum)
	if err != nil {
		return uuid.Nil, err
	}

	asset = seedAsset{
		SeedKey:   def.Key,
		PackID:    packID,
		StickerID: uuid.New(),
		FileID:    fileID,
		Checksum:  checksum,
		SizeBytes: int64(len(body)),
	}
	if err = s.upsertStickerAndSeedAsset(ctx, asset, def); err != nil {
		return uuid.Nil, err
	}
	return asset.StickerID, nil
}

func (s *seeder) findSeedAsset(ctx context.Context, seedKey string) (seedAsset, error) {
	var asset seedAsset
	err := s.db.QueryRow(ctx, `
		SELECT seed_key, pack_id, sticker_id, file_id, checksum_sha256
		FROM sticker_seed_assets
		WHERE seed_key = $1
	`, seedKey).Scan(&asset.SeedKey, &asset.PackID, &asset.StickerID, &asset.FileID, &asset.Checksum)
	return asset, err
}

func (s *seeder) upsertStickerAndSeedAsset(ctx context.Context, asset seedAsset, def stickerDefinition) error {
	tx, err := s.db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin seed sticker tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	emoji := def.Emoji
	if _, err = tx.Exec(ctx, `
		INSERT INTO stickers (
			id, pack_id, slug, file_id, fallback_file_id, preview_file_id,
			emoji, keywords, status, content_type, width, height, duration_ms,
			size_bytes, checksum, sort_order, created_by_user_id, created_at, updated_at
		)
		VALUES (
			$1, $2, $3, $4, $4, $4,
			$5, $6, 'ACTIVE', $7, $8, $9, $10,
			$11, $12, $13, NULL, NOW(), NOW()
		)
		ON CONFLICT (id) DO UPDATE SET
			pack_id = EXCLUDED.pack_id,
			slug = EXCLUDED.slug,
			file_id = EXCLUDED.file_id,
			fallback_file_id = EXCLUDED.fallback_file_id,
			preview_file_id = EXCLUDED.preview_file_id,
			emoji = EXCLUDED.emoji,
			keywords = EXCLUDED.keywords,
			status = 'ACTIVE',
			content_type = EXCLUDED.content_type,
			width = EXCLUDED.width,
			height = EXCLUDED.height,
			duration_ms = EXCLUDED.duration_ms,
			size_bytes = EXCLUDED.size_bytes,
			checksum = EXCLUDED.checksum,
			sort_order = EXCLUDED.sort_order,
			updated_at = NOW()
	`, asset.StickerID, asset.PackID, def.Key, asset.FileID, emoji, def.Keywords,
		stickerContentType, stickerCanvasSize, stickerCanvasSize, def.DurationMS,
		asset.SizeBytes, asset.Checksum, def.SortOrder); err != nil {
		return fmt.Errorf("upsert sticker row: %w", err)
	}

	if _, err = tx.Exec(ctx, `
		INSERT INTO sticker_seed_assets (
			seed_key, pack_id, sticker_id, file_id, checksum_sha256, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
		ON CONFLICT (seed_key) DO UPDATE SET
			pack_id = EXCLUDED.pack_id,
			sticker_id = EXCLUDED.sticker_id,
			file_id = EXCLUDED.file_id,
			checksum_sha256 = EXCLUDED.checksum_sha256,
			updated_at = NOW()
	`, asset.SeedKey, asset.PackID, asset.StickerID, asset.FileID, asset.Checksum); err != nil {
		return fmt.Errorf("upsert seed registry row: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit seed sticker tx: %w", err)
	}
	return nil
}

func (s *seeder) deactivateRetiredSeedStickers(ctx context.Context, activeSeedKeys []string) error {
	tag, err := s.db.Exec(ctx, `
		UPDATE stickers s
		SET status = 'DELETED', updated_at = NOW()
		FROM sticker_seed_assets a
		WHERE a.sticker_id = s.id
		  AND NOT (a.seed_key = ANY($1::text[]))
		  AND s.status <> 'DELETED'
	`, activeSeedKeys)
	if err != nil {
		return fmt.Errorf("deactivate retired seed stickers: %w", err)
	}
	if affected := tag.RowsAffected(); affected > 0 {
		log.Printf("deactivated %d retired seed stickers", affected)
	}
	return nil
}

func (s *seeder) deactivateRetiredOfficialPacks(ctx context.Context, activePackSlugs []string) error {
	tag, err := s.db.Exec(ctx, `
		UPDATE sticker_packs p
		SET status = 'DELETED',
			cover_sticker_id = NULL,
			updated_at = NOW()
		WHERE NOT (p.slug = ANY($1::text[]))
		  AND p.status <> 'DELETED'
		  AND (
		    p.is_official = TRUE
		    OR EXISTS (
		      SELECT 1
		      FROM stickers s
		      JOIN sticker_seed_assets a ON a.sticker_id = s.id
		      WHERE s.pack_id = p.id
		    )
		  )
	`, activePackSlugs)
	if err != nil {
		return fmt.Errorf("deactivate retired official sticker packs: %w", err)
	}
	if affected := tag.RowsAffected(); affected > 0 {
		log.Printf("deactivated %d retired official sticker packs", affected)
	}
	return nil
}

func (c *fileManagerClient) uploadSticker(ctx context.Context, def stickerDefinition, body []byte, checksum string) (uuid.UUID, error) {
	if strings.TrimSpace(c.internalToken) == "" {
		return uuid.Nil, fmt.Errorf("file-manager internal service token is required")
	}

	uploadReq := map[string]any{
		"originalName": fmt.Sprintf("%s.%s", def.FallbackName, stickerFileExt),
		"contentType":  stickerContentType,
		"sizeBytes":    int64(len(body)),
		"purpose":      "CHAT_STICKER",
		"visibility":   "PUBLIC",
		"ownerType":    systemOwnerType,
		"ownerId":      systemOwnerID,
	}

	var uploadResp struct {
		FileID string `json:"fileId"`
	}
	headers := map[string]string{
		"Idempotency-Key": fmt.Sprintf("seed-default-stickers:%s:%s", def.Key, checksum),
	}
	if err := c.doJSON(ctx, http.MethodPost, "/v1/files/upload-requests", headers, uploadReq, http.StatusCreated, &uploadResp); err != nil {
		return uuid.Nil, err
	}

	fileID, err := uuid.Parse(uploadResp.FileID)
	if err != nil {
		return uuid.Nil, fmt.Errorf("parse file-manager file id: %w", err)
	}

	if err = c.doBytes(ctx, http.MethodPut, "/v1/files/"+fileID.String()+"/binary", stickerContentType, body, http.StatusNoContent); err != nil {
		return uuid.Nil, err
	}

	var completeResp struct {
		Status string `json:"status"`
	}
	if err = c.doJSON(ctx, http.MethodPost, "/v1/files/"+fileID.String()+"/complete", nil, nil, http.StatusOK, &completeResp); err != nil {
		return uuid.Nil, err
	}
	if !strings.EqualFold(completeResp.Status, "READY") {
		return uuid.Nil, fmt.Errorf("file %s completed with unexpected status %q", fileID, completeResp.Status)
	}

	bindReq := map[string]any{
		"ownerType": systemOwnerType,
		"ownerId":   systemOwnerID,
		"purpose":   "CHAT_STICKER",
		"isPrimary": false,
	}
	if err = c.doJSON(ctx, http.MethodPost, "/v1/internal/files/"+fileID.String()+"/bindings", nil, bindReq, http.StatusCreated, nil); err != nil {
		return uuid.Nil, err
	}

	return fileID, nil
}

func (c *fileManagerClient) doJSON(
	ctx context.Context,
	method string,
	path string,
	headers map[string]string,
	payload any,
	expectedStatus int,
	out any,
) error {
	var body io.Reader
	if payload != nil {
		data, err := json.Marshal(payload)
		if err != nil {
			return err
		}
		body = bytes.NewReader(data)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, body)
	if err != nil {
		return err
	}
	req.Header.Set("X-Internal-Service-Token", c.internalToken)
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != expectedStatus {
		return responseError(resp)
	}
	if out == nil {
		return nil
	}
	return json.NewDecoder(resp.Body).Decode(out)
}

func (c *fileManagerClient) doBytes(
	ctx context.Context,
	method string,
	path string,
	contentType string,
	body []byte,
	expectedStatus int,
) error {
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("X-Internal-Service-Token", c.internalToken)
	req.Header.Set("Content-Type", contentType)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != expectedStatus {
		return responseError(resp)
	}
	return nil
}

func responseError(resp *http.Response) error {
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	return fmt.Errorf("file-manager %s %s returned %d: %s", resp.Request.Method, resp.Request.URL.Path, resp.StatusCode, strings.TrimSpace(string(body)))
}

func sha256Hex(body []byte) string {
	sum := sha256.Sum256(body)
	return hex.EncodeToString(sum[:])
}

func defaultStickerDefinitions() []stickerDefinition {
	travelTitle := localized("Travel", "Путешествия", "Саяхат")
	emotionsTitle := localized("Emotions", "Эмоции", "Эмоциялар")
	foodTitle := localized("Food", "Еда", "Тамақ")
	weatherTitle := localized("Weather", "Погода", "Ауа райы")
	transportTitle := localized("Transport", "Транспорт", "Көлік")
	planningTitle := localized("Planning", "Планы", "Жоспар")
	guidesTitle := localized("Guides", "Гиды", "Гидтер")
	cultureTitle := localized("Local Culture", "Местная культура", "Жергілікті мәдениет")
	bookingsTitle := localized("Bookings", "Бронирования", "Брондау")
	safetyTitle := localized("Safety", "Безопасность", "Қауіпсіздік")
	celebrationsTitle := localized("Celebrations", "Праздники", "Мереке")
	seasonalTitle := localized("Seasonal", "Сезонное", "Маусымдық")

	packDescription := localized(
		"Original FlyFy official stickers for travel chats.",
		"Официальные оригинальные стикеры FlyFy для туристических чатов.",
		"Саяхат чаттарына арналған ресми FlyFy стикерлері.",
	)

	return []stickerDefinition{
		stickerDef("travel", 10, travelTitle, "flyfy-travel-basics", travelTitle, packDescription, "airport-sprint", "✈️", []string{"travel", "flight", "airport", "rush", "boarding"}, 10, rgba(226, 244, 255), rgba(53, 132, 228), rgba(15, 49, 92)),
		stickerDef("travel", 10, travelTitle, "flyfy-travel-basics", travelTitle, packDescription, "passport-ready", "🛂", []string{"passport", "visa", "border", "ready", "trip"}, 20, rgba(236, 232, 255), rgba(113, 82, 220), rgba(49, 39, 107)),
		stickerDef("emotions", 20, emotionsTitle, "flyfy-emotions", emotionsTitle, packDescription, "trip-excited", "🤩", []string{"excited", "wow", "happy", "trip", "emotion"}, 10, rgba(255, 241, 214), rgba(245, 177, 53), rgba(105, 70, 20)),
		stickerDef("emotions", 20, emotionsTitle, "flyfy-emotions", emotionsTitle, packDescription, "travel-tired", "😴", []string{"tired", "jetlag", "sleepy", "late", "emotion"}, 20, rgba(235, 238, 255), rgba(112, 126, 220), rgba(48, 55, 112)),
		stickerDef("food", 30, foodTitle, "flyfy-food", foodTitle, packDescription, "need-coffee", "☕", []string{"coffee", "jetlag", "morning", "tired", "airport"}, 10, rgba(247, 239, 228), rgba(142, 92, 52), rgba(77, 48, 31)),
		stickerDef("food", 30, foodTitle, "flyfy-food", foodTitle, packDescription, "street-food", "🍜", []string{"food", "street", "local", "dinner", "taste"}, 20, rgba(255, 237, 221), rgba(229, 111, 59), rgba(105, 48, 27)),
		stickerDef("weather", 40, weatherTitle, "flyfy-weather", weatherTitle, packDescription, "sunny-plan", "☀️", []string{"sun", "weather", "clear", "warm", "plan"}, 10, rgba(255, 248, 211), rgba(239, 186, 51), rgba(112, 79, 17)),
		stickerDef("weather", 40, weatherTitle, "flyfy-weather", weatherTitle, packDescription, "rainy-detour", "🌧️", []string{"rain", "weather", "detour", "umbrella", "change"}, 20, rgba(226, 237, 250), rgba(70, 130, 201), rgba(30, 61, 102)),
		stickerDef("transport", 50, transportTitle, "flyfy-transport", transportTitle, packDescription, "taxi-found", "🚕", []string{"taxi", "ride", "car", "pickup", "transport"}, 10, rgba(255, 244, 202), rgba(238, 188, 42), rgba(104, 78, 17)),
		stickerDef("transport", 50, transportTitle, "flyfy-transport", transportTitle, packDescription, "train-window", "🚆", []string{"train", "rail", "window", "route", "transport"}, 20, rgba(224, 244, 241), rgba(46, 158, 151), rgba(24, 82, 78)),
		stickerDef("planning", 60, planningTitle, "flyfy-planning", planningTitle, packDescription, "packing-mode", "🧳", []string{"packing", "luggage", "suitcase", "trip", "ready"}, 10, rgba(255, 244, 220), rgba(233, 150, 48), rgba(105, 63, 21)),
		stickerDef("planning", 60, planningTitle, "flyfy-planning", planningTitle, packDescription, "calendar-ready", "🗓️", []string{"calendar", "plan", "schedule", "date", "ready"}, 20, rgba(238, 246, 255), rgba(69, 137, 216), rgba(30, 65, 113)),
		stickerDef("guides", 70, guidesTitle, "flyfy-guides", guidesTitle, packDescription, "guide-here", "🙋", []string{"guide", "here", "tour", "meet", "host"}, 10, rgba(235, 249, 234), rgba(76, 160, 93), rgba(35, 82, 45)),
		stickerDef("guides", 70, guidesTitle, "flyfy-guides", guidesTitle, packDescription, "follow-flag", "🚩", []string{"guide", "flag", "follow", "group", "tour"}, 20, rgba(255, 235, 235), rgba(221, 75, 80), rgba(112, 33, 38)),
		stickerDef("local-culture", 80, cultureTitle, "flyfy-local-culture", cultureTitle, packDescription, "market-walk", "🏺", []string{"market", "culture", "local", "walk", "souvenir"}, 10, rgba(250, 238, 222), rgba(192, 119, 58), rgba(92, 55, 30)),
		stickerDef("local-culture", 80, cultureTitle, "flyfy-local-culture", cultureTitle, packDescription, "phrase-book", "💬", []string{"language", "phrase", "culture", "local", "hello"}, 20, rgba(235, 241, 255), rgba(92, 112, 216), rgba(42, 54, 112)),
		stickerDef("bookings", 90, bookingsTitle, "flyfy-bookings", bookingsTitle, packDescription, "ticket-confirmed", "🎫", []string{"ticket", "booking", "confirmed", "reservation", "done"}, 10, rgba(232, 249, 240), rgba(54, 173, 113), rgba(25, 86, 56)),
		stickerDef("bookings", 90, bookingsTitle, "flyfy-bookings", bookingsTitle, packDescription, "payment-done", "✅", []string{"payment", "paid", "booking", "success", "done"}, 20, rgba(229, 248, 229), rgba(51, 161, 75), rgba(24, 86, 39)),
		stickerDef("safety", 100, safetyTitle, "flyfy-safety", safetyTitle, packDescription, "safe-route", "🛡️", []string{"safe", "route", "security", "careful", "map"}, 10, rgba(229, 241, 255), rgba(58, 119, 217), rgba(27, 58, 109)),
		stickerDef("safety", 100, safetyTitle, "flyfy-safety", safetyTitle, packDescription, "help-point", "🆘", []string{"help", "support", "safety", "urgent", "point"}, 20, rgba(255, 231, 231), rgba(226, 73, 73), rgba(116, 31, 31)),
		stickerDef("celebrations", 110, celebrationsTitle, "flyfy-celebrations", celebrationsTitle, packDescription, "trip-start", "🎉", []string{"start", "party", "celebrate", "trip", "go"}, 10, rgba(255, 238, 247), rgba(213, 83, 151), rgba(102, 38, 75)),
		stickerDef("celebrations", 110, celebrationsTitle, "flyfy-celebrations", celebrationsTitle, packDescription, "group-cheers", "🥳", []string{"cheers", "group", "friends", "celebrate", "happy"}, 20, rgba(243, 235, 255), rgba(144, 92, 221), rgba(69, 42, 111)),
		stickerDef("seasonal", 120, seasonalTitle, "flyfy-seasonal", seasonalTitle, packDescription, "winter-trip", "❄️", []string{"winter", "snow", "season", "cold", "trip"}, 10, rgba(230, 247, 255), rgba(62, 154, 207), rgba(26, 79, 110)),
		stickerDef("seasonal", 120, seasonalTitle, "flyfy-seasonal", seasonalTitle, packDescription, "summer-vibes", "🌴", []string{"summer", "season", "beach", "warm", "vacation"}, 20, rgba(229, 251, 242), rgba(37, 172, 111), rgba(18, 88, 57)),
	}
}

func localized(en, ru, kk string) map[string]string {
	return map[string]string{"en": en, "ru": ru, "kk": kk}
}

func stickerDef(
	groupSlug string,
	groupOrder int,
	groupTitle map[string]string,
	packSlug string,
	packTitle map[string]string,
	packDescription map[string]string,
	key string,
	emoji string,
	keywords []string,
	sortOrder int,
	background color.RGBA,
	accent color.RGBA,
	dark color.RGBA,
) stickerDefinition {
	return stickerDefinition{
		GroupSlug:       groupSlug,
		GroupTitle:      groupTitle,
		GroupOrder:      groupOrder,
		PackSlug:        packSlug,
		PackTitle:       packTitle,
		PackDescription: packDescription,
		PackOrder:       groupOrder,
		Key:             key,
		Emoji:           emoji,
		Keywords:        keywords,
		FallbackName:    key + "-fallback",
		DurationMS:      1080,
		SortOrder:       sortOrder,
		Background:      background,
		Accent:          accent,
		Dark:            dark,
	}
}

func renderStickerAnimation(def stickerDefinition) ([]byte, error) {
	animation := &gif.GIF{LoopCount: 0}
	delay := def.DurationMS / stickerFrameCount / 10
	if delay < 4 {
		delay = 4
	}

	for frame := 0; frame < stickerFrameCount; frame++ {
		rgbaFrame := renderStickerFrame(def, frame)
		palettedFrame := image.NewPaletted(rgbaFrame.Bounds(), palette.Plan9)
		imagedraw.FloydSteinberg.Draw(
			palettedFrame,
			rgbaFrame.Bounds(),
			rgbaFrame,
			image.Point{},
		)
		animation.Image = append(animation.Image, palettedFrame)
		animation.Delay = append(animation.Delay, delay)
	}

	var buf bytes.Buffer
	if err := gif.EncodeAll(&buf, animation); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func renderStickerFrame(def stickerDefinition, frame int) *image.RGBA {
	img := image.NewRGBA(image.Rect(0, 0, stickerCanvasSize, stickerCanvasSize))
	fillCircle(img, 256, 256, 236, color.RGBA{R: def.Background.R, G: def.Background.G, B: def.Background.B, A: 255})
	fillCircle(img, 256, 256, 210, color.RGBA{R: 255, G: 255, B: 255, A: 110})
	drawMotionAccent(img, def, frame)

	scene := image.NewRGBA(img.Bounds())
	drawStickerScene(scene, def, frame)
	offsetX, offsetY := sceneMotion(def, frame)
	drawLayer(img, scene, offsetX, offsetY)
	return img
}

func sceneMotion(def stickerDefinition, frame int) (int, int) {
	phase := 2 * math.Pi * float64(frame) / float64(stickerFrameCount)
	switch def.GroupSlug {
	case "travel":
		return int(math.Cos(phase) * 18), int(math.Sin(phase*2) * 8)
	case "emotions":
		return int(math.Sin(phase*2) * 8), int(math.Sin(phase) * 20)
	case "food":
		return int(math.Sin(phase) * 7), int(math.Cos(phase) * 9)
	case "weather":
		return int(math.Sin(phase) * 6), int(math.Cos(phase*2) * 7)
	case "transport":
		return int(math.Sin(phase) * 22), int(math.Sin(phase*2) * 5)
	case "planning":
		return int(math.Sin(phase) * 8), int(math.Abs(math.Sin(phase)) * -18)
	case "guides", "local-culture":
		return int(math.Sin(phase) * 12), int(math.Cos(phase) * 8)
	case "bookings", "safety":
		return 0, int(math.Sin(phase) * 12)
	case "celebrations":
		return int(math.Sin(phase*3) * 10), int(math.Sin(phase) * 18)
	case "seasonal":
		return int(math.Cos(phase) * 10), int(math.Sin(phase) * 10)
	default:
		return int(math.Sin(phase) * 10), int(math.Cos(phase) * 8)
	}
}

func drawLayer(dst *image.RGBA, src *image.RGBA, dx int, dy int) {
	bounds := src.Bounds()
	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			c := src.RGBAAt(x, y)
			if c.A != 0 {
				setRGBA(dst, x+dx, y+dy, c)
			}
		}
	}
}

func drawMotionAccent(img *image.RGBA, def stickerDefinition, frame int) {
	phase := 2 * math.Pi * float64(frame) / float64(stickerFrameCount)
	switch def.GroupSlug {
	case "transport", "travel":
		for i := 0; i < 3; i++ {
			y := 178 + i*52 + int(math.Sin(phase+float64(i))*8)
			drawLine(img, 72, y, 156, y-18, 7, alpha(def.Accent, 90))
		}
	case "weather", "seasonal":
		for i := 0; i < 6; i++ {
			x := 92 + i*62
			y := 96 + int(math.Mod(float64(frame*18+i*31), 260))
			drawLine(img, x, y, x-14, y+28, 5, alpha(def.Accent, 95))
		}
	case "celebrations":
		for i := 0; i < 8; i++ {
			x := 90 + i*46
			y := 98 + int(math.Mod(float64(frame*24+i*37), 250))
			fillCircle(img, x, y, 7, alpha(colorForIndex(i), 170))
		}
	case "food":
		for i := 0; i < 3; i++ {
			x := 196 + i*54 + int(math.Sin(phase+float64(i))*8)
			drawLine(img, x, 144, x-10, 92, 6, alpha(def.Dark, 80))
		}
	default:
		radius := 174 + int(math.Sin(phase)*12)
		drawCircle(img, 256, 256, radius, 4, alpha(def.Accent, 70))
		drawCircle(img, 256, 256, radius-34, 3, alpha(def.Dark, 45))
	}
}

func drawStickerScene(img *image.RGBA, def stickerDefinition, frame int) {
	switch def.Key {
	case "airport-sprint":
		drawPlane(img, def.Accent, def.Dark)
		drawLine(img, 104, 354, 246, 354, 10, alpha(def.Dark, 90))
		drawLine(img, 138, 382, 214, 382, 8, alpha(def.Dark, 70))
	case "lost-but-happy":
		drawMap(img, def.Accent, def.Dark)
		drawPin(img, 318, 214, 74, rgba(238, 85, 85), def.Dark)
	case "passport-ready":
		drawPassport(img, def.Accent, def.Dark)
	case "trip-excited":
		drawExcitedFace(img, def.Accent, def.Dark, frame)
	case "travel-tired":
		drawSleepyFace(img, def.Accent, def.Dark, frame)
	case "packing-mode":
		drawSuitcase(img, def.Accent, def.Dark)
	case "street-food":
		drawNoodleBowl(img, def.Accent, def.Dark, frame)
	case "sunny-plan":
		drawSunnyPlan(img, def.Accent, def.Dark, frame)
	case "rainy-detour":
		drawUmbrella(img, def.Accent, def.Dark, frame)
	case "taxi-found":
		drawTaxi(img, def.Accent, def.Dark, frame)
	case "train-window":
		drawTrain(img, def.Accent, def.Dark, frame)
	case "calendar-ready":
		drawCalendar(img, def.Accent, def.Dark)
	case "guide-here":
		drawGuideHere(img, def.Accent, def.Dark, frame)
	case "follow-flag":
		drawFlag(img, def.Accent, def.Dark, frame)
	case "market-walk":
		drawMarket(img, def.Accent, def.Dark, frame)
	case "phrase-book":
		drawPhraseBook(img, def.Accent, def.Dark, frame)
	case "ticket-confirmed":
		drawTicket(img, def.Accent, def.Dark)
	case "payment-done":
		drawPaymentDone(img, def.Accent, def.Dark, frame)
	case "safe-route":
		drawShieldRoute(img, def.Accent, def.Dark, frame)
	case "help-point":
		drawHelpPoint(img, def.Accent, def.Dark, frame)
	case "trip-start":
		drawTripStart(img, def.Accent, def.Dark, frame)
	case "group-cheers":
		drawGroupCheers(img, def.Accent, def.Dark, frame)
	case "winter-trip":
		drawWinterTrip(img, def.Accent, def.Dark, frame)
	case "summer-vibes":
		drawSummerVibes(img, def.Accent, def.Dark, frame)
	case "delayed-again":
		drawClock(img, def.Accent, def.Dark)
		drawLine(img, 112, 382, 400, 382, 12, alpha(def.Dark, 80))
	case "need-coffee":
		drawCoffee(img, def.Accent, def.Dark)
	case "beach-please":
		drawBeach(img, def.Accent, def.Dark)
	case "mountain-call":
		drawMountains(img, def.Accent, def.Dark)
	case "send-location":
		drawRoute(img, def.Accent, def.Dark)
		drawPin(img, 270, 178, 68, rgba(238, 85, 85), def.Dark)
	case "travel-camera":
		drawCamera(img, def.Accent, def.Dark)
	case "globe-mode":
		drawGlobe(img, def.Accent, def.Dark)
	case "camp-vibes":
		drawTent(img, def.Accent, def.Dark)
	default:
		drawGlobeAt(img, 256, 226, 86, def.Accent, def.Dark)
		drawLine(img, 174, 350, 338, 350, 12, alpha(def.Dark, 90))
		drawLine(img, 206, 382, 306, 382, 10, alpha(def.Dark, 70))
	}
}

func drawPlane(img *image.RGBA, accent, dark color.RGBA) {
	fillPolygon(img, []image.Point{{106, 280}, {406, 168}, {344, 248}, {420, 288}, {388, 324}, {308, 304}, {242, 386}, {206, 370}, {242, 304}}, accent)
	fillPolygon(img, []image.Point{{126, 276}, {308, 238}, {236, 292}}, rgba(255, 255, 255))
	drawLine(img, 108, 280, 408, 168, 8, dark)
}

func drawMap(img *image.RGBA, accent, dark color.RGBA) {
	fillPolygon(img, []image.Point{{118, 166}, {224, 132}, {320, 164}, {412, 132}, {412, 342}, {318, 382}, {222, 346}, {118, 382}}, rgba(255, 255, 255))
	drawLine(img, 224, 132, 222, 346, 8, alpha(dark, 110))
	drawLine(img, 320, 164, 318, 382, 8, alpha(dark, 110))
	drawLine(img, 148, 246, 208, 230, 8, accent)
	drawLine(img, 248, 270, 300, 288, 8, accent)
	drawLine(img, 340, 234, 390, 214, 8, accent)
}

func drawPin(img *image.RGBA, cx, cy, r int, accent, dark color.RGBA) {
	fillCircle(img, cx, cy, r, accent)
	fillPolygon(img, []image.Point{{cx - r/2, cy + r/2}, {cx + r/2, cy + r/2}, {cx, cy + r + 58}}, accent)
	fillCircle(img, cx, cy, r/3, rgba(255, 255, 255))
	drawCircle(img, cx, cy, r, 8, dark)
}

func drawPassport(img *image.RGBA, accent, dark color.RGBA) {
	fillRect(img, 166, 112, 346, 400, accent)
	fillRect(img, 190, 138, 322, 374, alpha(rgba(255, 255, 255), 45))
	drawLine(img, 166, 112, 346, 112, 10, dark)
	drawLine(img, 166, 400, 346, 400, 10, dark)
	drawLine(img, 166, 112, 166, 400, 10, dark)
	drawLine(img, 346, 112, 346, 400, 10, dark)
	drawGlobeAt(img, 256, 238, 62, rgba(255, 220, 91), dark)
	drawLine(img, 208, 328, 304, 328, 10, rgba(255, 220, 91))
	drawLine(img, 214, 356, 298, 356, 8, rgba(255, 220, 91))
}

func drawSuitcase(img *image.RGBA, accent, dark color.RGBA) {
	drawLine(img, 204, 154, 204, 112, 12, dark)
	drawLine(img, 204, 112, 308, 112, 12, dark)
	drawLine(img, 308, 112, 308, 154, 12, dark)
	fillRect(img, 128, 164, 384, 370, accent)
	fillRect(img, 158, 196, 354, 340, alpha(rgba(255, 255, 255), 55))
	drawLine(img, 128, 164, 384, 164, 12, dark)
	drawLine(img, 128, 370, 384, 370, 12, dark)
	drawLine(img, 128, 164, 128, 370, 12, dark)
	drawLine(img, 384, 164, 384, 370, 12, dark)
	drawLine(img, 196, 178, 196, 358, 8, dark)
	drawLine(img, 316, 178, 316, 358, 8, dark)
	fillCircle(img, 174, 390, 18, dark)
	fillCircle(img, 338, 390, 18, dark)
}

func drawClock(img *image.RGBA, accent, dark color.RGBA) {
	fillCircle(img, 256, 244, 124, rgba(255, 255, 255))
	drawCircle(img, 256, 244, 124, 14, accent)
	drawLine(img, 256, 244, 256, 172, 12, dark)
	drawLine(img, 256, 244, 316, 284, 12, dark)
	fillCircle(img, 256, 244, 14, dark)
	drawLine(img, 178, 116, 136, 84, 12, accent)
	drawLine(img, 334, 116, 376, 84, 12, accent)
}

func drawCoffee(img *image.RGBA, accent, dark color.RGBA) {
	fillRect(img, 152, 196, 330, 342, accent)
	fillRect(img, 174, 216, 308, 322, rgba(255, 255, 255))
	drawCircle(img, 342, 260, 52, 12, accent)
	drawLine(img, 172, 372, 350, 372, 14, dark)
	drawLine(img, 198, 154, 190, 112, 8, alpha(dark, 130))
	drawLine(img, 256, 154, 248, 112, 8, alpha(dark, 130))
	drawLine(img, 314, 154, 306, 112, 8, alpha(dark, 130))
}

func drawBeach(img *image.RGBA, accent, dark color.RGBA) {
	fillCircle(img, 372, 124, 44, rgba(255, 204, 79))
	fillPolygon(img, []image.Point{{124, 238}, {282, 140}, {380, 266}}, accent)
	drawLine(img, 282, 140, 228, 374, 10, dark)
	fillPolygon(img, []image.Point{{112, 386}, {400, 386}, {432, 432}, {80, 432}}, rgba(246, 202, 113))
	drawLine(img, 104, 334, 168, 318, 10, rgba(31, 153, 172))
	drawLine(img, 188, 334, 256, 318, 10, rgba(31, 153, 172))
	drawLine(img, 276, 334, 344, 318, 10, rgba(31, 153, 172))
}

func drawMountains(img *image.RGBA, accent, dark color.RGBA) {
	fillPolygon(img, []image.Point{{78, 382}, {218, 138}, {358, 382}}, accent)
	fillPolygon(img, []image.Point{{178, 382}, {318, 190}, {438, 382}}, rgba(88, 168, 116))
	fillPolygon(img, []image.Point{{190, 188}, {218, 138}, {252, 196}, {226, 184}}, rgba(255, 255, 255))
	fillPolygon(img, []image.Point{{292, 226}, {318, 190}, {344, 232}, {320, 222}}, rgba(255, 255, 255))
	drawLine(img, 82, 382, 438, 382, 14, dark)
	fillCircle(img, 374, 136, 34, rgba(255, 204, 79))
}

func drawRoute(img *image.RGBA, accent, dark color.RGBA) {
	drawLine(img, 116, 356, 170, 294, 10, accent)
	drawLine(img, 170, 294, 240, 328, 10, accent)
	drawLine(img, 240, 328, 322, 276, 10, accent)
	drawLine(img, 322, 276, 398, 330, 10, accent)
	fillCircle(img, 116, 356, 22, dark)
	fillCircle(img, 398, 330, 22, dark)
}

func drawCamera(img *image.RGBA, accent, dark color.RGBA) {
	fillRect(img, 118, 176, 394, 354, accent)
	fillRect(img, 166, 144, 256, 184, accent)
	fillRect(img, 308, 154, 368, 184, rgba(255, 255, 255))
	drawLine(img, 118, 176, 394, 176, 12, dark)
	drawLine(img, 118, 354, 394, 354, 12, dark)
	drawLine(img, 118, 176, 118, 354, 12, dark)
	drawLine(img, 394, 176, 394, 354, 12, dark)
	fillCircle(img, 256, 268, 76, rgba(255, 255, 255))
	drawCircle(img, 256, 268, 76, 12, dark)
	fillCircle(img, 256, 268, 36, alpha(dark, 200))
}

func drawGlobe(img *image.RGBA, accent, dark color.RGBA) {
	drawGlobeAt(img, 256, 252, 138, accent, dark)
	drawLine(img, 136, 392, 376, 392, 12, dark)
	drawLine(img, 256, 390, 256, 424, 12, dark)
}

func drawGlobeAt(img *image.RGBA, cx, cy, r int, accent, dark color.RGBA) {
	fillCircle(img, cx, cy, r, accent)
	drawCircle(img, cx, cy, r, 10, dark)
	drawCircle(img, cx, cy, r*2/3, 7, alpha(dark, 120))
	drawLine(img, cx-r+14, cy, cx+r-14, cy, 8, alpha(dark, 120))
	drawLine(img, cx, cy-r+14, cx, cy+r-14, 8, alpha(dark, 120))
	fillPolygon(img, []image.Point{{cx - 58, cy - 40}, {cx - 18, cy - 70}, {cx + 8, cy - 36}, {cx - 18, cy - 12}}, rgba(111, 195, 117))
	fillPolygon(img, []image.Point{{cx + 34, cy + 24}, {cx + 82, cy + 34}, {cx + 46, cy + 82}, {cx + 10, cy + 58}}, rgba(111, 195, 117))
}

func drawTent(img *image.RGBA, accent, dark color.RGBA) {
	fillPolygon(img, []image.Point{{110, 380}, {258, 142}, {420, 380}}, accent)
	fillPolygon(img, []image.Point{{236, 380}, {292, 242}, {420, 380}}, alpha(dark, 120))
	fillPolygon(img, []image.Point{{214, 380}, {258, 274}, {304, 380}}, rgba(255, 244, 220))
	drawLine(img, 110, 380, 420, 380, 14, dark)
	drawLine(img, 258, 142, 420, 380, 10, dark)
	drawLine(img, 258, 142, 110, 380, 10, dark)
	fillCircle(img, 376, 118, 32, rgba(255, 204, 79))
}

func drawExcitedFace(img *image.RGBA, accent, dark color.RGBA, frame int) {
	shine := 24 + int(math.Sin(framePhase(frame))*8)
	fillCircle(img, 256, 250, 132, rgba(255, 211, 89))
	drawCircle(img, 256, 250, 132, 12, dark)
	drawStar(img, 206, 212, 34, accent)
	drawStar(img, 306, 212, 34, accent)
	fillCircle(img, 206, 212, shine/3, rgba(255, 255, 255))
	fillCircle(img, 306, 212, shine/3, rgba(255, 255, 255))
	drawLine(img, 204, 304, 256, 336, 14, dark)
	drawLine(img, 256, 336, 312, 304, 14, dark)
	fillCircle(img, 374, 148, 18+shine/8, accent)
	fillCircle(img, 138, 346, 14+shine/10, alpha(accent, 190))
}

func drawSleepyFace(img *image.RGBA, accent, dark color.RGBA, frame int) {
	offset := int(math.Sin(framePhase(frame)) * 10)
	fillCircle(img, 244, 260, 124, rgba(246, 222, 154))
	drawCircle(img, 244, 260, 124, 12, dark)
	drawLine(img, 182, 238, 226, 238, 10, dark)
	drawLine(img, 274, 238, 318, 238, 10, dark)
	drawLine(img, 222, 316, 270, 324, 10, alpha(dark, 180))
	drawLine(img, 328+offset, 148-offset, 374+offset, 148-offset, 8, accent)
	drawLine(img, 374+offset, 148-offset, 334+offset, 198-offset, 8, accent)
	drawLine(img, 334+offset, 198-offset, 386+offset, 198-offset, 8, accent)
	drawLine(img, 362+offset/2, 92-offset, 402+offset/2, 92-offset, 7, alpha(accent, 150))
	drawLine(img, 402+offset/2, 92-offset, 366+offset/2, 134-offset, 7, alpha(accent, 150))
}

func drawNoodleBowl(img *image.RGBA, accent, dark color.RGBA, frame int) {
	wave := int(math.Sin(framePhase(frame)) * 10)
	fillCircle(img, 256, 300, 134, rgba(255, 255, 255))
	fillRect(img, 126, 278, 386, 374, accent)
	fillPolygon(img, []image.Point{{146, 374}, {366, 374}, {324, 420}, {188, 420}}, accent)
	drawLine(img, 126, 278, 386, 278, 12, dark)
	drawLine(img, 164, 402, 348, 402, 10, dark)
	for i := 0; i < 4; i++ {
		x := 172 + i*48
		drawLine(img, x, 276, x+28, 232+wave, 7, rgba(238, 181, 72))
	}
	drawLine(img, 160, 202, 362, 132, 9, dark)
	drawLine(img, 172, 224, 374, 154, 9, dark)
	fillCircle(img, 206, 316, 16, rgba(94, 174, 90))
	fillCircle(img, 302, 320, 16, rgba(238, 96, 76))
}

func drawSunnyPlan(img *image.RGBA, accent, dark color.RGBA, frame int) {
	pulse := 8 + int(math.Sin(framePhase(frame))*5)
	fillCircle(img, 334, 148, 60+pulse, rgba(255, 205, 72))
	for i := 0; i < 8; i++ {
		a := 2 * math.Pi * float64(i) / 8
		drawLine(img, 334+int(math.Cos(a)*84), 148+int(math.Sin(a)*84), 334+int(math.Cos(a)*112), 148+int(math.Sin(a)*112), 8, rgba(255, 205, 72))
	}
	fillRect(img, 142, 184, 348, 386, rgba(255, 255, 255))
	fillRect(img, 142, 184, 348, 232, accent)
	drawLine(img, 142, 184, 348, 184, 10, dark)
	drawLine(img, 142, 386, 348, 386, 10, dark)
	drawLine(img, 142, 184, 142, 386, 10, dark)
	drawLine(img, 348, 184, 348, 386, 10, dark)
	drawCheck(img, 196, 310, 78, rgba(73, 172, 98), dark)
}

func drawUmbrella(img *image.RGBA, accent, dark color.RGBA, frame int) {
	sway := int(math.Sin(framePhase(frame)) * 14)
	fillPolygon(img, []image.Point{{108 + sway, 246}, {256 + sway, 118}, {404 + sway, 246}}, accent)
	fillPolygon(img, []image.Point{{108 + sway, 246}, {180 + sway, 218}, {256 + sway, 246}, {334 + sway, 218}, {404 + sway, 246}}, alpha(rgba(255, 255, 255), 70))
	drawLine(img, 256+sway, 246, 256+sway, 370, 10, dark)
	drawLine(img, 256+sway, 370, 306+sway, 370, 10, dark)
	drawLine(img, 108+sway, 246, 404+sway, 246, 10, dark)
	for i := 0; i < 7; i++ {
		x := 124 + i*42 - sway/2
		y := 104 + int(math.Mod(float64(frame*22+i*33), 178))
		drawLine(img, x, y, x-12, y+28, 5, rgba(76, 148, 221))
	}
}

func drawTaxi(img *image.RGBA, accent, dark color.RGBA, frame int) {
	wheel := 16 + int(math.Abs(math.Sin(framePhase(frame))*5))
	fillRect(img, 118, 226, 394, 332, accent)
	fillPolygon(img, []image.Point{{174, 226}, {220, 162}, {318, 162}, {362, 226}}, accent)
	fillRect(img, 216, 174, 266, 222, rgba(230, 247, 255))
	fillRect(img, 278, 174, 328, 222, rgba(230, 247, 255))
	fillRect(img, 230, 132, 292, 162, rgba(255, 255, 255))
	drawLine(img, 118, 332, 394, 332, 12, dark)
	drawLine(img, 138, 226, 374, 226, 10, dark)
	fillCircle(img, 176, 342, 28, dark)
	fillCircle(img, 336, 342, 28, dark)
	fillCircle(img, 176, 342, wheel, rgba(255, 255, 255))
	fillCircle(img, 336, 342, wheel, rgba(255, 255, 255))
	drawLine(img, 78, 276, 132, 260, 7, alpha(dark, 85))
}

func drawTrain(img *image.RGBA, accent, dark color.RGBA, frame int) {
	light := 20 + int(math.Sin(framePhase(frame))*7)
	fillRect(img, 136, 126, 376, 356, accent)
	fillRect(img, 168, 164, 344, 250, rgba(232, 250, 255))
	drawLine(img, 136, 126, 376, 126, 12, dark)
	drawLine(img, 136, 356, 376, 356, 12, dark)
	drawLine(img, 136, 126, 136, 356, 12, dark)
	drawLine(img, 376, 126, 376, 356, 12, dark)
	drawLine(img, 256, 164, 256, 250, 8, dark)
	fillCircle(img, 198, 300, light, rgba(255, 230, 102))
	fillCircle(img, 314, 300, light, rgba(255, 230, 102))
	drawLine(img, 104, 400, 408, 400, 12, dark)
	drawLine(img, 128, 430, 384, 430, 10, alpha(dark, 120))
}

func drawCalendar(img *image.RGBA, accent, dark color.RGBA) {
	fillRect(img, 148, 126, 364, 388, rgba(255, 255, 255))
	fillRect(img, 148, 126, 364, 186, accent)
	drawLine(img, 148, 126, 364, 126, 10, dark)
	drawLine(img, 148, 388, 364, 388, 10, dark)
	drawLine(img, 148, 126, 148, 388, 10, dark)
	drawLine(img, 364, 126, 364, 388, 10, dark)
	for i := 0; i < 3; i++ {
		for j := 0; j < 3; j++ {
			fillCircle(img, 198+i*58, 232+j*46, 14, alpha(accent, 155))
		}
	}
	drawCheck(img, 232, 332, 70, rgba(73, 172, 98), dark)
}

func drawGuideHere(img *image.RGBA, accent, dark color.RGBA, frame int) {
	wave := int(math.Sin(framePhase(frame)) * 18)
	fillCircle(img, 246, 166, 54, rgba(246, 198, 142))
	drawCircle(img, 246, 166, 54, 9, dark)
	fillRect(img, 184, 226, 308, 370, accent)
	drawLine(img, 184, 226, 308, 226, 10, dark)
	drawLine(img, 184, 370, 308, 370, 10, dark)
	drawLine(img, 184, 226, 184, 370, 10, dark)
	drawLine(img, 308, 226, 308, 370, 10, dark)
	drawLine(img, 176, 244, 112, 190+wave, 12, dark)
	drawLine(img, 316, 246, 390, 198-wave/2, 12, dark)
	drawLine(img, 390, 198-wave/2, 420, 228-wave/2, 10, accent)
	fillCircle(img, 226, 156, 7, dark)
	fillCircle(img, 266, 156, 7, dark)
	drawLine(img, 228, 184, 270, 184, 8, dark)
}

func drawFlag(img *image.RGBA, accent, dark color.RGBA, frame int) {
	wave := int(math.Sin(framePhase(frame)) * 18)
	drawLine(img, 160, 118, 160, 402, 12, dark)
	fillPolygon(img, []image.Point{{160, 126}, {366, 158 + wave}, {324, 238 - wave/2}, {160, 216}}, accent)
	drawLine(img, 160, 126, 366, 158+wave, 8, dark)
	drawLine(img, 160, 216, 324, 238-wave/2, 8, dark)
	fillCircle(img, 160, 112, 18, accent)
	drawLine(img, 112, 402, 246, 402, 12, dark)
}

func drawMarket(img *image.RGBA, accent, dark color.RGBA, frame int) {
	bounce := int(math.Abs(math.Sin(framePhase(frame))) * 14)
	fillRect(img, 126, 206, 386, 388, rgba(255, 255, 255))
	fillPolygon(img, []image.Point{{106, 206}, {150, 132}, {362, 132}, {406, 206}}, accent)
	for i := 0; i < 4; i++ {
		x := 126 + i*64
		fillRect(img, x, 206, x+38, 250+bounce/3, alpha(rgba(255, 255, 255), 115))
	}
	drawLine(img, 106, 206, 406, 206, 10, dark)
	drawLine(img, 126, 388, 386, 388, 10, dark)
	fillCircle(img, 202, 310-bounce, 24, rgba(238, 96, 76))
	fillCircle(img, 256, 318-bounce/2, 24, rgba(76, 170, 94))
	fillCircle(img, 310, 310-bounce, 24, rgba(244, 184, 65))
}

func drawPhraseBook(img *image.RGBA, accent, dark color.RGBA, frame int) {
	pop := int(math.Sin(framePhase(frame))*8 + 8)
	fillRect(img, 138, 166, 296, 378, accent)
	fillRect(img, 164, 194, 276, 350, rgba(255, 255, 255))
	drawLine(img, 138, 166, 296, 166, 10, dark)
	drawLine(img, 138, 378, 296, 378, 10, dark)
	drawLine(img, 138, 166, 138, 378, 10, dark)
	drawLine(img, 296, 166, 296, 378, 10, dark)
	fillCircle(img, 346, 180, 62+pop, rgba(255, 255, 255))
	fillPolygon(img, []image.Point{{320, 228}, {344, 264}, {360, 222}}, rgba(255, 255, 255))
	drawCircle(img, 346, 180, 62+pop, 8, dark)
	drawLine(img, 314, 178, 378, 178, 7, accent)
	drawLine(img, 326, 202, 366, 202, 6, accent)
}

func drawTicket(img *image.RGBA, accent, dark color.RGBA) {
	fillPolygon(img, []image.Point{{126, 196}, {364, 148}, {400, 322}, {162, 370}}, accent)
	drawLine(img, 126, 196, 364, 148, 10, dark)
	drawLine(img, 364, 148, 400, 322, 10, dark)
	drawLine(img, 400, 322, 162, 370, 10, dark)
	drawLine(img, 162, 370, 126, 196, 10, dark)
	drawLine(img, 244, 174, 280, 344, 7, alpha(dark, 120))
	drawCheck(img, 186, 280, 82, rgba(255, 255, 255), dark)
}

func drawPaymentDone(img *image.RGBA, accent, dark color.RGBA, frame int) {
	pulse := 8 + int(math.Sin(framePhase(frame))*5)
	fillCircle(img, 256, 252, 132+pulse, rgba(238, 252, 235))
	drawCircle(img, 256, 252, 132+pulse, 10, accent)
	drawCheck(img, 194, 272, 132, accent, dark)
	fillRect(img, 170, 140, 342, 212, rgba(255, 255, 255))
	drawLine(img, 170, 140, 342, 140, 8, dark)
	drawLine(img, 170, 212, 342, 212, 8, dark)
	drawLine(img, 202, 176, 310, 176, 8, alpha(dark, 130))
}

func drawShieldRoute(img *image.RGBA, accent, dark color.RGBA, frame int) {
	pulse := int(math.Sin(framePhase(frame))*9 + 9)
	fillPolygon(img, []image.Point{{256, 106}, {372, 154}, {352, 310}, {256, 414}, {160, 310}, {140, 154}}, accent)
	fillPolygon(img, []image.Point{{256, 144}, {326, 174}, {312, 290}, {256, 354}, {200, 290}, {186, 174}}, rgba(255, 255, 255))
	drawLine(img, 256, 106, 372, 154, 10, dark)
	drawLine(img, 140, 154, 256, 106, 10, dark)
	drawLine(img, 160, 310, 256, 414, 10, dark)
	drawLine(img, 352, 310, 256, 414, 10, dark)
	drawLine(img, 198, 282, 242, 244+pulse, 8, accent)
	drawLine(img, 242, 244+pulse, 314, 282, 8, accent)
	fillCircle(img, 198, 282, 13, dark)
	fillCircle(img, 314, 282, 13, dark)
}

func drawHelpPoint(img *image.RGBA, accent, dark color.RGBA, frame int) {
	pulse := 8 + int(math.Sin(framePhase(frame))*6)
	fillCircle(img, 256, 250, 132+pulse, rgba(255, 255, 255))
	drawCircle(img, 256, 250, 132+pulse, 12, accent)
	drawLine(img, 256, 172, 256, 316, 28, accent)
	drawLine(img, 184, 244, 328, 244, 28, accent)
	drawLine(img, 174, 376, 338, 376, 12, dark)
	fillCircle(img, 256, 250, 26, rgba(255, 255, 255))
	drawCircle(img, 256, 250, 132+pulse, 6, dark)
}

func drawTripStart(img *image.RGBA, accent, dark color.RGBA, frame int) {
	flame := int(math.Sin(framePhase(frame))*9 + 18)
	fillPolygon(img, []image.Point{{218, 354}, {256, 116}, {294, 354}}, accent)
	fillPolygon(img, []image.Point{{218, 354}, {256, 404 + flame}, {294, 354}}, rgba(255, 184, 62))
	fillCircle(img, 256, 242, 42, rgba(255, 255, 255))
	drawCircle(img, 256, 242, 42, 8, dark)
	drawLine(img, 218, 354, 256, 116, 10, dark)
	drawLine(img, 294, 354, 256, 116, 10, dark)
	for i := 0; i < 6; i++ {
		drawStar(img, 110+i*58, 138+int(math.Mod(float64(i*31+frame*11), 170)), 16, colorForIndex(i))
	}
}

func drawGroupCheers(img *image.RGBA, accent, dark color.RGBA, frame int) {
	tilt := int(math.Sin(framePhase(frame)) * 14)
	drawLine(img, 208-tilt, 184, 244-tilt, 350, 12, dark)
	drawLine(img, 320+tilt, 184, 284+tilt, 350, 12, dark)
	fillPolygon(img, []image.Point{{168 - tilt, 154}, {238 - tilt, 154}, {250 - tilt, 236}, {188 - tilt, 236}}, accent)
	fillPolygon(img, []image.Point{{274 + tilt, 154}, {344 + tilt, 154}, {324 + tilt, 236}, {262 + tilt, 236}}, rgba(255, 205, 91))
	drawLine(img, 238-tilt, 154, 274+tilt, 154, 9, dark)
	fillCircle(img, 256, 112, 16, colorForIndex(frame))
	fillCircle(img, 360, 294, 12, colorForIndex(frame+2))
	fillCircle(img, 130, 292, 12, colorForIndex(frame+4))
}

func drawWinterTrip(img *image.RGBA, accent, dark color.RGBA, frame int) {
	shift := int(math.Sin(framePhase(frame)) * 8)
	fillCircle(img, 256, 246, 118, rgba(255, 255, 255))
	drawCircle(img, 256, 246, 118, 10, accent)
	drawMountains(img, alpha(accent, 190), dark)
	fillRect(img, 144, 348+shift, 368, 390+shift, rgba(245, 250, 255))
	for i := 0; i < 7; i++ {
		x := 112 + i*46
		y := 112 + int(math.Mod(float64(frame*17+i*29), 210))
		drawSnowflake(img, x, y, 12, accent)
	}
}

func drawSummerVibes(img *image.RGBA, accent, dark color.RGBA, frame int) {
	sway := int(math.Sin(framePhase(frame)) * 18)
	fillCircle(img, 358, 128, 48, rgba(255, 207, 73))
	fillPolygon(img, []image.Point{{118, 388}, {402, 388}, {438, 430}, {82, 430}}, rgba(246, 202, 113))
	drawLine(img, 250, 386, 286+sway, 154, 14, dark)
	fillPolygon(img, []image.Point{{286 + sway, 154}, {206 + sway, 186}, {270 + sway, 208}}, accent)
	fillPolygon(img, []image.Point{{286 + sway, 154}, {362 + sway, 184}, {300 + sway, 210}}, accent)
	fillPolygon(img, []image.Point{{286 + sway, 154}, {258 + sway, 82}, {314 + sway, 128}}, accent)
	drawLine(img, 112, 328, 182, 314, 10, rgba(35, 158, 179))
	drawLine(img, 206, 330, 284, 314, 10, rgba(35, 158, 179))
	drawLine(img, 308, 328, 386, 312, 10, rgba(35, 158, 179))
}

func drawCheck(img *image.RGBA, x int, y int, size int, accent color.RGBA, dark color.RGBA) {
	drawLine(img, x, y, x+size/3, y+size/3, size/9, dark)
	drawLine(img, x+size/3, y+size/3, x+size, y-size/2, size/9, dark)
	drawLine(img, x+2, y-2, x+size/3, y+size/3-2, size/14, accent)
	drawLine(img, x+size/3, y+size/3-2, x+size-2, y-size/2-2, size/14, accent)
}

func drawStar(img *image.RGBA, cx int, cy int, r int, c color.RGBA) {
	points := make([]image.Point, 0, 10)
	for i := 0; i < 10; i++ {
		radius := r
		if i%2 == 1 {
			radius = r / 2
		}
		angle := -math.Pi/2 + float64(i)*math.Pi/5
		points = append(points, image.Point{
			X: cx + int(math.Cos(angle)*float64(radius)),
			Y: cy + int(math.Sin(angle)*float64(radius)),
		})
	}
	fillPolygon(img, points, c)
}

func drawSnowflake(img *image.RGBA, cx int, cy int, r int, c color.RGBA) {
	drawLine(img, cx-r, cy, cx+r, cy, 4, c)
	drawLine(img, cx, cy-r, cx, cy+r, 4, c)
	drawLine(img, cx-r*2/3, cy-r*2/3, cx+r*2/3, cy+r*2/3, 4, c)
	drawLine(img, cx-r*2/3, cy+r*2/3, cx+r*2/3, cy-r*2/3, 4, c)
}

func framePhase(frame int) float64 {
	return 2 * math.Pi * float64(frame) / float64(stickerFrameCount)
}

func colorForIndex(i int) color.RGBA {
	colors := []color.RGBA{
		rgba(238, 85, 85),
		rgba(245, 177, 53),
		rgba(76, 170, 94),
		rgba(53, 132, 228),
		rgba(144, 92, 221),
		rgba(213, 83, 151),
	}
	return colors[i%len(colors)]
}

func fillRect(img *image.RGBA, x1, y1, x2, y2 int, c color.RGBA) {
	for y := y1; y < y2; y++ {
		for x := x1; x < x2; x++ {
			setRGBA(img, x, y, c)
		}
	}
}

func fillCircle(img *image.RGBA, cx, cy, r int, c color.RGBA) {
	r2 := r * r
	for y := cy - r; y <= cy+r; y++ {
		for x := cx - r; x <= cx+r; x++ {
			dx, dy := x-cx, y-cy
			if dx*dx+dy*dy <= r2 {
				setRGBA(img, x, y, c)
			}
		}
	}
}

func drawCircle(img *image.RGBA, cx, cy, r, width int, c color.RGBA) {
	outer := r * r
	innerR := r - width
	if innerR < 0 {
		innerR = 0
	}
	inner := innerR * innerR
	for y := cy - r; y <= cy+r; y++ {
		for x := cx - r; x <= cx+r; x++ {
			dx, dy := x-cx, y-cy
			d := dx*dx + dy*dy
			if d <= outer && d >= inner {
				setRGBA(img, x, y, c)
			}
		}
	}
}

func drawLine(img *image.RGBA, x1, y1, x2, y2, width int, c color.RGBA) {
	steps := int(math.Hypot(float64(x2-x1), float64(y2-y1)))
	if steps <= 0 {
		fillCircle(img, x1, y1, width/2, c)
		return
	}
	for i := 0; i <= steps; i++ {
		t := float64(i) / float64(steps)
		x := int(math.Round(float64(x1) + (float64(x2-x1) * t)))
		y := int(math.Round(float64(y1) + (float64(y2-y1) * t)))
		fillCircle(img, x, y, width/2, c)
	}
}

func fillPolygon(img *image.RGBA, points []image.Point, c color.RGBA) {
	if len(points) < 3 {
		return
	}
	minX, maxX := points[0].X, points[0].X
	minY, maxY := points[0].Y, points[0].Y
	for _, p := range points[1:] {
		if p.X < minX {
			minX = p.X
		}
		if p.X > maxX {
			maxX = p.X
		}
		if p.Y < minY {
			minY = p.Y
		}
		if p.Y > maxY {
			maxY = p.Y
		}
	}
	for y := minY; y <= maxY; y++ {
		for x := minX; x <= maxX; x++ {
			if pointInPolygon(x, y, points) {
				setRGBA(img, x, y, c)
			}
		}
	}
}

func pointInPolygon(x, y int, points []image.Point) bool {
	inside := false
	j := len(points) - 1
	for i := range points {
		pi, pj := points[i], points[j]
		intersects := (pi.Y > y) != (pj.Y > y) &&
			x < (pj.X-pi.X)*(y-pi.Y)/(pj.Y-pi.Y)+pi.X
		if intersects {
			inside = !inside
		}
		j = i
	}
	return inside
}

func setRGBA(img *image.RGBA, x, y int, c color.RGBA) {
	if x < 0 || y < 0 || x >= img.Bounds().Dx() || y >= img.Bounds().Dy() || c.A == 0 {
		return
	}
	if c.A == 255 {
		img.SetRGBA(x, y, c)
		return
	}

	dst := img.RGBAAt(x, y)
	srcA := float64(c.A) / 255
	dstA := float64(dst.A) / 255
	outA := srcA + dstA*(1-srcA)
	if outA == 0 {
		return
	}

	blend := func(src, dst uint8) uint8 {
		value := (float64(src)*srcA + float64(dst)*dstA*(1-srcA)) / outA
		return uint8(math.Round(value))
	}

	img.SetRGBA(x, y, color.RGBA{
		R: blend(c.R, dst.R),
		G: blend(c.G, dst.G),
		B: blend(c.B, dst.B),
		A: uint8(math.Round(outA * 255)),
	})
}

func rgba(r, g, b uint8) color.RGBA {
	return color.RGBA{R: r, G: g, B: b, A: 255}
}

func alpha(c color.RGBA, a uint8) color.RGBA {
	c.A = a
	return c
}

func init() {
	log.SetOutput(os.Stdout)
	log.SetFlags(log.LstdFlags | log.LUTC | log.Lmsgprefix)
	log.SetPrefix("seed-default-stickers ")
}
