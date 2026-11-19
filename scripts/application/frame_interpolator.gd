class_name FrameInterpolator

static func total_duration(tactic: Dictionary) -> int:
	var total := 0
	var frames: Array = tactic.get("frames", [])
	for frame in frames:
		total += max(1, int(frame.get("durationMs", 800)))
	return max(1, total)

static func frame_sample(frames: Array, time_ms: int) -> Dictionary:
	var elapsed := 0
	for index in range(frames.size()):
		var duration := maxi(1, int(frames[index].get("durationMs", 800)))
		if time_ms < elapsed + duration or index == frames.size() - 1:
			return {
				"index": index,
				"next": mini(index + 1, frames.size() - 1),
				"progress": clampf(float(time_ms - elapsed) / duration, 0.0, 1.0),
				"duration_ms": duration
			}
		elapsed += duration
	return {}

static func player_position(tactic: Dictionary, player_id: String, time_ms: int) -> Vector3:
	var frames: Array = tactic.get("frames", [])
	if frames.is_empty():
		return _legacy_position(tactic, player_id, time_ms)
	return player_motion(frames, player_id, frame_sample(frames, time_ms)).position

static func player_motion(frames: Array, player_id: String, sample: Dictionary) -> Dictionary:
	var start := position_in_frame(frames[sample.index], player_id)
	var end := position_in_frame(frames[sample.next], player_id)
	var direction := end - start
	return {"position": start + direction * float(sample.progress), "direction": direction}

static func ball_position(tactic: Dictionary, time_ms: int) -> Vector3:
	var frames: Array = tactic.get("frames", [])
	if frames.is_empty():
		return Vector3.ZERO
	var sample := frame_sample(frames, time_ms)
	return ball_position_in_frame(frames[sample.index]).lerp(ball_position_in_frame(frames[sample.next]), sample.progress)

static func position_in_frame(frame: Dictionary, player_id: String) -> Vector3:
	var positions: Dictionary = frame.get("positions", {})
	var point: Dictionary = positions.get(player_id, {})
	return Vector3(float(point.get("x", 0.0)), 0.0, float(point.get("z", 0.0)))

static func ball_position_in_frame(frame: Dictionary) -> Vector3:
	var point: Dictionary = frame.get("ball", {"x": 0.0, "z": 0.0})
	return Vector3(float(point.get("x", 0.0)), 0.0, float(point.get("z", 0.0)))

static func _legacy_position(tactic: Dictionary, player_id: String, time_ms: int) -> Vector3:
	var position := Vector3.ZERO
	for slot in tactic.get("initialFormation", []):
		if str(slot.get("playerId", "")) == player_id:
			position = Vector3(float(slot.get("x", 0.0)), 0.0, float(slot.get("z", 0.0)))
	for move in tactic.get("moveTracks", []):
		if str(move.get("playerId", "")) != player_id:
			continue
		var start := int(move.get("startMs", 0))
		var end := int(move.get("endMs", 0))
		var points: Array = move.get("waypoints", [])
		if points.is_empty():
			continue
		if time_ms < start:
			break
		var target: Dictionary = points.back()
		if time_ms >= end:
			position = Vector3(float(target.get("x", 0.0)), 0.0, float(target.get("z", 0.0)))
			continue
		var progress: float = clampf(float(time_ms - start) / maxf(1.0, float(end - start)), 0.0, 1.0)
		position = position.lerp(Vector3(float(target.get("x", 0.0)), 0.0, float(target.get("z", 0.0))), progress)
		break
	return position
