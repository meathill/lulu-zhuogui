extends "res://src/levels/greybox_stage.gd"

## 贴符、五雷、撕符、召唤阴差。

func _tick(delta: float) -> void:
	# 教学停表只冻威胁时钟。符力照样回，方便看条。
	if coach != null and bool(coach.call("holding")):
		energy.tick(delta)
		coach.call("pulse", delta)
		if auto_mode == "coach":
			coach.call("drive", delta)
		return
	super._tick(delta)
	if coach != null and ended == "":
		coach.call("pulse", delta)
		if auto_mode == "coach":
			coach.call("drive", delta)


func tutorial_paint(hot_ids: PackedStringArray, tool_id: String, energy_on: bool) -> void:
	for slot_id in slots.keys():
		var slot := slots[slot_id] as HotspotSlot
		if slot == null:
			continue
		slot.set_coached(hot_ids.has(str(slot_id)))
	if hud == null:
		return
	hud.highlight_tool("ward", tool_id == "ward")
	hud.highlight_tool("tear", tool_id == "tear")
	hud.highlight_energy(energy_on)


func _unhandled_input(event: InputEvent) -> void:
	if paused or ended != "" or not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if _pick_cabin(mouse.position):
		return
	_click(get_global_mouse_position())


func _pick_cabin(screen_pos: Vector2) -> bool:
	var view := get_node_or_null("ElevatorView")
	if view == null:
		return false
	var slot_id := str(view.call("pick", screen_pos))
	if slot_id == "":
		return true
	var slot: HotspotSlot = slots.get(slot_id)
	if slot == null:
		return true
	if slot.role == "backpack":
		click_backpack()
		return true
	if coach != null and bool(coach.call("intercept_slot", slot.slot_id)):
		_refresh()
		return true
	_use(slot)
	return true


func try_place(tool_id: String, slot_id: String) -> void:
	current_tool = tool_id
	var slot: HotspotSlot = slots.get(slot_id)
	if slot == null:
		return
	_use(slot)


func try_lightning(slot_id: String) -> void:
	current_tool = "lightning"
	var slot: HotspotSlot = slots.get(slot_id)
	if slot != null:
		_cast_lightning(slot)


func try_tear(slot_id: String) -> void:
	current_tool = "tear"
	var slot: HotspotSlot = slots.get(slot_id)
	if slot != null:
		_tear(slot)


func try_summon() -> void:
	if ended != "":
		return
	var result := summon.evaluate(actors, win_kind, form, _hold_ready())
	match result:
		"ok":
			_summon_ok()
		"refuse":
			status_text = "马科长：普通祟团不接收！有名有姓的再叫我。"
			print(status_text)
		"attached":
			status_text = "先撕符，把魂和旁边的祟分开。糊在一起阴差不收。"
		"unformed":
			status_text = "成型条还没满，送不走。"
		"need-hold":
			status_text = "先定神稳住，再召唤阴差。"
		_:
			status_text = "还没按住谁。"


func try_tame() -> void:
	if ended != "" or not is_held("pudding"):
		status_text = "先把布丁定在角落，再收服。"
		return
	_set_pudding("tamed")
	status_text = "收成伙伴了。没有项圈。"
	_win("布丁跟你走了。")


func try_disperse() -> void:
	if ended != "" or not is_held("pudding"):
		status_text = "先按住再驱散。五雷直接砸会把狗打碎。"
		return
	_set_pudding("scattered")
	status_text = "驱散结案。没有项圈。"
	_win("布丁散了。往后只能靠监控找小禾。")


func switch_camera(camera_id: String) -> void:
	current_camera = camera_id
	for item in slots.values():
		var slot := item as HotspotSlot
		slot.visible = camera_mode != "multi" or slot.camera_id == current_camera
	status_text = "切到机位 %s。只能往当前画面贴符。" % camera_id


func click_backpack() -> void:
	backpack_seen = true
	var flag := str(SaveManager.load_local().get("pudding", ""))
	var tail := "巷子里有东西盯上她了，今晚得替她守着。"
	if flag == "taken":
		tail = "和项圈对得上，是同一只狗。"
	status_text = "书包上挂着掉漆的旧狗牌，刻着「布丁」。" + tail


func advance_dialogue() -> void:
	if lines_seen >= dialogue.size():
		return
	lines_seen += 1
	status_text = dialogue[lines_seen - 1]


func is_held(actor_id: String) -> bool:
	var actor := _find(actor_id)
	return actor != null and actor.held and not actor.dead


func _click(world: Vector2) -> void:
	var best: HotspotSlot = null
	var best_dist := 99999.0
	for item in slots.values():
		var slot := item as HotspotSlot
		if not slot.visible:
			continue
		var dist := slot.position.distance_to(world)
		if dist < best_dist and slot.contains_point(world):
			best = slot
			best_dist = dist
	if best == null:
		return
	if best.role == "backpack":
		click_backpack()
		return
	if coach != null and bool(coach.call("intercept_slot", best.slot_id)):
		_refresh()
		return
	_use(best)


