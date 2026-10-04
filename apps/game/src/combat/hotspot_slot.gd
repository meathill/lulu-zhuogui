class_name HotspotSlot
extends Area2D

## 机位里的符位。M1 只有空位和已贴两种状态。

enum State { EMPTY, OCCUPIED }

signal ward_placed(slot_id: String)

@export var slot_id: String = "door-bottom-seam"
@export var slot_label: String = "门下缝"
@export var half_size: Vector2 = Vector2(200, 28)

var state: State = State.EMPTY

@onready var ward_mark: ColorRect = $WardMark


func _ready() -> void:
	ward_mark.visible = false


func contains_point(world_pos: Vector2) -> bool:
	var delta: Vector2 = world_pos - global_position
	return absf(delta.x) <= half_size.x and absf(delta.y) <= half_size.y


func place_ward() -> void:
	state = State.OCCUPIED
	ward_mark.visible = true
	ward_placed.emit(slot_id)
