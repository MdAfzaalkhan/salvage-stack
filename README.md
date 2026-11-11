# Salvage Stack — 0.2.0 Dark Glass

Full visual upgrade of the existing Godot 4.7.2 Standard / GDScript / Compatibility project. Package identity remains `com.vanthevor.salvagestack`. The latest 0.1.1 delivered archive was the base; the Mac checkout inspected during this task was still at 0.1.0. It was not overwritten from this restricted session.

## Update your local project

Use the package-level `apply_update.py`, like the Parcel Pilot updater. Close Godot, extract the complete update package anywhere, and run this command **from the extracted update folder**:

```bash
python3 apply_update.py "/Users/mak/Documents/GitHub/salvage-stack"
```

Add `--dry-run` to preview. Do not move just the Python file: it reads the adjacent payload and manifests. It validates known source versions, stops on conflicting local edits, makes a sibling backup, merges version/presentation fields, and preserves local signing/export configuration and player saves. No Downloads path is assumed. See `docs/UPDATING.md`.

Open the updated `project.godot` in Godot 4.7.2. The supplied development APK remains versionCode 3/versionName 0.2.0, with the same development signer as before. The game code/APK is unchanged by this updater-only packaging change.

## What changed visually

- Near-black violet/cool background, one reusable dark Theme, original nine-slice controls and consistent icon assets.
- Original CC0 pixel font for the wordmark and short celebration headings; readable sans serif elsewhere.
- Home has a separate decorative assembly/settling entrance, staggered treasure illumination, slow idle motion and restrained sheen/reflection. Controls are not held behind a mandatory wait. Reduced Motion has short fades and a static hero.
- A responsive 12-sequence grid with saved best recovery/completion/current state. Touch dragging on a card scrolls without selecting it.
- Compact gameplay branding, phase/divider, upcoming chips, dashed placement ghost and guide, numbered recovery indicators and white corner brackets around the selected treasure.
- Smoked glass faces, inset bevel highlights and clipped specular facets for **all existing polygons**. There are no branded studs, fake supporting ledges or 3D conversion.
- Treasures 1/2/3 use amber/magenta/cyan with white backed numbers. Extraction removes collision immediately, then animates a separate non-colliding copy toward the indicator. The effect never increments recovery or freezes the tower.
- Dark contextual tutorial, centred Pause/Settings/results, actual recovery modules on the result shelf, short transitions and held-input reset.
- Explicit readable normal/hover/pressed/hover-pressed/focus/disabled control states. Gameplay actions are dark with white labels/amber icons; primary navigation is amber with dark labels.

## What stays the same

All 12 authored sequences and their unlocked/replayable behaviour, geometry, body materials/mass, 120 Hz physics, gravity, settling thresholds, loss rule, success checks, progression, settings, checkpoint saves, damage recovery, music/effects and unconfigured monetisation boundary remain. Existing saves migrate through the existing 0.1.1 loader. No new currencies, scores, timers, lives, shop, native services or dependencies were introduced.

Touch/mouse: slide in the arena or use the slider, then Drop. Select any gold/coloured treasure body or numbered indicator, then Extract. Numbers are identities, not an order. Keyboard: arrows, Space, 1/2/3, Escape. Retry and checkpoint restoration remain in Pause.

## Evidence and limitations

Read `docs/VERIFICATION.md` and JSON evidence. All automated suites pass: 72 construction/order combinations, nine repeats, 120 checkpoint restorations, tutorial progression/migration, navigation and contrast, grid touch scrolling, modal bounds, Reduced Motion and immediate extraction/collision behaviour at three viewport sizes.

**No actual screenshots or recording could be obtained in this session.** Godot computer access was denied; native graphical launch was unavailable in this environment. Reference-image metadata/OCR were available, but the bitmap download failed, so exact visual matching is not verified. No generated mockups or asset previews have been labelled as running-game evidence. Physical Android testing is also outstanding because ADB's listener is blocked.

`docs/CAPTURE.md` and `tests/capture_screens.gd` provide an actual-render capture path for a graphical Godot session. They are not evidence that those captures have already been produced.

Glass uses lightweight 2D gradients/polygons and texture controls, with no full-screen blur or expensive refraction shader. A simpler path skips sheen/reflections on hosts reporting four or fewer processors; it can also be forced with `salvage/visuals/simple_effects=true` in Project Settings. Phone profiling/readability remains to be checked.

The game is not yet a verified store-ready release. Native monetisation, release signing/AAB, store setup, physical-device QA and final graphical comparison remain. See `docs/EXPORT.md` and `ATTRIBUTION.md`.

## Automated checks

```bash
godot --headless --path . --fixed-fps 120 --script res://tests/verify.gd
SALVAGE_TEST_SAVE_PATH=/tmp/salvage-ui-test.json godot --headless --path . --fixed-fps 120 --script res://tests/ui_verify.gd
SALVAGE_TEST_SAVE_PATH=/tmp/salvage-tutorial-test.json godot --headless --path . --fixed-fps 120 --script res://tests/tutorial_verify.gd
SALVAGE_TEST_SAVE_PATH=/tmp/salvage-glass-test.json godot --headless --path . --fixed-fps 120 --script res://tests/glass_verify.gd
```

Use an isolated save path for tests/capture; regular play continues using `user://salvage-save.json`. Existing Git ignore rules exclude imports, builds, credentials and updater backups.
