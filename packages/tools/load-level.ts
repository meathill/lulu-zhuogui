import { readdirSync, readFileSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { parse } from "yaml"
import { readLevel, type ReadLevelResult } from "./validate-level.ts"

const here = dirname(fileURLToPath(import.meta.url))

export const LEVEL_SOURCE_DIR = resolve(here, "../gamedata/levels")
export const LEVEL_OUTPUT_DIR = resolve(here, "../../apps/game/assets/data/levels")
export const LEVEL_SOURCE_PATH = resolve(LEVEL_SOURCE_DIR, "01-elevator.yaml")
export const LEVEL_OUTPUT_PATH = resolve(LEVEL_OUTPUT_DIR, "01-elevator.json")

export interface SourceLevel {
  fileName: string
  raw: unknown
  result: ReadLevelResult
}

export function listSourceFiles(): string[] {
  return readdirSync(LEVEL_SOURCE_DIR)
    .filter((name) => name.endsWith(".yaml"))
    .sort()
}

export function loadSourceFile(fileName: string): SourceLevel {
  const raw: unknown = parse(readFileSync(resolve(LEVEL_SOURCE_DIR, fileName), "utf8"))
  return { fileName, raw, result: readLevel(raw) }
}

export function loadAllSources(): SourceLevel[] {
  return listSourceFiles().map((fileName) => loadSourceFile(fileName))
}

export function loadSourceLevel(): ReadLevelResult {
  return loadSourceFile("01-elevator.yaml").result
}
