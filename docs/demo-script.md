# 2-Minute Demo Script

This script is optimized for interview time-boxing. Keep each step tight and demonstrate one concrete engineering point per section.

## 0:00 to 0:15 - Product Framing

- Open app launch screen.
- Explain: "This is one product combining food ordering and taxi-like live tracking, built in modular SPM architecture."

## 0:15 to 0:35 - Authentication

- Show login screen (`FeaturesAuth`).
- Enter test credentials and sign in.
- Mention:
  - keychain token persistence
  - biometric unlock support
  - deep link token ingestion route (`myapp://login?token=...`)

## 0:35 to 0:55 - Navigation and Feature Flags

- Land on Home (`FeaturesHome`).
- Explain coordinator-based navigation and DI container wiring.
- Mention runtime feature-flag refresh controlling destinations without rebuild.

## 0:55 to 1:15 - Orders and Offline Data

- Open Orders screen (`FeaturesOrders`).
- Create an order, verify immediate UI update.
- Mention:
  - repository pattern (`Data` package)
  - local-first sync policy via Core Data
  - loading/empty/error state handling

## 1:15 to 1:35 - Live Tracking

- Open Map (`FeaturesMap`).
- Show live order status and driver location updates.
- Mention:
  - async event stream (`AsyncThrowingStream`)
  - permission state handling and route rendering
  - non-fatal logging and global error flow

## 1:35 to 1:50 - UIKit Screen

- Open Offers (`FeaturesCatalogUIKit`).
- Highlight:
  - compositional layout
  - diffable data source
  - image cache pipeline (loader + cache + de-dup)

## 1:50 to 2:00 - Quality and Release

- Show CI/release files in repo.
- Mention:
  - lint/build/test workflows
  - Fastlane archive/TestFlight lanes
  - automated tests (unit + UI)

## Demo Backup Plan

If simulator/network behavior is unstable during demo:

1. Show test files proving behavior (`MapTrackingViewModelTests`, `OrdersViewModelTests`, UI tests).
2. Show architecture and tech map in `README.md`.
3. Show release workflow + Fastlane lanes for delivery readiness.
