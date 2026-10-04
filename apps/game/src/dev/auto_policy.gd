extends RefCounted

## 无头自测用的胜局手顺。失败局什么都不做，让破线自己发生。

var level: Node
var refused: bool = false


func tick() -> void:
	match str(level.get("level_id")):
		"level-01":
			_place("ward", "door-bottom-seam")
			_place("ward", "door-seam")
			_place("ward", "floor-panel")
		"level-02":
			_place("ward", "hall")
			_place("ward", "bath-door")
			level.call("try_lightning", "ground")
		"level-03":
			_place("reveal", "drunk")
			_place("ward", "door-seam")
			_place("ward", "zebra")
			level.call("try_lightning", "ground")
		"level-04":
			_place("redirect", "seat")
			_place("ward", "aisle")
		"level-05":
			_l5()
		"level-06":
			_place("ward", "debris-gate")
			if float(level.get("form")) >= 100.0:
				_place("hold", "circle")
				level.call("try_summon")
		"level-07":
			level.call("try_tear", "flower")
			_place("redirect", "flower")
			_place("hold", "corner")
			if bool(level.call("is_held", "pudding")):
				level.call("try_summon")
		"level-08":
			level.call("click_backpack")
			level.call("advance_dialogue")
			level.call("advance_dialogue")
			level.call("advance_dialogue")
			_place("ward", "path-a")
			_place("ward", "alley")
		"level-09":
			level.call("try_tear", "column")
			_place("ward", "pillar")
		"level-10":
			_place("ward", "door-seam")
			_place("hold", "bed")
			level.call("try_lightning", "bedroom-ground")


func _l5() -> void:
	if not refused:
		level.call("switch_camera", "A")
		_place("hold", "low-sui")
		if bool(level.call("is_held", "sui-low")):
			level.call("try_summon")
			if "不接收" in str(level.get("status_text")):
				refused = true
	_place("redirect", "fork")
	level.call("switch_camera", "B")
	_place("hold", "handoff")
	if bool(level.call("is_held", "min")):
		level.call("try_summon")


func _place(tool_id: String, slot_id: String) -> void:
	level.call("try_place", tool_id, slot_id)
