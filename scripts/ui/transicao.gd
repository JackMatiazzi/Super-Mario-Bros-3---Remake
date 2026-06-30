extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var fade_rect = $FadeRect

# Agora a função exige que você passe um texto (String) com o caminho da cena
func fechar_tela_retangulo(caminho_da_proxima_cena: String) -> void:
	var tween = create_tween()
	# Anima de 0.0 para 1.0 (Tela fica totalmente preta)
	tween.tween_property(color_rect.material, "shader_parameter/progresso", 1.0, 1.0)
	
	# Espera a tela ficar preta
	await tween.finished 
	
	# Troca para a cena que foi passada no parâmetro!
	get_tree().change_scene_to_file(caminho_da_proxima_cena)
	abrir_tela_retangulo()

func abrir_tela_retangulo() -> void:
	var tween = create_tween()
	tween.tween_property(color_rect.material, "shader_parameter/progresso", 0.0, 0.0)

func fade_out(caminho_da_proxima_cena: String) -> void:
	var tween = create_tween()
	
	# Anima a propriedade de cor para ficar totalmente preta e opaca (Alpha 1.0)
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	
	await tween.finished
	get_tree().change_scene_to_file(caminho_da_proxima_cena)
	fade_in()

func fade_in() -> void:
	var tween = create_tween()
	
	# Faz o inverso: anima a cor de volta para preto transparente (Alpha 0.0)
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)
