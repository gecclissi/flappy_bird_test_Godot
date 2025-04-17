extends Node

@export var pipe_scene : PackedScene
@export var bird_scene : PackedScene

var game_running : bool
var game_over : bool
var scroll
var score
const SCROLL_SPEED : int = 4
var screen_size : Vector2i
var ground_height : int
var pipes : Array
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

# Multiplayer
var players = {}
const PORT = 4242
const MAX_PLAYERS = 4

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	scroll = 0  # Inicialização explícita
	new_game()
	# Configuração multiplayer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	if "--server" in OS.get_cmdline_args():
		start_server()

func start_server():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT)
	if err != OK:
		print("Erro ao criar servidor: ", err)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Servidor iniciado na porta ", PORT)
	new_game()

func join_server(ip = "localhost"):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		print("Erro ao conectar ao servidor: ", err)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Conectando ao servidor ", ip)

func _on_peer_connected(id):
	print("Jogador conectado: ", id)
	# Só o servidor instancia novos jogadores
	if multiplayer.is_server():
		_spawn_player(id)
		setup_local_bird()

func _on_peer_disconnected(id):
	print("Jogador desconectado: ", id)
	if multiplayer.is_server():
		_despawn_player(id)

func _on_connected_to_server():
	print("Conectado ao servidor!")
	# Jogador local é spawnado pelo servidor

func _on_connection_failed():
	print("Falha na conexão!")
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")

func new_game():
	#reset variables
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	$ScoreLabel.text = "SCORE: " + str(score)
	$GameOver.hide()
	get_tree().call_group("pipes", "queue_free")
	pipes.clear()
	
	# Só o servidor controla o jogo
	if multiplayer.is_server():
		#generate starting pipes
		generate_pipes()
		# Reseta todos os pássaros
		for player_id in players:
			players[player_id].rpc("reset")

func _spawn_player(id):
	var bird = bird_scene.instantiate()
	bird.name = str(id)
	bird.set_multiplayer_authority(id)
	add_child(bird)
	players[id] = bird
	
	# Configura posição inicial (distribui os pássaros na tela)
	var x_pos = screen_size.x / 4
	var y_pos = screen_size.y / (MAX_PLAYERS + 1) * (players.size())
	bird.position = Vector2(x_pos, y_pos)
	
	# Conecta sinais
	if bird.has_signal("hit"):
		bird.hit.connect(bird_hit.bind(id))
	
	# Configura controle local
	if id == multiplayer.get_unique_id():
		bird.set_local(true)
	else:
		bird.set_local(false)

func _despawn_player(id):
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

@rpc("any_peer", "call_local")
func start_game():
	if not multiplayer.is_server():
		return
	
	game_running = true
	#start pipe timer
	$PipeTimer.start()
	
	# Ativa todos os pássaros
	for player_id in players:
		players[player_id].rpc("start_flying")

func _input(event):
	if game_over:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not game_running:
				if multiplayer.is_server():
					start_game()
				else:
					rpc_id(1, "start_game") # Envia para o servidor
			else:
				# Apenas o jogador local pode bater asas
					var local_bird = players.get(multiplayer.get_unique_id(), null)
					if local_bird and local_bird.flying:
						local_bird.flap()
					check_top()
func setup_local_bird():
	for bird in $Players.get_children():
		if bird.get_multiplayer_authority() == multiplayer.get_unique_id():
			bird.set_local(true)
			print("Jogador local identificado:", bird.name)

# Chamado apenas no servidor
func _process(delta):
	if not multiplayer.is_server() or not game_running:
		return
	
	scroll += SCROLL_SPEED
	#reset scroll
	if scroll >= screen_size.x:
		scroll = 0
	#move ground node
	$Ground.position.x = -scroll
	#move pipes
	for pipe in pipes:
		pipe.position.x -= SCROLL_SPEED

	# Sincroniza estado do jogo com os clientes
	rpc("update_game_state", scroll, $Ground.position)

@rpc("reliable")
func update_game_state(current_scroll, ground_position):
	if multiplayer.is_server():
		return
	
	scroll = current_scroll
	$Ground.position = ground_position

func _on_pipe_timer_timeout():
	if multiplayer.is_server():
		generate_pipes()
	
func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2  + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)
	
	# Sincroniza com os clientes
	rpc("spawn_pipe", pipe.position)

@rpc("reliable")
func spawn_pipe(position):
	if multiplayer.is_server():
		return
	
	var pipe = pipe_scene.instantiate()
	pipe.position = position
	add_child(pipe)
	pipes.append(pipe)

func scored():
	if not multiplayer.is_server():
		return
	
	score += 1
	$ScoreLabel.text = "SCORE: " + str(score)
	rpc("update_score", score)

@rpc("reliable")
func update_score(new_score):
	score = new_score
	$ScoreLabel.text = "SCORE: " + str(score)

func check_top():
	if $Bird.position.y < 0:
		bird_hit($Bird.get_multiplayer_authority())

func stop_game():
	if not multiplayer.is_server():
		return
	
	$PipeTimer.stop()
	$GameOver.show()
	game_running = false
	game_over = true
	
	# Para todos os pássaros
	for player_id in players:
		players[player_id].rpc("stop_flying")
	
	rpc("show_game_over")

@rpc("reliable")
func show_game_over():
	$GameOver.show()

func bird_hit(player_id):
	if not multiplayer.is_server():
		return
	
	if players.has(player_id):
		players[player_id].rpc("hit")
		# Verifica se todos os jogadores morreram
		var all_dead = true
		for id in players:
			if players[id].is_flying():
				all_dead = false
				break
		
		if all_dead:
			stop_game()

func _on_ground_hit(player_id):
	bird_hit(player_id)

func _on_game_over_restart():
	if multiplayer.is_server():
		new_game()
		rpc("restart_game")
	else:
		rpc_id(1, "_on_game_over_restart")

@rpc("reliable")
func restart_game():
	new_game()
