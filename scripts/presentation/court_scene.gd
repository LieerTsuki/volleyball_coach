class_name CourtScene
extends Node3D

func build(config: Dictionary) -> void:
	var width := float(config.get("widthM", 9.0)); var length := float(config.get("lengthM", 18.0)); var net_height := float(config.get("netHeightM", 2.43));
	_add_box("CourtFloor", Vector3(0, -0.08, 0), Vector3(width, 0.16, length), Color("20586c"))
	_add_box("CenterLine", Vector3(0, 0.02, 0), Vector3(width, 0.025, 0.06), Color.WHITE)
	_add_box("AttackLineHome", Vector3(0, 0.03, -float(config.get("attackLineOffsetM", 3.0))), Vector3(width, 0.025, 0.045), Color.WHITE)
	_add_box("AttackLineAway", Vector3(0, 0.03, float(config.get("attackLineOffsetM", 3.0))), Vector3(width, 0.025, 0.045), Color.WHITE)
	_add_box("Net", Vector3(0, net_height * 0.5, 0), Vector3(width, net_height, 0.06), Color("1d2630"))

func _add_box(node_name: String, center: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new(); mesh.size = size; mesh.material = StandardMaterial3D.new(); mesh.material.albedo_color = color; var node := MeshInstance3D.new(); node.name = node_name; node.mesh = mesh; node.position = center; add_child(node)
