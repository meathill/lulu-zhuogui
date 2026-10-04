class_name HudBar
extends CanvasLayer

## 关卡抬头、符按钮和结算。文字全是中文。
## 位置跟当前可见区域走，不写死 1920 或 y=900。

signal tool_selected(tool_id: String)
signal summon_pressed
signal tame_pressed
signal disperse_pressed
signal camera_pressed(camera_id: String)
signal dialogue_pressed
signal restart_pressed
signal menu_pressed
signal energy_pressed

var _root: Control
var _top: ColorRect
var _bottom: ColorRect
var _title: Label
var _goal: Label
var _meters: Label
var _energy: Label
var _status: Label
var _clock: Label
var _zhou: Label
var _dialogue: Label
var _end: Label
var _end_box: ColorRect
var _energy_hit: Button
var _talk: Button
var _retry: Button
var _back: Button
var _tool_buttons: Dictionary = {}
var _bottom_buttons: Array[Button] = []
var _wired: bool = false


func build(title: String, goal: String, tools: PackedStringArray, multi_camera: bool) -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.make()
	add_child(_root)
	_top = _panel(_root)
	_title = _label(_top, title, 28)
	_clock = _label(_top, "时间 00:00  波次 0/0", 22)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_goal = _label(_top, goal, 22)
	_meters = _label(_top, "", 20)
	_energy = _label(_top, "", 20)
	_energy_hit = Button.new()
	_energy_hit.flat = true
	_energy_hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_energy_hit.pressed.connect(func() -> void: energy_pressed.emit())
	_top.add_child(_energy_hit)
	_status = _label(_top, "", 20)
	_zhou = _label(_top, "", 20)
	_bottom = _panel(_root)
	for tool_id in tools:
		if tool_id == "summon":
			var summon := _button(_bottom, "召唤阴差")
			summon.pressed.connect(func() -> void: summon_pressed.emit())
			_bottom_buttons.append(summon)
		elif tool_id == "tame":
			var tame := _button(_bottom, "收服")
			tame.pressed.connect(func() -> void: tame_pressed.emit())
			_bottom_buttons.append(tame)
		elif tool_id == "disperse":
			var disperse := _button(_bottom, "驱散")
			disperse.pressed.connect(func() -> void: disperse_pressed.emit())
			_bottom_buttons.append(disperse)
		else:
			var captured := tool_id
			var button := _button(_bottom, _tool_name(captured))
			button.pressed.connect(func() -> void: tool_selected.emit(captured))
			_tool_buttons[captured] = button
			_bottom_buttons.append(button)
	if multi_camera:
		var cam_a := _button(_bottom, "机位A")
		cam_a.pressed.connect(func() -> void: camera_pressed.emit("A"))
		_bottom_buttons.append(cam_a)
		var cam_b := _button(_bottom, "机位B")
		cam_b.pressed.connect(func() -> void: camera_pressed.emit("B"))
		_bottom_buttons.append(cam_b)
	_dialogue = _label(_bottom, "", 22)
	_dialogue.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_dialogue.clip_text = true
	_talk = _button(_bottom, "下一句")
	_talk.pressed.connect(func() -> void: dialogue_pressed.emit())
	_bottom_buttons.append(_talk)
	_end_box = _panel(_root)
	_end_box.visible = false
	_end = _label(_end_box, "", 28)
	_end.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_end.clip_text = true
	_retry = _button(_end_box, "本关重开")
	_retry.pressed.connect(func() -> void: restart_pressed.emit())
	_back = _button(_end_box, "回选关")
	_back.pressed.connect(func() -> void: menu_pressed.emit())
	if not get_viewport().size_changed.is_connected(_relayout):
		get_viewport().size_changed.connect(_relayout)
	_wired = true
	_relayout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and _wired:
		call_deferred("_relayout")


func set_energy(text: String) -> void:
	_energy.text = text


func set_meters(text: String) -> void:
	_meters.text = text


func set_status(text: String) -> void:
	_status.text = text


func set_clock(text: String) -> void:
	if _clock != null:
		_clock.text = text


func set_zhou(text: String) -> void:
	_zhou.text = text


func set_dialogue(text: String) -> void:
	_dialogue.text = text


func set_coach(text: String) -> void:
	_dialogue.text = text


func highlight_tool(tool_id: String, on: bool) -> void:
	var button := _tool_buttons.get(tool_id) as Button
	if button == null:
		return
	button.modulate = Color(1, 0.82, 0.35) if on else Color(1, 1, 1)


