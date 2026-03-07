# Media Capture Guide

This folder contains reference assets that keep README image links stable.
Replace reference assets with real screenshots/GIFs using the same filenames.

## Required Files

- `01-login-screen.svg` -> replace with login screen capture
- `02-home-screen.svg` -> replace with home screen capture
- `03-orders-screen.svg` -> replace with orders screen capture
- `04-map-screen.svg` -> replace with map tracking screen capture
- `05-catalog-screen.svg` -> replace with UIKit offers screen capture
- `06-critical-flow-gif.svg` -> replace with a real GIF of critical flow (`.gif` recommended)

## Recommended Capture Settings

- Device: iPhone 15
- iOS: latest simulator runtime used by CI
- Appearance: light mode
- Dynamic Type: default
- Locale: English

## Critical Flow GIF Sequence

1. Login
2. Open Orders
3. Create order
4. Return Home
5. Open Map and wait for live status

## Quality Checklist

- No debug overlays visible
- Stable and readable typography
- Loading/error/empty states represented at least once across captures
- Accessibility labels remain set on critical controls
