package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestCreatePlaceRequiresPlaceManagePermission(t *testing.T) {
	t.Parallel()

	uc := NewPlaceContentUseCase(&placeAdminClientStub{}, &fileUploadClientStub{}, &placeAuditRepoStub{}, PlaceContentConfig{})
	_, err := uc.CreatePlace(context.Background(), &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{enum.PermissionDashboardRead},
	}, model.PlaceInput{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("CreatePlace() error = %v, want ErrPermissionDenied", err)
	}
}

func TestStartMediaBackfillRequiresPlaceManagePermission(t *testing.T) {
	t.Parallel()

	uc := NewPlaceContentUseCase(&placeAdminClientStub{}, &fileUploadClientStub{}, nil, PlaceContentConfig{})
	_, err := uc.StartMediaBackfill(context.Background(), &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{enum.PermissionDashboardRead},
	}, "KZ", RequestMetadata{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("StartMediaBackfill() error = %v, want ErrPermissionDenied", err)
	}
}

func TestStartMediaBackfillRequiresSuperAdmin(t *testing.T) {
	t.Parallel()

	client := &placeAdminClientStub{}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, nil, PlaceContentConfig{})
	_, err := uc.StartMediaBackfill(context.Background(), placeManagerActor(), "KZ", RequestMetadata{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("StartMediaBackfill() error = %v, want ErrPermissionDenied", err)
	}
	if client.startedBackfillCountry != "" {
		t.Fatalf("started backfill country = %q, want empty", client.startedBackfillCountry)
	}
}

func TestStartMediaBackfillNormalizesCountryCode(t *testing.T) {
	t.Parallel()

	client := &placeAdminClientStub{backfillJob: model.PlaceMediaBackfillJob{
		JobID:       "job-123",
		CountryCode: "KZ",
		Status:      "STARTED",
	}}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, nil, PlaceContentConfig{})

	job, err := uc.StartMediaBackfill(context.Background(), superAdminPlaceManagerActor(), " kz ", RequestMetadata{})
	if err != nil {
		t.Fatalf("StartMediaBackfill() error = %v", err)
	}
	if client.startedBackfillCountry != "KZ" {
		t.Fatalf("country = %q, want KZ", client.startedBackfillCountry)
	}
	if job.JobID != "job-123" {
		t.Fatalf("job = %#v", job)
	}
}

func TestReplacePlaceCoverImageUploadsFileAndAuditsAction(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	oldFileID := uuid.New()
	newFileID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:    placeID,
			Title: "Medeu",
			Media: []model.AdminPlaceMedia{
				{FileID: oldFileID, MediaType: "PHOTO", Position: 0},
			},
		},
	}
	files := &fileUploadClientStub{uploadedFileID: newFileID}
	audit := &placeAuditRepoStub{}
	uc := NewPlaceContentUseCase(client, files, audit, PlaceContentConfig{MaxImageBytes: 4 << 20})

	err := uc.ReplaceCoverImage(context.Background(), placeManagerActor(), placeID, PlaceImageUploadInput{
		FileName:    "medeu.jpg",
		ContentType: "image/jpeg",
		Content:     []byte{0xff, 0xd8, 0xff, 0xdb},
		Metadata:    RequestMetadata{RequestID: "req-media"},
	})

	if err != nil {
		t.Fatalf("ReplaceCoverImage() error = %v", err)
	}
	if files.lastOwnerID != placeID {
		t.Fatalf("upload owner id = %s, want %s", files.lastOwnerID, placeID)
	}
	if len(client.replacedMedia) != 1 {
		t.Fatalf("replaced media count = %d, want 1", len(client.replacedMedia))
	}
	if client.replacedMedia[0].FileID != newFileID || client.replacedMedia[0].MediaType != "PHOTO" || client.replacedMedia[0].Position != 0 {
		t.Fatalf("replacement media = %#v, want new cover at position 0", client.replacedMedia[0])
	}
	if audit.lastAction != "place.media.replaced" {
		t.Fatalf("audit action = %q, want place.media.replaced", audit.lastAction)
	}
}

