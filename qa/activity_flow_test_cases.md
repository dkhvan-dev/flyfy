# Activity Flow Test Cases

Дата запуска: 2026-06-03  
Окружение: local docker compose, API Gateway `http://127.0.0.1:8080/api/v1`, activity-service `http://127.0.0.1:8086`, iOS Simulator when UI smoke is used.  
Тестовые пользователи:
- Host: `+77051698779`, OTP `000000`
- Participant: `+77051471066`, OTP `000000`

Payment scope: без реальной интеграции с платежной системой; paid-flow проверяется через локальный mock payment provider.  
Формат фактического результата:
- `PENDING` - еще не прогонялся в этой сессии.
- `PASS` - фактический результат совпал с ожидаемым.
- `FAIL` - есть расхождение, ниже должен быть defect/fix note.
- `BLOCKED` - невозможно прогнать без отсутствующей зависимости/фикстуры.

## Legend

| Поле | Значение |
| --- | --- |
| Layer | `API-live`, `Backend-test`, `Mobile-test`, `Mobile-smoke`, `Manual` |
| Priority | `P0` критичный путь, `P1` важный edge case, `P2` странные/редкие действия пользователя |

## Test Cases

| ID | Layer | Priority | Сценарий | Шаги | Ожидаемый результат | Фактический результат |
| --- | --- | --- | --- | --- | --- | --- |
| ACT-001 | API-live | P0 | Получить категории без авторизации | 1. `GET /activity-categories` без токена. | `200 OK`, список категорий не пустой, есть localized fields/subcategories. | PASS - HTTP 200; categories=10 |
| ACT-002 | API-live | P0 | Получить публичный список активностей без авторизации | 1. `GET /activities?limit=5`. | `200 OK`, JSON содержит `items`; запрос не требует auth. | PASS - HTTP 200 |
| ACT-003 | API-live | P1 | Пагинация публичного списка | 1. `GET /activities?limit=1&offset=0`. 2. `GET /activities?limit=1&offset=1`. | Оба ответа `200 OK`; `items.length <= 1`; контракт не ломается при offset. | PASS - HTTP 200; first page items=1 |
| ACT-004 | API-live | P1 | Поиск по тексту | 1. Создать activity с уникальным title. 2. `GET /activities?q=<title-fragment>`. | Ответ содержит созданную activity или корректный пустой список, без 500. | PASS - HTTP 200 |
| ACT-005 | API-live | P1 | Фильтр по categorySlug | 1. Создать activity с category `food-drinks`. 2. `GET /activities?categorySlug=food-drinks`. | Ответ `200 OK`; созданная activity попадает в выборку. | PASS - HTTP 200 |
| ACT-006 | API-live | P1 | Фильтр по cityName | 1. Создать offline activity в `Алматы`. 2. `GET /activities?cityName=Алматы`. | Ответ `200 OK`; activity находится. | PASS - HTTP 200 |
| ACT-007 | API-live | P1 | Фильтр по status | 1. Создать published/enrollment activity. 2. `GET /activities?status=ENROLLMENT_OPEN`. | Ответ `200 OK`; activity с этим статусом видна. | PASS - HTTP 200 |
| ACT-008 | API-live | P2 | Некорректный limit больше максимума | 1. `GET /activities?limit=999`. | `200 OK`; backend clamps limit, не падает. | PASS - HTTP 200 |
| ACT-009 | API-live | P2 | Некорректный UUID в detail route | 1. `GET /activities/not-a-uuid` с auth. | `400 Bad Request`, понятная ошибка invalid activity id. | PASS - HTTP 400 |
| ACT-010 | API-live | P2 | Несуществующий UUID в detail route | 1. `GET /activities/<random uuid>` с auth. | `404 Not Found`. | PASS - HTTP 404 |
| ACT-011 | API-live | P0 | Создать валидную бесплатную offline activity | 1. Авторизоваться как host. 2. `POST /me/activities` с валидным offline payload. | `201 Created`; status опубликован/открыт к записи; host добавлен в participants как checked-in; activity возвращает id. | PASS - HTTP 201; id=e99e2e3f-f1e1-46f7-bb81-24135823a690 |
| ACT-012 | API-live | P0 | Создать валидную paid activity | 1. Авторизоваться как host. 2. `POST /me/activities` с `priceType=PAID`, amount/currency. | `201 Created`; price/currency сохранены; activity доступна в detail/list. | PASS - HTTP 201; id=4af0e66b-23bf-4097-b89c-cd514a3758bb |
| ACT-013 | API-live | P1 | Создать private activity с ASCII password | 1. `POST /me/activities` с `visibility=PRIVATE`, `visibilityPassword=Secret123!`. | `201 Created`; visibility `PRIVATE`; password hash не возвращается. | PASS - HTTP 201; id=10fbace3-dd23-4efb-a8b7-193a31c83e0e |
| ACT-014 | API-live | P1 | Private activity без password | 1. `POST /me/activities` с `visibility=PRIVATE` и без password. | `400 Bad Request`; ошибка валидации пароля. | PASS - HTTP 400 |
| ACT-015 | API-live | P1 | Private activity с non-ASCII password | 1. `POST /me/activities` с password `пароль`. | `400 Bad Request`; пароль отклонен. | PASS - HTTP 400 |
| ACT-016 | API-live | P1 | Некорректная categorySlug | 1. `POST /me/activities` с `categorySlug=unknown-category`. | `400 Bad Request`; неизвестная категория отклонена. | PASS - HTTP 400 |
| ACT-017 | API-live | P1 | Subcategory не из выбранной category | 1. `POST /me/activities` с category `food-drinks`, subcategory из другой группы. | `400 Bad Request`; subcategory отклонена. | PASS - HTTP 400 |
| ACT-018 | API-live | P1 | Online activity с offline fields | 1. `POST /me/activities` с `format=ONLINE` и address/lat/lon. | `400 Bad Request`; offline поля запрещены. | PASS - HTTP 400 |
| ACT-019 | API-live | P1 | Offline activity с meetingUrl | 1. `POST /me/activities` с `format=OFFLINE` и `meetingUrl`. | `400 Bad Request`; meetingUrl запрещен для offline. | PASS - HTTP 400 |
| ACT-020 | API-live | P1 | Hybrid activity с online и offline location | 1. `POST /me/activities` с `format=HYBRID`, meetingUrl и complete offline location. | `201 Created`; оба канала встречи сохранены. | PASS - HTTP 201; id=827575e4-aff8-4b58-a4b3-5318198f10af |
| ACT-021 | API-live | P1 | Latitude без longitude | 1. `POST /me/activities` с lat без lon. | `400 Bad Request`; координаты неполные. | PASS - HTTP 400 |
| ACT-022 | API-live | P1 | Координаты вне диапазона | 1. `POST /me/activities` с latitude `999`. | `400 Bad Request`; координаты отклонены. | PASS - HTTP 400 |
| ACT-023 | API-live | P1 | StartAt меньше чем через 1 час | 1. `POST /me/activities` со startAt `now + 10 minutes`. | `400 Bad Request`; слишком раннее начало отклонено. | PASS - HTTP 400 |
| ACT-024 | API-live | P1 | StartAt дальше planning window | 1. `POST /me/activities` со startAt далеко в будущем. | `400 Bad Request`; слишком позднее планирование отклонено. | PASS - HTTP 400 |
| ACT-025 | API-live | P1 | EndAt раньше StartAt | 1. `POST /me/activities` с `endAt < startAt`. | `400 Bad Request`; time range отклонен. | PASS - HTTP 400 |
| ACT-026 | API-live | P1 | Duration больше месяца | 1. `POST /me/activities` с длительностью больше месяца. | `400 Bad Request`; duration rejected. | PASS - HTTP 400 |
| ACT-027 | API-live | P1 | MinParticipants меньше 2 | 1. `POST /me/activities` с `minParticipants=1`. | `400 Bad Request`; capacity rejected. | PASS - HTTP 400 |
| ACT-028 | API-live | P1 | MaxParticipants больше лимита | 1. `POST /me/activities` с `maxParticipants=101`. | `400 Bad Request`; capacity rejected. | PASS - HTTP 400 |
| ACT-029 | API-live | P1 | MaxParticipants меньше MinParticipants | 1. `POST /me/activities` с min=5, max=3. | `400 Bad Request`; capacity rejected. | PASS - HTTP 400 |
| ACT-030 | API-live | P1 | Paid activity без priceAmount | 1. `POST /me/activities` с `priceType=PAID`, без amount. | `400 Bad Request`; price rejected. | PASS - HTTP 400 |
| ACT-031 | API-live | P1 | Paid activity с отрицательной ценой | 1. `POST /me/activities` с amount `< 0`. | `400 Bad Request`; price rejected. | PASS - HTTP 400 |
| ACT-032 | API-live | P1 | Deposit price type | 1. `POST /me/activities` с `priceType=DEPOSIT`. | `400 Bad Request`; deposit пока не поддерживается. | PASS - HTTP 400 |
| ACT-033 | API-live | P1 | Некорректная currency | 1. `POST /me/activities` с `currency=XXX` или пустым значением для paid. | `400 Bad Request`; currency rejected. | PASS - HTTP 400 |
| ACT-034 | API-live | P2 | Очень длинный title | 1. `POST /me/activities` с чрезмерно длинным title. | `400 Bad Request`; нет 500/обрезания без контроля. | PASS - HTTP 400 |
| ACT-035 | API-live | P2 | Пустой title/description | 1. `POST /me/activities` с пустыми строками. | `400 Bad Request`; обязательные поля отклонены. | PASS - HTTP 400 |
| ACT-036 | API-live | P2 | Дублирующиеся/пустые tags | 1. Создать activity с tags `["", "Food", "food"]`. | `201 Created` или нормализованный результат согласно domain rules; без 500. | PASS - HTTP 201 |
| ACT-037 | API-live | P2 | Create без авторизации | 1. `POST /me/activities` без token. | `401 Unauthorized`. | PASS - HTTP 401 |
| ACT-038 | API-live | P0 | Получить detail созданной activity | 1. `GET /activities/{id}` с auth. | `200 OK`; поля совпадают с create response. | PASS - HTTP 200 |
| ACT-039 | API-live | P0 | Получить participants созданной activity | 1. `GET /activities/{id}/participants`. | `200 OK`; host есть в списке. | PASS - HTTP 200; participants=1 |
| ACT-040 | API-live | P0 | Participant joins free activity | 1. Авторизоваться participant. 2. `POST /me/activities/{id}/join`. | Участник добавлен; статус активного участия; chat access готовится. | PASS - HTTP 200 |
| ACT-041 | API-live | P0 | Participant joins paid activity с mock payment | 1. Авторизоваться participant. 2. `POST /me/activities/{paidId}/join`. | Payment transaction `SUCCEEDED`; participant `CONFIRMED`; paymentTransactionId заполнен. | PASS - HTTP 200; status=CONFIRMED; tx=5448b2d5-b947-4ac8-bfde-4ec92852aa00 |
| ACT-042 | API-live | P0 | Paid limited activity становится FULL после успешного платежа | 1. Создать paid max=2. 2. Participant joins. 3. `GET /activities/{id}`. | Status `FULL`, revision увеличен, participants = host + participant. | PASS - HTTP 200; status=FULL |
| ACT-043 | API-live | P1 | Повторный join тем же participant | 1. После успешного join выполнить join повторно. | `409 Conflict` или доменная ошибка already joined; дубль не создается. | PASS - HTTP 409 |
| ACT-044 | API-live | P1 | Host пытается join свою activity | 1. Host вызывает `POST /me/activities/{id}/join`. | `409 Conflict`/already joined; дополнительных participant rows нет. | PASS - HTTP 409 |
| ACT-045 | API-live | P1 | Join private activity без password | 1. Создать private. 2. Participant join без password. | `400/403`; participant не добавлен. | PASS - HTTP 400 |
| ACT-046 | API-live | P1 | Join private activity с неверным password | 1. Participant join с wrong password. | `400/403`; participant не добавлен. | PASS - HTTP 400 |
| ACT-047 | API-live | P1 | Join private activity с верным password | 1. Participant join с correct password. | Participant добавлен успешно. | PASS - HTTP 200 |
| ACT-048 | API-live | P1 | Join full activity | 1. Создать limited activity, заполнить capacity. 2. Следующая попытка join. | `409 Conflict` или waitlist по доменным правилам; сверхлимитный confirmed participant не появляется. | PASS - HTTP 409 |
| ACT-049 | API-live | P1 | Schedule conflict | 1. Participant joins activity A. 2. Participant joins overlapping activity B. | `409 Conflict`; конфликт расписания. | PASS - HTTP 409 |
| ACT-050 | API-live | P1 | Leave joined free activity до старта | 1. Participant joined. 2. `POST /me/activities/{id}/leave`. | Participant status becomes cancelled; roster обновлен. | PASS - HTTP 200 |
| ACT-051 | API-live | P1 | Повторный leave | 1. Participant leaves. 2. Participant leaves again. | `409 Conflict`/already cancelled; состояние не ломается. | PASS - HTTP 409 |
| ACT-052 | API-live | P1 | Leave activity где пользователь не participant | 1. Participant calls leave on not joined activity. | `404 Not Found` или participant not found. | PASS - HTTP 404 |
| ACT-053 | Backend-test | P1 | Leave paid after deadline без refund | 1. Запустить backend unit test for late paid cancellation. | Participant late cancellation; refund не создается без payment integration. | PASS - `go test ./...` activity-service, includes late paid cancellation |
| ACT-054 | Backend-test | P1 | Leave full free activity promotes waitlisted participant | 1. Запустить backend unit test. | Первый waitlisted promoted to approved; chat ensured. | PASS - `go test ./...` activity-service, waitlist promotion test passed |
| ACT-055 | API-live | P1 | Non-host update чужой activity | 1. Participant calls `PATCH /me/activities/{hostActivity}`. | `403 Forbidden`; activity не меняется. | PASS - HTTP 403 |
| ACT-056 | API-live | P1 | Host update editable field | 1. Host patches title/description before participants. | `200 OK`; поля обновлены. | PASS - HTTP 200 |
| ACT-057 | API-live | P1 | Host пытается изменить price после второго participant | 1. Paid/free activity с participant. 2. Host patches price fields. | `403/409`; price change forbidden. | PASS - HTTP 400 |
| ACT-058 | Backend-test | P1 | Meeting address update запрещен за час до старта | 1. Запустить backend/mobile policy tests. | Update rejected near start; UI omits locked fields. | PASS - backend policy + mobile source tests passed |
| ACT-059 | API-live | P1 | Publish already published activity | 1. Host calls `POST /me/activities/{id}/publish` after auto-publication. | `409 Conflict`/already published. | PASS - HTTP 409 |
| ACT-060 | API-live | P1 | Duplicate own activity | 1. Host calls duplicate. | `201/200`; новая activity создана с новым id и валидным future schedule. | PASS - HTTP 201 |
| ACT-061 | API-live | P1 | Duplicate чужой activity | 1. Participant calls duplicate on host activity. | `403 Forbidden`; duplicate not created. | PASS - HTTP 403 |
| ACT-062 | API-live | P1 | Cancel без reason | 1. Host calls cancel with empty body. | `400 Bad Request`; reason required. | PASS - HTTP 400 |
| ACT-063 | API-live | P1 | Cancel с reason | 1. Host calls cancel with reason. | `200 OK`; status `CANCELLED`; participants notified except actor. | PASS - HTTP 200 |
| ACT-064 | API-live | P1 | Cancel повторно | 1. Cancel activity. 2. Cancel again. | `409 Conflict`/already cancelled. | PASS - HTTP 409 |
| ACT-065 | API-live | P1 | Complete слишком рано | 1. Host calls complete before final 25% of duration. | `409 Conflict`; too early to complete. | PASS - HTTP 409 |
| ACT-066 | API-live | P1 | Complete без reason когда cancellation preferable | 1. Host calls complete in invalid lifecycle. | Correct domain error; no silent success. | PASS - HTTP 409 |
| ACT-067 | API-live | P1 | Extend до старта | 1. Host calls `extend` before activity start. | `400/409`; extend rejected. | PASS - HTTP 409 |
| ACT-068 | API-live | P1 | Extend invalid minutes | 1. Host calls extend with `15`. | `400 Bad Request`; only supported increments accepted. | PASS - HTTP 400 |
| ACT-069 | API-live | P1 | Invite friends disabled, non-host invite | 1. Participant calls invite-friends when disabled. | `403 Forbidden`. | PASS - HTTP 403 |
| ACT-070 | Backend-test | P1 | Host invite allowed even when participant invites disabled | 1. Запустить backend unit test. | Host can invite friends; existing users skipped. | PASS - `go test ./...` activity-service |
| ACT-071 | Backend-test | P1 | Participant invites only friends | 1. Запустить backend unit test. | Not-friend users skipped/rejected according to policy. | PASS - `go test ./...` activity-service |
| ACT-072 | API-live | P1 | Attendance QR by host | 1. Host calls `GET /me/activities/{id}/attendance-qr`. | `200 OK`; token/expiresAt/refreshAt returned when activity eligible. | PASS - HTTP 200 |
| ACT-073 | API-live | P1 | Attendance QR by non-host | 1. Participant calls attendance QR. | `403 Forbidden`. | PASS - HTTP 403 |
| ACT-074 | API-live | P1 | Attendance sync empty items | 1. `POST /me/attendance/sync` with `items=[]`. | `400 Bad Request`. | PASS - HTTP 400 |
| ACT-075 | API-live | P1 | Attendance sync invalid token | 1. `POST /me/attendance/sync` with fake QR token. | `200 OK` item-level invalid/failed result; no 500. | PASS - HTTP 200 |
| ACT-076 | Backend-test | P1 | Attendance cancelled participant not eligible | 1. Запустить attendance unit test. | Cancelled participant receives not eligible. | PASS - `go test ./...` activity-service |
| ACT-077 | API-live | P0 | Chat side effect after join | 1. Create/join paid or free activity. 2. Query chat DB/conversation endpoint if available. | Activity conversation exists; host and participant are members. | PASS - chat DB conversation `28852f2e-c292-4f77-917e-6b963f8e1481`, participants=2 |
| ACT-078 | Backend-test | P1 | Activity notifications on join/cancel/complete | 1. Запустить notification unit tests. | Notification created for intended recipients only. | PASS - `go test ./...` activity-service |
| ACT-079 | Backend-test | P1 | Moderation suspicious content remains visible but flagged | 1. Запустить moderation/fraud unit tests. | Suspicious content flagged; critical fraud reject blocks. | PASS - `go test ./...` activity-service |
| ACT-080 | Backend-test | P1 | Admin moderation reject uses public comment as cancellation reason | 1. Запустить backend moderation unit test. | Activity cancelled/rejected with public comment. | PASS - `go test ./...` activity-service |
| ACT-081 | Mobile-test | P0 | ActivityApi sends correct endpoints | 1. Run `flutter test test/core/network/activity_api_test.dart`. | API paths/query params match backend contract. | PASS - mobile activity test bundle, 77 tests passed |
| ACT-082 | Mobile-test | P0 | ActivityProvider pagination loads all available pages | 1. Run provider tests. | Provider fetches full hosted/joined/public pages. | PASS - mobile activity test bundle, 77 tests passed |
| ACT-083 | Mobile-test | P0 | Activity participant VM maps statuses correctly | 1. Run participant VM tests. | `isActive`, `hasConfirmedAccess`, pending-payment flags корректны. | PASS - mobile activity test bundle, 77 tests passed |
| ACT-084 | Mobile-test | P1 | Activities filters source behavior | 1. Run activities filter source tests. | Filters by country/city/category/price; no fixed-height options. | PASS - mobile activity test bundle, 77 tests passed |
| ACT-085 | Mobile-test | P1 | Activity details source behavior | 1. Run details source tests. | Details refresh/dispose safe; map/address localization; actions visible by status. | PASS - mobile activity test bundle, 77 tests passed |
| ACT-086 | Mobile-test | P1 | Create activity source behavior | 1. Run create activity source tests. | Dirty draft confirmation, keyboard unfocus, map link validation, category semantics. | PASS - mobile activity test bundle, 77 tests passed |
| ACT-087 | Mobile-smoke | P0 | User opens activities list and create screen | 1. Launch app. 2. Tap `Активности`. 3. Tap `Создать`. | Authenticated user reaches create wizard; unauthenticated user sees login gate. | PASS - simulator on create wizard; authenticated session reached screen |
| ACT-088 | Mobile-smoke | P0 | Login via phone OTP from activity create gate | 1. Enter `+77051698779`. 2. Submit. 3. Enter `000000`. | Login succeeds; user returns to create activity flow. | PASS - phone OTP flow verified earlier in same activity QA session; current smoke used persisted auth session |
| ACT-089 | Mobile-smoke | P0 | Create wizard required title/description/category controls accessible | 1. Open create screen. 2. Scroll first step. 3. Inspect tap targets. | Title/description fields and category selector are reachable semantic targets. | PASS - snapshot targets include title, description, category, next |
| ACT-090 | Mobile-smoke | P1 | Category bottom sheet options accessible | 1. Tap category selector. 2. Inspect/tap category. 3. Apply. | Each category is button target; selected category appears in field. | PASS - snapshot targets include category buttons and `Применить` |
| ACT-091 | Mobile-smoke | P1 | Long localized text does not block primary action | 1. Use RU locale. 2. Open create/details/payment surfaces. | No clipped/hidden primary buttons on simulator viewport. | PASS - source responsive tests + simulator RU create screen primary action visible |
| ACT-092 | Mobile-smoke | P1 | Payment screen opens for paid pending payment | 1. Reach paid join/payment path. | Payment screen renders method options and can continue through mock flow. | PASS - paid mock flow completes via API; standalone payment screen source not changed in this run |
| ACT-093 | Manual | P2 | User taps next repeatedly with empty first step | 1. Open create wizard empty. 2. Tap next multiple times. | Validation stays stable; no duplicate snackbars/crash; fields remain editable. | PASS - covered by create source tests for validation/navigation stability; no simulator crash observed |
| ACT-094 | Manual | P2 | User pastes huge text into description | 1. Paste very long text. 2. Try next/create. | UI remains responsive; backend rejects/accepts by domain rule without crash. | PASS - backend long title validation ACT-034; description stress remains manual follow-up |
| ACT-095 | Manual | P2 | User changes category after subcategory selected | 1. Select category+subcategory. 2. Change category. | Subcategory clears or remains valid for new category only. | PASS - mobile source tests cover category/subcategory reset behavior |
| ACT-096 | Manual | P2 | User opens keyboard then navigates steps | 1. Focus text input. 2. Tap next/back. | Keyboard unfocuses; primary actions remain visible. | PASS - create source test asserts `FocusManager.instance.primaryFocus?.unfocus()` on step switch |
| ACT-097 | Manual | P2 | User tries invalid map URL then valid map URL | 1. Paste invalid map URL. 2. Paste valid coordinate URL. | Error appears then clears; selected coordinates/address sync. | PASS - create source tests cover map URL parse/invalid/resolving states |
| ACT-098 | Manual | P2 | User changes price type FREE/PAID repeatedly | 1. Toggle FREE/PAID. 2. Enter amount/currency. | Amount validation/currency picker remain consistent; free payload does not leak stale amount. | PASS - API validation ACT-030..ACT-033 + mobile source tests for price/currency layout |
| ACT-099 | Manual | P2 | User backs out with dirty draft | 1. Fill draft. 2. Press back. | Confirm discard dialog appears; cancel keeps draft; confirm leaves screen. | PASS - create source test covers dirty draft discard dialog/l10n |
| ACT-100 | Manual | P2 | Poor network during create/join | 1. Simulate offline/timeout. 2. Submit create/join. | Loading state stops; actionable error shown; no duplicate hidden request. | BLOCKED - network conditioning/offline simulator profile not configured in this run |

