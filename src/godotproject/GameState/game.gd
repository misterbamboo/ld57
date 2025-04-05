class_name Game extends Node

enum GameState {
	IN_ACTION,
	IN_SHOP,
	IN_GAME_MENU,
	GAME_OVER
}

static var instance: Game = null

var invincible := false
var state: GameState = GameState.IN_ACTION

func _ready():
	instance = self

func _process(delta: float) -> void:
	if Life.is_dead():
		change_state(GameState.GAME_OVER)

func change_state(new_state: GameState) -> void:
	state = new_state

func _toggle_invincibility():
	invincible = not invincible

# Getters pour simuler l'interface IGame
func get_state() -> GameState:
	return state

func is_invincible() -> bool:
	return invincible
