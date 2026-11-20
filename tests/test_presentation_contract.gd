extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var layout := VerticalCourtLayout.new()
	var rect := layout.court_rect(Vector2(1080, 1920))
	var home := layout.world_to_screen(Vector3(0, 0, -6), rect)
	var away := layout.world_to_screen(Vector3(0, 0, 6), rect)
	if home.y <= rect.position.y + rect.size.y * 0.5:
		push_error("Our negative-z court side must render below the net")
		quit(1)
		return
	if away.y >= rect.position.y + rect.size.y * 0.5:
		push_error("Opponent positive-z court side must render above the net")
		quit(1)
		return

	var replay := TacticReplay3D.new()
	root.add_child(replay)
	await process_frame
	var tactic := TacticModels.sample_tactic()
	replay.set_tactic(tactic)
	if replay.actors.size() != tactic.players.size():
		push_error("3D replay must create only the user's players")
		quit(1)
		return
	if replay.actors.has("away-0"):
		push_error("3D replay must not create opponent players")
		quit(1)
		return
	print("presentation contract tests passed")
	quit(0)