func highlight_energy(on: bool) -> void:
	_energy.modulate = Color(1, 0.9, 0.4) if on else Color(1, 1, 1)
	if _energy_hit != null:
		_energy_hit.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE


func show_end(text: String) -> void:
	_end.text = text
	_end_box.visible = true
	_relayout()


func _tool_name(tool_id: String) -> String:
	match tool_id:
		"ward":
			return "镇守"
		"lightning":
			return "五雷"
		"reveal":
			return "显形"
		"redirect":
			return "驱离"
		"hold":
			return "定神"
		"tear":
			return "撕符"
		_:
			return tool_id


func _visible_size() -> Vector2:
	var vis := get_viewport().get_visible_rect().size
	if vis.x < 2.0 or vis.y < 2.0:
		return Vector2(1280, 720)
	return vis


func _units_per_px(vis: Vector2) -> float:
	var win := DisplayServer.window_get_size()
	if win.x <= 1 or win.y <= 1 or vis.x <= 1.0 or vis.y <= 1.0:
		return 1.0
	return maxf(vis.x / float(win.x), vis.y / float(win.y))


func _relayout() -> void:
	if not _wired or _root == null:
		return
	var vis := _visible_size()
	var upp := _units_per_px(vis)
	var portrait := vis.y > vis.x
	var min_btn := maxf(48.0, 48.0 * upp)
	var margin := clampf(10.0 * upp, 12.0, vis.x * 0.06)
	var gap := clampf(8.0 * upp, 8.0, 24.0)
	var font_title := int(maxf(26.0, 18.0 * upp))
	var font_body := int(maxf(20.0, 15.0 * upp))
	var font_small := int(maxf(18.0, 13.0 * upp))
	# 窄或矮时字再大一号，拇指和眼睛都够得到。
	var cramped := portrait or vis.x < 1100.0 or vis.y < 900.0
	if cramped:
		font_body = int(maxf(font_body, 16.0 * upp))
		font_title = int(maxf(font_title, 18.0 * upp))
	_root.position = Vector2.ZERO
	_root.size = vis
	_style(_title, font_title)
	_style(_goal, font_body)
	_style(_meters, font_small)
	_style(_energy, font_small)
	_style(_status, font_small)
	_style(_clock, font_small)
	_style(_zhou, font_small)
	_style(_dialogue, font_body)
	_style(_end, font_body)
	if portrait:
		_layout_top_portrait(vis, margin, font_title, font_small)
	else:
		_layout_top_wide(vis, margin, gap, upp, font_title, font_body, font_small)
	_layout_bottom(vis, margin, gap, min_btn, font_body, cramped)
	_layout_end(vis, margin, gap, min_btn, font_body)


func _layout_top_portrait(vis: Vector2, margin: float, font_title: int, font_small: int) -> void:
	# 竖屏顶栏两行：标题，下面整行时钟。符力和乘客条挪到底栏，避免挤成一团。
	_goal.visible = false
	_status.visible = false
	_zhou.visible = false
	_attach(_meters, _bottom)
	_attach(_energy, _bottom)
	_attach(_energy_hit, _bottom)
	var line1 := float(font_title) + margin * 0.2
	var line2 := float(font_small) * 1.35
	var top_h := margin * 0.4 + line1 + line2 + margin * 0.25
	_top.position = Vector2.ZERO
	_top.size = Vector2(vis.x, top_h)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.clip_text = true
	_title.position = Vector2(margin, margin * 0.2)
	_title.size = Vector2(vis.x - margin * 2.0, line1)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_clock.clip_text = true
	_clock.position = Vector2(margin, margin * 0.2 + line1)
	_clock.size = Vector2(vis.x - margin * 2.0, line2)


