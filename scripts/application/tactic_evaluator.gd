class_name TacticEvaluator

static func evaluate_at(tactic: Dictionary, time_ms: int) -> Dictionary:
	var frames: Array = tactic.get("frames", [])
	var sample := FrameInterpolator.frame_sample(frames, time_ms)
	var state := {
		"players": [],
		"ball": _evaluate_ball(tactic, frames, sample, time_ms),
		"phase_index": 0,
		"frame_index": int(sample.get("index", 0))
	}
	for player in tactic.get("players", []):
		var id := str(player.get("id", ""))
		var pose := evaluate_pose(tactic, id, time_ms)
		var position: Vector3
		var yaw: float
		var stride := 0.0
		var stride_weight := 0.0
		if sample.is_empty():
			position = evaluate_player_position(tactic, id, time_ms)
			yaw = evaluate_yaw(tactic, id, time_ms, position)
		else:
			var motion := FrameInterpolator.player_motion(frames, id, sample)
			position = motion.position
			var direction: Vector3 = motion.direction
			var distance := direction.length()
			yaw = 180.0 if position.z > 0.0 else 0.0
			if distance > 0.01:
				yaw = rad_to_deg(atan2(direction.x, direction.z))
				if pose.type == "Ready":
					pose.type = "Run"
				var gait := _evaluate_stride(frames, id, sample, direction)
				stride = gait.x
				stride_weight = gait.y
		if pose.has("yaw"):
			yaw = rad_to_deg(float(pose.yaw))
			stride_weight *= 1.0 - sin(float(pose.progress) * PI)
		state.players.append({
			"player_id": id, "position": position, "yaw_deg": yaw, "pose": pose.type,
			"pose_progress": pose.progress, "stride": stride, "stride_weight": stride_weight
		})
	for index in range(tactic.get("phases", []).size()):
		if int(tactic.phases[index].get("startMs", 0)) <= time_ms:
			state.phase_index = index
	return state

static func _evaluate_stride(frames: Array, player_id: String, sample: Dictionary, direction: Vector3) -> Vector2:
	var index: int = sample.index
	var progress: float = sample.progress
	var duration: float = sample.duration_ms
	var distance := direction.length()
	var heading := direction / distance
	var distance_before := 0.0
	for previous in range(index - 1, -1, -1):
		var previous_move := FrameInterpolator.position_in_frame(frames[previous + 1], player_id) - FrameInterpolator.position_in_frame(frames[previous], player_id)
		if previous_move.length() <= 0.01 or previous_move.normalized().dot(heading) < 0.5:
			break
		distance_before += previous_move.length()
		heading = previous_move.normalized()
	var continues := false
	if index + 2 < frames.size():
		var next_move := FrameInterpolator.position_in_frame(frames[index + 2], player_id) - FrameInterpolator.position_in_frame(frames[index + 1], player_id)
		continues = next_move.length() > 0.01 and next_move.normalized().dot(direction / distance) >= 0.5
	# Distance keeps the same stride during continuous movement and when seeking.
	var edge := minf(0.35, 100.0 / duration)
	var ramp_in := 1.0 if distance_before > 0.0 else smoothstep(0.0, edge, progress)
	var ramp_out := 1.0 if continues else smoothstep(0.0, edge, 1.0 - progress)
	var weight := clampf(distance * 1000.0 / duration / 2.0, 0.18, 1.0)
	return Vector2((distance_before + distance * progress) * TAU / 1.35, weight * ramp_in * ramp_out)

static func evaluate_ball_at(tactic: Dictionary, time_ms: int) -> Dictionary:
	var frames: Array = tactic.get("frames", [])
	return _evaluate_ball(tactic, frames, FrameInterpolator.frame_sample(frames, time_ms), time_ms)

static func _evaluate_ball(tactic: Dictionary, frames: Array, sample: Dictionary, time_ms: int) -> Dictionary:
	var actions: Array = tactic.get("ballActions", [])
	var custom := tactic.has("rallyLeadInMs")
	if not actions.is_empty() and (custom or not _has_ball_keyframes(tactic, frames)):
		for index in range(actions.size() - 1, -1, -1):
			var action: Dictionary = actions[index]
			var start_ms := int(action.startMs)
			var end_ms := int(action.endMs)
			if time_ms < start_ms:
				continue
			if time_ms > end_ms:
				if custom:
					return _held_ball(tactic, action)
				continue
			var start := resolve_endpoint(tactic, action.get("from", {}))
			var end := resolve_endpoint(tactic, action.get("to", {}))
			var progress := float(time_ms - start_ms) / maxi(1, end_ms - start_ms)
			var arc_height := float(action.get("arcHeightM", 0.0))
			var position := start.lerp(end, progress) + Vector3.UP * 4.0 * arc_height * progress * (1.0 - progress)
			if bool(action.get("clearNet", false)):
				position = _clear_net(tactic, start, end, progress, arc_height, position)
			if action.get("type", "") == "Spike" and bool(action.get("clearNet", false)):
				return {"active": true, "position": position, "type": action.type, "landing": end}
			return {"active": true, "position": position, "type": action.get("type", "")}
		if time_ms < int(actions.front().startMs):
			return {"active": true, "position": resolve_endpoint(tactic, actions.front().get("from", {}))}
		if time_ms > int(actions.back().endMs):
			return _held_ball(tactic, actions.back())
		return {"active": false, "position": Vector3.ZERO}
	if sample.is_empty():
		return {"active": false, "position": Vector3.ZERO}

	var start := FrameInterpolator.ball_position_in_frame(frames[sample.index])
	var end := FrameInterpolator.ball_position_in_frame(frames[sample.next])
	var progress: float = sample.progress
	var position := start.lerp(end, progress)
	var distance := start.distance_to(end)
	position.y = 0.16 + 4.0 * progress * (1.0 - progress) * minf(3.4, distance * 0.5)
	return {"active": true, "position": position}

