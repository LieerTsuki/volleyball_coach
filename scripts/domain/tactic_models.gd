class_name TacticModels

const PLAYER_ROLES := ["主攻", "副攻", "二传", "接应", "自由人"]

static func default_court() -> Dictionary:
	return {"widthM": 9.0, "lengthM": 18.0, "attackLineOffsetM": 3.0, "netHeightM": 2.43, "freeZoneM": 3.0}

static func sample_tactic() -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	return {
		"schemaVersion": 1, "id": "sample-three-receiver-fast-middle", "title": "三人接发 · 副攻快球掩护 · 四号位进攻", "notes": "Godot 内置可播放示例", "createdAt": now, "updatedAt": now,
		"courtConfig": default_court(),
		"players": [
			{"id":"p1","jerseyNumber":"1","role":"二传","isReceiver":false}, {"id":"p2","jerseyNumber":"2","role":"主攻","isReceiver":true}, {"id":"p3","jerseyNumber":"3","role":"副攻","isReceiver":false},
			{"id":"p4","jerseyNumber":"4","role":"主攻","isReceiver":true}, {"id":"p5","jerseyNumber":"5","role":"接应","isReceiver":false}, {"id":"p6","jerseyNumber":"6","role":"自由人","isReceiver":true}
		],
		"initialFormation": [
			{"playerId":"p1","x":2.8,"z":-2.6,"yawDeg":180.0}, {"playerId":"p2","x":-3.2,"z":-5.6,"yawDeg":160.0}, {"playerId":"p3","x":-1.1,"z":-2.0,"yawDeg":180.0},
			{"playerId":"p4","x":0.1,"z":-5.7,"yawDeg":180.0}, {"playerId":"p5","x":3.0,"z":-5.4,"yawDeg":200.0}, {"playerId":"p6","x":-2.1,"z":-7.2,"yawDeg":170.0}
		],
		"frames": _sample_frames(),
		"phases": [{"id":"phase-receive","label":"发球与一传","startMs":0},{"id":"phase-set","label":"二传组织","startMs":1700},{"id":"phase-attack","label":"进攻","startMs":2800}],
		"moveTracks": [
			{"id":"m-p1","playerId":"p1","startMs":700,"endMs":1700,"waypoints":[{"x":1.4,"y":0,"z":-1.2}],"facingMode":"FacePath"},
			{"id":"m-p2","playerId":"p2","startMs":700,"endMs":1700,"waypoints":[{"x":-2.4,"y":0,"z":-4.2}],"facingMode":"FacePath"},
			{"id":"m-p6","playerId":"p6","startMs":700,"endMs":1700,"waypoints":[{"x":-1.1,"y":0,"z":-5.4}],"facingMode":"FacePath"},
			{"id":"m-p3","playerId":"p3","startMs":1600,"endMs":2700,"waypoints":[{"x":-0.4,"y":0,"z":-0.5},{"x":-0.8,"y":0,"z":0.8}],"facingMode":"FaceTarget"},
			{"id":"m-p2-attack","playerId":"p2","startMs":2700,"endMs":3500,"waypoints":[{"x":-2.2,"y":0,"z":-1.0},{"x":-2.4,"y":0,"z":0.7}],"facingMode":"FaceTarget"}
		],
		"poseActions": [
			{"id":"pose-ready-2","playerId":"p2","type":"Ready","startMs":0,"endMs":700}, {"id":"pose-dig-2","playerId":"p2","type":"Dig","startMs":1300,"endMs":1900},
			{"id":"pose-set-1","playerId":"p1","type":"Set","startMs":2050,"endMs":2650}, {"id":"pose-cover-3","playerId":"p3","type":"JumpCover","startMs":2200,"endMs":3100},
			{"id":"pose-approach-2","playerId":"p2","type":"Approach","startMs":2700,"endMs":3150}, {"id":"pose-spike-2","playerId":"p2","type":"Spike","startMs":3150,"endMs":3650}
		],
		"contactEvents": [
			{"id":"c-pass","playerId":"p2","actionId":"pose-dig-2","timeMs":1700,"anchorType":"Forearms"}, {"id":"c-set","playerId":"p1","actionId":"pose-set-1","timeMs":2500,"anchorType":"OverheadHands"}, {"id":"c-spike","playerId":"p2","actionId":"pose-spike-2","timeMs":3350,"anchorType":"HittingHand"}
		],
		"ballActions": [
			{"id":"ball-serve","type":"Serve","startMs":700,"endMs":1700,"from":{"isContact":false,"worldPoint":{"x":4.7,"y":2.3,"z":9.6}},"to":{"isContact":true,"contactId":"c-pass"},"arcHeightM":2.2},
			{"id":"ball-pass","type":"Pass","startMs":1700,"endMs":2500,"from":{"isContact":true,"contactId":"c-pass"},"to":{"isContact":true,"contactId":"c-set"},"arcHeightM":1.3},
			{"id":"ball-set","type":"Set","startMs":2500,"endMs":3350,"from":{"isContact":true,"contactId":"c-set"},"to":{"isContact":true,"contactId":"c-spike"},"arcHeightM":2.7},
			{"id":"ball-spike","type":"Spike","startMs":3350,"endMs":3800,"from":{"isContact":true,"contactId":"c-spike"},"to":{"isContact":false,"worldPoint":{"x":2.8,"y":0.15,"z":4.5}},"arcHeightM":0.3}
		]
	}

