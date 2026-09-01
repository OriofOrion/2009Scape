extends Control

@onready var level_label: Label = $Margin/VBox/TopBar/HBox/LevelLabel
@onready var xp_bar: ProgressBar = $Margin/VBox/TopBar/HBox/XPBar
@onready var gold_label: Label = $Margin/VBox/TopBar/HBox/GoldLabel
@onready var essence_label: Label = $Margin/VBox/TopBar/HBox/EssenceLabel
@onready var power_label: Label = $Margin/VBox/TopBar/HBox/PowerLabel
@onready var toast_label: Label = $Toast
@onready var toast_timer: Timer = $ToastTimer
@onready var offline_popup: AcceptDialog = $OfflineRewardsPopup

func _ready() -> void:
	GameState.resources_changed.connect(_refresh_top_bar)
	GameState.hero_summoned.connect(func(_id, _new, _lvl): _refresh_top_bar())
	GameState.level_up.connect(_on_level_up)
	GameState.chapter_unlocked.connect(_on_chapter_unlocked)
	GameState.offline_gains_ready.connect(_on_offline_gains)
	toast_timer.timeout.connect(_on_toast_timeout)
	_refresh_top_bar()

func _refresh_top_bar() -> void:
	level_label.text = "Lv. %d" % GameState.level
	xp_bar.max_value = GameData.xp_to_next_level(GameState.level)
	xp_bar.value = GameState.xp
	gold_label.text = "Gold: %d" % GameState.gold
	essence_label.text = "Essence: %d" % GameState.essence
	power_label.text = "Power: %d" % GameState.get_warband_power()

func _on_level_up(new_level: int) -> void:
	_show_toast("Level up! You are now level %d." % new_level)
	_refresh_top_bar()

func _on_chapter_unlocked(chapter: Dictionary) -> void:
	_show_toast("New chapter unlocked: %s" % chapter.title)

func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	toast_timer.start()

func _on_toast_timeout() -> void:
	toast_label.visible = false

func _on_offline_gains(summary: Dictionary) -> void:
	var lines: PackedStringArray = []
	for material_id in summary:
		var mat := GameData.get_material(material_id)
		lines.append("+%d %s" % [summary[material_id], mat.name])
	offline_popup.dialog_text = "While you were away:\n" + "\n".join(lines)
	offline_popup.popup_centered()
