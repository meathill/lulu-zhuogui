class_name HotspotSlot
extends Node2D

## 机位里的环境符位。符贴在位子上，不贴人；显形是唯一贴在附身者身上的例外。

signal pressed(slot_id: String)

@export var slot_id: String = ""
@export var slot_label: String = ""
@export var half_size: Vector2 = Vector2(78, 36)

var camera_id: String = "A"
var role: String = "env"
var accepts: PackedStringArray = PackedStringArray()
var redirect_path: PackedStringArray = PackedStringArray()
var redirect_arrive: String = ""
var lightning_hits: PackedStringArray = PackedStringArray()
var talisman: String = ""
var coached: bool = false
var plate: ColorRect
var caption: Label


func _ready() -> void:
	plate = ColorRect.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.offset_left = -half_size.x
	plate.offset_top = -half_size.y
	plate.offset_right = half_size.x
	plate.offset_bottom = half_size.y
	plate.color = Color(0.22, 0.24, 0.28, 0.95)
	add_child(plate)
	caption = Label.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.position = Vector2(-half_size.x + 6, -14)
	caption.size = Vector2(half_size.x * 2 - 8, 28)
	caption.add_theme_font_size_override("font_size", 20)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(caption)
	refresh()


func contains_point(world_pos: Vector2) -> bool:
	var delta := world_pos - global_position
	return absf(delta.x) <= half_size.x and absf(delta.y) <= half_size.y


func place_ward() -> void:
	set_talisman("ward")


func set_talisman(kind: String) -> void:
	talisman = kind
	refresh()


func clear_talisman() -> void:
	talisman = ""
	refresh()


func set_coached(on: bool) -> void:
	coached = on
	modulate = Color(1.25, 1.08, 0.45) if on else Color(1, 1, 1)


func refresh() -> void:
	if caption == null:
		return
	var tag := ""
	match talisman:
		"ward":
			tag = "·镇守"
		"redirect":
			tag = "·驱离"
		"hold":
			tag = "·定神"
		"reveal":
			tag = "·显形"
	caption.text = slot_label + tag
	match role:
		"ground":
			plate.color = Color(0.28, 0.22, 0.14, 0.95)
		"body":
			plate.color = Color(0.32, 0.2, 0.2, 0.95)
		"backpack":
			plate.color = Color(0.2, 0.28, 0.24, 0.95)
		_:
			plate.color = Color(0.2, 0.24, 0.3, 0.95)
	if talisman == "ward":
		plate.color = Color(0.72, 0.58, 0.22, 0.95)
	elif talisman == "redirect":
		plate.color = Color(0.25, 0.45, 0.38, 0.95)
	elif talisman == "hold":
		plate.color = Color(0.25, 0.35, 0.62, 0.95)
	elif talisman == "reveal":
		plate.color = Color(0.72, 0.72, 0.78, 0.95)


func apply_font(font: Font) -> void:
	if caption != null:
		caption.add_theme_font_override("font", font)
