# Bottleneck Analysis (p95 and Error Spikes)

## Method

- Reviewed instrumentation points and execution paths for offers feed, pagination, deep-link, and background refresh.
- Correlated high-risk code paths with current metrics/events.

## Ranked Bottlenecks

1. **Cold feed load dependency chain (network + mapping + image startup)**
- Impact: cold p95 spike and slower first meaningful content.
- Evidence path: `offers_feed_load_p95_ms` (profile=cold).
- Priority fix: keep stale-while-revalidate and improve first paint with prewarmed caches.

2. **Pagination non-progress cursor loops from backend anomalies**
- Impact: repeated requests, wasted bandwidth, UI stalls.
- Mitigation now: cursor non-progress guard + exhausted fallback.
- Evidence path: `offers_pagination_sample`, `offers_pagination_error_rate`.

3. **Stale cache reuse beyond acceptable age**
- Impact: outdated feed content, product trust erosion.
- Mitigation now: maximum stale age invalidation + future-timestamp invalidation.

4. **Background refresh transient network failures**
- Impact: lower refresh success rate, stale resume UX.
- Mitigation now: retry + exponential backoff in refresh pipeline and scheduler backoff.

5. **Deep-link malformed URLs without user feedback**
- Impact: silent failure perception and support burden.
- Mitigation now: deterministic user-facing error state and complete analytics context.

## Improvement Backlog (Priority Ordered)

1. Add persistent first-page disk cache for offers data (not only in-memory).
2. Add server-driven pagination health signal (cursor validity contract).
3. Add p95 alarm auto-link to release SHA for faster rollback decisions.
4. Add query-level CDN cache policy for offer feed endpoints (backend collaboration).
