# H37 combined targeted, read-only diagnostic

**Based on user-approved broad testing:** multiple *different* hypotheses are tested within one build, not additional generic object dumps.

## Verified starting evidence
H36 on 2026-10-12 read the live `CosmeticTagToPlayerSkin` maps from all 12 Sanctum alcoves: 126 tag→class pairs. Hinterclaw's placed actor contained 9 tags (Black, Yellow, Ice, Void, Damascus, Red, Pearl, Lava, Exalted), but not the cooked Gratitude `Character.Player.Hinterclaw.MacrosCosmetic`. The class values were reported `SOFTCLASS_UNRESOLVED`. This discrepancy is **not proof that the alcove map controls the game's original cosmetics-menu eligibility**.

## H37 experiments, grouped into one cumulative test
1. **SoftClass source resolution**: for the nine Hinterclaw entries, guarded read-only attempts to decode multiple native variants of Unreal's soft-class path (`AssetPathName`, nested `SoftObjectPath.AssetPathName`, `AssetPath.AssetPathName`, `AssetPtr`, `GetAssetPathName()`, `ToString()`, `GetFullName()`). Only asset-path identifiers are logged; raw pointers/URLs/user files are never printed. Marker `H37_SOFTCLASS`.
2. **Focused map-consumer metadata**: only the loaded Hinterclaw alcove actor's UClass is reflected with `ForEachFunction` / `ForEachProperty`, logging relevant cosmetic/skin/owned/selection names, bounded to 36 functions and 28 properties. This is **not executable Blueprint flow tracing**, and function names do not prove a causal UI gate. Markers `H37_CLASS_FUNCTION`, `H37_CLASS_PROPERTY`, `H37_CLASS_AUDIT_END`.
3. **UI comparison**: the first `F1 → C` in an already-loaded Sanctum records a narrow presence check of `WBP_GT_Test_C` / `WBP_Menu_Game_C`. After opening the original Hinterclaw skins screen, a **second** `F1 → C` captures a comparison, without rerunning the 12-alcove traversal. The classes may persist across both snapshots; unchanged presence does not prove identical UI states. Markers `H37_UI_WIDGET` and `H37_UI_SNAPSHOT_END`.
4. **Existing safe H36 map evidence**: the first C retains all bounded H36 map tag counts and key names to correlate with the previous log. Separate direct `ALCOVE_MAP_AUDIT` command remains available for debugging. A/B material apply/restore methods remain unchanged.

## Safety and compatibility
- All tests are read-only and wrapped in guarded `pcall`, with bounded reflection and logs.
- No `TMap:Add`, `TMap:Remove`, `SetValorplateCosmetic`, player inventory/reward/save/session mutation or server entitlement spoofing.
- `GodfallEnhanced.asi`, `dxgi.dll`, H35 offline locator and overlay F1 are unchanged from H36. Existing Coherent watcher can still be invoked manually with `COHERENT_PROBE`.
- The game/UE4SS can still crash on bad native reflection even when calls are guarded; do not invoke during a level transition.
- ZIP is cumulative, contains the original four functional runtime paths (README, ASI, DXGI, INI+UE4SS bridge) and H35 helper script.

## Single session test
1. Back up H36, extract entire H37 ZIP to the executable folder preserving `ue4ss/`; restart Godfall. Look for `H37_BOOT_MARKER=OK`.
2. In the Sanctum (fully loaded), press **F1 → C once**.
3. Close mod overlay, open Godfall's normal Hinterclaw skins menu; press **F1 → C a second time** if the overlay can open there. Do not use A or B for this experiment.
4. Send `GodfallEnhancedBridge.log` without restarting.

**Acceptance:** We obtain evidence on whether UE4SS can decode the nine soft-class values, which Alcove methods are reflected, and whether known frontend widgets differ in native cosmetics view. This is an **experiment**, not a native cosmetic unlock.

**Native unlock goal remains:** `Character.Player.Hinterclaw.MacrosCosmetic` must be present and selectable from the original cosmetics UI, persist through refresh and restart. No feature `Unlock Gratitude` / `Unlock All` is implemented or verified.
