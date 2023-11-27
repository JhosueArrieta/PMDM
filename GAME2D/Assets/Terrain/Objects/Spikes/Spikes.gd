extends Area2D

func _on_Spikes_body_entered(body):
	if body.is_on_ground("Player"):
		body.damage_ctrl(5) #Llamamos a la funcion de daño y le hacemos 5 de daño 
