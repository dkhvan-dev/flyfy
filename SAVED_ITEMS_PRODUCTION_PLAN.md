# Сохраненное Inflap: итоговый production-план

**Статус:** утвержденный production baseline; документ готов к декомпозиции на delivery-задачи. Подписание immutable source ID, auth и общей platform emergency-policy contracts остается входным gate реализации, а не открытым продуктовым решением

**Дата:** 2026-07-16

**Пользовательское название:** «Сохраненное»

**Внутренний bounded context:** saved-items

## 1. Итоговое продуктовое решение

Inflap предоставляет пользователю единое личное пространство, в котором можно:

1. Сохранить карточку места, публичной активности или любого другого пользователя, включая гида.
2. Позже найти ее на отдельном экране «Сохраненное».
3. Отфильтровать сохранения по категории контента.
4. При желании создать личные коллекции и вручную распределять по ним отдельные карточки.

В системе всегда существует виртуальное представление «Все». Оно содержит все ACTIVE-сохранения пользователя, не является строкой коллекции в БД, не переименовывается и не удаляется.

Пользовательские коллекции являются дополнительным способом организации. Одна карточка может входить в несколько личных коллекций, но в «Все» существует ровно один раз. Коллекции строго приватны: обнаружить, прочитать или изменить их может только владелец. Sharing, публикация, ссылки и совместная работа отсутствуют.

Canonical-состояние хранится на backend. У аккаунта одновременно действует только одна auth session: вход на новом устройстве отзывает предыдущую, а новое устройство загружает подтвержденное состояние обычными API.

Экран использует network-first модель:

- cold start и первый вход на экран требуют сети и валидной сессии;
- если сеть пропала после загрузки, уже загруженные в текущем процессе карточки остаются видимыми;
- следующая страница, новый server search и другие еще не загруженные выборки без сети не догружаются;
- thumbnail отображается только если уже был загружен общим image cache;
- после завершения процесса приложения персональная выборка не восстанавливается offline;
- persistent personal Saved cache, offline mutation queue и отдельный криптографический lease не создаются;
- данные незавершенной mutation не сохраняются между запусками и старый intent автоматически не replay-ится.

Каждое save, unsave и изменение коллекций относится к одной явно выбранной карточке и сразу отправляется на backend без искусственного delay. Пока процесс приложения жив, повторное действие с тем же target блокируется до подтвержденного результата, terminal operation status или same-key retry. После перезапуска приложение не восстанавливает pending operation и загружает текущее canonical state обычным API. Undo, recovery window и «Недавно удаленные» отсутствуют.

Во «Все», категориях и коллекциях обычный порядок карточек равен `saved_at DESC, id DESC`. Search является осознанным исключением: результаты группируются по качеству совпадения, а внутри одинакового match rank сортируются по `saved_at DESC, id DESC`.

Коллекции сортируются по `organized_at DESC, id DESC`. `organized_at` меняется только при создании, переименовании и ручном добавлении или удалении карточки. Технические обновления projection и счетчика не меняют пользовательский порядок.

Это production-реализация, а не MVP: scope ограничен подтвержденной пользовательской пользой, но надежность server persistence, безопасность, accessibility, observability, data lifecycle и rollout не упрощаются.

## 2. Зафиксированная терминология

| Термин | Значение |
|---|---|
| Сохранение | Личная связь пользователя с одной карточкой контента |
| Все | Виртуальная выборка всех ACTIVE-сохранений пользователя |
| Категория | Фильтр по типу контента, а не коллекция |
| Коллекция | Строго приватная папка пользователя для организации сохранений |
| Привязка к коллекции | Связь одной сохраненной карточки с одной коллекцией |
| Без коллекции | Виртуальный фильтр карточек, не входящих ни в одну ACTIVE-коллекцию |
| Удалить из коллекции | Удалить только привязку; карточка остается в «Все» |
| Удалить из Сохраненного | Удалить одну карточку из «Все» и всех ее коллекций |
| Недоступная карточка | Нейтральный placeholder ранее сохраненного target без sensitive projection |

В UI используются только понятные действия «Добавить в коллекцию», «Изменить коллекции», «Убрать из коллекции», «Удалить из Сохраненного» и confirmation CTA «Удалить везде». Внутренние термины `membership`, `unsave`, `scope` и `desired set` в локализованных строках запрещены.

## 3. Поддерживаемый функциональный объем

### 3.1 Типы контента

| Тип | Внутренний тип | Категория в UI | Visibility |
|---|---|---|---|
| Достопримечательность | ATTRACTION | Места | Всегда PUBLIC |
| Активность | ACTIVITY | Активности | PUBLIC или PRIVATE; Saved принимает только PUBLIC |
| Профиль пользователя | USER | Пользователи | Активный профиль; гид является обычным USER-target |

Только ACTIVITY среди поддерживаемых SavedTarget может быть PRIVATE. Checklists могут быть приватными в своем домене, но не являются SavedTarget и не получают Saved API, category или adapter.

Сохранение собственного профиля запрещено. Для USER-target backend перед любым
расширением проверяет, не заблокировал ли target владельца Saved. При такой
блокировке новый save и добавление в коллекции возвращают нейтральный
`SAVED_TARGET_UNAVAILABLE`, не раскрывая причину. Ранее сохраненный профиль не
исчезает: relationship сохраняется, а list/search/collection cover показывают
removable unavailable placeholder без имени, аватара, route и match metadata.
Global unsave и уменьшение набора коллекций остаются доступны. После unblock
публичная projection восстанавливается автоматически. Недоступность
relationship-policy dependency fail-closed только для USER: expansion
запрещается, USER projection скрывается, а места и активности продолжают
работать.

Несохраненная PRIVATE Activity:

- не получает bookmark control;
- не создает relationship;
- при прямом API-вызове возвращает неразличимый `SAVED_TARGET_UNAVAILABLE`;
- не раскрывает existence, owner или participant access.

Если ранее сохраненная PUBLIC Activity становится PRIVATE:

- relationship не удаляется автоматически;
- PUBLIC title, media, location, search document и detail route очищаются;
- пользователь видит нейтральный removable placeholder;
- разрешены global unsave и только уменьшение текущего набора коллекций;
- re-save, reactivation, membership expansion и inline create запрещены;
- PRIVATE -> PUBLIC повторно гидратирует тот же ACTIVE relationship без изменения `saved_at`.

Saved не получает ACL, audience entitlements и персональные private projections. Поддержка PRIVATE Activity для owner/participant возможна только будущим отдельным product decision и ADR.

Перед включением каждого типа source service обязан подтвердить:

- неизменяемый canonical ID на весь lifecycle target;
- visibility и lifecycle semantics;
- authenticated S2S save-eligibility RPC;
- bounded card hint `PUBLIC_SAVE_ALLOWED | PRIVATE_NOT_SAVEABLE | UNKNOWN` для согласованного UI, который никогда не принимается backend как authorization proof;
- тот же canonical target в eligibility response и monotonic source revision;
- минимальную безопасную PUBLIC card projection;
- `as_of` и source-defined `valid_until`/maximum display age для time-sensitive price/availability;
- versioned published, updated, unavailable и deleted events;
- PUBLIC <-> PRIVATE event только для ACTIVITY;
- canonical detail route;
- revocable/rotatable media reference contract для PUBLIC -> non-PUBLIC transition;
- локализованные EN/RU/KK title, city, country и display location;
- explicit `source_default_locale` из EN/RU/KK;
- deterministic locale fallback при отсутствии отдельного перевода.

Generic alias/canonicalization subsystem в baseline отсутствует. Если конкретный source domain действительно поддерживает merge/replacement со сменой ID, этот тип нельзя включать до отдельного domain-specific ADR, adapter contract, migration strategy и тестов. Остальные типы не получают alias table, merge logic или canonicalized events заранее.

### 3.2 Обязательные возможности

- one-tap online save и unsave одной карточки;
- per-target pending lock без debounce;
- отдельный экран «Сохраненное»;
- виртуальное представление «Все»;
- категории для трех поддерживаемых типов: ATTRACTION, ACTIVITY и USER;
- фильтр «Без коллекции»;
- server search по EN/RU/KK title, city и country;
- relevance tiers exact -> token -> prefix;
- cursor pagination;
- личные коллекции с уникальными ACTIVE-названиями;
- atomic inline create коллекции из picker;
- many-to-many распределение одной карточки;
- удаление из конкретной коллекции без global unsave;
- server-backed состояние после входа на новом устройстве;
- корректные loading, empty, offline, pending, unknown-result, conflict, quota и unavailable states;
- EN/RU/KK localization;
- adaptive UI и accessibility;
- bounded durable operation journal, idempotency, audit-safe observability, backup, projection reconciliation и controlled rollout.

### 3.3 Явно вне scope

- заметки, описания коллекций и другой пользовательский текст, кроме названия;
- sharing, публичные ссылки, invitations, roles и ownership transfer;
- комментарии и реакции;
- alerts по цене, доступности или датам;
- trip context, destinations, itinerary и экспорт в маршрут;
- карта сохранений, nearby и distance sort;
- city/country filter controls;
- гостевые сохранения и guest-to-account import;
- рекомендации на основе сохранений;
- smart views и автоматическое распределение;
- вложенные коллекции и теги;
- ручная сортировка карточек или коллекций;
- multi-card selection и любые массовые mutation;
- posts, routes и checklists;
- PRIVATE Activity и audience-scoped content;
- Undo, recovery и «Недавно удаленные»;
- typo tolerance, fuzzy search, generic transliteration и substring search;
- exact total/category counters на Saved search/list;
- persistent personal Saved page/card cache;
- offline writes и mutation replay после restart;
- одновременная работа аккаунта в нескольких active sessions.

Route bookmarks остаются в «Мои маршруты» и не мигрируют в Saved.

Любое расширение scope требует product evidence, UX-проверки, ADR и отдельного feature flag. Zero-result analytics используется как gate для будущих search-enhancements.

## 4. Пользовательская ценность и метрики

### 4.1 Пользовательские задачи

Пользователь должен без обучения:

1. Понять, сохранена ли карточка.
2. Сохранить ее одним нажатием.
3. Открыть «Сохраненное» из блока «Мой путь» своего профиля.
4. Найти карточку по категории, названию, городу или стране.
5. Создать коллекцию без ухода из текущего контекста.
6. Понять разницу между удалением из коллекции и из «Сохраненного».
7. Не получить ложный success при плохой сети или ACK loss.

### 4.2 Метрики полезности

| Метрика | Смысл |
|---|---|
| saved_refind_return_visit_24h | Возврат к сохранению в новый визит за 24 часа |
| successful_saved_reuse_30d | Detail или применимое действие после возврата за 30 дней |
| successful_saved_reuse_90d | Та же полезность для длинного travel lead time |
| median_time_to_refind | Время до открытия нужной карточки |
| saved_search_success | Search result открыт без следующей reformulation |
| saved_search_zero_result_rate | Основание для будущего расширения search semantics |
| saved_profile_entry_conversion | Переход из «Мой путь» в Saved |
| collection_organization_rate | Доля пользователей, применяющих коллекции |
| uncollected_organization_rate | Доля карточек, вручную распределенных из «Без коллекции» |

Same-day reuse учитывается отдельно. Preview, background prefetch и немедленное повторное открытие в том же navigation session не считаются refind.

Коммерческие действия измеряются отдельно:

