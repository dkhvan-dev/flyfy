package app

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var (
	featureFlagCodePattern = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_-]*$`)
	domainCodePattern      = regexp.MustCompile(`^[A-Za-z]+(?:_[A-Za-z]+)*$`)
)

const (
	msgFeatureFlagCodeInvalid = "Код флага: латиница/цифры, начинается с буквы; '-' и '_' допускаются только внутри"
	msgValueRequired          = "Не заполнен список значений"
	msgValueTypeMismatch      = "Тип данных значения флага должен быть в соответствии с типом фича флага"
	msgInvalidDateRange       = "Дата начала действия не может быть позже или равной дате окончания"
	msgEnabledFutureStart     = "Нельзя включать флаг с будущей датой начала действия. Планировщик сам включит флаг в указанную дату и время!"
)

func ValidateFeatureFlagCreate(request FeatureFlagCreateRequest, now time.Time) error {
	if strings.TrimSpace(request.DomainCode) == "" {
		return BadRequest("Не заполнен код домена/продукта")
	}
	if strings.TrimSpace(request.Code) == "" {
		return BadRequest("Не заполнен код флага")
	}
	if !validSeparatedCode(request.Code) {
		return BadRequest(msgFeatureFlagCodeInvalid)
	}
	return validateFeatureFlagFields(
		request.Name,
		request.Group,
		request.Type,
		request.Enabled,
		request.ActionStartDate,
		request.ActionEndDate,
		request.Value,
		now,
		true,
	)
}

func ValidateFeatureFlagUpdate(request FeatureFlagUpdateRequest, now time.Time) error {
	if strings.TrimSpace(request.DomainCode) == "" {
		return BadRequest("Не заполнен код домена/продукта")
	}
	return validateFeatureFlagFields(
		request.Name,
		request.Group,
		request.Type,
		request.Enabled,
		request.ActionStartDate,
		request.ActionEndDate,
		request.Value,
		now,
		false,
	)
}

func validateFeatureFlagFields(
	name string,
	group string,
	flagType FeatureFlagType,
	enabled bool,
	actionStartDate time.Time,
	actionEndDate *time.Time,
	value []any,
	now time.Time,
	requireArrayValue bool,
) error {
	if strings.TrimSpace(name) == "" {
		return BadRequest("Не заполнено наименование")
	}
	if strings.TrimSpace(group) == "" {
		return BadRequest("Не заполнена группа (категория)")
	}
	if !isKnownFeatureFlagType(flagType) {
		return BadRequest("Не заполнен тип флага")
	}
	if actionStartDate.IsZero() {
		return BadRequest("Не заполнена дата начала действия")
	}
	if actionEndDate != nil && !actionStartDate.Before(*actionEndDate) {
		return BadRequest(msgInvalidDateRange)
	}
	if enabled && TruncateToMinute(actionStartDate).After(TruncateToMinute(now)) {
		return BadRequest(msgEnabledFutureStart)
	}
	if requireArrayValue && flagType != FeatureFlagTypeToggle && len(value) == 0 {
		return BadRequest(msgValueRequired)
	}
	if !featureFlagValueMatchesType(flagType, value) {
		return BadRequest(msgValueTypeMismatch)
	}
	return nil
}

func ValidateDomainCreate(request DomainCreateRequest) error {
	if strings.TrimSpace(request.Code) == "" {
		return BadRequest("Не заполнен код домена/продукта")
	}
	if !domainCodePattern.MatchString(request.Code) {
		return BadRequest("Код домена/продукта может содержать только латинские буквы и \"_\". Начинаться должен строго с буквы.")
	}
	if strings.TrimSpace(request.Description) == "" {
		return BadRequest("Не заполнено описание")
	}
	return nil
}

func NormalizeFeatureFlagValue(flagType FeatureFlagType, values []string) ([]any, error) {
	result := make([]any, 0, len(values))
	for _, raw := range values {
		switch flagType {
		case FeatureFlagTypeToggle:
			value, err := strconv.ParseBool(raw)
			if err != nil {
				return nil, fmt.Errorf("%s: %w", msgValueTypeMismatch, err)
			}
			result = append(result, value)
		case FeatureFlagTypeArrayInteger:
			value, err := strconv.Atoi(raw)
			if err != nil {
				return nil, fmt.Errorf("%s: %w", msgValueTypeMismatch, err)
			}
			result = append(result, value)
		case FeatureFlagTypeArrayString:
			result = append(result, raw)
		default:
			return nil, BadRequest("Не заполнен тип флага")
		}
	}
	return result, nil
}

func FeatureFlagValueToStrings(values []any) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		result = append(result, fmt.Sprint(value))
	}
	return result
}

func isKnownFeatureFlagType(flagType FeatureFlagType) bool {
	switch flagType {
	case FeatureFlagTypeToggle, FeatureFlagTypeArrayInteger, FeatureFlagTypeArrayString:
		return true
	default:
		return false
	}
}

func validSeparatedCode(code string) bool {
	if !featureFlagCodePattern.MatchString(code) {
		return false
	}
	previousWasSeparator := false
	for _, char := range code[1:] {
		isSeparator := char == '-' || char == '_'
		if isSeparator && previousWasSeparator {
			return false
		}
		previousWasSeparator = isSeparator
	}
	return !previousWasSeparator
}

func featureFlagValueMatchesType(flagType FeatureFlagType, values []any) bool {
	if len(values) == 0 {
		return true
	}
	switch flagType {
	case FeatureFlagTypeToggle:
		if len(values) != 1 {
			return false
		}
		_, ok := values[0].(bool)
		return ok
	case FeatureFlagTypeArrayString:
		for _, value := range values {
			if _, ok := value.(string); !ok {
				return false
			}
		}
		return true
	case FeatureFlagTypeArrayInteger:
		for _, value := range values {
			if !isIntegerValue(value) {
				return false
			}
		}
		return true
	default:
		return false
	}
}

func isIntegerValue(value any) bool {
	switch v := value.(type) {
	case int:
		return true
	case int32:
		return true
	case int64:
		return true
	case float64:
		return v == float64(int64(v))
	case float32:
		return v == float32(int64(v))
	default:
		return false
	}
}
