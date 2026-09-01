extends Control

@onready var chapter_list: VBoxContainer = $Scroll/VBox/ChapterList

func _ready() -> void:
	GameState.chapter_unlocked.connect(func(_c): _rebuild())
	GameState.level_up.connect(func(_l): _rebuild())
	_rebuild()

func _rebuild() -> void:
	for c in chapter_list.get_children():
		c.queue_free()

	var chapters := GameData.get_unlocked_chapters(GameState.level)
	for i in range(chapters.size()):
		var chapter: Dictionary = chapters[i]
		var title := Label.new()
		title.text = "Chapter %d — %s" % [i + 1, chapter.title]
		title.add_theme_font_size_override("font_size", 18)
		chapter_list.add_child(title)

		var body := Label.new()
		body.text = chapter.text
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		chapter_list.add_child(body)
		chapter_list.add_child(HSeparator.new())

	if chapters.is_empty():
		var lbl := Label.new()
		lbl.text = "The story begins once you take your first steps as a Rift Warden."
		chapter_list.add_child(lbl)
