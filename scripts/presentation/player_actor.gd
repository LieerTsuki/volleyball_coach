class_name PlayerActor
extends Node3D

var player_id := ""
var torso: MeshInstance3D
var head: MeshInstance3D
var arm_l: MeshInstance3D
var arm_r: MeshInstance3D
var leg_l: MeshInstance3D
var leg_r: MeshInstance3D

func setup(definition: Dictionary) -> void:
	player_id = str(definition.id)
	var color := Color("e86b3a") if bool(definition.get("isReceiver", false)) else Color("369bd6")
	torso = _part(CapsuleMesh.new(), Vector3(0, 1.1, 0), Vector3(0.42, 1.0, 0.28), color)
	head = _part(SphereMesh.new(), Vector3(0, 2.02, 0), Vector3.ONE * 0.28, Color("f0c4a2"))
	arm_l = _part(CapsuleMesh.new(), Vector3(-0.48, 1.3, 0), Vector3(0.12, 0.55, 0.12), color)
	arm_r = _part(CapsuleMesh.new(), Vector3(0.48, 1.3, 0), Vector3(0.12, 0.55, 0.12), color)
	leg_l = _part(CapsuleMesh.new(), Vector3(-0.18, 0.42, 0), Vector3(0.14, 0.55, 0.14), color)
	leg_r = _part(CapsuleMesh.new(), Vector3(0.18, 0.42, 0), Vector3(0.14, 0.55, 0.14), color)
	var label := Label3D.new(); label.text = str(definition.get("jerseyNumber", "")); label.font_size = 64; label.modulate = Color.WHITE; label.position = Vector3(0, 1.2, -0.31); add_child(label)

func apply_state(state: Dictionary) -> void:
	position = state.position; rotation.y = deg_to_rad(float(state.yaw_deg)); var progress := float(state.pose_progress); var wave := sin(progress * PI); var pose := str(state.pose)
	var crouch := 0.18 if pose in ["Ready", "Dig"] else 0.0; torso.position.y = 1.1 - crouch; head.position.y = 2.02 - crouch
	var arm_angle := -55.0 * wave if pose == "Set" else (60.0 if pose == "Dig" else (-35.0 - 80.0 * wave if pose == "Spike" else 0.0))
	arm_l.rotation.x = deg_to_rad(arm_angle); arm_r.rotation.x = deg_to_rad(arm_angle)
	var jump := wave * 0.6 if pose in ["Spike", "JumpCover"] else 0.0; position.y = jump

func _part(mesh: PrimitiveMesh, local_position: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	mesh.material = StandardMaterial3D.new(); mesh.material.albedo_color = color; var node := MeshInstance3D.new(); node.mesh = mesh; node.position = local_position; node.scale = scale_value; add_child(node); return node
