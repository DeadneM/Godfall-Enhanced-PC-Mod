# H32 confirmed runtime findings (2026-10-09)

Source: user-supplied `GodfallEnhancedBridge(4).log` (387 lines, 57,690 bytes). The user's raw log is not committed.

## Verified behavior

- `V0.6H32` and `H32_BOOT_MARKER=OK` were logged.
- One `METHOD_C AUTO_NEXT` armed the automatic read-only watcher.
- Seven snapshots completed, with `mutated=0` and **no fatal runtime diagnostics reported**.
- Snapshot 1 scanned **244,097 UObjects**; 207 relevant names split as `coherent=49`, `gt_root=12`, `menu_game=146`, `cosmetic_ui=0`.
- Snapshot 2: **43 additions, zero removals**. Counts increased to `coherent=82`, `gt_root=22`, `menu_game=146`, `cosmetic_ui=0`.
- New objects included the **live** `WBP_GT_Test_C`, `CoherentUIGTWidget_Persistent_90`, audio wrapper, **16 `CoherentUIGTJSEvent` and 15 `CoherentUIGTJSPayload` UObjects**, plus 10 GT root-related objects in total.
- Snapshot 3: two JS event/payload additions and 31 removals (the initial transient event/payload batch largely disappeared), leaving `coherent=53`. Snapshots 4–6 showed `added=0 removed=0`. Snapshot 7 removed the last two transient event/payloads.
- The live `WBP_GT_Test_C` / `CoherentUIGTWidget_Persistent_90` view remained present through snapshots 3–7.
- **No native cosmetic UI instance** was detected by H32's targeted naming filter (`cosmetic_ui=0`); this is not proof none exists.

## Reflected metadata gives a practical next step

Native Coherent GT UClass signatures/property metadata:
- `CoherentUIGTComponent.URL`: **StrProperty**
- `CoherentUIGTSettings.CoUIResourcesRoot`: **StrProperty**
- `CoherentUIGTJSPayload.EventName`: **StrProperty**
- `CoherentUIGTBaseComponent`: methods `Load`, `Reload`, `TriggerJSEvent`, `CreateJSEvent`, `CreateDataModelFromObject`, and `CreateDataModelFromStruct`; delegates `JavaScriptEvent`, `ReadyForBindings`, `FinishLoad`, `StartLoading`.

H32 reflected names and types only. It **did not read actual URLs, resource root paths, event names, or JS payload contents**; no JS communication hooks were installed.

## Important uncertainty

The existence of an active CoherentGT view and ephemeral JS payload objects does **not demonstrate** that this specific view implements native skin ownership. The view is rooted at `BP_GameInstance_C.WBP_GT_Test_C`, and may serve an unrelated menu. No `MacrosCosmetic` ownership gate was identified.

## H33 plan

Perform **bounded, read-only property value inspection** for exactly those reflected string properties on live Coherent instances; also inspect the specific Coherent widget UClass and `WBP_GT_Test` metadata. Log only safe, short, non-sensitive event *names* (not payload arguments) and redact URLs if any contain query strings, credentials or account identifiers. Sample conservatively. No calls to `Load`, `Reload`, `TriggerJSEvent`, `GetString` on payloads, no hooks, no entitlement/loot/account actions.

H33 must retain F1 overlay, H25 A/B behavior and root-level ZIP layout, and explain that unlock is not yet implemented.

**Acceptance test for actual native unlock remains:** `Character.Player.Hinterclaw.MacrosCosmetic` visible and equippable through the vanilla cosmetics menu, with refresh/restart verification. Visual material swap alone is not sufficient.
