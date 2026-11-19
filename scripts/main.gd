extends Control

var repository := TacticRepository.new()
var tactic: Dictionary
var editor: TacticEditor2D
var replay: TacticReplay3D
var remembered_tactic_id := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_viewport_resized)
	tactic = repository.resume_tactic()
	remembered_tactic_id = str(tactic.id)
	editor = TacticEditor2D.new()
	add_child(editor)
	editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor.set_repository(repository)
	editor.set_tactic(tactic)
	editor.replay_requested.connect(_open_replay)
	editor.save_requested.connect(_save_tactic)
	editor.document_changed.connect(_on_document_changed)
	editor.document_opened.connect(_on_document_opened)

	replay = TacticReplay3D.new()
	replay.hide()
	add_child(replay)
	replay.editor_requested.connect(_open_editor)
	replay.save_requested.connect(_save_tactic)

func _open_replay() -> void:
	tactic = TacticModels.ensure_frames(tactic)
	editor.stop_preview()
	replay.set_tactic(tactic)
	editor.visible = false
	replay.visible = true
	replay.restart()

func _open_editor() -> void:
	replay.visible = false
	editor.visible = true
	editor.set_tactic(tactic)

func _save_tactic() -> void:
	var error := _persist_tactic()
	if replay.visible:
		replay.show_save_result(error)
	else:
		editor.show_save_result(error, true)

func _on_document_changed() -> void:
	tactic = editor.tactic
	editor.show_save_result(_persist_tactic())

func _on_document_opened() -> void:
	tactic = editor.tactic
	editor.show_save_result(OK)
	_remember_open_tactic()

func _persist_tactic() -> Error:
	var error := repository.save(tactic)
	if error == OK:
		_remember_open_tactic()
	return error

func _remember_open_tactic() -> void:
	var tactic_id := str(tactic.id)
	var error := OK
	if tactic_id != remembered_tactic_id:
		error = repository.remember_tactic(tactic_id)
	if error == OK:
		remembered_tactic_id = tactic_id
	editor.show_session_result(error)

func _on_viewport_resized() -> void:
	if editor:
		editor.queue_redraw()
