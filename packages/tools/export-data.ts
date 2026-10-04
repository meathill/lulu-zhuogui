import { mkdirSync, writeFileSync } from "node:fs"
import { dirname } from "node:path"
import { LEVEL_OUTPUT_PATH, loadSourceLevel } from "./load-level.ts"

const result = loadSourceLevel()
if (result.issues.length > 0 || result.level === null) {
  for (const issue of result.issues) {
    console.error(`${issue.path}: ${issue.message}`)
  }
  process.exit(1)
}

mkdirSync(dirname(LEVEL_OUTPUT_PATH), { recursive: true })
writeFileSync(LEVEL_OUTPUT_PATH, `${JSON.stringify(result.level, null, 2)}\n`, "utf8")
console.log(`已导出 ${result.level.id} -> ${LEVEL_OUTPUT_PATH}`)