- attraction detail или route handoff;
- activity join/booking start/booking complete;
- user profile open; для профиля гида отдельно измеряются contact/booking handoff.

Для privacy-safe attribution relationship получает случайный opaque `relationship_attribution_id` при каждой новой activation generation. Он не выводится из owner или target, не используется для authorization и меняется после unsave/re-save.

Search analytics использует ephemeral `saved_navigation_session_id`, `search_attempt_id` и `query_revision`. Raw target, collection ID и query в analytics не передаются. При отсутствии consent attribution events и fields отсутствуют, а Saved продолжает работать без изменений.

### 4.3 Guardrails

- confirmed data loss: 0;
- cross-account exposure: 0;
- duplicate ACTIVE relationship: 0;
- global unsave из remove-from-collection: 0;
- ложный success после network failure: 0;
- crash/ANR/jank не хуже mobile baseline;
- API error budget не превышен;
- search zero-result и abandonment не деградируют сверх согласованного порога;
- support complaints о потере сохранений или непонятном удалении не превышают baseline.

До rollout Product и Data фиксируют baseline, target, sample size, observation window и owner каждой метрики.

## 5. UX и информационная архитектура

### 5.1 Точка входа

- route: `/saved`;
- collection route: `/saved/collections/:collectionId`, только authenticated owner context; foreign/deleted ID дает neutral state и безопасный возврат в `/saved`;
- постоянная точка входа находится в профиле текущего пользователя;
- кнопка «Сохраненное» расположена в блоке «Мой путь»;
- в профилях других пользователей кнопка отсутствует;
- отдельный bottom-navigation slot и Home shortcut не создаются;
- возврат восстанавливает scroll position профиля;
- все domain cards используют единое bookmark state.

### 5.2 Структура экрана

Экран имеет два верхнеуровневых представления:

1. **Все**.
2. **Коллекции**.

«Все» содержит:

- app bar с заголовком, search и созданием коллекции;
- adaptive category selector;
- «Все», «Места», «Активности», «Пользователи»;
- filter action «Без коллекции»;
- lazy list с keyset pagination;
- отсутствие sort/reorder controls;
- сохранение scroll, query и filter в текущем процессе.

Exact total и category counts не показываются. Это снижает query cost и не добавляет пользователю постоянный счетчик, который редко помогает найти карточку.

«Коллекции» содержит:

- создание коллекции;
- локально searchable list/grid из bounded списка максимум 200 коллекций;
- title, exact active item count и cover-превью первой карточки коллекции;
- порядок `organized_at DESC, id DESC`;
- generic fallback, если коллекция пуста либо первая карточка не имеет доступного PUBLIC thumbnail.

Экран конкретной коллекции содержит title/count/actions, тот же adaptive category selector, search и lazy card list по `saved_at DESC, id DESC`. Первая карточка этого же порядка определяет cover-превью коллекции; ручной выбор cover отсутствует. Bookmark сохраняет одинаковую global Saved semantics на всех surfaces. В collection context отдельное организационное действие «Убрать из этой коллекции» показывается раньше отдельного destructive «Удалить из Сохраненного» и никогда не маскируется тем же icon/action. Metadata collection и card pages загружаются раздельно, поэтому изменение title или derived cover не сбрасывает scroll списка; Back восстанавливает scroll/query коллекций.

### 5.3 Карточки

- используется единая компактная Saved-карточка с type-specific icon, PUBLIC projection и стабильным unavailable state;
- bookmark state обозначается не только цветом;
- показываются только безопасные PUBLIC поля;
- current locale выбирает display translation;
- fallback: current locale -> source default -> EN -> первая доступная EN/RU/KK версия;
- alternate-locale search match показывается в существующем secondary-text slot;
- time-sensitive price/availability имеют explicit localized freshness state; после `valid_until` summary скрывается или помечается недоступным, но не показывается как актуальное;
- Saved card не обещает bookability: canonical detail повторно получает authoritative availability перед действием;
- thumbnail имеет стабильный aspect ratio и подходящий размер;
- primary action ведет на canonical detail;
- каждая SAVED-карточка имеет постоянное contextual action «Изменить коллекции», открывающее picker;
- в contextual menu «Удалить из Сохраненного» визуально отделено как destructive; внутри collection дополнительно раньше него расположено «Убрать из этой коллекции»;
- bookmark icon на всех surfaces означает только global Saved state и не заменяется collection-specific action.

PRIVATE/unavailable placeholder:

- не показывает прежние title, media и detail route;
- имеет действие «Удалить из Сохраненного»;
- внутри коллекции имеет «Убрать из этой коллекции»;
- из «Все» может открыть reduction-only picker;
- reduction-only picker показывает только текущие коллекции, разрешает снимать checkbox, но не позволяет additions или inline create.

### 5.4 Сохранение карточки

1. Пользователь нажимает bookmark.
2. Repository проверяет authenticated session и известное network state.
3. Создаются cryptographically random UUIDv4 operation ID и независимый >=128-bit idempotency key; target блокируется.
4. Request с operation ID и idempotency key отправляется немедленно; operation identity и semantic request удерживаются только в памяти живого процесса.
5. Bookmark меняется только после server confirmation текущей operation и monotonic resource version.
6. Success показывает «Добавлено в Сохраненное» и действие «В коллекцию».
7. Подтвержденная terminal ошибка снимает lock и показывает retry с новым operation ID/key, если ошибка retryable.
8. Timeout после возможной отправки переводит target в `PENDING_UNKNOWN`.
9. Пока процесс жив, unknown result разрешается owner/session-scoped operation status или повтором того же semantic request с тем же idempotency key. Plain `NOT_FOUND` от status не считается результатом: client делает same-key retry, который создает либо находит server receipt.
10. `EXPIRED` для существующей server operation означает, что она больше не может commit-иться; после terminal status client обновляет затронутое canonical state.
11. После process restart pending metadata отсутствует: client выполняет обычный online canonical bootstrap без status lookup и без replay старого intent. Уже принятый server request может завершиться только в пределах hard commit deadline; последующий refresh приводит UI к server state.
12. Delayed response старой operation не может откатить более новую version.

При заведомом offline state bookmark не меняется и UI предлагает повторить после подключения.

Если пользователь не авторизован, bookmark открывает contextual sign-in. Одноразовый continuation имеет короткий TTL, отменяется при уходе с исходного context и после login повторно проверяет target eligibility.

### 5.5 Удаление из Сохраненного

Удаление всегда относится к одной карточке.

Если effective memberships отсутствуют:

- current server response/`SavedStateRegistry` содержит `effective_collection_count = 0`; если count еще UNKNOWN, repository один раз получает `GET target collections`;
- DELETE отправляется без dialog;
- success показывает «Удалено из Сохраненного» без Undo;
- следующий save является новой activation без старых memberships.

Если карточка входит в коллекции:

- repository получает свежие exact membership IDs и collection titles через существующий `GET target collections`;
- sheet сообщает: «Карточка будет удалена из “Все” и из N коллекций»;
- доступны «Удалить везде», «Изменить коллекции» и «Отмена»;
- «Удалить везде» является semantic confirmation глобального удаления, а не подтверждением неизменности числа N;
- после подтверждения client отправляет обычный DELETE с новым operation ID/idempotency key без membership versions и без отдельного commit endpoint;
- server одной transaction блокирует relationship, переводит его в REMOVED и удаляет все effective memberships, существующие в момент commit;
- изменение N между preview и commit не вызывает повторный prompt; concurrent expansion после удаления отклоняется по relationship state/version.

### 5.6 Коллекции

Название:

- обязательно;
- 1..80 Unicode code points и не больше 320 UTF-8 bytes после trim;
- display title хранится в NFC;
- normalized key использует зафиксированный `COLLECTION_TITLE_NORMALIZATION_V1`: NFKC, Unicode full case folding, trim и collapse Unicode whitespace;
- line breaks, invalid Unicode, C0/C1 controls и bidi control symbols запрещены;
- zero-width format characters запрещены, кроме ZWJ; variation selectors и ZWJ допускаются без отдельного grapheme-parser;
- emoji допускаются как обычный Unicode text;
- normalized key ограничен 512 UTF-8 bytes;
- ACTIVE-названия одного owner уникальны по normalized key;
- visual-confusable detection не обещается и не блокирует приватное название.

Unicode data/package version для V1 закрепляется dependency lockfile и не меняется молча. Client validation является подсказкой; backend и partial unique index остаются authoritative. Новая normalization semantics вводится только отдельным ADR и collision-audited migration при реальной необходимости, без заранее реализуемой multi-version runtime logic.

Collection picker:

- adaptive bottom sheet;
- checkbox list;
- локальный search по normalized exact/token/prefix среди не более 200 загруженных ACTIVE collection options;
- inline create с draft;
- sticky action над клавиатурой;
- одна atomic target-scoped desired-set mutation;
- optional `new_collection` создается и включается в exact set той же transaction;
- selection и title draft сохраняются после исправимой ошибки;
- normal quota values не загромождают UI;
- warning показывается только около server-defined threshold или после quota rejection.

Удаление коллекции:

- confirmation показывает свежие title и current item count;
- текст сообщает, что карточки останутся в «Все» и других коллекциях;
- DELETE проверяет только ACTIVE lifecycle и подтвержденную metadata version;
- изменение item count само по себе не требует повторного confirmation;
- parent одной короткой transaction становится DELETED;
- title и normalized key очищаются;
- effective memberships сразу исчезают из reads и quotas;
- saved relationships остаются ACTIVE;
- восстановление и Undo отсутствуют;
- child rows физически удаляются FK-safe bounded batches не позже 24 часов, без отдельного user-visible cleanup lifecycle; payload-free parent tombstone сохраняется 14 дней.

### 5.7 Search

Search проверяет EN/RU/KK варианты title, city и country независимо от UI locale.

Поддерживаются:

- normalized full-field exact;
- token exact;
- field/token prefix.

Server назначает deterministic match rank:

1. title exact;
2. title token exact;
3. title/token prefix;
4. location exact/token;
5. location prefix.

Внутри одного rank используется `saved_at DESC, id DESC`.

Если одна карточка совпала по нескольким fields/locales, presentation match выбирается детерминированно по tuple `rank -> TITLE/CITY/COUNTRY -> current locale -> source default -> EN/RU/KK`. Effective display locale входит в search scope fingerprint, чтобы replay cursor возвращал тот же `matched_locale`.

Не поддерживаются:

- typo/fuzzy fallback;
- generic transliteration;
- arbitrary substring;
- city/country filter parameters;
- relevance score, зависящий от нестабильной DB-эвристики.

Collection list и picker не вызывают server search. `GET /saved-collections` возвращает bounded список максимум 200 элементов в `organized_at DESC, id DESC`, после чего mobile локально применяет full-title exact, token exact и title/token prefix. Backend остается authoritative только для uniqueness и CRUD.

Search request:

- отправляется POST body;
- имеет debounce и cancellation;
- stale response не заменяет более новый `query_revision`;
- raw query отсутствует в logs, traces, crash reports и analytics;
- zero-result state сохраняет query и предлагает clear;
- дальнейшее расширение search возможно только после анализа privacy-safe zero-result data.

### 5.8 Network и UI states

Обязательны:

