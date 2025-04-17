extends Node2D

@onready var volume_slider = $VolumeSlider
@onready var back_button = $BackButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if volume_slider:
		volume_slider.value = GlobalMusic.volume_db
		volume_slider.connect("value_changed",Callable(self, "_on_slider_value_changed"))
		print(volume_slider.value)
	else:
		print("Slider não encontrado!")
		
	back_button.connect("pressed",Callable(self,"_on_pressed_back"))
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed_back():
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")

func _on_slider_value_changed(value):
	GlobalMusic.volume_db = value