static func ensure_frames(tactic: Dictionary) -> Dictionary:
	if not tactic.get("frames", []).is_empty():
		return tactic
	if str(tactic.get("id", "")) == "sample-three-receiver-fast-middle":
		tactic["frames"] = _sample_frames()
		return tactic
	var positions := {}
	for slot in tactic.get("initialFormation", []):
		positions[str(slot.get("playerId", ""))] = {"x": float(slot.get("x", 0.0)), "z": float(slot.get("z", 0.0))}
	tactic["frames"] = [{"id": "frame-0", "durationMs": 900, "positions": positions}]
	return tactic

static func _sample_frames() -> Array[Dictionary]:
	return [
		{"id": "frame-0", "durationMs": 800, "positions": {
			"p1": {"x": 2.8, "z": -2.6}, "p2": {"x": -3.2, "z": -5.6}, "p3": {"x": -1.1, "z": -2.0},
			"p4": {"x": 0.1, "z": -5.7}, "p5": {"x": 3.0, "z": -5.4}, "p6": {"x": -2.1, "z": -7.2}
		}},
		{"id": "frame-1", "durationMs": 900, "positions": {
			"p1": {"x": 1.4, "z": -1.2}, "p2": {"x": -2.4, "z": -4.2}, "p3": {"x": -1.1, "z": -2.0},
			"p4": {"x": 0.1, "z": -5.7}, "p5": {"x": 3.0, "z": -5.4}, "p6": {"x": -1.1, "z": -5.4}
		}},
		{"id": "frame-2", "durationMs": 900, "positions": {
			"p1": {"x": 1.4, "z": -1.2}, "p2": {"x": -2.4, "z": -4.2}, "p3": {"x": -0.4, "z": -0.5},
			"p4": {"x": 0.1, "z": -5.7}, "p5": {"x": 3.0, "z": -5.4}, "p6": {"x": -1.1, "z": -5.4}
		}},
		{"id": "frame-3", "durationMs": 900, "positions": {
			"p1": {"x": 1.4, "z": -1.2}, "p2": {"x": -2.2, "z": -1.0}, "p3": {"x": -0.8, "z": 0.8},
			"p4": {"x": 0.1, "z": -5.7}, "p5": {"x": 3.0, "z": -5.4}, "p6": {"x": -1.1, "z": -5.4}
		}},
		{"id": "frame-4", "durationMs": 700, "positions": {
			"p1": {"x": 1.4, "z": -1.2}, "p2": {"x": -2.4, "z": 0.7}, "p3": {"x": -0.8, "z": 0.8},
			"p4": {"x": 0.1, "z": -5.7}, "p5": {"x": 3.0, "z": -5.4}, "p6": {"x": -1.1, "z": -5.4}
		}}
	]
