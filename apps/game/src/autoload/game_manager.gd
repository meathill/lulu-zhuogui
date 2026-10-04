extends Node

## 总状态机。M1 只在开局和结算时切阶段。

enum Phase { TITLE, DESK, LEVEL_INTRO, LEVEL_COMBAT, LEVEL_RESULT, STORY_INTERLUDE }

var phase: Phase = Phase.TITLE


func set_phase(next: Phase) -> void:
	phase = next
