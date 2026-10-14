# Godfall Enhanced PC Mod

Experimental PC modding project for **Godfall**, focused on restoring or exposing locally shipped cosmetic content and building a clean in-game cosmetic selector without modifying backend entitlements or save ownership.

## Current validated base

**V0.6H23 - Exact Material Equip TEST** is the current validated development base.

H23 proves that a hidden cosmetic appearance can be applied locally by changing the live Valorplate mesh materials directly, bypassing the failed loadout/session ownership route.

Validated proof of concept:

- Valorplate: **Hinterclaw**
- Hidden local cosmetic: `Character.Player.Hinterclaw.MacrosCosmetic`
- Live component: `CharacterMesh0`
- Four material overrides are applied directly with Unreal `GetMaterial(index)` / `SetMaterial(index, material)`
- No entitlement patching
- No save editing
- No loadout/session mutation
- No global UE4SS hooks in H23
- Original four materials are captured and can be restored

### MacrosCosmetic material overrides

| Slot | Material |
| --- | --- |
| 0 | `MI_Macros_lower` |
| 1 | `MI_Macros_Fur` |
| 2 | `MI_Macros_Cloth` |
| 3 | `MI_Macros_Upper` |

The H23 validation log reported all four direct `SetMaterial` calls as successful and finished with:

```text
H23_APPLY_OK changed=4 target=Character.Player.Hinterclaw.MacrosCosmetic
```

## H24 test candidate (not yet validated)

**V0.6H24 - Verified Material Equip TEST** is staged on the development branch `dev/h24-safe-material-restore`. H23 remains the validated canonical base on `main`.

- H24 keeps the exact H23 `dxgi.dll` and `GodfallEnhanced.asi` from the validated H23 archive.
- Applies all four Macros materials with immediate `GetMaterial` readback checks.
- Repeated Method A cannot overwrite the first original material snapshot.
- Failed application attempts rollback and retains recovery state if rollback is incomplete.
- Method B verifies all four restored slots before discarding recovery state.
- An optional `GodfallEnhanced.ini` controls verbose verification logging only.

Download the development ZIP: [GodfallEnhanced_V0.6H24_VerifiedMaterialEquip_TEST.zip](releases/H24/GodfallEnhanced_V0.6H24_VerifiedMaterialEquip_TEST.zip).

See [H24 test plan](docs/H24_TEST_PLAN.md) for step-by-step in-game checks.

## H25 crash-safe restoration test (not validated)

**H25** is the next development candidate after H24. A user confirmed H24 Method A equipped MacrosCosmetic, but Method B caused an access violation while trying to restore original materials. The original snapshot contained two transient `MaterialInstanceDynamic` objects.

H25 avoids saving transient UObject pointers across asynchronous commands. It stores restorable asset descriptors; for transient materials, it uses the stable parent material as a fallback. Method B preflights all four assets before any `SetMaterial` call and refuses safely if any needed asset cannot be resolved.

**Caveat:** restoring a parent asset may not preserve runtime MID parameter overrides. Exact vanilla restoration still needs validation. This is a crash-recovery candidate, not a complete cosmetics menu.

[Download H25 test ZIP](releases/H25/GodfallEnhanced_V0.6H25_SAFE_RESTORE_TEST.zip) · [H25 test plan](docs/H25_TEST_PLAN.md)

Unlike H24, the H25 ZIP has files directly at the archive root, ready to extract into the game executable folder.

## H26 - Unlock discovery TEST (read-only)

**H26 is not yet an Unlock Gratitude/Unlock All feature.** It adds targeted diagnostics to determine what makes a catalogued cosmetic selectable in the native Godfall UI.

- **Method C** in the existing F11 overlay runs a read-only metadata audit after its original material dump.
- Logs capped `H26_CLASS`, `H26_FUNCTION`, `H26_PROPERTY` entries for cosmetics, inventory, rewards, entitlements, SourceData and local player.
- No mutating gameplay calls or broad tracing hooks. Method A and Method B are kept from H25.
- Existing H23 `dxgi.dll` / `GodfallEnhanced.asi` remain unchanged.
- The ZIP contains files at its root, ready to extract directly into the game directory.

[Download H26 test ZIP](releases/H26/GodfallEnhanced_V0.6H26_UNLOCK_AUDIT_TEST.zip) · [H26 usage and safeguards](docs/H26_UNLOCK_DISCOVERY_TEST.md).

Send the new `GodfallEnhancedBridge.log` after running Method C once. The next step is to use actual reflected names from the user's game to test a **single cosmetic's local unlock** before building Unlock Gratitude and Unlock All.

## H27 - Native Unlock Audit + F1 hotkey (TEST)

**Current test candidate:** [Download H27 root-level ZIP](releases/H27/GodfallEnhanced_V0.6H27_UNLOCK_AUDIT_F1_TEST.zip).

- **F1** toggles the overlay instead of F11. The original H23 ASI key check was patched from `VK_F11=0x7A` to `VK_F1=0x70`; exactly one byte changed. The `dxgi.dll` loader is unchanged.
- **Method C** now performs a broader, prioritized **read-only** reflection scan of Aperion ownership, cosmetics, inventory, progression, and player classes. It lists relevant function/property names and bounded parameter metadata.
- **Methods A/B** retain H25 apply/restore behavior; this is still only a visual material equip and not an actual unlock.
- **ZIP root layout:** `dxgi.dll`, `GodfallEnhanced.asi`, `GodfallEnhanced.ini`, `README.txt`, and `ue4ss/...` are immediately inside the archive.

