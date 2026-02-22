extends CanvasLayer

# Debug cheat menu for testing

@onready var level_input: LineEdit = $Panel/MarginContainer/VBoxContainer/LevelInput
@onready var set_level_button: Button = $Panel/MarginContainer/VBoxContainer/SetLevelButton
@onready var encounter_toggle: CheckButton = $Panel/MarginContainer/VBoxContainer/EncounterToggle


func _input(event: InputEvent) -> void:
	# Press F12 to toggle cheat menu
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		var player: Node = get_tree().get_first_node_in_group("player")
		if player:
			visible = not visible
			if visible:
				_sync_from_state()
				level_input.grab_focus()
			get_viewport().set_input_as_handled()


func _ready() -> void:
	visible = false
	set_level_button.pressed.connect(_on_set_level_pressed)
	level_input.text_submitted.connect(_on_level_submitted)
	encounter_toggle.toggled.connect(_on_encounter_toggled)
	_sync_from_state()


func _on_set_level_pressed() -> void:
	_apply_level_change()


func _on_level_submitted(_text: String) -> void:
	_apply_level_change()


func _apply_level_change() -> void:
	var new_level: int = int(level_input.text)
	if new_level < 1 or new_level > 100:
		print("Invalid level. Must be between 1 and 100")
		return

	var before_soul: Dictionary = GameState.get_active_soul().duplicate(true)
	if not GameState.set_active_soul_level(new_level):
		print("Failed to set level.")
		return

	var after_soul: Dictionary = GameState.get_active_soul()
	print("Changed %s from level %d to level %d!" % [
		before_soul.get("name", "Soul"),
		int(before_soul.get("level", 1)),
		int(after_soul.get("level", 1))
	])
	if before_soul.get("name", "") != after_soul.get("name", ""):
		print("%s evolved into %s!" % [before_soul.get("name", "Soul"), after_soul.get("name", "Soul")])

	visible = false


func _on_encounter_toggled(enabled: bool) -> void:
	GameState.set_encounters_enabled(enabled)
	print("Random encounters: %s" % ("ON" if enabled else "OFF"))


func _sync_from_state() -> void:
	var soul: Dictionary = GameState.get_active_soul()
	level_input.text = str(int(soul.get("level", 1)))
	encounter_toggle.button_pressed = GameState.encounters_enabled
