class_name DrawTalisman
extends CanvasLayer

## 第 1 关镇守画符：先记住点序，再连线。记忆大考验那套。

signal completed
signal cancelled

var _root: Control
var _dim: ColorRect
var _paper: ColorRect
var _title: Label
var _hint: Label
var _cancel: Button
var _ink: Control
var _dots: Array[Control] = []
var _order: PackedInt32Array = PackedInt32Array()
var _next_idx: int = 0
var _dragging: bool = false
var _from_dot: int = -1
var _preview_to: Vector2 = Vector2.ZERO
var _links: Array[PackedInt32Array] = []
var _shake_t: float = 0.0
var _phase: String = "idle"
var _shot_mode: String = ""
var _opened: bool = false
var _paper_base := Vector2.ZERO

# 符纸上的相对坐标（0–1）。五笔，够给教程用。
const PATTERN: Array[Vector2] = [
	Vector2(0.22, 0.22),
	Vector2(0.78, 0.22),
	Vector2(0.50, 0.48),
	Vector2(0.28, 0.78),
	Vector2(0.72, 0.78),
]

const MEMORIZE_SEC := 1.5
const HIT_CSS := 56.0
const DOT_CSS := 40.0


func _ready() -> void:
	layer = 24
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _opened


func open_for_shot(mode: String) -> void:
	_shot_mode = mode
	open()


func open() -> void:
	if _opened:
		return
	_opened = true
	visible = true
	_phase = "memorize"
	_next_idx = 0
	_dragging = false
	_from_dot = -1
	_links.clear()
	_shake_t = 0.0
	_build()
	_relayout()
	if not get_viewport().size_changed.is_connected(_relayout):
		get_viewport().size_changed.connect(_relayout)
	set_process(true)
	set_process_input(true)
	if _shot_mode == "memory":
		# 截图时停在记忆拍，不自动进连线。
		return
	if _shot_mode == "connect":
		_enter_connect()
		return
	await get_tree().create_timer(MEMORIZE_SEC).timeout
	if not _opened or _phase != "memorize":
		return
	_enter_connect()


func close() -> void:
	_opened = false
	_phase = "idle"
	_shot_mode = ""
	visible = false
	set_process(false)
	set_process_input(false)
	if _root != null:
		_root.queue_free()
		_root = null
	_dots.clear()


func _enter_connect() -> void:
	_phase = "connect"
	_hint.text = "老周：按刚才的顺序，一笔连完。连错了没事，再来。"
	_ink.queue_redraw()