Test: open overlay with **F1**, select **Method C once**, then share `GodfallEnhancedBridge.log` ending in `H27_UNLOCK_AUDIT_END`. The native cosmetic unlock ownership mechanism remains to be identified; **Unlock Gratitude and Unlock All are not implemented yet**. H27 has not been validated in game.

See [H27 technical notes](docs/H27_UNLOCK_AUDIT_F1.md). H23 remains the official base on `main`.

## H28 - Targeted Acquisition Path Audit (F1)

H27 successfully listed 90 candidate native classes, 360 functions and 116 properties. The high global function limit, however, was consumed by inventory and loot functions before `APLocalPlayer` functions could be examined.

**H28** restricts reflection to specific game classes, prioritizing player acquisition, cosmetic ownership and loot management, and reports parameter metadata without calling mutating functions.

- [Download H28 development ZIP](releases/H28/GodfallEnhanced_V0.6H28_ACQUISITION_AUDIT_F1_TEST.zip)
- [H28 investigation notes](docs/H28_ACQUISITION_PATH_AUDIT.md)
- F1 overlay preserved; H25 Methods A/B unchanged.
- Method C: read-only targeted audit, `H28_UNLOCK_AUDIT_END` in the log.
- Files at ZIP root; binaries identical to H27, including the F1 ASI patch.
- This is **not yet Unlock Gratitude or Unlock All**.

The most relevant H27 finding was `APLootManagerComponent::NotifyPlayerAcquiredLootWithoutRequest` with a `bPersistToAccount` parameter. No unverified account reward or server call has been made. The next step is to inspect the player's ownership state, not assume this function grants skins.

### H29 game test, 2026-10-09

**First run succeeded, but the test is incomplete:** [runtime log analysis](docs/H29_RUNTIME_LOG_ANALYSIS.md).

- `METHOD_A`: `H25_APPLY_OK changed=4 verified=4` for Gratitude `Character.Player.Hinterclaw.MacrosCosmetic`.
- `METHOD_C`: `H29_UI_AUDIT_END snapshot=1 objects=91 classes_inspected=14 functions=38 properties=9 mutated=0`.
- The reflected Sanctuary alcove `BP_ValorplateAlcove` has a `CosmeticTagToPlayerSkin` map and `SetValorplateCosmetic` function. This likely concerns appearance/alcove mapping and **does not yet prove ownership**.
- **Missing:** `snapshot=2` and `H29_UI_DIFF`, so the in-game cosmetics menu has not yet been compared to the baseline.
- Next step: run Method C once *outside* the native Hinterclaw skin menu, then once *inside* it **in the same session**, before sending the log. No need to download a different build.
- No native cosmetic unlock has been validated.

## H29 - Native Cosmetics Menu UI Trace (TEST)

H28 successfully completed its targeted audit of the player's functions, including `GetActiveEntitlements`, `GetAvailableEntitlements`, `GetPlayerSessionData`, `OnLootAcquired`, and `FetchPlayerData`. It did **not** find a verified native function that unlocks individual cosmetic skins. `UnlockAllValorplates` is *not* an Unlock All Cosmetics function. See [H29 investigation](docs/H29_COSMETIC_UI_TRACE.md).

**H29 changes the strategy** from generic native API dumps to an on-demand **before/after snapshot of the native cosmetics selection UI**. This aims to identify its widget/Blueprint classes and availability filtering.

[Download H29 test ZIP](releases/H29/GodfallEnhanced_V0.6H29_COSMETICS_UI_TRACE_F1_TEST.zip)

- F1 overlay preserved.
- Method A/B retain the H25 MacrosCosmetic application/restoration.
- Method C (or `UNLOCK_UI_AUDIT`) captures the current UI object snapshot. Run it once in Sanctum **before** entering the vanilla cosmetics screen, then again while that screen is open. The log will contain `H29_UI_DIFF` and `H29_UI_AUDIT_END`.
- No hooks, gameplay mutation, network/account entitlement spoofing or save editing.
- ZIP layout at root.
- H29 has **not yet been validated in game**, and it does **not** unlock Gratitude or all cosmetics.

## H30 - One-click automatic cosmetics UI monitoring (TEST)

This development build addresses H29's incomplete two-snapshot workflow. The latest H29 log showed only `H29_UI_AUDIT_END snapshot=1`, so no before/after menu comparison was obtained.

**Download:** [H30 test ZIP](releases/H30/GodfallEnhanced_V0.6H30_COSMETICS_AUTO_WATCH_F1_TEST.zip) | [full notes](docs/H30_AUTO_COSMETICS_UI_WATCH.md).

- F1 overlay and H25 Method A/B preserved; ASI and DXGI binaries are unchanged from H29.
- One press on **Method C** outside the original Hinterclaw cosmetics screen takes a baseline and arms the watcher.
- The watcher automatically performs read-only scans about every **12 seconds**, stopping after **20 scans** (roughly four minutes). No second C click.
- Open the vanilla cosmetics screen, leave it open **30-45 seconds** and send `GodfallEnhancedBridge.log` before game restart.
- Expected markers: `H30_UI_WATCH_ARMED`, `H30_UI_BASELINE_SAVED`, `H30_UI_DIFF`, `H30_UI_SCAN_END`.
- `UNLOCK_UI_AUDIT` in the bridge command file also arms the watcher; `STOP_UI_WATCH` ends it.
- Tests have verified ZIP structure, CRC and binary preservation, **not yet in-game operation**. Scans of 245k+ objects may briefly affect frame pacing.
- The known Gratitude skin `Character.Player.Hinterclaw.MacrosCosmetic` is still only proven by material swaps; native menu unlock, Unlock Gratitude and Unlock All remain unverified.

