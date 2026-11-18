class_name TacticEditor2D
extends Control

signal replay_requested
signal save_requested
signal document_changed

var tactic: Dictionary = {}
var repository: TacticRepository
var selected_frame := 0
var board: VerticalCourtBoard
var frame_strip: HBoxContainer
var status_label: Label
var title_label: Label
var subtitle_label: Label
var play_button: Button
var playing := false
var status_message := "拖动球员圆点调整站位"
var library_overlay: PanelContainer
var player_overlay: PanelContainer
var player_number_input: LineEdit
var player_name_input: LineEdit
var library_list: VBoxContainer
var player_role_input: OptionButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	set_process(true)

func _process(delta: float) -> void:
	if not playing or tactic.is_empty() or not board:
		return
	var duration: int = FrameInterpolator.total_duration(tactic)
	var current: int = board.playback_time_ms if board.playback_time_ms >= 0 else 0
	current += roundi(delta * 1000.0 * 0.55)
	if current >= duration:
		current = 0
	board.set_playback_time(current)


func set_repository(value: TacticRepository) -> void:
	repository = value

func set_tactic(value: Dictionary) -> void:
	tactic = TacticModels.ensure_frames(value)
	selected_frame = clampi(selected_frame, 0, max(0, tactic.get("frames", []).size() - 1))
	if board:
		board.set_tactic(tactic)
		board.set_frame(selected_frame)
	if title_label:
		title_label.text = "球阵绘"
	if subtitle_label:
		subtitle_label.text = "当前战术 · " + str(tactic.get("title", "未命名战术"))
	_refresh_frame_strip()
	_update_status("拖动球员圆点调整第 %d 张" % (selected_frame + 1))

func _build_layout() -> void:
	var background := ColorRect.new()
	background.color = Color("fff6df")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 126)
	header.add_theme_stylebox_override("panel", _panel_style(Color("fff6df"), Color("18aeb4"), 0))
	root.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 18)
	header.add_child(header_row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_box)
	title_label = Label.new()
	title_label.text = "球阵绘"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color("102b45"))
	title_box.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.text = "2D 站位编排"
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color("ef755a"))
	title_box.add_child(subtitle_label)
	var library_button := _icon_button("res://assets/ui/library.svg", "战术库", _open_library)
	library_button.text = "战术库"
	library_button.custom_minimum_size = Vector2(148, 76)
	header_row.add_child(library_button)
	var save_button := _icon_button("res://assets/ui/save.svg", "保存", _save)
	save_button.text = "保存"
	save_button.custom_minimum_size = Vector2(132, 76)
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
	board.player_double_clicked.connect(_open_player_editor_by_id)
	board.ball_moved.connect(_on_ball_moved)

	var frames_panel := PanelContainer.new()
	frames_panel.custom_minimum_size = Vector2(0, 162)
	frames_panel.add_theme_stylebox_override("panel", _panel_style(Color("fff6df"), Color("18aeb4"), 0))
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
	toolbar.add_theme_stylebox_override("panel", _panel_style(Color("fff6df"), Color("18aeb4"), 0))
	root.add_child(toolbar)
	var toolbar_column := VBoxContainer.new()
	toolbar_column.add_theme_constant_override("separation", 12)
	toolbar.add_child(toolbar_column)
	status_label = Label.new()
	status_label.text = status_message
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color("102b45"))
	toolbar_column.add_child(status_label)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	toolbar_column.add_child(grid)
	grid.add_child(_icon_button("res://assets/ui/player.svg", "增加球员", _add_player))
	grid.add_child(_icon_button("res://assets/ui/plus_frame.svg", "新增站位图", _next_frame))
	play_button = _button("播放 2D", 0, _toggle_play)
	play_button.icon = load("res://assets/ui/play.svg")
	play_button.text = ""
	play_button.tooltip_text = "播放 2D"
	grid.add_child(play_button)
	grid.add_child(_icon_button("res://assets/ui/trash.svg", "删除站位图", _delete_frame))
	grid.add_child(_icon_button("res://assets/ui/play_3d.svg", "进入 3D 回放", _open_replay))
	for child in grid.get_children():
		child.custom_minimum_size = Vector2(0, 96)

func _button(text: String, width: int, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width if width > 0 else 0, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("fffaf0"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color("f08a5d"), Color("ffd166")))
	button.add_theme_stylebox_override("hover", _button_style(Color("ff9f68"), Color("fff0a8")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("d95f59"), Color("fff0a8")))
	button.pressed.connect(callback)
	return button