- initial skeleton;
- pull-to-refresh без предварительной очистки snapshot;
- empty «Все» с переходом в Explore/Search;
- empty category с clear-filter;
- empty collection с «Перейти ко всем»;
- empty «Без коллекции»;
- offline before initial load: connection-required state;
- offline after successful load: уже загруженный snapshot остается видимым;
- offline banner и disabled server-dependent actions;
- end-of-loaded-data marker вместо бесконечного spinner;
- pending;
- `PENDING_UNKNOWN`;
- retryable network error;
- permanent validation/access error;
- unavailable/private/deleted placeholder;
- quota reached;
- version conflict с конкретным следующим действием;
- platform emergency-lockdown state без показа personal data.

При потере сети:

- новые pages не загружаются;
- новый server search не запускается;
- scope, который еще не был загружен, не выдается за пустой;
- mutations не ставятся в очередь;
- уже загруженные thumbnails могут отображаться из общего public image cache;
- detail открывается offline только если соответствующий domain feature уже имеет собственный допустимый cache.

Pending UX не меняет размеры карточки: bookmark получает progress/disabled semantics. `PENDING_UNKNOWN` формулируется как «Проверяем результат» с действием «Проверить», а не как success/error и не предлагает новую mutation, пока живой процесс не получил terminal/expired status или same-key response.

### 5.9 Accessibility и adaptive UI

- touch target не меньше 48x48 dp;
- icon buttons имеют localized Semantics label и selected state;
- text scale до 200 процентов не скрывает critical actions;
- compact < 600 dp: одна колонка;
- medium 600..839 dp: adaptive grid;
- expanded >= 840 dp: constrained multi-column layout;
- SafeArea, keyboard insets и scrollable sheets обязательны;
- long EN/RU/KK strings не обрезают confirmations;
- focus order, screen reader, reduced motion и contrast входят в acceptance.

## 6. Domain-модель и инварианты

### 6.1 SavedTarget

`SavedTarget = { entity_type, entity_id }`, где:

- `entity_type`: ATTRACTION | ACTIVITY | USER;
- `entity_id`: opaque canonical source identifier.

Client не интерпретирует `entity_id` и не строит из него SQL или произвольный URL.

### 6.2 Главные инварианты

1. У owner не больше одного relationship на SavedTarget.
2. «Все» содержит ровно ACTIVE relationships.
3. Category определяется `entity_type` и не создает rows.
4. Membership, collection и relationship принадлежат одному owner.
5. Effective membership требует ACTIVE membership row, ACTIVE relationship и ACTIVE parent collection.
6. Одна карточка входит в конкретную коллекцию не больше одного раза.
7. Remove-from-collection не меняет relationship.
8. Collection delete не меняет relationships.
9. Global unsave принимает ровно один target.
10. Другой пользователь не может обнаружить personal resource по UUID.
11. Collection не имеет PUBLIC/LINK/SHARED mode.
12. Source service остается источником истины для content lifecycle и PUBLIC projection.
13. Client clock не определяет ordering или winner.
14. PRIVATE/unavailable target допускает только уменьшение уже существующего personal state.

### 6.3 Relationship lifecycle

ACTIVE:

- отображается в «Все»;
- может иметь effective memberships;
- имеет server `saved_at`;
- имеет случайный relationship attribution ID.

REMOVED:

- не отображается;
- effective memberships отсутствуют;
- повторный save создает новую activation generation;
- старые memberships не восстанавливаются;
- payload-free tombstone хранится 14 дней для bounded lifecycle/idempotency cleanup и затем purge-ится.

### 6.4 Collection lifecycle

ACTIVE:

- видна owner;
- допускает rename и membership mutations.

DELETED:

- немедленно скрыта;
- title и normalized key очищены;
- child rows неэффективны независимо от их физического state;
- saved relationships остаются ACTIVE;
- quota освобождена в parent transaction;
- восстановление отсутствует;
- cleanup-pending child rows удаляются не позже 24 часов, а parent tombstone — после стандартной 14-day eligibility.

### 6.5 Concurrency

- save/save сходится к одному desired state;
- remove/remove является idempotent no-op;
- rename требует metadata version;
- desired-set требует relationship state/version и dependent-membership version;
- global unsave не требует membership versions: после UI-confirmation он атомарно удаляет relationship и все memberships, существующие в момент commit;
- manual membership add/remove увеличивает dependent-membership version; parent delete не делает child fan-out;
- collection delete требует lifecycle и metadata version, но не item-count version;
- delayed response применяется только к текущей in-memory operation и monotonic resource version;
- last-response-wins и client-clock-wins запрещены.

## 7. Архитектурное решение

### 7.1 Граница saved-service

Saved-service отвечает за:

- personal relationships;
- collections и memberships;
- owner-scoped list/search;
- on-demand PUBLIC projection;
- bounded mutation operation journal и idempotency outcomes;
- service-level enforcement общей platform emergency access policy;
- quotas, outbox, projection reconciliation и subject purge.

Source services отвечают за:

- existence и canonical identity;
- visibility/lifecycle;
- localized PUBLIC card projection;
- media reference и detail route;
- authenticated eligibility RPC;
- versioned lifecycle events;
- неизменяемость canonical ID либо отдельный domain-specific canonicalization ADR до включения типа.

API Gateway отвечает за:

- authentication;
- trusted identity/session headers;
- body limits и rate limits;
- route policy;
- request/trace IDs;
- stripping spoofed headers;
- edge enforcement общей platform emergency access policy.

### 7.2 Почему отдельный сервис

| Вариант | Решение |
|---|---|
| Favorite-table в каждом source | Отклонен: fan-out и разные contracts |
| User-service | Отклонен: связывает profile domain со всеми content domains |
| Только local storage | Отклонен: нет server persistence |
| Отдельный saved-service | Выбран: единый owner model, collections и query surface |

### 7.3 Write flow

1. Gateway проверяет current single-active session generation.
2. Mobile создает client-generated UUID operation ID и idempotency key, удерживает semantic request в памяти и немедленно отправляет его.
3. Saved-service определяет closed operation kind, canonical request HMAC и bounded server commit deadline.
4. Короткая DB transaction сериализуется по owner/session/operation ID и создает либо находит `saved_operations` row. Новая mutation получает `PENDING`; same idempotency identity с другим HMAC отклоняется, existing terminal state replay-ится, existing `PENDING` возвращает in-progress status.
5. Любой mutation commit обязан CAS-проверить `status = PENDING`, неистекший deadline и допустимую session generation. После deadline operation уже не может изменить domain state.
6. Privacy-reducing operation не зависит от source availability.
7. Любое save/reactivation/membership expansion требует PUBLIC eligibility.
8. ATTRACTION может использовать server validation cache не старше 30 секунд.
9. ACTIVITY expansion требует authenticated live source RPC; USER expansion дополнительно требует live fail-closed relationship check.
10. Для eligibility-required operation короткая transaction создает или находит on-demand payload-free projection shell `UNKNOWN`, связанный с bounded operation deadline. Это дает concurrent deny-event строку и не создает full catalog mirror.
11. Source RPC обязан вернуть тот же immutable canonical target, visibility/source revisions и PUBLIC projection. Другой ID является contract violation и fail-closed; domain-specific merge support не входит в generic flow.
12. Final DB transaction сначала блокирует operation row, затем projection и domain rows, проверяет status/deadline/session generation, current platform access policy, deny revision, preconditions и quotas.
13. Domain write, outbox и transition operation в `SUCCEEDED` либо deterministic non-mutating `REJECTED` commit-ятся атомарно.
14. Известная dependency/pre-commit ошибка переводит `PENDING` в terminal `REJECTED` с typed retryable outcome; новая попытка использует новый operation ID/key.
15. Если handler/process исчез после записи `PENDING`, bounded sweeper CAS-переводит operation в `EXPIRED` после deadline.
16. Concurrent same-key request делает только bounded wait либо получает `PENDING`/terminal result; повторный source RPC для той же operation не запускается.
17. Response содержит operation ID, status, outcome, commit deadline и applied resource versions; mobile применяет его только к current in-memory operation и не поверх более новой version.

Operation states:

- `PENDING` — короткоживущая durable receipt, но не background job;
- `SUCCEEDED` — terminal mutation/no-op result;
- `REJECTED` — terminal non-mutating result;
- `EXPIRED` — terminal guarantee, что существующая server operation больше не может commit-иться.

`RETRYABLE` как persisted state, lease takeover, fencing epoch, server-side retry scheduler и хранение request payload не используются.

При ACK loss client в текущем процессе читает operation status либо повторяет тот же semantic request с тем же key. `NOT_FOUND` от status сам по себе не завершает unknown state: same-key retry создает или находит durable receipt. После terminal status client обновляет canonical resource.

После process restart operation identity и request отсутствуют. Client выполняет обычный canonical online refresh и никогда автоматически не replay-ит старый intent. Это осознанный bounded trade-off: уже принятый request может завершиться только до hard server deadline и станет виден при следующем refresh.

### 7.4 Reduction и expansion

Privacy-reducing:

- global unsave;
- remove-from-collection;
- strict subset текущего effective collection set;
- collection delete.

Eligibility-required:

- новый save;
- reactivation;
- новый PUT save intent для ACTIVE target;
- membership addition;
- mixed replace;
- inline `new_collection`.

Если target PRIVATE, UNAVAILABLE, DELETED или RESTRICTED:

- reduction разрешена;
- expansion отклоняется целиком;
- mixed replace не применяется частично.

### 7.5 Read flow и pagination

- cold screen bootstrap требует online session validation и Saved API;
- server сначала ограничивает query owner-ом;
- card projection читается без fan-out к source services;
- cursor является opaque AEAD-encrypted и authenticated keyset token с key ID и bounded expiry;
- normal list cursor содержит subject, scope fingerprint, schema, expiry и last `saved_at/id`;
- search cursor дополнительно содержит last `match_rank`;
- scope fingerprint является keyed digest и не раскрывает raw search query;
- client дедуплицирует IDs между pages;
- pull-to-refresh или local mutation заменяет affected snapshot;
- новые элементы перед cursor становятся видимыми при refresh;
- invalid/expired cursor возвращает один neutral `SAVED_CURSOR_INVALID`; client перезапускает текущий scope с первой page, не показывая его как empty;
- cursor не обещает frozen snapshot и не использует owner revision vector;
- `SAVED_CURSOR_STALE` и anchor-seek отсутствуют.

ETag применяется для обычной conditional revalidation загруженной page, но не превращает cursor в snapshot transaction.

### 7.6 Graceful degradation

- saved-service outage не блокирует Home/Search/detail content;
- bookmark при UNKNOWN не изображается как UNSAVED;
- source outage не блокирует privacy-reducing commands;
- ACTIVITY expansion fail-closed при source outage;
- USER expansion fail-closed при user-source или relationship-policy outage;
- relationship-policy outage скрывает только USER projections и не блокирует места, активности или privacy-reducing commands;
- already hydrated screen остается доступным в памяти после network loss;
- new pages, search и writes без сети не выполняются;
- process restart без сети показывает connection-required state;
- product flags не скрывают existing personal data;
- platform emergency access policy fail-closed блокирует все Saved reads и writes.

## 8. PostgreSQL-модель

### 8.1 saved_items

Основные поля:

- `id UUID PK`;
- `owner_user_id UUID NOT NULL`;
- `entity_type` closed enum/check;
- `entity_id TEXT` с byte limit;
- `relationship_state ACTIVE | REMOVED`;
- `saved_at, updated_at`;
- `removed_at, purge_eligible_at`;
- `state_generation UUID`;
- `relationship_attribution_id UUID`;
- `relationship_version BIGINT`;
- `dependent_membership_version BIGINT`;
- unique `(owner_user_id, entity_type, entity_id)`;
- unique `(owner_user_id, id)` для tenant-safe child FK.

