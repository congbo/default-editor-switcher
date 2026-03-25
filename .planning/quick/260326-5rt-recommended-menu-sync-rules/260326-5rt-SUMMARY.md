---
description: 修正推荐编辑器设置与菜单栏不同步、取消一级菜单补齐逻辑，并更新默认推荐与相关文档
date: 2026-03-26
status: completed
---

# Quick Task 260326-5rt Summary

- Fixed the recommendation store so menu-bar updates are triggered after persistence, which keeps settings and menu state aligned during checkbox and reorder changes.
- Reworked first-level menu composition so only checked, installed, full-support recommended editors appear there; unchecked editors stay in `More`, and the menu no longer backfills to 12 or injects the current editor.
- Updated the default enabled set to include `TextEdit` and `Qoder`, kept at least one checked recommendation, and synchronized the tests, README copy, and Phase 02/03 planning documents to the new behavior.
