import type {
  HotspotDefinition,
  LevelDefinition,
  SpiritDefinition,
  ValidationIssue,
} from "../../shared-types/src/level.ts"

export interface ReadLevelResult {
  issues: ValidationIssue[]
  level: LevelDefinition | null
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

function pushIssue(issues: ValidationIssue[], path: string, message: string): void {
  issues.push({ path, message })
}

function readString(value: unknown, path: string, issues: ValidationIssue[]): string | null {
  if (typeof value !== "string" || value.trim() === "") {
    pushIssue(issues, path, "必须是非空字符串")
    return null
  }
  return value
}

function readPositiveNumber(value: unknown, path: string, issues: ValidationIssue[]): number | null {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    pushIssue(issues, path, "必须是大于 0 的数字")
    return null
  }
  return value
}

function readNonNegativeNumber(value: unknown, path: string, issues: ValidationIssue[]): number | null {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    pushIssue(issues, path, "必须是大于等于 0 的数字")
    return null
  }
  return value
}

function readPositiveInt(value: unknown, path: string, issues: ValidationIssue[]): number | null {
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    pushIssue(issues, path, "必须是大于 0 的整数")
    return null
  }
  return value
}

function readHotspots(value: unknown, issues: ValidationIssue[]): HotspotDefinition[] | null {
  if (!Array.isArray(value) || value.length === 0) {
    pushIssue(issues, "hotspots", "至少要有一个符位")
    return null
  }
  const hotspots: HotspotDefinition[] = []
  const seen = new Set<string>()
  let valid = true
  for (let index = 0; index < value.length; index += 1) {
    const item: unknown = value[index]
    const path = `hotspots[${index}]`
    if (!isRecord(item)) {
      pushIssue(issues, path, "符位必须是对象")
      valid = false
      continue
    }
    const id = readString(item.id, `${path}.id`, issues)
    const label = readString(item.label, `${path}.label`, issues)
    if (id === null || label === null) {
      valid = false
      continue
    }
    if (seen.has(id)) {
      pushIssue(issues, `${path}.id`, `符位 id 重复：${id}`)
      valid = false
      continue
    }
    seen.add(id)
    hotspots.push({ id, label })
  }
  if (!valid) {
    return null
  }
  return hotspots
}

function readSpirit(value: unknown, issues: ValidationIssue[]): SpiritDefinition | null {
  if (!isRecord(value)) {
    pushIssue(issues, "spirit", "鬼祟必须是对象")
    return null
  }
  const id = readString(value.id, "spirit.id", issues)
  const maxHp = readPositiveNumber(value.maxHp, "spirit.maxHp", issues)
  const moveDurationSec = readPositiveNumber(value.moveDurationSec, "spirit.moveDurationSec", issues)
  const entryHotspotId = readString(value.entryHotspotId, "spirit.entryHotspotId", issues)
  if (id === null || maxHp === null || moveDurationSec === null || entryHotspotId === null) {
    return null
  }
  return { id, maxHp, moveDurationSec, entryHotspotId }
}


const TOOL_IDS = new Set(["ward", "lightning", "reveal", "redirect", "hold", "tear", "summon", "tame", "disperse"])
const ROLES = new Set(["env", "ground", "body", "backpack"])

function readStringList(value: unknown, path: string, issues: ValidationIssue[]): string[] | null {
  if (!Array.isArray(value) || value.length === 0) {
    pushIssue(issues, path, "必须是非空字符串数组")
    return null
  }
  const list: string[] = []
  for (let index = 0; index < value.length; index += 1) {
    const item = readString(value[index], `${path}[${index}]`, issues)
    if (item === null) {
      return null
    }
    list.push(item)
  }
  return list
}

