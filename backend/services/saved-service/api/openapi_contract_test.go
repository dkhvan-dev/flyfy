package api

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strings"
	"testing"
)

const openAPIContractPath = "openapi.yaml"

func TestOpenAPIContractSurface(t *testing.T) {
	spec := readContract(t)
	operations, paths := parsePathOperations(t, spec)

	expectedOperations := []string{
		"PUT /v1/users/me/saved-items/{entityType}/{entityKey}",
		"DELETE /v1/users/me/saved-items/{entityType}/{entityKey}",
		"GET /v1/users/me/saved-items",
		"POST /v1/users/me/saved-items/query",
		"POST /v1/users/me/saved-items/status:batch",
		"GET /v1/users/me/saved-items/capabilities",
		"GET /v1/users/me/saved-items/{entityType}/{entityKey}/collections",
		"PUT /v1/users/me/saved-items/{entityType}/{entityKey}/collections",
		"GET /v1/users/me/saved-operations/{operationId}",
		"POST /v1/users/me/saved-collections",
		"GET /v1/users/me/saved-collections",
		"GET /v1/users/me/saved-collections/{collectionId}",
		"PATCH /v1/users/me/saved-collections/{collectionId}",
		"DELETE /v1/users/me/saved-collections/{collectionId}",
	}

	want := make(map[string]struct{}, len(expectedOperations))
	for _, operation := range expectedOperations {
		want[operation] = struct{}{}
		if _, ok := operations[operation]; !ok {
			t.Errorf("mandatory operation %q is missing", operation)
		}
	}
	for operation := range operations {
		if _, ok := want[operation]; !ok {
			t.Errorf("unexpected operation %q; the Saved contract has an exact endpoint allowlist", operation)
		}
	}
	if len(operations) != len(want) {
		t.Errorf("operation count = %d, want exactly %d", len(operations), len(want))
	}
	for path := range paths {
		if !strings.HasPrefix(path, "/v1/users/me/") {
			t.Errorf("path %q is not versioned and owner-scoped through /users/me", path)
		}
	}

	requireContainsAll(t, spec,
		"openapi: 3.1.0",
		"security:\n  - bearerAuth: []",
		"type: http\n      scheme: bearer",
		"The authenticated owner is derived only from the verified session",
	)
	requireNoYAMLKeys(t, spec, "owner_id", "user_id", "share_token")
}

func TestExcludedFeaturesStayOutsideTheContract(t *testing.T) {
	spec := readContract(t)
	excluded := yamlBlock(t, spec, "x-excluded-features", 0)
	requireContainsAll(t, excluded,
		"mass_mutation",
		"sharing",
		"notes",
		"manual_reorder",
		"generic_aliases",
		"offline_queue_or_reconcile",
		"persistent_marker_endpoints",
	)

	// Exact path/method allowlisting is asserted separately. These key checks
	// guard against the excluded concepts being smuggled into existing bodies.
	requireNoYAMLKeys(t, spec,
		"bulk_targets",
		"confirmation",
		"confirmation_token",
		"items_version",
		"lifecycle_vector",
		"manual_order",
		"note",
		"notes",
		"offline_queue",
		"reconcile_token",
		"share",
		"sharing",
		"sort_order",
		"persistent_marker",
	)
	requireNoYAMLKeys(t, spec,
		"total",
		"total_count",
		"category_count",
		"category_counts",
		"counts_by_category",
		"country_id",
		"city_id",
	)
	requireNoYAMLKeys(t, spec, "example", "examples")
}

