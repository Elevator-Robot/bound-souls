# Run after importing with the project's approved Godot version:
# godot --headless --path . --script res://tests/battle_smoke.gd
extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	root.size = Vector2i(1152, 648)
	# Exercise the real world-to-battle transition, including the player's camera.
	change_scene_to_file("res://scenes/main/main.tscn")
	await process_frame
	await process_frame
	change_scene_to_file("res://scenes/battle/battle_scene.tscn")
	await process_frame
	await process_frame
	var battle = current_scene
	_check(battle.battle_active, "Battle must start with imported fighters")
	_check(battle.player_animation != null, "Starter fighter missing")
	_check(battle.enemy_animation != null, "Wild fighter missing")
	for sprite in [battle.player_animation, battle.enemy_animation]:
		if sprite != null:
			var slot: Control = sprite.get_parent()
			slot.resized.disconnect(battle._layout_animation.bind(sprite, slot))
			sprite.queue_free()
	await process_frame
	var state = root.get_node("GameState")
	for species in state.SOUL_SPECIES:
		for slot in [battle.player_sprite, battle.enemy_sprite]:
			var sprite: AnimatedSprite2D = battle._setup_animation(state.create_wild_soul(species), slot)
			_check(sprite != null, "%s failed to load" % species)
			if sprite == null:
				continue
			_check(battle._has_battle_frames(sprite), "%s has incomplete clips" % species)
			_check(sprite.is_visible_in_tree() and sprite.is_playing(), "%s is hidden or stopped" % species)
			var texture: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle", 0)
			var image: Image = texture.get_image()
			_check(image != null and image.get_used_rect().has_area(), "%s has no visible idle pixels" % species)
			var rect := Rect2(sprite.offset, texture.get_size())
			var bounds: Rect2 = sprite.get_global_transform_with_canvas() * rect
			_check(bounds.has_area() and root.get_visible_rect().encloses(bounds), "%s outside viewport" % species)
			_check(slot.get_global_rect().grow(0.01).encloses(bounds), "%s does not fit its slot" % species)
			# Confirm some artwork remains outside the opaque UI panels.
			var visible_pixel := false
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					if image.get_pixel(x, y).a == 0:
						continue
					var point: Vector2 = sprite.get_global_transform_with_canvas() * (sprite.offset + Vector2(x, y))
					var covered := false
					for panel in battle.get_node("UI").get_children():
						covered = covered or panel.get_global_rect().has_point(point)
					visible_pixel = visible_pixel or not covered
			_check(visible_pixel, "%s entirely covered by UI" % species)
			sprite.speed_scale = 100.0
			await battle._play_action(sprite, &"attack")
			_check(sprite.animation == &"idle", "%s did not recover from attack" % species)
			await battle._play_action(sprite, &"hurt")
			_check(sprite.animation == &"idle", "%s did not recover from hurt" % species)
			await battle._play_action(sprite, &"death")
			_check(not sprite.is_playing() and sprite.animation == &"death", "%s death must hold" % species)
			slot.resized.disconnect(battle._layout_animation.bind(sprite, slot))
			sprite.queue_free()
			await process_frame
	var empty := AnimatedSprite2D.new()
	await _check_combat_layout(battle, state)
	empty.sprite_frames = null
	_check(not battle._has_battle_frames(empty), "Missing frames must be rejected")
	empty.free()
	print("Battle smoke: 7 souls, both slots, all clips; failures=", failures)
	quit(0 if failures == 0 else 1)


func _check_combat_layout(battle: Control, state: Node) -> void:
	# Retain the same instances across resizes to exercise the slot resized signal.
	for species in state.SOUL_SPECIES:
		battle.player_soul = state.create_wild_soul(species)
		battle.enemy_soul = state.create_wild_soul(species)
		battle._refresh_ui()
		var fighters: Array[AnimatedSprite2D] = []
		for slot in [battle.player_sprite, battle.enemy_sprite]:
			fighters.append(battle._setup_animation(state.create_wild_soul(species), slot))
		for viewport_size in [Vector2i(1152, 648), Vector2i(800, 600), Vector2i(600, 800), Vector2i(1920, 1080), Vector2i(1152, 648)]:
			root.size = viewport_size
			await process_frame
			await process_frame
			# Disjoint slots guarantee separation for mixed-species pairings too.
			_check(not battle.player_sprite.get_global_rect().intersects(battle.enemy_sprite.get_global_rect()), "Combat slots overlap at %s" % viewport_size)
			var opaque_bounds: Array[Rect2] = []
			var panels: Array[Rect2] = []
			for panel in battle.get_node("UI").get_children():
				var panel_rect: Rect2 = panel.get_global_rect()
				_check(root.get_visible_rect().encloses(panel_rect), "UI outside viewport at %s" % viewport_size)
				for other in panels:
					_check(not panel_rect.intersects(other), "UI panels overlap at %s" % viewport_size)
				panels.append(panel_rect)
			for control in [battle.attack_button, battle.run_button, battle.message_label,
				battle.player_name_label, battle.player_hp_label, battle.enemy_name_label, battle.enemy_hp_label]:
				_check(control.get_parent().get_global_rect().encloses(control.get_global_rect()), "UI content clipped at %s" % viewport_size)
			for sprite in fighters:
				if sprite == null:
					continue
				var slot: Control = sprite.get_parent()
				var combined := Rect2()
				# Every frame, not just idle: effects/death must stay clear of UI too.
				for clip in sprite.sprite_frames.get_animation_names():
					for index in range(sprite.sprite_frames.get_frame_count(clip)):
						var texture := sprite.sprite_frames.get_frame_texture(clip, index)
						var used := Rect2(texture.get_image().get_used_rect())
						if not used.has_area():
							continue
						used.position += sprite.offset
						var bounds: Rect2 = sprite.get_global_transform_with_canvas() * used
						_check(root.get_visible_rect().encloses(bounds), "%s %s outside viewport at %s" % [species, clip, viewport_size])
						_check(slot.get_global_rect().grow(0.01).encloses(bounds), "%s %s outside slot at %s" % [species, clip, viewport_size])
						for panel in panels:
							_check(not bounds.intersects(panel), "%s %s obscured by UI at %s" % [species, clip, viewport_size])
						combined = combined.merge(bounds) if combined.has_area() else bounds
				_check(combined.size.x > 40 and combined.size.y > 40, "%s rendered too small" % species)
				opaque_bounds.append(combined)
			if opaque_bounds.size() == 2:
				_check(not opaque_bounds[0].intersects(opaque_bounds[1]), "%s fighters overlap" % species)
				_check(opaque_bounds[0].end.x < viewport_size.x * 0.5, "%s player not on left" % species)
				_check(opaque_bounds[1].position.x > viewport_size.x * 0.5, "%s enemy not on right" % species)
				_check(opaque_bounds[0].get_center().y > opaque_bounds[1].get_center().y, "%s player not below enemy" % species)
		for sprite in fighters:
			if sprite != null:
				var slot: Control = sprite.get_parent()
				slot.resized.disconnect(battle._layout_animation.bind(sprite, slot))
				sprite.queue_free()
		await process_frame
