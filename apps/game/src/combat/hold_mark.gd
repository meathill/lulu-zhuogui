class_name HoldMark
extends RefCounted

## 定神把人按住，不打碎。狗必须先在角落里。


func grab(actor: SpiritActor, slot: HotspotSlot) -> bool:
	if slot.talisman != "hold" or actor.dead:
		return false
	if actor.position.distance_to(slot.position) > 110.0:
		return false
	if actor.kind == "dog" and not actor.in_corner:
		return false
	actor.held = true
	actor.parked = true
	return true
