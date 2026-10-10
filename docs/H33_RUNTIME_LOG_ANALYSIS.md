# H33 runtime log - 2026-10-10

Source: user-supplied `GodfallEnhancedBridge(5).log`, 534 lines, 77,868 bytes. Raw log not copied into repository.

## Verified outcome
- `V0.6H33`, `H33_BOOT_MARKER=OK` and `METHOD_C AUTO_NEXT`.
- Six successful read-only captures: `H32_PROBE_END sample=1..6 mutated=0`. No fatal/error diagnostic in the supplied log. The watcher did not run to the max 10 samples; this is not itself a failure.
- First scan saw 245,397 UObjects, retaining 246 relevant names (88 Coherent, 12 GT-root, 146 menu-game, zero cosmetic-UI matches).
- 64 names appeared in sample #2, 12 in #3, 103 disappeared in #4, then 2 and 4 added in #5 and #6.
- Exactly **three** distinct sanitized values were printed at sample #1; samples #2–#6 printed `unique_new=0` (deduplication suppresses repeats). They were:
  - `EventName=UE_DATABRIDGE`
  - `URL=[REDACTED_ABSOLUTE_RESOURCE scheme=http]`
  - `URL=[REDACTED_RESOURCE]`
- An HTTP URL is demonstrably present, but its host/path/query are not in H33 logs, due to intentional redaction. Do not guess whether it is local or remote.
- `WBP_Menu_Game_C` class metadata exposes `ReactSettingsURL` and `ReactCharacterSelectURL` as `StrProperty`. **Only the property names/types were recorded**. No React URL value was read.
- `CoherentUIGTSettings.CoUIResourcesRoot` metadata was recorded in the broader reflection but no actual value was logged.
- The live `WBP_GT_Test_C` / `CoherentUIGTWidget_Persistent_90` remains present, but H33 did not establish this specific widget as a skin selector.

## Interpretation and next test
`UE_DATABRIDGE` names a Coherent JS event boundary. This does not reveal event payloads, cosmetic ownership flags, the actual React route, or a local vs backend entitlement check. The `ReactCharacterSelectURL` field is the first explicit class-level pointer toward a character-selection React route; however character selection is not automatically cosmetic selection.

H34 should use **UE4SS UClass:GetCDO()** (documented public API) and guarded `GetPropertyValue()` to inspect the *read-only default values* of `ReactSettingsURL`, `ReactCharacterSelectURL`, and `CoUIResourcesRoot`. Independently, sanitized Coherent URL scheme + coarse route components could distinguish a local `coui://` resource from HTTP hosting, without copying host identifiers, query strings, JS payloads, credentials, usernames or absolute filesystem paths. This may lead toward bundled React/JS resources.

No native cosmetic unlock has been demonstrated; `Character.Player.Hinterclaw.MacrosCosmetic` remains a visually-applied Gratitude skin rather than a verified selectable cosmetic.
