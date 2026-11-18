class_name TacticEditor2D
extends Control

signal replay_requested
signal save_requested
signal document_changed

var tactic: Dictionary = {}
var selected_frame := 0
var selected_player_id := ""
var dragged_player_id := ""
var playback_ms := 0.0
var playing := false
var court_rect := Rect2()
var title_label: Label
var status_label: Label
var frame_label: Label
var timeline: HSlider
var action_buttons: Array[Button] = []

const TOP_BAR := 82.0
const BOTTOM_BAR := 142.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_layout_controls)
	_build_controls()
	_layout_controls()

func set_tactic(value: Dictionary) -> void:
	tactic = TacticModels.ensure_frames(value)
	selected_frame = clampi(selected_frame, 0, max(0, tactic.get("frames", []).size() - 1))
	playback_ms = 0.0
	playing = false
	_update_controls()
	queue_redraw()

func _process(delta: float) -> void:
	if playing:
		playback_ms += delta * 1000.0
		if playback_ms >= FrameInterpolator.total_duration(tactic):
			playback_ms = 0.0
		queue_redraw()
		if timeline:
			timeline.set_value_no_signal(playback_ms)

func _build_controls() -> void:
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	add_child(title_label)

	var add_button := _make_button("＋球员", _add_player)
	var next_button := _make_button("下一张", _next_frame)
	var play_button := _make_button("播放 2D", _toggle_play)
	var reset_button := _make_button("重播", _replay)
	var replay_button := _make_button("进入 3D", _open_replay)
	var save_button := _make_button("保存", _save)
	action_buttons = [add_button, next_button, play_button, reset_button, replay_button, save_button]

	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color("9fb4c0"))
	status_label.add_theme_font_size_override("font_size", 18)
	add_child(status_label)
	frame_label = Label.new()
	frame_label.add_theme_font_size_override("font_size", 20)
	add_child(frame_label)

	timeline = HSlider.new()
	timeline.min_value = 0.0
	timeline.step = 10.0
	timeline.value_changed.connect(_on_timeline_changed)
	add_child(timeline)

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(118, 46)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	add_child(button)
	return button

func _layout_controls() -> void:
	if not title_label:
		return
	title_label.position = Vector2(24, 18)
	title_label.size = Vector2(310, 48)
	var x := 330.0
	for button in action_buttons:
		button.position = Vector2(x, 16)
		button.size = Vector2(118, 46)
		x += 126.0
	status_label.position = Vector2(max(24.0, size.x - 370.0), 24)
	status_label.size = Vector2(340, 38)
	frame_label.position = Vector2(24, size.y - 112)
	frame_label.size = Vector2(122, 40)
	timeline.position = Vector2(190, size.y - 56)
	timeline.size = Vector2(max(260.0, size.x - 420.0), 34)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("071017"))
	draw_rect(Rect2(0, 0, size.x, TOP_BAR), Color("101f29"))
	draw_rect(Rect2(0, size.y - BOTTOM_BAR, size.x, BOTTOM_BAR), Color("0d1a22"))
	_draw_court()
	_draw_paths()
	_draw_players()
	_draw_frame_strip()

func _draw_court() -> void:
	court_rect = _calculate_court_rect()
	draw_rect(court_rect.grow(10.0), Color("172b32"))
	draw_rect(court_rect, Color("d98a50"))
	draw_rect(court_rect, Color("f8e6d1"), false, 4.0)
	var center_y := court_rect.position.y + court_rect.size.y * 0.5
	draw_line(Vector2(court_rect.position.x, center_y), Vector2(court_rect.end.x, center_y), Color("fff6e7"), 3.0)
	var attack_offset := court_rect.size.y * 3.0 / 18.0
	draw_line(Vector2(court_rect.position.x, center_y - attack_offset), Vector2(court_rect.end.x, center_y - attack_offset), Color("fff6e7"), 3.0)
	draw_line(Vector2(court_rect.position.x, center_y + attack_offset), Vector2(court_rect.end.x, center_y + attack_offset), Color("fff6e7"), 3.0)
	draw_line(Vector2(court_rect.position.x + court_rect.size.x * 0.5, court_rect.position.y), Vector2(court_rect.position.x + court_rect.size.x * 0.5, court_rect.end.y), Color("fff6e7"), 2.0)
	draw_string(ThemeDB.fallback_font, court_rect.position + Vector2(16, 30), "对方场区", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(court_rect.position.x + 16, center_y + 28), "我方场区", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.85))

