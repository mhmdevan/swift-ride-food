# Changelog

All notable changes to this project are documented in this file.

## [0.17.0]

### Added

- Reliability hardening for offers flow:
  - cache invalidation safeguards for over-stale and future-skewed entries
  - pagination race protection and cursor non-progress handling
  - deep-link ignored telemetry and user-facing failed-link fallback state
  - background refresh retry/backoff policy with outcome-aware scheduling
  - URL log sanitizer for sensitive query keys (`token`, `password`, `email`, etc.)
- Extended automated coverage for:
  - cache invalidation edge cases
  - pagination race/non-progress cases
  - deep-link telemetry paths
  - network log sanitization
  - background refresh retry/backoff behavior
- CI evidence artifact generation for test matrix results.

### Changed

- `SwiftRideFoodApp` now schedules background refresh based on actual refresh outcome.
- `OffersBackgroundRefreshManager` now applies exponential backoff after failures and resets after success.
- `OffersFeedRefreshCoordinator` retries transient background failures before terminal failure.
- `OffersViewModel` blocks pagination while first-page refresh is in-flight to avoid stale append races.
- `scripts/test-packages.sh` supports optional clean mode (`CLEAN_PACKAGES=1`) and one-time clean retry on failure.

## [0.16.0]

### Added

- Observability foundations:
  - unified event taxonomy constants (`ObservabilityEventName`)
  - `RUMMonitoring` abstraction with in-memory/no-op implementations
  - app-level Sentry RUM adapter (`SentryRUMMonitor`) with safe fallback semantics
- `OffersPerformanceMonitor` actor for feed/pagination KPI instrumentation:
  - feed p50/p95 (warm/cold)
  - cache hit ratio
  - pagination error rate
- Additional UI quality coverage:
  - multiple critical XCUITest flows
  - dedicated performance test suite (`XCTApplicationLaunchMetric`, `XCTClockMetric`)
  - CI performance job and xcresult artifact upload
- Operational documentation for observability, dashboards/alerts, runbook, and accessibility walkthrough.

### Changed

- `AppRuntimeIntegrations` now resolves and configures RUM monitor at startup.
- `AppDependencyContainer` now wires offers feed/pagination measurements into central KPI monitoring.
- Deep-link and background-refresh telemetry now uses shared event taxonomy with richer breadcrumb coverage.
- Accessibility labels/traits/hints and Dynamic Type support improved across core screens.

## [0.15.0]

### Added

- Deep-link contracts and parser/router support for:
  - `swiftridefood://offers/{id}`
  - `https://app.swiftridefood.com/offers/{id}`
- Auth-aware pending-route resume flow after login.
- Offer detail route destination (`AppRoute.offerDetail`) and detail screen entry.
- Background feed refresh pipeline:
  - `OffersFeedRefreshCoordinator` for page-1 prefetch
  - idempotent interval gate and in-flight deduplication
  - `OffersBackgroundRefreshManager` scheduling abstraction
- App-link configuration artifacts:
  - URL scheme registration
  - BG refresh task identifier
  - associated domains entitlement
  - AASA example document
- New routing and background scheduling tests.

### Changed

- `RootView` now handles offers deep links first, preserves auth-token fallback parsing, resumes pending routes after authentication, and triggers on-resume offers refresh fallback.
- `AppDependencyContainer` reuses shared offers repositories and exposes background/on-resume refresh entry points.
- `SwiftRideFoodApp` now schedules and handles app refresh background tasks for offers prewarming.

## [0.14.1]

### Added

- Runtime integration factory (`AppRuntimeIntegrations`) with deterministic fallback providers.
- `FirebaseAnalyticsTracker` implementation in `Analytics`.
- Notification content mutator seam in `PushNotifications` for extension testability.
- New tests for runtime integration selection/bootstrap behavior, notification content mutation, and catalog UI flow.

### Changed

- `AppDependencyContainer` now resolves default analytics/crash/remote-config/messaging providers through centralized runtime integrations.
- `FirebaseBootstrapper.configureIfNeeded()` now returns `Bool`, guards missing config safely, and supports idempotent behavior.
- `PushNotificationCoordinator` no longer defaults to fallback messaging implicitly.
- `PushNotificationService` now requires explicit messaging client injection.
- Home screen copy updated to remove temporary language.

## [0.14.0]

### Added

- CI/CD and release automation:
  - CI stages for lint/build/test
  - Fastlane lanes for lint/build/tests/archive/build-number/TestFlight
  - manual release workflow for archive + optional TestFlight upload
- Performance and UX improvements:
  - catalog image cache pipeline with in-flight request deduplication
  - explicit empty state handling for catalog
  - performance-pass checklist document
- Portfolio packaging updates:
  - README architecture/tech/KPI/demo/trade-off structure
  - media folder structure and reference assets
  - detailed demo script

### Changed

- README reorganized for faster system understanding and run discoverability.
