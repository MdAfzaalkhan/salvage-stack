# Actual rendered capture

No screenshots or video were captured during the redesign session: computer access to Godot was denied, and the session could not launch a usable graphical renderer. These instructions are included so a permitted graphical run can produce implementation evidence without recreating screens by hand.

Close the editor's running game, use Godot 4.7.2 and run from the extracted/updated project folder:

```bash
SALVAGE_TEST_SAVE_PATH=/tmp/salvage-capture-save.json "/Users/mak/Downloads/Godot.app/Contents/MacOS/Godot" --path . -- --capture-demo
```

This drives the real game, including an actual successful construction/extraction and an actual failing centred construction. It writes these rendered viewport PNGs in `evidence/`: Home, sequences, tutorial, Build, selected Extract, Pause, Settings, success, failure. It does not edit your regular player save. It is a source/editor developer path; it is not enabled during ordinary play or shipped as an APK tutorial.

For a recording of the entrance/idle and extraction flow, Godot Movie Maker supports:

```bash
SALVAGE_TEST_SAVE_PATH=/tmp/salvage-capture-save.json "/Users/mak/Downloads/Godot.app/Contents/MacOS/Godot" --path . --write-movie /tmp/salvage-gameplay.avi --fixed-fps 60 -- --capture-demo
```

A headless Dummy renderer cannot provide these screenshots. Do not present blank captures, generated concepts, asset textures or headless bounds tests as running-game visual verification. Physical Android installation/play remains a separate check.
