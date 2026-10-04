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
