class_name PlayerActor
extends Node3D

var body: Node3D
var chest: Node3D
var shoulders: Array[Node3D] = []
var elbows: Array[Node3D] = []
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []

func setup(definition: Dictionary) -> void:
	var away := str(definition.get("team", "home")) == "away"
	var primary := _material(Color("ec593e") if away else Color("166ed0"))
	var accent := _material(Color("ffac80") if away else Color("70e7ff"))
	var shorts := _material(Color("212b47") if away else Color("122b4d"))
	var skin_colors := [Color("cf905f"), Color("f1b893"), Color("a26344"), Color("e1a57a")]
	var skin := _material(skin_colors[posmod(str(definition.get("id", "")).hash(), skin_colors.size())])
	var hair := _material(Color("202436"))
	var sock := _material(Color("e9f5f4"))
	var number := str(definition.get("jerseyNumber", ""))

	var marker := TorusMesh.new()
	marker.inner_radius = 0.29
	marker.outer_radius = 0.34
	marker.rings = 20
	marker.ring_segments = 6
	_part(self, marker, Vector3(0, 0.028, 0), Vector3(1, 0.24, 1), accent)
	body = _pivot(self, Vector3(0, 1.0, 0))
	chest = _pivot(body, Vector3.ZERO)
	_box(body, Vector3.ZERO, Vector3(0.46, 0.24, 0.27), shorts)
	_capsule(chest, Vector3(0, 0.34, 0), 0.29, 0.72, Vector3(1, 1, 0.59), primary)
	_box(chest, Vector3(0, 0.50, 0), Vector3(0.50, 0.12, 0.30), accent)
	_capsule(chest, Vector3(0, 0.70, 0), 0.09, 0.20, Vector3.ONE, skin)
	_capsule(chest, Vector3(0, 0.91, 0.015), 0.174, 0.39, Vector3(1, 1, 0.93), skin)
	_capsule(chest, Vector3(0, 1.014, -0.026), 0.18, 0.25, Vector3(1, 1, 0.98), hair)
	for side in [-1.0, 1.0]:
		_box(chest, Vector3(side * 0.07, 0.92, 0.164), Vector3(0.038, 0.025, 0.018), hair)
		var shoulder := _pivot(chest, Vector3(side * 0.30, 0.51, 0.0))
		_capsule(shoulder, Vector3(0, -0.06, 0), 0.103, 0.26, Vector3.ONE, primary)
		_capsule(shoulder, Vector3(0, -0.20, 0), 0.073, 0.27, Vector3.ONE, skin)
		var elbow := _pivot(shoulder, Vector3(0, -0.31, 0))
		_capsule(elbow, Vector3(0, -0.105, 0), 0.064, 0.28, Vector3.ONE, skin)
		_capsule(elbow, Vector3(0, -0.25, 0), 0.074, 0.16, Vector3.ONE, skin)
		shoulders.append(shoulder)
		elbows.append(elbow)

		var hip := _pivot(body, Vector3(side * 0.145, -0.035, 0))
		_capsule(hip, Vector3(0, -0.17, 0), 0.124, 0.46, Vector3.ONE, shorts)
		var knee := _pivot(hip, Vector3(0, -0.42, 0))
		_capsule(knee, Vector3(0, -0.145, 0), 0.078, 0.36, Vector3.ONE, skin)
		_box(knee, Vector3(0, -0.01, 0.062), Vector3(0.16, 0.15, 0.13), shorts)
		_capsule(knee, Vector3(0, -0.33, 0), 0.079, 0.23, Vector3.ONE, sock)
		_box(knee, Vector3(0, -0.46, 0.053), Vector3(0.19, 0.13, 0.31), sock)
		_box(knee, Vector3(0, -0.504, 0.053), Vector3(0.20, 0.04, 0.32), accent)
		hips.append(hip)
		knees.append(knee)

	var front_number := _number_label(chest, number, Vector3(0, 0.33, 0.177), 0.0047)
	var back_number := _number_label(chest, number, Vector3(0, 0.33, -0.177), 0.0047)
	back_number.rotate_y(PI)
	front_number.outline_size = 2
	back_number.outline_size = 2
	var tag := _number_label(body, number, Vector3(0, 1.42, 0), 0.010)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("ffb998") if away else Color("adf4ff")
	apply_state({"position": position, "yaw_deg": 180.0 if away else 0.0, "pose": "Ready"})

func apply_state(state: Dictionary) -> void:
	position = state.position
	rotation.y = deg_to_rad(float(state.yaw_deg))
	var progress := float(state.get("pose_progress", 0.0))
	var wave := sin(progress * PI)
	var stride := float(state.get("stride", 0.0))
	var weight := float(state.get("stride_weight", 0.0))
	var swing := sin(stride) * weight
	var pose := str(state.pose)

	body.position.y = 0.91 + weight * (0.06 + absf(sin(stride)) * 0.045)
	chest.rotation = Vector3(0.13 + weight * 0.16, swing * 0.15, 0)
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var step := swing * side
		hips[index].rotation = Vector3(-0.20 + step * 0.9, 0, side * 0.10)
		knees[index].rotation.x = 0.35 + maxf(0.0, step) * 0.95
		shoulders[index].rotation = Vector3(-0.36 - step * 0.95, 0, side * 0.16)
		elbows[index].rotation.x = -0.64 - weight * 0.26

	match pose:
		"Approach":
			chest.rotation.x += wave * 0.23
			body.position.y -= wave * 0.07
			for index in range(2):
				knees[index].rotation.x += wave * 0.18
				shoulders[index].rotation.x += wave * 0.86
		"Dig":
			body.position.y -= 0.13 * wave
			chest.rotation.x += 0.24 * wave
			for index in range(2):
				hips[index].rotation.x -= 0.30 * wave
				knees[index].rotation.x += 0.45 * wave
				shoulders[index].rotation.x = -1.26
				shoulders[index].rotation.z *= -0.7
				elbows[index].rotation.x = -0.15
		"Set", "JumpCover":
			for index in range(2):
				shoulders[index].rotation.x = -0.85 - 1.75 * wave
				elbows[index].rotation.x = -0.85 + 0.68 * wave
			if pose == "JumpCover":
				body.position.y += 0.62 * wave
		"Spike":
			body.position.y += 0.82 * wave
			chest.rotation.y = -0.50 * cos(progress * PI)
			shoulders[0].rotation.x = -0.45 - 1.85 * wave
			shoulders[1].rotation.x = -0.65 - 2.35 * smoothstep(0.0, 0.50, progress) + 2.15 * smoothstep(0.52, 1.0, progress)
			elbows[1].rotation.x = -1.15 + smoothstep(0.24, 0.45, progress)

func _pivot(parent: Node3D, center: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.position = center
	parent.add_child(joint)
	return joint

func _number_label(parent: Node3D, number: String, center: Vector3, pixel_size: float) -> Label3D:
	var label := Label3D.new()
	label.text = number
	label.font_size = 70
	label.pixel_size = pixel_size
	label.outline_size = 13
	label.outline_modulate = Color("142038")
	label.position = center
	parent.add_child(label)
	return label

func _capsule(parent: Node3D, center: Vector3, radius: float, height: float, proportions: Vector3, material: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 3
	_part(parent, mesh, center, proportions, material)

func _box(parent: Node3D, center: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_part(parent, mesh, center, Vector3.ONE, material)

func _part(parent: Node3D, mesh: PrimitiveMesh, center: Vector3, proportions: Vector3, material: Material) -> void:
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = center
	part.scale = proportions
	parent.add_child(part)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
