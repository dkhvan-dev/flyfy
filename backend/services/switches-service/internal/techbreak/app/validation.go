package app

import (
	"regexp"
	"strings"
	"time"
)

var (
	scopeCodePattern  = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_-]*$`)
	domainCodePattern = regexp.MustCompile(`^[A-Za-z]+(?:_[A-Za-z]+)*$`)
)

func ValidateTechBreakUpsert(request TechBreakUpsertRequest) error {
	if strings.TrimSpace(request.DomainCode) == "" {
		return BadRequest("Не заполнен код домена/продукта")
	}
	if strings.TrimSpace(request.Name) == "" {
		return BadRequest("Не заполнено наименование")
	}
	if request.ActionStartDate.IsZero() {
		return BadRequest("Не заполнена дата начала действия")
	}
	if request.ActionEndDate != nil && !request.ActionStartDate.Before(*request.ActionEndDate) {
		return BadRequest("Дата начала действия не может быть позже или равной дате окончания")
	}
	return nil
}

func ValidateTechBreakCheck(request TechBreakCheckRequest) error {
	if strings.TrimSpace(request.DomainCode) == "" {
		return BadRequest("Не передан код домена/продукта")
	}
	return nil
}

func ValidateTechBreakScopeCreate(request TechBreakScopeCreateRequest) error {
	if strings.TrimSpace(request.DomainCode) == "" {
		return BadRequest("Не заполнен код домена/продукта")
	}
	if strings.TrimSpace(request.Code) == "" {
		return BadRequest("Не заполнен код scope'а")
	}
	if !validSeparatedCode(request.Code) {
		return BadRequest("Код scope'а: латиница/цифры, начинается с буквы; '-' и '_' допускаются только внутри")
	}
	if strings.TrimSpace(request.Name) == "" {
		return BadRequest("Не заполнено наименование")
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

func ComputeTechBreakEnabled(actionStartDate time.Time, actionEndDate *time.Time, now time.Time) bool {
	start := TruncateToMinute(actionStartDate)
	current := TruncateToMinute(now)
	if start.After(current) {
		return false
	}
	if actionEndDate != nil && !actionEndDate.After(current) {
		return false
	}
	return true
}

func ActiveBreakMatches(techBreak TechBreakDetail, request TechBreakCheckRequest) bool {
	if !techBreak.Enabled {
		return false
	}
	if request.Nickname != "" && containsString(techBreak.ExcludeNicknames, request.Nickname) {
		return false
	}
	if request.Email != "" && containsString(techBreak.ExcludeEmails, request.Email) {
		return false
	}
	if len(request.ScopeCodes) > 0 {
		if len(techBreak.ScopeCodes) > 0 && !intersects(techBreak.ScopeCodes, request.ScopeCodes) {
			return false
		}
	} else if len(techBreak.ScopeCodes) > 0 {
		return false
	}
	return true
}

func validSeparatedCode(code string) bool {
	if !scopeCodePattern.MatchString(code) {
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

func containsString(values []string, needle string) bool {
	for _, value := range values {
		if value == needle {
			return true
		}
	}
	return false
}

func intersects(left []string, right []string) bool {
	set := make(map[string]struct{}, len(left))
	for _, value := range left {
		set[value] = struct{}{}
	}
	for _, value := range right {
		if _, ok := set[value]; ok {
			return true
		}
	}
	return false
}
