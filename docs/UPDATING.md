# Apply the update

Close Godot and extract the full ZIP to a separate folder anywhere. In the extracted update folder containing `apply_update.py`, run:

```bash
python3 apply_update.py "/Users/mak/Documents/GitHub/salvage-stack"
```

Append `--dry-run` for validation without writes. This is the existing Parcel Pilot-style updater workflow. Keep `apply_update.py`, `payload/`, `payload_manifest.json`, `baseline_manifest.json` and `remove_manifest.json` together. Run against the existing game checkout, not against `payload/`; do not copy `payload/` over the checkout before running the updater.

The destination is the explicit argument. No Downloads directory is assumed. The script checks incoming and installed hashes, stops before writes if local files conflict, and creates a sibling `salvage-stack-backup-...` folder before replacing source. It rolls back ordinary write failures. Keep the backup for recovery after power loss or process termination.

Git, Godot caches, player saves, credentials and extra local files are protected. Export presets are merged only for game version/build fields; owner IDs, signing, plugins, paths and permissions remain. Re-running an already applied update is a no-op. Conflicts identify the local files that must be reviewed; they are not silently overwritten.

After success, open `/Users/mak/Documents/GitHub/salvage-stack/project.godot` and allow the new textures to import. F5 runs the game. The supplied debug APK is not installed automatically. The older project-local `update_salvage_stack.py`, if present, is retained for compatibility, but use this package's `apply_update.py` for this update.
