extends Node

## 鼠标、手柄、触屏收成一套指针信号。M1 只接鼠标左键；Tab 预留给符位循环。

signal pointer_pressed(global_pos: Vector2)
signal pointer_dragged(global_pos: Vector2)
signal pointer_released(global_pos: Vector2)
signal slot_cycle_requested(direction: int)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			pointer_pressed.emit(mouse.global_position)
		else:
			pointer_released.emit(mouse.global_position)
		return

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			pointer_dragged.emit(motion.global_position)
		return

	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_TAB:
			var direction: int = -1 if key.shift_pressed else 1
			slot_cycle_requested.emit(direction)
