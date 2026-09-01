extends Control

@onready var recipe_list: VBoxContainer = $Scroll/VBox/RecipeList

func _ready() -> void:
	GameState.resources_changed.connect(_rebuild)
	GameState.level_up.connect(func(_new_level): _rebuild())
	_rebuild()

func _rebuild() -> void:
	for c in recipe_list.get_children():
		c.queue_free()

	for recipe in GameData.get_unlocked_recipes(GameState.level):
		var row := PanelContainer.new()
		var vbox := VBoxContainer.new()
		row.add_child(vbox)

		var owned := GameState.get_forge_count(recipe.id)
		var title := Label.new()
		title.text = "%s  (owned: %d)" % [recipe.name, owned]
		title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(title)

		var blurb := Label.new()
		blurb.text = recipe.blurb
		blurb.modulate = Color(0.8, 0.8, 0.85)
		vbox.add_child(blurb)

		var effects_text: PackedStringArray = []
		for k in recipe.effects:
			effects_text.append("%s +%.1f%%" % [_effect_label(k), recipe.effects[k]])
		var effects_label := Label.new()
		effects_label.text = "Effect: " + ", ".join(effects_text)
		vbox.add_child(effects_label)

		var cost := GameState.get_next_craft_cost(recipe.id)
		var cost_parts: PackedStringArray = ["%d gold" % cost.gold]
		for mat_id in cost.materials:
			var mat := GameData.get_material(mat_id)
			cost_parts.append("%d %s" % [cost.materials[mat_id], mat.name])
		var cost_label := Label.new()
		cost_label.text = "Cost: " + ", ".join(cost_parts)
		vbox.add_child(cost_label)

		var craft_btn := Button.new()
		craft_btn.text = "Forge"
		craft_btn.disabled = not GameState.can_craft(recipe.id)
		craft_btn.pressed.connect(_on_craft_pressed.bind(recipe.id))
		vbox.add_child(craft_btn)

		recipe_list.add_child(row)
		recipe_list.add_child(HSeparator.new())

func _effect_label(key: String) -> String:
	match key:
		"atk_pct": return "Warband ATK"
		"def_pct": return "Warband DEF"
		"gather_pct": return "Gather Speed"
		"summon_pct": return "Essence Gain"
		_: return key

func _on_craft_pressed(recipe_id: String) -> void:
	GameState.craft(recipe_id)
	_rebuild()
