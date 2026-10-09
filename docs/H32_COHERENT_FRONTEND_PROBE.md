# H32 Coherent GT frontend probe

## Basis
H31 game log (490 lines) confirmed five read-only snapshots but no native skin ownership change. Snapshot #2 loaded `WBP_GT_Test_C` under `BP_GameInstance_C`, with `CoherentUIGTWidget_Persistent_90` and `CoherentUIGTAudioWrapper`. The game demonstrably loads **at least one Coherent UI GT view**. The prior watch kept 42,155 matching object names, largely nested widgets. The relation between this Coherent view and the **vanilla Hinterclaw cosmetics screen** is unknown, not proven.

## New code
- H32 **replaces** the too-broad 42k-widget scan with bounded targets: instances/classes related to Coherent UIGT, `WBP_GT_Test`, `WBP_Menu_Game`, and cosmetic/skin-related menu UI.
- One F1 → C press records baseline, then 9 automatic samples every ~12s, up to 10 snapshots total.
- `H32_PROBE_COUNTS` separates coherent, GT root, menu game, and cosmetic UI.
- `H32_PROBE_ADDED` / `H32_PROBE_REMOVED` identifies loaded/unloaded bridge instances. Reflected class methods/properties are read-only and limited to 14 classes / 150 functions / 140 properties.
- No UI JavaScript execution, Coherent bind invocation, network or account mutation, entitlement changes, loadout changes, or hooks.
- H25 A/B code and F1 ASI/dxgi.dll binaries retained unchanged.
- Fixes the old H30 boot banner in H31: `V0.6H32` and `H32_BOOT_MARKER` both explicit.

## Test
1. Install H32 files at game root. Launch into Sanctum outside the native Hinterclaw cosmetics menu.
2. Press F1 then C **once**. Check for `H32_PROBE_ARMED` and `H32_PROBE_BASELINE_SAVED`.
3. Open the vanilla Hinterclaw skins screen for 30–45 seconds; leave it while automatic scans continue.
4. Send `GodfallEnhancedBridge.log` before restarting. No Method A during the diagnostic.
5. Can also arm by writing `COHERENT_PROBE` or `UNLOCK_UI_AUDIT` to `ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt`, stop via `STOP_COHERENT_PROBE`.

If a Coherent view remains persistent and object names never change, the next research step is the frontend resource + game-to-JS bridge/selection logic, *not* another generic UObject scan. If this is a non-Coherent menu, follow the newly named UMG class.

## Truth status
`Character.Player.Hinterclaw.MacrosCosmetic` is Gratitude pack content and its visual materials work. Native cosmetic ownership, Unlock Gratitude, and Unlock All **have not been demonstrated**.
