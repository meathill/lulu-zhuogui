extends Control

## 选关。短屏用滚动，十关都能点到。

var levels: Array[PackedStringArray] = [
	PackedStringArray(["第 1 关  让人发冷的电梯", "res://scenes/levels/level_01.tscn"]),
	PackedStringArray(["第 2 关  热水器在哭", "res://scenes/levels/level_02.tscn"]),
	PackedStringArray(["第 3 关  路口便利店的香炉", "res://scenes/levels/level_03.tscn"]),
	PackedStringArray(["第 4 关  末班 404", "res://scenes/levels/level_04.tscn"]),
	PackedStringArray(["第 5 关  按住老闵", "res://scenes/levels/level_05.tscn"]),
	PackedStringArray(["第 6 关  即将成型的灵", "res://scenes/levels/level_06.tscn"]),
	PackedStringArray(["第 7 关  步道上的黄影子", "res://scenes/levels/level_07.tscn"]),
	PackedStringArray(["第 8 关  狗牌 · 找林小禾", "res://scenes/levels/level_08.tscn"]),
	PackedStringArray(["第 9 关  空车棚 · 试探的影子", "res://scenes/levels/level_09.tscn"]),
	PackedStringArray(["第 10 关  林小禾卧室 · 梦魇", "res://scenes/levels/level_10.tscn"]),
]

var _title: Label
var _sub: Label
var _scroll: ScrollContainer
var _box: VBoxContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.08, 0.09)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_title = Label.new()
	_title.text = "路路捉鬼"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_sub = Label.new()
	_sub.text = "选一关。灰盒，符贴在环境上。"
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_box)
	for item in levels:
		var button := Button.new()
		button.text = item[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var scene_path := item[1]
		button.pressed.connect(func() -> void: get_tree().change_scene_to_file(scene_path))
		_box.add_child(button)
		_buttons.append(button)
	if not get_viewport().size_changed.is_connected(_relayout):
		get_viewport().size_changed.connect(_relayout)
	resized.connect(_relayout)
	_relayout()
	var shot := _arg_value("--shot-menu")
	if shot != "":
		_capture_menu(shot)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_relayout")


func _relayout() -> void:
	if _scroll == null:
		return
	var vis := get_viewport().get_visible_rect().size
	if vis.x < 2.0 or vis.y < 2.0:
		vis = Vector2(1280, 720)
	var upp := 1.0
	var win := DisplayServer.window_get_size()
	if win.x > 1 and win.y > 1:
		upp = maxf(vis.x / float(win.x), vis.y / float(win.y))
	var margin := clampf(12.0 * upp, 16.0, vis.x * 0.08)
	var min_btn := maxf(48.0, 48.0 * upp)
	var font_title := int(maxf(36.0, 22.0 * upp))
	var font_body := int(maxf(20.0, 15.0 * upp))
	var font_btn := int(clampf(float(font_body), 16.0, min_btn * 0.42))
	_title.add_theme_font_size_override("font_size", font_title)
	_title.add_theme_font_override("font", UiTheme.font())
	_sub.add_theme_font_size_override("font_size", font_body)
	_sub.add_theme_font_override("font", UiTheme.font())
	_title.position = Vector2(margin, margin * 0.4)
	_title.size = Vector2(vis.x - margin * 2.0, float(font_title) + 8.0)
	_sub.position = Vector2(margin, _title.position.y + _title.size.y)
	_sub.size = Vector2(vis.x - margin * 2.0, float(font_body) + 8.0)
	var top := _sub.position.y + _sub.size.y + margin * 0.35
	_scroll.position = Vector2(margin, top)
	_scroll.size = Vector2(vis.x - margin * 2.0, maxf(min_btn, vis.y - top - margin * 0.4))
	_box.add_theme_constant_override("separation", int(maxf(8.0, min_btn * 0.18)))
	_box.custom_minimum_size = Vector2(_scroll.size.x, 0)
	for button in _buttons:
		button.custom_minimum_size = Vector2(_scroll.size.x, min_btn)
		button.add_theme_font_size_override("font_size", font_btn)


func _arg_value(name: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(name + "="):
			return arg.trim_prefix(name + "=")
	return ""


func _capture_menu(path: String) -> void:
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SHOT save %s %s %sx%s" % [path, err, image.get_width(), image.get_height()])
	get_tree().quit(0)
