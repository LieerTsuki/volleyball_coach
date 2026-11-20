class_name TacticReplay3D
extends Node3D

signal editor_requested
signal save_requested

const MATCH_BALL := preload("res://scripts/presentation/match_ball.gdshader")
const INK := Color("0b1326")
const PANEL := Color("131e34")
const LINE := Color("293e58")
const WHITE := Color("f5f4e8")
const MIST := Color("aabed2")
const CYAN := Color("6de9ff")
const LIME := Color("e3ff69")
const CORAL := Color("ff967a")

var tactic: Dictionary = {}
var evaluated_tactic: Dictionary = {}
var actors: Dictionary = {}
var world: Node3D
var viewport_3d: SubViewport
var ball: MeshInstance3D
var ball_marker: MeshInstance3D
var landing_marker: MeshInstance3D
var camera: Camera3D
var camera_mode := "oblique"
var hud: CanvasLayer
var phase_label: Label
var title_label: Label
var time_label: Label
var timeline: HSlider
var play_button: Button
var speed_button: Button
var camera_buttons := ButtonGroup.new()
var save_button: Button
var playing := false
var speed := 1.0
var time_ms := 0.0
var duration_ms := 1
var lead_in_ms := 0
var hud_safe_frame: Control

func _ready() -> void:
	_build_hud()
	visibility_changed.connect(_sync_visibility)
	_sync_visibility()

func set_tactic(value: Dictionary) -> void:
	tactic = TacticModels.ensure_frames(value)
	evaluated_tactic = RallyPlan.compile(tactic)
	lead_in_ms = int(evaluated_tactic.get("rallyLeadInMs", 0))
	title_label.text = str(tactic.get("title", "未命名战术"))
	save_button.text = "保存"
	duration_ms = FrameInterpolator.total_duration(tactic) + lead_in_ms
	time_ms = 0.0
	timeline.set_value_no_signal(time_ms)
	timeline.max_value = duration_ms
	_rebuild_world()
	_apply_at(0)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not playing:
		return
	time_ms = minf(time_ms + delta * 1000.0 * speed, duration_ms)
	if time_ms >= duration_ms:
		_set_playing(false)
	_apply_at(roundi(time_ms))

func _sync_visibility() -> void:
	hud.visible = is_visible_in_tree()
	_apply_safe_area()
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if hud.visible else SubViewport.UPDATE_DISABLED
	if not hud.visible:
		_set_playing(false)

func _rebuild_world() -> void:
	if world:
		world.free()
	actors.clear()
	world = Node3D.new()
	viewport_3d.add_child(world)

	var sky := WorldEnvironment.new()
	var room := Environment.new()
	room.background_mode = Environment.BG_COLOR
	room.background_color = INK
	room.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	room.ambient_light_color = Color("cedff5")
	room.ambient_light_energy = 0.62
	sky.environment = room
	world.add_child(sky)

	var court := CourtScene.new()
	world.add_child(court)
	court.build(tactic.get("courtConfig", TacticModels.default_court()))
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(camera)
	camera.make_current()
	_fit_camera()

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-60, -27, 0)
	key_light.light_color = Color("fff1dd")
	key_light.light_energy = 0.98
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 55.0
	world.add_child(key_light)

	for definition in tactic.get("players", []):
		var actor := PlayerActor.new()
		world.add_child(actor)
		actor.setup(definition)
		actors[str(definition.id)] = actor
	_add_ball()

func _add_ball() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	sphere.radial_segments = 20
	sphere.rings = 12
	var skin := ShaderMaterial.new()
	skin.shader = MATCH_BALL
	sphere.material = skin
	ball = MeshInstance3D.new()
	ball.name = "MatchBall"
	ball.mesh = sphere
	world.add_child(ball)

	ball_marker = _add_floor_ring(0.245, Color("ffd873"))
	landing_marker = _add_floor_ring(0.56, Color("ff654d"))

