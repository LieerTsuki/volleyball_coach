class_name TacticReplay3D
extends Node3D

signal editor_requested
signal save_requested

var tactic: Dictionary = {}
var actors: Dictionary = {}
var opponents: Dictionary = {}
var ball: MeshInstance3D
var camera: Camera3D
var hud: CanvasLayer
var phase_label: Label
var tactic_title_label: Label
var time_label: Label
var timeline: HSlider
var playing := false
var time_ms := 0.0
var duration_ms := 4000
var built := false

func _ready() -> void:
	_build_hud()
	if not tactic.is_empty():
		_rebuild_world()

func set_tactic(value: Dictionary) -> void:
	tactic = TacticModels.ensure_frames(value)
	if tactic_title_label:
		tactic_title_label.text = "当前战术 · " + str(tactic.get("title", "未命名战术"))
	duration_ms = FrameInterpolator.total_duration(tactic)
	time_ms = clampf(time_ms, 0.0, float(duration_ms))
	if is_inside_tree():
		_rebuild_world()

func _process(delta: float) -> void:
	if not visible or not playing:
		return
	time_ms += delta * 1000.0 * 0.65
	if time_ms >= duration_ms:
		time_ms = 0.0
	_apply_at(roundi(time_ms))
	if timeline:
		timeline.set_value_no_signal(time_ms)

func _rebuild_world() -> void:
	for child in get_children():
		if child != hud:
			child.free()
	actors.clear()
	opponents.clear()
	ball = null
	var environment := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color("060b0e")
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("b9c9cc")
	world.ambient_light_energy = 0.55
	environment.environment = world
	add_child(environment)

	var court := CourtScene.new()
	add_child(court)
	court.build(tactic.get("courtConfig", TacticModels.default_court()))

	camera = Camera3D.new()
	camera.current = true
	add_child(camera)
	_set_camera("oblique")

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)

	for definition in tactic.get("players", []):
		var actor := PlayerActor.new()
		add_child(actor)
		actor.setup(definition)
		actors[str(definition.get("id", ""))] = actor

	for definition in _opponent_definitions():
		var opponent := PlayerActor.new()
		add_child(opponent)
		opponent.setup(definition)
		opponent.position = Vector3(float(definition.get("x", 0.0)), 0.0, float(definition.get("z", 0.0)))
		opponents[str(definition.get("id", ""))] = opponent

	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	var ball_material := StandardMaterial3D.new()
	ball_material.albedo_color = Color.WHITE
	ball_material.albedo_texture = load("res://assets/volleyball.png")
	ball_material.emission_enabled = true
	ball_material.emission = Color("5c4b12")
	sphere.material = ball_material
	ball = MeshInstance3D.new()
	ball.name = "MatchBall"
	ball.mesh = sphere
	add_child(ball)
	built = true
	_apply_at(roundi(time_ms))

func _opponent_definitions() -> Array[Dictionary]:
	return [
		{"id": "o1", "jerseyNumber": "1", "role": "二传", "team": "away", "x": -2.6, "z": 2.2},
		{"id": "o2", "jerseyNumber": "2", "role": "主攻", "team": "away", "x": 2.9, "z": 5.8},
		{"id": "o3", "jerseyNumber": "3", "role": "副攻", "team": "away", "x": 0.0, "z": 2.0},
		{"id": "o4", "jerseyNumber": "4", "role": "主攻", "team": "away", "x": -3.1, "z": 5.5},
		{"id": "o5", "jerseyNumber": "5", "role": "接应", "team": "away", "x": 1.8, "z": 5.1},
		{"id": "o6", "jerseyNumber": "6", "role": "自由人", "team": "away", "x": 2.9, "z": 7.4}
	]

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	var top_panel := ColorRect.new()
	top_panel.color = Color("fff6df")
	top_panel.position = Vector2(0, 0)
	top_panel.size = Vector2(1080, 154)
	hud.add_child(top_panel)
	var title := Label.new()
	title.text = "球阵绘"
	title.position = Vector2(24, 22)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("102b45"))
	hud.add_child(title)
	tactic_title_label = Label.new()
	tactic_title_label.text = "当前战术 · 未命名战术"
	tactic_title_label.position = Vector2(24, 76)
	tactic_title_label.add_theme_font_size_override("font_size", 18)
	tactic_title_label.add_theme_color_override("font_color", Color("ef755a"))
	hud.add_child(tactic_title_label)
	hud.add_child(_make_header_button("res://assets/ui/library.svg", "战术库", Vector2(700, 30), Vector2(150, 72), func(): editor_requested.emit()))
	hud.add_child(_make_header_button("res://assets/ui/save.svg", "保存", Vector2(860, 30), Vector2(130, 72), func(): save_requested.emit()))
	var control_panel := ColorRect.new()
	control_panel.color = Color("fff6df")
	control_panel.position = Vector2(0, 1605)
	control_panel.size = Vector2(1080, 315)
	hud.add_child(control_panel)
	phase_label = Label.new()
	phase_label.position = Vector2(32, 1620)
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", Color("18aeb4"))
	hud.add_child(phase_label)
	time_label = Label.new()
	time_label.position = Vector2(900, 1616)
	time_label.add_theme_font_size_override("font_size", 30)
	time_label.add_theme_color_override("font_color", Color("102b45"))
	hud.add_child(time_label)
	var speed_label := Label.new()
	speed_label.text = "路线由 2D 关键帧自动驱动"
	speed_label.position = Vector2(32, 1662)
	speed_label.add_theme_color_override("font_color", Color("102b45"))
	speed_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(speed_label)
	timeline = HSlider.new()
	timeline.position = Vector2(32, 1692)
	timeline.size = Vector2(1016, 30)
	timeline.step = 10.0
	timeline.value_changed.connect(_on_timeline_changed)
	hud.add_child(timeline)
	hud.add_child(_make_icon_button("res://assets/ui/play.svg", "播放 / 暂停", Vector2(40, 1735), _toggle_play))
	hud.add_child(_make_icon_button("res://assets/ui/restart.svg", "重播", Vector2(180, 1735), _restart))
	hud.add_child(_make_icon_button("res://assets/ui/camera_top.svg", "顶视", Vector2(320, 1735), func(): _set_camera("top")))
	hud.add_child(_make_icon_button("res://assets/ui/camera_oblique.svg", "斜上方", Vector2(460, 1735), func(): _set_camera("oblique")))
	hud.add_child(_make_icon_button("res://assets/ui/camera_net.svg", "网侧", Vector2(600, 1735), func(): _set_camera("net")))
	hud.add_child(_make_icon_button("res://assets/ui/back.svg", "返回 2D 编排", Vector2(900, 1735), func(): editor_requested.emit()))

