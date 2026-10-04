export interface HotspotDefinition {
  id: string
  label: string
}

export interface SpiritDefinition {
  id: string
  maxHp: number
  moveDurationSec: number
  entryHotspotId: string
}

export interface LevelDefinition {
  id: string
  title: string
  regenRate: number
  placeCost: number
  wardDamagePerSecond: number
  failThreshold: number
  initialEnergy: number
  energyMax: number
  hotspots: HotspotDefinition[]
  spirit: SpiritDefinition
}

export interface ValidationIssue {
  path: string
  message: string
}
