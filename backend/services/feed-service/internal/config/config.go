package config

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/sethvargo/go-envconfig"
)

type Config struct {
	App          AppConfig
	HTTP         HTTPConfig
	Postgres     PostgresConfig
	Redis        RedisConfig
	Log          LogConfig
	Security     SecurityConfig
	UserService  UserServiceConfig
	FileManager  FileManagerConfig
	Notification NotificationServiceConfig
	Activity     ActivityServiceConfig
	Public       PublicConfig
	Feed         FeedConfig
}

type AppConfig struct {
	Env string `env:"APP_ENV, default=development"`
}

func (a AppConfig) IsProduction() bool {
	return strings.EqualFold(a.Env, "production")
}

type HTTPConfig struct {
	Port         int           `env:"HTTP_PORT, default=8087"`
	ReadTimeout  time.Duration `env:"HTTP_READ_TIMEOUT, default=15s"`
	WriteTimeout time.Duration `env:"HTTP_WRITE_TIMEOUT, default=15s"`
	IdleTimeout  time.Duration `env:"HTTP_IDLE_TIMEOUT, default=60s"`
}

func (h HTTPConfig) Address() string {
	return fmt.Sprintf(":%d", h.Port)
}

type PostgresConfig struct {
	Host            string `env:"POSTGRES_HOST, required"`
	Port            int    `env:"POSTGRES_PORT, default=5432"`
	User            string `env:"POSTGRES_USER, required"`
	Password        string `env:"POSTGRES_PASSWORD, required"`
	DBName          string `env:"POSTGRES_DB, required"`
	SSLMode         string `env:"POSTGRES_SSLMODE, default=disable"`
	MaxOpenConns    int32  `env:"POSTGRES_MAX_OPEN_CONNS, default=10"`
	MinOpenConns    int32  `env:"POSTGRES_MIN_OPEN_CONNS, default=2"`
	MaxConnLifetime string `env:"POSTGRES_MAX_CONN_LIFETIME, default=1h"`
	MaxConnIdleTime string `env:"POSTGRES_MAX_CONN_IDLE_TIME, default=30m"`
}

type RedisConfig struct {
	FeedCacheEnabled bool          `env:"FEED_CACHE_ENABLED, default=false"`
	Addr             string        `env:"REDIS_ADDR, default=localhost:6379"`
	Password         string        `env:"REDIS_PASSWORD, default="`
	DB               int           `env:"REDIS_CACHE_DB, default=5"`
	KeyPrefix        string        `env:"FEED_CACHE_KEY_PREFIX, default=feed-service:feed-cache:"`
	FeedTTL          time.Duration `env:"FEED_CACHE_TTL, default=45s"`
	TrayTTL          time.Duration `env:"FEED_TRAY_CACHE_TTL, default=30s"`
}

func (p PostgresConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		p.User,
		p.Password,
		p.Host,
		p.Port,
		p.DBName,
		p.SSLMode,
	)
}

func (p PostgresConfig) ParsedMaxConnLifetime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnLifetime)
	if err != nil {
		return time.Hour
	}
	return d
}

func (p PostgresConfig) ParsedMaxConnIdleTime() time.Duration {
	d, err := time.ParseDuration(p.MaxConnIdleTime)
	if err != nil {
		return 30 * time.Minute
	}
	return d
}

type LogConfig struct {
	Level string `env:"LOG_LEVEL, default=info"`
}

type SecurityConfig struct {
	InternalServiceToken       string `env:"INTERNAL_SERVICE_TOKEN, required"`
	RequireAuthenticatedWrites bool   `env:"REQUIRE_AUTHENTICATED_WRITES, default=true"`
	TrustedGatewayHeaderUserID string `env:"TRUSTED_GATEWAY_HEADER_USER_ID, default=X-User-Id"`
	TrustedGatewayHeaderRoles  string `env:"TRUSTED_GATEWAY_HEADER_ROLES, default=X-User-Roles"`
	TrustedGatewayHeaderSub    string `env:"TRUSTED_GATEWAY_HEADER_SUB, default=X-Auth-Subject"`
	RequestIDHeader            string `env:"REQUEST_ID_HEADER, default=X-Request-Id"`
}

type UserServiceConfig struct {
	Target string `env:"USER_SERVICE_GRPC_TARGET, default=dns:///user-service:9094"`
}

type FileManagerConfig struct {
	Target string `env:"FILE_MANAGER_GRPC_TARGET, default=dns:///file-manager-service:9093"`
}

type NotificationServiceConfig struct {
	HTTPURL        string        `env:"NOTIFICATION_SERVICE_HTTP_URL, default=http://notification-service:8097"`
	RequestTimeout time.Duration `env:"NOTIFICATION_SERVICE_REQUEST_TIMEOUT, default=3s"`
}

type ActivityServiceConfig struct {
	HTTPURL        string        `env:"ACTIVITY_SERVICE_HTTP_URL, default=http://activity-service:8086"`
	RequestTimeout time.Duration `env:"ACTIVITY_SERVICE_REQUEST_TIMEOUT, default=5s"`
}

