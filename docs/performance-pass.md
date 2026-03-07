# Performance and Stability Pass

This pass is focused on two checks:

1. Main-thread checker
2. Memory leaks

## Scope

- Critical user flows:
  - Login -> Home
  - Home -> Offers (UIKit)
  - Home -> Map tracking (live updates)
  - Home -> Orders history and create order

## Before Running Instruments

1. Generate project: `./scripts/bootstrap.sh`
2. Build once in Debug for simulator.
3. Clear simulator state for deterministic startup timings when needed.

## Main Thread Checker

1. Open Xcode scheme `SwiftRideFood`.
2. Product -> Scheme -> Edit Scheme -> Diagnostics.
3. Enable Main Thread Checker.
4. Run app and execute all critical flows.
5. Ensure no runtime warnings for UIKit/SwiftUI state updates from background threads.

Exit criteria:
- No checker violations in critical flows.

## Leaks Pass

1. Open Instruments from Xcode (`Product -> Profile`) and choose `Leaks`.
2. Run for at least 3 minutes while repeating:
   - Open/close Offers screen
   - Open/close Map screen
   - Trigger order list refresh and order creation
3. Verify detached view controllers/view models are released.

Exit criteria:
- No persistent leak growth after repeated navigation loops.

## Follow-up Rules

- If a leak is detected:
  - fix smallest safe scope first (retain cycle, captured `self`, observer cleanup)
  - rerun the same scenario before broader refactor
- If a main-thread issue is detected:
  - move heavy work to async/background boundary
  - keep UI state mutations on `@MainActor`
