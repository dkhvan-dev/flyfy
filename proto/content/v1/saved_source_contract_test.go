package contentv1_test

import (
	"strings"
	"testing"

	"google.golang.org/protobuf/reflect/protoreflect"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestSavedSourceContractShape(t *testing.T) {
	t.Parallel()

	file := contentv1.File_content_v1_saved_source_proto
	if got, want := file.Package(), protoreflect.FullName("content.v1"); got != want {
		t.Fatalf("package = %q, want %q", got, want)
	}

	service := file.Services().ByName("SavedSourceService")
	if service == nil {
		t.Fatal("SavedSourceService is missing")
	}
	if got := service.Methods().Len(); got != 1 {
		t.Fatalf("SavedSourceService method count = %d, want 1", got)
	}
	method := service.Methods().ByName("ResolveSaveEligibility")
	if method == nil {
		t.Fatal("ResolveSaveEligibility is missing")
	}
	if got, want := method.Input().FullName(), protoreflect.FullName("content.v1.ResolveSaveEligibilityRequest"); got != want {
		t.Fatalf("ResolveSaveEligibility input = %q, want %q", got, want)
	}
	if got, want := method.Output().FullName(), protoreflect.FullName("content.v1.ResolveSaveEligibilityResponse"); got != want {
		t.Fatalf("ResolveSaveEligibility output = %q, want %q", got, want)
	}

	entityTypes := file.Enums().ByName("SavedEntityType")
	requireEnumValuesAtNumbers(t, entityTypes, []enumValueExpectation{
		{name: "SAVED_ENTITY_TYPE_UNSPECIFIED", number: 0},
		{name: "SAVED_ENTITY_TYPE_ATTRACTION", number: 1},
		{name: "SAVED_ENTITY_TYPE_ACTIVITY", number: 2},
		{name: "SAVED_ENTITY_TYPE_GUIDE", number: 4},
		{name: "SAVED_ENTITY_TYPE_USER", number: 5},
		{name: "SAVED_ENTITY_TYPE_POST", number: 6},
	})
	requireReservedEnumValue(t, entityTypes, 3, "SAVED_ENTITY_TYPE_EXCURSION")
	requireEnumValues(t, file.Enums().ByName("SaveEligibility"), []string{
		"SAVE_ELIGIBILITY_UNSPECIFIED",
		"SAVE_ELIGIBILITY_ELIGIBLE",
		"SAVE_ELIGIBILITY_INELIGIBLE",
	})
	requireEnumValues(t, file.Enums().ByName("SavedTargetVisibility"), []string{
		"SAVED_TARGET_VISIBILITY_UNSPECIFIED",
		"SAVED_TARGET_VISIBILITY_PUBLIC",
		"SAVED_TARGET_VISIBILITY_PRIVATE",
		"SAVED_TARGET_VISIBILITY_UNAVAILABLE",
		"SAVED_TARGET_VISIBILITY_DELETED",
		"SAVED_TARGET_VISIBILITY_RESTRICTED",
	})
	requireEnumValues(t, file.Enums().ByName("SavedLocale"), []string{
		"SAVED_LOCALE_UNSPECIFIED",
		"SAVED_LOCALE_EN",
		"SAVED_LOCALE_RU",
		"SAVED_LOCALE_KK",
	})
	requireEnumValues(t, file.Enums().ByName("SavedLifecycleEventKind"), []string{
		"SAVED_LIFECYCLE_EVENT_KIND_UNSPECIFIED",
		"SAVED_LIFECYCLE_EVENT_KIND_PUBLISHED",
		"SAVED_LIFECYCLE_EVENT_KIND_UPDATED",
		"SAVED_LIFECYCLE_EVENT_KIND_UNAVAILABLE",
		"SAVED_LIFECYCLE_EVENT_KIND_DELETED",
		"SAVED_LIFECYCLE_EVENT_KIND_VISIBILITY_CHANGED",
	})

	target := requireMessage(t, file, "SavedTarget")
	if got := target.Fields().Len(); got != 2 {
		t.Fatalf("SavedTarget field count = %d, want 2", got)
	}
	requireField(t, target, "entity_type", 1, protoreflect.EnumKind, "content.v1.SavedEntityType")
	requireField(t, target, "entity_id", 2, protoreflect.StringKind, "")

	projection := requireMessage(t, file, "SavedPublicCardProjection")
	requireField(t, projection, "source_default_locale", 1, protoreflect.EnumKind, "content.v1.SavedLocale")
	for number, locale := range []string{"en", "ru", "kk"} {
		requireField(t, projection, protoreflect.Name(locale), protoreflect.FieldNumber(number+2), protoreflect.MessageKind, "content.v1.SavedLocalizedCardProjection")
	}

	response := requireMessage(t, file, "ResolveSaveEligibilityResponse")
	requireField(t, response, "target", 1, protoreflect.MessageKind, "content.v1.SavedTarget")
	requireField(t, response, "eligibility", 2, protoreflect.EnumKind, "content.v1.SaveEligibility")
	requireField(t, response, "visibility", 3, protoreflect.EnumKind, "content.v1.SavedTargetVisibility")
	requireField(t, response, "revisions", 4, protoreflect.MessageKind, "content.v1.SavedSourceRevisions")
	requireField(t, response, "validated_at", 5, protoreflect.MessageKind, "google.protobuf.Timestamp")
	requireField(t, response, "public_projection", 6, protoreflect.MessageKind, "content.v1.SavedPublicCardProjection")

	event := requireMessage(t, file, "SavedSourceLifecycleEvent")
	requireField(t, event, "event_id", 1, protoreflect.StringKind, "")
	requireField(t, event, "kind", 2, protoreflect.EnumKind, "content.v1.SavedLifecycleEventKind")
	requireField(t, event, "target", 3, protoreflect.MessageKind, "content.v1.SavedTarget")
	requireField(t, event, "revisions", 4, protoreflect.MessageKind, "content.v1.SavedSourceRevisions")
	requireField(t, event, "occurred_at", 5, protoreflect.MessageKind, "google.protobuf.Timestamp")
	requireField(t, event, "visibility", 6, protoreflect.EnumKind, "content.v1.SavedTargetVisibility")
	requireField(t, event, "public_projection", 7, protoreflect.MessageKind, "content.v1.SavedPublicCardProjection")

	forbiddenFragments := []string{"alias", "merge", "owner", "relationship", "collection", "note", "share", "request_payload"}
	for i := 0; i < file.Messages().Len(); i++ {
		message := file.Messages().Get(i)
		for j := 0; j < message.Fields().Len(); j++ {
			name := string(message.Fields().Get(j).Name())
			for _, fragment := range forbiddenFragments {
				if strings.Contains(name, fragment) {
					t.Errorf("forbidden field %s.%s contains %q", message.Name(), name, fragment)
				}
			}
		}
	}
}

func requireEnumValues(t *testing.T, enum protoreflect.EnumDescriptor, names []string) {
	t.Helper()
	if enum == nil {
		t.Fatal("enum is missing")
	}
	if got := enum.Values().Len(); got != len(names) {
		t.Fatalf("%s value count = %d, want %d", enum.Name(), got, len(names))
	}
	for number, name := range names {
		value := enum.Values().Get(number)
		if got := string(value.Name()); got != name {
			t.Errorf("%s value %d = %q, want %q", enum.Name(), number, got, name)
		}
		if got := int(value.Number()); got != number {
			t.Errorf("%s.%s number = %d, want %d", enum.Name(), name, got, number)
		}
	}
}

type enumValueExpectation struct {
	name   string
	number protoreflect.EnumNumber
}

func requireEnumValuesAtNumbers(
	t *testing.T,
	enum protoreflect.EnumDescriptor,
	expected []enumValueExpectation,
) {
	t.Helper()
	if enum == nil {
		t.Fatal("enum is missing")
	}
	if got := enum.Values().Len(); got != len(expected) {
		t.Fatalf("%s value count = %d, want %d", enum.Name(), got, len(expected))
	}
	for index, expectation := range expected {
		value := enum.Values().Get(index)
		if got := string(value.Name()); got != expectation.name {
			t.Errorf("%s value %d = %q, want %q", enum.Name(), index, got, expectation.name)
		}
		if got := value.Number(); got != expectation.number {
			t.Errorf("%s.%s number = %d, want %d", enum.Name(), expectation.name, got, expectation.number)
		}
	}
}

func requireReservedEnumValue(
	t *testing.T,
	enum protoreflect.EnumDescriptor,
	number protoreflect.EnumNumber,
	name protoreflect.Name,
) {
	t.Helper()
	if enum.Values().ByNumber(number) != nil || enum.Values().ByName(name) != nil {
		t.Fatalf("%s retired value %s=%d is still active", enum.Name(), name, number)
	}

	numberReserved := enum.ReservedRanges().Has(number)
	nameReserved := false
	for index := 0; index < enum.ReservedNames().Len(); index++ {
		if enum.ReservedNames().Get(index) == name {
			nameReserved = true
			break
		}
	}
	if !numberReserved || !nameReserved {
		t.Fatalf("%s retired value %s=%d is not fully reserved", enum.Name(), name, number)
	}
}

func requireMessage(t *testing.T, file protoreflect.FileDescriptor, name protoreflect.Name) protoreflect.MessageDescriptor {
	t.Helper()
	message := file.Messages().ByName(name)
	if message == nil {
		t.Fatalf("message %s is missing", name)
	}
	return message
}

func requireField(
	t *testing.T,
	message protoreflect.MessageDescriptor,
	name protoreflect.Name,
	number protoreflect.FieldNumber,
	kind protoreflect.Kind,
	typeName protoreflect.FullName,
) {
	t.Helper()
	field := message.Fields().ByName(name)
	if field == nil {
		t.Fatalf("field %s.%s is missing", message.Name(), name)
	}
	if got := field.Number(); got != number {
		t.Errorf("field %s.%s number = %d, want %d", message.Name(), name, got, number)
	}
	if got := field.Kind(); got != kind {
		t.Errorf("field %s.%s kind = %s, want %s", message.Name(), name, got, kind)
	}
	if typeName == "" {
		return
	}
	if kind == protoreflect.MessageKind && field.Message().FullName() != typeName {
		t.Errorf("field %s.%s type = %s, want %s", message.Name(), name, field.Message().FullName(), typeName)
	}
	if kind == protoreflect.EnumKind && field.Enum().FullName() != typeName {
		t.Errorf("field %s.%s type = %s, want %s", message.Name(), name, field.Enum().FullName(), typeName)
	}
}
