extends Control

var repository := TacticRepository.new()
var tactic: Dictionary
var editor: TacticEditor2D
var replay: TacticReplay3D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_viewport_resized)
	tactic = TacticModels.ensure_frames(repository.ensure_sample())
	editor = TacticEditor2D.new()
	add_child(editor)
	editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor.set_tactic(tactic)
	editor.replay_requested.connect(_open_replay)
	editor.save_requested.connect(_save_tactic)

	replay = TacticReplay3D.new()
	add_child(replay)
	replay.set_tactic(tactic)
	replay.visible = false
	replay.editor_requested.connect(_open_editor)

func _open_replay() -> void:
	tactic = TacticModels.ensure_frames(tactic)
	replay.set_tactic(tactic)
	editor.visible = false
	replay.visible = true
	replay._restart()

func _open_editor() -> void:
	replay.playing = false
	replay.visible = false
	editor.visible = true
	editor.set_tactic(tactic)

func _save_tactic() -> void:
	repository.save(tactic)

func _on_viewport_resized() -> void:
	if editor:
		editor.queue_redraw()