static func _held_ball(tactic: Dictionary, action: Dictionary) -> Dictionary:
	var point := resolve_endpoint(tactic, action.get("to", {}))
	if action.get("type", "") == "Spike" and bool(action.get("clearNet", false)):
		return {"active": true, "position": point, "landing": point}
	return {"active": true, "position": point}

static func _clear_net(tactic: Dictionary, start: Vector3, end: Vector3, progress: float, arc_height: float, position: Vector3) -> Vector3:
	if start.z * end.z >= 0.0:
		return position
	var crossing := -start.z / (end.z - start.z)
	var net := start.lerp(end, crossing)
	var clearance := float(tactic.get("courtConfig", {}).get("netHeightM", 2.43)) + 0.27
	if net.y + 4.0 * arc_height * crossing * (1.0 - crossing) >= clearance:
		return position
	net.y = clearance
	var crossing_time := clampf(crossing, 0.14, 0.82)
	if progress < crossing_time:
		return start.lerp(net, progress / crossing_time)
	return net.lerp(end, (progress - crossing_time) / (1.0 - crossing_time))

static func _has_ball_keyframes(tactic: Dictionary, frames: Array) -> bool:
	if bool(tactic.get("ballKeyframesEdited", false)):
		return true
	for frame in frames:
		if not FrameInterpolator.ball_position_in_frame(frame).is_zero_approx():
			return true
	return false

static func evaluate_player_position(tactic: Dictionary, player_id: String, time_ms: int) -> Vector3:
	if not tactic.get("frames", []).is_empty():
		return FrameInterpolator.player_position(tactic, player_id, time_ms)
	var position := Vector3.ZERO
	for slot in tactic.get("initialFormation", []):
		if str(slot.get("playerId", "")) == player_id: position = Vector3(float(slot.x), 0.0, float(slot.z))
	for move in tactic.get("moveTracks", []):
		if str(move.get("playerId", "")) != player_id: continue
		var start := int(move.get("startMs", 0)); var end := int(move.get("endMs", 0)); var points: Array = move.get("waypoints", [])
		if time_ms < start: break
		if time_ms >= end: position = _point(points.back()); continue
		var u: float = clampf(float(time_ms - start) / maxf(1.0, float(end - start)), 0.0, 1.0)
		var target := _point(points.back()) if not points.is_empty() else position
		position = position.lerp(target, u); break
	return position

static func resolve_contact_point(tactic: Dictionary, contact: Dictionary) -> Vector3:
	var position := evaluate_player_position(tactic, str(contact.get("playerId", "")), int(contact.get("timeMs", 0)))
	if contact.has("yaw"):
		var offset := Vector3(0, 1.05, 0.52)
		match str(contact.get("anchorType", "")):
			"OverheadHands": offset = Vector3(0, 1.99, 0.36)
			"HittingHand": offset = Vector3(0.30, 2.84, 0.13)
		return position + offset.rotated(Vector3.UP, float(contact.yaw))
	var height := 1.0
	match str(contact.get("anchorType", "")):
		"OverheadHands": height = 2.15
		"HittingHand": height = 2.5
	return position + Vector3.UP * height

static func resolve_endpoint(tactic: Dictionary, endpoint: Dictionary) -> Vector3:
	if bool(endpoint.get("isContact", false)):
		for contact in tactic.get("contactEvents", []):
			if str(contact.get("id", "")) == str(endpoint.get("contactId", "")): return resolve_contact_point(tactic, contact)
	return Vector3(float(endpoint.get("worldPoint", {}).get("x", 0.0)), float(endpoint.get("worldPoint", {}).get("y", 0.0)), float(endpoint.get("worldPoint", {}).get("z", 0.0)))

static func evaluate_pose(tactic: Dictionary, player_id: String, time_ms: int) -> Dictionary:
	var poses: Array = tactic.get("poseActions", [])
	for index in range(poses.size() - 1, -1, -1):
		var pose: Dictionary = poses[index]
		if str(pose.get("playerId", "")) == player_id and time_ms >= int(pose.startMs) and time_ms <= int(pose.endMs):
			var result := {"type": str(pose.get("type", "Ready")), "progress": clampf(float(time_ms - int(pose.startMs)) / maxi(1, int(pose.endMs) - int(pose.startMs)), 0.0, 1.0)}
			if pose.has("yaw"):
				result["yaw"] = pose.yaw
			return result
	return {"type": "Ready", "progress": 0.0}

static func evaluate_yaw(tactic: Dictionary, player_id: String, time_ms: int, position: Vector3) -> float:
	for move in tactic.get("moveTracks", []):
		if str(move.get("playerId", "")) == player_id and time_ms >= int(move.startMs) and time_ms < int(move.endMs) and not move.get("waypoints", []).is_empty():
			var target := _point(move.waypoints[0]); return rad_to_deg(atan2(target.x - position.x, target.z - position.z))
	for slot in tactic.get("initialFormation", []):
		if str(slot.get("playerId", "")) == player_id: return float(slot.get("yawDeg", 0.0))
	return 0.0

static func _point(value: Dictionary) -> Vector3: return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
