extends Node2D

## 灰盒关卡状态、胜负和界面刷新。走位在 stage，下符在关卡脚本。

@export var level_resource_path: String = ""

const POLICY := preload("res://src/dev/auto_policy.gd")

var level_id: String = ""
var status_text: String = ""
var form: float = 0.0
var auto_mode: String = ""
var ended: String = ""
var paused: bool = false
var revealed: bool = false
var assist: bool = false
var backpack_seen: bool = false
var lines_seen: int = 0
var unresolved: int = 0
var spawned_count: int = 0
var time_sec: float = 0.0
var lightning_ready: float = 0.0
var kicked: bool = false
var current_tool: String = "ward"
var current_camera: String = "A"
var win_kind: String = "clear"
var camera_mode: String = "single"
var place_cost: float = 12.0
var lightning_cost: float = 12.0
var lightning_damage: float = 40.0
var ward_dps: float = 40.0
var kick_slot: String = ""
var kick_at: float = -1.0
var win_text: String = ""
var dialogue: PackedStringArray = PackedStringArray()

var energy := EnergyPool.new()
var redirect := RedirectField.new()
var hold := HoldMark.new()
var summon := SummonYin.new()
var meters := MeterRack.new()
var slots: Dictionary = {}
var actors: Array[SpiritActor] = []
var waves: Array[Dictionary] = []
var hud: HudBar
var cutscene: CutsceneStill
var policy: RefCounted
var font: Font



func _ready() -> void:
	font = UiTheme.font()
	auto_mode = _auto_arg()
	var data := _load_data()
	if data.is_empty():
		return
	_apply_config(data)
	call("_build_room", data)
	call("_build_slots", data)
	call("_build_waves", data)
	call("_build_hud", data)
	cutscene = CutsceneStill.new()
	add_child(cutscene)
	cutscene.finished.connect(_on_cutscene_done)
	if level_id == "level-10":
		_read_assist()
	if auto_mode == "win":
		policy = POLICY.new()
		policy.set("level", self)
	var intro := _lines(data.get("intro", {}))
	if auto_mode == "" and intro.size() > 0:
		paused = true
		cutscene.play(_image(data.get("intro", {})), intro)
	else:
		status_text = "点符位下符。符力自己会回。"
	_refresh()
	print("灰盒开局：%s" % level_id)


func _process(delta: float) -> void:
	if ended != "" or paused:
		return
	time_sec += delta
	energy.tick(delta)
	call("_kick")
	call("_spawn_due")
	if policy != null:
		policy.call("tick")
	call("_apply_holds")
	call("_move", delta)
	if assist:
		call("_assist", delta)
	var attached := _attached_ids()
	var broke := meters.tick(delta, attached, not attached.is_empty())
	if broke != "":
		_fail(broke)
		return
	_check_win()
	if auto_mode != "" and ended == "" and time_sec > 20.0:
		print("RESULT timeout")
		_quit(1)
		return
	_refresh()


func _auto_arg() -> String:
	var args := OS.get_cmdline_user_args()
	if args.has("--auto-win"):
		return "win"
	if args.has("--auto-fail"):
		return "fail"
	return ""


func _load_data() -> Dictionary:
	if not FileAccess.file_exists(level_resource_path):
		push_error("缺少关卡数据 %s" % level_resource_path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(level_resource_path))
	if parsed is Dictionary:
		return parsed
	return {}


func _apply_config(data: Dictionary) -> void:
	level_id = str(data.get("id", ""))
	win_kind = str(data.get("winKind", "clear"))
	camera_mode = str(data.get("cameraMode", "single"))
	place_cost = float(data.get("placeCost", 12))
	lightning_cost = float(data.get("lightningCost", place_cost))
	lightning_damage = float(data.get("lightningDamage", 40))
	ward_dps = float(data.get("wardDamagePerSecond", 40))
	kick_slot = str(data.get("kickSlot", ""))
	kick_at = float(data.get("kickAt", -1))
	form = float(data.get("formStart", 0))
	win_text = _first_line(data.get("outro", {}))
	dialogue = _lines(data.get("dialogue", []))
	var tools := _strings(data.get("tools", []))
	if tools.size() > 0:
		current_tool = tools[0]
	energy.setup(float(data.get("initialEnergy", 80)), float(data.get("energyMax", 100)), float(data.get("regenRate", 30)))
	var meter_raw: Variant = data.get("meters", [])
	if meter_raw is Array:
		meters.setup(meter_raw)


func _meter(meter_id: String, amount: float) -> void:
	var broke := meters.bump(meter_id, amount)
	if broke != "":
		_fail(broke)


