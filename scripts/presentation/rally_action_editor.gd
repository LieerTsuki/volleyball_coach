class_name RallyActionEditor
extends PanelContainer

signal action_changed

const INK := Color("0d182e")
const PANEL := Color("182941")
const BORDER := Color("375778")
const WHITE := Color("fff8e5")
const MIST := Color("b4c9df")
const MINT := Color("aff3f4")
const LIME := Color("e3ff69")

var tactic: Dictionary
var frame_index := 0
var point: Variant
var frame_label: Label
var target_field: VBoxContainer
var type_input: OptionButton
var player_input: OptionButton
var target_input: OptionButton
var map: VerticalCourtBoard
var map_hint: Label
var status: Label
var save_button: Button
var clear_button: Button

func _ready() -> void:
	z_index = 75
	add_theme_stylebox_override("panel", _style(INK, BORDER, 0))
	_build_layout()

func open_frame(document: Dictionary, index: int) -> void:
	tactic = document
	frame_index = index
	point = null
	var action: Dictionary = tactic.frames[index].get("rallyAction", {})
	var previous: Dictionary = tactic.frames[index - 1].get("rallyAction", {}) if index > 0 else {}
	var next_action: Dictionary = tactic.frames[index + 1].get("rallyAction", {}) if index + 1 < tactic.frames.size() else {}
	frame_label.text = "第 %d 张站位图 · %d 张" % [index + 1, tactic.frames.size()]
	type_input.select(maxi(0, RallyPlan.TYPES.find(action.get("type", "Pass"))))
	if action.is_empty() and previous.get("type", "") == "Pass":
		type_input.select(1)
	elif action.is_empty() and (previous.get("type", "") == "Set" or index + 1 == tactic.frames.size()):
		type_input.select(2)
	var player_id := str(action.get("playerId", previous.get("targetPlayerId", "")))
	var target_id := str(action.get("targetPlayerId", next_action.get("playerId", "")))
	_fill_players(player_input, player_id)
	_fill_players(target_input, target_id, _selected_id(player_input))
	if action.has("landing"):
		point = Vector3(float(action.landing.x), 0, float(action.landing.z))
	clear_button.disabled = action.is_empty()
	save_button.disabled = tactic.players.is_empty()
	map.set_tactic(tactic)
	_refresh_map()
	if tactic.players.is_empty():
		status.text = "请返回站位图，先添加球员"
	elif action.is_empty() and not RallyPlan.has_actions(tactic) and not tactic.get("ballActions", []).is_empty():
		status.text = "保存动作后，这份战术将使用你的自定义球路"
	show()

func _build_layout() -> void:
	var inset := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, 28)
	add_child(inset)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	inset.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := _label("球路与动作", 52, WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_button("返回站位", hide))
	frame_label = _label("", 30, MINT)
	layout.add_child(frame_label)

	var fields := HBoxContainer.new()
	fields.add_theme_constant_override("separation", 16)
	layout.add_child(fields)
	type_input = _option(_field(fields, "动作"))
	for type in RallyPlan.TYPES:
		type_input.add_item(RallyPlan.LABELS[type])
	type_input.item_selected.connect(_on_type_changed)
	player_input = _option(_field(fields, "执行球员"))
	player_input.item_selected.connect(_on_player_changed)
	target_field = _field(fields, "传给")
	target_input = _option(target_field)
	target_input.item_selected.connect(_on_target_changed)

	map_hint = _label("", 30, MINT)
	map_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(map_hint)
	map = VerticalCourtBoard.new()
	map.point_picker = true
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size.y = 380
	map.point_picked.connect(_pick_point)
	layout.add_child(map)
	status = _label("", 29, Color("ffbf9e"))
	status.custom_minimum_size.y = 43
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	layout.add_child(buttons)
	clear_button = _button("清除这张动作", _clear)
	buttons.add_child(clear_button)
	save_button = _button("保存动作", _save, true)
	buttons.add_child(save_button)
	for button in buttons.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _field(parent: HBoxContainer, text: String) -> VBoxContainer:
	var field := VBoxContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 8)
	parent.add_child(field)
	field.add_child(_label(text, 28, MIST))
	return field

func _option(parent: VBoxContainer) -> OptionButton:
	var option := OptionButton.new()
	option.fit_to_longest_item = false
	option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_control(option)
	var popup := option.get_popup()
	popup.add_theme_font_size_override("font_size", 34)
	popup.add_theme_constant_override("v_separation", 29)
	popup.add_theme_stylebox_override("panel", _style(PANEL, BORDER))
	parent.add_child(option)
	return option

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	_style_control(button, primary)
	return button

