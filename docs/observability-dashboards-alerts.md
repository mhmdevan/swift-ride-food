# Observability Dashboards and Alerts

This document defines the operational dashboards and alert rules.

## Dashboard 1: Product Funnel (Offers)

Widgets:

1. Feed open rate: `screen_offers_feed_viewed / active_sessions`
2. Card-to-detail CTR: `screen_offer_detail_viewed / screen_offers_feed_viewed`
3. Reorder conversion proxy (current scope): `orders_created_from_offers / screen_offer_detail_viewed`

Primary use:

- Validate feature adoption and navigation quality after rollout changes.

## Dashboard 2: Engineering Reliability

Widgets:

1. Crash-free sessions (Crashlytics)
2. Non-fatal error trend by category (`offers`, `deep_link`, `background_refresh`)
3. Deep-link success ratio:
   - success = `offers_deep_link_routed + offers_deep_link_requires_auth`
   - failure = `offers_deep_link_failed`
   - ignored = `offers_deep_link_ignored` (tracked separately, excluded from success/failure SLA)
4. BG refresh success ratio:
   - success = `offers_feed_refresh_succeeded`
   - failure = `offers_feed_refresh_failed`

Primary use:

- Early detection of regressions after release/promotions.

## Dashboard 3: Performance and Cache Efficiency

Widgets:

1. Feed load p50 warm (`offers_feed_load_p50_ms`, profile=warm)
2. Feed load p95 warm (`offers_feed_load_p95_ms`, profile=warm)
3. Feed load p95 cold (`offers_feed_load_p95_ms`, profile=cold)
4. Cache hit ratio (`offers_feed_cache_hit_ratio`)
5. Pagination error rate (`offers_pagination_error_rate`)

Primary use:

- Confirm KPI compliance and detect latency regressions.

## Alert Rules

| Alert | Condition | Threshold | Window | Severity | Action |
| --- | --- | --- | --- | --- | --- |
| Crash-free drop | crash-free sessions | < 99.8% | 30 min | P1 | Open incident + rollback assessment |
| Warm p95 regression | `offers_feed_load_p95_ms` (warm) | > 800ms | 15 min | P2 | Check network + cache + recent deploy |
| Cold p95 regression | `offers_feed_load_p95_ms` (cold) | > 2000ms | 15 min | P2 | Check API latency + first-load path |
| Pagination instability | `offers_pagination_error_rate` | >= 1% | 30 min | P2 | Inspect backend errors + retry path |
| BG refresh failures | failed/success ratio | > 15% failed | 60 min | P2 | Verify scheduler health + rate limits |
| Deep-link routing failures | failure ratio | > 1% | 30 min | P2 | Check parser contract + app links config |

## Routing and Escalation

- P1 -> on-call engineer immediately.
- P2 -> on-call engineer within 30 minutes.
- Repeated P2 for > 2 hours -> escalate to P1 until stabilized.

## CI Reporting Linkage

- CI uploads `PerformanceTests.xcresult` on every run (`ios-performance` job).
- Release gate requires CI green on:
  - lint
  - package tests
  - iOS tests
  - iOS performance job
