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

var player_soul: Dictionary = {}
var enemy_soul: Dictionary = {}
var battle_active: bool = false
var player_turn: bool = true
var enemy_animation: AnimatedSprite2D
var player_animation: AnimatedSprite2D

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
	var species_names: Array = GameState.SOUL_SPECIES.keys()
	var enemy_index: int = randi() % species_names.size()
	enemy_soul = GameState.create_wild_soul(species_names[enemy_index])
	player_animation = _setup_animation(player_soul, player_sprite)
	enemy_animation = _setup_animation(enemy_soul, enemy_sprite)
	if player_animation == null or enemy_animation == null:
		battle_active = false
		attack_button.disabled = true
		_show_message("Could not load fighters. Import project assets in Godot, then retry. Choose Run to return.")
		return

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

	enemy_name_label.text = "%s (%s)" % [enemy_soul["name"], String(enemy_soul["element"]).capitalize()]
	enemy_level_label.text = "Lv. %d" % int(enemy_soul.get("level", 1))
	enemy_hp_bar.value = float(enemy_soul["current_hp"]) / float(enemy_soul["max_hp"])
	enemy_hp_label.text = "HP: %d/%d" % [enemy_soul["current_hp"], enemy_soul["max_hp"]]


func _setup_animation(soul: Dictionary, container: TextureRect) -> AnimatedSprite2D:
	# Instantiate the approved scene so its fixed pivot and nearest filtering are retained.
	var scene: PackedScene = load(soul["scene"])
	if scene == null:
		return null
	var instance: Node = scene.instantiate()
	if not instance is AnimatedSprite2D:
		instance.free()
		return null
	var animation: AnimatedSprite2D = instance
	if not _has_battle_frames(animation):
		push_error("Missing battle frames for %s. Import project assets in the Godot editor." % soul["name"])
		animation.free()
		return null
	container.add_child(animation)
	container.texture = null
	container.resized.connect(_layout_animation.bind(animation, container))
	_layout_animation(animation, container)
	animation.play(&"idle")
	return animation


func _has_battle_frames(animation: AnimatedSprite2D) -> bool:
	var frames: SpriteFrames = animation.sprite_frames
	if frames == null:
		return false
	for clip in [&"idle", &"attack", &"hurt", &"death"]:
		if not frames.has_animation(clip) or frames.get_frame_count(clip) == 0:
			return false
		for index in range(frames.get_frame_count(clip)):
			var texture: Texture2D = frames.get_frame_texture(clip, index)
			if texture == null or texture.get_size().x <= 0 or texture.get_size().y <= 0:
				return false
			if texture is AtlasTexture and texture.atlas == null:
				return false
	return true


func _layout_animation(animation: AnimatedSprite2D, container: TextureRect) -> void:
	var canvas: Vector2 = animation.sprite_frames.get_frame_texture(&"idle", 0).get_size()
	# Fit the entire fixed canvas, never individual visible-frame bounds.
	var factor: float = minf(container.size.x / canvas.x, container.size.y / canvas.y)
	animation.scale = Vector2.ONE * factor
	animation.position = (container.size - canvas * factor) * 0.5 - animation.offset * factor


func _play_action(animation: AnimatedSprite2D, clip: StringName) -> void:
	animation.play(clip)
	await animation.animation_finished
	# Death must hold its final frame instead of making the defeated soul reappear.
	if clip != &"death":
		animation.play(&"idle")


func _show_message(text: String) -> void:
	message_label.text = text


func _on_attack_pressed() -> void:
	if not battle_active or not player_turn:
		return

	player_turn = false
	attack_button.disabled = true
	run_button.disabled = true
	_play_battle_sound("attack")
	await _play_action(player_animation, &"attack")

	var player_damage: int = _calculate_damage(player_soul, enemy_soul)
	enemy_soul["current_hp"] = max(0, int(enemy_soul["current_hp"]) - player_damage)
	_play_battle_sound("damage")
	_refresh_ui()
	_show_message("%s hit %s for %d!" % [player_soul["name"], enemy_soul["name"], player_damage])
	if int(enemy_soul["current_hp"]) <= 0:
		await _play_action(enemy_animation, &"death")
		_end_battle("won", "You won the battle!")
		return

	await _play_action(enemy_animation, &"hurt")
	await get_tree().create_timer(0.8).timeout
	await _play_action(enemy_animation, &"attack")
	var enemy_damage: int = _calculate_damage(enemy_soul, player_soul)
	_play_battle_sound("attack")
	player_soul["current_hp"] = max(0, int(player_soul["current_hp"]) - enemy_damage)
	_play_battle_sound("damage")
	_refresh_ui()
	_show_message("%s hit %s for %d!" % [enemy_soul["name"], player_soul["name"], enemy_damage])
	if int(player_soul["current_hp"]) <= 0:
		await _play_action(player_animation, &"death")
		_end_battle("lost", "Your soul fainted.")
		return

	await _play_action(player_animation, &"hurt")
	player_turn = true
	attack_button.disabled = false
	run_button.disabled = false


func _on_run_pressed() -> void:
	if not player_turn:
		return
	if not battle_active:
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
		return

	attack_button.disabled = true
	run_button.disabled = true
	player_turn = false
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


func _play_battle_sound(sound_name: String) -> void:
	if not BATTLE_SOUNDS.has(sound_name):
		return

	var stream: AudioStream = load(BATTLE_SOUNDS[sound_name])
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.play()
