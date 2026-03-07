# Incident Runbook (Offers + Navigation + Background Refresh)

This runbook defines how to triage and stabilize incidents for current observability scope.

## Severity Levels

| Severity | Definition | Target Response |
| --- | --- | --- |
| P1 | Crash spike or core flow unusable for many users | Immediate (<= 15 min) |
| P2 | Noticeable degradation, partial flow failures, KPI breach | <= 30 min |
| P3 | Minor degradation without user-blocking impact | next business cycle |

## Triage Inputs

1. Crashlytics crash-free sessions and top stack traces.
2. Non-fatal counts for `offers`, `deep_link`, `background_refresh` contexts.
3. RUM latencies and error metrics (`p95`, pagination error rate, cache ratio).
4. Release/feature flag state (GraphQL toggle, catalog UI toggle).

## First 15 Minutes (Minimal Safe Stabilization)

1. Confirm current app version and release window.
2. Check if incident is tied to a recent rollout.
3. If needed, apply immediate mitigation:
   - disable risky flag (`enableGraphQLOffersBackend`) and force REST path
   - keep fallback providers active (no hard dependency on external telemetry SDK state)
4. Publish status update with:
   - detected timestamp
   - impacted flow
   - mitigation applied

## Root-Cause Drilldown

### Deep Link Failures

1. Inspect `offers_deep_link_failed` reason distribution.
2. Validate route parser contract:
   - `swiftridefood://offers/{id}`
   - `https://app.swiftridefood.com/offers/{id}`
3. Confirm auth-resume path works for unauthenticated starts.

### Feed Latency / Pagination Errors

1. Compare warm vs cold p95.
2. Verify cache hit ratio trend.
3. Inspect pagination error rate and backend status codes.
4. Validate recent changes in repository/merge logic.

### Background Refresh Failures

1. Compare `scheduled` vs `started` vs `succeeded/failed` counts.
2. Check deduplicated/skipped rates for misconfigured intervals.
3. Verify on-resume fallback refresh still succeeding.

## Recovery Criteria

Incident can be resolved when:

1. Metrics return to target range for at least 60 minutes.
2. No new critical crash/non-fatal pattern appears.
3. Temporary mitigations are documented and tracked.

## Postmortem Checklist

1. Impact summary (users, duration, KPI delta).
2. Timeline with exact timestamps.
3. Root cause + contributing factors.
4. Permanent fix and tests added.
5. Follow-up tasks with owners and due dates.