func _style_control(button: Button, primary := false) -> void:
	button.custom_minimum_size.y = 112
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", INK if primary else WHITE)
	button.add_theme_color_override("font_hover_color", INK if primary else MINT)
	button.add_theme_color_override("font_pressed_color", INK if primary else MINT)
	button.add_theme_stylebox_override("normal", _style(LIME if primary else PANEL, LIME if primary else BORDER))
	button.add_theme_stylebox_override("hover", _style(LIME if primary else PANEL.lightened(0.12), MINT))
	button.add_theme_stylebox_override("pressed", _style(LIME.darkened(0.12) if primary else PANEL.darkened(0.15), MINT))
	button.add_theme_stylebox_override("disabled", _style(PANEL.darkened(0.22), BORDER.darkened(0.2)))

func _style(background: Color, border: Color, radius := 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	return style

func _fill_players(input: OptionButton, chosen: String, excluded := "") -> void:
	input.clear()
	input.add_item("选择球员")
	input.set_item_metadata(0, "")
	input.select(0)
	for player in tactic.get("players", []):
		var player_id := str(player.get("id", ""))
		if player_id == excluded:
			continue
		input.add_item("#%s  %s" % [str(player.get("jerseyNumber", "")), str(player.get("name", ""))])
		var index := input.item_count - 1
		input.set_item_metadata(index, player_id)
		if player_id == chosen:
			input.select(index)

func _selected_id(input: OptionButton) -> String:
	return str(input.get_selected_metadata())

func _type() -> String:
	return RallyPlan.TYPES[type_input.selected]

func _on_player_changed(_index: int) -> void:
	var target_id := _selected_id(target_input)
	_fill_players(target_input, target_id, _selected_id(player_input))
	if target_id != _selected_id(target_input):
		point = null
	_refresh_map()

func _on_target_changed(_index: int) -> void:
	point = null
	_refresh_map()

func _on_type_changed(_index: int) -> void:
	point = null
	_refresh_map()

func _pick_point(value: Vector3) -> void:
	if _type() == "Spike" and value.z <= 0.0:
		status.text = "请点中线以上的对方场区"
		return
	if _type() != "Spike" and (_selected_id(target_input).is_empty() or frame_index + 1 >= tactic.frames.size()):
		status.text = "需要先选择接球队员，并准备下一张站位图"
		return
	point = value
	_refresh_map()

func _refresh_map() -> void:
	var spike := _type() == "Spike"
	target_field.visible = not spike
	var next_index := mini(frame_index + 1, tactic.frames.size() - 1)
	map.set_frame(frame_index if spike else next_index)
	map.selected_player_id = "" if spike else _selected_id(target_input)
	map.target_point = point
	if spike:
		map_hint.text = "点对方场区，指定扣球落点"
	elif frame_index == next_index:
		map_hint.text = "请新增下一张站位图，用来记录接球位置"
	elif map.selected_player_id.is_empty():
		map_hint.text = "选接球队员，再点球场调整他在第 %d 张的接球站位" % (next_index + 1)
	else:
		map_hint.text = "第 %d 张接球站位 · 点球场可调整高亮球员的位置" % (next_index + 1)
		if point == null:
			map.target_point = FrameInterpolator.position_in_frame(tactic.frames[next_index], map.selected_player_id)
	status.text = ""
	if frame_index > 0:
		var previous: Dictionary = tactic.frames[frame_index - 1].get("rallyAction", {})
		var performer := _selected_id(player_input)
		if previous.has("targetPlayerId") and not performer.is_empty() and previous.targetPlayerId != performer:
			status.text = "保存后，上一张也会传给这名执行球员"
	if not spike and next_index > frame_index and not map.selected_player_id.is_empty():
		var next: Dictionary = tactic.frames[next_index].get("rallyAction", {})
		if not next.is_empty() and next.playerId != map.selected_player_id:
			status.text = "保存后，第 %d 张的接球动作也将交给这名球员" % (next_index + 1)
	map.queue_redraw()

func _save() -> void:
	var problem := RallyPlan.save_action(tactic, frame_index, _type(), _selected_id(player_input), _selected_id(target_input), point)
	if not problem.is_empty():
		status.text = problem
		return
	hide()
	action_changed.emit()

func _clear() -> void:
	tactic.frames[frame_index].erase("rallyAction")
	hide()
	action_changed.emit()
