extends SceneTree

func _init() -> void:
	var repository := TacticRepository.new()
	var created := repository.create_blank("测试战术")
	var loaded := repository.load_by_id(str(created.get("id", "")))
	if loaded.is_empty() or str(loaded.get("title", "")) != "测试战术":
		push_error("Tactic library must save and load a tactic")
		quit(1)
		return
	if not repository.delete_tactic(str(created.get("id", ""))):
		push_error("Tactic library must delete a custom tactic")
		quit(1)
		return
	print("tactic library tests passed")
	quit(0)