func TestReplacePlaceCarouselImagesUploadsAllFilesInOrder(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	firstFileID := uuid.New()
	secondFileID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:    placeID,
			Title: "Alakol",
			Media: []model.AdminPlaceMedia{
				{FileID: uuid.New(), MediaType: "PHOTO", Position: 0},
			},
		},
	}
	files := &fileUploadClientStub{uploadedFileIDs: []uuid.UUID{firstFileID, secondFileID}}
	audit := &placeAuditRepoStub{}
	uc := NewPlaceContentUseCase(client, files, audit, PlaceContentConfig{MaxImageBytes: 4 << 20})

	err := uc.ReplaceCarouselImages(context.Background(), placeManagerActor(), placeID, []PlaceImageUploadInput{
		{
			FileName:    "alakol-cover.jpg",
			ContentType: "image/jpeg",
			Content:     []byte{0xff, 0xd8, 0xff, 0xdb},
			Metadata:    RequestMetadata{RequestID: "req-carousel"},
		},
		{
			FileName:    "alakol-second.webp",
			ContentType: "image/webp",
			Content:     []byte("RIFFxxxxWEBPVP8 "),
			Metadata:    RequestMetadata{RequestID: "req-carousel"},
		},
	})

	if err != nil {
		t.Fatalf("ReplaceCarouselImages() error = %v", err)
	}
	if len(files.uploadedInputs) != 2 {
		t.Fatalf("uploaded file count = %d, want 2", len(files.uploadedInputs))
	}
	if len(client.replacedMedia) != 2 {
		t.Fatalf("replaced media count = %d, want 2", len(client.replacedMedia))
	}
	if client.replacedMedia[0].FileID != firstFileID ||
		client.replacedMedia[0].MediaType != "PHOTO" ||
		client.replacedMedia[0].Position != 0 ||
		client.replacedMedia[1].FileID != secondFileID ||
		client.replacedMedia[1].MediaType != "PHOTO" ||
		client.replacedMedia[1].Position != 1 {
		t.Fatalf("replacement media = %#v, want ordered carousel media", client.replacedMedia)
	}
	if audit.lastAction != "place.media.replaced" {
		t.Fatalf("audit action = %q, want place.media.replaced", audit.lastAction)
	}
}

func TestUpdatePlaceCarouselImagesReordersDeletesAndAppendsFiles(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	firstMediaID := uuid.New()
	secondMediaID := uuid.New()
	thirdMediaID := uuid.New()
	firstFileID := uuid.New()
	secondFileID := uuid.New()
	thirdFileID := uuid.Nil
	addedFileID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:    placeID,
			Title: "Medeu",
			Media: []model.AdminPlaceMedia{
				{ID: firstMediaID, FileID: firstFileID, MediaType: "PHOTO", Position: 0},
				{ID: secondMediaID, FileID: secondFileID, MediaType: "PHOTO", Position: 1},
				{
					ID:          thirdMediaID,
					FileID:      thirdFileID,
					ExternalURL: "https://example.com/imported.jpg",
					SourceURL:   "https://example.com/source",
					Credit:      "Imported",
					License:     "Source terms",
					MediaType:   "PHOTO",
					Position:    2,
				},
			},
		},
	}
	files := &fileUploadClientStub{uploadedFileID: addedFileID}
	audit := &placeAuditRepoStub{}
	uc := NewPlaceContentUseCase(client, files, audit, PlaceContentConfig{MaxImageBytes: 4 << 20})

	err := uc.UpdateCarouselImages(context.Background(), placeManagerActor(), placeID, PlaceMediaUpdateInput{
		Action:           PlaceMediaActionAppend,
		ExistingMediaIDs: []uuid.UUID{thirdMediaID, firstMediaID, secondMediaID},
		DeleteMediaIDs:   []uuid.UUID{secondMediaID},
		Uploads: []PlaceImageUploadInput{
			{
				FileName:    "medeu-new.jpg",
				ContentType: "image/jpeg",
				Content:     []byte{0xff, 0xd8, 0xff, 0xdb},
			},
		},
		Metadata: RequestMetadata{RequestID: "req-media-update"},
	})

	if err != nil {
		t.Fatalf("UpdateCarouselImages() error = %v", err)
	}
	if len(client.replacedMedia) != 3 {
		t.Fatalf("replaced media count = %d, want 3: %#v", len(client.replacedMedia), client.replacedMedia)
	}
	if client.replacedMedia[0].FileID != thirdFileID ||
		client.replacedMedia[0].ExternalURL != "https://example.com/imported.jpg" ||
		client.replacedMedia[0].SourceURL != "https://example.com/source" ||
		client.replacedMedia[0].Position != 0 {
		t.Fatalf("first media = %#v, want imported media preserved at position 0", client.replacedMedia[0])
	}
	if client.replacedMedia[1].FileID != firstFileID || client.replacedMedia[1].Position != 1 {
		t.Fatalf("second media = %#v, want original first media at position 1", client.replacedMedia[1])
	}
	if client.replacedMedia[2].FileID != addedFileID || client.replacedMedia[2].Position != 2 {
		t.Fatalf("third media = %#v, want uploaded media appended at position 2", client.replacedMedia[2])
	}
	if audit.lastAction != "place.media.updated" {
		t.Fatalf("audit action = %q, want place.media.updated", audit.lastAction)
	}
}

