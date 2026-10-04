class_name EnergyPool
extends RefCounted

## 关内符力。底盘是持续自回，贴符和五雷从这里扣。

var value: float = 0.0
var max_value: float = 100.0
var regen: float = 12.0


func setup(current: float, maximum: float, regen_rate: float) -> void:
	value = current
	max_value = maximum
	regen = regen_rate


func tick(delta: float) -> void:
	value = minf(max_value, value + regen * delta)


func try_spend(cost: float) -> bool:
	if value < cost:
		return false
	value -= cost
	return true
