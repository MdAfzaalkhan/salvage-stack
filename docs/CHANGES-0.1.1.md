# 0.1.1 — prompt tutorial and readable mobile controls

Implemented the approved four-action contextual tutorial on Shift 1, including Skip, saved completion, first-safe-recovery completion, unordered treasure selection and compact interim build guidance. Existing saves retain their progress and receive the new tutorial flag safely.

Fixed the source of idle button invisibility: the normal text property now uses `font_color`, not the nonexistent `font_normal_color`. Explicit colours cover all button/touch/focus states. Pressed gold was adjusted to maintain the same tested text-contrast floor. New slider/toggle assets are legible without hover.

Gameplay now uses a centred phase strip, bordered ivory prompt, outlined amber bottom action, larger Pause/objective controls and soft shaded piece faces. Geometry and authored solutions are unchanged. No generated concept image is flattened into the game.

The Android APK retains the same package and development signer as 0.1.0. It can update that installation. A separately rebuilt APK signed with another key may require uninstalling first; preserve data before changing signing identity.

Physical Android and rendered visual verification are still outstanding; ads/billing/release setup remain unconfigured.
