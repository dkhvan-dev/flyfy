package http

import (
	"net/http/httptest"
	"testing"
)

func TestBuildErrorResponseLocalizesBusinessError(t *testing.T) {
	req := httptest.NewRequest("GET", "/api/v1/private", nil)
	req.Header.Set("Accept-Language", "kk,en;q=0.8")

	resp := buildErrorResponse(req, errorCodeAuthRequired, errorKindBusiness)

	if resp.Kind != errorKindBusiness {
		t.Fatalf("Kind = %q, want %q", resp.Kind, errorKindBusiness)
	}
	if resp.Code != errorCodeAuthRequired {
		t.Fatalf("Code = %q, want %q", resp.Code, errorCodeAuthRequired)
	}
	if resp.Error != "Авторизация қажет" {
		t.Fatalf("Error = %q, want Kazakh localized title", resp.Error)
	}
	if resp.Message == "" {
		t.Fatal("Message must not be empty")
	}
}

func TestBuildErrorResponseMasksTechnicalError(t *testing.T) {
	req := httptest.NewRequest("GET", "/api/v1/private?lang=ru", nil)

	resp := buildErrorResponse(req, errorCodeUpstreamUnavailable, errorKindTechnical)

	if resp.Kind != errorKindTechnical {
		t.Fatalf("Kind = %q, want %q", resp.Kind, errorKindTechnical)
	}
	if resp.Code != errorCodeUpstreamUnavailable {
		t.Fatalf("Code = %q, want %q", resp.Code, errorCodeUpstreamUnavailable)
	}
	if resp.Error != "Техническая ошибка" {
		t.Fatalf("Error = %q, want technical title", resp.Error)
	}
	if resp.Message != "На сервере возникла проблема. Попробуйте позже." {
		t.Fatalf("Message = %q, want generic server problem message", resp.Message)
	}
}
