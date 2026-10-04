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
