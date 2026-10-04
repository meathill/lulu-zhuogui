class_name HudBar
extends CanvasLayer

## 关卡抬头、符按钮和结算。文字全是中文。

signal tool_selected(tool_id: String)
signal summon_pressed
signal tame_pressed
signal disperse_pressed
signal camera_pressed(camera_id: String)
signal dialogue_pressed
signal restart_pressed
signal menu_pressed

var _energy: Label
var _meters: Label
var _status: Label
var _clock: Label
var _zhou: Label
var _dialogue: Label
var _end: Label
var _end_box: Control


func build(title: String, goal: String, tools: PackedStringArray, multi_camera: bool) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.make()
	add_child(root)
	var top := _panel(root, 0, 0, 1920, 168)
	_label(top, title, 16, 8, 28)
	_clock = _label(top, "时间 00:00  波次 0/0", 1180, 10, 22)
	_clock.size = Vector2(700, 36)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(top, goal, 16, 44, 22)
	_meters = _label(top, "", 16, 78, 20)
	_energy = _label(top, "", 16, 108, 20)
	_status = _label(top, "", 16, 136, 20)
	_zhou = _label(top, "", 980, 108, 20)
	_zhou.size = Vector2(900, 52)
	var bottom := _panel(root, 0, 900, 1920, 180)
	var x := 16.0
	for tool_id in tools:
		if tool_id == "summon":
			var summon := _button(bottom, "召唤阴差", x, 24)
			summon.pressed.connect(func() -> void: summon_pressed.emit())
		elif tool_id == "tame":
			var tame := _button(bottom, "收服", x, 24)
			tame.pressed.connect(func() -> void: tame_pressed.emit())
		elif tool_id == "disperse":
			var disperse := _button(bottom, "驱散", x, 24)
			disperse.pressed.connect(func() -> void: disperse_pressed.emit())
		else:
			var captured := tool_id
			var button := _button(bottom, _tool_name(captured), x, 24)
			button.pressed.connect(func() -> void: tool_selected.emit(captured))
		x += 150.0
	if multi_camera:
		var cam_a := _button(bottom, "机位A", x, 24)
		cam_a.pressed.connect(func() -> void: camera_pressed.emit("A"))
		x += 150.0
		var cam_b := _button(bottom, "机位B", x, 24)
		cam_b.pressed.connect(func() -> void: camera_pressed.emit("B"))
	_dialogue = _label(bottom, "", 16, 100, 22)
	_dialogue.size = Vector2(1200, 36)
	var talk := _button(bottom, "下一句", 1240, 92)
	talk.pressed.connect(func() -> void: dialogue_pressed.emit())
	_end_box = _panel(root, 460, 360, 1000, 280)
	_end_box.visible = false
	_end = _label(_end_box, "", 24, 24, 28)
	_end.size = Vector2(940, 140)
	var retry := _button(_end_box, "本关重开", 40, 180)
	retry.pressed.connect(func() -> void: restart_pressed.emit())
	var back := _button(_end_box, "回选关", 240, 180)
	back.pressed.connect(func() -> void: menu_pressed.emit())


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


func show_end(text: String) -> void:
	_end.text = text
	_end_box.visible = true


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


func _panel(parent: Node, x: float, y: float, w: float, h: float) -> ColorRect:
	var panel := ColorRect.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(w, h)
	panel.color = Color(0.05, 0.05, 0.06, 0.88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _label(parent: Node, text: String, x: float, y: float, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(x, y)
	label.size = Vector2(1700, 36)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_font_override("font", UiTheme.font())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, x: float, y: float) -> Button:
	var button := Button.new()
	button.text = text
	button.position = Vector2(x, y)
	button.size = Vector2(136, 48)
	parent.add_child(button)
	return button
