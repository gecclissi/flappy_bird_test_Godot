extends Node2D

@onready var name_input = $NameInput
@onready var start_button = $StartButton
@onready var error_message = $StartButton/ErrorNick
@onready var error_message_change = $ChangeNickButton/ErrorNick
@onready var change_nick_button = $ChangeNickButton
@onready var name_edit_input = $NameChangeInput
@onready var control = $Control
@onready var ranking_list = $Control/ItemList
@onready var continue_game_button = $ContinueGameButton
@onready var new_game_button = $NewGameButton


func _ready() -> void:
	name_input.text = VarsGlobal.nick_name
	if name_input:
		name_input.connect("text_submitted", Callable(self, "_start_game"))
	else:
		print("Erro: Nó 'LineEdit' não encontrado!")
		
	start_button.connect("pressed",Callable(self,"_on_start_pressed"))
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_text_submitted(text)->void:
	_start_game()

func _on_start_pressed()->void:
	_start_game()

func _start_game() -> void:
	if name_input.text == "":
		error_message.popup()
	else:
		VarsGlobal.nick_name = name_input.text
		name_input.hide()
		start_button.hide()
		name_edit_input.text = name_input.text
		name_edit_input.show()
		change_nick_button.show()
		control.show()
		continue_game_button.show()
		new_game_button.show()
		var ranking = await  ApiManager.get_scores(VarsGlobal.nick_name)
		print(ranking)
		if !ranking.has("history") || len(ranking["history"]) <= 0:  # Verifica se houve erro
			print("Erro ao carregar o ranking: ", ranking.error)
			return
		
		ranking_list.clear()  # Limpa os itens existentes
		
		# Adiciona os itens do ranking ao ItemList
		for entry in ranking.history:
			print(entry)
			var score_date = entry["created_at"]
			var player_score = entry["score"]
			ranking_list.add_item(str(player_score))
	#	get_tree().change_scene_to_file("res://scenes/game/main.tscn")

		var item_list = $Control/ItemList
		if item_list.get_item_count() > 0:  # Verifica se há itens no ItemList
			item_list.select(0)  # Seleciona o primeiro item (índice 0)
			update_selected_item()  # Atualiza as variáveis automaticamente
		

func _on_change_nick_button_pressed() -> void:
	if name_input.text == "":
		error_message_change.dialog_text = "Nick Name Invalido"
		error_message_change.popup()
	else:
		var result = await  ApiManager.update_name(name_input.text,name_edit_input.text)
		if result.has("error"):
			error_message_change.dialog_text = "Erro ao alterar nome"
			error_message_change.popup()


#func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	#var score = ranking_list.get_item_text(index)
	#VarsGlobal.score_game = int(score)
	#continue_game_button.disabled = false


func _on_new_game_button_pressed() -> void:
	VarsGlobal.score_game = 0
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")


func _on_continue_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")


func update_selected_item() -> void:
	var selected_indices = $Control/ItemList.get_selected_items()
	if selected_indices.size() > 0:  # Garante que há algo selecionado
		var selected_index = selected_indices[0]
		var selected_text = $Control/ItemList.get_item_text(selected_index)
		print("Item selecionado automaticamente:", selected_text)

		# Atualiza VarsGlobal e habilita o botão
		VarsGlobal.score_game = int(selected_text)  # Converte o texto em número
		continue_game_button.disabled = false  # Habilita o botão
	else:
		print("Nenhum item está selecionado.")
		continue_game_button.disabled = true  # Desabilita o botão se nada estiver selecionado
