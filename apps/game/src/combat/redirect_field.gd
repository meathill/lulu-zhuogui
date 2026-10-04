class_name RedirectField
extends RefCounted

## 驱离符只改道，不扣血。


func retarget(actor: SpiritActor, slot: HotspotSlot) -> bool:
	if slot.talisman != "redirect":
		return false
	if not actor.redirectable or actor.attached:
		return false
	if slot.redirect_path.is_empty():
		return false
	actor.path = slot.redirect_path.duplicate()
	actor.path_index = 0
	actor.blocked_by = ""
	if slot.redirect_arrive != "":
		actor.on_arrive = slot.redirect_arrive
	return true
