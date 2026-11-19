extends SceneTree

func _init() -> void:
	var tactic := TacticModels.blank_tactic("关键帧回放测试")
	tactic.players = [{"id": "p1"}, {"id": "p2"}, {"id": "p3"}]
	tactic.frames = [
		{"durationMs": 1000, "positions": {"p1": {"x": -3, "z": -6}, "p2": {"x": 1, "z": -6}, "p3": {"x": 3, "z": -6}},
			"routes": {"p1": [{"x": -3, "z": -6}, {"x": 0, "z": 2}, {"x": 3, "z": -2}]}, "ball": {"x": -2, "z": -5}},
		{"durationMs": 1000, "positions": {"p1": {"x": 3, "z": -2}, "p2": {"x": 1, "z": -6}, "p3": {"x": 3, "z": -6}}, "ball": {"x": 2, "z": 4}},
		{"durationMs": 400, "positions": {"p1": {"x": 3, "z": -2}, "p2": {"x": 1, "z": -2}, "p3": {"x": 3, "z": -6}}, "ball": {"x": 2, "z": 4}}
	]

	if not FrameInterpolator.player_position(tactic, "p1", 500).is_equal_approx(Vector3(0, 0, -4)):
		_fail("Old dashed paths must not affect movement between keyframes")
		return
	TacticModels.ensure_frames(tactic)
	if tactic.frames[0].has("routes"):
		_fail("Loading old tactics must discard dashed path data")
		return
	var early := TacticEvaluator.evaluate_at(tactic, 500)
	var late := TacticEvaluator.evaluate_at(tactic, 1500)
	if not _matches_pose(early.players[0], "Run", Vector3(0, 0, -4)) or not _matches_pose(early.players[1], "Ready", Vector3(1, 0, -6)):
		_fail("3D must use the 2D coordinates and animate only moving players")
		return
	if not _matches_pose(late.players[0], "Ready", Vector3(3, 0, -2)) or not _matches_pose(late.players[1], "Run", Vector3(1, 0, -4)) or not _matches_pose(late.players[2], "Ready", Vector3(3, 0, -6)):
		_fail("Later runs and stationary players must follow their own keyframes")
		return
	if not bool(early.ball.active) or not Vector2(early.ball.position.x, early.ball.position.z).is_equal_approx(Vector2(0, -0.5)):
		_fail("3D must show the ball from the 2D keyframes")
		return
	var final_state := TacticEvaluator.evaluate_at(tactic, 2400)
	if not _matches_pose(final_state.players[1], "Ready", Vector3(1, 0, -2)):
		_fail("The final keyframe must hold its positions")
		return
	tactic.frames[1].positions.p1 = {"x": 0, "z": -4}
	var before := TacticEvaluator.evaluate_at(tactic, 999)
	var after := TacticEvaluator.evaluate_at(tactic, 1000)
	if absf(before.players[0].stride - after.players[0].stride) > 0.05 or float(after.players[0].stride_weight) < 0.9:
		_fail("A continuous run must keep its stride across keyframes")
		return
	var demo := TacticModels.ensure_frames(TacticModels.sample_tactic())
	if str(TacticEvaluator.evaluate_at(demo, 1800).ball.get("type", "")) != "Pass":
		_fail("The demo must still play its authored ball actions")
		return
	demo.ballActions[1].startMs = 1900
	if bool(TacticEvaluator.evaluate_at(demo, 1800).ball.active):
		_fail("An authored ball track must not jump to center court in a gap")
		return
	demo.frames[1]["ball"] = {"x": 2, "z": 4}
	var edited_ball: Vector3 = TacticEvaluator.evaluate_at(demo, 800).ball.position
	if not Vector2(edited_ball.x, edited_ball.z).is_equal_approx(Vector2(2, 4)):
		_fail("A 2D ball edit must override an authored demo ball track")
		return
	print("keyframe replay tests passed")
	quit(0)

func _matches_pose(player: Dictionary, pose: String, position: Vector3) -> bool:
	return player.pose == pose and position.is_equal_approx(player.position)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
