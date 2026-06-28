package http

import (
	"bytes"
	"encoding/json"
	stdhttp "net/http"
	"net/http/httptest"
	"testing"
)

type mediaBackfillStarterStub struct {
	countryCode string
	jobID       string
	err         error
}

func (s *mediaBackfillStarterStub) StartCountry(countryCode string) (string, error) {
	s.countryCode = countryCode
	if s.err != nil {
		return "", s.err
	}
	return s.jobID, nil
}

func TestStartPlaceMediaBackfillStartsCountryJob(t *testing.T) {
	t.Parallel()

	starter := &mediaBackfillStarterStub{jobID: "job-123"}
	handler := NewHandler(nil)
	handler.SetMediaBackfillStarter(starter)

	request := httptest.NewRequest(
		stdhttp.MethodPost,
		"/internal/v1/admin/places/media/backfill",
		bytes.NewBufferString(`{"countryCode":"kz"}`),
	)
	recorder := httptest.NewRecorder()

	handler.StartPlaceMediaBackfill(recorder, request)

	if recorder.Code != stdhttp.StatusAccepted {
		t.Fatalf("status = %d, want %d: %s", recorder.Code, stdhttp.StatusAccepted, recorder.Body.String())
	}
	if starter.countryCode != "KZ" {
		t.Fatalf("countryCode = %q, want KZ", starter.countryCode)
	}

	var response struct {
		JobID       string `json:"jobId"`
		CountryCode string `json:"countryCode"`
		Status      string `json:"status"`
	}
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.JobID != "job-123" || response.CountryCode != "KZ" || response.Status != "STARTED" {
		t.Fatalf("unexpected response: %#v", response)
	}
}

func TestStartPlaceMediaBackfillRejectsMissingCountry(t *testing.T) {
	t.Parallel()

	handler := NewHandler(nil)
	handler.SetMediaBackfillStarter(&mediaBackfillStarterStub{jobID: "job-123"})

	request := httptest.NewRequest(
		stdhttp.MethodPost,
		"/internal/v1/admin/places/media/backfill",
		bytes.NewBufferString(`{"countryCode":""}`),
	)
	recorder := httptest.NewRecorder()

	handler.StartPlaceMediaBackfill(recorder, request)

	if recorder.Code != stdhttp.StatusBadRequest {
		t.Fatalf("status = %d, want %d", recorder.Code, stdhttp.StatusBadRequest)
	}
}
