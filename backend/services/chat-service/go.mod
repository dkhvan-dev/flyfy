module github.com/dkhvan-dev/flyfy/backend/services/chat-service

go 1.26

require (
	github.com/google/uuid v1.6.0
	github.com/sethvargo/go-envconfig v1.3.0
)

require github.com/google/go-cmp v0.7.0 // indirect

replace github.com/dkhvan-dev/flyfy/proto => ../../../proto
