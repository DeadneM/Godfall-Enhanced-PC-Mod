# H34 runtime log analysis – 2026-10-11

Source: user-provided `GodfallEnhancedBridge(7).log` (521 lines, 81,117 bytes). Raw log was not uploaded to GitHub.

## Status and safety

- Correct build loaded: `V0.6H34 React Route and CDO Probe`, `H34_BOOT_MARKER=OK`.
- F1/C bridge command accepted: `COMMAND METHOD_C AUTO_NEXT`.
- Four read-only snapshots completed: `H32_PROBE_END sample=1..4 mutated=0`.
- No `FATAL` or `ERROR` line appears in the provided log. Snapshot #5 / `MAX_SAMPLES` was **not recorded**, which does not by itself prove a fault.

## Actual H34 discoveries (UClass default values, not live UI navigation)

```text
H34_CDO_ROUTE class=WBP_Menu_Game_C field=ReactSettingsURL scheme=relative origin=not_applicable leaf=settings
H34_CDO_ROUTE class=WBP_Menu_Game_C field=ReactCharacterSelectURL scheme=relative origin=not_applicable leaf=character-select
```

- `WBP_Menu_Game_C` exposes the actual **class default** relative React routes `settings` and `character-select`.
- This is stronger evidence than the mere property names from H33; it is **not** proof that either route is the Hinterclaw cosmetic list, or that an ownership gate runs in this Blueprint.
- H34 did not print a concrete `CoUIResourcesRoot` value, even though `CoherentUIGTSettings.CoUIResourcesRoot` property metadata was identified.
- Read-only Coherent UI view classification: `URL_ROUTE scheme=http origin=non_loopback leaf=empty` and `scheme=other route=redacted`. Exact URL/domain/path is not recorded by the privacy filter; do not invent or assume a particular host or remote service.
- The live event `UE_DATABRIDGE` was observed in snapshot #2 (`H33_VALUE field=EventName value=UE_DATABRIDGE`). **Only the event name**, not its payload or cosmetic content, is known.

## Observed transitions

| Snapshot | Scanned UObjects | Tracked objects | Coherent | GT root | Menu game | Cosmetic UI | Added |
|---|---:|---:|---:|---:|---:|---:|---:|
| #1 | 244,106 | 207 | 49 | 12 | 146 | 0 | baseline |
| #2 | 244,989 | 262 | 94 | 22 | 146 | 0 | 55 |
| #3 | 248,554 | 318 | 150 | 22 | 146 | 0 | 56 |
| #4 | 248,713 | 461 | 164 | 22 | 275 | 0 | 143 |

These counts demonstrate loading of Coherent event objects and a native `WBP_Menu_Game_C` widget tree by snapshot #4. The source does **not** label the user's exact menu actions, so do not claim that snapshot #4 is definitely the cosmetic screen.

## Decision: stop generic scanning; investigate actual frontend resources

The H26–H34 investigations have located a native menu class, route strings and a Coherent data bridge but **not the cosmetic availability query**. A new broad UObject scan would violate the project's progress-first charter.

**Next concrete source investigation:** locate the actual locally shipped frontend/React resources that implement `character-select`, or, if they are not available as standalone files, the cooked `WBP_Menu_Game` Blueprint together with relevant frontend resource package information. Search for `character-select`, `cosmetics/collection`, `UE_DATABRIDGE`, `MacRosCosmetic` / `MacrosCosmetic`, and skin eligibility, then compare one ordinary selectable Hinterclaw skin to Gratitude `Character.Player.Hinterclaw.MacrosCosmetic`.

The GitHub repository contains Lua bridges and diagnostic ZIPs but **not** the game-distributed React JS/HTML bundle or extracted menu assets. The historical user uploads of large Godfall game packages are no longer available in this session. Only request the minimal specific frontend bundle/assets needed, avoiding full multi-gigabyte package uploads if possible.

### Acceptance criteria

`Character.Player.Hinterclaw.MacrosCosmetic` appears in and can be equipped using the game's **original cosmetics menu**, survives menu refresh and restart. Visual H23–H25 material substitution alone does **not** meet the native-unlock objective.

**Status:** H34 runtime diagnostic completed successfully, no native unlock, no H35 build created.
