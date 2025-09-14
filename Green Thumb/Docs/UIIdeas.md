# UI/UX ideas inspired by references

This note distills design patterns from the images into reusable concepts for Green Thumb.

## Visual language
- Calm green palette with soft mint backgrounds and white surfaces.
- Rounded cards with subtle border and soft shadow.
- Pill actions for primary/secondary tasks (Add, Checkout, Filter, Notify).
- Friendly, rounded typography; heavier titles, regular body.
- Iconography: SF Symbols (leaf, drop, bell, scope, barcode, calendar).

## Components proposed
- Design tokens (colors, spacing, radius, shadows, type).
- GTCard: rounded card with stroke + soft shadow.
- GTPillButton: filled/outline/soft styles.
- GTChecklistRow: task row with circular checkbox, thumbnail, trailing action.
- GTSectionHeader: compact section title + subtitle.

## Screens to style next
- Dashboard: hero card + quick stat cards + today's checklist.
- My Garden: grid of plant cards with progress tags.
- Tasks: segmented Today / Upcoming / Completed with checklist rows.
- Health Log: card-based stats with small charts.
- Scanner: barcode/camera frame (use AVCapture overlay) with soft green laser.
- Calendar: month view with highlighted days + sheet for event details.

## Interaction patterns
- Minimize animations in forms to avoid recursive layout loops; prefer explicit transitions.
- Use objectID/UUID as stable selection ids.
- Present notifications while foreground with a simple banner.

## Implementation notes
- All components here are standalone and safe to drop in any view.
- Prefer adaptive light/dark shades derived from brand greens.
- Keep tokens in one place to enable theme changes later.
