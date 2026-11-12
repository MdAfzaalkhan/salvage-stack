# Verification — 0.2.1

Godot remains **4.7.2.stable.official.ed1daf0bf**, Standard, Compatibility, macOS. No engine/plugin upgrades. Headless checks used 120 Hz physics; the longer suite was rerun with `--fixed-fps 120` to drive the same fixed steps without real-time waiting.

| Automated check | Result |
|---|---|
| Authored placements × all six treasure-removal orders | 72 / 72 wins |
| Representative repeated constructions | 9 / 9 wins |
| Centre-placement probes | 12 sampled outcomes recorded |
| Settled checkpoint restoration suffixes | 120 / 120 wins |
| Duplicate actions, real loss culprit, pause, retry, corrupt-save recovery | Passed |
| Tutorial four stages, simulated touch, migration, Skip/completion persistence | Passed |
| Six button-state contrast checks, menus/results/navigation bounds | Passed |
| Card touch dragging and tapping, modal positioning, audio controls, Reduced Motion | Passed |
| Immediate collision removal, non-colliding extraction copy, no tower freezing | Passed |
| Exact-contour texture-alpha samples | 665,768 / 665,768 match |
| Texture coverage | All 61 materials; all authored shapes and display variants |
| Actual eight-placement towers at 720×1280, 720×1560, 960×1280 | 36 / 36 fit; no per-drop Build zoom on authored routes |
| Render-only framing and transformed touch selection | Passed |
| Android debug export and independent signature/package checks | Passed; version 0.2.1 / code 4 |

`evidence/` contains JSON records. These tests inspect real Godot nodes, image alpha, physics and simulated input. They do not render screenshots and do not establish visual quality or phone readability. The route/order results apply to those sampled arrangements, not every possible construction or cross-device determinism.

Preservation checks compare the previous 0.2.0 source: content, piece-body implementation, saves, audio, commerce and audio buses are byte-identical; Arena before its drawing function is byte-identical. Export settings change only version name/code. No local checkout was overwritten by this session.

## Outstanding

- Requested running screenshots (early build, completed tower, selected extraction and Home), same-size before/after and recording: **not produced**. Native graphical Godot aborts during `_RegisterApplication` / NSApplication initialization; application launch also fails. The Android emulator aborts in its startup/bootstrap path. Capture scripts are provided but are not evidence that captures were made.
- No physical Android device was connected. Android performance, frame pacing, heat, physical safe areas, touch comfort, haptics and audio balance remain untested.
- The approved/current images were visible in this request. Final brightness, reflections, material depth and spacing still need running-screen comparison. No claim of visual parity.
- Android export succeeds and APK verification passes; the engine separately reports it cannot save global editor settings from this restricted session. This does not count as device verification.
- Monetisation configuration, production signing/AAB/store work and iOS device export remain outstanding as before.
