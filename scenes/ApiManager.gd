extends Node

var base_url = "http://localhost:3000"  # URL base da API

# Requisição para salvar o score
func guardar_score(name: String, score: int) -> Dictionary:
	var body = {
		"name": name,
		"score": score
	}
	var request = HTTPRequest.new()
	add_child(request)

	# Configurando a requisição POST
	var headers = ["Content-Type: application/json"]
	var result = request.request(
		base_url + "/guardar_score",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

	if result != OK:
		return {"error": "Erro ao iniciar a requisição"}

	# Aguardando a conclusão da requisição
	var response = await request.request_completed
	var response_code = response[1]
	var response_body = response[3].get_string_from_utf8()

	# Processando resposta
	return _process_response(response_code, response_body)

# Requisição para obter o ranking
func get_ranking() -> Array:
	var request = HTTPRequest.new()
	add_child(request)

	# Configurando a requisição GET
	var result = request.request(
		base_url + "/ranking",
		[],
		HTTPClient.METHOD_GET
	)

	if result != OK:
		print("Erro: Não foi possível iniciar a requisição.")
		return []

	# Aguardando a conclusão da requisição
	var response = await request.request_completed
	if response.size() < 4:
		print("Erro: Resposta incompleta recebida.")
		return []
		
	var response_code = response[1]
	var response_body = response[3].get_string_from_utf8()
	
	var processed_response = _process_response(response_code, response_body)
	
	if processed_response.has("error"):
		print("Erro ao obter ranking:", processed_response.error)
		return []
	# Processando resposta
	return _process_response(response_code, response_body)

# Requisição para obter histórico de scores de um jogador
func get_scores(name: String) -> Dictionary:
	var request = HTTPRequest.new()
	add_child(request)

	# Configurando a requisição GET
	var result = request.request(
		base_url + "/scores/" + name,
		[],
		HTTPClient.METHOD_GET
	)

	if result != OK:
		return {"error": "Erro ao iniciar a requisição"}

	# Aguardando a conclusão da requisição
	var response = await request.request_completed
	var response_code = response[1]
	var response_body = response[3].get_string_from_utf8()

	# Processando resposta
	return _process_response(response_code, response_body)

# Requisição para atualizar o nome de um jogador
func update_name(oldName: String, newName: String) -> Dictionary:
	var body = {
		"oldName": oldName,
		"newName": newName
	}
	var request = HTTPRequest.new()
	add_child(request)

	# Configurando a requisição PUT
	var headers = ["Content-Type: application/json"]
	var result = request.request(
		base_url + "/update_name",
		headers,
		HTTPClient.METHOD_PUT,
		JSON.stringify(body)
	)

	if result != OK:
		return {"error": "Erro ao iniciar a requisição"}

	# Aguardando a conclusão da requisição
	var response = await request.request_completed
	var response_code = response[1]
	var response_body = response[3].get_string_from_utf8()

	# Processando resposta
	return _process_response(response_code, response_body)


# Função para processar a resposta da API
func _process_response(response_code: int, body: String) -> Variant:
	if response_code == 200:
		# Criando uma instância de JSON
		var json_instance = JSON.new()
		var parsed_json = json_instance.parse(body)
		if parsed_json == OK:
			return json_instance.get_data()
		else:
			print("Erro ao processar JSON recebido:", json_instance.get_error_message())
			return {"error": "Erro ao processar JSON recebido: " + json_instance.get_error_message()}
	else:
		print("Erro na resposta da API. Código:", str(response_code))
		return {"error": "Erro na resposta da API. Código: " + str(response_code)}
