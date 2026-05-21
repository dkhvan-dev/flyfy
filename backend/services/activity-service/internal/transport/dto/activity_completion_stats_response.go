package dto

type ActivityCompletionStatsResponse struct {
	UserID          string `json:"userId"`
	HostedCompleted int    `json:"hostedCompleted"`
	JoinedCompleted int    `json:"joinedCompleted"`
	TotalCompleted  int    `json:"totalCompleted"`
}
