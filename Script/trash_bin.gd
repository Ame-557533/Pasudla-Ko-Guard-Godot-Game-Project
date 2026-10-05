extends Area2D

@export var target_score: int = 5

func _ready() -> void:
	add_to_group("score_zone")
	add_to_group("trash_bin")
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	_check_and_deposit_trash(area)

func _on_body_entered(body: Node2D) -> void:
	_check_and_deposit_trash(body)

func _check_and_deposit_trash(node: Node) -> void:
	# 1. Double check if node is trash (via group, method, or name)
	var is_trash_item = node.is_in_group("trash") or node.has_method("hold_in_hand") or "trash" in node.name.to_lower()
	if not is_trash_item:
		return

	# 2. Ignore trash sitting on floor unthrown
	if "is_thrown" in node and not node.is_thrown:
		return

	print("SCORE ZONE ENTERED BY TRASH: ", node.name)

	# 3. Search for HUD
	var hud = _find_hud()

	if hud and hud.has_method("add_score"):
		print("SUCCESS: Trash scored! Freeing node.")
		hud.add_score(1)
		node.queue_free() # Destroys trash so player can't recall it
	else:
		push_warning("WARNING: Trash hit ScoreZone, but HUD node was NOT found!")

func _find_hud() -> CanvasLayer:
	var hud_node = get_tree().get_first_node_in_group("hud")
	if hud_node is CanvasLayer:
		return hud_node
		
	if get_tree().current_scene:
		var found = get_tree().current_scene.find_child("HUD", true, false)
		if found is CanvasLayer:
			return found
			
	for child in get_tree().root.get_children():
		if child is CanvasLayer and child.has_method("add_score"):
			return child
			
	return null
