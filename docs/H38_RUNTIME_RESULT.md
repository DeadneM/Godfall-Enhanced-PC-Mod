# H38 runtime result: WBP_GT_Test_C is a Coherent host

**Test date:** 2026-10-14. **Source:** user-supplied `GodfallEnhancedBridge(10).log`, 34 lines, 2,446 bytes. Raw user log not added to repo.

## Verified runtime sequence

- Correct boot: `V0.6H38 GT Widget / Coherent Live Probe`, `H38_BOOT_MARKER=OK`.
- `F1 → C` before the original skin UI: `WBP_GT_Test_C present=0`, `WBP_Menu_Game_C present=0`, `H38_GT_PROBE_END status=not_loaded mutated=0`.
- `F1 → C` after original Hinterclaw skin UI was opened: `WBP_GT_Test_C present=1`, `WBP_Menu_Game_C present=0`, `H38_GT_PROBE_END status=completed mutated=0`.
- **Two relevant class function names**: `ToggleBgBlurWidget` and `GetCoherentUIGTWidget`.
- **Two relevant class property names**: `BackgroundBlurWidget : ObjectProperty` and `CoherentUIGTWidget_Persistent_90 : ObjectProperty`.
- `CoherentUIGTWidget_Persistent` live instance exists; its `GetOuter()` is classified `GT_TEST`, indicating an object owned by `WBP_GT_Test_C`.
- `CoherentUIGTWidget` generic and `CoherentUIGTComponent` were not found as separate instances in this H38 test.
- No `H38_GT_ROUTE` or `H38_VIEW_URL` value was emitted. Do not infer an actual UI URL or resource host from this log. No fatal error was logged.

## Interpretation

`WBP_GT_Test_C` is **strongly supported as the live UMG host for Coherent GT while the skins menu is active**, not as the cosmetic ownership gate itself. It has only two surfaced class members relevant to our broad name filter and no obvious skin, entitlement, inventory or UI filtering methods.

The earlier Coherent HTTP `origin=non_loopback` classification in H34 does not establish whether the skin UI HTML/JS is remote, locally cached or embedded in an asset; H38 captured no route. `ReactCharacterSelectURL=character-select` belongs to a different `WBP_Menu_Game` class absent in the H37/H38 active cosmetics snapshots.

## Next action: one meaningful owner-to-child drilldown

H39 should stop introspecting the **host** and inspect its specifically named child `CoherentUIGTWidget_Persistent_90` via the reflected `ObjectProperty` on the live `WBP_GT_Test_C` instance (no live UObject-wide scan). Classify identity and ownership, only safe URL route categories, and bounded reflected child **metadata** to determine whether data bridge bindings exist there. The `GetCoherentUIGTWidget` function is not to be invoked until its effects are understood. No account, JS payload or entitlement changes.

If the child yields only generic Coherent plugin methods, **do not continue generating reflection-only versions**. Instead inspect FModel's `WBP_GT_Test` JSON and the compiled UI frontend resources or actual DataBridge request source. Use data-backed acceptance conditions before attempting any cosmetic map modification.

**Unlock goal still unmet**: `Character.Player.Hinterclaw.MacrosCosmetic` must be shown and selectable within original Godfall cosmetics UI; visual material substitution is not a native unlock. H39 is not yet validated in game.

**Status:** H38 successfully run as read-only diagnosis, no native unlock and no crashes in the submitted log.
