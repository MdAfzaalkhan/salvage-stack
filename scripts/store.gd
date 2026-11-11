extends RefCounted
const VERSION = 1
var path = "user://salvage-save.json"
var problem = ""
var data: Dictionary
var restored_backup = false

func defaults() -> Dictionary:
	var progress: Array = []
	for i in range(12):
		progress.append({"won":false,"best":0})
	return {"settings":{"music":0.65,"effects":0.8,"haptics":true,"reduced_motion":false},"progress":progress,"last":0,"checkpoint":{},"tutorial_done":false}

func load_save() -> void:
	data = defaults()
	for candidate in [path,path+".bak",path+".tmp"]:
		var loaded = read_valid(candidate)
		if not loaded.is_empty():
			data = loaded
			restored_backup = candidate != path
			return

func read_valid(filename: String) -> Dictionary:
	if not FileAccess.file_exists(filename):
		return {}
	var f = FileAccess.open(filename,FileAccess.READ)
	if f == null:
		return {}
	var parser = JSON.new()
	if parser.parse(f.get_as_text()) != OK:
		return {}
	var envelope = parser.data
	if not envelope is Dictionary or int(envelope.get("version",-1)) != VERSION:
		return {}
	var payload = envelope.get("payload","")
	if not payload is String or str(envelope.get("sha256","")) != payload.sha256_text():
		return {}
	if parser.parse(payload) != OK:
		return {}
	var value = parser.data
	# Additive migration: 0.1.0 saves retain settings, progress and checkpoint.
	if value is Dictionary and not value.has("tutorial_done"):
		value["tutorial_done"] = false
	if not valid_data(value):
		return {}
	return value

func valid_data(v: Variant) -> bool:
	if not v is Dictionary or not v.get("settings") is Dictionary or not v.get("progress") is Array:
		return false
	if v.progress.size() != 12 or not v.get("last") is float and not v.get("last") is int:
		return false
	if int(v.last)<0 or int(v.last)>11:
		return false
	for p in v.progress:
		if not p is Dictionary or not p.get("won") is bool or not _number(p.get("best"),0,3):
			return false
	var s = v.settings
	if not _number(s.get("music"),0,1) or not _number(s.get("effects"),0,1) or not s.get("haptics") is bool or not s.get("reduced_motion") is bool:
		return false
	return v.get("tutorial_done") is bool and valid_checkpoint(v.get("checkpoint"))

func _number(v: Variant, low: float, high: float) -> bool:
	return (v is float or v is int) and is_finite(float(v)) and float(v)>=low and float(v)<=high

func valid_checkpoint(c: Variant) -> bool:
	if not c is Dictionary:
		return false
	if c.is_empty():
		return true
	if not _number(c.get("sequence"),0,11) or not _number(c.get("placed"),0,8):
		return false
	if c.get("phase") not in ["build","extract"] or not c.get("recovered") is Array or not c.get("bodies") is Array:
		return false
	if (c.phase == "extract") != (int(c.placed)==8):
		return false
	if c.recovered.size()>2 or (c.phase=="build" and not c.recovered.is_empty()):
		return false
	var removed: Array = []
	for t in c.recovered:
		if not _number(t,1,3) or removed.has(int(t)*2-1):
			return false
		removed.append(int(t)*2-1)
	var ids: Array = []
	for b in c.bodies:
		if not b is Dictionary or not _number(b.get("id"),0,int(c.placed)-1):
			return false
		if ids.has(int(b.id)) or removed.has(int(b.id)):
			return false
		ids.append(int(b.id))
		for key in ["x","y","r","vx","vy","av"]:
			if not _number(b.get(key),-10000,10000):
				return false
	return ids.size()+removed.size()==int(c.placed)

func write() -> bool:
	if not valid_data(data):
		problem = "Save rejected: invalid state."
		return false
	var payload = JSON.stringify(data)
	var envelope = JSON.stringify({"version":VERSION,"payload":payload,"sha256":payload.sha256_text()})
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		problem = "Couldn't save. Please check free storage."
		return false
	file.store_string(envelope)
	file.flush()
	file.close()
	if read_valid(path+".tmp").is_empty():
		problem = "Couldn't verify save."
		return false
	# Keep the previous validated generation. A corrupt main never replaces backup.
	if not read_valid(path).is_empty():
		var err = DirAccess.copy_absolute(path,path+".bak")
		if err != OK:
			problem = "Couldn't back up save."
			return false
	var err = DirAccess.rename_absolute(path+".tmp",path)
	if err != OK:
		problem = "Couldn't finish saving."
		return false
	problem = ""
	return true

func record(index: int, count: int, won: bool) -> void:
	data.progress[index].best = maxi(int(data.progress[index].best),count)
	data.progress[index].won = data.progress[index].won or won
	data.checkpoint = {}
	write()
