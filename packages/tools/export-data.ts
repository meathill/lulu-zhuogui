import { mkdirSync, writeFileSync } from "node:fs"
import { resolve } from "node:path"
import { LEVEL_OUTPUT_DIR, loadAllSources } from "./load-level.ts"

mkdirSync(LEVEL_OUTPUT_DIR, { recursive: true })
let failed = false
for (const source of loadAllSources()) {
  if (source.result.issues.length > 0 || source.result.level === null) {
    failed = true
    for (const issue of source.result.issues) {
      console.error(`${source.fileName} ${issue.path}: ${issue.message}`)
    }
    continue
  }
  const output = resolve(LEVEL_OUTPUT_DIR, source.fileName.replace(/\.yaml$/, ".json"))
  writeFileSync(output, `${JSON.stringify(source.raw, null, 2)}\n`, "utf8")
  console.log(`已导出 ${source.result.level.id} -> ${output}`)
}
if (failed) {
  process.exit(1)
}
