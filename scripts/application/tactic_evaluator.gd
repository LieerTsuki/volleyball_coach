class_name TacticEvaluator

static func evaluate_at(tactic: Dictionary, time_ms: int) -> Dictionary:
	var state := {"players": [], "ball": {"active": false, "position": Vector3.ZERO}, "phase_index": 0}
	for player in tactic.get("players", []):
		var id := str(player.get("id", ""))
		var position := evaluate_player_position(tactic, id, time_ms)
		var pose := evaluate_pose(tactic, id, time_ms)
		state.players.append({"player_id": id, "position": position, "yaw_deg": evaluate_yaw(tactic, id, time_ms, position), "pose": pose.type, "pose_progress": pose.progress})
	for i in range(tactic.get("phases", []).size()):
		if int(tactic.phases[i].get("startMs", 0)) <= time_ms: state.phase_index = i
	var active = null
	for action in tactic.get("ballActions", []):
		if time_ms >= int(action.get("startMs", 0)) and time_ms <= int(action.get("endMs", 0)): active = action
	if active != null:
		var a := resolve_endpoint(tactic, active.get("from", {}))
		var b := resolve_endpoint(tactic, active.get("to", {}))
		var u := clamp(float(time_ms - int(active.startMs)) / max(1.0, float(int(active.endMs) - int(active.startMs))), 0.0, 1.0)
		state.ball = {"active": true, "position": a.lerp(b, u) + Vector3.UP * 4.0 * float(active.get("arcHeightM", 0.0)) * u * (1.0 - u), "type": str(active.get("type", "")), "progress": u}
	return state

static func evaluate_player_position(tactic: Dictionary, player_id: String, time_ms: int) -> Vector3:
	var position := Vector3.ZERO
	for slot in tactic.get("initialFormation", []):
		if str(slot.get("playerId", "")) == player_id: position = Vector3(float(slot.x), 0.0, float(slot.z))
	for move in tactic.get("moveTracks", []):
		if str(move.get("playerId", "")) != player_id: continue
		var start := int(move.get("startMs", 0)); var end := int(move.get("endMs", 0)); var points: Array = move.get("waypoints", [])
		if time_ms < start: break
		if time_ms >= end: position = _point(points.back()); continue
		var u := clamp(float(time_ms - start) / max(1.0, float(end - start)), 0.0, 1.0)
		var target := _point(points.back()) if not points.is_empty() else position
		position = position.lerp(target, u); break
	return position

static func resolve_contact_point(tactic: Dictionary, contact: Dictionary) -> Vector3:
	var position := evaluate_player_position(tactic, str(contact.get("playerId", "")), int(contact.get("timeMs", 0)))
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
	for pose in tactic.get("poseActions", []):
		if str(pose.get("playerId", "")) == player_id and time_ms >= int(pose.startMs) and time_ms <= int(pose.endMs):
			return {"type": str(pose.get("type", "Ready")), "progress": clamp(float(time_ms - int(pose.startMs)) / max(1.0, float(int(pose.endMs) - int(pose.startMs))), 0.0, 1.0)}
	return {"type": "Ready", "progress": 0.0}

static func evaluate_yaw(tactic: Dictionary, player_id: String, time_ms: int, position: Vector3) -> float:
	for move in tactic.get("moveTracks", []):
		if str(move.get("playerId", "")) == player_id and time_ms >= int(move.startMs) and time_ms < int(move.endMs) and not move.get("waypoints", []).is_empty():
			var target := _point(move.waypoints[0]); return rad_to_deg(atan2(target.x - position.x, target.z - position.z))
	for slot in tactic.get("initialFormation", []):
		if str(slot.get("playerId", "")) == player_id: return float(slot.get("yawDeg", 0.0))
	return 0.0

static func _point(value: Dictionary) -> Vector3: return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
