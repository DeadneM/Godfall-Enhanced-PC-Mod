# H30 Cosmetic UI Auto Watch (F1)

## Why
The 2026-10-09 H29 runtime log completed one 245,390-object UI snapshot (91 matches) and found `BP_ValorplateAlcove.CosmeticTagToPlayerSkin`. It did not contain a second snapshot, so the previous two-click procedure was not completed.

## H30 changes
- One press of F1 -> Method C **arms automatic monitoring** and immediately captures baseline.
- Every ~12 sec (48 passes of the 250 ms async loop), an additional read-only snapshot records `H30_UI_DIFF` and added/removed object names. Monitor is bounded at 20 total snapshots (~4 minutes), not an unbounded permanent scanner.
- Manual Method C during monitoring optionally takes an extra immediate snapshot, but is **not required**.
- To arm or force an immediate snapshot without overlay, write `UNLOCK_UI_AUDIT` to `ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt`. To stop early, write `STOP_UI_WATCH`.
- Bounded logs: baseline max 65 candidate names, subsequent diffs max 45 names per direction; ranked class metadata introspects at most 15 classes, 130 functions and 85 properties.
- Prioritizes skin/customization-related WidgetBlueprint classes. Keeps `BP_ValorplateAlcove` in the search if its name qualifies.
- The monitor does not cache native Unreal references between snapshots, only strings. No hooks, UI manipulation, entitlement spoofing, reward calls or save editing.
- H25 A/B untouched, F1 ASI and dxgi.dll binaries unchanged.
- `DUMP_MATERIALS` remains available explicitly, while C no longer performs an unrelated material dump.
- Caveat: repeated 245k-object scans can cause brief in-game stutters. Sampling is deliberately sparse, bounded and manually stoppable. Object-name changes may still miss a menu using persistent widgets or non-UMG UI.

## User test
1. Back up the mod, install H30 with ZIP files at root.
2. Start in Sanctum, **outside** the original Hinterclaw skins menu, use F1 -> C **once**. Log should show `H30_UI_WATCH_ARMED` and `H30_UI_BASELINE_SAVED`.
3. Open the normal Hinterclaw skins/cosmetics screen and leave it open for approximately 30-45 seconds so the automatic watcher can capture multiple samples.
4. Return to the game, send `GodfallEnhancedBridge.log` **before restarting** (log resets at boot). If large, share ZIP of that log.
5. Look for `H30_UI_DIFF sample=2`, `H30_UI_SCAN_END`, and `H30_UI_WATCH_STOP reason=MAX_SAMPLES` if letting it run to completion. A stop is not required to send it.
6. No need to click C twice, and do not click Method A during the audit; A remains available for independent visual tests.

## Unlock target
`Character.Player.Hinterclaw.MacrosCosmetic`, confirmed Gratitude Pack content, is applied visually in H25+ but not yet a verified native unlock. Identifying **vanilla menu visibility/selection state** is the priority before implementing Unlock Gratitude or Unlock All.
