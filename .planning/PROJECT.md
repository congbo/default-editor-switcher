# Default Editor Switcher

## What This Is

一个面向开发者的 macOS 应用，用来快速切换文件类型的默认打开方式。它借鉴 `default-browser` 的菜单栏极简交互，让用户可以一键把全部文本类文件切换到某个编辑器，同时在主窗口里为常见编程语言和自定义扩展名单独指定默认编辑器。

这个产品优先解决“系统默认打开方式改起来太慢太散”的问题，特别适合需要在 `VS Code`、`Cursor`、`Windsurf`、`Zed`、JetBrains 系列和其他开发工具之间频繁切换的开发者。

## Core Value

开发者可以在几秒内完成默认编辑器切换，而不是在 Finder 和系统设置里逐个文件类型手动修改。

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] 菜单栏中可一键将全部文本类文件切换到选定编辑器，交互保持像 `default-browser` 一样简单直接
- [ ] 自动识别 macOS 中常见开发者编辑器，并在优先展示内置名单的同时列出系统声明可打开这些文件类型的其他应用
- [ ] 主窗口支持为常见语言分类单独设置默认编辑器，包括 `Python`、`Web`、`Go`、`Java`、`Rust`、`Markdown` 等，并让语言规则覆盖全局文本规则
- [ ] 支持用户自定义扩展名规则，将任意扩展名绑定到指定编辑器
- [ ] 展示当前全局与语言级默认关联状态，并支持恢复到之前保存的规则集或系统初始状态
- [ ] 作为可发布产品交付，支持官网直装场景下的签名、notarization、错误提示和基础发布流程

### Out of Scope

- Mac App Store 分发兼容性 — v1 优先官网直装，可接受不兼容 App Store 的能力边界
- 非开发者导向的大而全文件类型管理器 — 核心场景是文本与编程语言，不追求覆盖所有媒体或办公文件类型
- 跨平台支持 — v1 仅面向 macOS

## Context

- 用户的主要痛点是 macOS 修改默认打开方式过于分散、效率低，尤其在不同 IDE 或所谓的 vibe-coding 编辑器之间来回切换时成本很高
- 次要场景是不同语言偏好不同 IDE，例如把全部文本切到一个编辑器，但让 `Python`、`Markdown` 或 `Web` 文件继续走各自更合适的工具
- 核心交互分两层:
  - 菜单栏负责最高频操作: 一键切换“全部文本 -> 某编辑器”
  - 主窗口负责低频但重要的高级配置: 语言级规则、自定义扩展名、状态查看、恢复
- 目标用户是开发者自己，尤其是会在 `VS Code / Cursor / Windsurf / Zed / JetBrains` 等工具间频繁切换的人
- 产品需要保持简单，不做复杂规则引擎或过重的企业级配置体验

## Constraints

- **Platform**: macOS 原生应用 — 功能依赖系统文件关联能力与本机已安装应用发现
- **Distribution**: 官网直装优先 — 需要面向签名与 notarization 设计发布流程，不以 Mac App Store 约束为先
- **UX**: 菜单栏入口必须极简 — 高频操作应在一两步内完成，复杂配置统一放入主窗口
- **Rule Model**: 语言级规则覆盖全局文本规则 — 规则优先级必须一致且可解释
- **App Discovery**: 优先内置常见编辑器名单，同时兼容系统里所有已声明可处理目标类型的应用
- **Audience**: 开发者优先 — 默认分类、命名和信息架构要围绕编程语言与编辑器习惯，而不是普通文档用户

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 菜单栏 + 主窗口双入口 | 高频操作需要极快，低频配置需要更完整的信息密度 | — Pending |
| 先解决“全部文本快速切换”，再支持语言级细分 | 主要痛点明确，语言级规则是次要但重要的增强能力 | — Pending |
| 语言规则覆盖全局文本规则 | 用户已经明确需要“全局默认 + 特定语言例外”的模型 | — Pending |
| 优先面向开发者并内置常见编辑器 | 用户群体明确，能减少首次使用时的扫描与理解成本 | — Pending |
| 发布方式优先官网直装 | 文件关联能力和产品定位都更适合不受 App Store 限制的分发方式 | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-25 after initialization*
