class_name TacticValidator

static func validate(tactic: Dictionary, require_playable := false) -> Array[String]:
	var issues: Array[String] = []
	if tactic.is_empty(): return ["战术数据为空。"]
	if int(tactic.get("schemaVersion", 0)) != 1: issues.append("战术版本不是当前支持的版本。")
	var players: Array = tactic.get("players", [])
	var player_ids: Dictionary = {}
	for player in players:
		var id := str(player.get("id", ""))
		if id.is_empty() or player_ids.has(id): issues.append("球员 ID 存在空值或重复。")
		player_ids[id] = true
	for move in tactic.get("moveTracks", []):
		if not player_ids.has(str(move.get("playerId", ""))): issues.append("跑位引用了不存在的球员。")
		if int(move.get("endMs", 0)) <= int(move.get("startMs", 0)): issues.append("跑位时间必须递增。")
		if move.get("waypoints", []).is_empty(): issues.append("跑位缺少目标点。")
	for pose in tactic.get("poseActions", []):
		if not player_ids.has(str(pose.get("playerId", ""))): issues.append("动作引用了不存在的球员。")
		if int(pose.get("endMs", 0)) <= int(pose.get("startMs", 0)): issues.append("动作时间必须递增。")
	if require_playable and tactic.get("contactEvents", []).is_empty(): issues.append("可回放战术至少需要一个触球事件。")
	if require_playable and tactic.get("ballActions", []).is_empty(): issues.append("可回放战术至少需要一段球路。")
	return issues
