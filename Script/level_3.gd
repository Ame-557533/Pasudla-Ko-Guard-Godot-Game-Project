extends Node2D



func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 1. Allow the player to move immediately in Level 3
		if "can_move" in player:
			player.can_move = true
		else:
			player.set_physics_process(true)
			
		# 2. OPTIONAL: If Level 3 allows throwing anywhere without a ThrowZone Area2D
		if "can_throw" in player:
			player.can_throw = true
