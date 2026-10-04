class_name UiTheme
extends RefCounted

## 灰盒界面共用的中文字体。网页导出不能靠系统字体。

const FONT_PATH := "res://assets/fonts/NotoSansSC-Subset.otf"

static var cached: Font


static func font() -> Font:
	if cached != null:
		return cached
	if ResourceLoader.exists(FONT_PATH):
		cached = load(FONT_PATH)
		return cached
	var fallback := SystemFont.new()
	fallback.font_names = PackedStringArray(["Noto Sans CJK SC", "Noto Sans SC", "WenQuanYi Micro Hei"])
	cached = fallback
	return cached


static func make() -> Theme:
	var theme := Theme.new()
	var face := font()
	theme.default_font = face
	theme.default_font_size = 22
	return theme


static func pixel_ratio() -> float:
	# 网页上这是 devicePixelRatio。关掉高分屏时是 1。
	var ratio := DisplayServer.screen_get_scale()
	if ratio < 0.5 or ratio > 8.0:
		return 1.0
	return ratio


static func css_size() -> Vector2:
	var win := Vector2(DisplayServer.window_get_size())
	var css := win / pixel_ratio()
	if css.x < 2.0 or css.y < 2.0:
		return Vector2(1280, 720)
	return css


static func units_per_css(vis: Vector2) -> float:
	# 逻辑像素 / CSS 像素。1920 宽的画布缩到 390 CSS 宽时，大约是 4.9。
	# 不要用窗口的设备像素去除，否则手机上字会缩成发丝。
	var css := css_size()
	if vis.x < 2.0 or vis.y < 2.0:
		return 1.0
	return maxf(vis.x / css.x, vis.y / css.y)