func _icon_button(icon_path: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.icon = load(icon_path)
	button.text = ""
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(88, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", _icon_hover_style(Color(0.12, 0.68, 0.71, 0.22)))
	button.add_theme_stylebox_override("pressed", _icon_hover_style(Color(0.94, 0.47, 0.36, 0.34)))
	button.pressed.connect(callback)
	return button

func _icon_hover_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = 46
	style.corner_radius_top_right = 46
	style.corner_radius_bottom_left = 46
	style.corner_radius_bottom_right = 46
	return style

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 5
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

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
		button.add_theme_stylebox_override("normal", _button_style(Color("274e62"), Color("75c9c8")))
		button.add_theme_stylebox_override("hover", _button_style(Color("3d7180"), Color("ffd166")))
		button.add_theme_stylebox_override("pressed", _button_style(Color("d95f59"), Color("fff0a8")))
		button.pressed.connect(func(): _select_frame(index))
		frame_strip.add_child(button)

func _select_frame(index: int) -> void:
	selected_frame = index
	playing = false
	if play_button:
		play_button.text = "播放 2D"
	board.set_frame(selected_frame)
	board.set_playback_time(-1)
	_refresh_frame_strip()
	_update_status("已选择第 %d 张站位图" % (selected_frame + 1))

func _on_player_selected(player_id: String) -> void:
	_update_status("已选择球员 %s，可拖动调整位置" % player_id)

func _on_player_moved(player_id: String, position: Vector3) -> void:
	var frames: Array = tactic.get("frames", [])
	if selected_frame < frames.size():
		var routes: Dictionary = frames[selected_frame].get("routes", {})
		routes.erase(player_id)
	document_changed.emit()
	_update_status("球员 %s 位置 %.1fm / %.1fm" % [player_id, position.x, position.z])

func _on_ball_moved(position: Vector3) -> void:
	document_changed.emit()
	_update_status("排球位置 %.1fm / %.1fm" % [position.x, position.z])

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
	board.selected_player_id = player_id
	board.set_tactic(tactic)
	document_changed.emit()
	_update_status("已添加球员 %d，可点击编辑球员修改号码和姓名" % number)

func _delete_selected_player() -> void:
	var player_id := board.selected_player_id if board else ""
	if player_id.is_empty():
		_update_status("请先点击要删除的球员")
		return
	for index in range(tactic.get("players", []).size()):
		if str(tactic.players[index].get("id", "")) == player_id:
			tactic.players.remove_at(index)
			break
	for frame in tactic.get("frames", []):
		var positions: Dictionary = frame.get("positions", {})
		positions.erase(player_id)
	board.selected_player_id = ""
	board.set_tactic(tactic)
	document_changed.emit()
	_update_status("已删除球员 %s" % player_id)

func _delete_frame() -> void:
	var frames: Array = tactic.get("frames", [])
	if frames.size() <= 1:
		_update_status("至少保留一张站位图")
		return
	frames.remove_at(selected_frame)
	selected_frame = mini(selected_frame, frames.size() - 1)
	board.set_tactic(tactic)
	board.set_frame(selected_frame)
	_refresh_frame_strip()
	document_changed.emit()
	_update_status("已删除当前站位图")

func _toggle_play() -> void:
	playing = not playing
	board.set_playback_time(0 if playing else -1)
	play_button.text = ""
	play_button.tooltip_text = "暂停 2D" if playing else "播放 2D"
	_update_status("2D 预览已%s" % ("开始" if playing else "暂停"))

func _restart_preview() -> void:
	playing = true
	board.set_playback_time(0)
	play_button.text = ""
	play_button.tooltip_text = "暂停 2D"
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

func _open_player_editor() -> void:
	var player_id := board.selected_player_id if board else ""
	if player_id.is_empty():
		_update_status("请先点击球员，再编辑资料")
		return
	var player: Dictionary = {}
	for candidate in tactic.get("players", []):
		if str(candidate.get("id", "")) == player_id:
			player = candidate
			break
	if player.is_empty():
		return
	_ensure_player_overlay()
	player_number_input.text = str(player.get("jerseyNumber", ""))
	player_name_input.text = str(player.get("name", "球员"))
	player_role_input.select(max(0, TacticModels.PLAYER_ROLES.find(str(player.get("role", "主攻")))))
	player_overlay.visible = true
	player_overlay.position = Vector2((size.x - player_overlay.size.x) * 0.5, (size.y - player_overlay.size.y) * 0.5)

func _open_player_editor_by_id(player_id: String) -> void:
	if board:
		board.selected_player_id = player_id
	_open_player_editor()

func _ensure_player_overlay() -> void:
	if player_overlay:
		return
	player_overlay = PanelContainer.new()
	player_overlay.custom_minimum_size = Vector2(760, 560)
	player_overlay.size = Vector2(760, 560)
	player_overlay.z_index = 60
	player_overlay.add_theme_stylebox_override("panel", _panel_style(Color("16384c"), Color("ffd166"), 30))
	add_child(player_overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	player_overlay.add_child(column)
	var heading := Label.new()
	heading.text = "编辑球员资料"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	column.add_child(heading)
	player_number_input = LineEdit.new()
	player_number_input.placeholder_text = "号码"
	player_number_input.custom_minimum_size = Vector2(0, 70)
	player_number_input.add_theme_font_size_override("font_size", 24)
	column.add_child(player_number_input)
	player_name_input = LineEdit.new()
	player_name_input.placeholder_text = "姓名"
	player_name_input.custom_minimum_size = Vector2(0, 70)
	player_name_input.add_theme_font_size_override("font_size", 24)
	column.add_child(player_name_input)
	player_role_input = OptionButton.new()
	player_role_input.custom_minimum_size = Vector2(0, 70)
	player_role_input.add_theme_font_size_override("font_size", 24)
	for role in TacticModels.PLAYER_ROLES:
		player_role_input.add_item(role)
	column.add_child(player_role_input)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	var cancel := _button("取消", 0, _close_player_editor)
	var confirm := _button("保存资料", 0, _save_player_editor)
	var remove := _button("删除球员", 0, _delete_player_from_editor)
	actions.add_child(cancel)
	actions.add_child(confirm)
	actions.add_child(remove)
	player_overlay.visible = false

func _close_player_editor() -> void:
	if player_overlay:
		player_overlay.visible = false

func _save_player_editor() -> void:
	var player_id := board.selected_player_id if board else ""
	for player in tactic.get("players", []):
		if str(player.get("id", "")) == player_id:
			player["jerseyNumber"] = player_number_input.text.strip_edges()
			player["name"] = player_name_input.text.strip_edges()
			player["role"] = player_role_input.get_item_text(player_role_input.selected)
			break
	board.set_tactic(tactic)
	_close_player_editor()
	document_changed.emit()
	_update_status("球员资料已更新")

func _delete_player_from_editor() -> void:
	_close_player_editor()
	_delete_selected_player()

func _open_library() -> void:
	if repository == null:
		_update_status("战术库尚未连接")
		return
	_ensure_library_overlay()
	_refresh_library()
	library_overlay.visible = true

func _ensure_library_overlay() -> void:
	if library_overlay:
		return
	library_overlay = PanelContainer.new()
	library_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	library_overlay.z_index = 70
	library_overlay.add_theme_stylebox_override("panel", _panel_style(Color("0b2030"), Color("ffd166"), 0))
	add_child(library_overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	library_overlay.add_child(column)
	var heading := Label.new()
	heading.text = "我的战术库"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	column.add_child(heading)
	library_list = VBoxContainer.new()
	library_list.add_theme_constant_override("separation", 12)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(library_list)
	column.add_child(scroll)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	actions.add_child(_button("新建战术", 0, _new_tactic))
	actions.add_child(_button("关闭", 0, _close_library))
	library_overlay.visible = false

func _refresh_library() -> void:
	if not library_list or repository == null:
		return
	for child in library_list.get_children():
		child.queue_free()
	for item in repository.load_all():
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 86)
		var open := _button(str(item.get("title", "未命名战术")), 0, func(): _load_tactic_from_library(str(item.get("id", ""))))
		var delete := _button("删除", 140, func(): _delete_tactic_from_library(str(item.get("id", ""))))
		row.add_child(open)
		row.add_child(delete)
		library_list.add_child(row)

func _new_tactic() -> void:
	if repository == null:
		return
	tactic = repository.create_blank()
	selected_frame = 0
	board.set_tactic(tactic)
	_refresh_frame_strip()
	_close_library()
	document_changed.emit()
	_update_status("已创建新战术")

func _load_tactic_from_library(tactic_id: String) -> void:
	var loaded := repository.load_by_id(tactic_id) if repository else {}
	if loaded.is_empty():
		return
	tactic = loaded
	selected_frame = 0
	board.set_tactic(tactic)
	_refresh_frame_strip()
	_close_library()
	document_changed.emit()
	_update_status("已打开战术：" + str(tactic.get("title", "")))

func _delete_tactic_from_library(tactic_id: String) -> void:
	if repository and repository.delete_tactic(tactic_id):
		_refresh_library()
		_update_status("已从战术库删除")
	else:
		_update_status("内置示例不能删除")

func _close_library() -> void:
	if library_overlay:
		library_overlay.visible = false
