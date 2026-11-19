extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_path := "user://" + TacticModels.new_tactic_id("library-test")
	var repository := TacticRepository.new(root_path)
	var first_id := str(TacticModels.blank_tactic().id)
	var second_id := str(TacticModels.blank_tactic().id)
	if first_id == second_id:
		push_error("Creating two tactics in the same second must not reuse an ID")
		quit(1)
		return
	var created := repository.create_blank("测试战术")
	var loaded := repository.load_by_id(str(created.get("id", "")))
	if loaded.is_empty() or str(loaded.get("title", "")) != "测试战术":
		push_error("Tactic library must save and load a tactic")
		quit(1)
		return
	var path := root_path.path_join(str(created.id) + ".json")
	DirAccess.make_dir_absolute(path + ".tmp")
	created.title = "写入失败"
	var save_error: Variant = repository.call("save", created)
	DirAccess.remove_absolute(path + ".tmp")
	if save_error == OK or repository.load_by_id(str(created.id)).get("title", "") != "测试战术":
		push_error("A failed save must preserve the original tactic")
		quit(1)
		return
	created.title = "第二份"
	if repository.save(created) != OK or repository.load_by_id(str(created.id)).get("title", "") != "第二份":
		push_error("Saving a new revision must replace the primary tactic")
		quit(1)
		return
	created.players = [{"id": "p1", "jerseyNumber": "18", "name": "测试攻手"}]
	created.frames[0].positions = {"p1": {"x": -2.0, "z": -1.5}}
	var problem := RallyPlan.save_action(created, 0, "Spike", "p1", "", Vector3(2, 0, 5))
	if not problem.is_empty() or repository.save(created) != OK or repository.remember_tactic(str(created.id)) != OK:
		push_error("The active tactic and custom action must be saved")
		quit(1)
		return
	var reopened := TacticRepository.new(root_path).resume_tactic()
	if reopened.get("id", "") != created.id or reopened.players[0].jerseyNumber != "18" or reopened.frames[0].rallyAction.type != "Spike":
		push_error("A new repository must resume the last tactic with players and actions")
		quit(1)
		return
	if not FrameInterpolator.position_in_frame(reopened.frames[0], "p1").is_equal_approx(Vector3(-2, 0, -1.5)):
		push_error("Resuming a tactic must preserve positions")
		quit(1)
		return
	var other := repository.create_blank("另一份战术")
	var blocked_write := root_path.path_join(str(other.id) + ".json.tmp")
	DirAccess.make_dir_absolute(blocked_write)
	var app = load("res://scenes/main.tscn").instantiate()
	app.repository = repository
	root.add_child(app)
	app.editor._load_tactic_from_library(str(other.id))
	DirAccess.remove_absolute(blocked_write)
	if repository.resume_tactic().id != other.id:
		push_error("Opening a saved tactic must not require rewriting its JSON")
		quit(1)
		return
	var session_temp := root_path.path_join("session.cfg.tmp")
	DirAccess.make_dir_absolute(session_temp)
	app.editor._load_tactic_from_library(str(created.id))
	DirAccess.remove_absolute(session_temp)
	if repository.resume_tactic().id != other.id or not app.editor.status_label.text.contains("启动恢复"):
		push_error("A session write failure must preserve and report the previous startup selection")
		quit(1)
		return
	app.free()
	repository.remember_tactic(str(created.id))
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("{}")
	corrupt.close()
	if repository.load_by_id(str(created.id)).get("title", "") != "第二份":
		push_error("A primary file with missing fields must fall back to a valid backup")
		quit(1)
		return
	DirAccess.remove_absolute(path)
	if repository.load_by_id(str(created.id)).get("title", "") != "第二份":
		push_error("The library must recover from a missing primary file")
		quit(1)
		return
	if not repository.load_all().any(func(item: Dictionary) -> bool: return item.get("id", "") == created.id):
		push_error("A recovered tactic must be discoverable in the library")
		quit(1)
		return
	if not repository.delete_tactic(str(created.get("id", ""))):
		push_error("Tactic library must delete a custom tactic")
		quit(1)
		return
	if repository.resume_tactic().get("id", "") != "sample-three-receiver-fast-middle":
		push_error("A deleted last tactic must fall back to the sample")
		quit(1)
		return
	for file_name in DirAccess.get_files_at(root_path):
		DirAccess.remove_absolute(root_path.path_join(file_name))
	DirAccess.remove_absolute(root_path)
	print("tactic library tests passed")
	quit(0)