`saved_at` меняется только при absent/REMOVED -> ACTIVE. Membership mutation его не меняет. Новая activation меняет `state_generation` и `relationship_attribution_id`.

### 8.2 saved_content_projections

Одна shared PUBLIC projection или payload-free deny tombstone:

- `entity_type + entity_id PK`;
- `source_service`;
- `source_revision`;
- `projection_revision`;
- `visibility_revision`;
- `visibility_status UNKNOWN | PUBLIC | PRIVATE | UNAVAILABLE | DELETED | RESTRICTED`;
- `visibility_validated_at`;
- `source_default_locale` constrained to EN/RU/KK;
- localized EN/RU/KK title/subtitle/city/country/display location;
- versioned normalized search document;
- media reference;
- rating и safe price/availability summary с `as_of` и `valid_until`;
- canonical detail route;
- `shell_expires_at` для любой ephemeral materialization с `ever_referenced=false`;
- `ever_referenced BOOLEAN` для выбора ephemeral/standard retention;
- `gc_candidate_at` для unreferenced materialized projection;
- `created_at, updated_at`.

UNKNOWN является внутренним payload-free on-demand shell и никогда не разрешает mutation. PRIVATE допустим только для ACTIVITY. Для non-PUBLIC status card payload, search document, media и route обязаны быть NULL.

Projection materialization:

- payload-free UNKNOWN shell создается при первой eligibility-required operation до source RPC и получает expiry, превышающий operation deadline;
- saved-service не является full catalog mirror;
- events для неизвестного target не создают projection;
- events обновляют только уже materialized target, включая shell текущей first-save operation;
- final write не может заменить более новый deny revision старым PUBLIC RPC response;
- entity type/key валидируются до shell insert;
- создание нового shell ограничено subject/IP rate limit, лимитом concurrent `PENDING` operations и global UNKNOWN-shell breaker;
- re-save после GC снова гидратирует projection через source RPC;
- reconciliation обходит только bounded materialized rows.

Projection GC:

- row с `ever_referenced=false` остается ephemeral даже если source/event сменил UNKNOWN на PUBLIC/deny; без ACTIVE relationship и связанной `PENDING` operation она удаляется bounded batches по `shell_expires_at`;
- first successful ACTIVE relationship атомарно выставляет `ever_referenced=true` и очищает `shell_expires_at`;
- default ephemeral TTL 15 минут, hard purge SLO не больше часа после expiry;
- worker сначала выставляет `gc_candidate_at`, только если `NOT EXISTS` ACTIVE saved relationship;
- source content updates не сдвигают `gc_candidate_at`; новый ACTIVE save атомарно очищает его;
- после retention worker берет row lock, повторно проверяет `NOT EXISTS` и удаляет candidate bounded batches;
- active placeholder/relationship запрещает GC;
- in-flight final transaction races учитываются общей lock hierarchy;
- ранее referenced PUBLIC/deny projection без ACTIVE references удаляется через 14 дней от `gc_candidate_at`, а не от content `updated_at`;
- повторный save не полагается на старую projection и повторно валидирует source.

### 8.3 saved_collections

- `id UUID PK`;
- `owner_user_id UUID`;
- `client_creation_id UUID`;
- `title` nullable для terminal tombstone;
- `normalized_title_key` nullable;
- `lifecycle_state ACTIVE | DELETED`;
- `lifecycle_version`;
- `metadata_version`;
- `items_version`;
- `active_item_count`;
- `created_at`;
- `organized_at`;
- `updated_at`;
- `deleted_at, purge_eligible_at`;
- unique `(owner_user_id, client_creation_id)`;
- unique `(owner_user_id, id)`.

Partial unique index:

`(owner_user_id, normalized_title_key COLLATE "C") WHERE lifecycle_state = 'ACTIVE'`.

`organized_at` меняется только при create, rename и manual membership mutation. `updated_at` честно меняется при любом row update, включая lifecycle transition.

`normalized_title_key` всегда строится по зафиксированному `COLLECTION_TITLE_NORMALIZATION_V1`; Unicode dependency/data version закреплена lockfile. Runtime не поддерживает несколько normalization versions. Изменение V1 запрещено без отдельного ADR, collision audit и обычной expand/contract migration.

Derived cover contract:

- cover не хранится в `saved_collections` и не имеет отдельного lifecycle, reverse index или repair queue;
- при чтении collection list/detail server выбирает первую effective membership по `saved_at_snapshot DESC, saved_item_id DESC`, то есть ту же первую карточку, что видит пользователь в списке коллекции;
- если ее current projection PUBLIC и содержит thumbnail, response возвращает bounded `cover_preview` этой карточки;
- пустая коллекция, PRIVATE/unavailable первая карточка или отсутствие thumbnail дают stable generic fallback; следующая карточка специально не подставляется;
- source deny event очищает shared projection, поэтому следующий read немедленно перестает возвращать прежнюю media без fan-out по коллекциям;
- derived cover никогда не меняет `organized_at` и не требует background maintenance.

### 8.4 saved_collection_items

- `id UUID PK`;
- `owner_user_id UUID`;
- `collection_id UUID`;
- `saved_item_id UUID`;
- `membership_state ACTIVE | REMOVED`;
- `membership_version`;
- `saved_at_snapshot TIMESTAMPTZ` из authoritative `saved_items.saved_at` для стабильного cover/list lookup;
- `removal_reason`;
- `added_at, updated_at, removed_at, purge_eligible_at`;
- unique `(owner_user_id, collection_id, saved_item_id)`;
- tenant-safe FK на collection и saved item.

ACTIVE child под DELETED parent считается cleanup-pending и не является effective membership. Он не читается, не учитывается в quota и физически удаляется generic worker bounded batches не позже 24 часов после parent delete.

Обычный REMOVED membership получает собственный 14-day `purge_eligible_at`. DELETED parent и terminal operation results сохраняются стандартные 14 дней, но не удерживают cleanup-pending children. После parent eligibility worker проверяет отсутствие children и связанных operation dependencies, затем удаляет parent.

Cross-resource lifecycle применяется явными repository transactions и lock order. DB отвечает за FK, unique, row-local CHECK и tenant safety; скрытая бизнес-оркестрация в сложных cross-table triggers не используется.

`saved_at_snapshot` задается backend при создании/reactivation membership и не принимается от client. Пока relationship ACTIVE, его `saved_at` неизменяем, поэтому snapshot не требует repair.

### 8.5 Idempotency и infrastructure

`saved_operations`:

- client-generated `operation_id UUID`;
- subject;
- session generation;
- closed non-null `operation_kind`;
- non-null idempotency key;
- non-null semantic request HMAC + key version;
- first-seen canonical source surface;
- accepted platform access-policy revision;
- status `PENDING | SUCCEEDED | REJECTED | EXPIRED`;
- server commit deadline;
- outcome, coarse `refresh_scope SAVED_ITEMS | COLLECTIONS | BOTH | NONE`, observed precondition versions и applied resource versions;
- created/completed/retention-expiry timestamps.

PK: `(subject, session_generation, operation_id)`.

Unique idempotency identity: `(subject, session_generation, idempotency_key)`. Один key запрещено переиспользовать между resources/commands; request HMAC mismatch возвращает replay error. Foreign operation ID возвращает neutral not-found.

`PENDING` не содержит mutation payload, collection IDs/titles, search query, card payload или raw source surface. Commit возможен только CAS-переходом до deadline и при разрешающей current platform policy. Terminal row также не хранит presentation snapshots. Terminal rows хранятся по умолчанию 14 дней и затем удаляются bounded retention worker.

Semantic HMAC использует server key version. Старые keys доступны для проверки не меньше максимального idempotency retention, а rotation выполняется с overlap без хранения raw canonical payload.

Другие таблицы:

- `saved_outbox`;
- `saved_inbox_dedup`;
- `saved_user_usage`;
- `saved_collection_usage`;
- `saved_subject_purge_operations`.

Отдельная cleanup-job table для delete collection не создается. Generic retention worker удаляет cleanup-pending children bounded batches в течение 24 часов, а terminal parent — после его 14-day eligibility.

### 8.6 Индексы

- owner + relationship state + `saved_at DESC, id DESC`;
- owner + entity type + state + `saved_at DESC, id DESC`;
- target projection PK;
- projection ephemeral `shell_expires_at`, visibility и `gc_candidate_at` partial indexes;
- normalized search-document indexes, подтвержденные owner-first EXPLAIN ANALYZE;
- owner + collection lifecycle + `organized_at DESC, id DESC`;
- ACTIVE normalized collection-title unique index;
- DELETED collection `(deleted_at, id)` partial index для bounded child cleanup;
- owner + collection + `saved_at_snapshot DESC, saved_item_id DESC` partial index для ACTIVE membership и derived cover;
- owner + saved item + membership state + collection;
- operation identity, `status + commit_deadline` и retention expiry;
- terminal `purge_eligible_at` indexes.

### 8.7 Configurable limits

- 10 000 ACTIVE saves на owner;
- 200 ACTIVE collections;
- 5 000 effective memberships в collection;
- 50 000 effective memberships на owner;
- batch status до 100 targets;
- не больше 32 concurrent `PENDING` operations на subject;
- server operation deadline hard max 15 секунд;
- Gateway-to-handler lifetime для одного Saved mutation request hard max 30 секунд; transport/proxy не queue-ит и не replay-ит request после закрытия connection;
- desired set до 200 collection IDs;
- page default 30, hard max 100;
- Saved search до 200 code points и bounded token count;
- collection title до 80 code points.

Limits защищают систему, а не являются монетизацией. UI показывает remaining quota только около threshold или после authoritative rejection.

## 9. HTTP API

### 9.1 Общие правила

- versioned `/v1`;
- OpenAPI является contract source of truth;
- owner берется только из trusted auth context;
- entity key имеет canonical encoding и byte limit;
- domain mutations используют cryptographically random UUIDv4 `Operation-Id` и независимый >=128-bit `Idempotency-Key`;
- mutable scopes используют typed base version;
- cursor AEAD-encrypted, authenticated, owner/scope-bound, имеет key ID и expiry;
- timestamps UTC RFC 3339;
- `Accept-Language` нормализуется в effective EN/RU/KK locale; locale входит в projection/search cursor scope;
- private responses запрещены для shared cache;
- request/response bodies personal endpoints не логируются;
- concrete personal route и query parameters редактируются в access logs до route template;
- payload/encoding limits проверяются до DB work.

Cursor plaintext никогда не логируется. Previous decrypt keys сохраняются не меньше maximum cursor TTL + clock-skew window; malformed, expired, wrong-owner/scope и unknown-key tokens имеют один external error shape.

`session_generation` должен быть стабильным в пределах одного login session и не меняться при обычной access-token rotation. Новый login/logout/replacement создает новую generation.

Mutation response:

- `operation_id`;
- `operation_status`;
- `operation_outcome`;
- `commit_deadline`;
- `refresh_scope` без resource IDs;
- `applied_resource_versions`;
- `result_recorded_at`;
- optional fresh `current_resource_snapshot` с собственной version.

Immutable operation result описывает конкретную attempt, а не обещает current state после более поздних mutations. Optional fresh owner-scoped snapshot строится отдельно и не является частью replayed result.

