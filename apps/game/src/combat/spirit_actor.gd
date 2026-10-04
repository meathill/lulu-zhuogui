class_name SpiritActor
extends Node2D

## 一块鬼渣。从门缝走到轿厢中央；血量由外面的符按秒扣。

signal reached_center
signal defeated

var max_hp: float = 90.0
var hp: float = 90.0
var move_duration_sec: float = 6.0
var is_active: bool = false

var _origin: Vector2 = Vector2.ZERO
var _destination: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0


func launch(from: Vector2, to: Vector2, health: float, duration: float) -> void:
	_origin = from
	_destination = to
	max_hp = health
	hp = health
	move_duration_sec = maxf(duration, 0.01)
	_elapsed = 0.0
	is_active = true
	visible = true
	position = from
	_sync_body()


func stop() -> void:
	is_active = false


func apply_damage(amount: float) -> void:
	if not is_active:
		return
	hp = maxf(0.0, hp - amount)
	_sync_body()
	if hp <= 0.0:
		is_active = false
		visible = false
		defeated.emit()


func _process(delta: float) -> void:
	if not is_active:
		return
	_elapsed += delta
	var ratio: float = clampf(_elapsed / move_duration_sec, 0.0, 1.0)
	position = _origin.lerp(_destination, ratio)
	if ratio >= 1.0:
		is_active = false
		reached_center.emit()


func _sync_body() -> void:
	var ratio: float = 1.0
	if max_hp > 0.0:
		ratio = clampf(hp / max_hp, 0.0, 1.0)
	modulate = Color(1, 1, 1, 0.35 + 0.65 * ratio)