func _add_floor_ring(radius: float, color: Color) -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.052
	ring.outer_radius = radius
	ring.rings = 18
	ring.ring_segments = 5
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = color
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material = ring_material
	var marker := MeshInstance3D.new()
	marker.mesh = ring
	marker.scale.y = 0.25
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(marker)
	return marker

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	hud_safe_frame = Control.new()
	hud_safe_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_safe_frame)
	var layout := VBoxContainer.new()
	hud_safe_frame.add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)

	var header := _panel(INK, 33, 24)
	layout.add_child(header)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	header.add_child(heading)
	var nav := _row()
	heading.add_child(nav)
	nav.add_child(_button("‹  返回 2D", func(): editor_requested.emit()))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)
	save_button = _button("保存", _save)
	nav.add_child(save_button)

	var heading_row := _row()
	heading.add_child(heading_row)
	var heading_label := _label("3D 战术回放", 58, WHITE)
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading_label)
	heading_row.add_child(_team_label("我方球员", CYAN))
	title_label = _label("", 29, MIST)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_child(title_label)

	var screen := SubViewportContainer.new()
	screen.stretch = true
	screen.stretch_shrink = 2
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(screen)
	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.msaa_3d = Viewport.MSAA_2X
	screen.add_child(viewport_3d)
	viewport_3d.size_changed.connect(_fit_camera)

	var bottom := _panel(PANEL, 33, 24)
	layout.add_child(bottom)
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	bottom.add_child(controls)
	var status := _row()
	controls.add_child(status)
	phase_label = _label("", 29, CYAN)
	phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_child(phase_label)
	time_label = _label("", 31, WHITE)
	status.add_child(time_label)

	timeline = HSlider.new()
	timeline.custom_minimum_size.y = 64
	timeline.step = 1.0
	timeline.add_theme_stylebox_override("slider", _style(LINE, LINE, 7))
	timeline.add_theme_stylebox_override("grabber_area", _style(CYAN, CYAN, 7))
	timeline.add_theme_stylebox_override("grabber_area_highlight", _style(LIME, LIME, 7))
	var handle_image := Image.create(22, 32, false, Image.FORMAT_RGBA8)
	handle_image.fill(WHITE)
	var handle := ImageTexture.create_from_image(handle_image)
	timeline.add_theme_icon_override("grabber", handle)
	timeline.add_theme_icon_override("grabber_highlight", handle)
	timeline.value_changed.connect(_seek)
	controls.add_child(timeline)

	var transport := _row()
	controls.add_child(transport)
	play_button = _button("播放", _toggle_play, true)
	play_button.size_flags_stretch_ratio = 2.1
	transport.add_child(play_button)
	transport.add_child(_button("重播", restart))
	speed_button = _button("1×", _toggle_speed)
	transport.add_child(speed_button)
	var cameras := _row()
	controls.add_child(cameras)
	_add_camera_button(cameras, "斜上方", "oblique")
	_add_camera_button(cameras, "顶视", "top")
	_add_camera_button(cameras, "网侧", "net")

func _apply_safe_area() -> void:
	if not hud_safe_frame or not is_inside_tree():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var safe: Rect2 = DisplayServer.get_display_safe_area()
	var top_inset := 20.0
	if safe.end.y <= viewport_size.y + 1.0 and safe.position.y > top_inset:
		top_inset = minf(safe.position.y, 44.0)
	var left_inset := maxf(12.0, safe.position.x)
	var right_inset := maxf(12.0, viewport_size.x - safe.end.x)
	hud_safe_frame.position = Vector2(left_inset, top_inset)
	hud_safe_frame.size = Vector2(maxf(240.0, viewport_size.x - left_inset - right_inset), maxf(480.0, viewport_size.y - top_inset))

func _panel(color: Color, inset: float, padding: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style(color, LINE)
	style.content_margin_left = inset
	style.content_margin_right = inset
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	return row

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _team_label(text: String, color: Color) -> PanelContainer:
	var badge := _panel(color.darkened(0.77), 19, 3)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(_label(text, 26, color))
	return badge

func _button(text: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 104)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 31)
	button.add_theme_color_override("font_color", INK if primary else WHITE)
	button.add_theme_color_override("font_hover_color", INK if primary else CYAN)
	button.add_theme_color_override("font_pressed_color", INK if primary else CYAN)
	button.add_theme_stylebox_override("normal", _style(LIME if primary else PANEL, LIME if primary else LINE, 12))
	button.add_theme_stylebox_override("hover", _style(LIME.lightened(0.20) if primary else Color("203453"), CYAN, 12))
	button.add_theme_stylebox_override("pressed", _style(LIME.darkened(0.15) if primary else Color("203453"), CYAN, 12))
	button.pressed.connect(callback)
	return button

