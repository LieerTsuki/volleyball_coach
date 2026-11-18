class_name VerticalCourtLayout
extends RefCounted

const COURT_WIDTH_M := 9.0
const COURT_LENGTH_M := 18.0
const ATTACK_LINE_FROM_NET_M := 3.0
const MIN_TOUCH_TARGET := 88.0

var minimum_touch_target: float = MIN_TOUCH_TARGET

func court_rect(viewport_size: Vector2, top_padding: float = 150.0, bottom_padding: float = 300.0) -> Rect2:
	var available_width: float = maxf(240.0, viewport_size.x - 32.0)
	var available_height: float = maxf(360.0, viewport_size.y - top_padding - bottom_padding)
	var court_width: float = minf(available_width, available_height * COURT_WIDTH_M / COURT_LENGTH_M)
	var court_height: float = court_width * COURT_LENGTH_M / COURT_WIDTH_M
	var left: float = (viewport_size.x - court_width) * 0.5
	var top: float = top_padding + maxf(0.0, (available_height - court_height) * 0.5)
	return Rect2(left, top, court_width, court_height)

func world_to_screen(position: Vector3, rect: Rect2) -> Vector2:
	var x: float = rect.position.x + (position.x + COURT_WIDTH_M * 0.5) / COURT_WIDTH_M * rect.size.x
	var y: float = rect.position.y + (position.z + COURT_LENGTH_M * 0.5) / COURT_LENGTH_M * rect.size.y
	return Vector2(x, y)

func screen_to_world(screen_position: Vector2, rect: Rect2) -> Vector3:
	var x: float = (screen_position.x - rect.position.x) / rect.size.x * COURT_WIDTH_M - COURT_WIDTH_M * 0.5
	var z: float = (screen_position.y - rect.position.y) / rect.size.y * COURT_LENGTH_M - COURT_LENGTH_M * 0.5
	return Vector3(clampf(x, -COURT_WIDTH_M * 0.5, COURT_WIDTH_M * 0.5), 0.0, clampf(z, -COURT_LENGTH_M * 0.5, COURT_LENGTH_M * 0.5))

func attack_line_screen_y(rect: Rect2, side: int) -> float:
	var center_y: float = rect.position.y + rect.size.y * 0.5
	var offset: float = ATTACK_LINE_FROM_NET_M / COURT_LENGTH_M * rect.size.y
	return center_y + offset * float(side)