func TestMutationContract(t *testing.T) {
	spec := readContract(t)
	operations, _ := parsePathOperations(t, spec)

	mutations := []string{
		"PUT /v1/users/me/saved-items/{entityType}/{entityKey}",
		"DELETE /v1/users/me/saved-items/{entityType}/{entityKey}",
		"PUT /v1/users/me/saved-items/{entityType}/{entityKey}/collections",
		"POST /v1/users/me/saved-collections",
		"PATCH /v1/users/me/saved-collections/{collectionId}",
		"DELETE /v1/users/me/saved-collections/{collectionId}",
	}
	for _, mutation := range mutations {
		block := operations[mutation]
		requireContainsAll(t, block,
			"#/components/parameters/OperationIdHeader",
			"#/components/parameters/IdempotencyKeyHeader",
			"#/components/parameters/SavedSourceSurfaceHeader",
			"'200':",
			"#/components/responses/MutationTerminalResponse",
			"'202':",
			"#/components/responses/MutationPendingResponse",
		)
	}

	readOnlyPosts := []string{
		"POST /v1/users/me/saved-items/query",
		"POST /v1/users/me/saved-items/status:batch",
	}
	for _, operation := range readOnlyPosts {
		block := operations[operation]
		if strings.Contains(block, "OperationIdHeader") || strings.Contains(block, "IdempotencyKeyHeader") {
			t.Errorf("read-only operation %q must not claim mutation identities", operation)
		}
	}

	operationID := yamlBlock(t, spec, "OperationId", 4)
	requireContainsAll(t, operationID, "format: uuid", "-4[0-9a-fA-F]{3}-", "[89aAbB]")
	idempotencyHeader := yamlBlock(t, spec, "IdempotencyKeyHeader", 4)
	requireContainsAll(t, idempotencyHeader,
		"required: true",
		"independent of Operation-Id",
		"minLength: 22",
		"x-min-entropy-bits: 128",
	)
	sourceSurfaceHeader := yamlBlock(t, spec, "SavedSourceSurfaceHeader", 4)
	requireContainsAll(t, sourceSurfaceHeader,
		"required: false",
		"default: UNKNOWN",
		"UNKNOWN, CARD, DETAIL, SAVED_ALL, SAVED_COLLECTION",
	)

	operationResult := yamlBlock(t, spec, "OperationResult", 4)
	requireContainsAll(t, operationResult,
		"operation_id",
		"operation_kind",
		"operation_status",
		"operation_outcome",
		"commit_deadline",
		"refresh_scope",
		"applied_resource_versions",
		"result_recorded_at",
		"current_resource_snapshot",
		"readOnly: true",
	)
	requireContainsAll(t, yamlBlock(t, spec, "PendingOperationResult", 4), "const: PENDING")
	requireContainsAll(t, yamlBlock(t, spec, "TerminalOperationResult", 4), "SUCCEEDED", "REJECTED", "EXPIRED")
	requireContainsAll(t, yamlBlock(t, spec, "RefreshScope", 4),
		"SAVED_ITEMS", "COLLECTIONS", "BOTH", "NONE", "contains no resource IDs",
	)
	requireContainsAll(t, yamlBlock(t, spec, "CurrentResourceSnapshot", 4),
		"Fresh owner-scoped state", "not part of the immutable", "snapshot version",
	)
}

func TestProductRolloutHeadersAreBoundedAndNeverAuthorizationClaims(t *testing.T) {
	spec := readContract(t)
	platform := yamlBlock(t, spec, "ClientPlatformHeader", 4)
	requireContainsAll(t, platform,
		"name: X-Client-Platform",
		"required: false",
		"enum: [android, ios]",
		"not an authentication or authorization claim",
	)
	build := yamlBlock(t, spec, "AppBuildHeader", 4)
	requireContainsAll(t, build,
		"name: X-App-Build",
		"required: false",
		"format: uint64",
		"minimum: 1",
		"grants no data access",
	)
	if got := strings.Count(spec, "#/components/parameters/ClientPlatformHeader"); got != 9 {
		t.Fatalf("ClientPlatformHeader path references = %d, want 9", got)
	}
	if got := strings.Count(spec, "#/components/parameters/AppBuildHeader"); got != 9 {
		t.Fatalf("AppBuildHeader path references = %d, want 9", got)
	}
}

