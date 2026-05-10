package filemanager

import (
	"context"
	"net"
	"testing"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/test/bufconn"

	filev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/file/v1"
)

func TestValidateTourCoverFileAcceptsAttractionMedia(t *testing.T) {
	t.Parallel()

	fileID := uuid.New()
	client, cleanup := newFileManagerClientForTest(
		t,
		&filev1.GetFileResponse{
			FileId:  fileID.String(),
			Status:  "READY",
			Purpose: "ATTRACTION_MEDIA",
		},
	)
	defer cleanup()

	if err := client.ValidateTourCoverFile(context.Background(), fileID); err != nil {
		t.Fatalf("ValidateTourCoverFile returned error for attraction media: %v", err)
	}
}

func newFileManagerClientForTest(
	t *testing.T,
	file *filev1.GetFileResponse,
) (*Client, func()) {
	t.Helper()

	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	filev1.RegisterFileServiceServer(server, &fileServiceStub{file: file})

	errCh := make(chan error, 1)
	go func() {
		errCh <- server.Serve(listener)
	}()

	client, err := New(
		"passthrough:///bufnet",
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) {
			return listener.Dial()
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		server.Stop()
		_ = listener.Close()
		t.Fatalf("create file manager client: %v", err)
	}

	return client, func() {
		_ = client.Close()
		server.Stop()
		_ = listener.Close()
		<-errCh
	}
}

type fileServiceStub struct {
	filev1.UnimplementedFileServiceServer
	file *filev1.GetFileResponse
}

func (s *fileServiceStub) GetFile(
	context.Context,
	*filev1.GetFileRequest,
) (*filev1.GetFileResponse, error) {
	return s.file, nil
}
