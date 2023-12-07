extends KinematicBody2D

const SPEED = 128
const FLOOR = Vector2(0, -1)
const GRAVITY = 16
const JUMP_HEIGHT = 550
const BOUNCING_JUMP = 112

var motion : Vector2 = Vector2.ZERO
var can_move : bool
var immunity : bool = false
var health : int = 5

var playback : AnimationNodeStateMachinePlayback

func _ready():
	playback = get_node("AnimationTree").get("parameters/playback")
	playback.start("Idle")
	get_node("AnimationTree").active = true

func _process(_delta):
	motion_ctrl()
	jump_ctrl()
	attack_ctrl()

func motion_ctrl() -> void:
	motion.y += GRAVITY
	
	if can_move:
		motion.x =  GLOBAL.get_axis().x * SPEED
		
		if GLOBAL.get_axis().x == 0:
			playback.travel("Idle")
		elif GLOBAL.get_axis().x == 1:
			playback.travel("Run")
			get_node("Sprite").flip_h = false
		elif GLOBAL.get_axis().x == -1:
			playback.travel("Run")
			get_node("Sprite").flip_h = true
		
		match playback.get_current_node():
			"Idle":
				motion.x =  0
				get_node("Particles").emitting = false
			"Run":
				get_node("Particles").emitting = true
	
	match get_node("Sprite").flip_h:
		true:
			get_node("Raycast").scale.x = -1
		false:
			get_node("Raycast").scale.x = 1
	
	motion = move_and_slide(motion, FLOOR)
	
	var slide_count = get_slide_count()
	
	if slide_count:
		var collision = get_slide_collision(slide_count - 1)
		var collider = collision.collider
		
		if collider.is_in_group("Platform") and Input.is_action_just_pressed("ui_down"):
			get_node("Collision").disabled = true
			get_node("Timer").start()

func jump_ctrl() -> void:
	match is_on_floor():
		true:
			can_move = true
			
			if Input.is_action_just_pressed("jump"):
				get_node("Sounds/Jump").play()
				motion.y -= JUMP_HEIGHT
		
		false:
			get_node("Particles").emitting = false
			
			if motion.y < 0:
				playback.travel("Jump")
			else:
				playback.travel("Fall")
			
			if get_node("Raycast/Wall").is_colliding():
				var body = get_node("Raycast/Wall").get_collider()
				
				if body.is_in_group("Terrain"):
					can_move = false
					
					if Input.is_action_just_pressed("jump"):
						get_node("Sounds/Jump").play()
						motion.y -= JUMP_HEIGHT
						
						if get_node("Sprite").flip_h:
							motion.x += BOUNCING_JUMP
							get_node("Sprite").flip_h = false
						else:
							motion.x -= BOUNCING_JUMP
							get_node("Sprite").flip_h = true

func attack_ctrl() -> void:
	var body = get_node("Raycast/Hit").get_collider()
	
	if is_on_floor():
		if GLOBAL.get_axis().x == 0 and Input.is_action_just_pressed("attack"):
			match playback.get_current_node():
				"Idle":
					playback.travel("Attack-1")
					get_node("Sounds/Sword").play()
				"Attack-1":
					playback.travel("Attack-2")
					get_node("Sounds/Sword").play()
				"Attack-2":
					playback.travel("Attack-3")
					get_node("Sounds/Sword").play()
					
			if get_node("Raycast/Hit").is_colliding(): 
				if body.is_in_group("Enemy"):
					body.damage_ctrl(3)

func damage_ctrl(damage : int) -> void:
	match immunity:
		false:
			health -= damage
			get_node("AnimationPlayer").play("Hit")
			get_node("Sounds/Hit").play()
			immunity = true

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"Hit":
			immunity = false

func _on_Timer_timeout():
	get_node("Collision").disabled = false
