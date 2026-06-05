package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"math"
	mrand "math/rand"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

type operation string

const (
	opListConversations operation = "list_conversations"
	opListMessages      operation = "list_messages"
	opSendMessage       operation = "send_message"
)

type actor struct {
	token   string
	subject string
	userID  string
}

type config struct {
	baseURL             string
	duration            time.Duration
	concurrency         int
	maxRequests         int
	requestTimeout      time.Duration
	conversationIDs     []string
	actors              []actor
	listConversationWgt int
	listMessagesWgt     int
	sendMessageWgt      int
}

type recorder struct {
	mu           sync.Mutex
	latencies    []time.Duration
	byOp         map[operation]*opStats
	errorSamples []string
}

type opStats struct {
	total   int64
	success int64
	errors  int64
}

func main() {
	cfg, err := parseConfig()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}

	if err := run(cfg); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func parseConfig() (config, error) {
	var cfg config
	flag.StringVar(&cfg.baseURL, "base-url", envString("CHAT_LOAD_BASE_URL", "http://127.0.0.1:8088/v1"), "chat API base URL")
	flag.DurationVar(&cfg.duration, "duration", envDuration("CHAT_LOAD_DURATION", 30*time.Second), "test duration")
	flag.IntVar(&cfg.concurrency, "concurrency", envInt("CHAT_LOAD_CONCURRENCY", 16), "number of concurrent workers")
	flag.IntVar(&cfg.maxRequests, "max-requests", envInt("CHAT_LOAD_MAX_REQUESTS", 0), "optional max request count; 0 means unlimited until duration")
	flag.DurationVar(&cfg.requestTimeout, "timeout", envDuration("CHAT_LOAD_REQUEST_TIMEOUT", 3*time.Second), "per-request timeout")
	flag.IntVar(&cfg.listConversationWgt, "list-conversations-weight", envInt("CHAT_LOAD_LIST_CONVERSATIONS_WEIGHT", 45), "weight for GET /conversations")
	flag.IntVar(&cfg.listMessagesWgt, "list-messages-weight", envInt("CHAT_LOAD_LIST_MESSAGES_WEIGHT", 40), "weight for GET /conversations/{id}/messages")
	flag.IntVar(&cfg.sendMessageWgt, "send-message-weight", envInt("CHAT_LOAD_SEND_MESSAGE_WEIGHT", 15), "weight for POST /conversations/{id}/messages")
	conversationIDs := flag.String("conversation-ids", envString("CHAT_LOAD_CONVERSATION_IDS", ""), "comma-separated conversation IDs")
	tokens := flag.String("tokens", envString("CHAT_LOAD_AUTH_TOKENS", ""), "comma-separated bearer tokens for gateway mode")
	subjects := flag.String("subjects", envString("CHAT_LOAD_AUTH_SUBJECTS", ""), "comma-separated trusted gateway subjects for direct service mode")
	userIDs := flag.String("user-ids", envString("CHAT_LOAD_USER_IDS", ""), "comma-separated trusted gateway user IDs for direct service mode")
	flag.Parse()

	cfg.baseURL = strings.TrimRight(strings.TrimSpace(cfg.baseURL), "/")
	cfg.conversationIDs = splitCSV(*conversationIDs)
	cfg.actors = buildActors(splitCSV(*tokens), splitCSV(*subjects), splitCSV(*userIDs))

	if cfg.baseURL == "" {
		return cfg, errors.New("base URL is required")
	}
	if cfg.duration <= 0 {
		return cfg, errors.New("duration must be positive")
	}
	if cfg.concurrency <= 0 {
		return cfg, errors.New("concurrency must be positive")
	}
	if cfg.maxRequests < 0 {
		return cfg, errors.New("max requests cannot be negative")
	}
	if cfg.requestTimeout <= 0 {
		return cfg, errors.New("timeout must be positive")
	}
	if len(cfg.actors) == 0 {
		return cfg, errors.New("provide CHAT_LOAD_AUTH_TOKENS or CHAT_LOAD_AUTH_SUBJECTS/CHAT_LOAD_USER_IDS")
	}
	if cfg.listMessagesWgt+cfg.sendMessageWgt > 0 && len(cfg.conversationIDs) == 0 {
		return cfg, errors.New("conversation IDs are required when message operations are enabled")
	}
	if cfg.listConversationWgt+cfg.listMessagesWgt+cfg.sendMessageWgt <= 0 {
		return cfg, errors.New("at least one operation weight must be positive")
	}
	return cfg, nil
}

