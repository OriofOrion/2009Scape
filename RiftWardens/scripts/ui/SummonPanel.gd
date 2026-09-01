extends Control

@onready var essence_label: Label = $Scroll/VBox/EssenceLabel
@onready var pity_label: Label = $Scroll/VBox/PityLabel
@onready var summon1_btn: Button = $Scroll/VBox/HBoxButtons/Summon1
@onready var summon10_btn: Button = $Scroll/VBox/HBoxButtons/Summon10
@onready var results_list: VBoxContainer = $Scroll/VBox/ResultsList

func _ready() -> void:
	GameState.resources_changed.connect(_refresh)
	summon1_btn.pressed.connect(_on_summon1)
	summon10_btn.pressed.connect(_on_summon10)
	_refresh()

func _refresh() -> void:
	essence_label.text = "Rift Essence: %d" % GameState.essence
	pity_label.text = "Summons since last Legendary: %d / %d" % [
		GameState.pity_counter, GameData.PITY_HARD_CAP
	]
	summon1_btn.disabled = not GameState.can_afford_summon(1)
	summon10_btn.disabled = not GameState.can_afford_summon(10)

func _on_summon1() -> void:
	var result := GameState.summon_single()
	if result.get("success", false):
		_show_results([result])
	_refresh()

func _on_summon10() -> void:
	var results := GameState.summon_ten()
	if results.size() > 0:
		_show_results(results)
	_refresh()

func _show_results(results: Array) -> void:
	for c in results_list.get_children():
		c.queue_free()
	for r in results:
		var hero := GameData.get_hero(r.hero_id)
		var rarity: Dictionary = GameData.RARITY_INFO[hero.rarity]
		var lbl := Label.new()
		var stars := "★".repeat(rarity.stars)
		var tag := "NEW" if r.is_new else "+1 Lv"
		lbl.text = "%s %s [%s] — %s" % [stars, hero.name, tag, hero.tagline]
		lbl.add_theme_color_override("font_color", Color(rarity.color))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		results_list.add_child(lbl)
