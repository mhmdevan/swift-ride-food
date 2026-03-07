# Accessibility Walkthrough (Offers Flow)

This checklist validates Dynamic Type and VoiceOver behavior for the core offers flow.

## Dynamic Type

1. On Simulator: Settings -> Accessibility -> Display & Text Size -> Larger Text.
2. Set text size to the largest accessibility category.
3. Run app and verify:
   - Home title/search/action buttons remain visible and tappable.
   - Offers list cards do not clip title/price content.
   - Orders form labels and buttons stay readable.

Expected result:

- No truncated critical text without fallback.
- Tappable controls remain reachable.

## VoiceOver Navigation

1. Enable VoiceOver in Simulator.
2. Navigate:
   - Auth screen
   - Home screen actions
   - Orders list/create flow
   - Catalog screen states (`loading`, `error`, `empty`, `success`)
3. Confirm key elements announce meaningful labels/hints.

Expected result:

- Header elements use header trait where applicable.
- Action controls expose clear hints.
- Collection/list cells provide concise summaries.

## Critical Accessibility IDs

- `email_input`, `password_input`, `sign_in_button`
- `home_title`, `home_search_input`, `home_action_catalog`
- `orders_list`, `create_order_title_input`, `orders_refresh_button`
- `offers_collection_view`, `offers_state_message`, `offers_retry_button`

## Regression Policy

Any new screen/major component must include:

1. Accessibility identifier for at least one stable anchor element.
2. Meaningful accessibility label.
3. Hint for non-obvious actions.
