---
created: 2026-03-26T04:48:48.902Z
title: Add native about dialog
area: ui
files:
  - App/Features/MenuBar/MenuBarContentView.swift:27
---

## Problem

The menu bar "More" submenu currently exposes settings and quit actions but does not provide a native macOS About entry. The requested behavior is to add an "About" item under that submenu which opens a native about dialog similar to the reference image, so users can quickly see the app icon, product name, version/build, and project information from the menu bar without opening the main window. The dialog also needs to include the project URL `https://github.com/congbo/default-editor-switcher` as a clickable link.

## Solution

Add a localized "About" action to the "More" submenu in `MenuBarContentView` and wire it to the native AppKit about panel API instead of building a custom SwiftUI window. Pass custom about panel options so the panel includes the GitHub project address as clickable content while preserving the standard macOS presentation for icon, app name, and version/build metadata.
