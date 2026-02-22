extends Control

const BACKGROUND_PATHS: PackedStringArray = [
	"res://assets/backgrounds/background1.png",
	"res://assets/backgrounds/background2.png",
	"res://assets/backgrounds/background3.png"
]
const BATTLE_SOUNDS: Dictionary = {
	"attack": "res://assets/audio/sfx/button_fx/fx/jump/button_fx_jump_001_01_cc0_avr.wav",
	"damage": "res://assets/audio/sfx/button_fx/fx/noise/button_fx_noise_008_cc0_avr.wav",
	"run": "res://assets/audio/sfx/button_fx/fx/delay/button_fx_delay_006_002_cc0_avr.wav",
	"victory": "res://assets/audio/sfx/button_fx/fx/magic/button_fx_magic_009_cc0_avr.wav"
}

const ENEMY_SOUL_POOL: Array[Dictionary] = [
	{"name": "Flamewing", "element": "grass", "level": 1, "max_hp": 35, "attack": 45, "defense": 30, "sprite": "res://assets/sprites/sprite1_idle.png", "sprite_attack": "res://assets/sprites/sprite1_attack.png", "evolves_to": "Aquaveil", "evolves_at": 16},
	{"name": "Nightstalker", "element": "grass", "level": 1, "max_hp": 42, "attack": 50, "defense": 34, "sprite": "res://assets/sprites/sprite15_idle.png", "sprite_attack": "res://assets/sprites/sprite15_attack.png", "evolves_to": "Prismguard", "evolves_at": 20},
	{"name": "Thunderfang", "element": "water", "level": 1, "max_hp": 32, "attack": 52, "defense": 28, "sprite": "res://assets/sprites/sprite12_idle.png", "sprite_attack": "res://assets/sprites/sprite12_attack.png", "evolves_to": "Vinelash", "evolves_at": 16},
	{"name": "Shadowclaw", "element": "fire", "level": 1, "max_hp": 40, "attack": 48, "defense": 32, "sprite": "res://assets/sprites/sprite7_idle.png", "sprite_attack": "res://assets/sprites/sprite7_attack.png", "evolves_to": "Crystalwing", "evolves_at": 16},
	{"name": "Voltspike", "element": "earth", "level": 1, "max_hp": 38, "attack": 55, "defense": 32, "sprite": "res://assets/sprites/sprite4_idle.png", "sprite_attack": "res://assets/sprites/sprite4_attack.png"},
	{"name": "Leafwhisper", "element": "wind", "level": 1, "max_hp": 40, "attack": 48, "defense": 40, "sprite": "res://assets/sprites/sprite5_idle.png", "sprite_attack": "res://assets/sprites/sprite5_attack.png"},
	{"name": "Frostbite", "element": "ice", "level": 1, "max_hp": 44, "attack": 50, "defense": 38, "sprite": "res://assets/sprites/sprite6_idle.png", "sprite_attack": "res://assets/sprites/sprite6_attack.png"},
	{"name": "Tidehunter", "element": "cute", "level": 1, "max_hp": 48, "attack": 42, "defense": 45, "sprite": "res://assets/sprites/sprite10_idle.png", "sprite_attack": "res://assets/sprites/sprite10_attack.png"},
	{"name": "Stoneguard", "element": "electric", "level": 1, "max_hp": 52, "attack": 40, "defense": 58, "sprite": "res://assets/sprites/sprite11_idle.png", "sprite_attack": "res://assets/sprites/sprite11_attack.png"}
]

var player_soul: Dictionary = {}
var enemy_soul: Dictionary = {}
var battle_active: bool = false
var player_turn: bool = true

@onready var background: TextureRect = $Background
@onready var player_sprite: TextureRect = $BattleArea/PlayerSprite
@onready var enemy_sprite: TextureRect = $BattleArea/EnemySprite

@onready var player_name_label: Label = $UI/PlayerInfo/VBoxContainer/PlayerName
@onready var player_level_label: Label = $UI/PlayerInfo/VBoxContainer/PlayerLevel
@onready var player_hp_bar: ProgressBar = $UI/PlayerInfo/VBoxContainer/PlayerHPBar
@onready var player_hp_label: Label = $UI/PlayerInfo/VBoxContainer/PlayerHPLabel

@onready var enemy_name_label: Label = $UI/EnemyInfo/VBoxContainer/EnemyName
@onready var enemy_level_label: Label = $UI/EnemyInfo/VBoxContainer/EnemyLevel
@onready var enemy_hp_bar: ProgressBar = $UI/EnemyInfo/VBoxContainer/EnemyHPBar
@onready var enemy_hp_label: Label = $UI/EnemyInfo/VBoxContainer/EnemyHPLabel

@onready var attack_button: Button = $UI/BattleMenu/VBoxContainer/AttackButton
@onready var run_button: Button = $UI/BattleMenu/VBoxContainer/RunButton
@onready var message_label: Label = $UI/MessageBox/MessageLabel
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer


