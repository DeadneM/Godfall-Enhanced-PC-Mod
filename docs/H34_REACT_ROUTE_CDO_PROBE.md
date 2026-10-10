# H34 React URL / Coherent resource route probe

## Trigger: H33 game log
H33 completed six read-only scans; three unique values were seen in the first scan:
- `EventName=UE_DATABRIDGE` (live Coherent JS event name).
- `URL=[REDACTED_ABSOLUTE_RESOURCE scheme=http]`.
- `URL=[REDACTED_RESOURCE]`.

No `CoUIResourcesRoot` value was printed. `WBP_Menu_Game_C` class metadata reveals **two explicit React URL StrProperties**: `ReactSettingsURL` and `ReactCharacterSelectURL`. H33 did **not** read their default or instance values. The presence of React character selection URLs does not prove that this view implements cosmetics/ownership. See [H33 runtime evidence](H33_RUNTIME_LOG_ANALYSIS.md).

## H34 changes
- Retains F1 overlay and H25 visual A/B methods, ASI/DXGI binaries unchanged.
- UE4SS **UClass:GetCDO()**, the public read-only class-default-object API, is guarded with `pcall`; when available, reads only `WBP_Menu_Game_C.ReactSettingsURL`, `WBP_Menu_Game_C.ReactCharacterSelectURL`, and `CoherentUIGTSettings.CoUIResourcesRoot`, all strings.
- Adds sanitized **URL route leaf** classification to H33 view property inspection; shows scheme (`http`, `https`, `coui`), whether host is loopback, and the last safe route/filename. Never records host, port, query, fragment, full filesystem path or JS payload content.
- Keeps `EventName` read-only, names only.
- Reduces maximum automatic scans from 10 to 5 (baseline + 4 checks at ~12-second intervals); no hooks, JSEvent calls, entitlement spoofing, account/save or inventory modification.
- New completion markers: `H34_CDO_ROUTE`, `H34_CDO_FIELD_UNAVAILABLE`, `H34_CDO_NOT_AVAILABLE`, `H33_VALUE field=URL_ROUTE` (if URL was accessible), plus existing `H32_PROBE_END` markers.
- Does not assume a default-value URL is the currently active view URL. A route name is a candidate for later resource analysis, **not an ownership proof**.

## Test
In Sanctum, outside the normal Hinterclaw skins menu, press F1 then C once. Open the in-game Hinterclaw cosmetics screen for ~30 seconds; send `GodfallEnhancedBridge.log` before game restart. H34's main work occurs at sample 1; 4 later scans check changes.

## Follow-up
If the default React character-select page can be identified, inspect the corresponding locally bundled UI resources or the game's actual bridge logic rather than repeating UClass dumps. Focus on how the original cosmetics menu populates and enables `Character.Player.Hinterclaw.MacrosCosmetic`. No `Unlock Gratitude` or `Unlock All` is yet implemented or validated.
