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
