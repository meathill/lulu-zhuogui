class_name SpiritActor
extends Node2D

## 一条路上的鬼、善鬼、狗或 Boss。血和走位由关卡按符位规则推。

signal reached_center
signal defeated

var actor_id: String = ""
var kind: String = "sui"
var label_text: String = ""
var max_hp: float = 30.0
var hp: float = 30.0
var speed: float = 220.0
var path: PackedStringArray = PackedStringArray()
var path_index: int = 0
var on_arrive: String = ""
var named: bool = false
var redirectable: bool = false
var damageable: bool = true
var ward_immune: bool = false
var immune_until_reveal: bool = false
var fragile: bool = false
var must_resolve: bool = true
var attached: bool = false
var held: bool = false
var parked: bool = false
var in_corner: bool = false
var dead: bool = false
var resolved: bool = false
var blocked_by: String = ""
var cling_to: String = ""
var after_tear_path: PackedStringArray = PackedStringArray()
var after_tear_arrive: String = ""
var payload: float = 1.0
var escape_text: String = ""
var is_active: bool = true

var _body: ColorRect
var _caption: Label


func _ready() -> void:
	_body = ColorRect.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.offset_left = -46
	_body.offset_top = -22
	_body.offset_right = 46
	_body.offset_bottom = 22
	add_child(_body)
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.position = Vector2(-46, -16)
	_caption.size = Vector2(92, 32)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 18)
	add_child(_caption)
	_paint()


func setup(spec: Dictionary) -> void:
	actor_id = str(spec.get("id", ""))
	kind = str(spec.get("kind", "sui"))
	label_text = str(spec.get("label", kind))
	max_hp = float(spec.get("hp", 30))
	hp = max_hp
	speed = float(spec.get("speed", 220))
	path = _strings(spec.get("path", []))
	path_index = 0
	on_arrive = str(spec.get("onArrive", ""))
	named = bool(spec.get("named", false)) or kind == "dog" or kind == "named"
	redirectable = bool(spec.get("redirectable", false))
	ward_immune = bool(spec.get("wardImmune", false))
	immune_until_reveal = bool(spec.get("immuneUntilReveal", false))
	fragile = bool(spec.get("fragile", false))
	attached = bool(spec.get("attached", false))
	cling_to = str(spec.get("clingTo", ""))
	after_tear_path = _strings(spec.get("afterTearPath", []))
	after_tear_arrive = str(spec.get("afterTearArrive", ""))
	payload = float(spec.get("payload", 1))
	escape_text = str(spec.get("escapeText", ""))
	if spec.has("damageable"):
		damageable = bool(spec["damageable"])
	else:
		damageable = kind not in ["good", "dog", "fragment", "shadow"]
	if spec.has("mustResolve"):
		must_resolve = bool(spec["mustResolve"])
	else:
		must_resolve = kind in ["sui", "evil", "core", "debris", "boss", "good"]
	_paint()


func apply_font(font: Font) -> void:
	if _caption != null:
		_caption.add_theme_font_override("font", font)


func refresh() -> void:
	_paint()


func apply_damage(amount: float) -> void:
	if dead:
		return
	hp = maxf(0.0, hp - amount)
	_paint()
	if hp <= 0.0:
		dead = true
		visible = false
		defeated.emit()


func stop() -> void:
	is_active = false
	parked = true


func launch(from: Vector2, to: Vector2, health: float, duration: float) -> void:
	position = from
	max_hp = health
	hp = health
	speed = from.distance_to(to) / maxf(duration, 0.01)
	path = PackedStringArray()
	is_active = true
	visible = true


func _paint() -> void:
	if _body == null:
		return
	var tint := Color(0.12, 0.12, 0.14, 0.94)
	match kind:
		"good":
			tint = Color(0.55, 0.72, 0.78, 0.94)
		"dog":
			tint = Color(0.84, 0.66, 0.24, 0.96)
		"core":
			tint = Color(0.55, 0.12, 0.22, 0.96)
		"boss":
			tint = Color(0.42, 0.05, 0.1, 0.96)
		"named":
			tint = Color(0.35, 0.42, 0.55, 0.96)
		"fragment":
			tint = Color(0.72, 0.76, 0.9, 0.94)
		"debris":
			tint = Color(0.32, 0.3, 0.18, 0.94)
		"shadow":
			tint = Color(0.04, 0.04, 0.06, 0.96)
		"evil":
			tint = Color(0.28, 0.06, 0.08, 0.96)
	var ratio := 1.0
	if max_hp > 0.0:
		ratio = clampf(hp / max_hp, 0.25, 1.0)
	_body.color = tint
	_body.color.a = 0.45 + 0.5 * ratio
	var state := ""
	if attached:
		state = "·粘"
	elif held:
		state = "·定"
	_caption.text = label_text + state


func _strings(value: Variant) -> PackedStringArray:
	var out: PackedStringArray = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out