func _layout_top_wide(vis: Vector2, margin: float, _gap: float, upp: float, font_title: int, font_body: int, font_small: int) -> void:
	_goal.visible = true
	_meters.visible = true
	_status.visible = true
	_zhou.visible = true
	_attach(_meters, _top)
	_attach(_energy, _top)
	_attach(_energy_hit, _top)
	var y := margin * 0.45
	var row_title := float(font_title) + 6.0
	var row := float(font_small) + 4.0
	var clock_w := clampf(_text_width(_clock, font_small) + margin * 2.0, vis.x * 0.36, vis.x * 0.5)
	var title_room := vis.x - margin * 3.0 - clock_w
	var narrow := title_room < _text_width(_title, font_title) * 0.82 or vis.x < 1100.0
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.clip_text = true
	_title.position = Vector2(margin, y)
	if narrow:
		_title.size = Vector2(vis.x - margin * 2.0, row_title)
		y += row_title
		_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_clock.position = Vector2(margin, y)
		_clock.size = Vector2(vis.x - margin * 2.0, row)
		y += row
	else:
		_title.size = Vector2(title_room, row_title)
		_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_clock.position = Vector2(vis.x - margin - clock_w, y)
		_clock.size = Vector2(clock_w, row_title)
		y += row_title
	var goal_lines := 2.0 if vis.y > 980.0 else 1.0
	_goal.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_goal.clip_text = true
	_goal.position = Vector2(margin, y)
	_goal.size = Vector2(vis.x - margin * 2.0, float(font_body) * goal_lines + 4.0)
	y += _goal.size.y
	_meters.autowrap_mode = TextServer.AUTOWRAP_OFF
	_meters.clip_text = true
	_meters.position = Vector2(margin, y)
	_meters.size = Vector2(vis.x - margin * 2.0, row)
	y += row
	var zhou_w := minf(vis.x * 0.42, maxf(220.0, 280.0 * upp))
	var split := vis.x > 1400.0
	_energy.autowrap_mode = TextServer.AUTOWRAP_OFF
	_energy.clip_text = true
	_energy.position = Vector2(margin, y)
	_energy.size = Vector2((vis.x - margin * 2.0 - zhou_w) if split else vis.x - margin * 2.0, row)
	_energy_hit.position = _energy.position
	_energy_hit.size = _energy.size
	y += row
	_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.clip_text = true
	_status.position = Vector2(margin, y)
	_status.size = Vector2((vis.x - margin * 2.0 - zhou_w) if split else vis.x - margin * 2.0, row)
	if split:
		_zhou.position = Vector2(vis.x - margin - zhou_w, y - row)
		_zhou.size = Vector2(zhou_w, row * 2.0)
		_zhou.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_zhou.clip_text = true
	else:
		y += row
		_zhou.position = Vector2(margin, y)
		_zhou.size = Vector2(vis.x - margin * 2.0, row)
		_zhou.autowrap_mode = TextServer.AUTOWRAP_OFF
		_zhou.clip_text = true
	y += row
	var cap := vis.y * 0.28
	if y + margin > cap and vis.y < 1400.0:
		y = cap
	_top.position = Vector2.ZERO
	_top.size = Vector2(vis.x, y + margin * 0.3)


func _layout_bottom(vis: Vector2, margin: float, gap: float, min_btn: float, font_body: int, cramped: bool) -> void:
	var font_btn := int(clampf(float(font_body), 16.0, min_btn * 0.42))
	var max_w := vis.x - margin * 2.0
	var cursor_x := margin
	var row_y := margin * 0.35
	var portrait := vis.y > vis.x
	if portrait:
		var stat_h := min_btn
		_meters.visible = true
		_meters.autowrap_mode = TextServer.AUTOWRAP_OFF
		_meters.clip_text = true
		_meters.position = Vector2(margin, row_y)
		_meters.size = Vector2(max_w * 0.42, stat_h)
		_energy.autowrap_mode = TextServer.AUTOWRAP_OFF
		_energy.clip_text = true
		_energy.position = Vector2(margin + max_w * 0.44, row_y)
		_energy.size = Vector2(max_w * 0.56, stat_h)
		_energy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_meters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_energy_hit.position = _energy.position
		_energy_hit.size = _energy.size
		row_y += stat_h + gap * 0.35
	var row_h := min_btn
	var rows := 1
	for button in _bottom_buttons:
		button.add_theme_font_size_override("font_size", font_btn)
		var text_w := _text_width_button(button, font_btn)
		var bw := maxf(min_btn, text_w + min_btn * 0.35)
		bw = minf(bw, max_w)
		if cursor_x > margin and cursor_x + bw > vis.x - margin:
			cursor_x = margin
			row_y += row_h + gap
			rows += 1
		button.position = Vector2(cursor_x, row_y)
		button.size = Vector2(bw, min_btn)
		cursor_x += bw + gap
	var buttons_bottom := row_y + row_h
	var lines := 2.4 if cramped else 2.6
	# 矮屏少留几行。竖屏给台词三行，中文按字折行才不会被切掉。
	if vis.y < 900.0:
		lines = 2.0
	elif portrait:
		lines = 4.0
	_dialogue.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	var line_h := float(UiTheme.font().get_height(font_body))
	var dialogue_h := line_h * lines + 4.0
	var stack := cramped or cursor_x > vis.x * 0.62
	if stack or rows > 1:
		_dialogue.position = Vector2(margin, buttons_bottom + gap * 0.6)
		_dialogue.size = Vector2(max_w, dialogue_h)
	else:
		# 宽屏：台词跟在按钮右侧，底栏更矮，少挡门下缝。
		var talk := _talk
		var left := talk.position.x + talk.size.x + gap
		if left > vis.x - margin - 80.0:
			_dialogue.position = Vector2(margin, buttons_bottom + gap * 0.6)
			_dialogue.size = Vector2(max_w, dialogue_h)
		else:
			_dialogue.position = Vector2(left, margin * 0.4)
			_dialogue.size = Vector2(vis.x - margin - left, maxf(min_btn, dialogue_h))
	if portrait:
		# 字体 get_height 偏大，按字号留三行，老周两句都进得来。
		_dialogue.size.y = float(font_body) * 2.15 * 3.0
	var content_bottom := maxf(buttons_bottom, _dialogue.position.y + _dialogue.size.y)
	var bottom_h := content_bottom + margin * 0.4
	if not portrait:
		var limit := vis.y * (0.34 if cramped else 0.28)
		if bottom_h > limit:
			var overflow := bottom_h - limit
			_dialogue.size.y = maxf(float(font_body) * 2.4, _dialogue.size.y - overflow)
			bottom_h = _dialogue.position.y + _dialogue.size.y + margin * 0.4
	_bottom.position = Vector2(0, vis.y - bottom_h)
	_bottom.size = Vector2(vis.x, bottom_h)
	_dialogue.move_to_front()
	for button in _bottom_buttons:
		button.move_to_front()


