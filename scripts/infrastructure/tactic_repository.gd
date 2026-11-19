class_name TacticRepository

const ROOT := "user://tactics"
var root_path: String

func _init(path: String = ROOT) -> void:
	root_path = path
	DirAccess.make_dir_recursive_absolute(root_path)

func ensure_sample() -> Dictionary:
	var sample := TacticModels.sample_tactic()
	var stored := load_by_id(str(sample.id))
	if not stored.is_empty():
		return stored
	save(sample)
	return sample

func create_blank(title: String = "未命名战术") -> Dictionary:
	var tactic := TacticModels.blank_tactic(title)
	save(tactic)
	return tactic

func resume_tactic() -> Dictionary:
	var session := ConfigFile.new()
	if session.load(root_path.path_join("session.cfg")) == OK:
		var tactic := load_by_id(str(session.get_value("editor", "tactic", "")))
		if not tactic.is_empty():
			return tactic
	return ensure_sample()

func remember_tactic(tactic_id: String) -> Error:
	var session := ConfigFile.new()
	session.set_value("editor", "tactic", tactic_id)
	return _replace_text(root_path.path_join("session.cfg"), session.encode_to_text())

func load_by_id(tactic_id: String) -> Dictionary:
	if not tactic_id.is_valid_filename():
		return {}
	var path := root_path.path_join(tactic_id + ".json")
	for candidate in [path, path + ".bak"]:
		var parsed := _decode_tactic(FileAccess.get_file_as_string(candidate), tactic_id)
		if not parsed.is_empty():
			return TacticModels.ensure_frames(parsed)
	return {}

func _decode_tactic(contents: String, tactic_id: String) -> Dictionary:
	if contents.is_empty():
		return {}
	var json := JSON.new()
	if json.parse(contents) != OK or not json.data is Dictionary:
		return {}
	var document: Dictionary = json.data
	if document.get("id", "") != tactic_id or not document.get("players", []) is Array:
		return {}
	var frames: Variant = document.get("frames", [])
	if not frames is Array:
		return {}
	for frame in frames:
		if not frame is Dictionary or not frame.get("positions", {}) is Dictionary:
			return {}
	return document

func delete_tactic(tactic_id: String) -> bool:
	if not tactic_id.is_valid_filename() or tactic_id == "sample-three-receiver-fast-middle":
		return false
	var path := root_path.path_join(tactic_id + ".json")
	var removed := false
	for candidate in [path + ".bak", path]:
		if not FileAccess.file_exists(candidate):
			continue
		if DirAccess.remove_absolute(candidate) != OK:
			return false
		removed = true
	return removed

func save(tactic: Dictionary) -> Error:
	var tactic_id := str(tactic.get("id", ""))
	if not tactic_id.is_valid_filename():
		return ERR_INVALID_PARAMETER
	TacticModels.ensure_frames(tactic)
	var path := root_path.path_join(tactic_id + ".json")
	var backup := path + ".bak"
	var temporary := path + ".tmp"
	var stage_error := _stage_text(temporary, JSON.stringify(tactic, "\t"))
	if stage_error != OK:
		return stage_error

	var previous := FileAccess.get_file_as_string(path)
	if not _decode_tactic(previous, tactic_id).is_empty():
		var backup_error := _replace_text(backup, previous)
		if backup_error != OK:
			DirAccess.remove_absolute(temporary)
			return backup_error

	var replace_error := _promote_text(temporary, path)
	if replace_error != OK and not FileAccess.file_exists(path) and FileAccess.file_exists(backup):
		_replace_text(path, FileAccess.get_file_as_string(backup))
	return replace_error

func _replace_text(path: String, contents: String) -> Error:
	var temporary := path + ".tmp"
	var stage_error := _stage_text(temporary, contents)
	if stage_error != OK:
		return stage_error
	return _promote_text(temporary, path)

func _stage_text(temporary: String, contents: String) -> Error:
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var written := file.store_string(contents)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if not written or write_error != OK or FileAccess.get_file_as_string(temporary) != contents:
		DirAccess.remove_absolute(temporary)
		return write_error if write_error != OK else ERR_FILE_CANT_WRITE
	return OK

func _promote_text(temporary: String, path: String) -> Error:
	var replace_error := DirAccess.rename_absolute(temporary, path)
	if replace_error != OK:
		DirAccess.remove_absolute(temporary)
	return replace_error

func load_all() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var ids := {}
	for name in DirAccess.get_files_at(root_path):
		if name.ends_with(".json"):
			ids[name.trim_suffix(".json")] = true
		elif name.ends_with(".json.bak"):
			ids[name.trim_suffix(".json.bak")] = true
	for id in ids:
		var tactic := load_by_id(id)
		if not tactic.is_empty():
			results.append(tactic)
	return results

func copy_tactic(source: Dictionary) -> Dictionary:
	var copy := source.duplicate(true)
	copy.id = TacticModels.new_tactic_id("copy")
	copy.title = str(source.title) + "（副本）"
	copy.updatedAt = Time.get_datetime_string_from_system(true)
	save(copy)
	return copy
