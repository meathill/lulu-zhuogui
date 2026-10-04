#!/usr/bin/env bash
# 无头跑第 1–10 关各一胜一负。
# --time-scale 只压缩墙钟。打印的 TIME 是玩家秒，和关卡 at 同一把尺子。
# 30 倍时，约 3 分钟玩家时间大约 6 秒墙钟，外加引擎启动。
set -euo pipefail
GODOT="${GODOT:-godot}"
SCALE="${TIME_SCALE:-30}"
cd "$(dirname "$0")/../apps/game"
fail=0
for n in 01 02 03 04 05 06 07 08 09 10; do
  for mode in fail win; do
    if ! timeout 120 "$GODOT" --headless "res://scenes/levels/level_${n}.tscn" -- "--auto-${mode}" "--time-scale=${SCALE}" | tee "/tmp/lulu-${n}-${mode}.log" | grep -q "RESULT ${mode}"; then
      echo "失败 ${n} ${mode}"
      fail=1
    else
      t=$(awk '/^TIME /{print $2}' "/tmp/lulu-${n}-${mode}.log" | tail -1)
      echo "通过 ${n} ${mode} 玩家秒 ${t}"
    fi
  done
done
exit "$fail"
