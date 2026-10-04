class_name TutorialCoach
extends RefCounted

## 第 1 关逐步带教。一句台词对一个动作，动作做完才说下一句。
## 等玩家点的时候威胁时钟停住，读得慢也不会被判负。

var host: Node
var lines: Dictionary = {}
var phase: String = ""
var line: String = ""
var drive_idle: float = 0.0
var tear_hint_time: float = 0.0
var block_said: bool = false
var replace_bare: bool = false
var wave_said: bool = false

const SECOND_SLOTS: PackedStringArray = ["door-seam", "floor-panel"]


static func attach(host: Node, data: Dictionary) -> TutorialCoach:
	var mode := str(host.get("auto_mode"))
	if mode != "" and mode != "coach":
		return null
	var block: Variant = data.get("tutorial", {})
	if not block is Dictionary or (block as Dictionary).is_empty():
		return null
	var coach := TutorialCoach.new()
	coach.host = host
	coach.lines = block
	host.set("current_tool", "")
	host.set("status_text", "听一句，做一个动作。")
	coach._enter("look")
	return coach


func holding() -> bool:
	return phase == "look" or phase == "place" or phase == "regen" or phase == "replace" or phase == "second"


func line_text() -> String:
	return line


func pulse(delta: float) -> void:
	if phase == "play":
		tear_hint_time += delta
	apply_hints()


func drive(delta: float) -> void:
	# 无头把点击补上，用来核对台词顺序和停表。
	if str(host.get("auto_mode")) != "coach" or str(host.get("ended")) != "":
		return
	drive_idle += delta
	match phase:
		"look":
			if drive_idle >= 1.0:
				intercept_slot("door-bottom-seam")
		"place":
			host.set("current_tool", "ward")
			host.call("try_place", "ward", "door-bottom-seam")
		"regen":
			if drive_idle >= 0.35:
				on_energy()
		"replace":
			if _slot_has("door-bottom-seam"):
				on_stuck("door-bottom-seam", "ward")
			else:
				host.set("current_tool", "ward")
				host.call("try_place", "ward", "door-bottom-seam")
		"second":
			if _slot_has("door-seam"):
				intercept_slot("door-seam")
			elif _slot_has("floor-panel"):
				intercept_slot("floor-panel")
			else:
				host.set("current_tool", "ward")
				host.call("try_place", "ward", "door-seam")


func intercept_slot(slot_id: String) -> bool:
	match phase:
		"look":
			if slot_id == "door-bottom-seam":
				_enter("place")
			else:
				_set_line(_text("lookHint"))
			return true
		"place", "replace":
			if str(host.get("current_tool")) != "ward":
				_set_line(_text("needTool"))
				return true
			return false
		"second":
			if SECOND_SLOTS.has(slot_id) and _slot_has(slot_id):
				host.call("retarget_entry", "sui-2", slot_id)
				_enter("play")
				return true
			if slot_id == "door-bottom-seam":
				_set_line(_text("second"))
				return true
			if str(host.get("current_tool")) != "ward":
				_set_line(_text("needTool"))
				return true
			return false
		_:
			return false


func on_tool(tool_id: String) -> void:
	if tool_id == "ward" and (phase == "place" or phase == "replace" or phase == "second"):
		_show_phase_line()
	apply_hints()


func on_energy() -> void:
	if phase != "regen":
		return
	_enter("wait-block")


func on_stuck(slot_id: String, tool_id: String) -> void:
	if tool_id != "ward":
		return
	match phase:
		"place":
			if slot_id == "door-bottom-seam":
				_enter("regen")
			else:
				_set_line(_text("tearWrong"))
		"replace":
			if slot_id == "door-bottom-seam":
				_enter("second")
			else:
				_set_line(_text("tearWrong"))
		"second":
			if SECOND_SLOTS.has(slot_id):
				host.call("retarget_entry", "sui-2", slot_id)
				_enter("play")
			else:
				_set_line(_text("tearWrong"))
		_:
			if slot_id != "door-bottom-seam" and not SECOND_SLOTS.has(slot_id):
				_set_line(_text("tearWrong"))


func on_tore(slot_id: String) -> void:
	if slot_id != "door-bottom-seam":
		return
	if phase == "wait-block" or phase == "wait-kick":
		replace_bare = true
		_enter("replace")


func on_blocked(slot_id: String) -> void:
	if slot_id != "door-bottom-seam" or block_said:
		return
	block_said = true
	if phase == "wait-block":
		_enter("wait-kick")
		return
	_set_line(_text("blocked"))
	_print("blocked")


func on_kick(removed: bool) -> void:
	if phase == "look" or phase == "place" or phase == "regen":
		return
	if not removed and _slot_has("door-bottom-seam"):
		return
	replace_bare = not removed
	_enter("replace")


func on_spawned(actor_id: String) -> void:
	if actor_id != "boss-slag" or wave_said:
		return
	wave_said = true
	_set_line(_text("wave"))
	_print("wave")


func apply_hints() -> void:
	var tool := ""
	if (phase == "place" or phase == "replace" or phase == "second") and str(host.get("current_tool")) != "ward":
		tool = "ward"
	elif phase == "play" and tear_hint_time < 8.0:
		tool = "tear"
	host.call("tutorial_paint", _hint_slots(), tool, phase == "regen")


func _hint_slots() -> PackedStringArray:
	var out := PackedStringArray()
	match phase:
		"look", "place", "replace":
			out.append("door-bottom-seam")
		"second":
			out.append("door-seam")
			out.append("floor-panel")
	return out


func _enter(next: String) -> void:
	phase = next
	drive_idle = 0.0
	if next == "place" or next == "replace" or next == "second":
		host.set("current_tool", "")
		tear_hint_time = 0.0
	if next == "regen":
		var pool: Variant = host.get("energy")
		pool.value = minf(36.0, float(pool.value))
	if next == "play":
		tear_hint_time = 0.0
	_show_phase_line()
	if next != "wait-block":
		_print(_tag(next))
	apply_hints()


func _show_phase_line() -> void:
	match phase:
		"look":
			_set_line(_text("look"))
		"place":
			_set_line(_text("place"))
		"regen":
			_set_line(_text("regen"))
		"wait-kick":
			_set_line(_text("blocked"))
		"replace":
			_set_line(_text("kickedBare" if replace_bare else "kicked"))
		"second":
			_set_line(_text("second"))
		"play":
			_set_line(_text("tear"))
		_:
			pass


func _tag(next: String) -> String:
	match next:
		"wait-kick":
			return "blocked"
		"play":
			return "tear"
		_:
			return next


func _print(tag: String) -> void:
	var spoken := line.replace("\n", " / ")
	print("COACH %s %.2f %s" % [tag, float(host.get("time_sec")), spoken])


func _set_line(body: String) -> void:
	if body == "":
		return
	line = "老周：" + body


func _text(key: String) -> String:
	var raw: Variant = lines.get(key, "")
	if raw is PackedStringArray:
		return "\n".join(raw)
	if raw is Array:
		var parts := PackedStringArray()
		for item in raw:
			parts.append(str(item))
		return "\n".join(parts)
	return str(raw)


func _slot_has(slot_id: String) -> bool:
	var slot: Variant = host.call("_slot", slot_id)
	return slot != null and str(slot.talisman) == "ward"