func _style(color: Color, border: Color, radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style

func _add_camera_button(row: HBoxContainer, label: String, preset: String) -> void:
	var button := _button(label, func(): _set_camera(preset))
	button.toggle_mode = true
	button.button_group = camera_buttons
	button.button_pressed = preset == camera_mode
	row.add_child(button)

func _apply_at(value: int) -> void:
	var state := TacticEvaluator.evaluate_at(evaluated_tactic, value - lead_in_ms)
	for player_state in state.players:
		actors[player_state.player_id].apply_state(player_state)
	ball.visible = bool(state.ball.active)
	ball_marker.visible = ball.visible
	landing_marker.visible = state.ball.has("landing")
	if landing_marker.visible:
		var target: Vector3 = state.ball.landing
		landing_marker.position = Vector3(target.x, 0.032, target.z)
	if ball.visible:
		ball.position = state.ball.position
		ball.rotation = Vector3(float(value) * 0.005, float(value) * 0.007, 0.55)
		ball_marker.position = Vector3(ball.position.x, 0.03, ball.position.z)
	timeline.set_value_no_signal(value)
	time_label.text = "%.2f / %.2f 秒" % [value / 1000.0, duration_ms / 1000.0]
	var frame_text := "站位 %02d / %02d" % [int(state.frame_index) + 1, tactic.frames.size()]
	var phases: Array = evaluated_tactic.get("phases", [])
	var phase := str(phases[state.phase_index].get("label", "")) if not phases.is_empty() else ""
	phase_label.text = frame_text if phase.is_empty() else "%s   ·   %s" % [frame_text, phase]

func restart() -> void:
	time_ms = 0.0
	_set_playing(true)
	_apply_at(0)

func _toggle_play() -> void:
	if time_ms >= duration_ms:
		restart()
	else:
		_set_playing(not playing)

func _set_playing(value: bool) -> void:
	playing = value
	play_button.text = "暂停" if playing else "播放"

func _toggle_speed() -> void:
	speed = 0.5 if speed == 1.0 else 1.0
	speed_button.text = "0.5×" if speed == 0.5 else "1×"

func _seek(value: float) -> void:
	time_ms = value
	_set_playing(false)
	_apply_at(roundi(time_ms))

func _save() -> void:
	save_requested.emit()

func show_save_result(error: Error) -> void:
	save_button.text = "已保存" if error == OK else "保存失败"

func _set_camera(preset: String) -> void:
	camera_mode = preset
	_fit_camera()

func _fit_camera() -> void:
	if not is_instance_valid(camera):
		return
	var eye := Vector3(9, 19, -24)
	var up := Vector3.UP
	match camera_mode:
		"top":
			eye = Vector3(0, 26, 0)
			up = Vector3.FORWARD
		"net":
			eye = Vector3(20, 11, -8)
	camera.look_at_from_position(eye, Vector3.ZERO, up)
	var config: Dictionary = tactic.get("courtConfig", TacticModels.default_court())
	var half_width := float(config.get("widthM", 9.0)) * 0.5
	var half_length := float(config.get("lengthM", 18.0)) * 0.5
	var inverse := camera.basis.inverse()
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	var corners: Array[Vector3] = []
	for x in [-half_width, half_width]:
		for z in [-half_length, half_length]:
			corners.append(Vector3(x, 0, z))
			corners.append(Vector3(x, 3.2, z))
	if camera_mode == "oblique":
		corners.append(Vector3(-4.2, 5.8, half_length + 6.6))
		corners.append(Vector3(4.2, 5.8, half_length + 6.6))
	for corner in corners:
		var projected := inverse * corner
		low = low.min(Vector2(projected.x, projected.y))
		high = high.max(Vector2(projected.x, projected.y))
	var center := (low + high) * 0.5
	camera.h_offset = center.x
	camera.v_offset = center.y
	var aspect := float(viewport_3d.size.x) / maxf(1, viewport_3d.size.y)
	var bounds := high - low
	camera.size = maxf(bounds.y + 1.6, (bounds.x + 1.25) / maxf(aspect, 0.1))
