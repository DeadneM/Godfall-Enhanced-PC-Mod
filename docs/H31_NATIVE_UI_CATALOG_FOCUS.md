# H31: Native cosmetic widget/catalog watcher

## Evidence from H30
The user's H30 log (272 lines) confirms six one-click automatic snapshots with no recorded Lua error. Baseline: 244,061 objects, 226 selected names. Sample 2: 355 added and eight Hinterclaw skin Blueprint classes (Black, Damascus, Exalted, Ice, Lava, Red, Void, Yellow). Sample 5: 349 removed. These class loads do **not** establish entitlement or skin ownership, and no MacrosCosmetic object was shown in the limited H30 name subset.

## H31 correction
H30 sorted changes alphabetically, showing only the first 45 of 355 added and 349 removed. Actual native UI widgets might have fallen after the cut.

H31 prioritizes `WBP_*`, `UserWidget`, `WidgetBlueprintGeneratedClass`, and UI/menu paths; filters common combat-mark widget components and Niagara/particle artifacts; logs up to 160 **priority ranked** object changes, plus separate `H31_WIDGET_ADDED` / `H31_WIDGET_REMOVED`, and every `H31_HINTERCLAW_SKIN_CLASS_ADDED` / `H31_HINTERCLAW_SKIN_CLASS_REMOVED`.
It increases bounded class metadata sampling from 15 to 24 classes, with conservative total limits. Automatic scans remain at ~12-second intervals and stop after 12 snapshots (roughly 2.4 minutes). A/B material methods are unchanged from H25, F1 overlay from H27 is unchanged, and no hooks, reward, account, inventory or save mutation is introduced.

## In-game test
Outside the Hinterclaw cosmetics screen, press F1 then C **one time**. Open the game's original Hinterclaw skin menu and stay there ~30–45s, then exit. Send `GodfallEnhancedBridge.log` before restarting, preferably with the run's `H31_UI_DIFF`, `H31_WIDGET_ADDED` and `H31_HINTERCLAW_SKIN_CLASS_ADDED` lines. Avoid Method A during this audit.

## Current goal
Identify the vanilla cosmetic menu's list filtering and the difference between a selectable skin and the Gratitude skin `Character.Player.Hinterclaw.MacrosCosmetic`. We have only proven Macros cosmetic visual material application, not native ownership. No `Unlock Gratitude` or `Unlock All` is implemented.