## H31 native UI/cosmetic skin catalog focus (unvalidated test)

The H30 user log confirms **six automatic snapshots** and a real object-load transition: **355 added** and later **349 removed**. Eight Hinterclaw skin Blueprint classes were observed in memory: Black, Damascus, Exalted, Ice, Lava, Red, Void and Yellow. The log has no proof that these cosmetics are owned, nor that MacrosCosmetic is absent from all content. See [H30 log evidence](docs/H30_RUNTIME_LOG_ANALYSIS.md).

**H31** fixes H30's alphabetic 45-entry logging truncation. It captures `UserWidget`, `WBP_` and cosmetic-menu class candidates, ranks them above combat widgets and logs up to 160 candidates plus dedicated widget/skin class events. H25 A/B and the F1 overlay binaries remain unchanged. Watch frequency is ~12 seconds, capped at 12 samples.

[Download H31 test ZIP](releases/H31/GodfallEnhanced_V0.6H31_NATIVE_UI_CATALOG_F1_TEST.zip) | [H31 technical notes](docs/H31_NATIVE_UI_CATALOG_FOCUS.md)

**Test**: outside the native Hinterclaw skin menu press F1 then C once, open the actual cosmetics screen for ~30–45 seconds, exit it, and send `GodfallEnhancedBridge.log` before restarting. Do not use A during this diagnostic. No native unlock, entitlement spoofing, network grant or save edit is included.

## H32 - Coherent GT frontend probe (TEST)

[Download H32 ZIP](releases/H32/GodfallEnhanced_V0.6H32_COHERENT_GT_FRONTEND_F1_TEST.zip) | [H31 actual runtime evidence](docs/H31_RUNTIME_LOG_ANALYSIS.md) | [H32 technical notes](docs/H32_COHERENT_FRONTEND_PROBE.md)

H31 completed five read-only snapshots; its live object-diff revealed `WBP_GT_Test_C`, `CoherentUIGTWidget_Persistent_90` and `CoherentUIGTAudioWrapper`, all attached to a live `BP_GameInstance_C`. This establishes use of a **Coherent UI GT component**, *not* that the native cosmetics screen uses it. H31 selected >42,000 widget-tree objects and did not identify MacrosCosmetic ownership or live menu eligibility.

**H32** narrows the watcher to Coherent GT, `WBP_GT_Test`, `WBP_Menu_Game` and cosmetics-related UI class/instance names. Method C once outside the skin menu starts read-only automatic snapshots every ~12 s for at most 10 samples. Open the vanilla Hinterclaw skin screen for 30–45 s, then send the log before restarting. H32 emits `H32_PROBE_COUNTS`, `H32_PROBE_DIFF` and bounded `H32_CLASS_META` signatures.

- Retains F1 overlay and H25 visual material A/B methods unchanged; binary dxgi/ASI preserved.
- Bounded metadata only, no JS execution, UI hooks, save, inventory or entitlement modification.
- ZIP built and structurally verified; **game test still pending**.
- `Character.Player.Hinterclaw.MacrosCosmetic` is confirmed Gratitude content; the native unlock is **not yet implemented**.

## H33 - Coherent GT runtime property values (TEST, not a cosmetic unlock)

The [H32 in-game log analysis](docs/H32_RUNTIME_LOG_ANALYSIS.md) confirms seven successful snapshots and a live `WBP_GT_Test_C` / `CoherentUIGTWidget_Persistent_90`, plus transient JS-event and JS-payload objects. Native Coherent metadata exposed `URL`, `CoUIResourcesRoot` and `EventName`, but H32 did **not** read their values.

**H33** adds guarded *read-only* property-value inspection for those three string fields. It logs event **names only**, redacts full URLs/absolute paths and does not read payload contents, execute JavaScript, hook views, or edit account/save/entitlement/inventory state. The scan is still bounded to 10 samples roughly 12 seconds apart.

[Download H33 cumulative test ZIP](releases/H33/GodfallEnhanced_V0.6H33_COHERENT_RUNTIME_VALUES_F1_TEST.zip) | [H33 instructions](docs/H33_COHERENT_RUNTIME_VALUES.md)

Installation: files are at archive root. Outside the normal Hinterclaw skins screen, press F1 then C **once**, enter that screen for about 30–45 seconds, and send `GodfallEnhancedBridge.log` before restarting. Markers include `H33_VALUE_SUMMARY`, `H33_VALUE`, `H33_TARGET_PROPERTY`, and `H32_PROBE_DIFF`.

F1 overlay, H25 Macros visual A/B methods, and ASI/DXGI binaries are unchanged. The ZIP's structure and CRC have been checked; **runtime H33 verification is still pending**. Neither `Unlock Gratitude` nor `Unlock All` exists yet.

## H34 React route/CDO probe (test, read-only)

[Download cumulative H34 test ZIP](releases/H34/GodfallEnhanced_V0.6H34_REACT_ROUTE_CDO_F1_TEST.zip) · [H33 runtime findings](docs/H33_RUNTIME_LOG_ANALYSIS.md) · [H34 technical notes](docs/H34_REACT_ROUTE_CDO_PROBE.md)

The H33 user log completed six clean read-only snapshots. It showed a live `UE_DATABRIDGE` Coherent JS event name and an HTTP-scheme Coherent URL (deliberately redacted). Crucially, `WBP_Menu_Game_C` exposes two `StrProperty` fields: `ReactSettingsURL` and `ReactCharacterSelectURL`. H33 did not read their values, so it cannot yet tell us whether these pages have anything to do with the native cosmetics selector.

