package main

import (
	"context"
	"errors"
	"testing"

	"kz/inflap/backend/services/saved-service/internal/app/savedsearchmigration"
)

func TestRequireSavedSearchReady(t *testing.T) {
	t.Parallel()

	ready := savedsearchmigration.Status{
		ColumnsReady:              true,
		TriggerReady:              true,
		ParityConstraintPresent:   true,
		ParityConstraintValidated: true,
		OwnerIndexReady:           true,
		ProjectionIndexReady:      true,
	}
	tests := []struct {
		name    string
		reader  savedSearchStatusReader
		wantErr bool
	}{
		{name: "ready", reader: searchStatusReaderStub{status: ready}},
		{name: "pending", reader: searchStatusReaderStub{status: savedsearchmigration.Status{Pending: true}}, wantErr: true},
		{name: "inspection failure", reader: searchStatusReaderStub{err: errors.New("database unavailable")}, wantErr: true},
		{name: "missing reader", wantErr: true},
	}
	for _, test := range tests {
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			err := requireSavedSearchReady(context.Background(), test.reader)
			if (err != nil) != test.wantErr {
				t.Fatalf("requireSavedSearchReady() error = %v, wantErr %v", err, test.wantErr)
			}
		})
	}
}

type searchStatusReaderStub struct {
	status savedsearchmigration.Status
	err    error
}

func (stub searchStatusReaderStub) Status(context.Context) (savedsearchmigration.Status, error) {
	return stub.status, stub.err
}
