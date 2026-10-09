# H33 Coherent GT runtime value probe (READ ONLY)

## Source evidence
H32 user log (`GodfallEnhancedBridge(4).log`, 387 lines, 57,690 B) completed seven scans. Snapshot 2 spawned a live `WBP_GT_Test_C` owning `CoherentUIGTWidget_Persistent_90`, 16 JS-event UObjects, 15 JS-payload UObjects, and an audio wrapper. The Coherent widget survived the later samples, while transient JS events/payloads were collected.

H32 identified but **did not read** these properties:
- `CoherentUIGTComponent.URL` (`StrProperty`);
- `CoherentUIGTSettings.CoUIResourcesRoot` (`StrProperty`);
- `CoherentUIGTJSPayload.EventName` (`StrProperty`).

These are relevant to the frontend resource path and event names, but they do **not** prove the Coherent widget is the native cosmetic selector.

## H33 changes
- F1 → C once starts the existing automatic 12-second read-only Coherent watcher, 10 samples maximum.
- Additional guarded `UObject:GetPropertyValue` probes collect exactly the three string properties above from selected *live* objects; no arbitrary property walking of session/account data.
- `H33_VALUE_SUMMARY` and `H33_VALUE` report sanitized, unique event **names only**, resource paths or redacted URL markers. No payload arguments are accessed. Queries/fragments, absolute paths, credentials and suspicious tokens are not logged. Logging limits 35 new values per scan.
- Targeted reflection of `CoherentUIGTWidget_Persistent`, `CoherentUIGTWidget`, `CoherentUIGTComponent`, `WBP_GT_Test_C`, `WBP_Menu_Game_C` (metadata only). Previously H32 hit its 14-class cap alphabetically before reaching the Widget classes.
- Does NOT invoke `TriggerJSEvent`, `Load`, `Reload`, entitlement, reward, inventory or save changes. Does not register hooks. UE4SS property lookup is read-only as per its documented `GetPropertyValue` API.
- H25 visual A/B and the F1 ASI + DXGI are unchanged. ZIP root layout preserved.

## Test
1. Back up mod files, install H33 at game root.
2. In Sanctum, outside the vanilla Hinterclaw cosmetics menu, F1 → C **once**.
3. Open the original Hinterclaw cosmetic selection interface for 30–45 seconds. Do not use A.
4. Send `GodfallEnhancedBridge.log` before restarting. Look for `H33_VALUE_SUMMARY`, `H33_VALUE`, `H33_TARGET_PROPERTY` and `H32_PROBE_DIFF`.

## Limitations / interpretation
UE4SS versions may not expose some inherited properties on `CoherentUIGTWidget_Persistent`; in that case no value will be logged. Event names are never sufficient to infer ownership or entitlement. If the active view URL or resource root is discovered, **next inspect the frontend's resource and data/model bridge** rather than make more broad runtime object inventories. The mod still does NOT implement Unlock Gratitude or Unlock All.

Known visual skin target: `Character.Player.Hinterclaw.MacrosCosmetic` (Gratitude Pack), whose appearance is confirmed but native selection remains unproven.
