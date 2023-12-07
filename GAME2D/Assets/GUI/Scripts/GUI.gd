extends CanvasLayer

onready var player : KinematicBody2D = get_tree().get_nodes_in_group("Player")[0]

func _ready():
	get_node("AnimationPlayer").play("Fade-In")
	get_node("TextureProgress").max_value = player.health

func _process(_delta):
	if is_instance_valid(player):
		get_node("TextureProgress").value = player.health
		get_node("ScoreContainer/Label").text = str("x ") + str(GLOBAL.coins)

func _on_TextureProgress_value_changed(value):
	if value <= 0:
		get_node("AnimationPlayer").play("Fade-Out")

func _on_AnimationPlayer_animation_started(anim_name):
	match anim_name:
		"Fade-Out":
			get_tree().paused = true
			get_node("Control/VBoxContainer").visible = true
			get_node("Sounds/GameOver").play()
		"Fade-In":
			get_node("Control/VBoxContainer").visible = false

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"Fade-In":
			get_tree().paused = false

func _on_GameOver_finished():
	get_tree().call_deferred("reload_current_scene")
