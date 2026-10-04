# WIP · M1 灰盒

第 1 关「让人发冷的电梯」先跑通手感，不铺官网、后端、Steam、CI。

## 这次做完

- [x] pnpm + turborepo 工作区：`dev:game`、`build:data`、`check:data`
- [x] `apps/game`：Godot 4.3、`gl_compatibility`、逻辑分辨率 1920×1080、`canvas_items` + `expand`
- [x] 单例桩：GameManager、InputManager、SaveManager（本地 JSON；Steam 只写在注释里）、AudioManager
- [x] 灰盒场景：轿厢色块、门下缝 `HotspotSlot`（EMPTY / OCCUPIED）、点击贴符、符力自回、鬼渣从门缝走向中央、符持续掉血
- [x] 发冷乘客到 3 失败，并显示老周一句人话；鬼血归零胜利
- [x] `packages/gamedata` 第 1 关 yaml、导出到 `apps/game/assets/data/`、缺符位 id 的 vitest

## 下一步

- [ ] 侦察问号、门下缝被踢、多缝位点、浓度条、停 -3 的一小大波
- [ ] 发冷改成真乘客进出，而不是鬼摸到中央就 +1
- [ ] 中文字体入库（现在靠系统字体，没有 CJK 字体时字会是方框）
- [ ] 符力维持消耗、符力碎片、老周开场台词
- [ ] 不在 M1：Steam GDExtension、官网、后端、CI
