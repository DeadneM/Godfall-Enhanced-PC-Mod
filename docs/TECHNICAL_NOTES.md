# Technical Notes

## Goal

Expose and apply locally shipped Godfall cosmetics that may be absent from the normal cosmetic menu, while staying entirely local/client-side.

The project does **not** attempt to fabricate SHiFT/EOS entitlements, redeem server rewards, or alter backend ownership.

## Executable target

`Aperion-Win64-Shipping.exe`

- Size: `112,827,392` bytes
- SHA-256: `301f90fc4f6119b64f7ef51971f6083264c4f4878500f5cd52341e4eb673b834`

## Entitlement experiments

Two obvious gates were identified and tested:

- `APLocalPlayer::HasEntitlement`
- `APCosmeticsManager::IsCosmeticEnabled`

Forcing both gates to true did **not** make hidden skins appear in the vanilla cosmetic UI. This proved those functions were not the final downstream catalog/ownership filter.

The runtime entitlement audit also showed the Godfall entitlement layer reporting only the Deluxe entitlement (`GODFALLDELUXE000`) in the tested environment, while hidden cosmetics were still physically present in local data.

## SourceData breakthrough

Godfall exposes reflected SourceData APIs including:

- `GetSourceDataCollectionAllKeyExists`
- `GetSourceDataCollectionAllKeyValueMatches`
- `GetSourceDataCollectionBestGameplayTagMatch`
- `GetSourceDataCollectionBestKeyValueMatch`

The important local collection is:

`cosmetics/collection`

Querying it by `gameplayTag` returned **163 entries**.

Observed distribution:

- Valorplates: 124
- Weapons: 26
- Banners: 7
- Spectral weapons: 6

Each cosmetic row observed contained only:

- `gameplayTag`
- `forGameplayTag`
- `cosmeticClass`

No explicit hidden, entitlement, ownership, requirement, or unlock field was found in those rows. Hidden/owned filtering therefore occurs after the local SourceData catalog is built.

## Loadout branch, H9-H19

The next approach attempted to reproduce the cosmetic through Godfall's loadout/session path.

Important reflected functions included:

- `GetLoadoutCharacterString`
- `GetLoadoutString`
- `UpdateLocalPlayerLoadoutFromJson`
- `CreateLoadoutCharacter`
- `AssembleLocalPlayerLoadoutCharacter`
- `AssembleLocalPlayerLoadout`
- `AssembleLoadoutFromJson`
- `SetPlayerSessionLoadoutCharacter`
- `SetNeedsReassembleLoadoutCharacter`

A vanilla applied cosmetic was confirmed to change both the root character `gameplayTag` and `cosmetics.valorplates["0"]` in the character JSON when an explicit skin was present.

For a default Valorplate appearance such as default Hinterclaw, no explicit `cosmetics.valorplates["0"]` entry existed, requiring insertion when testing JSON modification.

The JSON patching eventually worked, but the live player state repeatedly reverted or rejected the modified loadout. Further calls then became dominated by complicated Unreal struct requirements (`LoadoutCharacter`, `FTransform`, `UniqueNetId`, world context, assemble modes). This branch was abandoned after H19 because it was not converging on a stable cosmetic equip path.

## Vanilla tracing branch, H20

H20 attempted broad native tracing to observe a working vanilla Chrome -> Gold cosmetic change.

This approach was abandoned immediately because the broad UE4SS hook set destabilized the game and produced a GameThread access violation. Broad tracing is therefore considered unsafe for this project.

## Direct visual branch, H21-H23

A cooked Blueprint dump showed that `BP_Hinterclaw_MacrosCosmetic_C` is a real local child of `BP_Hinterclaw_C`, with gameplay tag:

`Character.Player.Hinterclaw.MacrosCosmetic`

The hidden Blueprint reuses the normal Hinterclaw skeletal mesh but overrides four materials on `CharacterMesh0`:

1. `MI_Macros_lower`
2. `MI_Macros_Fur`
3. `MI_Macros_Cloth`
4. `MI_Macros_Upper`

The normal Hinterclaw uses `SK_Hinterclaw`, so this gave a much simpler local path: modify the materials of the already-live `CharacterMesh0` instead of asking the ownership/loadout system to respawn a different class.

### H21

Found the live mesh successfully, but the initial reflected paths for `GetMaterial` and `SetMaterial` were wrong. No material operation actually occurred.

### H22

Walking the class hierarchy worked, but the resolver performed partial-name matching and incorrectly chose `GetMaterialSlotNames` and `SetMaterialByName` instead of the exact target functions.

### H23 - validated

H23 uses exact-name resolution and direct UE4SS dynamic dispatch on the live `CharacterMesh0`:

- `GetMaterial(index)`
- `SetMaterial(index, material)`

It first captures slots 0-3 for restoration, loads the four Macros material assets, applies all four, and reports success only if all four calls complete.

The successful validation log contained:

```text
H23_SET_DIRECT_OK slot=0 mat=...MI_Macros_lower
H23_SET_DIRECT_OK slot=1 mat=...MI_Macros_Fur
H23_SET_DIRECT_OK slot=2 mat=...MI_Macros_Cloth
H23_SET_DIRECT_OK slot=3 mat=...MI_Macros_Upper
H23_APPLY_OK changed=4 target=Character.Player.Hinterclaw.MacrosCosmetic
```

The cosmetic change was also visually confirmed in game.

H23 is therefore the current canonical development base.

## Current design direction

Do not return to the H10-H20 loadout/session architecture unless new evidence specifically requires it.

Build from H23 instead:

1. Detect the current Valorplate.
2. Enumerate its cosmetics from `cosmetics/collection`.
3. Resolve each local cosmetic Blueprint/CDO.
4. Extract the visual overrides required by that cosmetic.
5. Apply those overrides directly to the live Valorplate components.
6. Store enough original state for exact restoration.
7. Present the result through a small F11 Cosmetics UI.

## Stability rules learned

- Avoid broad `RegisterHook` tracing across large function sets.
- Avoid deep unrestricted UObject traversal.
- Prefer narrow reflected calls and fail-soft checks.
- Do not mutate backend entitlement or SHiFT/EOS reward data.
- Keep cosmetic application local and reversible.