**H34** tries guarded read-only `UClass:GetCDO()` / `GetPropertyValue()` on exactly those two React fields and `CoherentUIGTSettings.CoUIResourcesRoot`, while reporting only safe URL scheme/route-leaf information (not full URLs, user paths or accounts). It retains the Coherent event **name-only** diagnosis. No JS payload/arguments, interface invocation, account entitlement, inventory or save changes are performed.

A single **F1 → C** starts a baseline and at most four more ~12-second snapshots. Open the vanilla Hinterclaw cosmetics screen during the test and send `GodfallEnhancedBridge.log` before restarting. New markers: `H34_CDO_ROUTE` / `H34_CDO_FIELD_UNAVAILABLE` / `H33_VALUE field=URL_ROUTE`.

F1 overlay, H25 material A/B, ASI and DXGI binaries are preserved; ZIP root and CRC have been verified. **H34 is a game-test candidate, not an implemented Unlock Gratitude / Unlock All.**

## H34 in-game result – 2026-10-11

**Diagnostic validated in game; no cosmetic unlock.** In the supplied `GodfallEnhancedBridge(7).log`, the correct H34 Lua bridge ran and four read-only snapshots completed without fatal errors. The `WBP_Menu_Game_C` **class-default values** were captured: `ReactSettingsURL = settings` and `ReactCharacterSelectURL = character-select`. The `UE_DATABRIDGE` event name recurred. The Coherent view also reported a non-loopback HTTP URL category, but no raw hostname/path was recorded. These values **do not yet identify** a cosmetic ownership filter.

[Detailed H34 runtime analysis](docs/H34_RUNTIME_LOG_ANALYSIS.md).

**Decision:** no further generic UObject audits. Before building H35, locate/inspect the game's actual React/frontend resources or the relevant cooked menu Blueprint and bridge calls to find the skin eligibility lookup for `cosmetics/collection`. The repo does not contain the original React asset bundle. H23 remains the validated visual proof of concept; H34 is now a runtime-verified **diagnostic**, not a native unlock.

## H35: offline frontend resource discovery (EXPERIMENTAL)

**Download:** [Godfall Enhanced V0.6H35 complete ZIP](releases/H35/GodfallEnhanced_V0.6H35_OFFLINE_FRONTEND_LOCATOR.zip) | [Technical plan and limitations](docs/H35_OFFLINE_FRONTEND_LOCATOR.md)

H34 was tested successfully: the `WBP_Menu_Game_C` CDO exposed **ReactSettingsURL = settings** and **ReactCharacterSelectURL = character-select**, while `UE_DATABRIDGE` appeared as a Coherent UI GT event name. That does **not** demonstrate the original cosmetics menu's entitlement/ownership gate.

To break the H26–H34 cycle of general UObject scans, H35 adds a **separate offline, local-only resource locator**. It inventories the installation's package names and likely loose frontend/React files, and searches small frontend text files for known marker **names only**. It writes `GodfallFrontendAssetsReport.txt` using relative game-installation paths, never uploading anything automatically or reading saves, backend data, JavaScript payloads or credentials.

**Test:** close Godfall, extract all ZIP contents beside `Aperion-Win64-Shipping.exe`, double-click **`Run_GodfallFrontendLocator.cmd`**, then send the generated `GodfallFrontendAssetsReport.txt` in the chat. The CMD uses a temporary process-level PowerShell execution-policy bypass (no permanent settings changes); inspect the included `.ps1` source if desired. No need to retest F1 → C just for H35.

H35 preserves the **H34 Lua behavior**, existing A/B H25 materials, F1 overlay, and the unchanged ASI/DXGI binaries. Only the boot marker is updated to `H35_BOOT_MARKER=OK`. The ZIP structure and CRCs were checked; **the locator has now run successfully on the user's Windows installation** (see confirmed result below).

### H35 confirmed result (2026-10-11)

The user ran the H35 offline locator successfully. It identified **23 packaged IoStore-related files** (`global.ucas/.utoc` and `pakchunk0..6` each with `.pak/.utoc/.ucas`) and **zero loose frontend assets or text files**. No game data were modified; no React/Coherent frontend code was extracted.

**Next milestone:** inspect *package paths* using FModel and export only a focused `WBP_Menu_Game` / character-select / cosmetic metadata subset if accessible. The H34 non-loopback HTTP Coherent view remains a separate hypothesis: the bundled archives are not yet proven to contain the React UI. [Exact results and method](docs/H35_RUNTIME_RESULT_AND_FMODEL_NEXT.md).

### H35 FModel exports received

User-provided exports of `WBP_Menu_Game` (227 JSON objects) and `BP_Hinterclaw_MacrosCosmetic` (28 exported objects) were parsed. The **exact** menu CDO values are `ReactSettingsURL=esc-menu/settings` and `ReactCharacterSelectURL=character-select`. Generated Unreal function metadata references `DataBridgeOutgoingRequest` and JSON promise data, but does not expose request payloads or a cosmetic ownership check. The Macros Blueprint confirms the `Character.Player.Hinterclaw.MacrosCosmetic` GameplayTag and four mesh materials only.

**Next targeted input:** FModel JSON export of `BP_ValorplateAlcove`, because earlier runtime evidence found `CosmeticTagToPlayerSkin` there. No H36 build is justified solely from these two exports. [Complete evidence and follow-up](docs/H35_FMODEL_EXPORTED_ASSET_ANALYSIS.md).

**Unlock status:** `MacrosCosmetic` is still visually applied only; `Unlock Gratitude` / `Unlock All` are not implemented.

## H36: live Valorplate Alcove cosmetic map (EXPERIMENTAL)

