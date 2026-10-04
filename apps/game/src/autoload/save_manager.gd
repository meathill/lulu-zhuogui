extends Node

## 本地 JSON 存档（user://save.json）。
## M1 不加密，也不接 Steam Cloud。
## 以后由 SteamManager 包 GodotSteam；非 Steam 环境走 Dummy 桩，避免代码分叉。
## 本里程碑不引入 Steam GDExtension。

const SAVE_PATH: String = "user://save.json"


func save_local(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("存档写不进去")
		return
	file.store_string(JSON.stringify(data))


func load_local() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("存档读不出来")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}
