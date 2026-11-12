# Salvage Stack — 0.2.1 Material and Framing Update

This is the existing Godot 4.7.2 Standard / GDScript / Compatibility game. No engine, plugin, physics geometry, sequences, save format, tutorial progression or audio changes were made. Package identity remains `com.vanthevor.salvagestack`.

## Apply to the Mac checkout

Close Godot. Extract the entire update ZIP anywhere. From the extracted update folder containing `apply_update.py`, run:

```bash
python3 apply_update.py "/Users/mak/Documents/GitHub/salvage-stack"
```

Optional preview: append `--dry-run`. Keep the script, payload and manifests together. No Downloads path or source-selection prompt is assumed. The updater validates payload hashes, stops on conflicting local source edits, backs up replaced files beside the destination, preserves saves/Git/caches and merges version fields into the owner's export configuration. See `docs/UPDATING.md`.

Open the updated `project.godot` in the installed Godot 4.7.2 and press F5. The package's `payload/` is also a standalone source project. The debug arm64 APK is `payload/builds/SalvageStack-debug.apk`, versionName 0.2.1 / versionCode 4, signed with the existing development signer. No production signing key is included.

## Changes

- 61 original, exact-contour PNG materials at three texels per world unit. The source baker computes polygon-union masks, bevel distance/normals, specular edges, darker side/lower facets and narrow internal refractions. Compound seams and the old broad diagonal stripe are removed. Bevels stay inside collision outlines.
- Substantial amber, magenta and cyan fronts with white numbers directly on the jewel face. No small framed number badge. Gameplay, previews, objective markers, Home, cards and results share the same materials.
- Compact header, 54-pixel visible Pause surface inside an 88×72 target, smaller upcoming strip, contextual instructions and a centred short placement rail. No generic construction/recovery slogan in gameplay.
- Rendering-only viewport transform. The Build frame is stable across authored placements; Extract gets one closer frame that remains through removals. An outlier taller tower can expand the envelope without moving, resizing, freezing or otherwise changing physics bodies. Touch coordinates and recovery effects use the inverse/forward render transform.
- A darker exact-contour foundation, quieter markings under the real y=74 loss plane, short selected-module flash and the existing non-colliding recovery flight. Reduced Motion skips the selection flash and retains existing simplified motion.

## Verification and limitations

Automated checks passed: 93 sampled physics routes (72 authored construction/order wins, nine repeats and 12 centre-strategy probes), 120 checkpoint restoration suffixes, tutorial/migration, navigation, button-state contrast, pause/retry/results, simulated touch, card scrolling, audio settings and Reduced Motion. A new check validates 665,768 texture-alpha samples and 36 actual constructed tower layouts (12 sequences at three sizes). See `docs/VERIFICATION.md` and `evidence/`.

**Actual running-game screenshots, recording and same-size before/after comparison were not obtainable.** Native Godot aborts during macOS application registration; the Android emulator also aborts at startup in this session. No physical Android device is connected. These are open verification deliverables, and no asset sheet or concept art is offered as implementation evidence. The approved reference and current screenshot were visible in this request, but final rendered material quality cannot be judged without a working graphical run. Visual parity is not claimed.

`docs/CAPTURE.md` supplies the real-game capture command. It produces Home, tutorial, early build, all-eight-piece tower, selected extraction, menus and real results without changing the regular save. Phone safe areas, practical touch comfort, effects performance, haptics and audible balance still need physical-device testing.

See `ATTRIBUTION.md` for original artwork/font/audio provenance and `docs/EXPORT.md` for export setup and remaining release requirements. This remains a development build with unconfigured monetisation and no claim of store readiness.
