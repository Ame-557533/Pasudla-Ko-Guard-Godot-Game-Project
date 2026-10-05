extends CharacterBody2D

const SPEED = 110.0
const JUMP_VELOCITY = -250.0

@export var max_throw_force: float = 900.0
@export var force_multiplier: float = 4.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var carry_position: Marker2D = $CarryPosition

var held_trash_queue: Array[Area2D] = []
var trajectory_dots: Array[Vector2] = []
var is_aiming: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var can_throw: bool = false
var can_move: bool = false

func _ready() -> void:
	add_to_group("player")
	can_throw = false
	is_aiming = false
	trajectory_dots.clear()
	queue_redraw()
		
	call_deferred("_connect_to_hud")
	call_deferred("_check_initial_throw_boundary")

func _process(_delta: float) -> void:
	held_trash_queue = held_trash_queue.filter(func(item): return is_instance_valid(item))

	for i in range(held_trash_queue.size()):
		var trash = held_trash_queue[i]
		if is_instance_valid(trash) and not trash.is_thrown:
			trash.global_position = carry_position.global_position
			trash.visible = (i == 0)

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity.x = 0
		if is_on_floor() and animated_sprite:
			animated_sprite.play("idle")
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		if animated_sprite:
			animated_sprite.play("run")
			animated_sprite.flip_h = (direction < 0)
		if carry_position:
			carry_position.position.x = -abs(carry_position.position.x) if direction < 0 else abs(carry_position.position.x)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if animated_sprite:
			animated_sprite.play("idle")

	move_and_slide()

func _input(event: InputEvent) -> void:
	if not can_move or held_trash_queue.is_empty():
		return

	# Force cancel aiming and clear dots if outside boundary
	if not can_throw:
		if is_aiming:
			is_aiming = false
			trajectory_dots.clear()
			queue_redraw()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_aiming = true
			drag_start_pos = get_global_mouse_position()
		elif is_aiming and not event.pressed:
			is_aiming = false
			trajectory_dots.clear()
			queue_redraw()
			
			if can_throw:
				throw_trash()

	if event is InputEventMouseMotion and is_aiming:
		update_trajectory()

func equip_trash(trash: Area2D) -> void:
	if not is_instance_valid(trash) or trash in held_trash_queue:
		return

	held_trash_queue.append(trash)
	if trash.has_method("hold_in_hand"):
		trash.hold_in_hand()

func return_trash_to_queue(trash: Area2D) -> void:
	if not is_instance_valid(trash):
		return
	trash.is_thrown = false
	trash.velocity = Vector2.ZERO
	if trash.has_method("hold_in_hand"):
		trash.hold_in_hand()
		
	if not trash in held_trash_queue:
		held_trash_queue.push_front(trash)

func get_throw_velocity() -> Vector2:
	var current_mouse = get_global_mouse_position()
	var drag_vector = drag_start_pos - current_mouse
	var launch_velocity = drag_vector * force_multiplier
	return launch_velocity.limit_length(max_throw_force)

func update_trajectory() -> void:
	trajectory_dots.clear()
	var start_pos = carry_position.global_position
	var vel = get_throw_velocity()
	var throw_gravity = 980.0
	
	# Compact length settings
	var max_points = 22      # Controls arc length
	var time_step = 0.035    # Fine-tunes spacing between dots
	
	var sim_pos = start_pos
	var sim_vel = vel
	
	for i in range(max_points):
		trajectory_dots.append(sim_pos)
		sim_pos += sim_vel * time_step
		sim_vel.y += throw_gravity * time_step
		
	queue_redraw()

func _draw() -> void:
	# Only draw custom dots while aiming
	if is_aiming and not trajectory_dots.is_empty():
		var total = trajectory_dots.size()
		for i in range(total):
			var alpha = 1.0 - (float(i) / float(total)) # Fades from bright to transparent
			var dot_pos = to_local(trajectory_dots[i])
			draw_circle(dot_pos, 1.8, Color(1, 1, 1, alpha)) # Small 1.8px radius dots

func throw_trash() -> void:
	if held_trash_queue.is_empty():
		return

	var trash_to_throw = held_trash_queue.pop_front()
	var throw_vel = get_throw_velocity()

	if is_instance_valid(trash_to_throw):
		trash_to_throw.visible = true
		if trash_to_throw.has_method("launch"):
			trash_to_throw.launch(throw_vel)
			
	# Clear dots instantly after throw
	trajectory_dots.clear()
	queue_redraw()

func _connect_to_hud() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud and get_tree().current_scene:
		hud = get_tree().current_scene.find_child("HUD", true, false)
		
	if hud and hud.has_signal("score_updated"):
		if not hud.score_updated.is_connected(_on_hud_score_updated):
			hud.score_updated.connect(_on_hud_score_updated)
		if "current_score" in hud and "max_score" in hud:
			_on_hud_score_updated(hud.current_score, hud.max_score)

func _check_initial_throw_boundary() -> void:
	can_throw = false
	
	await get_tree().physics_frame
	await get_tree().physics_frame

	var boundary: Area2D = null
	if get_tree().current_scene:
		boundary = get_tree().current_scene.find_child("ThrowBoundary", true, false) as Area2D
	
	if not boundary:
		boundary = get_tree().get_first_node_in_group("throw_boundary") as Area2D

	if boundary:
		var bodies = boundary.get_overlapping_bodies()
		var areas = boundary.get_overlapping_areas()
		if self in bodies or self in areas:
			can_throw = true
			print("PLAYER SPAWNED INSIDE THROW BOUNDARY: can_throw = true")
		else:
			can_throw = false
			print("PLAYER SPAWNED OUTSIDE THROW BOUNDARY: can_throw = false")

func _on_hud_score_updated(current_score: int, max_s: int) -> void:
	var overhead_label = get_node_or_null("ScoreLabel")
	if not overhead_label:
		overhead_label = find_child("ScoreLabel", true, false)
	if overhead_label:
		overhead_label.text = "%d/%d" % [current_score, max_s]