func TestUpdatePlaceCarouselImagesAllowsDeletingAllMedia(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	mediaID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:    placeID,
			Title: "Medeu",
			Media: []model.AdminPlaceMedia{
				{ID: mediaID, FileID: uuid.New(), MediaType: "PHOTO", Position: 0},
			},
		},
	}
	audit := &placeAuditRepoStub{}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, audit, PlaceContentConfig{})

	err := uc.UpdateCarouselImages(context.Background(), placeManagerActor(), placeID, PlaceMediaUpdateInput{
		Action:           PlaceMediaActionManage,
		ExistingMediaIDs: []uuid.UUID{mediaID},
		DeleteMediaIDs:   []uuid.UUID{mediaID},
		Metadata:         RequestMetadata{RequestID: "req-media-delete"},
	})

	if err != nil {
		t.Fatalf("UpdateCarouselImages() error = %v", err)
	}
	if len(client.replacedMedia) != 0 {
		t.Fatalf("replaced media count = %d, want 0: %#v", len(client.replacedMedia), client.replacedMedia)
	}
}

func TestUpdatePlaceVisitInfoPreservesExistingFeeCurrencies(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:            placeID,
			Title:         "Charyn Canyon",
			Description:   "Canyon",
			DefaultLocale: "en",
			CountryCode:   "KZ",
			CityID:        "almaty",
			Category:      "NATURE",
			Status:        "PUBLISHED",
			VisitInfo: model.PlaceVisitInfo{
				FeeDetails: []model.PlaceFeeDetail{
					{Title: "Admission", Amount: floatPtrForPlaceContentTest(1000), Currency: "KZT", Unit: "PERSON", SortOrder: 10},
					{Title: "Guide", Amount: floatPtrForPlaceContentTest(5000), Currency: "USD", Unit: "GROUP", SortOrder: 20},
				},
				FeeItems: []model.PlaceFeeDetail{
					{Type: "ENTRANCE", Title: "Park admission", MinAmount: floatPtrForPlaceContentTest(1000), Currency: "KZT", Unit: "PERSON", Required: true, SortOrder: 10},
					{Type: "GUIDE", Title: "Guide", MinAmount: floatPtrForPlaceContentTest(5000), Currency: "USD", Unit: "GROUP", Required: false, SortOrder: 20},
				},
			},
		},
	}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, nil, PlaceContentConfig{})

	_, err := uc.UpdatePlaceVisitInfo(context.Background(), placeManagerActor(), placeID, model.PlaceVisitInfo{
		FeeDetails: []model.PlaceFeeDetail{
			{Title: "Guide updated", Amount: floatPtrForPlaceContentTest(5500), Currency: "EUR", Unit: "GROUP", SortOrder: 20},
		},
		FeeItems: []model.PlaceFeeDetail{
			{Type: "GUIDE", Title: "Guide updated", MinAmount: floatPtrForPlaceContentTest(5500), Currency: "EUR", Unit: "GROUP", Required: false, SortOrder: 20},
		},
	}, RequestMetadata{})
	if err != nil {
		t.Fatalf("UpdatePlaceVisitInfo() error = %v", err)
	}
	if client.lastUpdatedPlaceInput.VisitInfo == nil {
		t.Fatal("VisitInfo was not sent")
	}
	if got := client.lastUpdatedPlaceInput.VisitInfo.FeeDetails[0].Currency; got != "USD" {
		t.Fatalf("fee detail currency = %q, want existing USD", got)
	}
	if got := client.lastUpdatedPlaceInput.VisitInfo.FeeItems[0].Currency; got != "USD" {
		t.Fatalf("fee item currency = %q, want existing USD", got)
	}
}

