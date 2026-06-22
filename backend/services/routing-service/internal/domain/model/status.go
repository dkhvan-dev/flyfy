package model

type RoutingServiceStatus string

const (
	RoutingStatusOK       RoutingServiceStatus = "ok"
	RoutingStatusDegraded RoutingServiceStatus = "degraded"
)

type RoutingStatusResponse struct {
	Status  RoutingServiceStatus `json:"status"`
	Engines []EngineStatus       `json:"engines"`
	Data    RoutingDataStatus    `json:"data"`
}

type EngineStatus struct {
	Name      string `json:"name"`
	Enabled   bool   `json:"enabled"`
	Reachable bool   `json:"reachable"`
	Status    string `json:"status"`
	Version   string `json:"version,omitempty"`
	Error     string `json:"error,omitempty"`
}

type RoutingDataStatus struct {
	Region              string `json:"region,omitempty"`
	OSMSource           string `json:"osmSource,omitempty"`
	OSMDataVersion      string `json:"osmDataVersion,omitempty"`
	TransitEnabled      bool   `json:"transitEnabled"`
	TransitCityCode     string `json:"transitCityCode,omitempty"`
	GTFSVersion         string `json:"gtfsVersion,omitempty"`
	GeneratedAt         string `json:"generatedAt,omitempty"`
	AttributionRequired bool   `json:"attributionRequired"`
}
