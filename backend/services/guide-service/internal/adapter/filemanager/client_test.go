package filemanager

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/guide-service/internal/app"
	filev1 "kz/inflap/proto/gen/go/file/v1"
)

func TestCreateDownloadURLValidatesFileManagerResponse(t *testing.T) {
	tests := []struct {
		name    string
		value   string
		wantErr bool
	}{
		{
			name:  "https",
			value: "https://media.example.test/avatar?signature=short-lived",
		},
		{
			name:  "http",
			value: "http://file-manager.internal/avatar",
		},
		{name: "relative", value: "/files/avatar", wantErr: true},
		{name: "unsupported scheme", value: "ftp://media.example.test/avatar", wantErr: true},
		{name: "userinfo", value: "https://user:secret@media.example.test/avatar", wantErr: true},
		{name: "literal control", value: "https://media.example.test/avatar\nnext", wantErr: true},
		{name: "escaped control", value: "https://media.example.test/avatar?key=%0Avalue", wantErr: true},
		{name: "surrounding whitespace", value: " https://media.example.test/avatar", wantErr: true},
		{name: "missing host", value: "https:///avatar", wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			service := &downloadURLFileServiceStub{url: test.value}
			client := &Client{service: service}

			got, err := client.CreateDownloadURL(context.Background(), uuid.New())
			if test.wantErr {
				if !errors.Is(err, app.ErrFileManagerDownloadURLInvalid) {
					t.Fatalf("CreateDownloadURL() error = %v, want invalid URL", err)
				}
				if got != "" {
					t.Fatalf("CreateDownloadURL() = %q on invalid response, want empty", got)
				}
			} else {
				if err != nil || got != test.value {
					t.Fatalf("CreateDownloadURL() = %q, %v, want %q, nil", got, err, test.value)
				}
			}
			if service.calls != 1 {
				t.Fatalf("CreateDownloadUrl RPC calls = %d, want 1", service.calls)
			}
		})
	}
}

func TestCreateGuideDocumentDownloadURLPreservesDocumentErrorContract(t *testing.T) {
	client := &Client{service: &downloadURLFileServiceStub{
		err: status.Error(codes.NotFound, "missing"),
	}}

	_, err := client.CreateGuideDocumentDownloadURL(context.Background(), uuid.New())
	if !errors.Is(err, app.ErrGuideDocumentFileNotFound) {
		t.Fatalf("CreateGuideDocumentDownloadURL() error = %v, want document not found", err)
	}
}

type downloadURLFileServiceStub struct {
	filev1.FileServiceClient
	url   string
	err   error
	calls int
}

func (s *downloadURLFileServiceStub) CreateDownloadUrl(
	context.Context,
	*filev1.CreateDownloadUrlRequest,
	...grpc.CallOption,
) (*filev1.CreateDownloadUrlResponse, error) {
	s.calls++
	if s.err != nil {
		return nil, s.err
	}
	return &filev1.CreateDownloadUrlResponse{Url: s.url}, nil
}
