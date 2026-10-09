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
