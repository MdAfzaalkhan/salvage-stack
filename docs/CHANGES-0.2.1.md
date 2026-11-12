# 0.2.1 — material and composition polish

New original baked materials replace per-polygon gradients and diagonal bands. The standard-library baker lives in `tools/bake_materials.py`; `tools/export_material_shapes.gd` exports the collision unions and a GDScript catalog. Runtime rendering uses one lightweight texture per piece, white number text and selection brackets. Transparent texture pixels stay outside the union, and bevel depth remains inside it. No additional collision surfaces or external assets are introduced.

Rebake from the project root:

```bash
godot --headless --path . --script res://tools/export_material_shapes.gd
python3 tools/bake_materials.py
```

The camera is a viewport canvas transform, independent of physics and UI CanvasLayers. Build uses the sequence's structural height plus release clearance; an exceptional taller arrangement expands to the complete stack envelope. Extract fits the actual settled tower once. It does not recenter or zoom after each extraction. Foundation, loss plane, ghosts, picking and visual recovery coordinates stay aligned.

The reference has more luminous, transparent glass and a different stack silhouette. This implementation keeps the game's actual shape proportions and side-on view, with opaque contact edges and restrained bevels. It does not extrude fake supporting ledges. Final rendered differences, softness, brightness and perceived scale require the blocked graphical comparison; no visual parity claim is made.