`refresh_scope` определяется server-side: save/unsave без membership effects -> `SAVED_ITEMS`; metadata-only collection create/rename -> `COLLECTIONS`; membership change, global unsave с memberships, inline create или collection delete -> `BOTH`; non-mutating rejection без нужды refresh -> `NONE`. Client может расширить refresh, но не сужать server hint.

### 9.2 Endpoints

~~~http
PUT    /v1/users/me/saved-items/{entityType}/{entityKey}
DELETE /v1/users/me/saved-items/{entityType}/{entityKey}
GET    /v1/users/me/saved-items
POST   /v1/users/me/saved-items/query
POST   /v1/users/me/saved-items/status:batch
GET    /v1/users/me/saved-items/capabilities
GET    /v1/users/me/saved-items/{entityType}/{entityKey}/collections
PUT    /v1/users/me/saved-items/{entityType}/{entityKey}/collections
GET    /v1/users/me/saved-operations/{operationId}

POST   /v1/users/me/saved-collections
GET    /v1/users/me/saved-collections
GET    /v1/users/me/saved-collections/{collectionId}
PATCH  /v1/users/me/saved-collections/{collectionId}
DELETE /v1/users/me/saved-collections/{collectionId}
~~~

Mass mutation endpoint отсутствует.

`GET /capabilities` возвращает effective product flags/revision, `has_confirmed_saved_data`, поддерживаемые entity types и quota warning. Endpoint остается доступным при выключенных product flags, но блокируется общей platform emergency access policy.

`POST /status:batch` принимает не больше 100 targets и возвращает только owner Saved state, exact `effective_collection_count`, eligibility hint и resource version без card projection. Это единственный batch read endpoint Saved; произвольный projection lookup отсутствует.

`GET /saved-operations/{operationId}` доступен только subject и session generation исходной operation, возвращает `PENDING | SUCCEEDED | REJECTED | EXPIRED`, outcome/deadline/coarse refresh scope/versions и optional fresh canonical snapshot. Endpoint используется только пока процесс хранит operation identity, никогда не запускает или replay-ит mutation. Foreign/unknown ID неразличимы; при `NOT_FOUND` живой client повторяет тот же semantic request с тем же idempotency key вместо создания отдельного reconcile command.

### 9.3 List и search contracts

Normal list принимает:

- `type`;
- `collection_id`;
- `uncollected`;
- `cursor`;
- `limit`.

Во всех normal/search scopes `collection_id` и `uncollected=true` взаимоисключающие. Foreign/deleted collection получает neutral not-found. `GET /saved-collections/{collectionId}` возвращает metadata, а обычные страницы карточек коллекции читает owner-scoped `/saved-items?collection_id=...`.

Search POST принимает:

- `type`;
- `collection_id`;
- `uncollected`;
- `search`;
- `cursor`;
- `limit`.

`country_id` и `city_id` отсутствуют.

Response:

- `items`;
- `next_cursor`;
- `has_more`;
- `quota_warning` при необходимости;
- item-level relationship attribution только при analytics consent.

Каждый saved item/status содержит exact `effective_collection_count`, чтобы обычный one-tap unsave при нуле не требовал preflight request. Это per-card organizational state, а не запрещенный total/category counter.

Exact total/category counts отсутствуют.

Search item дополнительно содержит bounded:

- `match_rank`;
- `match_kind EXACT | TOKEN | PREFIX`;
- `matched_field TITLE | CITY | COUNTRY`;
- `matched_locale`;
- alternate public display value только если match не совпадает с current display field.

### 9.4 Save и removal

PUT:

- absent/REMOVED -> ACTIVE создает новую activation;
- ACTIVE -> operation-level no-op после current eligibility validation;
- PRIVATE/unavailable target не изменяет existing relationship;
- replay terminal key возвращает immutable operation result; optional current snapshot строится заново и явно versioned.

DELETE:

- всегда означает semantic global unsave одной карточки;
- UI до вызова использует свежий `GET target collections`: при N=0 отправляет DELETE сразу, при N>0 сначала показывает confirmation «Удалить везде»;
- backend не принимает confirmation flag, membership versions или snapshot token: authenticated owner имеет право удалить собственную карточку независимо от client UI;
- transaction блокирует relationship, переводит его в REMOVED и удаляет все effective memberships, существующие в момент commit;
- изменение N после preview не отклоняет operation и не вызывает второй prompt;
- concurrent membership expansion сериализуется после relationship lock и не может восстановить membership под REMOVED relationship.

### 9.5 Collection assignment

GET target collections возвращает:

- relationship state/generation/version;
- dependent-membership version;
- exact effective collection IDs;
- доступные ACTIVE collection options с title, достаточные для удаления-preview и локального picker search;
- quota warning/snapshot при необходимости.

PUT принимает:

- discriminated `EXPECTED_ABSENT | EXPECTED_ACTIVE | EXPECTED_REMOVED`;
- current relationship/dependent-membership versions;
- unique `desired_collection_ids`;
- optional один `new_collection { client_creation_id, title }`.

Server:

- locks collection rows в стабильном UUID order;
- повторно вычисляет current effective set;
- проверяет owner, lifecycle и quota;
- классифицирует reduction/expansion;
- создает save/collection/memberships одной transaction;
- не создает partial state при любой ошибке.

Client не передает collection `items_version` или lifecycle vector. Deleted/foreign desired collection определяется под server lock и возвращает typed conflict.

### 9.6 Collection CRUD

POST create использует immutable `client_creation_id`.

PATCH меняет только title и требует metadata version.

DELETE:

- требует lifecycle и metadata version;
- не требует `items_version`;
- не отклоняется только из-за изменившегося item count;
- одной parent transaction скрывает collection и effective memberships;
- не ждет физического удаления child rows;
- никогда не выполняет unsave.

`GET /saved-collections` возвращает все ACTIVE collections owner одним bounded ответом до hard limit 200 в `organized_at DESC, id DESC`; отдельные pagination/search endpoints отсутствуют. Mobile выполняет title search локально и лениво строит только видимые widgets/images.

Collection list/detail возвращают exact `active_item_count`, derived `cover_preview` первой карточки либо generic fallback, metadata/lifecycle versions и quota warning при необходимости.

### 9.7 Error codes

- `SAVED_TARGET_TYPE_UNSUPPORTED`;
- `SAVED_TARGET_UNAVAILABLE`;
- `SAVED_DEPENDENCY_UNAVAILABLE`;
- `SAVED_MUTATION_STALE`;
- `SAVED_MUTATION_REPLAY_MISMATCH`;
- `SAVED_COLLECTION_NOT_FOUND`;
- `SAVED_COLLECTION_DELETED`;
- `SAVED_COLLECTION_TITLE_INVALID`;
- `SAVED_COLLECTION_TITLE_CONFLICT`;
- `SAVED_COLLECTION_LIMIT_REACHED`;
- `SAVED_COLLECTION_ITEM_LIMIT_REACHED`;
- `SAVED_MEMBERSHIP_LIMIT_REACHED`;
- `SAVED_ITEM_LIMIT_REACHED`;
- `SAVED_REQUEST_IN_PROGRESS`;
- `SAVED_OPERATION_EXPIRED`;
- `SAVED_CURSOR_INVALID`;
- `SAVED_RATE_LIMITED`;
- `SAVED_TEMPORARILY_UNAVAILABLE`;
- shared `PLATFORM_PERSONAL_DATA_LOCKED`.

Missing, PRIVATE, restricted и deleted target имеют одинаковый external error shape. Source outage возвращает отдельный retryable dependency error.

Error envelope содержит stable `code`, `retryable` и optional `retry_after_ms`.

### 9.8 Idempotency outcomes

| Outcome | Server state | Mobile |
|---|---|---|
| Request durably accepted | PENDING до bounded deadline | Keep target locked; poll status or same-key retry |
| Success/no-op | Terminal SUCCEEDED | Apply only current operation/version |
| Deterministic rejection в final transaction | Terminal REJECTED | Show actionable error; changed intent uses new key |
| Known transient dependency/pre-commit failure | Terminal REJECTED с retryable outcome | Unlock; explicit retry creates new operation/key |
| Handler/process lost | Existing PENDING до deadline, затем CAS EXPIRED | Пока process жив: wait/status; после EXPIRED refresh canonical state |
| Concurrent same key | Bounded wait, PENDING или terminal result | Status/same-key retry; no second intent |
| ACK/connection loss | Unknown to client | PENDING_UNKNOWN; operation status или same-key retry в живом процессе |
| Process restart | Pending metadata потеряна, request не replay-ится | Online canonical bootstrap; возможный accepted request ограничен server deadline |
| Session revoked/replaced | Request rejected | Clear in-memory personal state and auth flow |

## 10. Mobile architecture и network behavior

### 10.1 Feature structure

~~~text
mobile/lib/features/saved/
  data/
    saved_api.dart
    saved_repository.dart
  domain/
    saved_target.dart
    saved_item.dart
    saved_collection.dart
    saved_operation.dart
  presentation/
    saved_screen.dart
    saved_all_view.dart
    saved_collections_view.dart
    saved_collection_screen.dart
  widgets/
    saved_category_selector.dart
    saved_collection_picker.dart
    saved_empty_state.dart
    saved_network_state.dart
~~~

Фактические имена адаптируются к feature-first структуре проекта. Widgets не вызывают API напрямую.

### 10.2 SavedStateRegistry

Registry:

- хранит `SAVED | UNSAVED | UNKNOWN`;
- хранит `ALLOWED | NOT_SAVEABLE | REMOVE_ONLY | UNKNOWN`;
- хранит server-confirmed `effective_collection_count | UNKNOWN` и обновляет его после collection mutations;
- принимает source DTO eligibility hint только для presentation и никогда не передает его обратно как authorization proof;
- хранит current in-memory operation и applied resource version;
- используется всеми domain cards;
- batch-загружает видимые targets;
- имеет global bounded status cache и не растет пропорционально числу посещенных scopes;
- не интерпретирует timeout/cache miss как UNSAVED;
- уведомляет только подписанные widgets;
- очищается при logout, account switch, revoke и platform emergency lockdown.

### 10.3 In-memory loaded state

- personal pages не записываются в SQLite/shared preferences/files;
- repository хранит bounded LRU загруженных pages только в памяти процесса;
- один global weighted LRU budget действует на весь Saved feature, а не на каждый scope; initial safety cap — 500 lightweight items или 8 MiB DTO/page metadata, whichever comes first, с корректировкой по profiling;
- image memory/disk budget остается ответственностью общего image component и не входит в Saved page budget;
- memory-pressure callback сначала evicts least-recently-used pages/status entries, не меняя canonical state;
- evicted или еще не загруженный scope без сети показывается как unavailable-to-load, а не как empty;
- query/filter/scroll state может сохраняться, пока жив feature/process;
- public image cache управляется общим image component и не хранит Saved membership;
- process death удаляет personal loaded pages, pending operation identity и state;
- cold start всегда загружает canonical state online.

### 10.4 Network lifecycle

- online bootstrap является обязательным;
- уже открытый snapshot не очищается из-за временного network loss;
- writes требуют network request и server confirmation;
- никакого optimistic success;
- unknown result разрешается только в текущем процессе через operation status или same-key retry;
- plain `NOT_FOUND` при живом request context приводит к same-key retry, а не к новой operation;
- operation payload/identity не persist-ятся и после restart не replay-ятся;
- после restart repository выполняет обычный online canonical bootstrap без специального recovery flow;
- request, уже принятый server до process death, ограничен hard commit deadline; последующий pull-to-refresh сходится к canonical state;
- новое устройство загружает server state, старое очищается после revoke detection;
- полностью offline старое устройство не может узнать о remote revoke до network contact; это документированный остаточный риск текущего in-memory UX.

