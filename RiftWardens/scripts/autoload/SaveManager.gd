extends Node
## Handles local, offline JSON persistence. No account, no login, no network.

const SAVE_PATH := "user://savegame.json"

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> Dictionary:
	if not save_exists():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("RiftWardens: could not open save file for reading.")
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("RiftWardens: save file was corrupt, ignoring.")
		return {}
	return parsed

func save_game(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("RiftWardens: could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
