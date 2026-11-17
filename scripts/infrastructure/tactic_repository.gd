class_name TacticRepository

const ROOT := "user://tactics"

func _init() -> void: DirAccess.make_dir_recursive_absolute(ROOT)

func ensure_sample() -> Dictionary:
	var sample := TacticModels.sample_tactic()
	var path: String = ROOT + "/" + str(sample.id) + ".json"
	if not FileAccess.file_exists(path): save(sample)
	return sample

func save(tactic: Dictionary) -> void:
	var path := ROOT + "/" + str(tactic.id) + ".json"
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE); file.store_string(JSON.stringify(tactic, "\t")); file.close()
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path + ".bak"); DirAccess.rename_absolute(path, path + ".bak")
	DirAccess.rename_absolute(tmp, path)

func load_all() -> Array[Dictionary]:
	var results: Array[Dictionary] = []; var dir := DirAccess.open(ROOT)
	if dir == null: return results
	dir.list_dir_begin(); var name := dir.get_next()
	while not name.is_empty():
		if name.ends_with(".json"):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "/" + name)); if parsed is Dictionary: results.append(parsed)
		name = dir.get_next()
	dir.list_dir_end(); return results

func copy_tactic(source: Dictionary) -> Dictionary:
	var copy: Dictionary = JSON.parse_string(JSON.stringify(source)); copy.id = "copy-" + str(Time.get_unix_time_from_system()); copy.title = str(source.title) + "（副本）"; copy.updatedAt = Time.get_datetime_string_from_system(true); save(copy); return copy
