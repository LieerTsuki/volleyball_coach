class_name FrameInterpolator

static func total_duration(tactic: Dictionary) -> int:
	var total := 0
	var frames: Array = tactic.get("frames", [])
	for frame in frames:
		total += max(1, int(frame.get("durationMs", 800)))
	return max(1, total)

static func player_position(tactic: Dictionary, player_id: String, time_ms: int) -> Vector3:
	var frames: Array = tactic.get("frames", [])
	if frames.is_empty():
		return _legacy_position(tactic, player_id, time_ms)
	var elapsed := 0
	var clamped_time := clampi(time_ms, 0, total_duration(tactic))
	for index in range(max(0, frames.size() - 1)):
		var frame: Dictionary = frames[index]
		var duration: int = maxi(1, int(frame.get("durationMs", 800)))
		if clamped_time <= elapsed + duration:
			var start := position_in_frame(frame, player_id)
			var end := position_in_frame(frames[index + 1], player_id)
			var progress: float = clampf(float(clamped_time - elapsed) / float(duration), 0.0, 1.0)
			var routes: Dictionary = frame.get("routes", {})
			if routes.has(player_id):
				return _sample_route(routes[player_id], progress, start, end)
			return start.lerp(end, progress)
		elapsed += duration
	return position_in_frame(frames.back(), player_id)

static func ball_position(tactic: Dictionary, time_ms: int) -> Vector3:
	var frames: Array = tactic.get("frames", [])
	if frames.is_empty():
		return Vector3.ZERO
	var elapsed := 0
	var clamped_time := clampi(time_ms, 0, total_duration(tactic))
	for index in range(max(0, frames.size() - 1)):
		var frame: Dictionary = frames[index]
		var duration: int = maxi(1, int(frame.get("durationMs", 800)))
		if clamped_time <= elapsed + duration:
			var start := _ball_in_frame(frame)
			var end := _ball_in_frame(frames[index + 1])
			var progress: float = clampf(float(clamped_time - elapsed) / float(duration), 0.0, 1.0)
			return start.lerp(end, progress)
		elapsed += duration
	return _ball_in_frame(frames.back())

static func position_in_frame(frame: Dictionary, player_id: String) -> Vector3:
	var positions: Dictionary = frame.get("positions", {})
	var point: Dictionary = positions.get(player_id, {})
	return Vector3(float(point.get("x", 0.0)), 0.0, float(point.get("z", 0.0)))

static func _ball_in_frame(frame: Dictionary) -> Vector3:
	var point: Dictionary = frame.get("ball", {"x": 0.0, "z": 0.0})
	return Vector3(float(point.get("x", 0.0)), 0.0, float(point.get("z", 0.0)))

static func _sample_route(route: Array, progress: float, start: Vector3, end: Vector3) -> Vector3:
	if route.size() < 2:
		return start.lerp(end, progress)
	var points: Array[Vector3] = []
	for value in route:
		var point: Dictionary = value
		points.append(Vector3(float(point.get("x", 0.0)), 0.0, float(point.get("z", 0.0))))
	if points.front().distance_to(start) > 0.8:
		points.push_front(start)
	if points.back().distance_to(end) > 0.8:
		points.append(end)
	var segment_length := 0.0
	for index in range(points.size() - 1):
		segment_length += points[index].distance_to(points[index + 1])
	if segment_length <= 0.001:
		return start.lerp(end, progress)
	var target_distance := segment_length * progress
	var walked := 0.0
	for index in range(points.size() - 1):
		var length := points[index].distance_to(points[index + 1])
		if target_distance <= walked + length:
			var local := (target_distance - walked) / maxf(length, 0.001)
			return points[index].lerp(points[index + 1], local)
		walked += length
	return points.back()

static func frame_position_map(frame: Dictionary) -> Dictionary:
	return frame.get("positions", {})

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
