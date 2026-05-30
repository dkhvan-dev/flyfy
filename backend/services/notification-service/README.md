# Notification Service

Production push notification service for Inflap.

## Quick Android FCM Smoke Test

1. Start backend dependencies and `notification-service`.
2. Run the Android app against the API gateway:

   ```bash
   cd mobile
   flutter run -d <android-device-id> --dart-define=INFLAP_API_BASE_URL=http://<host-or-tunnel>/api/v1
   ```

3. Sign in on the device and allow notifications. The app registers the FCM token automatically.
4. Get the authenticated user id from your user/session data.
5. Send a test notification from inside the Docker network:

   ```bash
   docker compose -f deploy/docker-compose.yml exec notification-service wget -qO- \
     --header='Content-Type: application/json' \
     --header='X-Internal-Service-Token: super-secret-internal-token' \
     --header='X-Service-Name: manual-smoke-test' \
     --post-data='{"idempotencyKey":"manual-smoke-test-001","recipientUserIds":["f18f4045-a230-4d2a-8a17-e3183da52e68"],"category":"activity","priority":"high","title":"Inflap test","body":"Push pipeline works","data":{"activityId":"test-activity-id"},"deepLink":"/notifications","ttlSeconds":3600}' \
     http://localhost:8097/internal/v1/notifications/send
   ```

6. Check `notification-service` logs for FCM provider result and verify the Android device receives the notification. If the app is foregrounded, Inflap shows it through a local notification channel.

Use a new `idempotencyKey` for each manual send, otherwise the backend intentionally deduplicates the request.

## Secrets

Never store Firebase service account JSON, APNs keys, HMS client secrets, internal tokens, or token encryption keys in git.

The service supports mounted secret files through `_FILE` environment variables:

| Value | Direct env | File env |
| --- | --- | --- |
| DB password | `DB_PASSWORD` | `DB_PASSWORD_FILE` |
| Internal service token | `INTERNAL_SERVICE_TOKEN` | `INTERNAL_SERVICE_TOKEN_FILE` |
| Device token encryption key | `NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64` | `NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64_FILE` |
| Device token hash key | `NOTIFICATION_TOKEN_HASH_KEY_BASE64` | `NOTIFICATION_TOKEN_HASH_KEY_BASE64_FILE` |
| HMS client secret | `HMS_CLIENT_SECRET` | `HMS_CLIENT_SECRET_FILE` |
| Firebase service account | `FCM_SERVICE_ACCOUNT_JSON_PATH` | mount JSON file and point this env to it |

For Kubernetes, create secrets and mount them as files:

```bash
kubectl create secret generic notification-service-secrets \
  --from-file=firebase-service-account.json=./firebase-service-account.json \
  --from-literal=internal-service-token='<token>' \
  --from-literal=token-encryption-key-base64='<base64-32-byte-key>' \
  --from-literal=token-hash-key-base64='<base64-32-byte-or-longer-key>'
```

Then configure the deployment with:

```yaml
env:
  - name: FCM_SERVICE_ACCOUNT_JSON_PATH
    value: /run/secrets/firebase-service-account.json
  - name: INTERNAL_SERVICE_TOKEN_FILE
    value: /run/secrets/internal-service-token
  - name: NOTIFICATION_TOKEN_ENCRYPTION_KEY_BASE64_FILE
    value: /run/secrets/token-encryption-key-base64
  - name: NOTIFICATION_TOKEN_HASH_KEY_BASE64_FILE
    value: /run/secrets/token-hash-key-base64
volumeMounts:
  - name: notification-secrets
    mountPath: /run/secrets
    readOnly: true
```

## Load Tuning

Core worker controls:

- `NATS_BATCH_SIZE`: pull batch size, default `500`.
- `NATS_FANOUT_CONCURRENCY`: concurrent request fanout workers, default `8`.
- `NATS_DELIVERY_CONCURRENCY`: concurrent provider delivery workers, default `64`.
- `NATS_MAX_ACK_PENDING`: JetStream backpressure limit, default `8192`.
- `NATS_MAX_DELIVER`: message retry cap before DLQ, default `10`.
- `NATS_ACK_WAIT`, `NATS_NAK_DELAY`, `NATS_FETCH_MAX_WAIT`: redelivery and latency controls.

Failed or invalid messages are terminated and published to:

- `notifications.dlq.fanout.invalid`
- `notifications.dlq.fanout.failed`
- `notifications.dlq.delivery.invalid`
- `notifications.dlq.delivery.failed`
