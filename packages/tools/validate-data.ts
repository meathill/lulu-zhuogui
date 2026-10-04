import { loadSourceLevel } from "./load-level.ts"

const result = loadSourceLevel()
if (result.issues.length > 0 || result.level === null) {
  for (const issue of result.issues) {
    console.error(`${issue.path}: ${issue.message}`)
  }
  process.exit(1)
}

console.log(`关卡数据校验通过：${result.level.title}`)
