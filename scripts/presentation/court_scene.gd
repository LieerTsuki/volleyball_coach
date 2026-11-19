class_name CourtScene
extends Node3D

const WOOD := preload("res://scripts/presentation/arena_wood.gdshader")
const NAVY := Color("172946")
const CONCOURSE := Color("24496a")
const CYAN := Color("53e3ff")
const CORAL := Color("ff7657")
const INK := Color("0b1428")
const WHITE := Color("fff4db")

var materials: Dictionary = {}

func build(config: Dictionary) -> void:
	var width := float(config.get("widthM", 9.0))
	var length := float(config.get("lengthM", 18.0))
	var free_zone := float(config.get("freeZoneM", 3.0))
	var net_height := float(config.get("netHeightM", 2.43))
	var half_width := width * 0.5
	var half_length := length * 0.5

	_box(Vector3(0, -0.32, 0), Vector3(44, 0.32, 48), INK)
	_box(Vector3(0, -0.14, 0), Vector3(width + 2 * free_zone, 0.18, length + 2 * free_zone), CONCOURSE)
	var floor_material := ShaderMaterial.new()
	floor_material.shader = WOOD
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(width, 0.12, length)
	_instance(floor_mesh, Vector3(0, -0.06, 0), floor_material)
	_box(Vector3(0, 0.008, 0), Vector3(width, 0.012, 0.05), WHITE)
	for side in [-1.0, 1.0]:
		var team_color := CYAN if side < 0.0 else CORAL
		var attack_z: float = side * float(config.get("attackLineOffsetM", 3.0))
		_box(Vector3(side * half_width, 0.008, 0), Vector3(0.05, 0.012, length), WHITE)
		_box(Vector3(0, 0.008, attack_z), Vector3(width, 0.012, 0.05), WHITE)
		_box(Vector3(0, 0.008, side * half_length), Vector3(width, 0.012, 0.05), WHITE)
		_box(Vector3(0, -0.043, side * (half_length + 1.27)), Vector3(width, 0.012, 0.14), team_color)
		_box(Vector3(side * (half_width + free_zone - 0.12), -0.043, 0), Vector3(0.05, 0.012, length + 2 * free_zone), CYAN)
		for bench in range(3):
			var z := -5.0 + bench * 4.0
			_box(Vector3(side * (half_width + 1.75), 0.19, z), Vector3(0.38, 0.45, 1.6), NAVY)
			_box(Vector3(side * (half_width + 1.75), 0.426, z), Vector3(0.39, 0.04, 1.6), team_color)

	_add_net(width, net_height)
	_add_stand(Vector3(-half_width - free_zone - 1.55, 0, 0), -PI * 0.5, 21)
	_add_stand(Vector3(0, 0, half_length + free_zone + 1.40), 0.0, 18)
	_add_scoreboard(half_length + free_zone + 3.60)
	_add_walls(half_width + free_zone + 5.7, half_length + free_zone + 5.7)

func _add_net(width: float, height: float) -> void:
	var span := width + 0.70
	var bottom := height - 0.97
	_box(Vector3(0, height, 0), Vector3(span, 0.07, 0.046), WHITE)
	_box(Vector3(0, bottom, 0), Vector3(span, 0.026, 0.024), WHITE)
	var mesh_size := Vector2i(65, 7)
	var strands: Array[Transform3D] = []
	var spacing := span / mesh_size.x
	for index in range(mesh_size.x + 1):
		strands.append(Transform3D(Basis.from_scale(Vector3(0.012, height - bottom, 0.012)), Vector3(index * spacing - span / 2.0, (height + bottom) * 0.5, 0)))
	for index in range(1, mesh_size.y):
		var y := lerpf(bottom, height, float(index) / mesh_size.y)
		strands.append(Transform3D(Basis.from_scale(Vector3(span, 0.012, 0.012)), Vector3(0, y, 0)))
	_batch(BoxMesh.new(), strands, [], _material(Color("b2cbcb")))
	for side in [-1.0, 1.0]:
		var x: float = side * (width * 0.5 + 0.35)
		_box(Vector3(x, height * 0.5, 0), Vector3(0.13, height + 0.35, 0.13), WHITE)
		_box(Vector3(x, 0.83, 0), Vector3(0.30, 1.66, 0.30), CYAN if side < 0.0 else CORAL)
		_box(Vector3(x, height + 0.37, 0), Vector3(0.035, 0.56, 0.035), CORAL)

