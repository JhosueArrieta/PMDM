extends KinematicBody2D

# El principio de la refactorización consiste en cambiar el código sin cambiar el comportamiento para facilitar la lectura y por lo tanto la tarea de actualizar el software.

const SPEED = 128
const FLOOR = Vector2(0, -1)
const GRAVITY = 16
const JUMP_HEIGHT = 500
const BOUNCING_JUMP = 112 # Esta constante es para definir la fuerza de rebote en la pared.
onready var motion : Vector2 = Vector2.ZERO
var can_move : bool # Esta variable es para comprobar si el personaje puede moverse.

""" STATE MACHINE """
var playback : AnimationNodeStateMachinePlayback


func _ready() -> void:
	playback = $AnimationTree.get("parameters/playback") # Obtenemos la referencia al parámetro playback del nodo AnimationTree.
	playback.start("Idle") # Iniciamos en el estado Idle.
	$AnimationTree.active = true # Y activamos el AnimationTree


func _process(_delta) -> void:
	motion_ctrl()
	jump_ctrl()
	attack_ctrl()


# Al separar los comportamientos en distintas funciones, la función de movimiento ha quedado mucho más limpia y comprensible a simple vista.
func motion_ctrl() -> void:
	motion.y += GRAVITY
	
	if can_move: # Aquí se indica que solo podrá moverse si can_move es igual a true.
		motion.x =  GLOBAL.get_axis().x * SPEED
		
		if GLOBAL.get_axis().x == 0:
			playback.travel("Idle")
		elif GLOBAL.get_axis().x == 1:
			playback.travel("Run")
			$Sprite.flip_h = false
		elif GLOBAL.get_axis().x == -1:
			playback.travel("Run")
			$Sprite.flip_h = true
		
		match playback.get_current_node():
			"Idle":
				motion.x =  0
				$Particles.emitting = false
			"Run":
				$Particles.emitting = true
				
	# Como he añadido los Raycast dentro de un position únicamente tenemos que cambiar la escala del nodo padre para invertir sus nodos hijos. Al ser un código más sencillo se puede prescindir de la función direction_ctrl() creada anteriormente.
	match $Sprite.flip_h:
		true:
			$Raycast.scale.x = -1
		false:
			$Raycast.scale.x = 1
			
	motion = move_and_slide(motion, FLOOR)
	
	var slide_count = get_slide_count() # Retorna el número de veces que el cuerpo está colisionando.
	
	if slide_count: # Si fuera superior a 0 es igual a true.
		# Así que guardamos en una variable el objeto colisionado y en otra su collider.
		var collision = get_slide_collision(slide_count - 1)
		var collider = collision.collider
		
		# Si pertenece al grupo Platform y presionamos abajo, desactivamos el collider del player y activamos el timer.
		if collider.is_in_group("Platform") and Input.is_action_just_pressed("ui_down"):
			$Collision.disabled = true
			$Timer.start()


func _on_Timer_timeout():
	# Cuando el tiempo termina, se activa nuevamente el collider, es una forma de hacer esto.
	$Collision.disabled = false


# Separamos la función de salto igualmente para mantener orden en el código y facilitar así la lectura.
func jump_ctrl() -> void:
	match is_on_floor():
		true: # Aquí comprobamos si el personaje se encuentra tocando el suelo.
			can_move = true # En caso afirmativo, can_move es igual a true.
		
			if Input.is_action_just_pressed("jump"):
				$Sounds/Jump.play()
				motion.y -= JUMP_HEIGHT
			
		false: # Aquí comprobamos si el personaje no se encuentra tocando el suelo.
			$Particles.emitting = false # En caso negativo, se desactiva la emisión de partículas.
		
			if motion.y < 0:
				playback.travel("Jump")
			else:
				playback.travel("Fall")
			
			if $Raycast/Wall.is_colliding(): # Tenemos que comprobar primero si ha colisionado, de lo contrario arrojaría un error.
				
				var body = $Raycast/Wall.get_collider() # Creo esta variable para guardar las colisiones.
			
				if body.is_in_group("Terrain"): # Comprobamos si el personaje se encuentra tocando la pared.
					can_move = false # Y en caso afirmativo, can_move es igual a false. Movemos esta comprobación aquí para que solo bloquee el movimiento si colisiona con una pared.
					
					if Input.is_action_just_pressed("jump"):
						$Sounds/Jump.play()
						motion.y -= JUMP_HEIGHT
						
						if $Sprite.flip_h:
							motion.x += BOUNCING_JUMP
							$Sprite.flip_h = false
						else:
							motion.x -= BOUNCING_JUMP
							$Sprite.flip_h = true


# Creamos una función para controlar el ataque del personaje.
func attack_ctrl() -> void:
	var body = $Raycast/Hit.get_collider() # Utilizamos el mismo procedimiento que para detectar la colisión con la pared.
	
	if is_on_floor():
		if GLOBAL.get_axis().x == 0 and Input.is_action_just_pressed("attack"):
			match playback.get_current_node():
				"Idle":
					playback.travel("Attack-1")
					$Sounds/Sword.play()
				"Attack-1":
					playback.travel("Attack-2")
					$Sounds/Sword.play()
				"Attack-2":
					playback.travel("Attack-3")
					$Sounds/Sword.play()
					
			if $Raycast/Hit.is_colliding(): 
				if body.is_in_group("Enemy"):
					body.damage_ctrl(3)