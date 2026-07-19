# api-gateway

`api-gateway` — внешний HTTP entrypoint для клиентских запросов.

## Что делает gateway

- принимает внешние HTTP запросы
- валидирует bearer access token через `token-service`
- разделяет public / protected routes
- добавляет trusted headers в downstream сервисы:
  - `X-Auth-Subject`
  - `X-User-Id`
  - `X-User-Roles`
  - `X-Request-Id`
- для Saved routes проверяет token `session_id` и добавляет trusted `X-Session-Generation`
- перед каждым Saved downstream-запросом проверяет общий fail-closed platform personal-data policy
- проксирует запросы в backend services

## Downstream routes

### auth-service
- `/api/v1/auth/*`

### user-service
- `/api/v1/users/*`
- `/api/v1/public/users*`

### saved-service
- `/api/v1/users/me/saved-items*`
- `/api/v1/users/me/saved-operations/{operationId}`
- `/api/v1/users/me/saved-collections*`

### guide-service
- `/api/v1/guides/*`
- `/api/v1/admin/guides/*`

### file-manager-service
- `/api/v1/files/*`

## Public routes

- `/health`
- `/ready`
- `/api/v1/auth/*`

## Protected routes

Все остальные проксируемые API требуют bearer access token.

## Trusted headers

Gateway всегда **перезаписывает** trusted headers перед проксированием.
Внешним клиентам нельзя доверять значения:
- `X-Auth-Subject`
- `X-User-Id`
- `X-User-Roles`
- `X-Session-Generation`

`X-Request-Id` принимается только как canonical non-zero UUID; любое пустое,
malformed или потенциально содержащее PII значение заменяется новым UUID.
`X-Client-Platform` и `X-App-Build` проксируются как bounded product-rollout
metadata и никогда не используются для аутентификации или авторизации.

## ENV

Скопируй `.env.example` и задай реальные значения.

- `SAVED_SERVICE_URL` — абсолютный HTTP(S) origin saved-service без path/query/credentials
- `SAVED_SERVICE_REQUEST_TIMEOUT` — positive duration, hard max `30s`
- `PLATFORM_POLICY_BASE_URL` — origin `switches-service`; в production обязателен HTTPS
- `PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN` — отдельный внутренний токен policy endpoint из secret/env
- `PLATFORM_POLICY_HTTP_TIMEOUT` — timeout одного policy fetch, максимум `5s`
- `PLATFORM_POLICY_REFRESH_TIMEOUT` — общий timeout coalesced on-demand refresh, максимум `5s` и меньше Saved request timeout
- `PLATFORM_POLICY_MAX_RESPONSE_BYTES` — максимум ответа policy endpoint, не более `64 KiB`
- `PLATFORM_POLICY_ALLOW_INSECURE_HTTP` — явный opt-in для локального dev/test; в production запрещён

Platform policy не запускает background refresh и не делает stale-allow. Недоступный,
просроченный, некорректный или откатившийся policy блокирует только Saved routes.
Общий `/ready` продолжает отражать готовность Gateway для остальных продуктов, а
Saved capability endpoint проходит тот же обязательный guard, что и остальные Saved routes.

## Локальный запуск

```bash
go mod tidy
go run ./cmd
```
