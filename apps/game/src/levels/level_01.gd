extends Node2D

## 第 1 关灰盒：点门下缝贴符，符力自回，鬼渣被磨死即过关。
## 无头校验可加用户参数 --auto-ward，开局自动贴一张。

const LEVEL_PATH: String = "res://assets/data/levels/01-elevator.json"

@onready var door_slot: HotspotSlot = $HotspotDoorBottom
@onready var spirit: SpiritActor = $Spirit
@onready var center_mark: Marker2D = $CenterMark
@onready var title_label: Label = $Hud/HudRoot/Title
@onready var energy_bar: ProgressBar = $Hud/HudRoot/EnergyBar
@onready var energy_label: Label = $Hud/HudRoot/EnergyLabel
@onready var cold_label: Label = $Hud/HudRoot/ColdLabel
@onready var status_label: Label = $Hud/HudRoot/StatusLabel
@onready var zhou_label: Label = $Hud/HudRoot/ZhouLine

var regen_rate: float = 12.0
var place_cost: float = 35.0
var ward_damage_per_second: float = 30.0
var fail_threshold: int = 3
var initial_energy: float = 40.0
var energy_max: float = 100.0
var spirit_max_hp: float = 90.0
var move_duration_sec: float = 6.0
var energy: float = 40.0
var cold_passengers: int = 0
var has_ended: bool = false


func _ready() -> void:
	GameManager.set_phase(GameManager.Phase.LEVEL_COMBAT)
	var data: Dictionary = _load_level()
	_apply_level_data(data)
	energy = initial_energy
	title_label.text = "第 1 关  %s" % str(data.get("title", "让人发冷的电梯"))
	InputManager.pointer_pressed.connect(_on_pointer_pressed)
	door_slot.ward_placed.connect(_on_ward_placed)
	spirit.reached_center.connect(_on_spirit_reached_center)
	spirit.defeated.connect(_on_spirit_defeated)
	if "--auto-ward" in OS.get_cmdline_user_args():
		energy = maxf(energy, place_cost)
		_try_place_ward()
	_launch_spirit()
	_refresh_hud()
	print("灰盒开局：%s" % title_label.text)


func _process(delta: float) -> void:
	if has_ended:
		return
	energy = minf(energy_max, energy + regen_rate * delta)
	if door_slot.state == HotspotSlot.State.OCCUPIED and spirit.is_active:
		spirit.apply_damage(ward_damage_per_second * delta)
	_refresh_hud()


func _on_pointer_pressed(screen_pos: Vector2) -> void:
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	if not door_slot.contains_point(world_pos):
		return
	_try_place_ward()


func _on_ward_placed(slot_id: String) -> void:
	print("灰盒：符位 %s 已贴" % slot_id)


func _try_place_ward() -> void:
	if has_ended:
		return
	if door_slot.state == HotspotSlot.State.OCCUPIED:
		status_label.text = "门下缝已经贴过了。"
		return
	if energy < place_cost:
		status_label.text = "符力不够，等它自己回一回。"
		return
	energy -= place_cost
	door_slot.place_ward()
	status_label.text = "符贴上了。别画那么工整，挡住就成。"
	_refresh_hud()


func _on_spirit_reached_center() -> void:
	if has_ended:
		return
	cold_passengers += 1
	print("灰盒：发冷乘客 %d/%d" % [cold_passengers, fail_threshold])
	if cold_passengers >= fail_threshold:
		_fail()
		return
	status_label.text = "又有人缩脖子了。门下缝再盯着点。"
	_launch_spirit()
	_refresh_hud()


func _on_spirit_defeated() -> void:
	if has_ended:
		return
	_win()


func _fail() -> void:
	has_ended = true
	spirit.stop()
	GameManager.set_phase(GameManager.Phase.LEVEL_RESULT)
	zhou_label.text = "老周：今天先到这儿吧，我去问问那谁有没有空。"
	status_label.text = "发冷的人到了 %d 个，这单先停。" % fail_threshold
	_refresh_hud()
	print("灰盒失败：%s" % zhou_label.text)


func _win() -> void:
	has_ended = true
	spirit.stop()
	GameManager.set_phase(GameManager.Phase.LEVEL_RESULT)
	status_label.text = "鬼渣散了。差不多得了，早点交班。"
	_refresh_hud()
	print("灰盒胜利：鬼渣散了")


func _launch_spirit() -> void:
	spirit.launch(door_slot.global_position, center_mark.global_position, spirit_max_hp, move_duration_sec)


func _load_level() -> Dictionary:
	if not FileAccess.file_exists(LEVEL_PATH):
		push_error("缺少关卡数据：%s" % LEVEL_PATH)
		return {}
	var file: FileAccess = FileAccess.open(LEVEL_PATH, FileAccess.READ)
	if file == null:
		push_error("打不开关卡数据")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("关卡数据不是对象")
	return {}


func _apply_level_data(data: Dictionary) -> void:
	regen_rate = float(data.get("regenRate", regen_rate))
	place_cost = float(data.get("placeCost", place_cost))
	ward_damage_per_second = float(data.get("wardDamagePerSecond", ward_damage_per_second))
	fail_threshold = int(data.get("failThreshold", fail_threshold))
	initial_energy = float(data.get("initialEnergy", initial_energy))
	energy_max = float(data.get("energyMax", energy_max))
	var spirit_variant: Variant = data.get("spirit", {})
	if spirit_variant is Dictionary:
		var spirit_data: Dictionary = spirit_variant
		spirit_max_hp = float(spirit_data.get("maxHp", spirit_max_hp))
		move_duration_sec = float(spirit_data.get("moveDurationSec", move_duration_sec))
		door_slot.slot_id = str(spirit_data.get("entryHotspotId", door_slot.slot_id))
	var hotspots_variant: Variant = data.get("hotspots", [])
	if hotspots_variant is Array:
		for item: Variant in hotspots_variant:
			if item is Dictionary:
				var hotspot: Dictionary = item
				door_slot.slot_label = str(hotspot.get("label", door_slot.slot_label))
				break


func _refresh_hud() -> void:
	energy_bar.max_value = energy_max
	energy_bar.value = energy
	var ward_text: String = "已贴符" if door_slot.state == HotspotSlot.State.OCCUPIED else "空位"
	energy_label.text = "符力 %.0f / %.0f（%s）" % [energy, energy_max, ward_text]
	cold_label.text = "发冷乘客 %d/%d" % [cold_passengers, fail_threshold]
