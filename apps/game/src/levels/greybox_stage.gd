extends "res://src/levels/greybox_state.gd"

## 摆场、出波、沿符位走位。

func _build_room(data: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.offset_right = 1920
	bg.offset_bottom = 1080
	var rgb: Variant = data.get("bg", [0.1, 0.11, 0.13])
	if rgb is Array and rgb.size() >= 3:
		bg.color = Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))
	add_child(bg)


func _build_slots(data: Dictionary) -> void:
	var raw: Variant = data.get("hotspots", [])
	if not raw is Array:
		return
	for item in raw:
		if not item is Dictionary:
			continue
		var spec := item as Dictionary
		var slot := HotspotSlot.new()
		slot.slot_id = str(spec.get("id", ""))
		slot.slot_label = str(spec.get("label", slot.slot_id))
		slot.position = Vector2(float(spec.get("x", 0)), float(spec.get("y", 0)))
		slot.camera_id = str(spec.get("camera", "A"))
		slot.role = str(spec.get("role", "env"))
		slot.accepts = _strings(spec.get("accepts", []))
		slot.redirect_path = _strings(spec.get("redirectTo", []))
		slot.redirect_arrive = str(spec.get("redirectArrive", ""))
		slot.lightning_hits = _strings(spec.get("lightningHits", []))
		add_child(slot)
		slot.apply_font(font)
		if camera_mode == "multi" and slot.camera_id != current_camera:
			slot.visible = false
		slots[slot.slot_id] = slot


func _build_waves(data: Dictionary) -> void:
	var raw: Variant = data.get("waves", [])
	if not raw is Array:
		return
	for item in raw:
		if item is Dictionary:
			var wave := (item as Dictionary).duplicate(true)
			wave["done"] = false
			waves.append(wave)


func _build_hud(data: Dictionary) -> void:
	hud = HudBar.new()
	add_child(hud)
	hud.build(str(data.get("title", "")), str(data.get("goal", "")), _strings(data.get("tools", [])), camera_mode == "multi")
	hud.tool_selected.connect(func(tool_id: String) -> void: current_tool = tool_id)
	hud.summon_pressed.connect(func() -> void: call("try_summon"))
	hud.tame_pressed.connect(func() -> void: call("try_tame"))
	hud.disperse_pressed.connect(func() -> void: call("try_disperse"))
	hud.camera_pressed.connect(func(camera_id: String) -> void: call("switch_camera", camera_id))
	hud.dialogue_pressed.connect(func() -> void: call("advance_dialogue"))
	hud.restart_pressed.connect(func() -> void: get_tree().reload_current_scene())
	hud.menu_pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu/level_select.tscn"))


func _spawn_due() -> void:
	for wave in waves:
		if bool(wave["done"]) or time_sec < float(wave["at"]):
			continue
		wave["done"] = true
		var specs: Variant = wave.get("actors", [])
		if specs is Array:
			for spec in specs:
				if spec is Dictionary:
					_spawn(spec)


func _spawn(spec: Dictionary) -> void:
	var actor := SpiritActor.new()
	add_child(actor)
	actor.setup(spec)
	actor.apply_font(font)
	actor.z_index = 3
	if actor.path.size() > 0:
		var origin := _slot(actor.path[0])
		if origin != null:
			actor.position = origin.position
	if actor.attached and actor.cling_to != "":
		var host := _find(actor.cling_to)
		if host != null:
			host.attached = true
			host.refresh()
			actor.damageable = false
			actor.parked = true
			actor.position = host.position
	if actor.must_resolve:
		unresolved += 1
	spawned_count += 1
	actors.append(actor)
	actor.refresh()


func _move(delta: float) -> void:
	for actor in actors:
		if actor.dead or actor.parked or actor.held:
			continue
		if actor.blocked_by != "":
			_soak(actor, delta)
			continue
		if actor.path.is_empty():
			continue
		var slot := _slot(actor.path[actor.path_index])
		if slot == null:
			continue
		if actor.position.distance_to(slot.position) <= actor.speed * delta:
			actor.position = slot.position
			_on_reach(actor, slot)
		else:
			actor.position = actor.position.move_toward(slot.position, actor.speed * delta)
		if camera_mode == "multi":
			actor.visible = slot.camera_id == current_camera


func _on_reach(actor: SpiritActor, slot: HotspotSlot) -> void:
	if redirect.retarget(actor, slot):
		status_text = "驱离改道了，不伤血。"
		return
	if _try_block(actor, slot):
		return
	if actor.path_index < actor.path.size() - 1:
		actor.path_index += 1
		return
	_finish(actor)


func _try_block(actor: SpiritActor, slot: HotspotSlot) -> bool:
	if slot.talisman != "ward" or not actor.damageable or actor.ward_immune:
		return false
	if actor.immune_until_reveal and not revealed:
		return false
	if actor.attached and actor.kind == "sui":
		return false
	actor.blocked_by = slot.slot_id
	return true


func _soak(actor: SpiritActor, delta: float) -> void:
	var slot := _slot(actor.blocked_by)
	if slot == null or slot.talisman != "ward":
		actor.blocked_by = ""
		return
	actor.apply_damage(ward_dps * delta)
	if actor.hp <= 0.0:
		_resolve(actor)


func _finish(actor: SpiritActor) -> void:
	match actor.on_arrive:
		"cold":
			_meter("cold", 1)
		"fear", "clog":
			_meter(actor.on_arrive, 1)
		"offering":
			_meter("offering", 1)
		"yang":
			_meter("yang", -1)
		"form":
			form += actor.payload
			status_text = "成型条 %.0f。" % form
		"form-hit":
			form -= actor.payload
			if form <= 0.0:
				_fail("灵没成型，被冲散了。")
				return
		"exit":
			status_text = "善鬼被赶到后半节，到站自己下。"
		"escape":
			_fail(actor.escape_text if actor.escape_text != "" else "目标冲出去了。")
			return
		"corner":
			actor.in_corner = true
			actor.parked = true
			status_text = "布丁进了角落。定神按住，再召唤阴差。"
			actor.refresh()
			return
		"park":
			actor.parked = true
			return
		"cling":
			_cling(actor)
			return
	_resolve(actor)


func _cling(actor: SpiritActor) -> void:
	var host := _find(actor.cling_to)
	if host == null:
		_resolve(actor)
		return
	actor.attached = true
	host.attached = true
	actor.damageable = false
	actor.parked = true
	actor.position = host.position
	actor.refresh()
	host.refresh()
	status_text = "祟粘上来了。撕符才能分开。"


func _apply_holds() -> void:
	for item in slots.values():
		var slot := item as HotspotSlot
		if slot.talisman != "hold":
			continue
		for actor in actors:
			if hold.grab(actor, slot):
				actor.refresh()


func _kick() -> void:
	if kicked or kick_slot == "" or time_sec < kick_at:
		return
	kicked = true
	var slot := _slot(kick_slot)
	if slot == null or slot.talisman != "ward":
		return
	slot.clear_talisman()
	for actor in actors:
		if actor.blocked_by == kick_slot:
			actor.blocked_by = ""
	status_text = "乘客把门下缝的符踢掉了，补贴一张。"


func _assist(delta: float) -> void:
	for actor in actors:
		if actor.kind == "boss" and not actor.dead:
			actor.apply_damage(22.0 * delta)
			if actor.hp <= 0.0:
				_resolve(actor)


