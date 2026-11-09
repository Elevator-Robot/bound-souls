extends Node

const SOUL_SPECIES: Dictionary = {
	"Whisp": {
		"element": "wind",
		"base_hp": 40,
		"base_attack": 48,
		"base_defense": 40,
		"scene": "res://assets/sprites/whisp-complete-battle.tscn"
	},
	"Nyx": {
		"element": "dark",
		"base_hp": 42,
		"base_attack": 50,
		"base_defense": 34,
		"scene": "res://assets/sprites/nyx-complete-battle.tscn"
	},
	"Moss": {
		"element": "grass",
		"base_hp": 48,
		"base_attack": 42,
		"base_defense": 45,
		"scene": "res://assets/sprites/moss-complete-battle.tscn"
	},
	"Maw": {
		"element": "dark",
		"base_hp": 38,
		"base_attack": 55,
		"base_defense": 32,
		"scene": "res://assets/sprites/maw-complete-battle.tscn"
	},
	"Malgharok": {
		"element": "fire",
		"base_hp": 40,
		"base_attack": 48,
		"base_defense": 32,
		"scene": "res://assets/sprites/malgharok-complete-battle.tscn"
	},
	"Khefret": {
		"element": "earth",
		"base_hp": 52,
		"base_attack": 40,
		"base_defense": 58,
		"scene": "res://assets/sprites/khefret-complete-battle.tscn"
	},
	"Juniper": {
		"element": "water",
		"base_hp": 32,
		"base_attack": 52,
		"base_defense": 28,
		"scene": "res://assets/sprites/juniper-complete-battle.tscn"
	}
}
const STARTING_SOUL: Dictionary = {
	"name": "Whisp",
	"level": 1
}

var player_souls: Array[Dictionary] = []
var active_soul_index: int = 0
var souls_collected: int = 0
var last_battle_result: String = ""
var encounters_enabled: bool = true
var position_before_battle: Vector2 = Vector2.ZERO
var should_restore_position_after_battle: bool = false


func _ready() -> void:
	_ensure_starter_soul()


func reset_run() -> void:
	player_souls.clear()
	active_soul_index = 0
	last_battle_result = ""
	encounters_enabled = true
	position_before_battle = Vector2.ZERO
	should_restore_position_after_battle = false
	_ensure_starter_soul()


func get_active_soul() -> Dictionary:
	_ensure_starter_soul()
	var clamped_index: int = clamp(active_soul_index, 0, player_souls.size() - 1)
	return player_souls[clamped_index]


func set_active_soul_level(new_level: int) -> bool:
	if new_level < 1 or new_level > 100:
		return false

	_ensure_starter_soul()
	var clamped_index: int = clamp(active_soul_index, 0, player_souls.size() - 1)
	var soul: Dictionary = player_souls[clamped_index]
	soul["level"] = new_level
	_recalculate_soul_stats(soul)
	player_souls[clamped_index] = soul
	return true


func set_encounters_enabled(enabled: bool) -> void:
	encounters_enabled = enabled


func _ensure_starter_soul() -> void:
	if player_souls.is_empty():
		player_souls.append(_create_soul(STARTING_SOUL["name"], STARTING_SOUL["level"]))
	souls_collected = player_souls.size()


func _create_soul(species_name: String, level: int) -> Dictionary:
	var species: Dictionary = SOUL_SPECIES.get(species_name, {})
	var soul: Dictionary = {
		"name": species_name,
		"element": species.get("element", "fire"),
		"level": level,
		"scene": species.get("scene", "")
	}
	_recalculate_soul_stats(soul)
	return soul


func create_wild_soul(species_name: String) -> Dictionary:
	# Preserve the original level-one encounter stat range, without player growth bonuses.
	var soul: Dictionary = _create_soul(species_name, 1)
	var species: Dictionary = SOUL_SPECIES[species_name]
	soul["max_hp"] = species["base_hp"]
	soul["attack"] = species["base_attack"]
	soul["defense"] = species["base_defense"]
	soul["current_hp"] = soul["max_hp"]
	return soul


func _recalculate_soul_stats(soul: Dictionary) -> void:
	var species_name: String = soul.get("name", "")
	var species: Dictionary = SOUL_SPECIES.get(species_name, {})
	if species.is_empty():
		return

	var level: int = int(soul.get("level", 1))
	soul["max_hp"] = int(species.get("base_hp", 1)) + (level * 2)
	soul["attack"] = int(species.get("base_attack", 1)) + (level * 3)
	soul["defense"] = int(species.get("base_defense", 1)) + (level * 3)
	soul["current_hp"] = soul["max_hp"]