function validateBoard(raw: Record<string, unknown>, hotspotIds: Set<string>, issues: ValidationIssue[]): void {
  const cameraMode = raw.cameraMode
  if (cameraMode !== undefined && cameraMode !== "single" && cameraMode !== "multi") {
    pushIssue(issues, "cameraMode", "只能是 single 或 multi")
  }
  const winKind = raw.winKind
  if (winKind !== undefined && !["clear", "summon", "form-send", "backpack", "boss"].includes(String(winKind))) {
    pushIssue(issues, "winKind", "胜负类型不认识")
  }
  if (Array.isArray(raw.tools)) {
    for (const tool of raw.tools) {
      if (tool === "anshen" || tool === "安神") {
        pushIssue(issues, "tools", "没有安神这张符")
      } else if (typeof tool !== "string" || !TOOL_IDS.has(tool)) {
        pushIssue(issues, "tools", `不认识的符：${String(tool)}`)
      }
    }
  }
  if (Array.isArray(raw.hotspots)) {
    raw.hotspots.forEach((item, index) => {
      if (!isRecord(item)) {
        return
      }
      const role = item.role ?? "env"
      if (typeof role !== "string" || !ROLES.has(role)) {
        pushIssue(issues, `hotspots[${index}].role`, "位点类型不认识")
      }
      const accepts = Array.isArray(item.accepts) ? item.accepts.map(String) : []
      if (accepts.includes("lightning") && role !== "ground") {
        pushIssue(issues, `hotspots[${index}]`, "五雷只能扔在地面")
      }
      if (accepts.includes("reveal") && role !== "body") {
        pushIssue(issues, `hotspots[${index}]`, "显形只能贴在被附身的人身上")
      }
      if (role === "body" && accepts.some((tool) => tool !== "reveal" && tool !== "tear")) {
        pushIssue(issues, `hotspots[${index}]`, "活人身上只能贴显形")
      }
      for (const target of Array.isArray(item.redirectTo) ? item.redirectTo : []) {
        if (!hotspotIds.has(String(target))) {
          pushIssue(issues, `hotspots[${index}].redirectTo`, `找不到符位 ${String(target)}`)
        }
      }
    })
  }
  if (!Array.isArray(raw.waves)) {
    return
  }
  raw.waves.forEach((wave, waveIndex) => {
    if (!isRecord(wave) || !Array.isArray(wave.actors)) {
      pushIssue(issues, `waves[${waveIndex}]`, "波次要有 actors")
      return
    }
    wave.actors.forEach((actor, actorIndex) => {
      const path = `waves[${waveIndex}].actors[${actorIndex}]`
      if (!isRecord(actor)) {
        pushIssue(issues, path, "敌人必须是对象")
        return
      }
      readString(actor.id, `${path}.id`, issues)
      readString(actor.kind, `${path}.kind`, issues)
      const route = readStringList(actor.path, `${path}.path`, issues)
      if (route) {
        for (const hop of route) {
          if (!hotspotIds.has(hop)) {
            pushIssue(issues, `${path}.path`, `找不到符位 ${hop}`)
          }
        }
      }
    })
  })
}

export function readLevel(raw: unknown): ReadLevelResult {
  const issues: ValidationIssue[] = []
  if (!isRecord(raw)) {
    pushIssue(issues, "level", "关卡必须是对象")
    return { issues, level: null }
  }

  const id = readString(raw.id, "id", issues)
  const title = readString(raw.title, "title", issues)
  const regenRate = readPositiveNumber(raw.regenRate, "regenRate", issues)
  const placeCost = readNonNegativeNumber(raw.placeCost, "placeCost", issues)
  const wardDamagePerSecond = readPositiveNumber(raw.wardDamagePerSecond, "wardDamagePerSecond", issues)
  const failThreshold = readPositiveInt(raw.failThreshold, "failThreshold", issues)
  const initialEnergy = readNonNegativeNumber(raw.initialEnergy, "initialEnergy", issues)
  const energyMax = readPositiveNumber(raw.energyMax, "energyMax", issues)
  const hotspots = readHotspots(raw.hotspots, issues)
  const spirit = readSpirit(raw.spirit, issues)

  if (initialEnergy !== null && energyMax !== null && initialEnergy > energyMax) {
    pushIssue(issues, "initialEnergy", "初始符力不能超过上限")
  }
  if (spirit && hotspots && !hotspots.some((hotspot) => hotspot.id === spirit.entryHotspotId)) {
    pushIssue(issues, "spirit.entryHotspotId", `找不到符位 ${spirit.entryHotspotId}`)
  }

  if (hotspots) {
    validateBoard(raw, new Set(hotspots.map((hotspot) => hotspot.id)), issues)
  }

  if (
    issues.length > 0 ||
    id === null ||
    title === null ||
    regenRate === null ||
    placeCost === null ||
    wardDamagePerSecond === null ||
    failThreshold === null ||
    initialEnergy === null ||
    energyMax === null ||
    hotspots === null ||
    spirit === null
  ) {
    return { issues, level: null }
  }

  return {
    issues,
    level: {
      id,
      title,
      regenRate,
      placeCost,
      wardDamagePerSecond,
      failThreshold,
      initialEnergy,
      energyMax,
      hotspots,
      spirit,
    },
  }
}
