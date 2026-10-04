# DEV_NOTE

## Godot 4.3 二进制

- 4.3-stable 的 GitHub Release **没有**单独的 linux headless 包。
- 用标准包 `Godot_v4.3-stable_linux.x86_64`，加 `--headless`。
- `--check-only` 必须配 `--script`，只查单个脚本。整项目先 `--headless --import` 生成 `.godot/`（不入库）。
- 单独 `--check-only --script` 主场景时，Autoload 名字不在作用域里，`level_01.gd` 会报找不到 `GameManager`。用 `--headless` 跑主场景才算数。
- 引擎不要提交。本机校验过的路径是 `/tmp/godot-4.3/Godot_v4.3-stable_linux.x86_64`。

## 数据脚本

- Node >= 24 直接跑 `.ts`，不要 tsc / ts-node。
- 相对导入写上 `.ts` 后缀。`@lulu/shared-types` 的入口也是 `.ts`，不要指望从 `node_modules` 当运行时代码加载（类型导入会被擦掉）。

## 网页导出

- 模板放在 `~/.local/share/godot/export_templates/4.3.stable/`，含 `web_nothreads_release.zip`。模板不入库。
- 预设 `Web` 关闭 `variant/thread_support`。GitHub Pages 没有 COOP/COEP，开线程的包打不开。
- 导出前先建好 `apps/game/build/web/`。产物不进 master，单独放托管分支。