type PublicConfig struct {
	PostShareBaseURL string `env:"FEED_STORY_SHARE_BASE_URL, default=https://inflap.app/posts"`
}

type FeedConfig struct {
	ProjectionWorkerEnabled            bool          `env:"FEED_PROJECTION_WORKER_ENABLED, default=true"`
	ProjectionWorkerPollInterval       time.Duration `env:"FEED_PROJECTION_WORKER_POLL_INTERVAL, default=5s"`
	ProjectionWorkerBatchSize          int           `env:"FEED_PROJECTION_WORKER_BATCH_SIZE, default=50"`
	ProjectionWorkerMaxAttempts        int           `env:"FEED_PROJECTION_WORKER_MAX_ATTEMPTS, default=20"`
	ProjectionWorkerBaseBackoff        time.Duration `env:"FEED_PROJECTION_WORKER_BASE_BACKOFF, default=1s"`
	ActivityIntentWorkerEnabled        bool          `env:"FEED_ACTIVITY_INTENT_WORKER_ENABLED, default=true"`
	ActivityIntentWorkerPollInterval   time.Duration `env:"FEED_ACTIVITY_INTENT_WORKER_POLL_INTERVAL, default=5s"`
	ActivityIntentWorkerBatchSize      int           `env:"FEED_ACTIVITY_INTENT_WORKER_BATCH_SIZE, default=50"`
	ActivityIntentWorkerMaxAttempts    int           `env:"FEED_ACTIVITY_INTENT_WORKER_MAX_ATTEMPTS, default=20"`
	ActivityIntentWorkerBaseBackoff    time.Duration `env:"FEED_ACTIVITY_INTENT_WORKER_BASE_BACKOFF, default=1s"`
	RankingExperimentKey               string        `env:"FEED_RANKING_EXPERIMENT_KEY, default=control"`
	RankingPostInterestWeight          float64       `env:"FEED_RANKING_POST_INTEREST_WEIGHT, default=1"`
	RankingCommunityInterestWeight     float64       `env:"FEED_RANKING_COMMUNITY_INTEREST_WEIGHT, default=0.35"`
	RankingCityAffinityWeight          float64       `env:"FEED_RANKING_CITY_AFFINITY_WEIGHT, default=0.25"`
	RankingCountryAffinityWeight       float64       `env:"FEED_RANKING_COUNTRY_AFFINITY_WEIGHT, default=0.10"`
	RankingCategoryAffinityWeight      float64       `env:"FEED_RANKING_CATEGORY_AFFINITY_WEIGHT, default=0.20"`
	RankingTagAffinityWeight           float64       `env:"FEED_RANKING_TAG_AFFINITY_WEIGHT, default=0.15"`
	RankingMaxBoostHours               int           `env:"FEED_RANKING_MAX_BOOST_HOURS, default=72"`
	RankingMaxPenaltyHours             int           `env:"FEED_RANKING_MAX_PENALTY_HOURS, default=336"`
	RankingInterestFreshnessDelay      time.Duration `env:"FEED_RANKING_INTEREST_FRESHNESS_DELAY, default=5m"`
	RankingNotInterestedPenalty        time.Duration `env:"FEED_RANKING_NOT_INTERESTED_PENALTY, default=336h"`
	RankingRecentCommunityEventWindow  time.Duration `env:"FEED_RANKING_RECENT_COMMUNITY_EVENT_WINDOW, default=24h"`
	RankingRecentCommunityPenaltyHours int           `env:"FEED_RANKING_RECENT_COMMUNITY_PENALTY_HOURS, default=8"`
	RankingMaxPostsPerCommunityPerPage int           `env:"FEED_RANKING_MAX_POSTS_PER_COMMUNITY_PER_PAGE, default=3"`
	RankingMaxPostsPerCategoryPerPage  int           `env:"FEED_RANKING_MAX_POSTS_PER_CATEGORY_PER_PAGE, default=8"`
	RankingMaxPostsPerAuthorPerPage    int           `env:"FEED_RANKING_MAX_POSTS_PER_AUTHOR_PER_PAGE, default=4"`
	RankingColdStartMaxBoostHours      int           `env:"FEED_RANKING_COLD_START_MAX_BOOST_HOURS, default=6"`
	RankingColdStartEngagementWeight   float64       `env:"FEED_RANKING_COLD_START_ENGAGEMENT_WEIGHT, default=1"`
	CuratedMaxConversionBlocksPerPage  int           `env:"FEED_CURATED_MAX_CONVERSION_BLOCKS_PER_PAGE, default=2"`
	CuratedMaxOfficialNewsCardsPerPage int           `env:"FEED_CURATED_MAX_OFFICIAL_NEWS_CARDS_PER_PAGE, default=1"`
	CuratedMaxProfileCardsPerPage      int           `env:"FEED_CURATED_MAX_PROFILE_CARDS_PER_PAGE, default=1"`
}

func Load(ctx context.Context) (*Config, error) {
	var cfg Config
	if err := envconfig.Process(ctx, &cfg); err != nil {
		return nil, fmt.Errorf("process env config: %w", err)
	}
	return &cfg, nil
}
