extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var multiplayer_scene = preload("res://scenes/multplayer_player.tscn")
# Called when the node enters the scene tree for the first time.
var _players_spawn_node

func become_host():
	print("Iniciando como host...")

	# Carrega a cena diretamente antes de configurá-la
	var scene = preload("res://scenes/gameMultplay/main.tscn").instantiate()
	get_tree().root.add_child(scene)  # Adiciona a cena à árvore de nós
	get_tree().current_scene = scene  # Define a nova cena como a "atual"

	# Verifica se a cena possui o nó 'Bird'
	if not scene.has_node("Bird"):
		print("Erro: O nó 'Bird' não foi encontrado na cena carregada!")
		return
	
	_players_spawn_node = scene.get_node("Bird")
	print("Nó 'Bird' encontrado:", _players_spawn_node)
	
	# Configuração do servidor
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)

	_remove_simgle_player()

	_add_player_to_game(1)
	
func join_as_player_2():
	print(" as player 2")
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	
	_remove_simgle_player()
	
	
func _add_player_to_game(id: int):
	print("Player %s join" % id)
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	
	
	
func _del_player(id: int):
	print("Player %s left" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()

func _remove_simgle_player():
	print("remove simgle player")
	var scene = preload("res://scenes/gameMultplay/main.tscn").instantiate()
	get_tree().root.add_child(scene)  # Adiciona a cena à árvore de nós
	get_tree().current_scene = scene  # Define a nova cena como a "atual"

	# Verifica se a cena possui o nó 'Bird'
	if not scene.has_node("Bird"):
		print("Erro: O nó 'Bird' não foi encontrado na cena carregada!")
		return
	var player_to_remove = scene.get_node("Bird")
	player_to_remove.queue_free()
