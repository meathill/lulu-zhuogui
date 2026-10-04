import { loadAllSources } from "./load-level.ts"

let failed = false
for (const source of loadAllSources()) {
  if (source.result.issues.length > 0 || source.result.level === null) {
    failed = true
    for (const issue of source.result.issues) {
      console.error(`${source.fileName} ${issue.path}: ${issue.message}`)
    }
    continue
  }
  console.log(`关卡数据校验通过：${source.result.level.title}`)
}
if (failed) {
  process.exit(1)
}
