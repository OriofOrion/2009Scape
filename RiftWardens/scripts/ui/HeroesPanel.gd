extends Control

@onready var power_label: Label = $Scroll/VBox/PowerLabel
@onready var class_container: VBoxContainer = $Scroll/VBox/ClassContainer

func _ready() -> void:
	GameState.resources_changed.connect(_rebuild)
	GameState.hero_summoned.connect(func(_id, _new, _lvl): _rebuild())
	_rebuild()

func _rebuild() -> void:
	power_label.text = "Warband Power: %d   (%d / 48 heroes recruited)" % [
		GameState.get_warband_power(), GameState.get_owned_hero_ids().size()
	]

	for c in class_container.get_children():
		c.queue_free()

	for class_id in GameData.CLASS_ORDER:
		var cls := GameData.get_class_info(class_id)
		var section := VBoxContainer.new()

		var header := Label.new()
		header.text = cls.name
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", Color(cls.color))
		section.add_child(header)

		var blurb := Label.new()
		blurb.text = cls.blurb
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD
		blurb.modulate = Color(0.8, 0.8, 0.85)
		section.add_child(blurb)

		var grid := GridContainer.new()
		grid.columns = 2
		for hero in GameData.HEROES:
			if hero.class_id != class_id:
				continue
			grid.add_child(_build_hero_row(hero))
		section.add_child(grid)
		section.add_child(HSeparator.new())
		class_container.add_child(section)

func _build_hero_row(hero: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	panel.custom_minimum_size = Vector2(220, 0)

	var owned := GameState.is_hero_owned(hero.id)
	var rarity: Dictionary = GameData.RARITY_INFO[hero.rarity]

	var name_label := Label.new()
	var stars := "★".repeat(rarity.stars)
	if owned:
		var lvl := GameState.get_hero_level(hero.id)
		name_label.text = "%s %s (Lv.%d)" % [stars, hero.name, lvl]
	else:
		name_label.text = "%s ??? (Locked)" % stars
	name_label.add_theme_color_override("font_color", Color(rarity.color))
	vbox.add_child(name_label)

	var detail_label := Label.new()
	if owned:
		var stats := GameData.compute_hero_stats(hero.id, GameState.get_hero_level(hero.id))
		detail_label.text = "%s — ATK %d / DEF %d / HP %d" % [hero.tagline, stats.atk, stats.def, stats.hp]
	else:
		detail_label.text = "Summon this hero to reveal them."
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_label.modulate = Color(0.85, 0.85, 0.9)
	vbox.add_child(detail_label)

	return panel
