class_name CourtScene
extends Node3D

func build(config: Dictionary) -> void:
	var width := float(config.get("widthM", 9.0))
	var length := float(config.get("lengthM", 18.0))
	var net_height := float(config.get("netHeightM", 2.43))
	_add_box("ArenaFloor", Vector3(0, -0.24, 0), Vector3(42, 0.18, 34), Color("111a1d"), 0.9)
	_add_box("CourtFloor", Vector3(0, -0.08, 0), Vector3(width, 0.16, length), Color("c77d42"), 0.78)
	_add_box("CenterLine", Vector3(0, 0.02, 0), Vector3(width, 0.025, 0.06), Color("fff2d3"), 0.65)
	_add_box("AttackLineHome", Vector3(0, 0.03, -float(config.get("attackLineOffsetM", 3.0))), Vector3(width, 0.025, 0.045), Color("fff2d3"), 0.65)
	_add_box("AttackLineAway", Vector3(0, 0.03, float(config.get("attackLineOffsetM", 3.0))), Vector3(width, 0.025, 0.045), Color("fff2d3"), 0.65)
	_add_box("SidelineLeft", Vector3(-width * 0.5, 0.03, 0), Vector3(0.045, 0.025, length), Color("fff2d3"), 0.65)
	_add_box("SidelineRight", Vector3(width * 0.5, 0.03, 0), Vector3(0.045, 0.025, length), Color("fff2d3"), 0.65)
	_add_box("EndlineHome", Vector3(0, 0.03, -length * 0.5), Vector3(width, 0.025, 0.045), Color("fff2d3"), 0.65)
	_add_box("EndlineAway", Vector3(0, 0.03, length * 0.5), Vector3(width, 0.025, 0.045), Color("fff2d3"), 0.65)
	_add_net(width, net_height)
	_add_stands()
	_add_scoreboard()
	_add_lights()

func _add_net(width: float, net_height: float) -> void:
	_add_box("NetTop", Vector3(0, net_height, 0), Vector3(width, 0.08, 0.08), Color("f1f4e9"), 0.45)
	_add_box("NetBottom", Vector3(0, 0.35, 0), Vector3(width, 0.035, 0.035), Color("b9d3d3"), 0.55)
	for index in range(1, 14):
		var x := -width * 0.5 + float(index) * width / 14.0
		_add_box("NetV%d" % index, Vector3(x, net_height * 0.67, 0), Vector3(0.018, net_height * 0.67, 0.025), Color("c8dddd"), 0.5)
	for index in range(1, 7):
		var y := 0.35 + float(index) * (net_height - 0.35) / 7.0
		_add_box("NetH%d" % index, Vector3(0, y, 0), Vector3(width, 0.018, 0.025), Color("c8dddd"), 0.5)
	_add_cylinder("PostHome", Vector3(-width * 0.5 - 0.18, net_height * 0.5, 0), 0.1, net_height + 0.5, Color("19252d"))
	_add_cylinder("PostAway", Vector3(width * 0.5 + 0.18, net_height * 0.5, 0), 0.1, net_height + 0.5, Color("19252d"))
	_add_box("PostBandHome", Vector3(-width * 0.5 - 0.18, net_height - 0.2, 0), Vector3(0.26, 0.28, 0.12), Color("c5e53e"), 0.6)
	_add_box("PostBandAway", Vector3(width * 0.5 + 0.18, net_height - 0.2, 0), Vector3(0.26, 0.28, 0.12), Color("c5e53e"), 0.6)

func _add_stands() -> void:
	for row in range(4):
		var z_front := 13.0 + float(row) * 1.35
		for seat in range(22):
			var x := -14.0 + float(seat) * 1.33
			var color := Color("c5e53e") if (seat + row) % 4 == 0 else Color("252f34")
			_add_box("SeatFront_%d_%d" % [row, seat], Vector3(x, 0.15 + float(row) * 0.45, z_front), Vector3(0.78, 0.55, 0.55), color, 0.95)
			_add_box("SeatBack_%d_%d" % [row, seat], Vector3(x, 0.15 + float(row) * 0.45, -z_front), Vector3(0.78, 0.55, 0.55), color, 0.95)
	_add_box("BackWall", Vector3(0, 6.0, 18.0), Vector3(42, 12, 0.35), Color("1b2328"), 0.95)
	_add_box("FrontWall", Vector3(0, 6.0, -18.0), Vector3(42, 12, 0.35), Color("1b2328"), 0.95)
	_add_box("LeftWall", Vector3(-21, 6.0, 0), Vector3(0.35, 12, 34), Color("171f24"), 0.95)
	_add_box("RightWall", Vector3(21, 6.0, 0), Vector3(0.35, 12, 34), Color("171f24"), 0.95)
	_add_box("NeonBannerLeft", Vector3(-10.5, 5.6, 17.75), Vector3(7.5, 0.22, 0.12), Color("c5e53e"), 0.6)
	_add_box("NeonBannerRight", Vector3(10.5, 5.6, 17.75), Vector3(7.5, 0.22, 0.12), Color("c5e53e"), 0.6)
	_add_label("ArenaLabel", "COURT 01", Vector3(-2.9, 7.4, 17.65), 48, Color("e8ff8c"))

func _add_scoreboard() -> void:
	_add_box("Scoreboard", Vector3(0, 8.3, 17.55), Vector3(10.5, 3.2, 0.4), Color("080d10"), 0.92)
	_add_label("ScoreLabel", "HOME   17     06   AWAY", Vector3(-4.25, 8.45, 17.25), 52, Color("f6f3e6"))
	_add_label("ScoreSubLabel", "VOLLEYBALL  /  SET 2", Vector3(-2.5, 7.55, 17.25), 24, Color("c5e53e"))

func _add_lights() -> void:
	for position in [Vector3(-11, 10, -8), Vector3(11, 10, -8), Vector3(-11, 10, 8), Vector3(11, 10, 8)]:
		var light := OmniLight3D.new()
		light.position = position
		light.omni_range = 28.0
		light.light_energy = 7.0
		light.light_color = Color("fff1d0")
		add_child(light)

func _add_box(node_name: String, center: Vector3, size: Vector3, color: Color, roughness: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	mesh.material = material
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = center
	add_child(node)

func _add_cylinder(node_name: String, center: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.45
	mesh.material = material
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = center
	add_child(node)

func _add_label(node_name: String, text: String, position: Vector3, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.font_size = font_size
	label.modulate = color
	label.position = position
	label.outline_size = 12
	label.outline_modulate = Color("050708")
	add_child(label)
