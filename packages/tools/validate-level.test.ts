import { readFileSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { parse } from "yaml"
import { describe, expect, it } from "vitest"
import { readLevel } from "./validate-level.ts"

const here = dirname(fileURLToPath(import.meta.url))

describe("关卡校验", () => {
  it("入口符位 id 不存在时失败", () => {
    const result = readLevel({
      id: "level-01",
      title: "让人发冷的电梯",
      regenRate: 12,
      placeCost: 35,
      wardDamagePerSecond: 30,
      failThreshold: 3,
      initialEnergy: 40,
      energyMax: 100,
      hotspots: [{ id: "door-bottom-seam", label: "门下缝" }],
      spirit: {
        id: "thick-slag",
        maxHp: 90,
        moveDurationSec: 6,
        entryHotspotId: "cable-shaft",
      },
    })
    expect(result.level).toBeNull()
    expect(result.issues.some((issue) => issue.path === "spirit.entryHotspotId")).toBe(true)
  })

  it("第1关源文件可以通过校验", () => {
    const source = readFileSync(resolve(here, "../gamedata/levels/01-elevator.yaml"), "utf8")
    const result = readLevel(parse(source))
    expect(result.issues).toEqual([])
    expect(result.level?.id).toBe("level-01")
    expect(result.level?.hotspots.map((hotspot) => hotspot.id)).toEqual(["door-bottom-seam"])
  })
})