func TestUpdatePlaceVisitInfoGeneralPreservesRepeatedBlocks(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:            placeID,
			Title:         "Charyn Canyon",
			Description:   "Canyon",
			DefaultLocale: "en",
			CountryCode:   "KZ",
			CityID:        "almaty",
			Category:      "NATURE",
			Status:        "PUBLISHED",
			VisitInfo: model.PlaceVisitInfo{
				PriceNoteLocales: map[string]string{"en": "Old note"},
				FeeItems: []model.PlaceFeeDetail{
					{Type: "ENTRANCE", Title: "Park admission", MinAmount: floatPtrForPlaceContentTest(1000), Currency: "KZT", Unit: "PERSON", Required: true, SortOrder: 10},
				},
				AccessOptions: []model.PlaceAccessOption{
					{TransportType: "CAR", RouteHint: "Keep route", SortOrder: 10},
				},
				PracticalNotes: []model.PlacePracticalNote{
					{NoteType: "SAFETY", Body: "Keep tip", SortOrder: 10},
				},
				RecommendedItems: []model.PlaceRecommendedItem{
					{ItemType: "WATER", Title: "Water", SortOrder: 10},
				},
			},
		},
	}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, nil, PlaceContentConfig{})

	_, err := uc.UpdatePlaceVisitInfoGeneral(context.Background(), placeManagerActor(), placeID, model.PlaceVisitInfo{
		PriceNoteLocales: map[string]string{"en": "Updated note"},
		PriceNote:        "Updated note",
		BestTime:         "MORNING",
	}, RequestMetadata{})
	if err != nil {
		t.Fatalf("UpdatePlaceVisitInfoGeneral() error = %v", err)
	}
	got := client.lastUpdatedPlaceInput.VisitInfo
	if got == nil {
		t.Fatal("VisitInfo was not sent")
	}
	if got.PriceNoteLocales["en"] != "Updated note" {
		t.Fatalf("PriceNoteLocales[en] = %q, want updated note", got.PriceNoteLocales["en"])
	}
	if len(got.FeeItems) != 1 || got.FeeItems[0].Title != "Park admission" {
		t.Fatalf("FeeItems = %+v, want existing block preserved", got.FeeItems)
	}
	if len(got.AccessOptions) != 1 || got.AccessOptions[0].RouteHint != "Keep route" {
		t.Fatalf("AccessOptions = %+v, want existing block preserved", got.AccessOptions)
	}
	if len(got.PracticalNotes) != 1 || got.PracticalNotes[0].Body != "Keep tip" {
		t.Fatalf("PracticalNotes = %+v, want existing block preserved", got.PracticalNotes)
	}
	if len(got.RecommendedItems) != 1 || got.RecommendedItems[0].Title != "Water" {
		t.Fatalf("RecommendedItems = %+v, want existing block preserved", got.RecommendedItems)
	}
}

