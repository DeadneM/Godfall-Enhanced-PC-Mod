# H30 runtime results, 2026-10-09

Source: user-provided GodfallEnhancedBridge(3).log (272 lines, 47,157 bytes). Raw runtime log is not committed.

## What the log actually demonstrates

- H30 boot succeeded; `COMMAND METHOD_C AUTO_NEXT` armed the one-click monitor.
- `H30_UI_WATCH_ARMED period_seconds_approx=12 max_samples=20`; baseline sample=1 scanned 244,061 UObjects and retained 226 matches (37 classes, 189 instances).
- Six samples completed. No `FATAL`, `ERROR`, `H30_UI_SCAN_ERROR` or `H30_UI_WATCH_ERROR` appears. Log ends at sample=6; the watch's 20-sample limit was not reached (the test was stopped/saved or the log truncated).
- In sample=2, 355 names appeared (581 total). Samples=3/4 remained stable.
- In sample=5, 349 names disappeared (232 total). Sample=6 was stable. We do not have an explicit in-game event marker; this pattern is **consistent** with entering and leaving a character cosmetic/preview context, but does not prove precise user actions.
- New loaded classes during sample=2 included: `BP_Hinterclaw_Black`, `BP_Hinterclaw_Damascus`, `BP_Hinterclaw_Exalted`, `BP_Hinterclaw_Ice`, `BP_Hinterclaw_Lava`, `BP_Hinterclaw_Red`, `BP_Hinterclaw_Void`, `BP_Hinterclaw_Yellow`.
- No `MacrosCosmetic` occurrence in the H30 runtime log other than its static Method A boot description. That does **not** establish that the corresponding catalog row is absent, excluded by entitlement, or not loaded in memory: H30 matched a narrow name subset and did not dump all changed objects.
- Other new objects include multiple `BP_PlaneSwitchingCosmeticsManager_Component_C`, player character classes, `APWidgetComponent`, and `APWidgetComponentEnemy`. The latter may represent actor/HUD components rather than the native cosmetic selection menu.
- H30 baseline reflection listed 48 relevant UFunctions and 5 UProperties in 15 classes, but prioritization selected generic cosmetic managers and unrelated classes before the real skin selection interface.

## Precise flaw in H30

The diff was sorted alphabetically and truncated after only 45 added and 45 removed names. For 355 added / 349 removed, **310 added and 304 removed names went unlogged**. As a result, the most useful UMG widgets may have been omitted, and the test cannot yet identify the native menu's ownership filter.

A `BP_Hinterclaw_*` Blueprint class appearing in memory proves it was loaded. It does *not* prove that skin is owned, unlocked, visible, selectable or present in the vanilla UI list.

## H31 priority

Replace broad alphabetical logging with **priority-ranked UI widget/skin candidates**: `WidgetBlueprintGeneratedClass`, `UserWidget`, `WBP_*`, `/UI/`, `/GUI/`, plus the actual character skin classes. Log the full ranked changes for these specific items, rather than repeatedly dumping generic cosmetic manager APIs.

Keep: F1 overlay, stable H25 material A/B code, automatic one-click snapshots with conservative 12s sampling, bounded logs, no account/network mutation. Once real UI methods are known, compare native-menu eligibility between known selectable skin and `Character.Player.Hinterclaw.MacrosCosmetic`.

Status: H30 automatic scanning **validated by runtime log**; native cosmetic unlock is not verified.