### 10.5 Conflict UX

- duplicate title сохраняет draft и фокусирует field;
- stale rename предлагает server title и сохраненный local draft;
- изменение membership count после confirmation не вызывает повторный prompt: «Удалить везде» относится к current commit state;
- collection delete не reprompt-ится из-за item-count change;
- delayed response не вызывает visual rollback;
- network unknown отличается от confirmed retryable failure;
- generic error не заменяет доступное конкретное действие.

## 11. Content consistency

### 11.1 Projection events

Source events:

- `content.published`;
- `content.updated`;
- `content.unavailable`;
- `content.visibility_changed`;
- `content.deleted`.

Consumer:

- принимает только authenticated/versioned event;
- обновляет только materialized projection;
- игнорирует unknown targets;
- применяет revisions монотонно;
- deny/private event очищает payload атомарно;
- старое событие не восстанавливает visibility;
- reconciliation проверяет bounded known rows.

Tracing `Gateway -> saved-service -> source adapter` включается для всех eligibility-required operations: new save, reactivation, ACTIVE PUT validation, membership expansion, mixed replace и inline create.

### 11.2 Недоступный content

- temporary unavailable: neutral placeholder;
- PUBLIC Activity -> PRIVATE: payload purge и REMOVE_ONLY;
- deleted/restricted: payload-free removable placeholder;
- restored PUBLIC: rehydrate existing ACTIVE relationship.

Online response/event очищает mobile in-memory sensitive projection до следующего render. Перед discard client best-effort evicts известную media reference из общего memory/disk image cache, а source обязан revoke/rotate больше не публичный media URL. Уже загруженный offline snapshot не узнает о transition до network contact; после получения authoritative deny payload projection очищается немедленно. Недоступные приложению OS/network caches остаются документированным platform residual risk.

## 12. Security и privacy

### 12.1 Authorization

- owner только из verified session;
- user ID из body/path не принимается;
- every query tenant-scoped;
- foreign/unknown IDs дают neutral response;
- collection UUID не является authorization;
- ACL/share-token fallback отсутствует;
- Gateway strips spoofed identity headers;
- S2S использует service authentication;
- session generation проверяется на каждом API request;
- operation, прошедшая external RPC, перед final commit повторно проходит bounded auth/session-generation check по подписанному auth contract; revoked generation не может commit-иться.

### 12.2 Platform emergency access policy

Saved не создает собственный control plane, epoch distributor или feature-specific lockdown flag. Он потребляет общую platform policy для аварийной блокировки personal-data endpoints:

- Stage 0 подтверждает существующий Gateway/auth contract; если общей capability нет, она проектируется отдельным platform ADR и переиспользуемым механизмом до rollout Saved;
- Security/SRE включает policy при cross-account exposure, auth bypass или personal-data incident;
- authenticated monotonic platform policy revision независимо enforced в API Gateway и saved-service;
- policy блокирует list, query, detail, status, capabilities и все mutations, имея приоритет над product flags;
- stale/unavailable policy state старше platform TTL приводит к fail-closed в обоих enforcement points;
- final commit проверяет current platform revision/allow state, поэтому ранее принятая `PENDING` operation не может обойти активную блокировку;
- direct/internal saved-service route входит в общий platform rehearsal;
- API возвращает shared `PLATFORM_PERSONAL_DATA_LOCKED` без personal payload;
- online mobile немедленно очищает SavedStateRegistry и loaded personal pages;
- background projection/purge integrity workers и account deletion управляются общей incident policy;
- offline in-memory client узнает о блокировке только при следующем network contact или завершении процесса.

### 12.3 Data protection

- TLS external и S2S;
- PostgreSQL/WAL/backups encrypted;
- personal Saved pages не persist-ятся на device;
- auth tokens хранятся только в platform secure storage;
- Saved operation/request payload и operation identity не persist-ятся на device;
- logout/revoke/account switch очищает in-memory Saved state;
- collection title и normalized key считаются personal data;
- raw query и request bodies не логируются;
- support видит operation/request IDs, coarse states, counters и revisions;
- `saved_operations` rows не содержат title/card/query/request payload;
- no admin impersonation/manual row editing;
- account export включает ACTIVE relationships, collections и memberships;
- account deletion запускает resumable subject purge;
- PITR restore replay-ит deletion ledger до открытия traffic.

### 12.4 Abuse

Все endpoints имеют subject/IP/operation rate limits и owner quotas. Создание UNKNOWN shell дополнительно ограничено лимитом concurrent `PENDING`, global breaker и short TTL.

Privacy-reducing operations получают reserved capacity, но сохраняют hard abuse ceiling. Обычное одиночное действие не получает искусственную задержку. Mutation storm может быть fail-closed отдельным breaker.

## 13. Reliability, performance и observability

### 13.1 SLO

| Операция | Цель без client network |
|---|---|
| Personal API availability | 99.9% в месяц |
| Save/unsave/create/rename p95/p99 | <= 350/750 ms |
| ACTIVITY eligibility RPC p95/p99 | <= 150/300 ms |
| Collection parent delete p95/p99 | <= 350/750 ms |
| Desired set до 20 IDs p95/p99 | <= 350/750 ms |
| Desired set 200 IDs p95/p99 | <= 750/1500 ms |
| List page 30 p95/p99 | <= 300/700 ms |
| Search page 30 p95/p99 | <= 350/800 ms при 10 000 saves |
| Batch status 100 p95/p99 | <= 200/500 ms |
| Operation status p95/p99 | <= 150/400 ms |
| Collection list до 200 с derived cover p95/p99 | <= 350/800 ms |
| Warm in-process Saved reopen p95 | <= 100 ms |
| Cold online bootstrap healthy 4G p95 | <= 2 s end-to-end |
| Projection update lag p95/p99 | <= 60 s / 5 min |
| Activity PRIVATE/deny server purge p95/p99 | <= 2/10 s |
| Ephemeral projection/shell hard purge after expiry | <= 1 h |
| Deleted-collection child cleanup | <= 24 h |
| Inherited platform emergency-policy propagation target/hard | <= 10/30 s |
| Terminal purge after eligibility | <= 24 h hard SLO |
| Confirmed data loss/cross-account exposure | 0 |

`PUBLIC_VISIBILITY_MAX_STALENESS = 30s` применяется только к always-public types. ACTIVITY expansion всегда использует live RPC.

### 13.2 Observability

Metrics:

- operation count/latency/error code, PENDING age и EXPIRED count;
- unknown-result age, operation-status outcome и same-key outcome;
- stale response ignored и canonical refresh;
- list/search latency, match-rank distribution и zero-result rate;
- on-demand projection hydrate/GC/event lag, ephemeral shell/row count/age/purge;
- PRIVATE Activity rejection и impossible-private contract violation;
- collection CRUD, desired-set size и parent delete latency;
- quota rejection/usage drift;
- derived-cover query latency и generic-fallback rate;
- deleted-collection child cleanup age/backlog;
- terminal purge age;
- outbox/inbox backlog;
- DB pool, lock, WAL и replica lag;
- platform emergency-policy revision/propagation age/blocked request count;
- mobile crash, ANR, frames и memory.

Logs:

- structured request/trace/operation IDs;
- route template вместо concrete personal IDs;
- no owner title, target ID, query или body;
- security/data-loss events не скрываются sampling.

Tracing:

- Gateway -> saved-service;
- operation receipt insert/status/expiry transition;
- source adapter span для каждой eligibility-required operation;
- final DB transaction и outbox;
- same-key DB wait/timeout и canonical refresh;
- no high-cardinality user/target labels.

### 13.3 Operations

- liveness проверяет процесс;
- readiness проверяет DB, crypto keys и fresh platform access-policy state;
- outbox/inbox workers имеют bounded retry, backoff и DLQ;
- operation expiry, ephemeral projection GC, standard projection GC, child cleanup, retention и subject purge идут bounded/resumable batches;
- PITR/restore drills обязательны;
- zonal DB failure: RPO 0, RTO <= 15 min;
- regional disaster: RPO <= 5 min, RTO <= 4 h;
- dashboards, alerts и runbooks готовы до external cohort;
- product kill switch не скрывает existing data;
- общая platform emergency policy fail-close enforced в Gateway и saved-service по одному monotonic policy contract;
- destructive-data breaker отдельно останавливает domain mutations, переводит affected PENDING в non-mutating terminal/expiry path, но сохраняет operation status и reads;
- migration использует expand/contract и backward-compatible rollback.

## 14. Аналитика

Минимальные events:

- `saved_item_activated`;
- `saved_item_removed`;
- `saved_profile_entry_clicked`;
- `saved_screen_opened`;
- `saved_category_selected`;
- `saved_search_submitted`;
- `saved_search_zero_result`;
- `saved_result_opened`;
- `saved_primary_action_started`;
- `saved_collection_created`;
- `saved_collection_renamed`;
- `saved_collection_deleted`;
- `saved_collection_item_added`;
- `saved_collection_item_removed`.

Event содержит:

- unique `event_id` и schema version;
- pseudonymous user scope;
- bounded canonical source surface;
- app/platform/version;
- entity type при необходимости;
- operation outcome/latency bucket;
- optional random relationship attribution ID;
- navigation/search attempt IDs;
- match kind/rank bucket без matched text;
- для search только coarse query script `LATIN | CYRILLIC | MIXED | OTHER`, length bucket и token-count bucket, вычисленные без сохранения текста или fingerprint;
- consent/experiment context.

Raw target, collection UUID, collection title и query запрещены.

Zero-result analytics является единственным product gate для будущих typo, transliteration, substring, location filters или дополнительных search capabilities.

## 15. Тестовая стратегия

### 15.1 Domain unit

- unique relationship и membership;
- server `saved_at`;
- reactivation создает новую generation без old memberships;
- category не создает rows;
- atomic desired set и inline create;
- empty desired set не выполняет unsave;
- remove-from-collection не меняет relationship;
- collection delete не меняет relationships;
- one-target global unsave;
- normalized unique collection title;
- simplified Unicode validation принимает emoji/ZWJ и отклоняет controls/bidi;
- PUBLIC eligibility matrix;
- PRIVATE/unavailable допускает только reduction;
- exact/token/prefix rank deterministic;
- multi-field/multi-locale match metadata deterministic;
- locale fallback deterministic;
- expired price/availability projection не отображается как current;
- source RPC с изменившимся canonical ID fail-closed как contract violation;
- quota accounting.

### 15.2 Repository integration

