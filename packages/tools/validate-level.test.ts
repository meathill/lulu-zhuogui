import { readdirSync, readFileSync } from "node:fs"
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
    expect(result.level?.hotspots.map((hotspot) => hotspot.id)).toEqual([
      "door-bottom-seam",
      "door-seam",
      "floor-panel",
      "center",
    ])
  })

  it("十关都能过校验，且守住符位规则", () => {
    const names = readdirSync(resolve(here, "../gamedata/levels")).filter((name) => name.endsWith(".yaml")).sort()
    expect(names).toHaveLength(10)
    const multi: string[] = []
    for (const name of names) {
      const raw = parse(readFileSync(resolve(here, "../gamedata/levels", name), "utf8")) as {
        id: string
        cameraMode: string
        tools: string[]
        winKind: string
        waves: { actors: { kind: string }[] }[]
        hotspots: { role?: string; accepts?: string[] }[]
      }
      const result = readLevel(raw)
      expect(result.issues, name).toEqual([])
      expect(result.level?.id).toBe(raw.id)
      expect(raw.tools).not.toContain("安神")
      expect(raw.tools).not.toContain("anshen")
      if (raw.cameraMode === "multi") {
        multi.push(raw.id)
      }
      for (const hotspot of raw.hotspots) {
        if (hotspot.accepts?.includes("lightning")) {
          expect(hotspot.role).toBe("ground")
        }
        if (hotspot.role === "body") {
          expect(hotspot.accepts ?? []).toEqual(["reveal"])
        }
      }
    }
    expect(multi).toEqual(["level-05"])
    const level8 = parse(readFileSync(resolve(here, "../gamedata/levels/08-xiahe.yaml"), "utf8")) as {
      waves: { actors: { kind: string }[] }[]
    }
    const kinds = level8.waves.flatMap((wave) => wave.actors.map((actor) => actor.kind))
    expect(kinds).not.toContain("dog")
    const level9 = parse(readFileSync(resolve(here, "../gamedata/levels/09-carport.yaml"), "utf8")) as {
      tools: string[]
    }
    expect(level9.tools).toEqual(["ward", "tear"])
    const level10 = parse(readFileSync(resolve(here, "../gamedata/levels/10-bedroom.yaml"), "utf8")) as {
      winKind: string
    }
    expect(level10.winKind).toBe("boss")
  })
})
