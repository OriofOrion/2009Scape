extends Control

@onready var zone_list: VBoxContainer = $Scroll/VBox/ZoneList
@onready var current_zone_label: Label = $Scroll/VBox/CurrentZoneLabel
@onready var zone_progress: ProgressBar = $Scroll/VBox/ZoneProgress
@onready var materials_list: VBoxContainer = $Scroll/VBox/MaterialsList

func _ready() -> void:
	GameState.resources_changed.connect(_refresh_materials)
	GameState.level_up.connect(func(_new_level): _rebuild_zone_list())
	GameState.gather_progressed.connect(_on_gather_progressed)
	_rebuild_zone_list()
	_refresh_materials()

func _rebuild_zone_list() -> void:
	for c in zone_list.get_children():
		c.queue_free()
	for zone in GameData.get_unlocked_zones(GameState.level):
		var btn := Button.new()
		btn.text = "%s (Lv.%d)" % [zone.name, zone.required_level]
		btn.toggle_mode = true
		btn.button_pressed = zone.id == GameState.current_zone_id
		btn.pressed.connect(_on_zone_pressed.bind(zone.id))
		zone_list.add_child(btn)
	_refresh_materials()

func _on_zone_pressed(zone_id: String) -> void:
	GameState.set_current_zone(zone_id)
	_rebuild_zone_list()

func _refresh_materials() -> void:
	var zone := GameState.get_current_zone()
	if zone.is_empty():
		return
	current_zone_label.text = "%s\n%s" % [zone.name, zone.blurb]
	for c in materials_list.get_children():
		c.queue_free()
	for material_id in zone.materials:
		var mat := GameData.get_material(material_id)
		var lbl := Label.new()
		lbl.text = "%s: %d" % [mat.name, GameState.get_material_count(material_id)]
		materials_list.add_child(lbl)

func _on_gather_progressed(zone_id: String, _material_id: String, fraction: float) -> void:
	if zone_id == GameState.current_zone_id:
		zone_progress.value = fraction * 100.0