- tenant-safe FK и IDOR-resistant queries;
- concurrent save/save дает одну row;
- operation receipt durable до source RPC, а same identity не запускает второй RPC/intent;
- status `NOT_FOUND` с последующим same-key retry создает либо находит ровно один receipt;
- same idempotency key final transaction дает один terminal result;
- rollback не оставляет partial domain state; `PENDING` либо получает terminal outcome, либо гарантированно EXPIRED после deadline;
- final CAS после deadline/EXPIRED не может commit-ить domain mutation;
- same key/different committed payload отклоняется;
- ACK-loss replay возвращает terminal result;
- delayed old result имеет lower version;
- desired-set races сериализуются без partial state;
- deleted collection desired ID отклоняется под lock;
- collection delete не зависит от concurrent item-count change;
- collection delete/global unsave race соблюдает общий lock order и не deadlock-ится;
- global unsave удаляет все memberships current commit state без membership-version precondition;
- parent DELETED сразу выключает effective memberships;
- generic retention удаляет cleanup-pending child rows не позже 24 часов, сохраняя parent tombstone 14 дней;
- keyset pagination без duplicate при insert/delete;
- search cursor учитывает match rank;
- on-demand projection не создает full catalog mirror;
- first-operation UNKNOWN shell принимает concurrent deny event, а более старый PUBLIC RPC не перезаписывает deny revision;
- invalid-target shell имеет bounded TTL/rate/quota и purge-ится без ACTIVE/PENDING reference;
- first-attempt PUBLIC/deny row без successful relationship остается ephemeral и не получает 14-day retention;
- projection GC не удаляет target с ACTIVE relationship;
- content events не продлевают `gc_candidate_at` orphaned projection;
- GC/save race сериализуется;
- deny event очищает payload;
- authoritative deny очищает Saved projection и best-effort evicts previously referenced image cache entry;
- derived cover соответствует первой карточке `saved_at DESC, id DESC`; empty/non-PUBLIC/no-thumbnail first item дает generic fallback;
- deny первой карточки не делает event fan-out и уже на следующем read дает fallback;
- `organized_at` и `updated_at` изменяются по разным правилам;
- indexes используются на hard-limit dataset.

### 15.3 Contract

- OpenAPI backward compatibility;
- ровно четыре entity types;
- CHECKLIST rejected;
- PRIVATE Activity external error не отличается от missing;
- always-public PRIVATE response fail closed;
- source eligibility hint является presentation-only и forged value не принимается mutation API;
- no batch mutation endpoint;
- `status:batch` является единственным batch read, projection batch route отсутствует;
- list/search/status contracts возвращают per-card `effective_collection_count`, но не aggregate totals;
- search schema не содержит typo/transliteration/location filters;
- list/search response не содержит exact total/category counts;
- normal list поддерживает mutually-exclusive collection/uncollected scopes с owner-neutral errors;
- cursor является AEAD-encrypted keyset token без revision vector/anchor, raw query или открытого subject;
- source projection contract содержит explicit `source_default_locale`;
- assignment принимает один target и optional one `new_collection`;
- collection DELETE не требует item version;
- collection list возвращает bounded максимум 200 элементов без server search/cursor;
- mutation response содержит operation status/deadline/applied versions;
- immutable operation result содержит только coarse refresh scope; optional owner snapshot является отдельным fresh response block;
- owner/session-scoped operation-status GET никогда не replay-ит mutation; plain NOT_FOUND в живом процессе требует same-key retry;
- persisted `PENDING` является bounded receipt; retry state, lease takeover и server scheduler отсутствуют;
- product flags и общая platform emergency access policy имеют разные contracts;
- generic alias table/event отсутствуют; baseline source ID immutable, domain-specific merge требует отдельного ADR;
- unknown source event не materialize-ит projection;
- raw query, target IDs и collection IDs отсутствуют в analytics/log contracts; random operation/trace IDs разрешены.

### 15.4 Mobile

- единый bookmark state на всех surfaces;
- UNKNOWN не превращается в UNSAVED;
- PRIVATE unsaved card без bookmark;
- forged/unknown eligibility hint не расширяет backend access;
- PRIVATE placeholder имеет reduction-only picker;
- immediate online request без delay;
- repeated tap того же target blocked;
- offline action не показывает success;
- confirmed zero collection count позволяет immediate DELETE без preflight; UNKNOWN/non-zero получает fresh target-collections preview;
- in-process ACK loss сходится operation status или same-key retry;
- restart не восстанавливает pending operation, не replay-ит intent и загружает canonical state online;
- cold start offline показывает connection-required;
- hydrated screen после network loss сохраняет loaded cards;
- pagination/search не изображают completeness offline;
- thumbnails отображаются только из existing image cache;
- search exact/token/prefix rank и date tie-break;
- cross-locale search и display fallback;
- duplicate/quota/network errors сохраняют picker draft;
- quota hidden в normal state и видна near-limit/error;
- collection delete не reprompt-ится только из-за count change;
- stale title требует confirmation refresh;
- локальный collection search работает по всем bounded 200 options без network request;
- derived cover первой карточки и fallback не вызывают layout shift;
- platform emergency lockdown очищает personal UI;
- global LRU/memory-pressure eviction не превышает общий budget и не выдает evicted scope за empty;
- scroll/filter/query state сохраняется в живом процессе;
- no share, notes, multi-select, Undo или reorder controls;
- text scale 200%, keyboard и long localization.

### 15.5 E2E

- save каждого включенного PUBLIC type (Attraction, Activity, User) -> «Все» и category;
- guide card и любой foreign profile сохраняются одним USER target;
- self-save и save пользователя, заблокировавшего owner, нейтрально отклоняются;
- ранее сохраненный USER после target-owned block остается removable unavailable placeholder и восстанавливается после unblock;
- relationship-policy outage fail-closed скрывает USER без деградации Attraction/Activity;
- PRIVATE Activity не сохраняется;
- PUBLIC -> PRIVATE -> removable placeholder;
- PRIVATE reduction проходит, expansion fail closed;
- profile «Мой путь» -> Saved;
- ordinary list order by saved date;
- collection list загружает максимум 200 owner-scoped metadata rows, ищет локально и сохраняет порядок/scroll независимо от metadata refresh;
- search order by match rank then saved date;
- inline create collection + membership atomic;
- one card in multiple collections, one row in «Все»;
- existing saved card из All/category/detail открывает «Изменить коллекции» без повторного save;
- collection screen paginates/searches its own cards; bookmark remains global, while remove-from-this-collection is a distinct labeled action;
- remove from one collection preserves save;
- zero-membership card удаляется одним DELETE без dialog/preflight;
- global unsave после «Удалить везде» удаляет все memberships current commit state;
- re-save does not restore memberships;
- delete collection preserves cards in «Все»;
- item count change during delete sheet does not force repeat confirmation;
- изменение N между preview и global unsave не вызывает повторного confirmation;
- title change does force refreshed confirmation;
- empty collection «Перейти ко всем»;
- network loss after load preserves current snapshot only;
- restart offline cannot bootstrap;
- restart online делает обычный canonical bootstrap без operation recovery/replay;
- new-device login revokes old session;
- platform emergency policy blocks reads/writes and clears online client;
- account switch has zero personal state exposure.

### 15.6 Performance/resilience/security

- 10 000 saves, 200 collections, 50 000 memberships;
- desired set 20/200 IDs;
- 5 000-item parent delete without child fan-out;
- deleted-collection child cleanup за 24 часа и parent retention 14 дней в WAL/lock budget;
- worst-case EN/RU/KK exact/token/prefix search;
- source timeout/circuit breaker;
- DB failover;
- NATS outage/redelivery;
- projection GC/save/event races;
- ephemeral shell/deny flood, expiry/purge и global breaker;
- operation status/same-key retry и receipt race;
- collection list 200 rows с indexed derived-cover lookup;
- global LRU memory profile;
- IDOR, mass assignment, forged headers;
- malformed target и tampered/expired/wrong-key AEAD cursor;
- idempotency replay mismatch;
- PENDING crash/deadline/EXPIRED late-commit attempts;
- process restart during PENDING и convergence при следующем canonical refresh;
- PRIVATE expansion forgery;
- body/query/log leakage scan;
- platform emergency-policy propagation, stale policy, direct-service bypass и PENDING final-commit attempts;
- account deletion and backup restore;
- dependency/container/SBOM scans.

## 16. Этапы реализации

### Этап 0. Product и contract gate

- подтверждены scope и terminology;
- подтверждена visibility matrix;
- source teams подписали immutable-ID/eligibility/event contracts; тип со сменой ID имеет отдельный domain ADR до rollout;
- auth team подписала stable session-generation, revoke propagation и final-commit validation contract;
- подтверждены online-only bootstrap и in-process degraded view;
- подтвержден search exact/token/prefix с relevance tiers;
- подтвержден on-demand projection lifecycle;
- утверждены bounded operation journal, in-process status/same-key recovery и AEAD keyset pagination;
- утверждены unique title, atomic inline create и collection delete semantics;
- подтверждена общая platform emergency access policy; при ее отсутствии принят отдельный platform ADR без Saved-specific control plane;
- OpenAPI и threat model reviewed.

Exit:

- нет открытых решений, требующих destructive migration;
- prototype проходит core journeys/accessibility;
- requirement -> invariant -> test -> metric traceability готова.

### Этап 1. Internal foundation

- saved-service skeleton;
- relationships и on-demand projections;
- PENDING/terminal operation journal, expiry CAS, outbox, quota и purge;
- save/unsave/operation-status/item-status/list/capabilities;
- keyset pagination;
- SavedStateRegistry и global in-memory LRU;
- one source adapter;
- integration с общей platform emergency access policy;
- dashboards/runbooks.

Exit:

- concurrent/retry/ACK loss не создают duplicate;
- in-process timeout сходится через status/same-key retry, а server operation не commit-ится после deadline;
- projection materialization/GC безопасны;
- security/repository/load tests проходят;
- capability доступна internal cohort.

### Этап 2. Полный экран

- три production-enabled source adapters: Attraction, Activity и User;
- unsupported и retired entity types отклоняются fail-closed до создания operation;
- profile entry;
- «Все», categories и «Без коллекции»;
- EN/RU/KK exact/token/prefix search;
- relevance rank;
- unavailable lifecycle;
- in-process network degradation;
- localization/accessibility;
- product analytics.

Exit:

- три включенных PUBLIC types проходят E2E, а unsupported types отклоняются fail-closed;
- PRIVATE/deny suites проходят;
- search functional/performance acceptance готов;
- core SLO выдержан;
- zero-result analytics вычисляется без raw query.

### Этап 3. Личные коллекции

- create/read/rename/delete;
- unique normalized title;
- picker и atomic inline create;
- many-to-many memberships;
- reduction-only picker;
- semantic «Удалить везде» flow без повторного prompt при изменении N;
- `organized_at` order;
- bounded collection list с локальным search;
- derived cover первой карточки без persisted cover/repair worker;
- simple parent delete + child cleanup <= 24 h + parent retention purge.

Exit:

- collection actions не удаляют saves;
- 5 000/50 000 limits проходят;
- no partial desired set;
- item-count race не создает needless confirmation;
- title race защищена;
- foreign UUID не обнаруживается;
- UI ясно различает два удаления.

### Этап 4. Hardening и rollout

- expand/contract migration drills;
- load/soak/failover/PITR;
- projection GC и retention purge;
- operation expiry и ephemeral projection GC;
- stale response fencing;
- multilingual search;
- integration rehearsal общей platform emergency access policy;
- accessibility/localization/device reports;
- staged rollout и supported-client cleanup.

## 17. Rollout

### 17.1 Feature flags

- `saved_core`;
- `saved_search`;
- `saved_entity_attraction`;
- `saved_entity_activity`;
- `saved_entity_user`;
- `saved_collections`.

Product flags:

- блокируют discovery/new expansion;
- не скрывают existing owner data;
- не отключают unsave/remove/delete.

