extends Control

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


func _ready() -> void:
	theme = UiTheme.make()
	var title := Label.new()
	title.text = "路路捉鬼"
	title.position = Vector2(80, 28)
	title.add_theme_font_size_override("font_size", 48)
	add_child(title)
	var sub := Label.new()
	sub.text = "选一关。灰盒，符贴在环境上。"
	sub.position = Vector2(80, 88)
	add_child(sub)
	var y := 150.0
	for item in levels:
		var button := Button.new()
		button.text = item[0]
		button.position = Vector2(80, y)
		button.size = Vector2(720, 64)
		var scene_path := item[1]
		button.pressed.connect(func() -> void: get_tree().change_scene_to_file(scene_path))
		add_child(button)
		y += 78.0
