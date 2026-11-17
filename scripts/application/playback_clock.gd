class_name PlaybackClock
extends Node

signal changed(time_ms: int)
var time_ms := 0
var duration_ms := 4000
var speed := 1.0
var playing := false

func configure(duration: int) -> void:
	duration_ms = max(1, duration); time_ms = clamp(time_ms, 0, duration_ms)

func _process(delta: float) -> void:
	if not playing: return
	time_ms += roundi(delta * 1000.0 * speed)
	if time_ms >= duration_ms: time_ms = duration_ms; playing = false
	changed.emit(time_ms)

func toggle() -> void: playing = not playing
func replay() -> void: time_ms = 0; playing = true; changed.emit(time_ms)
func seek(value: int) -> void: time_ms = clamp(value, 0, duration_ms); changed.emit(time_ms)