func _layout_end(vis: Vector2, margin: float, gap: float, min_btn: float, font_body: int) -> void:
	var box_w := minf(maxf(520.0, vis.x * 0.72), vis.x - margin * 2.0)
	var font_btn := int(clampf(float(font_body), 16.0, min_btn * 0.46))
	_retry.add_theme_font_size_override("font_size", font_btn)
	_back.add_theme_font_size_override("font_size", font_btn)
	var retry_w := maxf(min_btn * 2.2, _text_width_button(_retry, font_btn) + min_btn * 0.4)
	var back_w := maxf(min_btn * 2.2, _text_width_button(_back, font_btn) + min_btn * 0.4)
	var side_by_side := retry_w + back_w + gap + margin * 2.0 <= box_w
	var buttons_h := min_btn if side_by_side else min_btn * 2.0 + gap
	var text_h := float(font_body) * 3.2 + margin
	var box_h := text_h + buttons_h + margin * 2.0
	if box_h > vis.y - margin * 2.0:
		box_h = vis.y - margin * 2.0
		text_h = maxf(float(font_body) * 1.8, box_h - buttons_h - margin * 2.0)
	_end_box.size = Vector2(box_w, box_h)
	_end_box.position = Vector2((vis.x - box_w) * 0.5, (vis.y - box_h) * 0.5)
	_end.position = Vector2(margin, margin * 0.6)
	_end.size = Vector2(box_w - margin * 2.0, text_h)
	var by := box_h - margin * 0.6 - (min_btn if side_by_side else buttons_h)
	if side_by_side:
		_retry.position = Vector2(margin, by)
		_retry.size = Vector2(retry_w, min_btn)
		_back.position = Vector2(margin + retry_w + gap, by)
		_back.size = Vector2(back_w, min_btn)
	else:
		var bw := minf(box_w - margin * 2.0, maxf(retry_w, back_w))
		_retry.position = Vector2(margin, by)
		_retry.size = Vector2(bw, min_btn)
		_back.position = Vector2(margin, by + min_btn + gap)
		_back.size = Vector2(bw, min_btn)



func _attach(node: Node, parent: Node) -> void:
	if node.get_parent() == parent:
		return
	node.get_parent().remove_child(node)
	parent.add_child(node)


func _style(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_font_override("font", UiTheme.font())


func _text_width(label: Label, size: int) -> float:
	return UiTheme.font().get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _text_width_button(button: Button, size: int) -> float:
	return UiTheme.font().get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _panel(parent: Node) -> ColorRect:
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.06, 0.88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_font_override("font", UiTheme.font())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Node, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(48, 48)
	parent.add_child(button)
	return button
