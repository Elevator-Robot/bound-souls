extends Node

const STARTING_SOUL: Dictionary = {
	"name": "Shadowclaw",
	"element": "fire",
	"level": 1,
	"max_hp": 40,
	"attack": 48,
	"defense": 32,
	"sprite": "res://assets/sprites/sprite7_idle.png",
	"sprite_attack": "res://assets/sprites/sprite7_attack.png",
	"evolves_to": "Crystalwing",
	"evolves_at": 16
}

var player_souls: Array[Dictionary] = []
var active_soul_index: int = 0
var souls_collected: int = 0
var last_battle_result: String = ""


func _ready() -> void:
	_ensure_starter_soul()


func reset_run() -> void:
	player_souls.clear()
	active_soul_index = 0
	last_battle_result = ""
	_ensure_starter_soul()


func get_active_soul() -> Dictionary:
	_ensure_starter_soul()
	var clamped_index: int = clamp(active_soul_index, 0, player_souls.size() - 1)
	return player_souls[clamped_index]


func _ensure_starter_soul() -> void:
	if player_souls.is_empty():
		player_souls.append(STARTING_SOUL.duplicate(true))
	souls_collected = player_souls.size()
