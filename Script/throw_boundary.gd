extends Area2D

func _ready() -> void:
	add_to_group("throw_boundary")
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)

func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		body.can_throw = true
		print("PLAYER ENTERED BOUNDARY")

func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		body.can_throw = false
		print("PLAYER EXITED BOUNDARY")

func _on_area_entered(area: Area2D) -> void:
	if _is_player(area):
		area.can_throw = true

func _on_area_exited(area: Area2D) -> void:
	if _is_player(area):
		area.can_throw = false

func _is_player(node: Node) -> bool:
	return node.is_in_group("player") or "student" in node.name.to_lower() or "player" in node.name.to_lower()
