extends CharacterBody3D

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D

var health = 1
var kills = 0
var deaths = 0

# mvmt
const SPEED = 10.0
const JUMP_VELOCITY = 10.0
var gravity = 20.0

# dash
var DASH_SPEED = 30
var is_dashing = false

var can_shoot = true
var can_dash = true


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # fix mouse cursor to center of screen
	camera.current = true
	
	## are you sure should init here?
	GameManager.Players[multiplayer.get_unique_id()].kills = 0
	GameManager.Players[multiplayer.get_unique_id()].deaths = 0

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .001) ## need setting to adjust both x, y sens
		camera.rotate_x(-event.relative.y * .001)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2) # avoid camera somersault??
		
	if Input.is_action_just_pressed("shoot") and can_shoot: ## need ui indicator for cooldown
		play_shoot_effects() ## animation effects, nothing for now
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			if hit_player.has_method("receive_damage"): # safety check
				var hit_player_id = hit_player.get_multiplayer_authority()
				hit_player.receive_damage.rpc_id(hit_player_id)
				var player_name = GameManager.Players[hit_player_id]["name"]
				print("You've neutralized " + player_name + "!")
		
		can_shoot = false
		await get_tree().create_timer(1.0).timeout
		can_shoot = true
		
	if Input.is_action_just_pressed("dash") and can_dash:
		print("dashing")
		play_dash_effects()
		var dash_dir = -transform.basis.z.normalized()
		velocity += dash_dir * DASH_SPEED
		is_dashing = true
		can_dash = false
		await get_tree().create_timer(0.2).timeout
		is_dashing = false
		await get_tree().create_timer(1.8).timeout
		can_dash = true


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not is_dashing:
		var input_dir := Input.get_vector("left", "right", "up", "down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
func play_shoot_effects():
	# stop animation player first for gun animations
	pass
	
func play_dash_effects():
	pass
	
@rpc("any_peer")
func receive_damage():
	if multiplayer.get_remote_sender_id() in GameManager.Players:
		GameManager.Players[multiplayer.get_remote_sender_id()].kills += 1
		GameManager.update_player_score.rpc(
			multiplayer.get_remote_sender_id(),
			GameManager.Players[multiplayer.get_remote_sender_id()].kills,
			GameManager.Players[multiplayer.get_remote_sender_id()].deaths
		)
	# Update own deaths
	deaths += 1
	GameManager.Players[multiplayer.get_unique_id()].deaths = deaths
	GameManager.update_player_score.rpc(
		multiplayer.get_unique_id(),
		GameManager.Players[multiplayer.get_unique_id()].kills,
		deaths
	)
	# respawn
	position = Vector3.ZERO
		