func run(cfg config) error {
	ctx, cancel := context.WithTimeout(context.Background(), cfg.duration)
	defer cancel()

	client := &http.Client{Timeout: cfg.requestTimeout}
	rec := &recorder{
		byOp: map[operation]*opStats{
			opListConversations: {},
			opListMessages:      {},
			opSendMessage:       {},
		},
	}
	startedAt := time.Now()
	var wg sync.WaitGroup
	var sequence uint64
	var startedRequests uint64

	for workerID := 0; workerID < cfg.concurrency; workerID++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			rng := mrand.New(mrand.NewSource(time.Now().UnixNano() + int64(workerID)*997))
			for {
				select {
				case <-ctx.Done():
					return
				default:
				}
				if cfg.maxRequests > 0 && atomic.AddUint64(&startedRequests, 1) > uint64(cfg.maxRequests) {
					return
				}
				op := chooseOperation(cfg, rng)
				actor := cfg.actors[rng.Intn(len(cfg.actors))]
				conversationID := ""
				if len(cfg.conversationIDs) > 0 {
					conversationID = cfg.conversationIDs[rng.Intn(len(cfg.conversationIDs))]
				}
				reqCtx, cancelReq := context.WithTimeout(context.Background(), cfg.requestTimeout)
				req, err := buildRequest(reqCtx, cfg, op, actor, conversationID, atomic.AddUint64(&sequence, 1))
				if err != nil {
					cancelReq()
					rec.record(op, 0, err)
					continue
				}
				started := time.Now()
				resp, err := client.Do(req)
				cancelReq()
				elapsed := time.Since(started)
				if resp != nil {
					_, _ = io.Copy(io.Discard, resp.Body)
					_ = resp.Body.Close()
				}
				if err == nil && !expectedStatus(op, resp.StatusCode) {
					err = fmt.Errorf("unexpected HTTP %d", resp.StatusCode)
				}
				rec.record(op, elapsed, err)
			}
		}(workerID)
	}

	wg.Wait()
	printSummary(cfg, rec.snapshot(), time.Since(startedAt))
	return nil
}

func chooseOperation(cfg config, rng *mrand.Rand) operation {
	total := cfg.listConversationWgt + cfg.listMessagesWgt + cfg.sendMessageWgt
	n := rng.Intn(total)
	if n < cfg.listConversationWgt {
		return opListConversations
	}
	n -= cfg.listConversationWgt
	if n < cfg.listMessagesWgt {
		return opListMessages
	}
	return opSendMessage
}

