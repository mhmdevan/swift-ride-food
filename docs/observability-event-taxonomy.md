# Observability Event Taxonomy (v1)

Owner: iOS

This taxonomy is the single source of truth for observability instrumentation.

## Naming Rules

- Prefix by intent: `screen_`, `offers_`, `home_`
- Use snake_case only.
- Keep semantic stability (do not rename active events without migration note).
- Do not include PII in names or parameters.

## Event Dictionary

| Category | Event | Required Parameters | Source |
| --- | --- | --- | --- |
| screen | `screen_home_viewed` | none | `RootView` / `AppCoordinator` |
| screen | `screen_auth_viewed` | none | `RootView` / `AppCoordinator` |
| screen | `screen_orders_viewed` | none | `AppCoordinator` |
| screen | `screen_map_viewed` | none | `AppCoordinator` |
| screen | `screen_offers_feed_viewed` | none | `AppCoordinator` |
| screen | `screen_offer_detail_viewed` | `offer_id` | `AppCoordinator` |
| action | `home_action_selected` | `action` | `HomeViewModel` |
| action | `retry_tapped` | `scope` | feature view models |
| load | `offers_feed_load_sample` | `profile`, `duration_ms`, `outcome`, `item_count` | `OffersPerformanceMonitor` |
| load | `offers_pagination_sample` | `duration_ms`, `outcome`, `appended_item_count` | `OffersPerformanceMonitor` |
| metric | `offers_feed_load_p50_ms` | `profile` | `OffersPerformanceMonitor` |
| metric | `offers_feed_load_p95_ms` | `profile` | `OffersPerformanceMonitor` |
| metric | `offers_feed_cache_hit_ratio` | none | `OffersPerformanceMonitor` |
| metric | `offers_pagination_error_rate` | none | `OffersPerformanceMonitor` |
| deep_link | `offers_deep_link_routed` | `source`, `offer_id` | `AppCoordinator` |
| deep_link | `offers_deep_link_requires_auth` | `source`, `offer_id` | `AppCoordinator` |
| deep_link | `offers_deep_link_failed` | `reason`, `scheme`, `host`, `path_shape` | `AppCoordinator` |
| deep_link | `offers_deep_link_ignored` | `scheme`, `host`, `path_shape` | `AppCoordinator` |
| bg_refresh | `offers_background_refresh_scheduled` | `earliest_begin_epoch` | `OffersBackgroundRefreshManager` |
| bg_refresh | `offers_background_refresh_schedule_failed` | none | `OffersBackgroundRefreshManager` |
| bg_refresh | `offers_feed_refresh_started` | `reason` | `OffersFeedRefreshCoordinator` |
| bg_refresh | `offers_feed_refresh_succeeded` | `reason` | `OffersFeedRefreshCoordinator` |
| bg_refresh | `offers_feed_refresh_failed` | `reason` | `OffersFeedRefreshCoordinator` |
| bg_refresh | `offers_feed_refresh_skipped` | `reason` | `OffersFeedRefreshCoordinator` |
| bg_refresh | `offers_feed_refresh_deduplicated` | `reason` | `OffersFeedRefreshCoordinator` |

## Crash Breadcrumb Policy

- Add breadcrumb at route transitions and background refresh boundaries.
- Include non-sensitive metadata only (`source`, `reason`, `offer_id`, duration bucket/value).
- Use non-fatal reporting for handled failures that still degrade UX.

## PII Guardrails

- Allowed: UUID-like IDs and enum reasons.
- Disallowed: email, phone, addresses, payment info, full token strings.
- For errors, record category and normalized reason; do not log raw request bodies.

## Versioning

- Current taxonomy version: `v1`.
- Breaking change process:
  1. add migration section to this document
  2. keep old + new events for one release window
  3. remove old events after dashboard migration