**[Download H36 ZIP](releases/H36/GodfallEnhanced_V0.6H36_ALCOVE_MAP_READONLY_F1_TEST.zip)** · [FModel findings / method / safety](docs/H36_ALCOVE_MAP_AUDIT.md)

The user's focused FModel JSON export of `BP_ValorplateAlcove` (44 records, 37 functions) confirms an **editable `CosmeticTagToPlayerSkin` MapProperty** of `GameplayTag → SoftClass<BP_Player>`, plus the `SetValorplateCosmetic` Blueprint event signature. The class default object contains **no map values**, so we cannot infer the mapping for the placed Sanctum alcoves.

**H36 specifically answers that question.** Method **F1 → C** now performs a one-shot, read-only `FindAllOf("BP_ValorplateAlcove_C")` and guarded `TMap:ForEach` on any live instances, logging counts and only relevant Hinterclaw/Macros/Gratitude tags. No `SetValorplateCosmetic` calls, entitlement changes or saved-state mutations. **Do this only after entering the Sanctum and completing all loading.** Return `GodfallEnhancedBridge.log` before restarting.

The existing H25 A/B visual method, F1 overlay, H34 Coherent watcher (manual `COHERENT_PROBE` command), H35 offline frontend locator, `GodfallEnhanced.asi` and `dxgi.dll` are preserved. Archive layout and CRCs checked, binaries and H35 locator byte-identical. **Not yet tested in game.** It is still a diagnostics-only mod, **not** an unlocker.

### H36 user runtime evidence – 2026-10-12

**H36 was successfully tested in the user's Sanctum** (`H36_BOOT_MARKER=OK`; `METHOD_C`). All 12 placed `BP_ValorplateAlcove_C` actors had readable maps, totaling **126 entries**; the **Hinterclaw** alcove held exactly **9** entries: Black, Yellow, Ice, Void, Damascus, Red, Pearl, Lava, and Exalted. **The locally shipped `Character.Player.Hinterclaw.MacrosCosmetic` was absent from this particular alcove map.** The 9 soft-class values were still not decoded (`SOFTCLASS_UNRESOLVED`). `H36_ALCOVE_AUDIT_END ... mutated=0`.

This is a promising *presentation mapping difference*, but there is no proof that `CosmeticTagToPlayerSkin` controls the original owned-skins menu. No unsafe `TMap:Add` or `SetValorplateCosmetic` experiment has been done. Next: trace the specific map consumer/Blueprint graph before any runtime mutation. [Detailed H36 log findings](docs/H36_RUNTIME_RESULT.md).

## H37: multi-probe after H36 (experimental)

**[Download H37 cumulative ZIP](releases/H37/GodfallEnhanced_V0.6H37_ALCOVE_SOFTCLASS_UI_MULTIPROBE_F1_TEST.zip)** | [Detailed H37 test plan and limits](docs/H37_MULTI_PROBE_PLAN.md)

Following the successful H36 Sanctum map read (12 alcoves, 126 actor mappings, 9 Hinterclaw entries, **no MacrosCosmetic key**), H37 bundles three **different targeted read-only probes**, rather than another general UObject scan:

- **SoftClass decoding:** tests guarded getter paths on the nine class references H36 could not decode (`H37_SOFTCLASS`).
- **Actual actor class metadata:** enumerates only filtered reflected function/property names for the loaded Hinterclaw alcove (`H37_CLASS_AUDIT_END`).
- **Vanilla menu comparison:** `F1 → C` the **first time** in a loaded Sanctum performs the grouped map probe and UI baseline; after opening the *original* Hinterclaw cosmetics screen, a **second** `F1 → C` records the UI widget presence again (`H37_UI_SNAPSHOT_END sample=1/2`), avoiding a second alcove-map scan.

No `TMap:Add/Remove`, `SetValorplateCosmetic`, saved-state changes, entitlement or server calls are made. H25 visual A/B, H34 Coherent watcher manual command, H35 offline locator, F1 overlay and **unchanged ASI/DXGI binaries** remain in the ZIP. The archive structure and CRCs were checked, but **H37 has not yet run on the user's PC**. No native cosmetic unlock has been demonstrated.

## H38: Live Coherent GT widget, targeted test (experimental)

**[H38 cumulative ZIP](releases/H38/GodfallEnhanced_V0.6H38_GT_COHERENT_WIDGET_F1_TEST.zip)** · [H38 technical notes](docs/H38_GT_WIDGET_COHERENT_PROBE.md) · [H37 actual user runtime evidence](docs/H37_RUNTIME_RESULT.md)

The user's H37 log completed two sequential UI snapshots. **`WBP_GT_Test_C` was absent in the Sanctum baseline and present with the original Hinterclaw cosmetics screen open**, while `WBP_Menu_Game_C` remained absent in both. All nine Hinterclaw alcove-map value paths still reported `TSoftObjectPtrUserdata path=UNRESOLVED`. This is evidence that a Coherent/GT frontend host *loads in association with the original cosmetics view*, **not** proof of the skin ownership filter.

**H38 F1 → C** performs a narrow read-only check of that active `WBP_GT_Test_C`: selected class function/property names and types, and carefully sanitized Coherent view URL categories and parent relationships. The first C press, before opening original skins, is the baseline; the second, after opening the skin selector, reads the active widget. The prior 12-alcove scan remains accessible by a manual `ALCOVE_MAP_AUDIT` command but is no longer triggered by C.

The archive retains the H25 A/B material controls, F1, H35 offline locator and byte-identical `GodfallEnhanced.asi`/`dxgi.dll`. ZIP entries and CRCs were checked. **H38 has not yet been tested in game**. No `TMap` mutations, JS event injections, saves or server/account entitlement changes.