func _add_stand(origin: Vector3, yaw: float, seats: int) -> void:
	var stand := Node3D.new()
	stand.position = origin
	stand.rotation.y = yaw
	add_child(stand)
	var people: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var shirts: Array[Color] = []
	var faces: Array[Color] = []
	var width := seats * 0.86 + 0.9
	var palette := [Color("315b8c"), Color("55afd1"), Color("e99069"), Color("809db1"), Color("645292")]
	var skin := [Color("d59b79"), Color("a66b4f"), Color("edba93")]
	for row in range(4):
		var y := 0.34 + row * 0.48
		var z := row * 0.97
		_box(Vector3(0, y * 0.5 - 0.13, z), Vector3(width, y, 0.97), NAVY, stand)
		_box(Vector3(0, y - 0.108, z - 0.47), Vector3(width, 0.046, 0.04), CONCOURSE, stand)
		for seat in range(seats):
			if seat == seats / 2 or (seat * 3 + row * 7) % 11 < 2:
				continue
			var x := (seat - (seats - 1) * 0.5) * 0.86
			people.append(Transform3D(Basis.IDENTITY, Vector3(x, y + 0.17, z)))
			heads.append(Transform3D(Basis.IDENTITY, Vector3(x, y + 0.49 + 0.035 * ((seat + row) % 3), z)))
			shirts.append(palette[(seat + 2 * row) % palette.size()])
			faces.append(skin[(seat * 2 + row) % skin.size()])

	var shirt_mesh := CapsuleMesh.new()
	shirt_mesh.radius = 0.21
	shirt_mesh.height = 0.54
	shirt_mesh.radial_segments = 6
	shirt_mesh.rings = 2
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.128
	head_mesh.height = 0.256
	head_mesh.radial_segments = 7
	head_mesh.rings = 3
	var crowd_material := StandardMaterial3D.new()
	crowd_material.vertex_color_use_as_albedo = true
	_batch(shirt_mesh, people, shirts, crowd_material, stand)
	_batch(head_mesh, heads, faces, crowd_material, stand)
	_box(Vector3(0, 2.15, 3.55), Vector3(width, 0.95, 0.32), INK, stand)
	_glow(Vector3(0, 2.27, 3.37), Vector3(width, 0.045, 0.032), CYAN, stand)
	_glow(Vector3(0, 0.17, -0.49), Vector3(width, 0.09, 0.041), CYAN, stand)

func _add_scoreboard(z: float) -> void:
	_box(Vector3(0, 4.3, z), Vector3(8.4, 2.9, 0.44), INK)
	_glow(Vector3(0, 5.68, z - 0.25), Vector3(8.4, 0.07, 0.045), CYAN)
	_glow(Vector3(3.72, 4.3, z - 0.25), Vector3(0.09, 1.94, 0.05), CYAN)
	_glow(Vector3(-3.72, 4.3, z - 0.25), Vector3(0.09, 1.94, 0.05), CORAL)
	_label("VOLLEYSKETCH", Vector3(0, 5.10, z - 0.26), 0.008, WHITE)
	_label("HOME", Vector3(2.05, 4.07, z - 0.26), 0.013, CYAN)
	_label("VS", Vector3(0, 4.07, z - 0.26), 0.009, WHITE)
	_label("AWAY", Vector3(-2.05, 4.07, z - 0.26), 0.013, CORAL)

func _add_walls(side: float, back: float) -> void:
	var wall := Color("142039")
	_box(Vector3(0, 3.45, back), Vector3(side * 2.1, 7.1, 0.36), wall)
	_box(Vector3(-side, 3.45, 0), Vector3(0.36, 7.1, back * 2.0), wall)
	_glow(Vector3(0, 6.32, back - 0.22), Vector3(side * 2.0, 0.06, 0.05), CYAN)
	_glow(Vector3(-side + 0.22, 6.32, 0), Vector3(0.05, 0.06, back * 1.95), CYAN)
	for bay in range(-3, 4):
		_box(Vector3(bay * side / 3.0, 3.45, back - 0.24), Vector3(0.32, 7.0, 0.24), NAVY)
		_box(Vector3(-side + 0.24, 3.45, bay * back / 3.0), Vector3(0.24, 7.0, 0.32), NAVY)
	for x in [-8.4, 8.4]:
		var p := Vector3(x, 6.92, back - 0.76)
		_box(p + Vector3.UP * 0.15, Vector3(3.7, 0.26, 1.22), NAVY)
		for index in range(6):
			_glow(p + Vector3(-1.4 + 0.56 * index, 0, 0), Vector3(0.43, 0.15, 0.52), WHITE)

func _material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var key := Vector2i(color.to_rgba32(), int(glowing))
	if not materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.82
		if glowing:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materials[key] = material
	return materials[key]

func _box(center: Vector3, size: Vector3, color: Color, parent: Node3D = null) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_instance(mesh, center, _material(color), parent)

func _glow(center: Vector3, size: Vector3, color: Color, parent: Node3D = null) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_instance(mesh, center, _material(color, true), parent)

func _instance(mesh: PrimitiveMesh, center: Vector3, material: Material, parent: Node3D = null) -> void:
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = center
	if parent == null:
		add_child(node)
	else:
		parent.add_child(node)

func _batch(mesh: PrimitiveMesh, transforms: Array[Transform3D], colors: Array[Color], material: Material, parent: Node3D = null) -> void:
	mesh.material = material
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = not colors.is_empty()
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for index in range(transforms.size()):
		batch.set_instance_transform(index, transforms[index])
		if batch.use_colors:
			batch.set_instance_color(index, colors[index])
	var node := MultiMeshInstance3D.new()
	node.multimesh = batch
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent == null:
		add_child(node)
	else:
		parent.add_child(node)

func _label(text: String, center: Vector3, pixel_size: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = pixel_size
	label.modulate = color
	label.position = center
	label.rotation.y = PI
	label.outline_size = 0
	add_child(label)