func _check_win() -> void:
	if ended != "":
		return
	if win_kind == "clear" and _waves_done() and unresolved <= 0 and spawned_count > 0:
		_win(win_text if win_text != "" else "这一单清完了。")
	elif win_kind == "backpack" and _waves_done() and unresolved <= 0 and backpack_seen and lines_seen >= dialogue.size() and dialogue.size() > 0:
		_win(win_text if win_text != "" else "小禾安全了。")
	elif win_kind == "boss" and _boss_down():
		_win(win_text if win_text != "" else "梦魇散了。")


func _boss_down() -> bool:
	var seen := false
	for actor in actors:
		if actor.kind != "boss":
			continue
		seen = true
		if not actor.dead and not actor.resolved:
			return false
	return seen


func _waves_done() -> bool:
	if waves.is_empty():
		return false
	for wave in waves:
		if not bool(wave["done"]):
			return false
	return true


func _resolve(actor: SpiritActor) -> void:
	if actor.resolved:
		return
	actor.resolved = true
	actor.dead = true
	actor.visible = false
	if actor.must_resolve:
		unresolved -= 1


func _fail(reason: String) -> void:
	if ended != "":
		return
	ended = "fail"
	status_text = reason
	var zhou := "老周：今天先到这儿吧，我去问问那谁有没有空。"
	print("RESULT fail")
	print(reason)
	if auto_mode == "win":
		print("RESULT unexpected-fail")
		_quit(1)
		return
	if auto_mode == "fail":
		_quit(0)
		return
	if hud != null:
		hud.set_zhou(zhou)
		hud.show_end(reason + "\n" + zhou)


func _win(text: String) -> void:
	if ended != "":
		return
	ended = "win"
	status_text = text
	print("RESULT win")
	print(text)
	if auto_mode == "fail":
		print("RESULT unexpected-win")
		_quit(1)
		return
	if auto_mode == "win":
		_quit(0)
		return
	if hud != null:
		hud.show_end(text)


func _quit(code: int) -> void:
	get_tree().quit(code)


func _read_assist() -> void:
	var flag := str(SaveManager.load_local().get("pudding", ""))
	assist = flag == "tamed"
	print("ASSIST %s" % ("yes" if assist else "no"))
	if flag == "taken":
		status_text = "布丁交给了阴差，这关没有布丁助战。"
	elif flag == "scattered":
		status_text = "布丁被驱散了，没有助战。"
	elif assist:
		status_text = "收服的布丁冲进来助战。"
	else:
		status_text = "布丁不在这间卧室里。"


func _set_pudding(flag: String) -> void:
	var saved := SaveManager.load_local()
	saved["pudding"] = flag
	SaveManager.save_local(saved)


func _attached_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for actor in actors:
		if actor.attached and not actor.dead:
			ids.append(actor.actor_id)
	return ids


func _find(actor_id: String) -> SpiritActor:
	for actor in actors:
		if actor.actor_id == actor_id and not actor.resolved:
			return actor
	return null


func _slot(slot_id: String) -> HotspotSlot:
	return slots.get(slot_id) as HotspotSlot


func _refresh() -> void:
	if hud == null:
		return
	var ward := "符力 %.0f / %.0f  当前：%s" % [energy.value, energy.max_value, _tool_name(current_tool)]
	if win_kind == "form-send":
		ward += "  成型 %.0f" % form
	if camera_mode == "multi":
		ward += "  机位 %s" % current_camera
	hud.set_energy(ward)
	hud.set_meters("  ".join(meters.lines()))
	hud.set_status(status_text)
	if dialogue.size() > 0 and lines_seen == 0:
		hud.set_dialogue("点「下一句」听林小禾说话。")
	elif lines_seen > 0:
		hud.set_dialogue(dialogue[lines_seen - 1])


func _tool_name(tool_id: String) -> String:
	match tool_id:
		"ward":
			return "镇守"
		"lightning":
			return "五雷"
		"reveal":
			return "显形"
		"redirect":
			return "驱离"
		"hold":
			return "定神"
		"tear":
			return "撕符"
		_:
			return tool_id


func _on_cutscene_done() -> void:
	paused = false
	time_sec = 0.0


func _strings(value: Variant) -> PackedStringArray:
	var out: PackedStringArray = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out


func _lines(value: Variant) -> PackedStringArray:
	if value is Dictionary:
		return _strings((value as Dictionary).get("lines", []))
	return _strings(value)


func _image(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("image", ""))
	return ""


func _first_line(value: Variant) -> String:
	var lines := _lines(value)
	if lines.size() == 0:
		return ""
	return lines[0]