## H39: Coherent persistent child audit (experimental)

**[Download H39 ZIP](releases/H39/GodfallEnhanced_V0.6H39_COHERENT_PERSISTENT_CHILD_F1_TEST.zip)** · [H39 test plan](docs/H39_COHERENT_CHILD_PROBE.md) · [H38 verified user result](docs/H38_RUNTIME_RESULT.md)

H38 was tested in-game on 2026-10-14. It confirmed `WBP_GT_Test_C` becomes present when the vanilla Hinterclaw skins screen opens and has a `CoherentUIGTWidget_Persistent_90 : ObjectProperty` with a live Coherent child referenced by the host (H39 later shows its direct `GetOuter()` does not match that host). Its only relevant host functions are `GetCoherentUIGTWidget` and `ToggleBgBlurWidget`. H38 yielded **no useful native cosmetics/ownership function or frontend URL**.

H39 follows the **specific child object** referenced by that property, not thousands of arbitrary Unreal objects. **F1 → C** first outside the original skins menu and again inside it reports direct child relationship, bounded inherited class metadata and any **sanitized URL/resource name**. It does not invoke the `GetCoherentUIGTWidget` method or call JS.

The ZIP preserves the H25 visual A/B, F1 overlay, H35 offline locator, existing ASI/DXGI binaries and manually accessible previous probes. Integrity checked, but **H39 not yet tested in game**. No native skin unlock has been implemented. If this child only exposes generic Coherent plugin APIs, investigate FModel `WBP_GT_Test` / the actual UI data source instead of further class reflection.

### H39 confirmed in-game, 2026-10-14

**User log received and analyzed:** H39 boot marker verified, two read-only C tests completed, and the original skins-menu view again contained `WBP_GT_Test_C`. Its `CoherentUIGTWidget_Persistent_90` object property **resolves**, although `GetOuter()` is not directly the host UObject (`direct=0`).

The targeted child exposes only generic Coherent GUI support: `Load`, `Reload`, `IsDocumentReady`, `OnUIGTScriptingReady` and delegates such as `ReadyForBindings` and `JavaScriptEvent`. **No URL, skin inventory, ownership check, cosmetic list or availability filter was recovered.** `H39_CHILD_PROBE_END status=completed mutated=0`, without logged fatal errors.

**Decision:** Stop the H29–H39 class-reflection lineage; H40 is **not** justified as another reflection build. Next target: user’s **FModel JSON export of `WBP_GT_Test`** or actual discovered frontend JS/UI resources, to find the real original-menu cosmetics query. Do **not** modify the `BP_ValorplateAlcove` map or account entitlements merely because it omits the local `MacrosCosmetic` tag. [Detailed H39 in-game analysis](docs/H39_RUNTIME_RESULT.md).

### H39 FModel follow-up: WBP_GT_Test asset export analyzed (2026-10-14)

The user provided a complete FModel JSON export of `WBP_GT_Test` (**14 cooked Unreal objects**). It confirms `WBP_GT_Test_C` directly extends **`WBP_GT_Settings_C`** (`/Game/Aperion/Blueprints/UI/WBP_GT_Settings`); its `GetCoherentUIGTWidget` function names an ancestor signature in **`WBP_GT_Base_C`** (`/Game/Aperion/Blueprints/UI/WBP_GT_Base`). The exact full parent chain must be confirmed by exporting `WBP_GT_Settings`.

The Coherent child's `Outer` is **`WidgetTree'WBP_GT_Test_C:WidgetTree'`**, explaining the H39 `direct=0` result (the property is valid, but child is not directly outered to the host UObject). The export contains only a few host/layout/blur widgets and **no concrete cosmetics eligibility data or frontend URL**.

**Next requested artifacts:** only the **FModel JSON exports** of `WBP_GT_Settings` and `WBP_GT_Base`. No H40 build until they reveal a testable new path. [FModel export analysis](docs/H39_FMODEL_WBP_GT_TEST_EXPORT.md).

## H40: DataBridge request TYPE-only experiment (experimental)

**[Download cumulative H40 ZIP](releases/H40/GodfallEnhanced_V0.6H40_DATABRIDGE_REQUEST_TYPE_F1_TEST.zip)** | [Exact FModel findings and risk controls](docs/H40_DATABRIDGE_TYPE_PROBE.md)

Two FModel JSON exports supplied on 2026-10-14 resolved the full host inheritance: `WBP_GT_Test_C → WBP_GT_Settings_C → WBP_GT_Base_C → WBP_UserWidget_C`. `WBP_GT_Base_C` defines `OnDataBridgeIncomingRequest(Type: FString, Payload: JsonObjectWrapper, Promise: PromiseHandle)`, and `WBP_GT_Settings_C` overrides it to manage video/input settings. Base also exposes `CoherentUIGTInput`, `TargetURLReadyForBindings`, `IsTargetURLReadyForBindings`. **No file exposed cosmetic eligibility logic or entitlement checks.**

This constitutes a **new, exact, testable hook target** after the inconclusive generic H29–H39 widget scans. H40 **F1 → C**, only after entering the original Hinterclaw skins UI, manually registers at most two exact UE4SS Blueprint UFunction hooks on the base/settings `OnDataBridgeIncomingRequest` methods, reading **only sanitized request `Type` names**, never payload, promise, account, URL or JS data. All callbacks return nil and original native behavior remains unchanged. Hooks automatically unregister after up to **48 matching calls or ~90 seconds**, or via second C.

