extends CanvasLayer

signal restart

@onready var list_ranking = $Control/ItemList
@onready var continue_buton = $ContinueButton
@onready var change_nick_button = $ChangeNickButton



func _on_game_over_visibility_changed():
	if is_visible():
		var result = await ApiManager.guardar_score(VarsGlobal.nick_name,VarsGlobal.score_game)
		print(result)
		print("CanvasLayer agora está visível!")
		var ranking = await ApiManager.get_ranking()
		if len(ranking) <= 0:  # Verifica se houve erro
			print("Erro ao carregar o ranking: ", ranking.error)
			return
		
		list_ranking.clear()  # Limpa os itens existentes

		# Adiciona os itens do ranking ao ItemList
		for entry in ranking:
			var player_name = entry["name"]
			var player_score = entry["max_score"]
			list_ranking.add_item(player_name + ": " + str(player_score))
	else:
		print("CanvasLayer foi ocultado.")
	
func _on_restart_button_pressed():
	restart.emit()
	self.hide()


func _on_continue_button_pressed() -> void:
	get_tree().reload_current_scene()
	self.hide()
