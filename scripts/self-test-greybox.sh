#!/usr/bin/env bash
# 无头跑第 1–10 关各一胜一负。Godot 4.3 二进制由环境变量 GODOT 指定。
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/../apps/game"
fail=0
for n in 01 02 03 04 05 06 07 08 09 10; do
  for mode in fail win; do
    if ! timeout 25 "$GODOT" --headless "res://scenes/levels/level_${n}.tscn" -- "--auto-${mode}" | tee "/tmp/lulu-${n}-${mode}.log" | grep -q "RESULT ${mode}"; then
      echo "失败 ${n} ${mode}"
      fail=1
    else
      echo "通过 ${n} ${mode}"
    fi
  done
done
exit "$fail"