**Test:** back up H39, install H40 ZIP to the game EXE directory preserving `ue4ss/`, restart; enter the original Hinterclaw skins screen, press **F1 → C** once, close overlay and navigate three or four normal skins, then press **F1 → C** again. Send `GodfallEnhancedBridge.log` before restart. `H40_BRIDGE_HOOK_OK` and `H40_BRIDGE_TYPE` are the main observations.

**Risk:** a narrowly scoped UFunction hook still has nonzero crash/compatibility risk on the user's UE4SS build (H20 broad hook tests previously crashed). If there is a crash, return to H39; do not repeatedly run a crashing path. An unavailable hook or zero events is useful negative evidence, **not proof no DataBridge requests exist**.

The archive preserves H25 A/B materials, F1, previous manually accessible diagnostics, H35 offline locator, and byte-identical original ASI/DXGI binaries. Archive integrity/CRC checked on GitHub; **H40 not yet tested on the user's PC**. The native `MacrosCosmetic` unlock is still not implemented.

### H40 actual user test (2026-10-14): hooks registered, run incomplete

The received 16-line user log confirms `H40_BOOT_MARKER=OK`; first C was too early (`GT_TEST_NOT_LOADED`), but a second C **registered both BASE and SETTINGS hooks** (`H40_BRIDGE_ARMED hooks=2`). **No `H40_BRIDGE_TYPE` or `H40_BRIDGE_STOP` is in the file.** Neither a completed zero-event result, automatic cleanup, nor a game crash can be inferred. The inherited `H24_NO_HOOKS=TRUE` startup banner is stale when H40's optional hooks are active.

**Next step:** determine if the game crashed after the second C. If so, roll back to H39 and do not repeat the hook test. If not, capture a complete manual start/stop test and supply the resulting log before the next restart. Do not broaden the hook scope or build H41 without this evidence. [Full H40 runtime result and source audit](docs/H40_RUNTIME_RESULT.md).

## H41: single-hook DataBridge timeline (experimental)

**[Download cumulative H41 ZIP](releases/H41/GodfallEnhanced_V0.6H41_SINGLE_DATABRIDGE_EVENT_TRACE_F1_TEST.zip)** · [H41 test details](docs/H41_SINGLE_HOOK_EVENT_TRACE.md) · [H40 second user log findings](docs/H40_RUNTIME_RESULT_SECOND_TEST.md)

The user's follow-up H40 test on an armor with owned skins finally recorded real UI→Unreal DataBridge **Type** events, including `UE_ROUTE_UI`, `UE4_SHOW_LOADOUT_VISUAL_REQUEST`, `UE4_HIDE_LOADOUT_VISUAL_REQUEST`, `UE4_SHOW_LOADOUT_WEAPON_VISUAL_REQUEST`, `UE4_PLAY_AUDIO_CUE` and `UE4_PLAY_MUSIC`. The first monitoring window reached **48 hits** and ended with **`unregistered=2 errors=0`**. It registered a second window before the 4,234-byte log ended, so that later cleanup is unconfirmed. The two BASE/SETTINGS streams are nearly identical and appear to consume the event cap too quickly.

**H41**, available only on experimental branch `dev/h41-single-hook-event-summary`, now arms **one** proven UFunction (`WBP_GT_Base_C:OnDataBridgeIncomingRequest`) only with F1 → C while the original skin menu is open. It captures up to **160 callbacks or 90 seconds**, logs the sanitized event order, and summarizes counts by Type on stop. No request Payload/Promise or account/save state is touched, and no original Unreal return value is overridden. The startup status message correctly says hooks are **optional on C** instead of falsely stating no hooks.

The install-ready ZIP retains F1, H25 A/B visual apply/restore, H35 offline locator and byte-for-byte original `GodfallEnhanced.asi` and `dxgi.dll`. All 13 ZIP entries and stored CRCs were checked; **H41 still needs in-game user testing**. Its existence is **not** evidence of a native `MacrosCosmetic` unlock.

## H44: four separate hotkeys, no auto-chain (EXPERIMENTAL)

**[Download H44 cumulative ZIP](releases/H44/GodfallEnhanced_V0.6H44_FOUR_INDEPENDENT_TRIGGERS_TEST.zip)** · [Complete key mapping, known hazards, rollback](docs/H44_FOUR_INDEPENDENT_TRIGGERS.md)

**H43 CRASHED** in the user's GameThread (`UE4SS+0x3E60BE`). H44 was **rebuilt from H41**, not the crashing H43 native sequence. Instead of one Method C call chaining four dangerous operations, it registers **four independent keys**:

- **F6:** the validated H25 visual Macros material swap only
- **F7:** Hinterclaw Alcove `CosmeticTagToPlayerSkin` map insertion attempt only (high risk: Unreal `SoftClass` argument not validated)
- **F8:** `APCosmeticsManager::AddCosmeticOverride` attempt only (high risk: native struct conversion not validated)
- **F9:** `SetValorplateCosmetic` Alcove preview attempt only (high risk: native Blueprint argument types not validated)
- **F10:** best-effort rollback of H44 map/override/material changes; no exact native Alcove preview undo exists

**F1 C now displays help only**, and does not call native experimental operations. Original F1 A/B H25 material apply/restore still work. If keys are intercepted or unavailable, enter `H44_VISUAL`, `H44_MAP`, `H44_OVERRIDE`, `H44_PREVIEW`, or `H44_REVERT` in the existing `ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt`.

A per-key `H44_TRIGGER` and per-native-call `H44_NATIVE_BEGIN` is written *before* executing the risky operation, so the latest log shows which key was active if a native crash happens. Each operation executes only when its own hotkey or explicit manual command is used, on the game thread. **Test F6 first and do not press F7/F8/F9 together**. `pcall` cannot prevent C++ access violations. If a key crashes the game, don't retry that key. H44 is **not a native unlock** and not a safe/stable release.

