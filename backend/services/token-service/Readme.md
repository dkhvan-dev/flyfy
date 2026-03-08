# Token Service

Микросервис управления JWT-токенами для Tourism SuperApp.

## Обзор

Token Service — фундаментальный сервис Auth-домена, отвечающий за:

- Генерацию и валидацию **user tokens** (access + refresh, RS256)
- Генерацию и валидацию **service tokens** (S2S, Client Credentials)
- RBAC для межсервисного взаимодействия
- Ротацию RSA-ключей подписи
- JWKS-эндпоинт для публичных ключей
- Revocation list (отзыв токенов при logout)

## Архитектура

Hexagonal Architecture (Ports & Adapters):

```
internal/
├── domain/           # Ядро: модели + порты (интерфейсы)
│   ├── model/        #   Сущности: UserClaims, ServiceAccount, TokenPair, ошибки
│   └── port/         #   Порты: TokenGenerator, TokenValidator, KeyStore, etc.
├── app/              # Use Cases: бизнес-логика (зависит только от domain/)
│   ├── token_usecase.go     # Генерация, валидация, S2S auth, revocation
│   └── key_rotation.go      # Фоновая ротация ключей
└── adapter/          # Реализации портов (зависит от domain/ и app/)
    ├── grpc/         #   gRPC server, handler, interceptors (S2S RBAC)
    ├── http/         #   REST: JWKS + health endpoints
    ├── crypto/       #   Bcrypt (PasswordVerifier)
    └── repository/   #   PostgreSQL, Redis, InMemory key store
```

## Стек

| Компонент | Технология |
|-----------|-----------|
| Язык | Go 1.26 |
| gRPC | google.golang.org/grpc |
| JWT | github.com/go-jose/go-jose/v4 (RS256) |
| HTTP Router | github.com/go-chi/chi/v5 |
| PostgreSQL | github.com/jackc/pgx/v5 |
| Redis | github.com/redis/go-redis/v9 |
| Logging | github.com/rs/zerolog |
| Config | github.com/sethvargo/go-envconfig |

## Запуск

### Зависимости

```bash
# Запуск PostgreSQL + Redis
make docker-compose-up

# Применение миграций
export PG_DSN="postgres://token_service:token_secret_dev@localhost:5432/token_service?sslmode=disable"
make migrate-up
```

### Запуск сервиса

```bash
cp .env.example .env
make run
```

### Docker

```bash
make docker-build
make docker-run
```

## API

### gRPC (порт 50051)

| Метод | Описание | Требуемая роль |
|-------|----------|----------------|
| `AuthenticateService` | Аутентификация микросервиса → service token | Публичный |
| `GenerateUserTokens` | Генерация access + refresh пары | `token:generate` |
| `ValidateAccessToken` | Валидация access токена | `token:validate` |
| `ValidateRefreshToken` | Валидация refresh токена | `token:validate` |
| `RefreshTokens` | Обновление пары токенов | `token:generate`, `token:validate` |
| `RevokeToken` | Отзыв токена по JTI | `token:revoke` |
| `ValidateServiceToken` | Валидация service токена | `token:validate` |

### REST (порт 8081)

| Endpoint | Описание |
|----------|----------|
| `GET /.well-known/jwks.json` | Публичные ключи (JWKS) |
| `GET /health` | Health check |
| `GET /ready` | Readiness check |

## S2S Authentication

Каждый микросервис имеет `service_id` + `service_secret` и набор ролей:

1. При старте сервис вызывает `AuthenticateService` → получает service JWT
2. При вызове другого сервиса передаёт JWT в gRPC metadata: `authorization: Bearer <token>`
3. gRPC interceptor проверяет токен и наличие нужных ролей
4. Если роли нет → `PERMISSION_DENIED`, событие в аудит-лог

## Тестирование

```bash
make test           # Unit-тесты
make test-cover     # С покрытием
make lint           # Линтеры
```

## Генерация Proto

```bash
make tools   # Установка protoc-gen-go
make proto   # Генерация Go-кода из .proto
```