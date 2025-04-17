extends Node

@onready var play_button = $PlayButton
@onready var exit_button = $ExitButton
@onready var host_button = $MultplayerHUD/Controls/VBoxContainer/HostGame
@onready var join_button = $MultplayerHUD/Controls/VBoxContainer/JoinAsPlayer2
@onready var back_button = $MultplayerHUD/JoinMenu/BackButton
@onready var connect_button = $MultplayerHUD/JoinMenu/ConnectButton
@onready var ip_input = $MultplayerHUD/JoinMenu/IPInput
@onready var status_label = $MultplayerHUD/JoinMenu/StatusLabel

func _ready() -> void:
	# Conecta todos os botões
	play_button.connect("pressed", Callable(self, "_on_play_pressed"))
	exit_button.connect("pressed", Callable(self, "_on_exit_pressed"))
	host_button.connect("pressed", Callable(self, "_on_host_pressed"))
	join_button.connect("pressed", Callable(self, "_on_join_pressed"))
	connect_button.connect("pressed", Callable(self, "_on_connect_pressed"))
	
	# Esconde o menu de join inicialmente
	$MultplayerHUD/JoinMenu.hide()
	$MultplayerHUD/Controls.hide()
	status_label.text = ""

func _on_play_pressed():
	$PlayButton.hide()
	$ExitButton.hide()
	$MultplayerHUD/Controls.show()

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")

func _on_host_pressed():
	become_host()

func _on_join_pressed():
	join_as_player()


func _on_connect_pressed():
	_on_join_button_pressed()

## Lógica Multiplayer #########################################################

func become_host():
	status_label.text = "Iniciando servidor..."
	
	# Carrega a cena principal
	var main_scene = load("res://scenes/gameMultplay/main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	
	# Remove a cena atual
	get_tree().current_scene.queue_free()
	get_tree().current_scene = main_scene
	
	# Inicia o servidor
	main_scene.start_server()

func join_as_player():
	$MultplayerHUD/Controls.hide()
	$MultplayerHUD/JoinMenu.show()
	ip_input.grab_focus()

func _on_join_button_pressed() -> void:
	if ip_input.text == "":
		status_label.text = "Digite um IP válido"
		return
	
	status_label.text = "Conectando..."
	
	# Carrega a cena principal primeiro
	var main_scene = load("res://scenes/gameMultplay/main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	
	# Remove a cena atual
	get_tree().current_scene.queue_free()
	get_tree().current_scene = main_scene
	
	# Conecta ao servidor
	main_scene.join_server(ip_input.text)
	
	# Timeout de conexão
	await get_tree().create_timer(5.0).timeout
	if multiplayer.multiplayer_peer == null || multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		status_label.text = "Falha na conexão"