func _ready() -> void:
	randomize()
	attack_button.pressed.connect(_on_attack_pressed)
	run_button.pressed.connect(_on_run_pressed)
	_load_random_background()
	_start_battle()


func _start_battle() -> void:
	player_soul = GameState.get_active_soul().duplicate(true)
	if player_soul.is_empty():
		_show_message("No soul available to battle.")
		attack_button.disabled = true
		return

	player_soul["current_hp"] = int(player_soul.get("max_hp", 1))
	var enemy_index: int = randi() % ENEMY_SOUL_POOL.size()
	enemy_soul = ENEMY_SOUL_POOL[enemy_index].duplicate(true)
	enemy_soul["current_hp"] = int(enemy_soul.get("max_hp", 1))

	battle_active = true
	player_turn = true
	_refresh_ui()
	_show_message("A wild %s appeared!" % enemy_soul["name"])


func _load_random_background() -> void:
	var background_index: int = randi() % BACKGROUND_PATHS.size()
	background.texture = load(BACKGROUND_PATHS[background_index])


func _refresh_ui() -> void:
	player_name_label.text = "%s (%s)" % [player_soul["name"], String(player_soul["element"]).capitalize()]
	player_level_label.text = "Lv. %d" % int(player_soul.get("level", 1))
	player_hp_bar.value = float(player_soul["current_hp"]) / float(player_soul["max_hp"])
	player_hp_label.text = "HP: %d/%d" % [player_soul["current_hp"], player_soul["max_hp"]]
	player_sprite.texture = _make_first_frame_texture(player_soul["sprite"])

	enemy_name_label.text = "%s (%s)" % [enemy_soul["name"], String(enemy_soul["element"]).capitalize()]
	enemy_level_label.text = "Lv. %d" % int(enemy_soul.get("level", 1))
	enemy_hp_bar.value = float(enemy_soul["current_hp"]) / float(enemy_soul["max_hp"])
	enemy_hp_label.text = "HP: %d/%d" % [enemy_soul["current_hp"], enemy_soul["max_hp"]]
	enemy_sprite.texture = _make_first_frame_texture(enemy_soul["sprite"])


func _show_message(text: String) -> void:
	message_label.text = text


func _on_attack_pressed() -> void:
	if not battle_active or not player_turn:
		return

	player_turn = false
	attack_button.disabled = true
	run_button.disabled = true
	_play_battle_sound("attack")

	var player_damage: int = _calculate_damage(player_soul, enemy_soul)
	enemy_soul["current_hp"] = max(0, int(enemy_soul["current_hp"]) - player_damage)
	_play_battle_sound("damage")
	_refresh_ui()
	_show_message("%s hit %s for %d!" % [player_soul["name"], enemy_soul["name"], player_damage])
	if int(enemy_soul["current_hp"]) <= 0:
		await get_tree().create_timer(0.8).timeout
		_end_battle("won", "You won the battle!")
		return

	await get_tree().create_timer(0.8).timeout
	var enemy_damage: int = _calculate_damage(enemy_soul, player_soul)
	_play_battle_sound("attack")
	player_soul["current_hp"] = max(0, int(player_soul["current_hp"]) - enemy_damage)
	_play_battle_sound("damage")
	_refresh_ui()
	_show_message("%s hit %s for %d!" % [enemy_soul["name"], player_soul["name"], enemy_damage])
	if int(player_soul["current_hp"]) <= 0:
		await get_tree().create_timer(0.8).timeout
		_end_battle("lost", "Your soul fainted.")
		return

	player_turn = true
	attack_button.disabled = false
	run_button.disabled = false


func _on_run_pressed() -> void:
	if not battle_active:
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
		return

	attack_button.disabled = true
	run_button.disabled = true
	_play_battle_sound("run")
	_show_message("You escaped safely.")
	await get_tree().create_timer(0.6).timeout
	_end_battle("ran", "You escaped safely.")


func _calculate_damage(attacker: Dictionary, defender: Dictionary) -> int:
	var base_attack: int = int(attacker.get("attack", 1))
	var defense: int = int(defender.get("defense", 0))
	var random_bonus: int = randi_range(0, 3)
	return max(1, base_attack + random_bonus - int(defense / 2))


func _end_battle(result: String, message: String) -> void:
	battle_active = false
	GameState.last_battle_result = result
	if result == "won":
		_play_battle_sound("victory")
	_show_message(message)
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _make_first_frame_texture(texture_path: String) -> Texture2D:
	var atlas_source: Texture2D = load(texture_path)
	if atlas_source == null:
		return null

	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = atlas_source
	atlas.region = Rect2(0, 0, 96, 96)
	return atlas


func _play_battle_sound(sound_name: String) -> void:
	if not BATTLE_SOUNDS.has(sound_name):
		return

	var stream: AudioStream = load(BATTLE_SOUNDS[sound_name])
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.play()
