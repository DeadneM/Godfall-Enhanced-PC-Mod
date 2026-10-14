# H39 runtime result: Coherent widget is generic bridge infrastructure

**Date:** 2026-10-14
**Input:** user-provided `GodfallEnhancedBridge(20261014-112613).log`, **45 lines / 3,496 bytes**. Raw user log remains outside the repo. **Status: H39 successfully executed in game as a read-only diagnostic; native cosmetic unlock still unavailable.**

## Exactly confirmed

- The correct bridge loaded: `V0.6H39 Coherent Persistent Child Inspect`, `H39_BOOT_MARKER=OK`.
- First `F1 → C` in Sanctum baseline:
  - `WBP_GT_Test_C present=0` and `WBP_Menu_Game_C present=0`.
  - `H39_CHILD_PROBE_END status=host_not_loaded mutated=0`.
- Second `F1 → C`, while the original Hinterclaw skins menu was visible:
  - `WBP_GT_Test_C present=1`, `WBP_Menu_Game_C present=0`.
  - `H39_CHILD_PROPERTY result=resolved`.
  - `H39_CHILD_INSTANCE name=CoherentUIGTWidget_Persistent_90`.
  - `H39_CHILD_OWNERSHIP direct=0`. This is **not a failure to locate the child**: the parent widget's reflected ObjectProperty resolves the child, but `GetOuter()` is not an exact match for the `WBP_GT_Test_C` UObject. This corrects the earlier loose H38 conclusion based on a classified outer.
- Reflected `CoherentUIGTWidget_Persistent` class (depth 0):
  - Functions: `Reload`, `OnUIGTScriptingReady`, `Load`, `IsDocumentReady`.
  - Multicast delegate properties: `ReadyForBindings`, `BindingsReleased`, `FinishLoad`, `FailLoad`, `StartLoading`, `JavaScriptEvent`, `UIGTScriptingReady`.
- Inherited `Widget` class (depth 1): `OnPointerEvent__DelegateSignature`, `AccessibleWidgetData`, `NativeBindings`; base classes `Visual` and `Object` also observed.
- `H39_CHILD_META_END functions=5 properties=9 mutated=0`.
- `H39_CHILD_PROBE_END status=completed mutated=0`; **no fatal errors in supplied log**.
- **No `H39_CHILD_ROUTE` logged**, and **no skin availability, ownership, inventory or selection-specific functions/fields were identified**. No event payload contents were inspected.

## Why the native-widget probe series stops here

H37 identified the UI host by direct before/after test, H38 located its persistent Coherent child, and H39 established that the child exposes only **generic Coherent loading/event/binding infrastructure** in the available reflected properties. Additional iterations scanning those same reflected host/plugin classes would repeat inconclusive work, despite the user's previous preference for stronger combined tests.

`JavaScriptEvent` and `ReadyForBindings` explain the *possible boundary between Unreal and the frontend*, but their names **do not reveal the cosmetic list or eligibility gate**. Attempting to attach hooks, emit JS messages or change entitlement-like fields without knowing the real request format would be speculative and could compromise gameplay/account state.

The previously validated H36 map `BP_ValorplateAlcove_C.CosmeticTagToPlayerSkin` contains nine Hinterclaw tags but not `Character.Player.Hinterclaw.MacrosCosmetic`. This alone is not a proof that the map governs the original skins UI; it might only govern Sanctum Alcove presentation. **Do not inject a new tag or `SoftClass` entry as the next step.**

## Next source-based investigation, not H40 reflection scanning

1. In FModel on the user’s existing IoStore packages, locate **`WBP_GT_Test`**, export that *single package* as JSON and send it. Inspect widget tree, Coherent widget defaults, bindings and referenced other packages.
2. Search the package tree / locally available resources for frontend or `DataBridge` / cosmetics retrieval definitions only when those assets are discovered. The original H34 HTTP view was classified as non-loopback; this does not prove whether the actual JavaScript resources are local or remote. Do not infer a remote host or request payload.
3. Determine which *actual* cosmetic/ownership list is requested when the native skin screen opens, and find the appropriate local UI display path **before** any reversible visibility test. Do not modify account entitlements, rewards, saved progression or backend flows.
4. Build H40 only once a distinct, evidence-backed target, concrete expected outcome and rollback conditions exist.

## Status

- **H23:** visual Hinterclaw Macros substitution validated by user.
- **H25:** materials application/restoration verified in logs.
- **H34:** class-default React routes `esc-menu/settings` and `character-select` extracted by FModel.
- **H35:** installed IoStore inventory; FModel targeted exports.
- **H36:** 12 live Sanctum alcove maps, 126 entries, nine Hinterclaw tags; absent MacrosCosmetic.
- **H37:** `WBP_GT_Test_C` appears when vanilla skins menu opens.
- **H38:** identified specific `CoherentUIGTWidget_Persistent_90` ObjectProperty.
- **H39:** that property resolves a child with only generic Coherent plugin interfaces. **Diagnostic successful; line of inquiry exhausted.**
- **H40:** **not built**.
- **Native `MacrosCosmetic` equip / Unlock Gratitude / Unlock All:** **not achieved**.

See [H39 experiment plan](H39_COHERENT_CHILD_PROBE.md), [H38 runtime result](H38_RUNTIME_RESULT.md), [H36 map data](H36_RUNTIME_RESULT.md). 
