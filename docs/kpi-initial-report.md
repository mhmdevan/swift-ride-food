# KPI Initial Report
Window: Initial internal validation window (CI + local instrumented runs)

## Scope and Data Sources

- Current evidence available in this environment:
  - CI test matrix outputs and artifacts
  - unit/integration instrumentation behavior
  - local package test outcomes
- Full staging telemetry export (Sentry/Crashlytics dashboard snapshots) is not available in this environment.

## KPI Snapshot

| KPI | Target | Current Evidence | Status |
| --- | --- | --- | --- |
| Crash-free sessions | >= 99.8% | Requires production/staging dashboard export | Pending external telemetry |
| Feed Load p95 (Warm) | <= 800ms | Instrumentation implemented (`offers_feed_load_p95_ms`) | Tracking ready |
| Feed Load p95 (Cold) | <= 2.0s | Instrumentation implemented (`offers_feed_load_p95_ms`) | Tracking ready |
| Pagination error rate | < 1% | Metric emitted (`offers_pagination_error_rate`) | Tracking ready |
| Image cache hit ratio | >= 65% | Metric emitted (`offers_feed_cache_hit_ratio`) | Tracking ready |
| XCUITest pass rate | >= 98% | CI jobs configured, awaiting full Xcode runner execution | Pending CI run |
| BG refresh success rate | >= 85% | Events emitted (`started/succeeded/failed`) | Tracking ready |
| Deep-link success routing | >= 99% | Events emitted (`routed/requires_auth/failed/ignored`) | Tracking ready |

## Interpretation

- Telemetry plumbing is now complete and KPI-ready.
- KPI pass/fail numbers require one staging/internal rollout interval with provider dashboards connected.

## Next Data Pull Actions

1. Run CI on full Xcode runner and attach `test-matrix-evidence` + `ios-performance-xcresult`.
2. Export 24h staging snapshots for crash-free, p95, pagination errors, deep-link routing.
3. Update this file with measured values and verdict per KPI.
