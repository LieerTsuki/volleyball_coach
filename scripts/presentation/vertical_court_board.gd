class_name VerticalCourtBoard
extends Control

signal player_moved(player_id: String, position: Vector3)
signal player_selected(player_id: String)
signal player_double_clicked(player_id: String)

var tactic: Dictionary = {}
var frame_index := 0
var selected_player_id := ""
var dragged_player_id := ""
var playback_time_ms := -1
var court_layout := VerticalCourtLayout.new()
var court_rect := Rect2()
var last_tap_player_id := ""
var last_tap_time_ms := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_refresh_layout)
	_refresh_layout()

func set_tactic(value: Dictionary) -> void:
	tactic = value
	frame_index = clampi(frame_index, 0, max(0, tactic.get("frames", []).size() - 1))
	_refresh_layout()

func set_frame(index: int) -> void:
	frame_index = clampi(index, 0, max(0, tactic.get("frames", []).size() - 1))
	selected_player_id = ""
	dragged_player_id = ""
	queue_redraw()

func set_playback_time(time_ms: int) -> void:
	playback_time_ms = time_ms
	queue_redraw()

func _refresh_layout() -> void:
	court_rect = court_layout.court_rect(size, 22.0, 34.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("1f5278"))
	draw_rect(court_rect.grow(6.0), Color("12324e"))
	draw_rect(court_rect, Color("e8a36a"))
	draw_rect(court_rect, Color("fff7e8"), false, 5.0)
	var center_y := court_rect.position.y + court_rect.size.y * 0.5
	draw_line(Vector2(court_rect.position.x, center_y), Vector2(court_rect.end.x, center_y), Color("fff7e8"), 4.0)
	draw_line(Vector2(court_rect.position.x, court_layout.attack_line_screen_y(court_rect, -1)), Vector2(court_rect.end.x, court_layout.attack_line_screen_y(court_rect, -1)), Color("fff7e8"), 4.0)
	draw_line(Vector2(court_rect.position.x, court_layout.attack_line_screen_y(court_rect, 1)), Vector2(court_rect.end.x, court_layout.attack_line_screen_y(court_rect, 1)), Color("fff7e8"), 4.0)
	draw_line(Vector2(court_rect.position.x, court_rect.position.y), Vector2(court_rect.end.x, court_rect.position.y), Color("fff7e8"), 4.0)
	draw_line(Vector2(court_rect.position.x, court_rect.end.y), Vector2(court_rect.end.x, court_rect.end.y), Color("fff7e8"), 4.0)
	draw_string(ThemeDB.fallback_font, court_rect.position + Vector2(18, 34), "对方场区", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(court_rect.position.x + 18, center_y + 34), "我方场区", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.92))
	_draw_players()

func _draw_players() -> void:
	if tactic.get("frames", []).is_empty():
		return
	var radius := clampf(court_rect.size.x * 0.052, 30.0, 48.0)
	for player in tactic.get("players", []):
		var player_id := str(player.get("id", ""))
		var position := FrameInterpolator.position_in_frame(tactic.get("frames", [])[frame_index], player_id)
		if playback_time_ms >= 0:
			position = FrameInterpolator.player_position(tactic, player_id, playback_time_ms)
		var screen_position := court_layout.world_to_screen(position, court_rect)
		var is_receiver := bool(player.get("isReceiver", false))
		var fill := Color("d83524") if not is_receiver else Color("5b9a3b")
		if player_id == selected_player_id:
			draw_circle(screen_position, radius + 10.0, Color(1, 1, 1, 0.38))
		draw_circle(screen_position, radius, fill)
		draw_arc(screen_position, radius, 0.0, TAU, 48, Color("fffaf0"), 4.0)
		draw_string(ThemeDB.fallback_font, screen_position + Vector2(-10, 10), str(player.get("jerseyNumber", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		var player_name := str(player.get("name", "球员 " + str(player.get("jerseyNumber", ""))))
		draw_string(ThemeDB.fallback_font, screen_position + Vector2(-42, radius + 28), player_name, HORIZONTAL_ALIGNMENT_LEFT, 90, 18, Color("fff6e5"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_player(event.position)
		else:
			dragged_player_id = ""
		accept_event()
	elif event is InputEventScreenDrag:
		_drag_player(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_player(event.position)
		else:
			dragged_player_id = ""
		accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_drag_player(event.position)
		accept_event()

func _press_player(screen_position: Vector2) -> void:
	if tactic.get("frames", []).is_empty():
		return
	var frame: Dictionary = tactic.get("frames", [])[frame_index]
	var hit_radius := clampf(court_rect.size.x * 0.052, 30.0, 48.0) + 30.0
	for player in tactic.get("players", []):
		var player_id := str(player.get("id", ""))
		var player_screen := court_layout.world_to_screen(FrameInterpolator.position_in_frame(frame, player_id), court_rect)
		if player_screen.distance_to(screen_position) <= hit_radius:
			selected_player_id = player_id
			dragged_player_id = player_id
			var now := Time.get_ticks_msec()
			if last_tap_player_id == player_id and now - last_tap_time_ms <= 380:
				player_double_clicked.emit(player_id)
			last_tap_player_id = player_id
			last_tap_time_ms = now
			player_selected.emit(player_id)
			queue_redraw()
			return

func _drag_player(screen_position: Vector2) -> void:
	if dragged_player_id.is_empty() or not court_rect.has_point(screen_position) or tactic.get("frames", []).is_empty():
		return
	var frame: Dictionary = tactic.get("frames", [])[frame_index]
	var positions: Dictionary = frame.get("positions", {})
	var point := court_layout.screen_to_world(screen_position, court_rect)
	positions[dragged_player_id] = {"x": point.x, "z": point.z}
	player_moved.emit(dragged_player_id, point)
	queue_redraw()