Flags server-controlled, sticky по owner и capability внутри rollout cohort и
scoped по environment, supported app build и platform. Cohort вычисляется
детерминированно на сервере; marker store и persisted client identity для
rollout не создаются. Mobile передаёт bounded `X-Client-Platform: android|ios`
и положительный `X-App-Build`; эти значения не являются authorization claim.
Missing/malformed metadata fail-closed только для new expansion и не блокируют
canonical reads/reducing actions.

| Capability state | Поведение |
|---|---|
| `saved_core` off, данных нет | Entry и new save скрыты |
| `saved_core` off, данные есть | Entry, reads и reducing actions доступны; new save запрещен |
| `saved_entity_*` off | Existing cards типа видны и удаляются; new save запрещен |
| `saved_search` off | Saved search route не выполняет query; списки и категории продолжают работать |
| `saved_collections` off | Existing collections читаются, переименовываются и удаляются; create/add запрещены |
| Product flag rollback | Operation status, account export/delete, unsave, remove и terminal collection delete сохраняются |

Platform emergency access policy не является Saved feature flag:

- не sticky;
- имеет высший приоритет;
- monotonic platform revision dual-enforced в Gateway и saved-service;
- блокирует reads/writes и final commit ранее принятой `PENDING` operation во время активной policy;
- не удаляет server data;
- online client очищает personal presentation state.

### 17.2 Cohorts

1. CI и production-like migrations.
2. Internal users.
3. 1% после minimum sample/soak.
4. 5%.
5. 25%.
6. 50%.
7. 100% после SLO, guardrail, support и idempotency/data-integrity review.

### 17.3 Automatic pause

- data loss или cross-account exposure;
- duplicate/invariant violation;
- quota drift;
- API error budget breach;
- deny purge lag;
- impossible PRIVATE for always-public type;
- crash/ANR/jank regression;
- migration/backfill drift;
- DB lock/WAL/replica-lag breach;
- projection GC error;
- overdue ephemeral projection или deleted-child cleanup;
- PENDING после deadline или late commit attempt;
- derived-cover query SLO breach или stale-media response;
- overdue retention purge;
- stale-response regression;
- platform emergency-policy bypass;
- support complaint spike;
- global unsave from collection action.

## 18. Изменения по модулям

| Модуль | Ответственность |
|---|---|
| saved-service/domain | Target, relationship, collection, membership, lifecycle |
| saved-service/app | Save/unsave, in-process operation status semantics, assignment, query, parent delete, projection lifecycle |
| saved-service/repository | PostgreSQL, AEAD keyset query, PENDING/terminal operations, quotas, bounded cleanup |
| saved-service/http | Owner-scoped versioned API, operation status, service-level platform-policy enforcement |
| saved-service/messaging | Known-projection events, outbox и projection reconciliation |
| Gateway/auth | Session generation, trusted headers, route policy и общая emergency access policy |
| Source services | Immutable ID, eligibility, PUBLIC projection, source default locale, lifecycle events |
| Mobile saved feature | All, categories, search, collections, in-memory operations и global LRU |
| Reusable cards | Unified SavedStateRegistry binding |
| Infrastructure | PostgreSQL HA/PITR, NATS, metrics, alerts, secrets |
| CI/CD | Contract, migration, security, accessibility и rollout gates |

## 19. Основные риски и меры

| Риск | Эффект | Мера |
|---|---|---|
| Duplicate relationship | Две карточки в «Все» | Unique owner/immutable target |
| Remove membership делает unsave | Потеря карточки | Разные commands и tests |
| Пользователь не понимает global unsave | Потеря организации | Fresh membership preview + явное «Удалить везде» + одна atomic transaction |
| Collection delete удаляет saves | Потеря карточек | Parent lifecycle invariant |
| Empty collection после failed inline create | Мусор | Одна atomic transaction |
| Duplicate normalized title | Путаница | Partial unique index |
| Stale response откатывает UI | Неверный bookmark | Current operation + monotonic version |
| ACK loss создает duplicate | Непредсказуемость | Durable operation journal + in-process same-key/status recovery |
| Process restart происходит во время unknown operation | Bootstrap может кратко опередить commit уже принятого request | No replay, hard server deadline и convergence на следующем refresh как documented bounded trade-off |
| Client после restart повторяет старый intent | Отмена нового решения | Operation/request identity не persist-ятся и автоматически не replay-ятся |
| Source outage блокирует removal | Нельзя удалить данные | Reduction не зависит от source |
| PRIVATE Activity payload остается | Privacy incident | Atomic projection purge + placeholder |
| Saved-service копирует весь catalog | Storage/coupling | On-demand materialization, unknown events ignored |
| Invalid IDs раздувают UNKNOWN shells | Storage/DoS | Validation + subject/global limits + short TTL/purge |
| GC удаляет active projection | Blank cards | Row lock + NOT EXISTS ACTIVE relationship |
| Content events бессрочно продлевают orphan projection | Storage drift | Независимый `gc_candidate_at` |
| Source неожиданно меняет canonical ID | Потеря связи с карточкой | Immutable-ID contract; тип fail-closed до domain-specific ADR/migration |
| Search слабый result выше exact | Пользователь не находит карточку | Deterministic match ranks |
| Search scope разрастается без evidence | Cost/complexity | Zero-result analytics gate |
| Derived cover расходится с первой карточкой | Непредсказуемая коллекция | Один indexed order `saved_at_snapshot DESC, saved_item_id DESC` для cover и списка |
| Первая карточка стала PRIVATE/unavailable | Утечка старой media | Projection purge + read-time PUBLIC check + generic fallback без fan-out |
| Per-scope mobile cache раздувает RAM | Crash/jank | Один global weighted LRU + memory-pressure eviction |
| Deleted collection хранит child links без recovery | Лишнее хранение personal data | Child cleanup <= 24 h, parent tombstone 14 days |
| Quota постоянно загромождает picker | UX noise | Show only near limit/error |
| Cross-account read incident нельзя остановить | Data exposure | Общая monotonic platform emergency policy, enforced в Gateway и service |
| Offline process не знает remote revoke | Residual exposure до network contact или завершения процесса | No persistent cache; purge at contact/logout/process death |
| Terminal data хранится бессрочно | Privacy/storage drift | 14-day eligibility + 24h purge SLO |

## 20. Definition of Done

### Product и UX

- API распознает только три product target enum values: Attraction, Activity и User;
- PRIVATE Activity не сохраняется;
- formerly PUBLIC Activity становится neutral REMOVE_ONLY placeholder;
- «Все» и categories являются virtual queries;
- normal lists sorted by saved date;
- search sorted by match rank, then saved date;
- collections sorted by `organized_at`;
- collection contents sorted by saved date and owner-scoped independently from metadata;
- collection list search выполняется локально по bounded максимум 200 collections;
- collection cover равна thumbnail первой карточки списка либо generic fallback;
- custom collections private and owner-only;
- inline create atomic;
- duplicate ACTIVE names rejected;
- one card may belong to multiple collections;
- remove-from-collection never unsaves;
- global unsave при N>0 требует один semantic confirmation «Удалить везде» без повторного prompt при изменении N;
- no bulk, notes, sharing, Undo, recovery или reorder;
- profile entry расположен в «Мой путь»;
- cold offline bootstrap blocked;
- hydrated in-process snapshot survives network loss without pretending completeness;
- accessibility/localization/adaptive checks pass.

### Domain и data

- owner immutable;
- tenant-safe FK/unique constraints;
- server timestamps and versions;
- random per-activation attribution ID;
- on-demand projection and safe GC;
- no PRIVATE payload in shared projection;
- source canonical IDs immutable; generic alias subsystem отсутствует;
- durable bounded operation states PENDING/SUCCEEDED/REJECTED/EXPIRED;
- EXPIRED operation cannot commit; final commit respects current platform access policy;
- domain write/result/outbox atomic;
- no persisted request payload или client operation replay;
- effective membership requires ACTIVE child/relationship/parent;
- parent delete immediately disables memberships and preserves saves;
- deleted-collection children purge <= 24 h, parent tombstone retention 14 days;
- `organized_at` separated from technical `updated_at`;
- derived first-card cover uses indexed read-time lookup and immediate privacy fallback without repair state;
- quota counters transaction-safe;
- retention and subject purge verified;
- query plans pass hard-limit tests.

### API и integration

- OpenAPI versioned;
- no public/share/batch mutation routes; `status:batch` is the only bounded batch read;
- trusted owner/session only;
- exact/token/prefix search only;
- no location filters or aggregate total/category list/search counts;
- AEAD-encrypted keyset cursor without revision/anchor protocol;
- operation-status endpoint is owner/session scoped and read-only; reconcile endpoint отсутствует;
- assignment supports optional atomic `new_collection`;
- global DELETE при N>0 после UI-confirmation удаляет current relationship/memberships без `removal:commit` и version choreography;
- collection list bounded максимум 200; отдельный server collection search отсутствует;
- collection delete ignores item-count-only race;
- source eligibility matrix enforced;
- external target errors do not reveal existence;
- error/retry semantics deterministic;
- общая platform emergency policy блокирует every personal endpoint в пределах platform SLO;
- logs/events do not contain personal text/query/target/collection IDs; random operation/trace IDs remain allowed.

### Mobile

- single SavedStateRegistry;
- UNKNOWN never rendered as UNSAVED;
- per-target in-memory lock;
- no artificial request delay;
- no persistent personal Saved page/card cache;
- operation identity/request существуют только в памяти процесса и не replay-ятся после restart;
- unknown result в живом процессе разрешается через operation status или same-key retry;
- server-confirmed zero collection count позволяет immediate DELETE, non-zero/UNKNOWN получает fresh preview;
- one global LRU budget and truthful evicted-scope UX;
- in-process network degradation matches defined UX;
- thumbnails use existing public image cache only;
- reduction-only picker implemented;
- draft/selection preserved on correctable errors;
- quota visible only near limit/error;
- platform emergency policy clears personal state;
- no overflow, hidden CTA or clipped localization;
- baseline frame/memory budgets pass.

### Operations и release

- threat model reviewed;
- Critical/High findings closed;
- dashboards/alerts/runbooks ready;
- DB/NATS/source outage rehearsed;
- operation expiry, shell/projection GC, child cleanup and purge workers bounded/resumable;
- platform emergency-policy integration drill passes;
- PITR/account deletion verified;
- migration/rollback rehearsed;
- unit/integration/contract/mobile/E2E/performance/security suites pass;
- staged rollout completes required sample and soak;
- capability, SLO и support owners назначены.

## 21. Итоговый порядок приоритетов

1. Подписать immutable source ID, auth и общей platform emergency-policy contracts.
2. Реализовать reliable personal save kernel с bounded operation journal/status и on-demand projection.
3. Выпустить «Все», categories и EN/RU/KK relevance-tier search.
4. Добавить личные collections и manual per-card organization.
5. Провести hardening, platform emergency-policy rehearsal и staged rollout.

Итоговая граница остается простой: пользователь сохраняет публичные карточки
Attraction, Activity и профили других пользователей, включая гидов, находит их в одном месте и при желании вручную
организует в строго приватные коллекции. Экскурсии зависят от продукта гида и
его календарной доступности, поэтому не являются SavedTarget.
Уже загруженный экран остается полезным при краткой потере сети, но приложение
не создает persistent offline Saved, operation marker, скрытую mutation queue,
lease/takeover или server retry subsystem. Idempotency и operation status
защищают живой request flow, а после restart приложение просто читает canonical
server state. Любая новая продуктовая сложность требует измеримой
пользовательской пользы и отдельного решения; delivery-команда не расширяет
scope внутри реализации.
