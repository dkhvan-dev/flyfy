# FlyFy Sticker Platform Design

Date: 2026-05-10
Status: Approved for implementation planning

## Summary

FlyFy will ship a production-grade official sticker platform, not a local-only asset bundle in the mobile app. The platform provides original FlyFy animated sticker packs grouped like Telegram, available to all users through a remote-managed catalog. Telegram's official sticker formats and UX patterns can inspire the experience, but FlyFy must not copy Telegram official stickers or third-party sticker artwork without explicit rights.

The selected mobile UX is a Telegram-like bottom sticker picker inside chat: a sticker button opens a bottom panel with pack tabs, recent stickers, grouped grids, previews, loading states, and one-tap sending.

## Goals

- Provide official FlyFy sticker packs to every user by default.
- Keep sticker catalog management server-driven so new packs can be published without app releases.
- Support animated stickers with static fallbacks for reliability and accessibility.
- Use existing FlyFy architecture boundaries: sticker-service owns sticker metadata and availability, file-manager-service owns binary assets, chat-service validates sticker send operations.
- Keep the mobile chat flow fast on poor networks through lazy loading, caching, skeleton states, and graceful fallback rendering.
- Prepare for future admin publishing, moderation, localization, analytics, and user-created packs without overloading the first implementation.

## Non-Goals

- Do not scrape, clone, bundle, proxy, or redistribute Telegram official sticker assets.
- Do not depend on Telegram APIs at runtime for FlyFy stickers.
- Do not store sticker binaries directly in Flutter source as the primary catalog mechanism.
- Do not add premium or paid sticker monetization in the first production slice.
- Do not let frontend-only visibility rules decide whether a sticker can be sent.

## Legal And Brand Decision

Official FlyFy stickers must be original or properly licensed. Telegram documentation describes open sticker creation and formats, but it does not grant FlyFy rights to redistribute Telegram official artwork. FlyFy can use similar interaction patterns, technical constraints, and visual quality standards while creating its own brand-safe catalog.

References:

- https://core.telegram.org/stickers
- https://core.telegram.org/api/stickers
- https://core.telegram.org/import-stickers

## Product Experience

The sticker picker appears from the chat composer as a bottom panel.

Core states:

- Recent: first tab, populated by stickers the user has sent recently.
- Official packs: horizontal tabs with pack thumbnail, title, and optional unread/new marker.
- Grid: lazy-loaded sticker thumbnails with animation on hover/press or when visible.
- Preview: long press opens a larger preview with pack name and send action.
- Search: searches sticker title, emoji aliases, keywords, pack name, and localized tags.
- Empty: friendly message when no recent stickers exist or search has no results.
- Loading: skeleton cells and disabled send action until sticker metadata is ready.
- Error: retry affordance when catalog or asset loading fails.

Default official pack groups:

- Travel
- Emotions
- Food
- Weather
- Transport
- Planning
- Guides
- Local Culture
- Bookings
- Safety
- Celebrations
- Seasonal

Each group can contain multiple packs. Each pack should target 16-32 stickers. The first production rollout can publish fewer packs if asset production is incomplete, but the data model and UX must support the full catalog shape from day one.

## Architecture

### sticker-service

Owns sticker domain metadata:

- sticker packs
- stickers
- pack groups
- ordering
- public availability
- official flag
- status and version
- localized title and description
- emoji aliases and search keywords
- asset references
- thumbnail and fallback references

The service exposes public catalog endpoints for mobile and internal validation endpoints for chat-service.

### file-manager-service

Owns binary files:

- animation file
- static fallback
- pack thumbnail
- optional preview thumbnail

Sticker-service stores only file references and content metadata. File-manager-service enforces upload, ownership, binding, scanning, size limits, MIME type validation, and download URL generation.

### chat-service

Owns sending and storing chat messages. When a user sends a sticker, chat-service validates the sticker through sticker-service before persisting the message. The stored message payload should include stable sticker identifiers and enough display metadata for clients to render a previously sent sticker even if the catalog later changes.

### mobile Flutter app

The app consumes the sticker catalog through the existing networking/provider patterns. Widgets do not call APIs directly. The sticker picker receives state from a provider/use-case layer, sends sticker commands through chat provider flow, and caches remote assets locally.

## Data Model

Conceptual entities:

- StickerGroup: id, slug, localized title, display order, status.
- StickerPack: id, group_id, slug, localized title, localized description, official flag, visibility, status, version, display order, thumbnail_file_id, published_at.
- Sticker: id, pack_id, slug, emoji aliases, localized keywords, status, display order, animation_file_id, fallback_file_id, preview_file_id, content_type, width, height, duration_ms, size_bytes, checksum.
- UserStickerState: user_id, sticker_id, last_used_at, usage_count, favorite flag.

Required constraints:

- Public official packs are readable by all authenticated users.
- Only active stickers from active visible packs can be sent.
- Sticker slugs are unique within a pack.
- Pack slugs are stable and unique.
- Asset files must be bound to sticker-service domain entities.
- Published assets are immutable by default; replacements create a new sticker version.

## API Surface

Public mobile endpoints:

