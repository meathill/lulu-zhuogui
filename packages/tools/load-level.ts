import { readFileSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { parse } from "yaml"
import { readLevel, type ReadLevelResult } from "./validate-level.ts"

const here = dirname(fileURLToPath(import.meta.url))

export const LEVEL_SOURCE_PATH = resolve(here, "../gamedata/levels/01-elevator.yaml")
export const LEVEL_OUTPUT_PATH = resolve(here, "../../apps/game/assets/data/levels/01-elevator.json")

export function loadSourceLevel(): ReadLevelResult {
  const raw: unknown = parse(readFileSync(LEVEL_SOURCE_PATH, "utf8"))
  return readLevel(raw)
}
