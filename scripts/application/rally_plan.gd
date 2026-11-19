class_name RallyPlan

const LEAD_IN_MS := 650
const TYPES := ["Pass", "Set", "Spike"]
const LABELS := {"Pass": "一传", "Set": "二传", "Spike": "起跳扣球"}
const POSES := {"Pass": "Dig", "Set": "Set", "Spike": "Spike"}
const ANCHORS := {"Pass": "Forearms", "Set": "OverheadHands", "Spike": "HittingHand"}

static func save_action(tactic: Dictionary, frame_index: int, type: String, player_id: String, target_id: String, point: Variant) -> String:
	var frames: Array = tactic.get("frames", [])
	if frame_index < 0 or frame_index >= frames.size() or not TYPES.has(type):
		return "请选择有效的站位图和动作"
	if not _has_player(tactic, player_id):
		return "请选择执行动作的球员"
	var previous: Dictionary = {}
	if frame_index > 0:
		previous = frames[frame_index - 1].get("rallyAction", {})
		if previous.has("targetPlayerId") and previous.get("playerId", "") == player_id:
			return "这名球员执行了上一张传球，请选另一名球员接球"

	var action := {"type": type, "playerId": player_id}
	if type == "Spike":
		if not _in_court(tactic, point) or point.z <= 0.0:
			return "请在对方场区点选扣球落点"
		action["landing"] = {"x": point.x, "z": point.z}
	else:
		if frame_index + 1 >= frames.size():
			return "请先新增下一张站位图，记录接球位置"
		if not _has_player(tactic, target_id) or target_id == player_id:
			return "请选择另一名球员接球"
		var next: Dictionary = frames[frame_index + 1]
		var next_action: Dictionary = next.get("rallyAction", {})
		if next_action.get("targetPlayerId", "") == target_id:
			return "这名球员是下一张传球的目标，请先调整下一张的传球对象"
		if point != null:
			if not _in_court(tactic, point):
				return "请在球场内点选接球位置"
			next.positions[target_id] = {"x": point.x, "z": point.z}
		if not next_action.is_empty():
			next_action["playerId"] = target_id
		action["targetPlayerId"] = target_id
	frames[frame_index]["rallyAction"] = action
	if previous.has("targetPlayerId"):
		previous["targetPlayerId"] = player_id
	return ""

static func has_actions(tactic: Dictionary) -> bool:
	for frame in tactic.get("frames", []):
		if frame.has("rallyAction"):
			return true
	return false

static func remove_player_actions(tactic: Dictionary, player_id: String) -> void:
	for frame in tactic.get("frames", []):
		var action: Dictionary = frame.get("rallyAction", {})
		if action.get("playerId", "") == player_id or action.get("targetPlayerId", "") == player_id:
			frame.erase("rallyAction")

static func player_tag(tactic: Dictionary, player_id: String) -> String:
	for player in tactic.get("players", []):
		if str(player.get("id", "")) == player_id:
			return "#%s" % str(player.get("jerseyNumber", ""))
	return ""

static func _has_player(tactic: Dictionary, player_id: String) -> bool:
	for player in tactic.get("players", []):
		if not player_id.is_empty() and str(player.get("id", "")) == player_id:
			return true
	return false

static func _in_court(tactic: Dictionary, point: Variant) -> bool:
	if not point is Vector3 or not point.is_finite():
		return false
	var court: Dictionary = tactic.get("courtConfig", TacticModels.default_court())
	return absf(point.x) <= float(court.get("widthM", 9.0)) * 0.5 and absf(point.z) <= float(court.get("lengthM", 18.0)) * 0.5