func TestGlobalUnsaveHasNoPreconditionChoreography(t *testing.T) {
	spec := readContract(t)
	operations, _ := parsePathOperations(t, spec)
	block := operations["DELETE /v1/users/me/saved-items/{entityType}/{entityKey}"]

	requireContainsAll(t, block,
		"only DELETE meaning",
		"every effective collection membership",
		"accepts no confirmation flag",
	)
	if strings.Contains(block, "requestBody:") {
		t.Error("global target DELETE must not accept a request body")
	}
	if got := strings.Count(block, "#/components/parameters/"); got != 3 {
		t.Errorf("global target DELETE has %d operation parameters, want operation, idempotency, and bounded source-surface headers", got)
	}
}

func TestLimitsAndCollectionPreconditions(t *testing.T) {
	spec := readContract(t)

	requireContainsAll(t, yamlBlock(t, spec, "BatchSavedStatusRequest", 4),
		"maxItems: 100", "uniqueItems: true",
	)
	requireContainsAll(t, yamlBlock(t, spec, "PageLimitQuery", 4),
		"maximum: 100", "default: 30",
	)
	requireContainsAll(t, yamlBlock(t, spec, "SavedItemsQueryRequest", 4),
		"maximum: 100", "default: 30", "#/components/schemas/SearchText",
	)
	requireContainsAll(t, yamlBlock(t, spec, "SearchText", 4),
		"maxLength: 200", "200 Unicode code points",
	)
	requireContainsAll(t, yamlBlock(t, spec, "DesiredCollectionAssignmentRequest", 4),
		"maxItems: 200",
		"uniqueItems: true",
		"expected_relationship",
		"expected_dependent_membership_version",
		"new_collection",
	)
	requireContainsAll(t, yamlBlock(t, spec, "CollectionTitle", 4),
		"maxLength: 80", "80 Unicode code points",
	)
	requireContainsAll(t, yamlBlock(t, spec, "SavedCollectionsList", 4), "maxItems: 200")

	expectedRelationship := yamlBlock(t, spec, "ExpectedRelationship", 4)
	requireContainsAll(t, expectedRelationship,
		"oneOf:",
		"EXPECTED_ABSENT",
		"EXPECTED_ACTIVE",
		"EXPECTED_REMOVED",
		"propertyName: state",
	)
	requireContainsAll(t, yamlBlock(t, spec, "RenameCollectionRequest", 4),
		"expected_metadata_version",
	)
	deleteCollection := yamlBlock(t, spec, "DeleteCollectionRequest", 4)
	requireContainsAll(t, deleteCollection,
		"expected_metadata_version",
		"expected_lifecycle_version",
	)
	if strings.Contains(deleteCollection, "items_version") {
		t.Error("collection deletion must not depend on an item-count version")
	}
}

