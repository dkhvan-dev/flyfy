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
- проксирует запросы в backend services

## Downstream routes

### auth-service
- `/api/v1/auth/*`

### user-service
- `/api/v1/users/*`
- `/api/v1/public/users*`

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

## ENV

Скопируй `.env.example` и задай реальные значения.

## Локальный запуск

```bash
go mod tidy
go run ./cmd