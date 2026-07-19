package filemanager

import (
	"context"
	"errors"
	"net"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"

	"kz/inflap/backend/services/place-service/internal/app"
	filev1 "kz/inflap/proto/gen/go/file/v1"
)

func TestCreateDownloadURLValidatesFileManagerResponse(t *testing.T) {
	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	tests := []struct {
		name    string
		value   string
		wantErr bool
	}{
		{name: "https", value: "https://media.example.test/cover?signature=short-lived"},
		{name: "http", value: "http://file-manager.internal/cover"},
		{name: "relative", value: "/files/cover", wantErr: true},
		{name: "unsupported scheme", value: "ftp://media.example.test/cover", wantErr: true},
		{name: "userinfo", value: "https://user:secret@media.example.test/cover", wantErr: true},
		{name: "literal control", value: "https://media.example.test/cover\nnext", wantErr: true},
		{name: "escaped control", value: "https://media.example.test/cover?key=%0Avalue", wantErr: true},
		{name: "backslash", value: "https://media.example.test\\@attacker.test/cover", wantErr: true},
		{name: "surrounding whitespace", value: " https://media.example.test/cover", wantErr: true},
		{name: "missing host", value: "https:///cover", wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			service := &savedCoverFileServiceStub{
				downloadURL: test.value,
				expiresAt:   now.Add(15 * time.Minute).Format(time.RFC3339),
			}
			client := &Client{
				service:        service,
				requestTimeout: time.Second,
				now:            func() time.Time { return now },
			}

			got, err := client.CreateDownloadURL(context.Background(), uuid.New())
			if test.wantErr {
				if !errors.Is(err, app.ErrSavedCoverDownloadURLInvalid) {
					t.Fatalf("CreateDownloadURL() error = %v, want invalid URL", err)
				}
				if got != "" {
					t.Fatalf("CreateDownloadURL() = %q on invalid response", got)
				}
			} else if err != nil || got != test.value {
				t.Fatalf("CreateDownloadURL() = %q, %v, want %q, nil", got, err, test.value)
			}
			if service.calls != 1 {
				t.Fatalf("CreateDownloadUrl RPC calls = %d, want 1", service.calls)
			}
		})
	}
}

func TestCreateDownloadURLRejectsMissingOrUnboundedExpiry(t *testing.T) {
	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	tests := []struct {
		name      string
		expiresAt string
	}{
		{name: "missing"},
		{name: "malformed", expiresAt: "tomorrow"},
		{name: "already expired", expiresAt: now.Add(-time.Second).Format(time.RFC3339)},
		{name: "too little remaining lifetime", expiresAt: now.Add(time.Second).Format(time.RFC3339)},
		{name: "unbounded", expiresAt: now.Add(time.Hour).Format(time.RFC3339)},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			client := &Client{
				service: &savedCoverFileServiceStub{
					downloadURL: "https://media.example.test/cover?signature=short-lived",
					expiresAt:   test.expiresAt,
				},
				requestTimeout: time.Second,
				now:            func() time.Time { return now },
			}

			_, err := client.CreateDownloadURL(context.Background(), uuid.New())
			if !errors.Is(err, app.ErrSavedCoverFileManagerBadResponse) {
				t.Fatalf("CreateDownloadURL() error = %v, want invalid response", err)
			}
		})
	}
}

func TestCreateDownloadURLMapsFileManagerStatusWithoutDetails(t *testing.T) {
	tests := []struct {
		name    string
		code    codes.Code
		wantErr error
	}{
		{name: "not found", code: codes.NotFound, wantErr: app.ErrSavedCoverFileNotFound},
		{name: "unavailable", code: codes.Unavailable, wantErr: app.ErrSavedCoverFileManagerUnavailable},
		{name: "deadline", code: codes.DeadlineExceeded, wantErr: app.ErrSavedCoverFileManagerUnavailable},
		{name: "rejected", code: codes.InvalidArgument, wantErr: app.ErrSavedCoverFileManagerBadResponse},
		{name: "internal", code: codes.Internal, wantErr: app.ErrSavedCoverFileManagerBadResponse},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			client := &Client{
				service: &savedCoverFileServiceStub{
					err: status.Error(test.code, "sensitive upstream details"),
				},
				requestTimeout: time.Second,
			}
			_, err := client.CreateDownloadURL(context.Background(), uuid.New())
			if !errors.Is(err, test.wantErr) {
				t.Fatalf("CreateDownloadURL() error = %v, want %v", err, test.wantErr)
			}
			if err != test.wantErr {
				t.Fatalf("CreateDownloadURL() leaked or wrapped upstream error: %v", err)
			}
		})
	}
}

func TestClientSendsInternalServiceIdentity(t *testing.T) {
	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	service := &savedCoverMetadataServer{}
	filev1.RegisterFileServiceServer(server, service)
	serveDone := make(chan error, 1)
	go func() {
		serveDone <- server.Serve(listener)
	}()
	t.Cleanup(func() {
		server.Stop()
		_ = listener.Close()
		<-serveDone
	})

	client, err := New(
		"passthrough:///saved-cover-file-manager",
		"internal-token",
		"place-service",
		time.Second,
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) {
			return listener.Dial()
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	t.Cleanup(func() { _ = client.Close() })

	fileID := uuid.New()
	if _, err = client.CreateDownloadURL(context.Background(), fileID); err != nil {
		t.Fatalf("CreateDownloadURL() error = %v", err)
	}
	if service.fileID != fileID.String() {
		t.Fatalf("file ID = %q, want %q", service.fileID, fileID)
	}
	if got := service.metadata.Get("x-internal-service-token"); len(got) != 1 || got[0] != "internal-token" {
		t.Fatalf("internal token metadata = %#v", got)
	}
	if got := service.metadata.Get("x-service-name"); len(got) != 1 || got[0] != "place-service" {
		t.Fatalf("service name metadata = %#v", got)
	}
}

type savedCoverFileServiceStub struct {
	filev1.FileServiceClient
	downloadURL string
	expiresAt   string
	err         error
	fileID      string
	calls       int
}

func (s *savedCoverFileServiceStub) CreateDownloadUrl(
	_ context.Context,
	request *filev1.CreateDownloadUrlRequest,
	_ ...grpc.CallOption,
) (*filev1.CreateDownloadUrlResponse, error) {
	s.calls++
	s.fileID = request.GetFileId()
	if s.err != nil {
		return nil, s.err
	}
	return &filev1.CreateDownloadUrlResponse{
		Url:       s.downloadURL,
		ExpiresAt: s.expiresAt,
	}, nil
}

type savedCoverMetadataServer struct {
	filev1.UnimplementedFileServiceServer
	metadata metadata.MD
	fileID   string
}

func (s *savedCoverMetadataServer) CreateDownloadUrl(
	ctx context.Context,
	request *filev1.CreateDownloadUrlRequest,
) (*filev1.CreateDownloadUrlResponse, error) {
	s.metadata, _ = metadata.FromIncomingContext(ctx)
	s.fileID = request.GetFileId()
	return &filev1.CreateDownloadUrlResponse{
		Url:       "https://media.example.test/cover?signature=short-lived",
		ExpiresAt: time.Now().UTC().Add(15 * time.Minute).Format(time.RFC3339),
	}, nil
}
