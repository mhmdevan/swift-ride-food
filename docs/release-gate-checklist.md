# Release Gate Checklist (Go / No-Go)

## Gate Inputs

| Gate | Criteria | Owner |
| --- | --- | --- |
| Test Matrix | CI jobs green for lint, package-tests, ios-build, ios-tests, ios-performance | iOS + QA |
| KPI Readiness | KPI telemetry emitted and dashboard widgets configured | iOS + Product |
| Security | Security checklist has no open critical item | iOS |
| Stability | No P1/P2 unresolved incident in staging during validation window | iOS + QA |
| Release Artifacts | Archive workflow successful | iOS/DevOps |

## Decision Rules

- **Go** when all gates pass and no unresolved blocker.
- **Conditional Go** only with explicit documented risk and rollback owner.
- **No-Go** if any P0/P1 gate fails.

## Current Status Template

| Gate | Status | Evidence Link |
| --- | --- | --- |
| Test Matrix | Pending CI run | `test-matrix-evidence` artifact |
| KPI Readiness | In Progress | `docs/kpi-initial-report.md` |
| Security | Pass | `docs/security-review-checklist.md` |
| Stability | Pending staging window | incident board |
| Release Artifacts | Pending run | Release workflow artifact |

## Rollback Conditions

Trigger rollback if any occurs after rollout:

1. Crash-free sessions < 99.8% for 30+ minutes.
2. Warm feed p95 > 800ms for 15+ minutes with confirmed regression.
3. Deep-link failure rate > 1% sustained for 30+ minutes.
