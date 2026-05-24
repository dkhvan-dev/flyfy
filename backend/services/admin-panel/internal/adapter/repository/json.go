package repository

import "encoding/json"

func jsonParam(raw json.RawMessage) any {
	if len(raw) == 0 {
		return nil
	}
	return string(raw)
}
