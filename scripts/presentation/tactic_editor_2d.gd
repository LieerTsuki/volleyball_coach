class_name TacticEditor2D
extends Control

signal replay_requested
signal save_requested
signal document_changed

var tactic: Dictionary = {}
var selected_frame := 0
var board: VerticalCourtBoard
var frame_strip: HBoxContainer
var status_label: Label
var title_label: Label
var play_button: Button
var playing := false
var status_message := "拖动球员圆点调整站位"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()

func set_tactic(value: Dictionary) -> void:
	tactic = TacticModels.ensure_frames(value)
	selected_frame = clampi(selected_frame, 0, max(0, tactic.get("frames", []).size() - 1))
	if board:
		board.set_tactic(tactic)
		board.set_frame(selected_frame)
	_refresh_frame_strip()
	_update_status("拖动球员圆点调整第 %d 张" % (selected_frame + 1))

func _build_layout() -> void:
	var background := ColorRect.new()
	background.color = Color("153d5c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 126)
	header.add_theme_stylebox_override("panel", _panel_style(Color("07131d"), Color("284b62"), 0))
	root.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 18)
	header.add_child(header_row)
	var back := _button("‹", 92, _back_pressed)
	header_row.add_child(back)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_box)
	title_label = Label.new()
	title_label.text = "排球战术板"
	title_label.add_theme_font_size_override("font_size", 30)
	title_box.add_child(title_label)
	var subtitle := Label.new()
	subtitle.text = "2D 站位编排"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("a8c0ce"))
	title_box.add_child(subtitle)
	var save_button := _button("保存", 132, _save)
	header_row.add_child(save_button)

	var board_panel := PanelContainer.new()
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel", _panel_style(Color("1f5278"), Color("316d93"), 0))
	root.add_child(board_panel)
	board = VerticalCourtBoard.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_panel.add_child(board)
	board.player_moved.connect(_on_player_moved)
	board.player_selected.connect(_on_player_selected)

	var frames_panel := PanelContainer.new()
	frames_panel.custom_minimum_size = Vector2(0, 162)
	frames_panel.add_theme_stylebox_override("panel", _panel_style(Color("0e2738"), Color("284b62"), 0))
	root.add_child(frames_panel)
	var frames_column := VBoxContainer.new()
	frames_column.add_theme_constant_override("separation", 8)
	frames_panel.add_child(frames_column)
	var frames_title := Label.new()
	frames_title.text = "站位图序列"
	frames_title.add_theme_font_size_override("font_size", 20)
	frames_column.add_child(frames_title)
	var frame_scroll := ScrollContainer.new()
	frame_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	frame_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frames_column.add_child(frame_scroll)
	frame_strip = HBoxContainer.new()
	frame_strip.add_theme_constant_override("separation", 12)
	frame_scroll.add_child(frame_strip)

	var toolbar := PanelContainer.new()
	toolbar.custom_minimum_size = Vector2(0, 330)
	toolbar.add_theme_stylebox_override("panel", _panel_style(Color("07131d"), Color("284b62"), 0))
	root.add_child(toolbar)
	var toolbar_column := VBoxContainer.new()
	toolbar_column.add_theme_constant_override("separation", 12)
	toolbar.add_child(toolbar_column)
	status_label = Label.new()
	status_label.text = status_message
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color("d7e5ea"))
	toolbar_column.add_child(status_label)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	toolbar_column.add_child(grid)
	grid.add_child(_button("＋ 添加球员", 0, _add_player))
	grid.add_child(_button("下一张", 0, _next_frame))
	play_button = _button("播放 2D", 0, _toggle_play)
	grid.add_child(play_button)
	grid.add_child(_button("重播", 0, _restart_preview))
	grid.add_child(_button("进入 3D", 0, _open_replay))
	grid.add_child(_button("删除球员", 0, _delete_selected_player))
	for child in grid.get_children():
		child.custom_minimum_size = Vector2(0, 86)

func _button(text: String, width: int, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width if width > 0 else 0, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	return button

func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

func _refresh_frame_strip() -> void:
	if not frame_strip:
		return
	for child in frame_strip.get_children():
		child.queue_free()
	for index in range(tactic.get("frames", []).size()):
		var frame: Dictionary = tactic.get("frames", [])[index]
		var button := Button.new()
		button.text = "第 %d 张\n%d ms" % [index + 1, int(frame.get("durationMs", 800))]
		button.custom_minimum_size = Vector2(148, 82)
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(func(): _select_frame(index))
		frame_strip.add_child(button)

func _select_frame(index: int) -> void:
	selected_frame = index
	playing = false
	if play_button:
		play_button.text = "播放 2D"
	board.set_frame(selected_frame)
	_refresh_frame_strip()
	_update_status("已选择第 %d 张站位图" % (selected_frame + 1))

func _on_player_selected(player_id: String) -> void:
	_update_status("已选择球员 %s，可拖动调整位置" % player_id)

func _on_player_moved(player_id: String, position: Vector3) -> void:
	document_changed.emit()
	_update_status("球员 %s 位置 %.1fm / %.1fm" % [player_id, position.x, position.z])

func _next_frame() -> void:
	var frames: Array = tactic.get("frames", [])
	if frames.is_empty():
		return
	var copy: Dictionary = JSON.parse_string(JSON.stringify(frames[selected_frame]))
	copy["id"] = "frame-%d" % frames.size()
	copy["durationMs"] = 800
	frames.append(copy)
	_select_frame(frames.size() - 1)
	document_changed.emit()
	_update_status("已复制上一张，拖动需要跑位的球员")

func _add_player() -> void:
	var players: Array = tactic.get("players", [])
	var number := players.size() + 1
	var player_id := "p%d" % number
	players.append({"id": player_id, "jerseyNumber": str(number), "name": "球员 %d" % number, "role": "主攻", "isReceiver": false})
	for frame in tactic.get("frames", []):
		var positions: Dictionary = frame.get("positions", {})
		positions[player_id] = {"x": 0.0, "z": -6.5}
	board.set_tactic(tactic)
	document_changed.emit()
	_update_status("已添加球员 %d" % number)

func _delete_selected_player() -> void:
	_update_status("请先点击要删除的球员")

func _toggle_play() -> void:
	playing = not playing
	play_button.text = "暂停 2D" if playing else "播放 2D"
	_update_status("2D 预览已%s" % ("开始" if playing else "暂停"))

func _restart_preview() -> void:
	playing = true
	play_button.text = "暂停 2D"
	_update_status("2D 预览从第 1 张开始")

func _open_replay() -> void:
	replay_requested.emit()

func _save() -> void:
	tactic.updatedAt = Time.get_datetime_string_from_system(true)
	save_requested.emit()
	_update_status("战术已保存")

func _back_pressed() -> void:
	_update_status("当前已是战术编辑首页")

func _update_status(text: String) -> void:
	status_message = text
	if status_label:
		status_label.text = status_message
