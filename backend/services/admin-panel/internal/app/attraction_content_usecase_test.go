package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

func TestCreateAttractionRequiresAttractionManagePermission(t *testing.T) {
	t.Parallel()

	uc := NewAttractionContentUseCase(&attractionAdminClientStub{}, &fileUploadClientStub{}, &attractionAuditRepoStub{}, AttractionContentConfig{})
	_, err := uc.CreateAttraction(context.Background(), &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@flyfy.local",
		DisplayName: "Support",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{enum.PermissionDashboardRead},
	}, model.AttractionInput{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("CreateAttraction() error = %v, want ErrPermissionDenied", err)
	}
}

func TestReplaceAttractionCoverImageUploadsFileAndAuditsAction(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	oldFileID := uuid.New()
	newFileID := uuid.New()
	client := &attractionAdminClientStub{
		item: &model.AdminAttraction{
			ID:    attractionID,
			Title: "Medeu",
			Media: []model.AdminAttractionMedia{
				{FileID: oldFileID, MediaType: "PHOTO", Position: 0},
			},
		},
	}
	files := &fileUploadClientStub{uploadedFileID: newFileID}
	audit := &attractionAuditRepoStub{}
	uc := NewAttractionContentUseCase(client, files, audit, AttractionContentConfig{MaxImageBytes: 4 << 20})

	err := uc.ReplaceCoverImage(context.Background(), attractionManagerActor(), attractionID, AttractionImageUploadInput{
		FileName:    "medeu.jpg",
		ContentType: "image/jpeg",
		Content:     []byte{0xff, 0xd8, 0xff, 0xdb},
		Metadata:    RequestMetadata{RequestID: "req-media"},
	})

	if err != nil {
		t.Fatalf("ReplaceCoverImage() error = %v", err)
	}
	if files.lastOwnerID != attractionID {
		t.Fatalf("upload owner id = %s, want %s", files.lastOwnerID, attractionID)
	}
	if len(client.replacedMedia) != 1 {
		t.Fatalf("replaced media count = %d, want 1", len(client.replacedMedia))
	}
	if client.replacedMedia[0].FileID != newFileID || client.replacedMedia[0].MediaType != "PHOTO" || client.replacedMedia[0].Position != 0 {
		t.Fatalf("replacement media = %#v, want new cover at position 0", client.replacedMedia[0])
	}
	if audit.lastAction != "attraction.media.replaced" {
		t.Fatalf("audit action = %q, want attraction.media.replaced", audit.lastAction)
	}
}

func TestReplaceAttractionCarouselImagesUploadsAllFilesInOrder(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	firstFileID := uuid.New()
	secondFileID := uuid.New()
	client := &attractionAdminClientStub{
		item: &model.AdminAttraction{
			ID:    attractionID,
			Title: "Alakol",
			Media: []model.AdminAttractionMedia{
				{FileID: uuid.New(), MediaType: "PHOTO", Position: 0},
			},
		},
	}
	files := &fileUploadClientStub{uploadedFileIDs: []uuid.UUID{firstFileID, secondFileID}}
	audit := &attractionAuditRepoStub{}
	uc := NewAttractionContentUseCase(client, files, audit, AttractionContentConfig{MaxImageBytes: 4 << 20})

	err := uc.ReplaceCarouselImages(context.Background(), attractionManagerActor(), attractionID, []AttractionImageUploadInput{
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
	if audit.lastAction != "attraction.media.replaced" {
		t.Fatalf("audit action = %q, want attraction.media.replaced", audit.lastAction)
	}
}

func TestUpdateAttractionCarouselImagesReordersDeletesAndAppendsFiles(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	firstMediaID := uuid.New()
	secondMediaID := uuid.New()
	thirdMediaID := uuid.New()
	firstFileID := uuid.New()
	secondFileID := uuid.New()
	thirdFileID := uuid.Nil
	addedFileID := uuid.New()
	client := &attractionAdminClientStub{
		item: &model.AdminAttraction{
			ID:    attractionID,
			Title: "Medeu",
			Media: []model.AdminAttractionMedia{
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
	audit := &attractionAuditRepoStub{}
	uc := NewAttractionContentUseCase(client, files, audit, AttractionContentConfig{MaxImageBytes: 4 << 20})

	err := uc.UpdateCarouselImages(context.Background(), attractionManagerActor(), attractionID, AttractionMediaUpdateInput{
		Action:           AttractionMediaActionAppend,
		ExistingMediaIDs: []uuid.UUID{thirdMediaID, firstMediaID, secondMediaID},
		DeleteMediaIDs:   []uuid.UUID{secondMediaID},
		Uploads: []AttractionImageUploadInput{
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
	if audit.lastAction != "attraction.media.updated" {
		t.Fatalf("audit action = %q, want attraction.media.updated", audit.lastAction)
	}
}

func TestUpdateAttractionCarouselImagesAllowsDeletingAllMedia(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	mediaID := uuid.New()
	client := &attractionAdminClientStub{
		item: &model.AdminAttraction{
			ID:    attractionID,
			Title: "Medeu",
			Media: []model.AdminAttractionMedia{
				{ID: mediaID, FileID: uuid.New(), MediaType: "PHOTO", Position: 0},
			},
		},
	}
	audit := &attractionAuditRepoStub{}
	uc := NewAttractionContentUseCase(client, &fileUploadClientStub{}, audit, AttractionContentConfig{})

	err := uc.UpdateCarouselImages(context.Background(), attractionManagerActor(), attractionID, AttractionMediaUpdateInput{
		Action:           AttractionMediaActionManage,
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

func attractionManagerActor() *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "content@flyfy.local",
		DisplayName: "Content Manager",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{enum.PermissionAttractionManage},
	}
}

type attractionAdminClientStub struct {
	item          *model.AdminAttraction
	replacedMedia []model.AttractionMediaInput
}

func (c *attractionAdminClientStub) ListAttractions(context.Context, model.AdminAttractionFilter) ([]model.AdminAttraction, int, error) {
	return nil, 0, nil
}

func (c *attractionAdminClientStub) GetAttraction(_ context.Context, id uuid.UUID) (*model.AdminAttraction, error) {
	if c.item != nil && c.item.ID == id {
		return c.item, nil
	}
	return nil, nil
}

func (c *attractionAdminClientStub) CreateAttraction(_ context.Context, input model.AttractionInput) (*model.AdminAttraction, error) {
	return &model.AdminAttraction{ID: uuid.New(), Title: input.Title}, nil
}

func (c *attractionAdminClientStub) UpdateAttraction(_ context.Context, id uuid.UUID, input model.AttractionInput) (*model.AdminAttraction, error) {
	return &model.AdminAttraction{ID: id, Title: input.Title}, nil
}

func (c *attractionAdminClientStub) ReplaceMedia(_ context.Context, _ uuid.UUID, media []model.AttractionMediaInput) error {
	c.replacedMedia = media
	return nil
}

type fileUploadClientStub struct {
	uploadedFileID  uuid.UUID
	uploadedFileIDs []uuid.UUID
	lastOwnerID     uuid.UUID
	uploadedInputs  []model.FileUploadInput
}

func (c *fileUploadClientStub) UploadPublicAttractionImage(_ context.Context, input model.FileUploadInput) (*model.UploadedFile, error) {
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

type attractionAuditRepoStub struct {
	lastAction string
}

func (r *attractionAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	r.lastAction = event.Action
	return nil
}

func (r *attractionAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}
