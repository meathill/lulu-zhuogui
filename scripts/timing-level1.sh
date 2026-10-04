#!/usr/bin/env bash
# 第 1 关节奏断言，单位是玩家秒，不是墙钟。
# --time-scale=30：Engine.time_scale=30，180 玩家秒约 6 墙秒。
# 关卡数据没有被缩短。TIME 行来自 time_sec（波次 at 用的同一时钟）。
set -euo pipefail
GODOT="${GODOT:-godot}"
SCALE="${TIME_SCALE:-30}"
cd "$(dirname "$0")/../apps/game"
scene="res://scenes/levels/level_01.tscn"

echo "挂机（什么都不贴）"
timeout 120 "$GODOT" --headless "$scene" -- --auto-fail "--time-scale=${SCALE}" | tee /tmp/lulu-01-idle.log >/dev/null
idle=$(awk '/^TIME /{print $2}' /tmp/lulu-01-idle.log | tail -1)
python3 - "$idle" << 'PY'
import sys
t = float(sys.argv[1])
if not (t >= 25.0 and t < 240.0):
    raise SystemExit(f"挂机失败时间 {t} 不在 [25, 240) 玩家秒")
print(f"挂机失败于 {t:.2f} 玩家秒")
PY

echo "开局贴门下缝（教程那张符）"
timeout 120 "$GODOT" --headless "$scene" -- --auto-ward "--time-scale=${SCALE}" | tee /tmp/lulu-01-ward.log >/dev/null
if ! grep -q "RESULT hold" /tmp/lulu-01-ward.log; then
  echo "提前贴符没有撑过 60 玩家秒"
  exit 1
fi
if grep -q "RESULT early-fail" /tmp/lulu-01-ward.log; then
  echo "60 玩家秒内就已经判负"
  exit 1
fi
ward=$(awk '/^TIME /{print $2}' /tmp/lulu-01-ward.log | tail -1)
python3 - "$ward" << 'PY'
import sys
t = float(sys.argv[1])
if t < 60.0:
    raise SystemExit(f"贴符后只撑到 {t} 玩家秒")
print(f"贴符后仍在场，记录时间 {t:.2f} 玩家秒")
PY
