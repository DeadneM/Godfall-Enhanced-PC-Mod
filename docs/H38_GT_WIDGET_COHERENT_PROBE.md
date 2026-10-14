# H38: Active WBP_GT_Test / Coherent widget data-boundary audit

## Why this build is different

In the user's `GodfallEnhancedBridge(9).log` (H37), **two controlled snapshots** showed:
- Sanctum before the vanilla Hinterclaw cosmetics menu: `WBP_GT_Test_C present=0`, `WBP_Menu_Game_C present=0`.
- After the vanilla cosmetics menu was opened: **`WBP_GT_Test_C present=1`**, `WBP_Menu_Game_C present=0`.

This is a genuine runtime UI-state correlation and the most specific lead so far. It **does not yet prove** that `WBP_GT_Test_C` enforces cosmetic eligibility, or that the menu bridge is local rather than using account-sourced data.

Other H37 results: the 12 Sanctum alcoves still had 126 map entries, with 9 Hinterclaw tags but no MacrosCosmetic; all nine `TSoftObjectPtrUserdata` values were unresolved. `SetValorplateCosmetic` and alcove owned-state functions are confirmed **names**, not evidence of native UI unlock.

## H38 changes

Built from H37 code and unchanged ASI/DXGI binary payloads, with H25 A/B visual controls, F1 overlay, and H35 offline locator preserved.

- **F1 → C** now records a lightweight `H37_UI_SNAPSHOT` of the two known widget classes and a bounded `H38_GT_PROBE` of **only the active** `WBP_GT_Test_C`.
- When this widget is absent (before the menu), log `H38_GT_PRESENT=0` and stop.
- When present, collect up to 60 relevant **UFunction names** and 65 relevant **property names/types** belonging only to that widget class via guarded `ForEachFunction/ForEachProperty`. These are metadata, not function invocations.
- Only when a relevant property name has `url`, inspect its runtime value and log **sanitized scheme/origin/resource-leaf classification** (`H38_GT_ROUTE`). Do not log other string values, event payloads, web hosts, credentials or account-related content.
- Check three known Coherent host types with `FindFirstOf`: `CoherentUIGTWidget_Persistent`, `CoherentUIGTWidget`, `CoherentUIGTComponent`, optionally inspect their **URL route summary** and classify their outer as GT_TEST / COHERENT / GAME_INSTANCE / OTHER. No global UObject crawl.
- The earlier H36/37 alcove scan remains callable **separately** by writing `ALCOVE_MAP_AUDIT` to the existing bridge command file. The prior Coherent watcher similarly remains accessible by manual `COHERENT_PROBE`. They no longer run automatically on the C button.
- No hooks, no `TMap:Add` or `Remove`, no `SetValorplateCosmetic`, reward/inventory/session/save mutation, account changes or JavaScript event invocation.

## One-session test

1. Back up H37; extract H38 ZIP to game EXE directory while retaining `ue4ss/` tree. Restart Godfall. Check `H38_BOOT_MARKER=OK`.
2. In fully loaded Sanctum, outside the original cosmetics screen, press **F1 → C** once.
3. Open the vanilla Hinterclaw cosmetics screen, open F1 overlay there, then press **C a second time**.
4. Send `GodfallEnhancedBridge.log` before exiting/relaunching (log resets on startup).

**New markers:** `H38_GT_PRESENT`, `H38_GT_FUNCTION`, `H38_GT_PROPERTY`, `H38_GT_ROUTE`, `H38_VIEW_URL`, `H38_VIEW_PARENT`, `H38_GT_PROBE_END`.

**Success for H38:** establish the specific widget's exposed native bridge/interface properties and any class/route associated with the menu view. **Not** a native cosmetic unlock. Further step: FModel focused `WBP_GT_Test` export or tracing the *exact discovered* DataBridge UI query. Unreal Blueprint metadata alone cannot identify a filter.

**Safety caveat:** UE4SS read-only UObject reflection can still trigger engine faults; all calls guarded and only invoke after level load.
