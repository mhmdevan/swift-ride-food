# Offers Deep Link Contract

## Supported Routes

1. Custom scheme:
`swiftridefood://offers/{offer_id}`

2. Universal link:
`https://app.swiftridefood.com/offers/{offer_id}`

`offer_id` must be a valid UUID.

## Routing Behavior

1. Authenticated user:
- App routes to catalog and then pushes offer detail.

2. Unauthenticated user:
- Route is stored as pending intent.
- User completes login.
- App resumes to the stored offer detail route.

3. Invalid route:
- No crash.
- Route is rejected with a deterministic failure reason.

## Failure Reasons

- `invalidScheme`
- `invalidHost`
- `invalidPath`
- `invalidOfferIdentifier`

## Telemetry Events

- `offers_deep_link_routed`
- `offers_deep_link_requires_auth`
- `offers_deep_link_failed`
