# Apply updates using the Parcel Pilot workflow

1. Close Godot and stop editing the target project.
2. Extract the whole `SalvageStack-0.2.0-update` package anywhere convenient. Keep `apply_update.py`, `payload/` and all three manifest files together.
3. In Terminal, open that extracted folder and run:

```bash
python3 apply_update.py "/Users/mak/Documents/GitHub/salvage-stack" --dry-run
python3 apply_update.py "/Users/mak/Documents/GitHub/salvage-stack"
```

The script lives in the **update package**; the argument is your **existing local game folder**. There is no source-selection prompt, no Downloads assumption and no need to copy the script into the game project.

It supports the supplied 0.1.0/0.1.1/0.2.0 source baselines. All payload hashes and conflicts are validated before any target write. Recognised files are replaced; unknown local edits stop the entire update. Extra files, `.git`, `.godot`, local save data and credentials are retained. Generated `.uid`/`.import` files are not overwritten by the manifest. There are no obsolete-file removals in this package.

`project.godot` and export presets are merged rather than overwritten: only the game version, initial dark background, absent simple-effects default and Android/iOS version fields change. Owner signing keys/passwords, app identifiers, native templates, permissions, export paths, unrelated settings and plugins remain. Higher owner build counters are preserved/bumped once; repeating the same update is a no-op.

A sibling backup such as `salvage-stack-backup-YYYYMMDD-HHMMSS-...` is created next to the game folder. It contains the previous versions of replaced files plus `restore_manifest.json`. Ordinary write failures roll back completed changes. Keep the backup until you have checked the update. A force-kill or power loss can still interrupt a multi-file update.

Reopen Godot and let changed assets import. No engine/plugin upgrade or network connection is required. The game save is not reset and the supplied APK is not installed automatically.

The older `update_salvage_stack.py` may remain in your existing game folder for compatibility. Use `apply_update.py` from this package for the Parcel Pilot-style workflow. `payload/` contains the full source snapshot for inspection, but the script applies only manifest files and the documented configuration merges.