func TestStatusCursorLocaleAndErrors(t *testing.T) {
	spec := readContract(t)

	savedState := yamlBlock(t, spec, "SavedState", 4)
	requireContainsAll(t, savedState, "UNKNOWN", "CONFIRMED_UNSAVED", "SAVED")
	if strings.Index(savedState, "UNKNOWN") == strings.Index(savedState, "CONFIRMED_UNSAVED") {
		t.Error("UNKNOWN and CONFIRMED_UNSAVED must remain distinct enum values")
	}

	requireContainsAll(t, yamlBlock(t, spec, "OpaqueCursor", 4),
		"Opaque AEAD-protected", "bound to owner", "effective locale", "must not parse or log",
	)
	requireContainsAll(t, yamlBlock(t, spec, "Locale", 4), "enum: [en, ru, kk]")
	requireContainsAll(t, yamlBlock(t, spec, "AcceptLanguage", 4),
		"Accept-Language", "EN, RU, or KK", "#/components/schemas/AcceptLanguageValue",
	)
	requireContainsAll(t, yamlBlock(t, spec, "RelationshipGeneration", 4),
		"format: uuid", "activation generation",
	)
	requireContainsAll(t, yamlBlock(t, spec, "UnavailableSavedCardProjection", 4),
		"additionalProperties: false", "const: UNAVAILABLE",
	)
	unavailableProjection := yamlBlock(t, spec, "UnavailableSavedCardProjection", 4)
	for _, payloadField := range []string{"title:", "subtitle:", "image_url:", "display_locale:"} {
		if strings.Contains(unavailableProjection, payloadField) {
			t.Errorf("unavailable projection contains forbidden public payload field %q", payloadField)
		}
	}

	errorCode := yamlBlock(t, spec, "ErrorCode", 4)
	for _, code := range []string{
		"SAVED_TARGET_TYPE_UNSUPPORTED",
		"SAVED_TARGET_UNAVAILABLE",
		"SAVED_DEPENDENCY_UNAVAILABLE",
		"SAVED_MUTATION_STALE",
		"SAVED_MUTATION_REPLAY_MISMATCH",
		"SAVED_COLLECTION_NOT_FOUND",
		"SAVED_COLLECTION_DELETED",
		"SAVED_COLLECTION_TITLE_INVALID",
		"SAVED_COLLECTION_TITLE_CONFLICT",
		"SAVED_COLLECTION_LIMIT_REACHED",
		"SAVED_COLLECTION_ITEM_LIMIT_REACHED",
		"SAVED_MEMBERSHIP_LIMIT_REACHED",
		"SAVED_ITEM_LIMIT_REACHED",
		"SAVED_REQUEST_IN_PROGRESS",
		"SAVED_OPERATION_EXPIRED",
		"SAVED_CURSOR_INVALID",
		"SAVED_RATE_LIMITED",
		"SAVED_TEMPORARILY_UNAVAILABLE",
		"PLATFORM_PERSONAL_DATA_LOCKED",
	} {
		requireContainsAll(t, errorCode, code)
	}
	requireContainsAll(t, yamlBlock(t, spec, "ErrorEnvelope", 4),
		"additionalProperties: false", "code:", "retryable:", "retry_after_ms:",
	)
}

func TestEveryResponseIsPrivateAndStrictSchemasAreUsed(t *testing.T) {
	spec := readContract(t)
	responses := yamlSectionChildren(t, spec, "responses", 2, 4)
	if len(responses) < 10 {
		t.Fatalf("parsed only %d reusable responses; response-section parser likely lost contract coverage", len(responses))
	}
	for name, block := range responses {
		for _, header := range []string{
			"#/components/headers/PrivateCacheControl",
			"#/components/headers/PragmaNoCache",
			"#/components/headers/ContentLanguage",
			"#/components/headers/VaryPersonal",
			"#/components/headers/RequestId",
		} {
			if !strings.Contains(block, header) {
				t.Errorf("response component %q lacks required private response header %q", name, header)
			}
		}
	}

	requireContainsAll(t, yamlBlock(t, spec, "PrivateCacheControl", 4),
		"required: true", "const: 'private, no-store'",
	)
	if got := strings.Count(spec, "additionalProperties: false"); got < 25 {
		t.Errorf("strict schema count = %d, want at least 25 additionalProperties guards", got)
	}
}

func readContract(t *testing.T) string {
	t.Helper()
	contents, err := os.ReadFile(openAPIContractPath)
	if err != nil {
		t.Fatalf("read %s: %v", openAPIContractPath, err)
	}
	return string(contents)
}

