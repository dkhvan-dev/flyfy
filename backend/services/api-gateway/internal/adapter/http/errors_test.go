package http

import (
	"net/http"
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

func TestBuildDownstreamErrorResponseLocalizesTechnicalCode(t *testing.T) {
	req := httptest.NewRequest("GET", "/api/v1/feed", nil)
	req.Header.Set("Accept-Language", "kk,en;q=0.8")

	payload := map[string]any{
		"error": "invalid request body",
	}

	rewritten, ok := buildDownstreamErrorResponse(req, http.StatusBadRequest, payload)
	if !ok {
		t.Fatal("buildDownstreamErrorResponse ok = false, want true")
	}

	if rewritten.Code != "invalid_request_body" {
		t.Fatalf("Code = %q, want invalid_request_body", rewritten.Code)
	}
	if rewritten.Message != "Сұрауды тексеріп, қайталап көріңіз." {
		t.Fatalf("Message = %q, want Kazakh localized message", rewritten.Message)
	}
	if rewritten.Error != "Сұрау қате" {
		t.Fatalf("Error = %q, want Kazakh localized title", rewritten.Error)
	}
}

func TestBuildDownstreamErrorResponsePreservesMaintenanceKind(t *testing.T) {
	req := httptest.NewRequest("GET", "/api/v1/activities/join?lang=ru", nil)

	payload := map[string]any{
		"error":   "Технические работы",
		"message": "temporary downstream English text",
		"code":    "activity.technical_maintenance",
		"kind":    "maintenance",
	}

	rewritten, ok := buildDownstreamErrorResponse(req, http.StatusServiceUnavailable, payload)
	if !ok {
		t.Fatal("buildDownstreamErrorResponse ok = false, want true")
	}

	if rewritten.Kind != "maintenance" {
		t.Fatalf("Kind = %q, want maintenance", rewritten.Kind)
	}
	if rewritten.Code != "activity.technical_maintenance" {
		t.Fatalf("Code = %q, want activity.technical_maintenance", rewritten.Code)
	}
	if rewritten.Message != "Сейчас проводятся технические работы. Попробуйте позже." {
		t.Fatalf("Message = %q, want localized maintenance message", rewritten.Message)
	}
}
