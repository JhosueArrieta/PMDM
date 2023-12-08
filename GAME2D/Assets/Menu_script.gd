extends Control

func _ready():
	var main_menu_button = preload("res://Assets/MainMenuButton.tscn")
	var buttons = ["JUGAR","CONFIGURACIÓN","SALIR","TUTORIAL"]
	
	for i in range (buttons.size()):
		var instance = main_menu_button.instance()
		instance.text = buttons[i]
		match i:
			0:
				instance.connect("pressed",self, "load_scene", ["res://Assets/Terrain/Jungle/Level.tscn"])
			1:
				instance.connect("pressed",self, "load_scene")
			2:
				instance.connect("pressed",self, "quit")
			3: 
				instance.connect("pressed",self,"load_scene", ["res://Assets/Terrain/Jungle/Level1.tscn"])
		$CenterContainer/PanelContainer/VBoxContainer/Buttons.add_child(instance)


func load_scene(scene: String) -> void:
	var error_code = get_tree().change_scene(scene)
	if error_code != 0:
		print("Error: ", error_code)

func quit():
	get_tree().quit()
	