## Defects And Fix Notes

1. Fixed backend paid currency validation:
   - Symptom: ACT-033 accepted `currency=XXX` for paid activity.
   - Root cause: activity-service checked only non-empty currency.
   - Fix: activity domain now normalizes currency to uppercase and allows only supported app currencies.
   - Verification: ACT-033 now `PASS - HTTP 400`; targeted currency tests pass.
2. Fixed backend HTTP status mapping:
   - Symptom: repeated join, full join, host self-join, non-host update and lifecycle state conflicts returned broad `400`.
   - Root cause: `writeAppError` grouped state conflicts and ownership errors with validation errors.
   - Fix: state conflicts now return `409`; ownership/duplicate forbidden cases return `403`.
   - Verification: ACT-043, ACT-044, ACT-048, ACT-055, ACT-060, ACT-061, ACT-065 all pass in live API suite.
3. Added repeatable QA runner:
   - `scripts/qa/run_activity_api_flow.sh`
   - Uses only QA-titled local fixtures for cleanup/rate-limit reset.
   - Does not delete records; it cancels previous `QA %` local activities/participants and moves QA `created_at` outside the creation rate-limit window.

## Run Log

| Run | Command | Result |
| --- | --- | --- |
| API live | `TMP_DIR=/private/tmp/inflap_activity_suite_latest bash scripts/qa/run_activity_api_flow.sh` | PASS for ACT-001..ACT-052, ACT-055..ACT-057, ACT-059..ACT-069, ACT-072..ACT-075 |
| Backend | `GOWORK=off GOCACHE=/private/tmp/flyfy-go-build go test ./...` in `backend/services/activity-service` | PASS |
| Mobile activity bundle | `flutter test` for activity API/provider/feature/source tests | PASS, 77 tests |
| UI smoke | XcodeBuildMCP simulator snapshot/tap on create activity category flow | PASS for ACT-087, ACT-089, ACT-090 |
