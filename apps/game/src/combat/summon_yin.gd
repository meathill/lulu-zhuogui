class_name SummonYin
extends RefCounted

## 定神之后才能叫阴差。普通祟团拒收；粘着祟的有名魂也先撕开。


func evaluate(actors: Array, win_kind: String, form_value: float, hold_ready: bool) -> String:
	if win_kind == "form-send":
		if form_value < 100.0:
			return "unformed"
		if not hold_ready:
			return "need-hold"
		return "ok"

	var named_held := false
	var named_attached := false
	var ordinary_held := false
	for item in actors:
		var actor := item as SpiritActor
		if actor == null or actor.dead or not actor.held:
			continue
		if actor.named:
			named_held = true
			if actor.attached:
				named_attached = true
		else:
			ordinary_held = true
	if named_attached:
		return "attached"
	if named_held:
		return "ok"
	if ordinary_held:
		return "refuse"
	return "none"