func parsePathOperations(t *testing.T, spec string) (map[string]string, map[string]struct{}) {
	t.Helper()
	lines := strings.Split(spec, "\n")
	operations := make(map[string]string)
	paths := make(map[string]struct{})
	currentPath := ""
	inPaths := false
	methods := map[string]struct{}{
		"get": {}, "put": {}, "post": {}, "delete": {}, "patch": {},
		"head": {}, "options": {}, "trace": {},
	}

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		indent := leadingSpaces(line)
		if line == "paths:" {
			inPaths = true
			continue
		}
		if !inPaths {
			continue
		}
		if trimmed != "" && indent == 0 {
			break
		}
		if indent == 2 && strings.HasPrefix(trimmed, "/") && strings.HasSuffix(trimmed, ":") {
			currentPath = strings.TrimSuffix(trimmed, ":")
			paths[currentPath] = struct{}{}
			continue
		}
		if currentPath == "" || indent != 4 || !strings.HasSuffix(trimmed, ":") {
			continue
		}
		method := strings.TrimSuffix(trimmed, ":")
		if _, ok := methods[method]; !ok {
			continue
		}

		end := len(lines)
		for j := i + 1; j < len(lines); j++ {
			if strings.TrimSpace(lines[j]) == "" {
				continue
			}
			if leadingSpaces(lines[j]) <= 4 {
				end = j
				break
			}
		}
		key := strings.ToUpper(method) + " " + currentPath
		if _, duplicate := operations[key]; duplicate {
			t.Fatalf("duplicate OpenAPI operation %q", key)
		}
		operations[key] = strings.Join(lines[i:end], "\n")
	}

	return operations, paths
}

func yamlBlock(t *testing.T, spec, name string, indent int) string {
	t.Helper()
	lines := strings.Split(spec, "\n")
	marker := strings.Repeat(" ", indent) + name + ":"
	for i, line := range lines {
		if line != marker {
			continue
		}
		end := len(lines)
		for j := i + 1; j < len(lines); j++ {
			if strings.TrimSpace(lines[j]) == "" {
				continue
			}
			if leadingSpaces(lines[j]) <= indent {
				end = j
				break
			}
		}
		return strings.Join(lines[i:end], "\n")
	}
	t.Fatalf("YAML block %q at indentation %d not found", name, indent)
	return ""
}

func yamlSectionChildren(t *testing.T, spec, section string, sectionIndent, childIndent int) map[string]string {
	t.Helper()
	sectionBlock := yamlBlock(t, spec, section, sectionIndent)
	lines := strings.Split(sectionBlock, "\n")
	children := make(map[string]string)
	for i := 1; i < len(lines); i++ {
		line := lines[i]
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || leadingSpaces(line) != childIndent || !strings.HasSuffix(trimmed, ":") {
			continue
		}
		name := strings.TrimSuffix(trimmed, ":")
		end := len(lines)
		for j := i + 1; j < len(lines); j++ {
			if strings.TrimSpace(lines[j]) == "" {
				continue
			}
			if leadingSpaces(lines[j]) <= childIndent {
				end = j
				break
			}
		}
		children[name] = strings.Join(lines[i:end], "\n")
	}
	return children
}

func requireContainsAll(t *testing.T, value string, fragments ...string) {
	t.Helper()
	for _, fragment := range fragments {
		if !strings.Contains(value, fragment) {
			t.Errorf("required contract fragment %q is missing", fragment)
		}
	}
}

func requireNoYAMLKeys(t *testing.T, spec string, forbidden ...string) {
	t.Helper()
	forbiddenSet := make(map[string]struct{}, len(forbidden))
	for _, key := range forbidden {
		forbiddenSet[strings.ToLower(key)] = struct{}{}
	}

	var found []string
	scanner := bufio.NewScanner(strings.NewReader(spec))
	lineNumber := 0
	for scanner.Scan() {
		lineNumber++
		trimmed := strings.TrimSpace(scanner.Text())
		if !strings.HasSuffix(trimmed, ":") {
			continue
		}
		key := strings.ToLower(strings.TrimSpace(strings.TrimSuffix(trimmed, ":")))
		if _, banned := forbiddenSet[key]; banned {
			found = append(found, fmt.Sprintf("%s at line %d", key, lineNumber))
		}
	}
	if err := scanner.Err(); err != nil {
		t.Fatalf("scan OpenAPI contract: %v", err)
	}
	if len(found) > 0 {
		sort.Strings(found)
		t.Errorf("forbidden YAML keys present: %s", strings.Join(found, ", "))
	}
}

func leadingSpaces(line string) int {
	return len(line) - len(strings.TrimLeft(line, " "))
}