The 13-entry ZIP has verified CRCs and preserves the H41 `GodfallEnhanced.asi`, `dxgi.dll`, H35 locator, and H25 A/B. Main unchanged, H44 not yet tested in-game.

## H45: cooked Macros Blueprint and native tag compatibility repair (EXPERIMENTAL)

**[Download H45 cumulative ZIP](releases/H45/GodfallEnhanced_V0.6H45_NATIVE_ASSET_TAG_F6_F9_TEST.zip)** · [H45 engineering notes and hazards](docs/H45_ASSET_TAG_REPAIR.md) · [H44 actual user log result](docs/H44_RUNTIME_RESULT.md)

The **real 142-line H44 game log** validated F6 visual Macros twice and F10 restore once, but **F7/F8 never called their experimental native methods** because `BP_Hinterclaw_MacrosCosmetic_C` was not resolved; **F9 never called its native method** because global `FName` was absent in this UE4SS setup.

H45 fixes both observed blockers while **retaining F6/F7/F8/F9 and F10 as separate opt-in hotkeys**. The Macros Blueprint path was independently verified by the user's cooked FModel export. UE4SS `StaticFindObject(string)` expects an unprefixed Unreal object path, not the `BlueprintGeneratedClass ` prefix incorrectly used in H44. H45 uses that documented form, short-name lookup and three FModel-grounded `LoadAsset` forms, and checks the true cooked CDO `GameplayTag`. **F9** uses the actual native CDO tag instead of constructing a tag through unavailable global `FName`. **F8** uses the validated CDO tag's native FName for the request ID; that could conflict with an existing request with the same name, so remains high risk and manual only.

F7 and F8 also remain high native-risk operations: `TSoftClassPtr` map value and `FGameplayTagContainer` argument marshalling are not yet proven, and a `pcall` cannot contain a native C++ access violation. **Do not retest a crashing key**. F9 is the first separate trial worth considering because its documented Blueprint signature is two parameters (`FString`, `FGameplayTag`), but it can still fail or crash and is an **Alcove preview**, not a native owned skin.

Archive verified (13 entries / CRCs); original H41/H44 `GodfallEnhanced.asi`, `dxgi.dll`, H35 locator, and H25 F1 A/B visual methods unchanged. No automatic native mutation on game start or F1 C. `main` unchanged. **H45 is published but not yet in-game validated; native Macros unlock is not achieved.**

## Installation

1. Open the Godfall executable directory, normally the directory containing `Aperion-Win64-Shipping.exe`.
2. Extract the contents of the H23 test archive into that directory while preserving its `ue4ss` folder structure.
3. Start Godfall.
4. Equip the normal/default Hinterclaw appearance.
5. Press **F11** to open the current development overlay.
6. In H23, **Method A** applies the MacrosCosmetic materials.
7. **Method B** restores the four materials captured before applying the cosmetic.
8. **Method C** dumps the current material slots for diagnostics.

The A/B/C labels are temporary development controls and will be replaced by a proper Cosmetics UI.

## Download

The validated development archive is stored in:

`releases/H23/GodfallEnhanced_V0.6H23_ExactMaterialEquip_TEST.zip`

## Project direction

The next phase is to generalize the successful H23 method:

- enumerate every Valorplate cosmetic from `cosmetics/collection`
- map each cosmetic Blueprint to its material and mesh overrides
- detect the currently equipped Valorplate automatically
- expose hidden/local cosmetics through a simple F11 **Cosmetics** menu
- add an **Equip** button and reliable **Restore Original Cosmetic** action
- keep diagnostics in a collapsed **Advanced / Debug** section

The long-term goal is a clean local cosmetic utility, not an entitlement spoofer.

## Important discoveries

The local SourceData catalog contains **163 cosmetic entries**. The observed distribution during research was:

- 124 Valorplate cosmetics
- 26 weapon cosmetics
- 7 banners
- 6 spectral weapon cosmetics

Hidden and ordinary cosmetics coexist in the same local collection. The SourceData rows observed for cosmetics expose `gameplayTag`, `forGameplayTag`, and `cosmeticClass`; the hidden/owned filtering therefore happens downstream of the catalog.

For Hinterclaw, locally shipped variants discovered include:

- `Character.Player.Hinterclaw.Black`
- `Character.Player.Hinterclaw.Damascus`
- `Character.Player.Hinterclaw.Exalted`
- `Character.Player.Hinterclaw.Ice`
- `Character.Player.Hinterclaw.Lava`
- `Character.Player.Hinterclaw.MacrosCosmetic`
- `Character.Player.Hinterclaw.Pearl`
- `Character.Player.Hinterclaw.Red`
- `Character.Player.Hinterclaw.Void`
- `Character.Player.Hinterclaw.Yellow`

See [`docs/TECHNICAL_NOTES.md`](docs/TECHNICAL_NOTES.md) for the research history and rejected approaches.

## Source

The exact H23 UE4SS bridge source is under:

`src/GodfallEnhancedBridge/main.lua`

The current `GodfallEnhanced.asi` and `dxgi.dll` are included as validated binaries in `releases/H23/`. Their matching C/C++ source was not present in the current working set, so no synthetic or approximate source has been published.

## Compatibility target

Validated executable during this research:

- `Aperion-Win64-Shipping.exe`
- Size: `112,827,392` bytes
- SHA-256: `301f90fc4f6119b64f7ef51971f6083264c4f4878500f5cd52341e4eb673b834`

## Status

This repository is currently a **development / reverse-engineering project**. H23 is a validated proof of concept, not yet a polished public release.