func buildRequest(
	ctx context.Context,
	cfg config,
	op operation,
	actor actor,
	conversationID string,
	sequence uint64,
) (*http.Request, error) {
	var method string
	var url string
	var body io.Reader

	switch op {
	case opListConversations:
		method = http.MethodGet
		url = cfg.baseURL + "/conversations?limit=20"
	case opListMessages:
		method = http.MethodGet
		url = cfg.baseURL + "/conversations/" + conversationID + "/messages?limit=50"
	case opSendMessage:
		method = http.MethodPost
		url = cfg.baseURL + "/conversations/" + conversationID + "/messages"
		payload := map[string]any{
			"type":            "text",
			"content":         fmt.Sprintf("load-smoke %d %s", sequence, time.Now().UTC().Format(time.RFC3339Nano)),
			"clientMessageId": uuidV4(),
		}
		data, err := json.Marshal(payload)
		if err != nil {
			return nil, err
		}
		body = bytes.NewReader(data)
	default:
		return nil, fmt.Errorf("unknown operation %q", op)
	}

	req, err := http.NewRequestWithContext(ctx, method, url, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("X-Request-Id", "chat-load-"+uuidV4())
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if actor.token != "" {
		req.Header.Set("Authorization", "Bearer "+actor.token)
	}
	if actor.subject != "" {
		req.Header.Set("X-Auth-Subject", actor.subject)
	}
	if actor.userID != "" {
		req.Header.Set("X-User-Id", actor.userID)
	}
	return req, nil
}

func expectedStatus(op operation, status int) bool {
	switch op {
	case opSendMessage:
		return status == http.StatusCreated
	default:
		return status == http.StatusOK
	}
}

func (r *recorder) record(op operation, latency time.Duration, err error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	stats := r.byOp[op]
	stats.total++
	if err != nil {
		stats.errors++
		if len(r.errorSamples) < 5 {
			r.errorSamples = append(r.errorSamples, fmt.Sprintf("%s: %v", op, err))
		}
		return
	}
	stats.success++
	r.latencies = append(r.latencies, latency)
}

func (r *recorder) snapshot() recorder {
	r.mu.Lock()
	defer r.mu.Unlock()

	latencies := append([]time.Duration(nil), r.latencies...)
	errorSamples := append([]string(nil), r.errorSamples...)
	byOp := make(map[operation]*opStats, len(r.byOp))
	for op, stats := range r.byOp {
		copyStats := *stats
		byOp[op] = &copyStats
	}
	return recorder{latencies: latencies, byOp: byOp, errorSamples: errorSamples}
}

func printSummary(cfg config, rec recorder, elapsed time.Duration) {
	var total int64
	var success int64
	var failures int64
	for _, stats := range rec.byOp {
		total += stats.total
		success += stats.success
		failures += stats.errors
	}

	sort.Slice(rec.latencies, func(i, j int) bool {
		return rec.latencies[i] < rec.latencies[j]
	})

	fmt.Printf("chat load smoke\n")
	fmt.Printf("base_url=%s duration=%s concurrency=%d max_requests=%d elapsed=%s\n", cfg.baseURL, cfg.duration, cfg.concurrency, cfg.maxRequests, elapsed.Round(time.Millisecond))
	fmt.Printf("requests=%d success=%d errors=%d rps=%.2f error_rate=%.2f%%\n", total, success, failures, float64(total)/elapsed.Seconds(), percentage(failures, total))
	fmt.Printf("latency_success p50=%s p95=%s p99=%s max=%s\n", percentile(rec.latencies, 50), percentile(rec.latencies, 95), percentile(rec.latencies, 99), maxLatency(rec.latencies))
	for _, op := range []operation{opListConversations, opListMessages, opSendMessage} {
		stats := rec.byOp[op]
		fmt.Printf("%s total=%d success=%d errors=%d\n", op, stats.total, stats.success, stats.errors)
	}
	if len(rec.errorSamples) > 0 {
		fmt.Printf("error_samples:\n")
		for _, sample := range rec.errorSamples {
			fmt.Printf("- %s\n", sample)
		}
	}
}

func percentile(latencies []time.Duration, p int) time.Duration {
	if len(latencies) == 0 {
		return 0
	}
	rank := int(math.Ceil(float64(p)/100*float64(len(latencies)))) - 1
	if rank < 0 {
		rank = 0
	}
	if rank >= len(latencies) {
		rank = len(latencies) - 1
	}
	return latencies[rank].Round(time.Millisecond)
}

func maxLatency(latencies []time.Duration) time.Duration {
	if len(latencies) == 0 {
		return 0
	}
	return latencies[len(latencies)-1].Round(time.Millisecond)
}

func percentage(part, total int64) float64 {
	if total == 0 {
		return 0
	}
	return float64(part) / float64(total) * 100
}

func buildActors(tokens, subjects, userIDs []string) []actor {
	size := max(len(tokens), max(len(subjects), len(userIDs)))
	actors := make([]actor, 0, size)
	for i := 0; i < size; i++ {
		actors = append(actors, actor{
			token:   valueAt(tokens, i),
			subject: valueAt(subjects, i),
			userID:  valueAt(userIDs, i),
		})
	}
	return actors
}

func splitCSV(value string) []string {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		if trimmed := strings.TrimSpace(part); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func valueAt(values []string, index int) string {
	if index < len(values) {
		return values[index]
	}
	return ""
}

func envString(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}

func envInt(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func envDuration(key string, fallback time.Duration) time.Duration {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := time.ParseDuration(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func uuidV4() string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return fmt.Sprintf("%d", time.Now().UnixNano())
	}
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	dst := make([]byte, 36)
	hex.Encode(dst[0:8], b[0:4])
	dst[8] = '-'
	hex.Encode(dst[9:13], b[4:6])
	dst[13] = '-'
	hex.Encode(dst[14:18], b[6:8])
	dst[18] = '-'
	hex.Encode(dst[19:23], b[8:10])
	dst[23] = '-'
	hex.Encode(dst[24:], b[10:])
	return string(dst)
}
