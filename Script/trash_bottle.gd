extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_thrown: bool = false
var velocity: Vector2 = Vector2.ZERO
var throw_gravity: float = 980.0

func _ready() -> void:
	add_to_group("trash")
	
	if sprite:
		sprite.play()
		
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if is_thrown:
		velocity.y += throw_gravity * delta
		position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if _is_scorezone(body):
		return

	if is_thrown:
		if body.is_in_group("ground") or "ground" in body.name.to_lower():
			return_to_player()
		return

	if not is_thrown and body.is_in_group("player") and body.has_method("equip_trash"):
		body.equip_trash(self)

func _on_area_entered(area: Area2D) -> void:
	if _is_scorezone(area):
		return
		
	if is_thrown and (area.is_in_group("ground") or "bounds" in area.name.to_lower()):
		return_to_player()

func _is_scorezone(node: Node) -> bool:
	if node.is_in_group("score_zone") or node.is_in_group("trash_bin"):
		return true
	var low_name = node.name.to_lower()
	return "score" in low_name or "bin" in low_name

func hold_in_hand() -> void:
	if sprite:
		sprite.stop()
		sprite.frame = 0

func launch(initial_velocity: Vector2) -> void:
	visible = true
	is_thrown = true
	velocity = initial_velocity
	
	if sprite:
		sprite.play()

func return_to_player() -> void:
	is_thrown = false
	velocity = Vector2.ZERO
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("return_trash_to_queue"):
		player.return_trash_to_queue(self)
