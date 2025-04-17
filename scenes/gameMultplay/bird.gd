extends CharacterBody2D

# Constantes de física
const GRAVITY : int = 1000
const MAX_VEL : int = 600
const FLAP_SPEED : int = -500
const START_POS = Vector2(100, 400)

# Variáveis de estado
var flying : bool = false
var falling : bool = false
var is_local : bool = false

# Variáveis sincronizadas (se estiver usando MultiplayerSynchronizer)
@export var sync_velocity : Vector2
@export var sync_position : Vector2
@export var sync_rotation : float

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configura o multiplayer
	set_multiplayer_authority(str(name).to_int())
	
	# Só processa input se for o jogador local
	set_process_input(is_local)
	reset()

# Função para definir se é o jogador local
func set_local(value : bool):
	is_local = value
	set_process_input(is_local)
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 1 if value else 0.7)

# Reset do pássaro (chamado pelo servidor)
@rpc("call_local", "reliable")
func reset():
	falling = false
	flying = false
	position = START_POS
	velocity = Vector2.ZERO
	rotation = 0
	$AnimatedSprite2D.stop()

# Inicia o voo (chamado pelo servidor)
@rpc("call_local", "reliable")
func start_flying():
	flying = true
	falling = false
	$AnimatedSprite2D.play()

# Para o voo (chamado pelo servidor)
@rpc("call_local", "reliable")
func stop_flying():
	flying = false
	$AnimatedSprite2D.stop()

# Chamada quando o pássaro bate em algo
@rpc("call_local", "reliable")
func hit():
	if not falling:  # Só cai se não estava já caindo
		falling = true
		flying = false
		$AnimatedSprite2D.stop()

# Chamada quando o jogador bate asas
@rpc("call_local", "reliable")
func flap():
	if flying and not falling:
		velocity.y = FLAP_SPEED
		# Efeito visual/sonoro local
		if is_local:
			$FlapSound.play()

func _input(event):
	if is_local and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if flying and not falling:
				# Chama localmente e no servidor
				rpc("flap")
				if multiplayer.is_server():
					flap()

# Lógica de física (rodando em todos os peers)
func _physics_process(delta):
	if not multiplayer.is_server() and not is_local:
		# Interpolação para pássaros remotos
		position = position.lerp(sync_position, delta * 10)
		rotation = lerp(rotation, sync_rotation, delta * 10)
		return
	
	if flying or falling:
		# Aplica gravidade
		velocity.y += GRAVITY * delta
		
		# Velocidade terminal
		if velocity.y > MAX_VEL:
			velocity.y = MAX_VEL
		
		# Rotação baseada na velocidade
		if flying:
			rotation = deg_to_rad(velocity.y * 0.05)
		elif falling:
			rotation = PI/2
		
		# Move o pássaro
		var collision = move_and_collide(velocity * delta)
		
		# Verifica colisões (só no servidor)
		if multiplayer.is_server() and collision:
			var collider = collision.get_collider()
			if collider.is_in_group("pipes") or collider.is_in_group("ground"):
				rpc("hit")
				if collider.is_in_group("ground"):
					# Notifica o main que bateu no chão
					get_parent().ground_hit.emit(get_multiplayer_authority())
		
		# Atualiza variáveis sincronizadas
		sync_velocity = velocity
		sync_position = position
		sync_rotation = rotation

# Função para verificar se está voando (usada pelo Main)
func is_flying() -> bool:
	return flying and not falling
