extends Node2D

@onready var play_button = $PlayButton
@onready var exit_button = $ExitButton
@onready var options_button = $OptionsButton
@onready var multplayer_button = $MultplayerButton

func _ready():
	play_button.connect("pressed", Callable(self, "_on_play_pressed"))
	exit_button.connect("pressed", Callable(self, "_on_exit_pressed"))
	options_button.connect("pressed", Callable(self, "_on_options_pressed"))
	multplayer_button.connect("pressed", Callable(self, "_on_multplayer_pressed"))


func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/set_name.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://scenes/OptionsMenu.tscn")
	

func _on_exit_pressed():
	get_tree().quit()
	
	
func _on_multplayer_pressed():
	get_tree().change_scene_to_file("res://scenes/MultplayerMenu.tscn")
