---
phase: 02
slug: menu-bar-global-switch
status: approved
shadcn_initialized: false
preset: none
created: 2026-03-25
reviewed_at: 2026-03-25T14:30:00Z
---

# Phase 02 — UI Design Contract

> Visual and interaction contract for the menu bar quick-switch phase. This phase stays native to macOS menu patterns instead of inventing a custom floating panel.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | none — native SwiftUI plus AppKit bridges only |
| Icon library | SF Symbols |
| Font | SF Pro Text / SF Pro Display |

## Visual Hierarchy

| Area | Contract |
|------|----------|
| Primary focal point | The first visible block in the menu is the current global editor summary, including the effective editor name and a one-line state note. |
| Secondary focal point | The primary app action list appears immediately below the summary and stays fully text labeled, with checked recommended editors first and all other eligible apps deferred to `More`. |
| Tertiary content | System-eligible but non-recommended or partially supported editors appear in a visually separated lower section. |
| Persistent footer | A final footer row labeled `Open Rules Window...` remains pinned as the last action after a separator. |
| Accessibility rule | No icon-only interactive control is allowed in this phase; every action row includes a text label, and any status glyph is supplementary only. |
| Menu density | The top-level menu surfaces the checked recommended editors that are actually installed and fully supported on this Mac, without backfilling missing slots. |

## Interaction Contract

| Element | Contract |
|---------|----------|
| Menu order | Current state summary -> Recommended Editors section -> Other Eligible Editors section -> separator -> `Open Rules Window...` |
| Current editor affordance | The active editor is marked inline inside the editor list with a checkmark and `Current` suffix. |
| Global recommendation order | The curated default order keeps `Kiro` immediately after `Cursor`, inserts `Qoder` after `Zed`, includes `TextEdit` in the default first-level seed, and preserves that order before unchecked apps move to `More`. |
| Other eligible ordering | Outside the curated recommendation block, global-menu candidates sort by the number of supported developer-text filename extensions, highest first. |
| Partial or unverified options | These rows remain visible but non-primary, grouped under an `Other Eligible Editors` or `Needs Verification` heading with a capability note. |
| Post-switch behavior | After a switch attempt, refresh the current-state summary and checked row state, but do not show success, failure, or extension-preview messaging in the dropdown. |
| Window entry point | `Open Rules Window...` opens a lightweight placeholder window in this phase; it does not expose editing yet. |

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Checkmark-to-label gap, inline badge padding |
| sm | 8px | Compact row content spacing |
| md | 16px | Default section padding inside custom summary rows |
| lg | 24px | Gap between summary block and editor sections when using window-style content |
| xl | 32px | Minimum content width breathing room in the rules-window placeholder |
| 2xl | 48px | Empty-state vertical spacing in the rules-window placeholder |
| 3xl | 64px | Not used in the menu; reserved for later main-window screens |

Exceptions: none

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 13px | 400 | 1.38 |
| Label | 11px | 600 | 1.27 |
| Heading | 15px | 600 | 1.30 |
| Display | 20px | 600 | 1.20 |

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #F4F1EA | Summary background tone and rules-window placeholder surface target |
| Secondary (30%) | #DED7CA | Secondary badges, dividers, and lower-emphasis surfaces |
| Accent (10%) | #1F6FEB | Current-editor checkmark, success glyph, active summary badge, and keyboard-focus ring only |
| Destructive | #C0362C | Reserved for future destructive recovery actions; not used as a normal action color in this phase |

Accent reserved for: current-editor marker, success status glyph, focus ring, and the current-state badge only

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Use {EditorName} for All Text Files` |
| Empty state heading | `No Eligible Editors Found` |
| Empty state body | `Install or re-register a text editor, then reopen the menu to refresh the list.` |
| Error state | `Couldn't switch every text file type. Review the affected editor status and try another app.` |
| Destructive confirmation | None in Phase 02 — switching remains one-click and reversible only through another switch action |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-03-25
