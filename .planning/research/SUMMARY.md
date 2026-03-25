# Project Research Summary

**Project:** Default Editor Switcher
**Domain:** macOS developer utility for switching default file editors
**Researched:** 2026-03-25
**Confidence:** MEDIUM-HIGH

## Executive Summary

这是一个很典型的 macOS 原生工具型产品，而不是通用桌面软件。最合理的实现路径是用原生 Swift 技术栈把菜单栏极简交互、文件类型建模和 Launch Services 默认关联更新封装成一个轻量但可靠的系统偏好工具。

研究结果基本支持当前产品方向: 用 `MenuBarExtra` 做高频入口，用主窗口管理语言规则和自定义扩展名，用 `UTType` + 扩展名集合建模目标范围，再通过 Launch Services 更新默认编辑器，并在每次批量写入后做读回验证。最主要的风险不在 UI，而在“编辑器声明能力并不一致”“规则优先级容易让用户误解”和“批量修改必须能恢复”。

## Key Findings

### Recommended Stack

Apple 原生栈最合适。`SwiftUI` 足够承担菜单栏和主窗口，`AppKit`/`NSWorkspace` 负责应用发现和图标，`UniformTypeIdentifiers` 负责把扩展名和语言桶映射到系统内容类型，`Launch Services` 负责真正的默认打开方式修改。MVP 不需要第三方依赖。

**Core technologies:**
- `SwiftUI`: menu bar 和主窗口 UI 骨架
- `AppKit / NSWorkspace`: 枚举可用编辑器、图标和工作区能力
- `UniformTypeIdentifiers`: 归一化文本/源码类型
- `Launch Services`: 读写默认关联
- `Developer ID + notarization`: 官网直装发布

### Expected Features

这个品类的 table stakes 不是“规则足够多”，而是“切换足够快且结果可信”。因此最关键的是菜单栏一键全局切换、编辑器发现、当前状态可见和高级规则窗口。

**Must have (table stakes):**
- 菜单栏一键切换全部文本类默认编辑器
- 编辑器自动发现与排序
- 当前默认状态可见
- 语言规则与自定义扩展名规则
- 结果验证与恢复

**Should have (competitive):**
- 开发者导向语言分组
- 编辑器优先排序
- 恢复上一个快照或系统基线

**Defer (v2+):**
- Shortcuts 自动化
- 多配置档案
- 更复杂的上下文路由规则

### Architecture Approach

推荐采用四层结构: UI 场景层、规则/目录服务层、系统集成层、持久化层。这样菜单栏和设置窗口都只表达意图，真正的优先级计算、写入验证、恢复回滚都在服务层完成。

**Major components:**
1. `EditorCatalog` — 发现并排序编辑器
2. `RuleEngine` — 计算全局、语言、自定义规则的最终生效结果
3. `AssociationWriter` — 执行 Launch Services 更新
4. `SnapshotStore` — 写前保存，失败或恢复时回放

### Critical Pitfalls

1. **编辑器声明不一致** — 先做能力验证，不要只靠内置名单
2. **规则优先级不透明** — 明确展示 `custom > language > global`
3. **批量更新半成功** — 写前快照、写后验证、失败可恢复
4. **分发模型定错** — 从一开始就按官网直装 + Developer ID + notarization 设计

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Association Core
**Rationale:** 先证明系统能力可用，否则 UI 都是空壳
**Delivers:** 类型建模、编辑器发现、Launch Services 读写和验证基础
**Addresses:** editor discovery, content taxonomy
**Avoids:** capability detection pitfall

### Phase 2: Menu Bar Quick Switch
**Rationale:** 先交付主价值，而不是先堆高级配置
**Delivers:** 像 `Default Browser` 一样简单的菜单栏全局切换
**Uses:** `MenuBarExtra`, current-state cache
**Implements:** 高频交互入口

### Phase 3: Language Override Engine
**Rationale:** 用户明确需要“全局切换 + 特定语言例外”
**Delivers:** 语言分组与覆盖优先级模型
**Implements:** rule engine

### Phase 4: Rules Management Window
**Rationale:** 自定义扩展名和规则冲突可视化需要完整窗口
**Delivers:** 主窗口、语言规则编辑、自定义扩展名规则

### Phase 5: Recovery and Trust
**Rationale:** 这个产品必须“可回退”才值得日常使用
**Delivers:** 当前状态视图、快照、恢复与错误反馈

### Phase 6: Release Hardening
**Rationale:** 官网直装是产品定义的一部分，不是收尾细节
**Delivers:** Developer ID、notarization、clean-machine 验证和发布流程

### Phase Ordering Rationale

- 先验证系统写能力，再做 UI，避免做出漂亮但不可靠的壳
- 把菜单栏主价值放在前面，尽快验证产品吸引力
- 把恢复和发布硬化单独拉出来，确保它们不会在功能堆叠中被稀释

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** 具体的 Launch Services 读写/读回验证边界需要 POC
- **Phase 6:** 签名与 notarization 细节需要在真实产物上跑通

Phases with standard patterns (skip research-phase):
- **Phase 2:** 菜单栏和状态展示是标准原生 macOS 工具形态

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | 关键能力都来自 Apple 原生框架，路径清晰 |
| Features | MEDIUM-HIGH | 与用户目标和参考产品边界高度一致 |
| Architecture | MEDIUM-HIGH | 本地工具型架构简单，但系统写入细节仍需 POC |
| Pitfalls | MEDIUM | 部分风险来自真实机器行为，需在实施中验证 |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- Launch Services 对不同文本/源码类型的写入一致性需要在实现阶段做验证矩阵
- 某些编辑器对特定扩展名的声明可能不完整，需要产品内置补偿策略

## Sources

### Primary (HIGH confidence)
- https://developer.apple.com/support/xcode/ — toolchain and Swift versions
- https://developer.apple.com/documentation/swiftui/menubarextra — menu bar app architecture
- https://developer.apple.com/documentation/coreservices/1444955-lssetdefaultrolehandlerforconten?changes=_6&language=objc — system default handler mutation
- https://developer.apple.com/documentation/uniformtypeidentifiers/uttypesourcecode — source-code/text type relationship
- https://developer.apple.com/macos/distribution/ — direct distribution vs App Store constraints
- https://developer.apple.com/developer-id/ — signing and notarization path

### Secondary (MEDIUM confidence)
- https://developer.apple.com/documentation/appkit/nsworkspace/urlsforapplications%28toopen%3A%29-ualk?language=objc — app discovery entry point
- https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts/LSCConcepts.html — Launch Services concepts and roles

### Tertiary (LOW-MEDIUM confidence)
- https://sindresorhus.com/default-browser — analogous product scope and App Store note
- https://sindresorhus.com/velja — adjacent feature boundary to avoid scope drift

---
*Research completed: 2026-03-25*
*Ready for roadmap: yes*
