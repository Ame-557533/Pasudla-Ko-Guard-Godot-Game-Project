extends CanvasLayer

signal score_updated(current_score: int, max_score: int)

@export var max_score: int = 5

# Using @export_file prevents circular dependencies entirely
@export_file("*.tscn") var next_level_path: String = ""
@export_file("*.tscn") var first_level_path: String = "res://Scenes/level_1.tscn"

var current_score: int = 0

@onready var score_label: Label = $ScoreLabel
@onready var level_complete_popup: Control = $LevelCompletePopup
@onready var title_label: Label = $LevelCompletePopup/VBoxContainer/TitleLabel
@onready var prompt_label: Label = $LevelCompletePopup/VBoxContainer/PromptLabel
@onready var yes_button: Button = $LevelCompletePopup/VBoxContainer/HBoxContainer/YesButton
@onready var no_button: Button = $LevelCompletePopup/VBoxContainer/HBoxContainer/NoButton
@onready var fade_rect: ColorRect = $FadeRect

func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS

	if level_complete_popup:
		level_complete_popup.visible = false

	if fade_rect:
		fade_rect.visible = true
		fade_rect.color.a = 1.0
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 0.0, 0.6)
		tween.tween_callback(func(): fade_rect.visible = false)
		
	if yes_button and not yes_button.pressed.is_connected(_on_yes_button_pressed):
		yes_button.pressed.connect(_on_yes_button_pressed)
	if no_button and not no_button.pressed.is_connected(_on_no_button_pressed):
		no_button.pressed.connect(_on_no_button_pressed)
		
	update_score_ui()

func add_score(amount: int = 1) -> void:
	current_score += amount
	update_score_ui()
	
	if current_score >= max_score:
		show_completion_ui()

func update_score_ui() -> void:
	if score_label:
		score_label.text = "Trash: %d/%d" % [current_score, max_score]
	score_updated.emit(current_score, max_score)

func show_completion_ui() -> void:
	if not level_complete_popup:
		return
		
	level_complete_popup.visible = true
	get_tree().paused = true

	# Levels 1 to 4: next_level_path is assigned
	if next_level_path != "":
		if title_label:
			title_label.text = "Level Complete!"
		if prompt_label:
			prompt_label.text = "You cleaned up the trash! Proceed to your next area?"
		if yes_button:
			yes_button.text = "Next Level"
		if no_button:
			no_button.text = "Restart"
	# Level 5: next_level_path is LEFT EMPTY
	else:
		if title_label:
			title_label.text = "Congratulations!"
		if prompt_label:
			prompt_label.text = "You threw all the trash into the bin and made it to class, 
			although you are a bit late!"
		if yes_button:
			yes_button.text = "Play Again"
		if no_button:
			no_button.text = "Exit Game"

func _on_yes_button_pressed() -> void:
	get_tree().paused = false
	await _fade_to_black()
	
	if next_level_path != "":
		# Advances to Level 2, 3, 4, 5
		get_tree().change_scene_to_file(next_level_path)
	elif first_level_path != "":
		# Level 5: Restarts back to Level 1
		get_tree().change_scene_to_file(first_level_path)

func _on_no_button_pressed() -> void:
	get_tree().paused = false
	
	if next_level_path != "":
		# Restarts current level for intermediate levels
		await _fade_to_black()
		get_tree().reload_current_scene()
	else:
		# Quits game on Level 5
		get_tree().quit()

func _fade_to_black() -> void:
	if fade_rect:
		fade_rect.visible = true
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 0.4)
		await tween.finished