func _draw_paths() -> void:
	var frames: Array = tactic.get("frames", [])
	if frames.size() < 2:
		return
	var frame: Dictionary = frames[selected_frame]
	var next_index: int = mini(selected_frame + 1, frames.size() - 1)
	var next_frame: Dictionary = frames[next_index]
	for player in tactic.get("players", []):
		var player_id := str(player.get("id", ""))
		var start := _court_to_screen(FrameInterpolator.position_in_frame(frame, player_id))
		var end := _court_to_screen(FrameInterpolator.position_in_frame(next_frame, player_id))
		if start.distance_to(end) < 2.0:
			continue
		var is_selected := player_id == selected_player_id
		var path_color := Color("f5f7ff") if is_selected else Color(1, 1, 1, 0.5)
		draw_dashed_line(start, end, path_color, 4.0 if is_selected else 2.0, 8.0)
		var direction := (end - start).normalized()
		var side := Vector2(-direction.y, direction.x)
		var arrow := PackedVector2Array([end, end - direction * 16.0 + side * 7.0, end - direction * 16.0 - side * 7.0])
		draw_colored_polygon(arrow, path_color)

func _draw_players() -> void:
	var radius := clampf(court_rect.size.x * 0.035, 20.0, 32.0)
	for player in tactic.get("players", []):
		var player_id := str(player.get("id", ""))
		var position: Vector3
		if playing:
			position = FrameInterpolator.player_position(tactic, player_id, roundi(playback_ms))
		else:
			position = FrameInterpolator.position_in_frame(tactic.get("frames", [])[selected_frame], player_id)
		var screen_position := _court_to_screen(position)
		var receiver := bool(player.get("isReceiver", false))
		var color := Color("5a963e") if receiver else Color("b92345")
		if player_id == selected_player_id:
			draw_circle(screen_position, radius + 7.0, Color(1, 1, 1, 0.32))
		draw_circle(screen_position, radius, color)
		draw_arc(screen_position, radius, 0.0, TAU, 40, Color("fff8e9"), 3.0)
		draw_string(ThemeDB.fallback_font, screen_position + Vector2(-8, 8), str(player.get("jerseyNumber", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
		draw_string(ThemeDB.fallback_font, screen_position + Vector2(-26, radius + 22), "球员 " + str(player.get("jerseyNumber", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f4e6d8"))

func _draw_frame_strip() -> void:
	var frames: Array = tactic.get("frames", [])
	var card_width := 78.0
	var start_x := 150.0
	var y := size.y - 112.0
	for index in range(frames.size()):
		var rect := Rect2(start_x + index * (card_width + 10.0), y, card_width, 54.0)
		var color := Color("e8b35a") if index == selected_frame else Color("243a44")
		draw_rect(rect, color)
		draw_rect(rect, Color("fff4dc"), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 23), "第 %d 张" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("071017") if index == selected_frame else Color("d9e8ed"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 43), "%d ms" % int(frames[index].get("durationMs", 800)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("071017") if index == selected_frame else Color("9fb4c0"))

func _calculate_court_rect() -> Rect2:
	var available_width: float = maxf(320.0, size.x - 360.0)
	var available_height: float = maxf(240.0, size.y - TOP_BAR - BOTTOM_BAR - 28.0)
	var width: float = minf(available_width, available_height * 2.0)
	var height: float = width * 0.5
	var left: float = 160.0
	var top: float = TOP_BAR + (available_height - height) * 0.5
	return Rect2(left, top, width, height)

func _court_to_screen(position: Vector3) -> Vector2:
	var x := court_rect.position.x + (position.x + 4.5) / 9.0 * court_rect.size.x
	var y := court_rect.position.y + (position.z + 9.0) / 18.0 * court_rect.size.y
	return Vector2(x, y)

func _screen_to_court(screen_position: Vector2) -> Vector3:
	var x := (screen_position.x - court_rect.position.x) / court_rect.size.x * 9.0 - 4.5
	var z := (screen_position.y - court_rect.position.y) / court_rect.size.y * 18.0 - 9.0
	return Vector3(clampf(x, -4.35, 4.35), 0.0, clampf(z, -8.85, 8.85))

func _handle_press(screen_position: Vector2) -> void:
	if _select_frame_at(screen_position):
		return
	if playing:
		return
	var frame: Dictionary = tactic.get("frames", [])[selected_frame]
	for player in tactic.get("players", []):
		var player_id := str(player.get("id", ""))
		var player_position := _court_to_screen(FrameInterpolator.position_in_frame(frame, player_id))
		if player_position.distance_to(screen_position) <= 38.0:
			selected_player_id = player_id
			dragged_player_id = player_id
			queue_redraw()
			return

func _handle_release() -> void:
	dragged_player_id = ""

func _handle_drag(screen_position: Vector2) -> void:
	if dragged_player_id.is_empty() or playing or not court_rect.has_point(screen_position):
		return
	var frame: Dictionary = tactic.get("frames", [])[selected_frame]
	var positions: Dictionary = frame.get("positions", {})
	var point := _screen_to_court(screen_position)
	positions[dragged_player_id] = {"x": point.x, "z": point.z}
	document_changed.emit()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_press(event.position)
		else:
			_handle_release()
		accept_event()
	elif event is InputEventScreenDrag:
		_handle_drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_press(event.position)
		else:
			_handle_release()
		accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_handle_drag(event.position)
		accept_event()

func _select_frame_at(screen_position: Vector2) -> bool:
	var frames: Array = tactic.get("frames", [])
	var y := size.y - 112.0
	if screen_position.y < y or screen_position.y > y + 54.0:
		return false
	var index := int((screen_position.x - 150.0) / 88.0)
	if index >= 0 and index < frames.size():
		selected_frame = index
		playing = false
		playback_ms = _time_before_frame(index)
		_update_controls()
		queue_redraw()
	return true

func _time_before_frame(index: int) -> int:
	var result := 0
	var frames: Array = tactic.get("frames", [])
	for i in range(min(index, frames.size())):
		result += max(1, int(frames[i].get("durationMs", 800)))
	return result

func _next_frame() -> void:
	var frames: Array = tactic.get("frames", [])
	if frames.is_empty():
		return
	var copy: Dictionary = JSON.parse_string(JSON.stringify(frames[selected_frame]))
	copy["id"] = "frame-%d" % frames.size()
	copy["durationMs"] = 800
	frames.append(copy)
	selected_frame = frames.size() - 1
	document_changed.emit()
	_update_controls()
	queue_redraw()

func _add_player() -> void:
	var players: Array = tactic.get("players", [])
	var next_number := players.size() + 1
	var player_id := "p%d" % next_number
	players.append({"id": player_id, "jerseyNumber": str(next_number), "role": "主攻", "isReceiver": false})
	for frame in tactic.get("frames", []):
		var positions: Dictionary = frame.get("positions", {})
		positions[player_id] = {"x": 0.0, "z": -6.8}
	selected_player_id = player_id
	document_changed.emit()
	_update_status("已添加球员 %s，可直接拖动" % next_number)
	queue_redraw()

func _toggle_play() -> void:
	playing = not playing
	_update_controls()
	queue_redraw()

func _replay() -> void:
	playback_ms = 0.0
	playing = true
	_update_controls()
	queue_redraw()

func _on_timeline_changed(value: float) -> void:
	playback_ms = value
	playing = false
	queue_redraw()

func _open_replay() -> void:
	replay_requested.emit()

func _save() -> void:
	tactic.updatedAt = Time.get_datetime_string_from_system(true)
	save_requested.emit()
	_update_status("已保存当前关键帧战术")

func _update_controls() -> void:
	if not timeline:
		return
	timeline.max_value = FrameInterpolator.total_duration(tactic)
	timeline.value = playback_ms
	if action_buttons.size() >= 3:
		action_buttons[2].text = "暂停 2D" if playing else "播放 2D"
	if frame_label:
		frame_label.text = "关键帧 %d / %d" % [selected_frame + 1, tactic.get("frames", []).size()]
	_update_status("拖动球员圆点调整第 %d 张" % (selected_frame + 1))

func _update_status(text: String) -> void:
	if status_label:
		status_label.text = text