func _build() -> void:
	if _root != null:
		_root.queue_free()
	_dots.clear()
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = UiTheme.make()
	add_child(_root)
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.02, 0.03, 0.72)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim)
	_paper = ColorRect.new()
	_paper.color = Color(0.86, 0.78, 0.58, 1.0)
	_paper.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_paper)
	_title = Label.new()
	_title.text = "画镇守符"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", UiTheme.font())
	_title.add_theme_color_override("font_color", Color(0.18, 0.10, 0.06))
	_paper.add_child(_title)
	_hint = Label.new()
	_hint.text = "老周：先记住这几笔，再照着连。"
	_hint.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_override("font", UiTheme.font())
	_hint.add_theme_color_override("font_color", Color(0.22, 0.14, 0.08))
	_paper.add_child(_hint)
	_ink = Control.new()
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.draw.connect(_draw_ink)
	_paper.add_child(_ink)
	for i in PATTERN.size():
		var dot := ColorRect.new()
		dot.color = Color(0.12, 0.08, 0.05, 1.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_paper.add_child(dot)
		_dots.append(dot)
		var num := Label.new()
		num.name = "Num"
		num.text = str(i + 1)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.add_theme_font_override("font", UiTheme.font())
		num.add_theme_color_override("font_color", Color(0.92, 0.86, 0.70))
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(num)
	_cancel = Button.new()
	_cancel.text = "取消"
	_cancel.pressed.connect(_on_cancel)
	_paper.add_child(_cancel)


func _relayout() -> void:
	if _root == null:
		return
	var vis := get_viewport().get_visible_rect().size
	if vis.x < 2.0 or vis.y < 2.0:
		vis = Vector2(390, 844)
	var upc := UiTheme.units_per_css(vis)
	_root.position = Vector2.ZERO
	_root.size = vis
	_dim.position = Vector2.ZERO
	_dim.size = vis
	var margin := 16.0 * upc
	var paper_w := minf(vis.x - margin * 2.0, 360.0 * upc)
	var paper_h := minf(vis.y - margin * 2.0, 520.0 * upc)
	if vis.y > vis.x:
		paper_w = vis.x - margin * 2.0
		paper_h = minf(vis.y * 0.72, 560.0 * upc)
	_paper.size = Vector2(paper_w, paper_h)
	_paper_base = Vector2((vis.x - paper_w) * 0.5, (vis.y - paper_h) * 0.42)
	_paper.position = _paper_base
	var font_title := int(round(26.0 * upc))
	var font_body := int(round(20.0 * upc))
	var font_dot := int(round(18.0 * upc))
	_title.add_theme_font_size_override("font_size", font_title)
	_hint.add_theme_font_size_override("font_size", font_body)
	_title.position = Vector2(margin * 0.6, margin * 0.5)
	_title.size = Vector2(paper_w - margin * 1.2, float(font_title) * 1.4)
	_hint.position = Vector2(margin * 0.6, _title.position.y + _title.size.y)
	_hint.size = Vector2(paper_w - margin * 1.2, float(font_body) * 2.6)
	var pad_top := _hint.position.y + _hint.size.y + margin * 0.4
	var btn_h := 48.0 * upc
	_cancel.add_theme_font_size_override("font_size", font_body)
	_cancel.add_theme_font_override("font", UiTheme.font())
	var cancel_w := maxf(120.0 * upc, UiTheme.font().get_string_size("取消", HORIZONTAL_ALIGNMENT_LEFT, -1, font_body).x + 36.0 * upc)
	_cancel.size = Vector2(cancel_w, btn_h)
	_cancel.position = Vector2((paper_w - cancel_w) * 0.5, paper_h - margin * 0.6 - btn_h)
	var field := Rect2(margin, pad_top, paper_w - margin * 2.0, _cancel.position.y - pad_top - margin * 0.4)
	_ink.position = field.position
	_ink.size = field.size
	var hit := HIT_CSS * upc
	var dot_s := DOT_CSS * upc
	for i in _dots.size():
		var rel: Vector2 = PATTERN[i]
		var center := field.position + Vector2(field.size.x * rel.x, field.size.y * rel.y)
		var d := _dots[i]
		d.size = Vector2(dot_s, dot_s)
		d.position = center - d.size * 0.5
		# 点击半径用更大的隐形区：画线时用几何判定，不靠控件。
		d.set_meta("center", center)
		d.set_meta("hit", hit * 0.5)
		var num := d.get_node_or_null("Num") as Label
		if num != null:
			num.add_theme_font_size_override("font_size", font_dot)
			num.position = Vector2.ZERO
			num.size = d.size
	_ink.queue_redraw()


func _process(delta: float) -> void:
	if _paper != null:
		if _shake_t > 0.0:
			_shake_t = maxf(0.0, _shake_t - delta)
			var amp := 3.0 * UiTheme.units_per_css(get_viewport().get_visible_rect().size)
			_paper.position = _paper_base + Vector2(sin(Time.get_ticks_msec() * 0.06) * amp * (_shake_t / 0.35), 0)
			_ink.queue_redraw()
		elif _paper.position != _paper_base:
			_paper.position = _paper_base


func _input(event: InputEvent) -> void:
	if not _opened or _phase != "connect":
		if _opened:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			var hit := _hit_dot(mouse.position)
			if hit >= 0 and hit == _next_idx:
				_dragging = true
				_from_dot = hit
				_preview_to = mouse.position
			elif hit >= 0:
				_fail_link()
		else:
			if _dragging:
				_finish_drag(mouse.position)
			_dragging = false
			_from_dot = -1
			_ink.queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_preview_to = motion.position
		var hit := _hit_dot(motion.position)
		if hit >= 0 and hit == _next_idx + 1 and hit != _from_dot:
			_commit_link(_from_dot, hit)
			_from_dot = hit
			if _next_idx >= PATTERN.size() - 1:
				_dragging = false
				_succeed()
		elif hit >= 0 and hit != _from_dot and hit != _next_idx + 1:
			_fail_link()
			_dragging = false
			_from_dot = -1
		_ink.queue_redraw()
		get_viewport().set_input_as_handled()


func _finish_drag(pos: Vector2) -> void:
	var hit := _hit_dot(pos)
	if hit >= 0 and hit == _next_idx + 1 and _from_dot == _next_idx:
		_commit_link(_from_dot, hit)
		if _next_idx >= PATTERN.size() - 1:
			_succeed()
	elif hit >= 0 and hit != _from_dot:
		_fail_link()


func _commit_link(a: int, b: int) -> void:
	var link := PackedInt32Array([a, b])
	_links.append(link)
	_next_idx = b
	_ink.queue_redraw()


func _fail_link() -> void:
	_shake_t = 0.35
	_dragging = false
	_from_dot = -1
	_ink.queue_redraw()


func _succeed() -> void:
	_phase = "done"
	close()
	completed.emit()


func _on_cancel() -> void:
	close()
	cancelled.emit()


func _hit_dot(screen_pos: Vector2) -> int:
	# screen_pos 是视口坐标；点中心存的是纸面局部（相对 _paper）。
	var local := screen_pos - _paper.global_position
	var best := -1
	var best_d := 1e9
	for i in _dots.size():
		var center: Vector2 = _dots[i].get_meta("center")
		var radius: float = float(_dots[i].get_meta("hit"))
		var d := local.distance_to(center)
		if d <= radius and d < best_d:
			best_d = d
			best = i
	return best


func _dot_center_local(i: int) -> Vector2:
	var center: Vector2 = _dots[i].get_meta("center")
	return center - _ink.position


func _draw_ink() -> void:
	if _ink == null:
		return
	var upc := UiTheme.units_per_css(get_viewport().get_visible_rect().size)
	var stroke_w := maxf(4.0, 5.0 * upc)
	# 记忆拍：按顺序画出示范线。
	if _phase == "memorize":
		for i in range(PATTERN.size() - 1):
			var a := _dot_center_local(i)
			var b := _dot_center_local(i + 1)
			var t := float(i) / float(PATTERN.size() - 1)
			var col := Color(0.55, 0.12, 0.08, 0.85).lerp(Color(0.75, 0.28, 0.12, 0.95), t)
			_ink.draw_line(a, b, col, stroke_w, true)
		return
	for link in _links:
		var a := _dot_center_local(int(link[0]))
		var b := _dot_center_local(int(link[1]))
		_ink.draw_line(a, b, Color(0.18, 0.08, 0.05, 1.0), stroke_w, true)
	if _dragging and _from_dot >= 0:
		var a2 := _dot_center_local(_from_dot)
		var b2 := _preview_to - _paper.global_position - _ink.position
		_ink.draw_line(a2, b2, Color(0.35, 0.16, 0.08, 0.7), stroke_w * 0.85, true)
