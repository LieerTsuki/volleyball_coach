extends SceneTree

func _init() -> void:
	var tactic := TacticModels.ensure_frames(TacticModels.blank_tactic("接发进攻"))
	tactic.players = [
		{"id": "libero", "jerseyNumber": "6"},
		{"id": "setter", "jerseyNumber": "1"},
		{"id": "hitter", "jerseyNumber": "4"}
	]
	tactic.frames[0].positions = {
		"libero": {"x": -2, "z": -5},
		"setter": {"x": 0, "z": -2},
		"hitter": {"x": -4, "z": -6}
	}
	for index in range(2):
		tactic.frames.append(tactic.frames[0].duplicate(true))
	var landing := Vector3(2.2, 0, 4.7)
	var error := RallyPlan.save_action(tactic, 2, "Spike", "hitter", "", landing)
	if not error.is_empty():
		_fail(error)
		return
	error = RallyPlan.save_action(tactic, 1, "Set", "setter", "setter", null)
	if error.is_empty() or tactic.frames[1].has("rallyAction"):
		_fail("A set cannot target the setter")
		return
	error = RallyPlan.save_action(tactic, 1, "Set", "setter", "hitter", Vector3(-3, 0, -1))
	if not error.is_empty():
		_fail(error)
		return
	error = RallyPlan.save_action(tactic, 0, "Pass", "libero", "setter", Vector3(1, 0, -1.4))
	if not error.is_empty():
		_fail(error)
		return
	if not FrameInterpolator.player_position(tactic, "hitter", 1800).is_equal_approx(Vector3(-3, 0, -1)):
		_fail("The chosen set location must update the hitter's next standing position")
		return

	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(tactic))
	var replay := RallyPlan.compile(reloaded)
	var pass_contact := TacticEvaluator.evaluate_at(replay, 0)
	var set_contact := TacticEvaluator.evaluate_at(replay, 900)
	var spike_contact := TacticEvaluator.evaluate_at(replay, 1800)
	if pass_contact.players[0].pose != "Dig" or set_contact.players[1].pose != "Set" or spike_contact.players[2].pose != "Spike":
		_fail("Each saved move must animate its selected player at the assigned keyframe")
		return
	if not is_equal_approx(float(spike_contact.players[2].pose_progress), 0.5):
		_fail("The selected hitter must contact the ball near the top of the jump")
		return
	if set_contact.ball.type != "Set" or spike_contact.ball.type != "Spike":
		_fail("Ball flights must join with the next contact on the same frame time")
		return
	var point_before: Vector3 = TacticEvaluator.evaluate_at(replay, 1799).ball.position
	if point_before.distance_to(spike_contact.ball.position) > 0.03:
		_fail("The set must reach the same hand position the spike starts from")
		return

	if not _clears_net(replay, -650, 0):
		_fail("The incoming ball must clear the net before the first pass")
		return
	var end: Vector3 = TacticEvaluator.evaluate_at(replay, 2699).ball.position
	if not _clears_net(replay, 1800, 2300) or not Vector2(end.x, end.z).is_equal_approx(Vector2(landing.x, landing.z)):
		_fail("The spike must clear the net and stay at the selected landing spot")
		return

	var gap: Dictionary = tactic.duplicate(true)
	gap.frames[1].erase("rallyAction")
	var linked := RallyPlan.compile(gap)
	var held := TacticEvaluator.evaluate_ball_at(linked, 1000)
	var restart: Vector3 = TacticEvaluator.evaluate_ball_at(linked, 1150).position
	if not bool(held.active) or not restart.is_equal_approx(held.position):
		_fail("Removing a middle action must keep the ball visible and continue from its last position")
		return

	error = RallyPlan.save_action(tactic, 2, "Spike", "libero", "", landing)
	if not error.is_empty() or tactic.frames[1].rallyAction.targetPlayerId != "libero":
		_fail("Changing the hitter must retarget the incoming set")
		return

	var demo := TacticModels.ensure_frames(TacticModels.sample_tactic())
	RallyPlan.save_action(demo, 2, "Spike", "p2", "", landing)
	demo.frames[2].erase("rallyAction")
	if RallyPlan.compile(demo).ballActions.is_empty():
		_fail("Clearing all new actions must restore the legacy demo playback")
		return

	RallyPlan.remove_player_actions(tactic, "setter")
	if tactic.frames[0].has("rallyAction") or tactic.frames[1].has("rallyAction") or not tactic.frames[2].has("rallyAction"):
		_fail("Deleting a player must clear only actions involving that player")
		return
	print("rally action tests passed")
	quit()

func _clears_net(replay: Dictionary, start: int, end: int) -> bool:
	for time_ms in range(start, end):
		var position: Vector3 = TacticEvaluator.evaluate_ball_at(replay, time_ms).position
		if absf(position.z) < 0.035 and position.y >= 2.43 + 0.17:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
