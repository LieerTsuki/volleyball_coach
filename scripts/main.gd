extends Node3D

var tactic: Dictionary
var repository := TacticRepository.new()
var clock := PlaybackClock.new()
var actors: Dictionary = {}
var ball: MeshInstance3D
var camera: Camera3D
var phase_label: Label
var time_label: Label
var timeline: HSlider

func _ready() -> void:
	add_child(clock); clock.configure(4000); clock.changed.connect(_apply_at)
	tactic = repository.ensure_sample(); _build_scene(); _build_ui(); _apply_at(0)

func _build_scene() -> void:
	var court := CourtScene.new(); add_child(court); court.build(tactic.courtConfig)
	camera = Camera3D.new(); camera.current = true; add_child(camera); _set_camera("top")
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-50, -30, 0); light.light_energy = 1.1; add_child(light)
	for definition in tactic.players:
		var actor := PlayerActor.new(); add_child(actor); actor.setup(definition); actors[str(definition.id)] = actor
	var sphere := SphereMesh.new(); sphere.radius = 0.12; sphere.height = 0.24; sphere.material = StandardMaterial3D.new(); sphere.material.albedo_color = Color("f3bd3e"); ball = MeshInstance3D.new(); ball.mesh = sphere; add_child(ball)

func _build_ui() -> void:
	var canvas := CanvasLayer.new(); add_child(canvas); var panel := ColorRect.new(); panel.color = Color(0.03, 0.06, 0.1, 0.85); panel.position = Vector2(0, 0); panel.size = Vector2(1920, 150); canvas.add_child(panel)
	var title := Label.new(); title.text = str(tactic.title); title.position = Vector2(40, 22); title.add_theme_font_size_override("font_size", 30); canvas.add_child(title)
	phase_label = Label.new(); phase_label.position = Vector2(40, 102); phase_label.add_theme_font_size_override("font_size", 22); canvas.add_child(phase_label)
	time_label = Label.new(); time_label.position = Vector2(1660, 25); time_label.add_theme_font_size_override("font_size", 28); canvas.add_child(time_label)
	timeline = HSlider.new(); timeline.position = Vector2(480, 104); timeline.size = Vector2(850, 26); timeline.max_value = 4000; timeline.value_changed.connect(func(value): clock.seek(roundi(value))); canvas.add_child(timeline)
	_add_button(canvas, "播放 / 暂停", Vector2(480, 45), func(): clock.toggle()); _add_button(canvas, "重播", Vector2(650, 45), func(): clock.replay()); _add_button(canvas, "顶视", Vector2(820, 45), func(): _set_camera("top")); _add_button(canvas, "斜上方", Vector2(970, 45), func(): _set_camera("oblique")); _add_button(canvas, "网侧", Vector2(1140, 45), func(): _set_camera("net")); _add_button(canvas, "保存", Vector2(1320, 45), func(): repository.save(tactic))

func _add_button(parent: Node, text: String, pos: Vector2, callback: Callable) -> void:
	var button := Button.new(); button.text = text; button.position = pos; button.size = Vector2(140, 42); button.pressed.connect(callback); parent.add_child(button)

func _apply_at(time_ms: int) -> void:
	var state := TacticEvaluator.evaluate_at(tactic, time_ms)
	for player_state in state.players:
		if actors.has(player_state.player_id): actors[player_state.player_id].apply_state(player_state)
	ball.visible = bool(state.ball.active); if ball.visible: ball.position = state.ball.position
	if timeline: timeline.set_value_no_signal(time_ms)
	if time_label: time_label.text = "%02d:%03d" % [time_ms / 1000, time_ms % 1000]
	if phase_label: phase_label.text = "当前阶段 · " + str(tactic.phases[state.phase_index].label)

func _set_camera(preset: String) -> void:
	if preset == "top": camera.position = Vector3(0, 22, 0); camera.rotation_degrees = Vector3(-90, 0, 0); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 11
	elif preset == "oblique": camera.position = Vector3(12, 15, -15); camera.rotation_degrees = Vector3(-45, 38, 0); camera.projection = Camera3D.PROJECTION_PERSPECTIVE; camera.fov = 42
	else: camera.position = Vector3(-12, 5, -2); camera.rotation_degrees = Vector3(-76, -90, 0); camera.projection = Camera3D.PROJECTION_PERSPECTIVE; camera.fov = 46