func TestUpdatePlaceVisitFeeItemsReplacesOnlyFeeItems(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:            placeID,
			Title:         "Charyn Canyon",
			Description:   "Canyon",
			DefaultLocale: "en",
			CountryCode:   "KZ",
			CityID:        "almaty",
			Category:      "NATURE",
			Status:        "PUBLISHED",
			VisitInfo: model.PlaceVisitInfo{
				PriceNoteLocales: map[string]string{"en": "Keep this note"},
				FeeDetails: []model.PlaceFeeDetail{
					{Title: "Admission", Amount: floatPtrForPlaceContentTest(1000), Currency: "KZT", Unit: "PERSON", SortOrder: 10},
				},
				FeeItems: []model.PlaceFeeDetail{
					{Type: "ENTRANCE", Title: "Old admission", MinAmount: floatPtrForPlaceContentTest(1000), Currency: "KZT", Unit: "PERSON", SortOrder: 10},
				},
				AccessOptions: []model.PlaceAccessOption{
					{TransportType: "CAR", RouteHint: "Keep route", SortOrder: 10},
				},
			},
		},
	}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, nil, PlaceContentConfig{})

	_, err := uc.UpdatePlaceVisitFeeItems(context.Background(), placeManagerActor(), placeID, []model.PlaceFeeDetail{
		{Type: "GUIDE", Title: "Guide updated", MinAmount: floatPtrForPlaceContentTest(5500), Unit: "GROUP", SortOrder: 10},
	}, RequestMetadata{})
	if err != nil {
		t.Fatalf("UpdatePlaceVisitFeeItems() error = %v", err)
	}
	if client.lastUpdatedPlaceInput.VisitInfo == nil {
		t.Fatal("VisitInfo was not sent")
	}
	updated := client.lastUpdatedPlaceInput.VisitInfo
	if got := updated.PriceNoteLocales["en"]; got != "Keep this note" {
		t.Fatalf("PriceNoteLocales.en = %q, want existing note preserved", got)
	}
	if len(updated.FeeDetails) != 1 || updated.FeeDetails[0].Title != "Admission" {
		t.Fatalf("FeeDetails = %#v, want existing fee details preserved", updated.FeeDetails)
	}
	if len(updated.AccessOptions) != 1 || updated.AccessOptions[0].RouteHint != "Keep route" {
		t.Fatalf("AccessOptions = %#v, want existing access options preserved", updated.AccessOptions)
	}
	if len(updated.FeeItems) != 1 || updated.FeeItems[0].Type != "GUIDE" || updated.FeeItems[0].Title != "Guide updated" {
		t.Fatalf("FeeItems = %#v, want replacement fee items", updated.FeeItems)
	}
}

func TestUpdatePlaceVisitFeeItemsDefaultsNewItemCurrencyFromPlace(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	priceCurrency := "KZT"
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:            placeID,
			Title:         "Charyn Canyon",
			Description:   "Canyon",
			DefaultLocale: "en",
			CountryCode:   "KZ",
			CityID:        "almaty",
			Category:      "NATURE",
			PriceCurrency: &priceCurrency,
			Status:        "PUBLISHED",
		},
	}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, nil, PlaceContentConfig{})

	_, err := uc.UpdatePlaceVisitFeeItems(context.Background(), placeManagerActor(), placeID, []model.PlaceFeeDetail{
		{Type: "GUIDE", Title: "Guide", MinAmount: floatPtrForPlaceContentTest(5500), Unit: "GROUP", SortOrder: 10},
	}, RequestMetadata{})
	if err != nil {
		t.Fatalf("UpdatePlaceVisitFeeItems() error = %v", err)
	}
	got := client.lastUpdatedPlaceInput.VisitInfo
	if got == nil || len(got.FeeItems) != 1 {
		t.Fatalf("FeeItems = %+v, want one item", got)
	}
	if got.FeeItems[0].Currency != "KZT" {
		t.Fatalf("new fee item currency = %q, want KZT", got.FeeItems[0].Currency)
	}
}

func TestUpdatePlaceVisitFeeItemsPreservesCurrencyWhenRowsAreDeleted(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	client := &placeAdminClientStub{
		item: &model.AdminPlace{
			ID:            placeID,
			Title:         "Charyn Canyon",
			Description:   "Canyon",
			DefaultLocale: "en",
			CountryCode:   "KZ",
			CityID:        "almaty",
			Category:      "NATURE",
			Status:        "PUBLISHED",
			VisitInfo: model.PlaceVisitInfo{
				FeeItems: []model.PlaceFeeDetail{
					{Type: "ENTRANCE", Title: "Park admission", MinAmount: floatPtrForPlaceContentTest(1000), Currency: "KZT", Unit: "PERSON", Required: true, SortOrder: 10},
					{Type: "GUIDE", Title: "Guide", MinAmount: floatPtrForPlaceContentTest(5000), Currency: "USD", Unit: "GROUP", Required: false, SortOrder: 20},
				},
			},
		},
	}
	uc := NewPlaceContentUseCase(client, &fileUploadClientStub{}, nil, PlaceContentConfig{})

	_, err := uc.UpdatePlaceVisitFeeItems(context.Background(), placeManagerActor(), placeID, []model.PlaceFeeDetail{
		{Type: "GUIDE", Title: "Guide", MinAmount: floatPtrForPlaceContentTest(5000), Unit: "GROUP", Required: false, SortOrder: 10},
	}, RequestMetadata{})
	if err != nil {
		t.Fatalf("UpdatePlaceVisitFeeItems() error = %v", err)
	}
	got := client.lastUpdatedPlaceInput.VisitInfo
	if got == nil || len(got.FeeItems) != 1 {
		t.Fatalf("FeeItems = %+v, want one preserved item", got)
	}
	if got.FeeItems[0].Currency != "USD" {
		t.Fatalf("remaining fee item currency = %q, want USD", got.FeeItems[0].Currency)
	}
}

