#!/usr/bin/env bash
# 第 1 关逐步教学。停表期间 time_sec 保持 0，点完才走威胁时钟。
# --time-scale 只压缩墙钟。COACH 行里的数字是玩家秒。
set -euo pipefail
GODOT="${GODOT:-godot}"
SCALE="${TIME_SCALE:-30}"
cd "$(dirname "$0")/../apps/game"
scene="res://scenes/levels/level_01.tscn"
timeout 120 "$GODOT" --headless "$scene" -- --auto-coach "--time-scale=${SCALE}" | tee /tmp/lulu-01-coach.log >/dev/null
python3 - /tmp/lulu-01-coach.log << 'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
rows = []
for line in text.splitlines():
    matched = re.match(r"COACH (\S+) ([0-9.]+)(?: (.*))?$", line)
    if matched and matched.group(1) not in {"done", "fail"}:
        rows.append((matched.group(1), float(matched.group(2)), matched.group(3) or ""))
names = [name for name, _, _ in rows]
expect = ["look", "place", "regen", "blocked", "replace", "second", "tear", "wave"]
if names != expect:
    raise SystemExit(f"拍子顺序不对：{names}")
by = {name: (t, spoken) for name, t, spoken in rows}
if by["place"][0] != 0.0 or by["regen"][0] != 0.0:
    raise SystemExit(f"停表失败，贴符时时钟已走：place={by['place'][0]} regen={by['regen'][0]}")
if not (15.0 <= by["blocked"][0] <= 20.0):
    raise SystemExit(f"第一只细祟出现在 {by['blocked'][0]} 秒，不在 15–20")
if not (30.0 <= by["replace"][0] <= 45.0):
    raise SystemExit(f"踢符在 {by['replace'][0]} 秒")
if abs(by["second"][0] - by["replace"][0]) > 0.2:
    raise SystemExit("补符时时钟还在走")
if abs(by["tear"][0] - by["second"][0]) > 0.2:
    raise SystemExit("第二条缝还没贴上，时钟就走了")
if not (175.0 <= by["wave"][0] <= 190.0):
    raise SystemExit(f"一大波在 {by['wave'][0]} 秒")
for _, _, spoken in rows:
    if "没有" in spoken:
        raise SystemExit(spoken)
if "COACH done" not in text or "RESULT win" not in text:
    raise SystemExit("教学局没有打完")
time_match = re.findall(r"^TIME ([0-9.]+)$", text, re.M)
if not time_match or not (180.0 <= float(time_match[-1]) < 240.0):
    raise SystemExit(f"结算时间异常：{time_match}")
print("教学拍子通过，结算玩家秒", time_match[-1])
PY