- List official sticker groups and active packs.
- List stickers in a pack with pagination or version-based sync.
- Search stickers across official catalog.
- List and update recent stickers for the current user.
- Get catalog version or delta metadata for client cache invalidation.

Internal endpoints:

- Validate sticker send by sticker_id, requester user_id, and conversation context.
- Resolve sticker metadata for chat-service persistence.

Admin endpoints, later exposed through admin-platform:

- Create and edit group.
- Create and edit pack.
- Upload and bind sticker assets.
- Validate asset technical requirements.
- Preview pack.
- Publish, unpublish, reorder, and archive.
- View audit log and validation failures.

## Asset Pipeline

Preferred production formats:

- Animated primary: Lottie-compatible JSON/TGS or WEBM VP9, selected after validating Flutter rendering reliability across iOS and Android.
- Static fallback: PNG or WebP with transparent background.
- Thumbnail: optimized static image for pack tabs and loading placeholders.

Validation rules:

- Maximum duration: 3 seconds.
- Looped animation.
- No audio.
- Transparent background where format supports it.
- Bounded dimensions appropriate for chat rendering.
- Strict content type allowlist.
- File size limits per format.
- Checksum stored for deduplication and cache integrity.

If both Lottie/TGS and WEBM are supported later, the catalog should advertise available renditions and let the client choose the best supported asset.

## Mobile Implementation Details

The chat composer gets a sticker icon. Tapping it opens the bottom picker.

State ownership:

- StickerCatalogProvider owns catalog loading, version cache, search, and pack selection.
- ChatProvider owns sending a sticker message through existing send flow.
- Recent stickers can be maintained locally for instant UI and synced to backend for cross-device continuity.

Rendering:

- Lazy grid rendering.
- In-memory and disk asset cache.
- Static fallback when animation fails or reduce-motion mode is active.
- Accessible labels based on localized title and emoji aliases.
- Stable cell dimensions to avoid layout shifts.

Failure behavior:

- If catalog load fails, show retry and keep composer usable.
- If animation load fails, render fallback asset.
- If validation fails on send, show safe localized error and refresh catalog metadata.
- If user is offline, allow browsing cached official stickers but block sending with a clear retry state unless chat offline queue supports sticker messages.

## Security And Abuse Controls

- Backend validates every sticker send.
- User id is taken from auth context, never request body.
- Only active public stickers are available to regular users.
- Admin publish actions require explicit role checks.
- Every admin mutation is audited.
- Uploads require MIME, extension, size, duration, dimension, and checksum validation.
- Download URLs must be time-limited if assets are private behind file-manager-service.
- Logs must not include signed download URLs or sensitive auth metadata.
- Search endpoints should be rate limited and paginated.

## Observability

Metrics:

- catalog load latency
- sticker send success/failure count
- asset render fallback rate
- search latency and zero-result rate
- validation failure reasons
- admin publish failures

Logs:

- request id
- pack id and sticker id
- failure code
- no signed URLs
- no PII beyond required user id in protected service logs

Tracing:

- mobile API request to sticker-service
- chat-service sticker validation call
- file-manager download URL generation

## Testing Strategy

Backend:

- Domain tests for pack visibility, status transitions, versioning, and send validation.
- Repository tests for constraints, ordering, pagination, and search.
- HTTP handler tests for auth, validation errors, pagination, and safe responses.
- File upload validation tests for disallowed formats and oversized files.
- Contract tests between chat-service and sticker-service validation endpoint.

Mobile:

- Provider tests for catalog load, cache refresh, search, recent stickers, and error states.
- Widget tests for picker tabs, grid, empty state, retry, preview, and send action.
- Golden or screenshot tests for compact and large screens.
- Integration test for opening picker, selecting a sticker, and sending a message.

Admin:

- Permission tests for publish/unpublish actions.
- Audit log tests for every mutation.
- Validation tests for asset pipeline failures.

## Rollout Plan

1. Backend catalog foundation in sticker-service.
2. Seed original official FlyFy sticker groups, packs, and generated placeholder-safe assets for development.
3. Mobile picker UI integrated into chat with remote catalog and fallback rendering.
4. Chat send validation and message payload persistence.
5. Recent stickers and cache invalidation.
6. Admin publishing workflow in admin-platform.
7. Replace development placeholder assets with final original or licensed production artwork.
8. Observability dashboards and rate limits before public release.

## Acceptance Criteria

- All authenticated users can browse active official FlyFy sticker packs in chat.
- Sticker picker behaves like the approved Telegram-like bottom picker.
- A user can send an active official sticker, and recipients see the sticker message.
- Backend rejects inactive, missing, private, or malformed sticker sends.
- Mobile handles loading, empty, error, offline, animation failure, and reduce-motion states.
- New official packs can be added server-side without a mobile app release.
- No Telegram official or third-party sticker artwork is bundled, copied, or redistributed without explicit rights.
- Admin actions for production catalog changes are role-protected and audited.

## Decisions

- The first production architecture is remote-managed, not app-bundled.
- Sticker artwork is original FlyFy-owned or explicitly licensed.
- The chat UX uses the Telegram-like bottom picker.
- Official public packs are available to all users by default.
- Static fallbacks are required for every animated sticker.
- Backend validation is mandatory for every sticker send.
