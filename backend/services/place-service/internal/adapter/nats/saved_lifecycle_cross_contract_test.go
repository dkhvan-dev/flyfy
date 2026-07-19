package nats

import (
	"go/ast"
	"go/parser"
	"go/token"
	"path/filepath"
	"strconv"
	"testing"
	"time"
)

type savedSourceStreamContract struct {
	name            string
	subjectPattern  string
	storage         string
	retention       string
	maxAge          time.Duration
	maxBytes        int64
	discard         string
	duplicateWindow time.Duration
}

func TestSavedSourceSharedStreamContractMatchesActivityAndGuide(t *testing.T) {
	t.Parallel()

	want := savedSourceStreamContract{
		name:            SavedSourceStreamName,
		subjectPattern:  SavedSourceSubjectPattern,
		storage:         "FileStorage",
		retention:       "LimitsPolicy",
		maxAge:          SavedSourceStreamMaxAge,
		maxBytes:        SavedSourceStreamMaxBytes,
		discard:         "DiscardOld",
		duplicateWindow: SavedSourceDuplicateWindow,
	}
	if DefaultSavedLifecycleSubject != "saved.source.attraction.lifecycle.v1" {
		t.Fatalf("Place lifecycle subject drifted to %q", DefaultSavedLifecycleSubject)
	}

	servicesRoot := filepath.Join("..", "..", "..", "..")
	producers := map[string]string{
		"activity": filepath.Join(
			servicesRoot,
			"activity-service",
			"internal",
			"adapter",
			"nats",
			"saved_lifecycle_publisher.go",
		),
		"guide": filepath.Join(
			servicesRoot,
			"guide-service",
			"internal",
			"adapter",
			"nats",
			"saved_lifecycle_publisher.go",
		),
	}
	for producer, path := range producers {
		producer := producer
		path := path
		t.Run(producer, func(t *testing.T) {
			t.Parallel()
			if got := parseSavedSourceStreamContract(t, path); got != want {
				t.Fatalf("%s SAVED_SOURCE contract = %+v, want %+v", producer, got, want)
			}
		})
	}

	activitySubjectPath := filepath.Join(
		servicesRoot,
		"activity-service",
		"internal",
		"domain",
		"model",
		"saved_lifecycle_outbox.go",
	)
	if got := parseStringConstant(t, activitySubjectPath, "ActivitySavedLifecycleSubjectV1"); got != "saved.source.activity.lifecycle.v1" {
		t.Fatalf("Activity lifecycle subject drifted to %q", got)
	}
	if got := parseStringConstant(t, producers["guide"], "DefaultSavedLifecycleSubject"); got != "saved.source.guide.lifecycle.v1" {
		t.Fatalf("Guide lifecycle subject drifted to %q", got)
	}
}

func parseSavedSourceStreamContract(t *testing.T, path string) savedSourceStreamContract {
	t.Helper()
	file, constants := parseGoFileAndConstants(t, path)
	var literal *ast.CompositeLit
	ast.Inspect(file, func(node ast.Node) bool {
		candidate, ok := node.(*ast.CompositeLit)
		if !ok {
			return true
		}
		selector, ok := candidate.Type.(*ast.SelectorExpr)
		if ok && selector.Sel.Name == "StreamConfig" {
			literal = candidate
			return false
		}
		return true
	})
	if literal == nil {
		t.Fatalf("%s does not define jetstream.StreamConfig", path)
	}

	fields := make(map[string]ast.Expr, len(literal.Elts))
	for _, element := range literal.Elts {
		pair, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, ok := pair.Key.(*ast.Ident)
		if ok {
			fields[key.Name] = pair.Value
		}
	}
	subjects, ok := fields["Subjects"].(*ast.CompositeLit)
	if !ok || len(subjects.Elts) != 1 {
		t.Fatalf("%s must configure exactly one shared subject pattern", path)
	}

	return savedSourceStreamContract{
		name:            evalStringExpression(t, fields["Name"], constants),
		subjectPattern:  evalStringExpression(t, subjects.Elts[0], constants),
		storage:         selectorValue(t, fields["Storage"]),
		retention:       selectorValue(t, fields["Retention"]),
		maxAge:          time.Duration(evalIntegerExpression(t, fields["MaxAge"], constants)),
		maxBytes:        evalIntegerExpression(t, fields["MaxBytes"], constants),
		discard:         selectorValue(t, fields["Discard"]),
		duplicateWindow: time.Duration(evalIntegerExpression(t, fields["Duplicates"], constants)),
	}
}

func parseStringConstant(t *testing.T, path string, name string) string {
	t.Helper()
	_, constants := parseGoFileAndConstants(t, path)
	expression, ok := constants[name]
	if !ok {
		t.Fatalf("%s does not define constant %s", path, name)
	}
	return evalStringExpression(t, expression, constants)
}

func parseGoFileAndConstants(t *testing.T, path string) (*ast.File, map[string]ast.Expr) {
	t.Helper()
	file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
	if err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
	constants := make(map[string]ast.Expr)
	for _, declaration := range file.Decls {
		group, ok := declaration.(*ast.GenDecl)
		if !ok || group.Tok != token.CONST {
			continue
		}
		for _, specification := range group.Specs {
			values, ok := specification.(*ast.ValueSpec)
			if !ok || len(values.Values) != len(values.Names) {
				continue
			}
			for index, name := range values.Names {
				constants[name.Name] = values.Values[index]
			}
		}
	}
	return file, constants
}

func evalStringExpression(t *testing.T, expression ast.Expr, constants map[string]ast.Expr) string {
	t.Helper()
	switch value := expression.(type) {
	case *ast.BasicLit:
		if value.Kind != token.STRING {
			break
		}
		decoded, err := strconv.Unquote(value.Value)
		if err != nil {
			t.Fatalf("decode string constant %s: %v", value.Value, err)
		}
		return decoded
	case *ast.Ident:
		resolved, ok := constants[value.Name]
		if ok {
			return evalStringExpression(t, resolved, constants)
		}
	}
	t.Fatalf("unsupported string expression %T", expression)
	return ""
}

func evalIntegerExpression(t *testing.T, expression ast.Expr, constants map[string]ast.Expr) int64 {
	t.Helper()
	switch value := expression.(type) {
	case *ast.BasicLit:
		if value.Kind == token.INT {
			parsed, err := strconv.ParseInt(value.Value, 0, 64)
			if err == nil {
				return parsed
			}
		}
	case *ast.Ident:
		resolved, ok := constants[value.Name]
		if ok {
			return evalIntegerExpression(t, resolved, constants)
		}
	case *ast.SelectorExpr:
		packageName, ok := value.X.(*ast.Ident)
		if ok && packageName.Name == "time" {
			switch value.Sel.Name {
			case "Hour":
				return int64(time.Hour)
			case "Minute":
				return int64(time.Minute)
			}
		}
	case *ast.BinaryExpr:
		left := evalIntegerExpression(t, value.X, constants)
		right := evalIntegerExpression(t, value.Y, constants)
		switch value.Op {
		case token.ADD:
			return left + right
		case token.SUB:
			return left - right
		case token.MUL:
			return left * right
		case token.QUO:
			return left / right
		}
	case *ast.ParenExpr:
		return evalIntegerExpression(t, value.X, constants)
	}
	t.Fatalf("unsupported integer expression %T", expression)
	return 0
}

func selectorValue(t *testing.T, expression ast.Expr) string {
	t.Helper()
	selector, ok := expression.(*ast.SelectorExpr)
	if !ok {
		t.Fatalf("unsupported selector expression %T", expression)
	}
	return selector.Sel.Name
}
