class_name MeterRack
extends RefCounted

## 浓度、惧值、阳气、供品进度。破线返回失败文案。

var rows: Array[Dictionary] = []


func setup(raw: Array) -> void:
	rows.clear()
	for item in raw:
		if not item is Dictionary:
			continue
		var spec := item as Dictionary
		var start := float(spec.get("start", 0))
		rows.append({
			"id": str(spec.get("id", "")),
			"label": str(spec.get("label", "")),
			"value": start,
			"max": float(spec.get("max", 100)),
			"fail_at": float(spec.get("failAt", 100)),
			"mode": str(spec.get("mode", "up")),
			"per_second": float(spec.get("perSecond", 0)),
			"while_attached": str(spec.get("whileAttached", "")),
			"fail_text": str(spec.get("failText", "这单先停。")),
		})


func bump(meter_id: String, amount: float) -> String:
	for row in rows:
		if str(row["id"]) != meter_id:
			continue
		row["value"] = float(row["value"]) + amount
		return _failed(row)
	return ""


func tick(delta: float, attached_ids: PackedStringArray, any_attached: bool) -> String:
	for row in rows:
		var rate := float(row["per_second"])
		if rate == 0.0:
			continue
		var gate := str(row["while_attached"])
		if gate == "any" and not any_attached:
			continue
		if gate != "" and gate != "any" and not attached_ids.has(gate):
			continue
		row["value"] = float(row["value"]) + rate * delta
		var failed := _failed(row)
		if failed != "":
			return failed
	return ""


func lines() -> PackedStringArray:
	var out: PackedStringArray = []
	for row in rows:
		out.append("%s %.0f / %.0f" % [str(row["label"]), float(row["value"]), float(row["max"])])
	return out


func _failed(row: Dictionary) -> String:
	var value := float(row["value"])
	var fail_at := float(row["fail_at"])
	var broken := value >= fail_at if str(row["mode"]) == "up" else value <= fail_at
	if broken:
		return str(row["fail_text"])
	return ""
