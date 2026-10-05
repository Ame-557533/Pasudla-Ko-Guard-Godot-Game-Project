extends Control

signal dialogue_finished

@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DialogueLabel

@export var characters_per_second: float = 30.0

var dialogue_data: Array[Dictionary] = []
var current_line_index: int = 0
var is_active: bool = false
var tween: Tween

func start_dialogue(lines: Array[Dictionary]) -> void:
	dialogue_data = lines
	current_line_index = 0
	is_active = true
	visible = true
	_show_line()

# Change _input to _unhandled_input so UI clicks trigger properly
func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	# Check for key presses, mouse clicks, or UI accept actions (Space/Enter)
	if event.is_pressed() and not event.is_echo():
		if event is InputEventKey or event is InputEventMouseButton or event.is_action_pressed("ui_accept"):
			if tween and tween.is_running():
				tween.kill()
				dialogue_label.visible_ratio = 1.0
			else:
				_next_line()

func _show_line() -> void:
	if current_line_index < dialogue_data.size():
		var line_info = dialogue_data[current_line_index]
		
		speaker_label.text = line_info.get("speaker", "NPC")
		dialogue_label.text = line_info.get("text", "")
		dialogue_label.visible_ratio = 0.0
		
		var duration: float = dialogue_label.text.length() / characters_per_second
		
		if tween:
			tween.kill()
			
		tween = create_tween()
		tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	else:
		_end_dialogue()

func _next_line() -> void:
	current_line_index += 1
	_show_line()

func _end_dialogue() -> void:
	if tween:
		tween.kill()
	is_active = false
	visible = false
	dialogue_finished.emit()
