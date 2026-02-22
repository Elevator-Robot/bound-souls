extends CharacterBody2D

@export var speed: float = 70.0
@export var encounter_check_interval: float = 1.5
@export_range(0.0, 1.0, 0.01) var encounter_chance: float = 0.25
@export_file("*.tscn") var battle_scene_path: String = "res://scenes/battle/battle_scene.tscn"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var last_axis_horizontal: bool = true
var last_move_animation: StringName = &"walk_down"
var step_timer: float = 0.0


func _physics_process(_delta: float) -> void:
	var x: float = Input.get_axis("ui_left", "ui_right")
	var y: float = Input.get_axis("ui_up", "ui_down")
	var horizontal_just_pressed: bool = Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")
	var vertical_just_pressed: bool = Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down")

	if horizontal_just_pressed:
		last_axis_horizontal = true
	elif vertical_just_pressed:
		last_axis_horizontal = false

	if x != 0.0 and y != 0.0:
		if last_axis_horizontal:
			y = 0.0
		else:
			x = 0.0
	var dir: Vector2 = Vector2(x, y)

	velocity = dir * speed
	move_and_slide()
	_check_random_encounter(_delta)
	_update_animation(dir)


func _update_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		sprite.play(last_move_animation)
		sprite.stop()
		sprite.frame = 0
		return

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0.0:
			last_move_animation = &"walk_right"
		else:
			last_move_animation = &"walk_left"
	else:
		if dir.y > 0.0:
			last_move_animation = &"walk_down"
		else:
			last_move_animation = &"walk_up"

	sprite.play(last_move_animation)


func _check_random_encounter(delta: float) -> void:
	if velocity.length() <= 0.0:
		return

	step_timer += delta
	if step_timer < encounter_check_interval:
		return

	step_timer = 0.0
	if randf() >= encounter_chance:
		return
	if GameState.souls_collected <= 0:
		print("Encounter skipped: no captured souls.")
		return

	_trigger_battle()


func _trigger_battle() -> void:
	if battle_scene_path.is_empty():
		push_warning("Battle scene path is empty; skipping encounter transition.")
		return

	if not ResourceLoader.exists(battle_scene_path):
		push_warning("Battle scene does not exist: " + battle_scene_path)
		return

	get_tree().change_scene_to_file(battle_scene_path)