static func compile(tactic: Dictionary) -> Dictionary:
	if not has_actions(tactic):
		return tactic

	var result := tactic.duplicate()
	result["poseActions"] = []
	result["contactEvents"] = []
	result["ballActions"] = []
	result["phases"] = []
	var frames: Array = tactic.get("frames", [])
	var contacts := {}
	var elapsed := 0

	for index in range(frames.size()):
		var action: Dictionary = frames[index].get("rallyAction", {})
		var type := str(action.get("type", ""))
		var player_id := str(action.get("playerId", ""))
		if TYPES.has(type) and _has_player(tactic, player_id):
			var target: Vector3
			if type == "Spike":
				var landing: Dictionary = action.get("landing", {})
				target = Vector3(float(landing.get("x", 0)), 0.18, float(landing.get("z", 4.5)))
			else:
				var target_id := str(action.get("targetPlayerId", ""))
				if index + 1 >= frames.size() or not _has_player(tactic, target_id):
					elapsed += maxi(1, int(frames[index].get("durationMs", 800)))
					continue
				target = FrameInterpolator.position_in_frame(frames[index + 1], target_id)
			var feet := FrameInterpolator.position_in_frame(frames[index], player_id)
			var direction := target - feet
			var yaw := atan2(direction.x, direction.z) if Vector2(direction.x, direction.z).length_squared() > 0.001 else 0.0
			var contact := {"id": "contact-%d" % index, "playerId": player_id, "timeMs": elapsed,
				"anchorType": ANCHORS[type], "yaw": yaw}
			contacts[index] = {"contact": contact, "action": action, "target": target}
			result.contactEvents.append(contact)
			_append_pose(result, player_id, type, elapsed, yaw)
			var caption: String = "%s · %s" % [LABELS[type], player_tag(tactic, player_id)]
			if type != "Spike":
				caption += " → " + player_tag(tactic, str(action.targetPlayerId))
			result.phases.append({"startMs": elapsed, "label": caption})
		elapsed += maxi(1, int(frames[index].get("durationMs", 800)))

	var flight_end := -LEAD_IN_MS
	for index in contacts:
		var step: Dictionary = contacts[index]
		var contact: Dictionary = step.contact
		var action: Dictionary = step.action
		var time_ms := int(contact.timeMs)
		var target_id := str(action.get("targetPlayerId", ""))
		var from := _contact_endpoint(contact)
		var last: Dictionary = result.ballActions.back() if not result.ballActions.is_empty() else {}
		if last.get("to", {}) != from and flight_end < time_ms:
			var feed_from: Dictionary = last.get("to", {})
			if feed_from.is_empty():
				feed_from = _world_endpoint(_feed_position(tactic, frames[index], str(action.type), str(action.playerId)))
			result.ballActions.append(_flight("Feed", maxi(flight_end, time_ms - LEAD_IN_MS), time_ms, feed_from, from, 0.9))
		var duration := maxi(1, int(frames[index].get("durationMs", 800)))
		if action.type == "Spike":
			flight_end = time_ms + mini(maxi(1, duration - 130), 450)
			result.ballActions.append(_flight("Spike", time_ms, flight_end, from, _world_endpoint(step.target), 0.12))
		else:
			flight_end = time_ms + duration
			var next: Dictionary = contacts.get(index + 1, {})
			var arrival: Dictionary = next.get("contact", {})
			if arrival.get("playerId", "") != target_id:
				arrival = {"id": "receive-%d" % index, "playerId": target_id, "timeMs": flight_end,
					"anchorType": "Forearms", "yaw": float(contact.yaw) + PI}
				result.contactEvents.append(arrival)
			var arc := 1.45 if action.type == "Set" else 0.85
			result.ballActions.append(_flight(str(action.type), time_ms, flight_end, from, _contact_endpoint(arrival), arc))
	if not result.ballActions.is_empty():
		result["rallyLeadInMs"] = LEAD_IN_MS
	return result

static func _append_pose(tactic: Dictionary, player_id: String, type: String, hit_time: int, yaw: float) -> void:
	var half_span := 400 if type == "Spike" else 250
	if type == "Spike":
		tactic.poseActions.append({"playerId": player_id, "type": "Approach", "startMs": hit_time - LEAD_IN_MS,
			"endMs": hit_time - half_span - 1})
	tactic.poseActions.append({"playerId": player_id, "type": POSES[type], "startMs": hit_time - half_span,
		"endMs": hit_time + half_span, "yaw": yaw})

static func _feed_position(tactic: Dictionary, frame: Dictionary, type: String, player_id: String) -> Vector3:
	var point := FrameInterpolator.ball_position_in_frame(frame)
	if not point.is_zero_approx():
		return point + Vector3.UP * 2.25
	if type == "Pass":
		var court: Dictionary = tactic.get("courtConfig", TacticModels.default_court())
		return Vector3(1.5, 2.5, float(court.get("lengthM", 18.0)) * 0.5 - 0.4)
	var player := FrameInterpolator.position_in_frame(frame, player_id)
	return player + Vector3(1.7, 2.7, -1.5)

static func _flight(type: String, start: int, end: int, from: Dictionary, to: Dictionary, arc: float) -> Dictionary:
	return {"type": type, "startMs": start, "endMs": end, "from": from, "to": to, "arcHeightM": arc, "clearNet": true}

static func _contact_endpoint(contact: Dictionary) -> Dictionary:
	return {"isContact": true, "contactId": contact.id}

static func _world_endpoint(point: Vector3) -> Dictionary:
	return {"worldPoint": {"x": point.x, "y": point.y, "z": point.z}}
