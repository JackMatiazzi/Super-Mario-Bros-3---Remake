class_name Hud extends CanvasLayer

@export var player_path: NodePath
@export var tempo_inicial := 300

@onready var power_bar: ProgressBar = $Root/HudBar/PowerBar
@onready var coins_value: Label = $Root/HudBar/CoinsValue
@onready var score_value: Label = $Root/HudBar/ScoreValue
@onready var state_value: Label = $Root/HudBar/StateValue
@onready var time_value: Label = $Root/HudBar/TimeValue

var tempo_restante := 300.0
var player: Mario


func _ready() -> void:
	tempo_restante = tempo_inicial
	if player_path != NodePath():
		player = get_node_or_null(player_path) as Mario


func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Mario
	tempo_restante = max(tempo_restante - delta, 0.0)
	_update_values()


func _update_values() -> void:
	if player == null:
		time_value.text = str(int(ceil(tempo_restante)))
		return
	power_bar.value = player.flight_charge / player.FLIGHT_CHARGE_TIME
	coins_value.text = "COIN %02d" % player.moedas
	score_value.text = "%07d" % player.pontos
	state_value.text = _state_text()
	time_value.text = str(int(ceil(tempo_restante)))


func _state_text() -> String:
	match player.state:
		Mario.MarioState.ADULTO:
			return "SUPER"
		Mario.MarioState.RACCOON:
			return "RACCOON"
	return "SMALL"