func _use(slot: HotspotSlot) -> void:
	if ended != "":
		return
	if camera_mode == "multi" and slot.camera_id != current_camera:
		status_text = "这个位子在别的机位，先切监控。"
		return
	match current_tool:
		"tear":
			_tear(slot)
		"lightning":
			_cast_lightning(slot)
		"reveal":
			_cast_reveal(slot)
		_:
			_stick(slot, current_tool)


func _stick(slot: HotspotSlot, tool_id: String) -> void:
	if slot.role == "body":
		status_text = "符贴在环境上。只有显形能贴被附身的人。"
		return
	if not slot.accepts.has(tool_id):
		status_text = "这个位子贴不了这张符。"
		return
	if slot.talisman == tool_id:
		return
	if not energy.try_spend(place_cost):
		status_text = "符力不够，等它自己回一回。"
		return
	slot.set_talisman(tool_id)
	match tool_id:
		"redirect":
			status_text = "驱离贴上了。只改道，不造成伤害。"
		"hold":
			status_text = "定神贴上了。按住之后才能召唤阴差。"
		_:
			status_text = "镇守贴上了。经过的祟会被挡住。"
	if coach != null:
		coach.call("on_stuck", slot.slot_id, tool_id)


func _cast_reveal(slot: HotspotSlot) -> void:
	if slot.role != "body":
		status_text = "显形只能贴在被附身的人身上。"
		return
	if slot.talisman == "reveal":
		return
	if not energy.try_spend(place_cost):
		status_text = "符力不够，等它自己回一回。"
		return
	slot.set_talisman("reveal")
	revealed = true
	status_text = "附身现形了。五雷扔地上打核，别打人。"


func _cast_lightning(slot: HotspotSlot) -> void:
	if slot.role == "body":
		_fail("没显形就劈在活人身上，宿主受伤了。")
		return
	if slot.role != "ground":
		status_text = "五雷得扔在地上引雷，不能往人身上贴。"
		return
	if time_sec < lightning_ready:
		return
	if not energy.try_spend(lightning_cost):
		status_text = "符力不够，雷引不下来。"
		return
	lightning_ready = time_sec + 0.35
	var any := false
	for actor_id in slot.lightning_hits:
		var actor := _find(actor_id)
		if actor != null and _zap(actor):
			any = true
	for actor in actors:
		if actor.dead or actor.position.distance_to(slot.position) > 170.0:
			continue
		if _zap(actor):
			any = true
	if any and ended == "":
		status_text = "五雷扔在地上，天雷落下来了。"


func _zap(actor: SpiritActor) -> bool:
	if actor.dead:
		return false
	if actor.immune_until_reveal and not revealed:
		status_text = "还没显形，雷打不中附身核。"
		return false
	if actor.kind == "dog":
		actor.apply_damage(lightning_damage)
		status_text = "五雷会伤到布丁。"
		if actor.hp <= 0.0:
			_fail("布丁被攻击符打碎了。")
		return true
	if actor.fragile:
		_fail("魂被打碎了。碎了不会没，只会往低处流。")
		return true
	if not actor.damageable or actor.kind == "good" or actor.kind == "shadow":
		return false
	actor.apply_damage(lightning_damage)
	if actor.hp <= 0.0:
		_resolve(actor)
	return true


func _tear(slot: HotspotSlot) -> void:
	var separated := _separate(slot)
	if slot.talisman != "":
		slot.clear_talisman()
		for actor in actors:
			if actor.blocked_by == slot.slot_id:
				actor.blocked_by = ""
		status_text = "符撕掉了，位子空出来。"
		if coach != null:
			coach.call("on_tore", slot.slot_id)
		return
	status_text = "撕开了，魂和祟分开了。" if separated else "这儿没有可撕的符。"


func _separate(slot: HotspotSlot) -> bool:
	var near := false
	for actor in actors:
		if actor.attached and actor.position.distance_to(slot.position) <= 180.0:
			near = true
	if not near:
		return false
	for actor in actors:
		if not actor.attached:
			continue
		actor.attached = false
		if actor.kind == "sui":
			actor.damageable = true
			actor.parked = false
			if actor.after_tear_path.size() > 0:
				actor.path = actor.after_tear_path.duplicate()
				actor.path_index = 0
				actor.blocked_by = ""
				if actor.after_tear_arrive != "":
					actor.on_arrive = actor.after_tear_arrive
		actor.refresh()
	return true


func _summon_ok() -> void:
	if level_id == "level-07":
		_set_pudding("taken")
		_win("阴差带走了布丁，刻着「布丁」的项圈留下了。")
		return
	if level_id == "level-06":
		_win("成型灵稳住了，阴差送去投胎。")
		return
	_win("阴差到了，交接完成。")


func _hold_ready() -> bool:
	for item in slots.values():
		if (item as HotspotSlot).talisman == "hold":
			return true
	return false


