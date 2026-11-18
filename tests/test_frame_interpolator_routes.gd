extends SceneTree

func _init() -> void:
	var tactic := TacticModels.blank_tactic("路径测试")
	tactic["frames"] = [
		{"id": "frame-0", "durationMs": 1000, "positions": {"p1": {"x": -3.0, "z": -6.0}}, "routes": {"p1": [{"x": -3.0, "z": -6.0}, {"x": 0.0, "z": -3.0}, {"x": 3.0, "z": 0.0}]}, "ball": {"x": -2.0, "z": -5.0}},
		{"id": "frame-1", "durationMs": 1000, "positions": {"p1": {"x": 3.0, "z": 0.0}}, "routes": {}, "ball": {"x": 2.0, "z": 4.0}}
	]
	var midpoint := FrameInterpolator.player_position(tactic, "p1", 500)
	if midpoint.x <= -0.5 or midpoint.z >= -2.0:
		push_error("Player route interpolation did not follow the drawn path")
		quit(1)
		return
	var ball_midpoint := FrameInterpolator.ball_position(tactic, 500)
	if ball_midpoint.distance_to(Vector3.ZERO) < 0.01:
		push_error("Ball keyframe interpolation is missing")
		quit(1)
		return
	print("frame route tests passed")
	quit(0)
