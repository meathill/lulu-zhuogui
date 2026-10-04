class_name CutsceneStill
extends CanvasLayer

## 过场：一张静帧加字幕，点一下往下走。不做动画。

signal finished

var _lines: PackedStringArray = PackedStringArray()
var _index: int = 0
var _caption: Label
var _image: TextureRect


func _ready() -> void:
	layer = 20
	visible = false
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.04, 0.05, 1)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	_image = TextureRect.new()
	_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_image)
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.62)
	bar.anchor_left = 0
	bar.anchor_top = 1
	bar.anchor_right = 1
	bar.anchor_bottom = 1
	bar.offset_top = -220
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_caption = Label.new()
	_caption.anchor_left = 0.08
	_caption.anchor_top = 1
	_caption.anchor_right = 0.92
	_caption.anchor_bottom = 1
	_caption.offset_top = -200
	_caption.offset_bottom = -70
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 32)
	_caption.add_theme_font_override("font", UiTheme.font())
	add_child(_caption)
	var next := Button.new()
	next.text = "继续"
	next.anchor_left = 0.78
	next.anchor_top = 1
	next.anchor_right = 0.94
	next.anchor_bottom = 1
	next.offset_top = -64
	next.offset_bottom = -16
	next.pressed.connect(_advance)
	add_child(next)


func play(image_path: String, lines: PackedStringArray) -> void:
	_lines = lines
	_index = 0
	if image_path != "" and ResourceLoader.exists(image_path):
		_image.texture = load(image_path)
	visible = true
	_show_line()


func _show_line() -> void:
	if _index < _lines.size():
		_caption.text = _lines[_index]
	else:
		_caption.text = ""


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		visible = false
		finished.emit()
		return
	_show_line()