func placeManagerActor() *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "content@inflap.local",
		DisplayName: "Content Manager",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{enum.PermissionPlaceManage},
	}
}

func superAdminPlaceManagerActor() *model.StaffUser {
	actor := placeManagerActor()
	actor.Roles = []enum.StaffRole{enum.StaffRoleSuperAdmin}
	return actor
}

type placeAdminClientStub struct {
	item                   *model.AdminPlace
	replacedMedia          []model.PlaceMediaInput
	startedBackfillCountry string
	backfillJob            model.PlaceMediaBackfillJob
	lastUpdatedPlaceInput  model.PlaceInput
}

func (c *placeAdminClientStub) ListPlaces(context.Context, model.AdminPlaceFilter) ([]model.AdminPlace, int, error) {
	return nil, 0, nil
}

func (c *placeAdminClientStub) GetPlace(_ context.Context, id uuid.UUID) (*model.AdminPlace, error) {
	if c.item != nil && c.item.ID == id {
		return c.item, nil
	}
	return nil, nil
}

func (c *placeAdminClientStub) ListVisitReferences(context.Context, string) (model.PlaceVisitReferenceCatalog, error) {
	return model.PlaceVisitReferenceCatalog{}, nil
}

func (c *placeAdminClientStub) CreatePlace(_ context.Context, input model.PlaceInput) (*model.AdminPlace, error) {
	return &model.AdminPlace{ID: uuid.New(), Title: input.Title}, nil
}

func (c *placeAdminClientStub) UpdatePlace(_ context.Context, id uuid.UUID, input model.PlaceInput) (*model.AdminPlace, error) {
	c.lastUpdatedPlaceInput = input
	return &model.AdminPlace{ID: id, Title: input.Title}, nil
}

func (c *placeAdminClientStub) ReplaceMedia(_ context.Context, _ uuid.UUID, media []model.PlaceMediaInput) error {
	c.replacedMedia = media
	return nil
}

func (c *placeAdminClientStub) StartMediaBackfill(_ context.Context, countryCode string) (model.PlaceMediaBackfillJob, error) {
	c.startedBackfillCountry = countryCode
	return c.backfillJob, nil
}

type fileUploadClientStub struct {
	uploadedFileID  uuid.UUID
	uploadedFileIDs []uuid.UUID
	lastOwnerID     uuid.UUID
	uploadedInputs  []model.FileUploadInput
}

func (c *fileUploadClientStub) UploadPublicPlaceImage(_ context.Context, input model.FileUploadInput) (*model.UploadedFile, error) {
	c.lastOwnerID = input.OwnerID
	c.uploadedInputs = append(c.uploadedInputs, input)
	if len(c.uploadedFileIDs) > 0 {
		id := c.uploadedFileIDs[0]
		c.uploadedFileIDs = c.uploadedFileIDs[1:]
		return &model.UploadedFile{ID: id}, nil
	}
	return &model.UploadedFile{ID: c.uploadedFileID}, nil
}

func (c *fileUploadClientStub) GetPublicContent(_ context.Context, _ uuid.UUID) (*model.FileContent, error) {
	return nil, nil
}

type placeAuditRepoStub struct {
	lastAction string
}

func (r *placeAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	r.lastAction = event.Action
	return nil
}

func (r *placeAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}

func floatPtrForPlaceContentTest(value float64) *float64 {
	return &value
}
