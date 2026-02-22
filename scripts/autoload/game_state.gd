extends Node

const SOUL_SPECIES: Dictionary = {
	"Shadowclaw": {
		"element": "fire",
		"base_hp": 40,
		"base_attack": 48,
		"base_defense": 32,
		"sprite": "res://assets/sprites/sprite7_idle.png",
		"sprite_attack": "res://assets/sprites/sprite7_attack.png",
		"evolves_to": "Crystalwing",
		"evolves_at": 16
	},
	"Crystalwing": {
		"element": "fire",
		"base_hp": 48,
		"base_attack": 54,
		"base_defense": 42,
		"sprite": "res://assets/sprites/sprite8_idle.png",
		"sprite_attack": "res://assets/sprites/sprite8_attack.png",
		"evolves_to": "Blazeclaw",
		"evolves_at": 32
	},
	"Blazeclaw": {
		"element": "fire",
		"base_hp": 58,
		"base_attack": 62,
		"base_defense": 50,
		"sprite": "res://assets/sprites/sprite9_idle.png",
		"sprite_attack": "res://assets/sprites/sprite9_attack.png"
	}
}
const STARTING_SOUL: Dictionary = {
	"name": "Shadowclaw",
	"level": 1
}

var player_souls: Array[Dictionary] = []
var active_soul_index: int = 0
var souls_collected: int = 0
var last_battle_result: String = ""
var encounters_enabled: bool = true


func _ready() -> void:
	_ensure_starter_soul()


func reset_run() -> void:
	player_souls.clear()
	active_soul_index = 0
	last_battle_result = ""
	encounters_enabled = true
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
	_apply_evolution_for_level(soul)
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
		"sprite": species.get("sprite", ""),
		"sprite_attack": species.get("sprite_attack", "")
	}
	if species.has("evolves_to"):
		soul["evolves_to"] = species["evolves_to"]
		soul["evolves_at"] = species["evolves_at"]
	_recalculate_soul_stats(soul)
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


func _apply_evolution_for_level(soul: Dictionary) -> void:
	while true:
		var species_name: String = soul.get("name", "")
		var species: Dictionary = SOUL_SPECIES.get(species_name, {})
		if species.is_empty() or not species.has("evolves_to"):
			return
		if int(soul.get("level", 1)) < int(species["evolves_at"]):
			return

		var evolved_name: String = species["evolves_to"]
		var evolved_data: Dictionary = SOUL_SPECIES.get(evolved_name, {})
		soul["name"] = evolved_name
		soul["element"] = evolved_data.get("element", soul.get("element", "fire"))
		soul["sprite"] = evolved_data.get("sprite", soul.get("sprite", ""))
		soul["sprite_attack"] = evolved_data.get("sprite_attack", soul.get("sprite_attack", ""))
		if evolved_data.has("evolves_to"):
			soul["evolves_to"] = evolved_data["evolves_to"]
			soul["evolves_at"] = evolved_data["evolves_at"]
		else:
			soul.erase("evolves_to")
			soul.erase("evolves_at")
