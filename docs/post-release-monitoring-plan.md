# Post-Release Monitoring Plan (24h / 72h)

## Objectives

- Detect regressions early after rollout.
- Validate KPI movement against targets.
- Contain blast radius quickly using feature flags and rollback rules.

## 0-24 Hours (Hypercare)

1. Check every 2 hours:
- crash-free sessions
- warm/cold feed p95
- pagination error rate
- deep-link failed ratio
- BG refresh success ratio

2. On any threshold breach:
- open incident thread
- freeze rollout progression
- evaluate immediate mitigation (disable GraphQL variant, revert build)

## 24-72 Hours

1. Check every 6 hours:
- product funnel KPIs (feed open, detail CTR, reorder conversion)
- engineering KPIs trend stability

2. Decide rollout stage progression:
- Stage 1 -> 10% only after 24h stable metrics
- 10% -> 50% only after next 24h stable metrics
- 50% -> 100% only after 72h gate pass

## Ownership and Escalation

- Primary: iOS on-call
- Secondary: QA lead
- Product notification: when KPI trend breaches or rollback is considered

## Exit Criteria

Monitoring cycle is complete when:

1. 72h completed with no unresolved P1/P2 incidents.
2. KPI trend is stable or improving relative to baseline.
3. Final rollout decision is documented.