func _make_button(text: String, position: Vector2, button_size: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = button_size
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_stylebox_override("normal", _button_style(Color("f08a5d"), Color("ffd166")))
	button.add_theme_stylebox_override("hover", _button_style(Color("ff9f68"), Color("fff0a8")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("d95f59"), Color("fff0a8")))
	button.pressed.connect(callback)
	hud.add_child(button)
	return button

func _make_header_button(icon_path: String, text: String, position: Vector2, button_size: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.icon = load(icon_path)
	button.text = text
	button.position = position
	button.size = button_size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("102b45"))
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", _icon_hover_style(Color(0.12, 0.68, 0.71, 0.2)))
	button.add_theme_stylebox_override("pressed", _icon_hover_style(Color(0.94, 0.47, 0.36, 0.3)))
	button.pressed.connect(callback)
	return button

func _make_icon_button(icon_path: String, tooltip: String, position: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.icon = load(icon_path)
	button.position = position
	button.size = Vector2(104, 104)
	button.tooltip_text = tooltip
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", _icon_hover_style(Color(0.12, 0.68, 0.71, 0.2)))
	button.add_theme_stylebox_override("pressed", _icon_hover_style(Color(0.94, 0.47, 0.36, 0.3)))
	button.pressed.connect(callback)
	return button

func _icon_hover_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = 52
	style.corner_radius_top_right = 52
	style.corner_radius_bottom_left = 52
	style.corner_radius_bottom_right = 52
	return style

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	return style

func _apply_at(value: int) -> void:
	if tactic.is_empty() or not built:
		return
	var state := TacticEvaluator.evaluate_at(tactic, value)
	for player_state in state.players:
		var player_id := str(player_state.get("player_id", ""))
		if actors.has(player_id):
			actors[player_id].apply_state(player_state)
	ball.visible = bool(state.ball.get("active", false))
	if ball.visible:
		ball.position = state.ball.get("position", Vector3.ZERO)
	if timeline:
		timeline.max_value = duration_ms
		timeline.set_value_no_signal(value)
	if time_label:
		time_label.text = "%02d:%03d" % [value / 1000, value % 1000]
	if phase_label:
		var phases: Array = tactic.get("phases", [])
		if not phases.is_empty():
			phase_label.text = "当前阶段  ·  " + str(phases[state.phase_index].get("label", ""))

func _toggle_play() -> void:
	playing = not playing

func _restart() -> void:
	time_ms = 0.0
	playing = true
	_apply_at(0)

func _on_timeline_changed(value: float) -> void:
	time_ms = value
	playing = false
	_apply_at(roundi(value))

func _set_camera(preset: String) -> void:
	if not camera:
		return
	var position := Vector3(0, 18, -20)
	if preset == "top":
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 25.0
		position = Vector3(0, 28, 0)
	elif preset == "net":
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 48.0
		position = Vector3(-14, 6.5, -1.5)
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 46.0
		position = Vector3(14, 15, -17)
	camera.look_at_from_position(position, Vector3(0, 1.0, 0), Vector3.UP)
