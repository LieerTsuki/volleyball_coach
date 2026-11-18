extends SceneTree

func _init() -> void:
	var layout_script = load("res://scripts/presentation/vertical_court_layout.gd")
	if layout_script == null:
		push_error("VerticalCourtLayout script is missing")
		quit(1)
		return
	var layout = layout_script.new()
	var rect: Rect2 = layout.court_rect(Vector2(1080, 1920))
	if absf(rect.size.x / rect.size.y - 0.5) > 0.001:
		push_error("Court must keep a 9:18 proportion")
		quit(1)
		return
	var source := Vector3(2.25, 0.0, -6.0)
	var screen: Vector2 = layout.world_to_screen(source, rect)
	var restored: Vector3 = layout.screen_to_world(screen, rect)
	if source.distance_to(restored) > 0.001:
		push_error("Court coordinate conversion must round-trip")
		quit(1)
		return
	if layout.minimum_touch_target < 88.0:
		push_error("Touch target is too small")
		quit(1)
		return
	print("vertical court layout tests passed")
	quit(0)
