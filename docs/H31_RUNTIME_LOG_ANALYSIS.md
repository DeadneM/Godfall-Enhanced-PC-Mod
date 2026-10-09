# H31 runtime analysis - 2026-10-09

Source: user-supplied `Texte collé.txt`, which is a GodfallEnhancedBridge log (490 lines, 90,334 bytes). No game/account private values copied. Raw log not committed.

## Confirmed H31 execution
- Header is **incorrectly still H30** (`V0.6H30 Cosmetic UI Auto Watch`) even though `H31_BOOT_MARKER=OK` and H31 markers are present. Fix the banner next version.
- `COMMAND METHOD_C AUTO_NEXT` armed one-click watcher.
- Five snapshots completed without visible fatal error: sample 1 scanned 245,387 UObjects and retained 42,155 names (153 classes); sample 2 scanned 245,845 and retained 42,179; sample 3 scanned 244,438 and retained 41,940; samples 4-5 stable.
- Sample 2: **24 additions**, of which 22 were counted as widgets. They included live `WBP_GT_Test_C` and a `CoherentUIGTWidget_Persistent` under `BP_GameInstance_C`.
- Sample 3: **239 removals**, of which 237 were counted as widgets. Removed objects include `WBP_PlayerDefeat`, `WBP_CompassObject`, `WBP_HUD`, and related control trees. The log does not prove these represent the cosmetic-selection UI, and they may represent a game-state transition.
- No `H31_HINTERCLAW_SKIN_CLASS_ADDED` or `_REMOVED` events were logged. Unlike H30, this run shows no newly loaded Hinterclaw skin Blueprint classes. It does not prove the assets are absent or never loaded.
- All five `H31_UI_SCAN_END` entries have `mutated=0`. The log ends after sample 5; no `H31_UI_WATCH_STOP` line.

## New strong architectural clue

The live UObject paths show:
`WBP_GT_Test_C -> WidgetTree -> CoherentUIGTWidget_Persistent_90`
and `CoherentUIGTAudioWrapper`.

This **proves at least one Coherent UI GT widget exists in the running Godfall build**. Whether the vanilla cosmetic menu uses this exact instance remains unproven.

We should stop assuming the cosmetics menu is entirely composed of Unreal UMG widgets. A persistent Coherent UI GT view may display changing frontend content while its Unreal UObject names remain unchanged. Simple object-name diffs would then never identify a selected skin or an ownership filter.

## H31 diagnostics limitation

The additional `wbp_` and `/ui/` matching expanded the baseline from H30's 226 matches to **42,155** (almost all nested widget-tree objects), obscuring the relevant view. The prior 160-entry sorted diff improved logging but not relevance. Do not repeat the same broad snapshot in H32.

## Correct next step

A targeted **read-only** Coherent bridge diagnostic: scan specifically for live Coherent GT instances, their UClass/UProperty/UFunction metadata, `WBP_GT_Test`, `WBP_Menu_Game`, and cosmetic/menu presentation managers. Compare instance presence every ~12 seconds while switching the native Hinterclaw cosmetic UI. Print bounded runtime object names and reflect only identified classes. Avoid dynamic edits, Coherent JavaScript execution, entitlement/account calls, UI hooks and save modifications.

If this points to the Coherent frontend rather than UE4 UMG, next work must inspect the frontend resource/bridge path to locate the true `cosmetics/collection` visibility check.

## Status
H25 visual application/restore remains separately validated. H31 watcher and its 5 captures work. The native unlock of Gratitude `Character.Player.Hinterclaw.MacrosCosmetic` is **NOT** demonstrated.
