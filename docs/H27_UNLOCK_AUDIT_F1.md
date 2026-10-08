# Godfall H27: Unlock acquisition discovery, F1 overlay TEST

## Findings from H26
- H26 completed a read-only reflection audit: 15 native classes, 92 functions, 7 properties, mutated=0.
- It found `APLocalPlayer::OnLootAcquired`, `APAction_Inventory_Add`, `APCosmeticsManager`, and SourceData APIs. This does **not** show an unlock path.
- Its inventory candidate limit was consumed by APAction wrappers. Reward/entitlement/profile group counts were zero because their class names did not directly include those words.
- H26 showed Macros material application on `CharacterMesh0`; that remains a **visual effect**, not an unlocked skin.

## H27 changes
1. **F1 overlay**: a single-byte binary patch of the **H23 ASI from the ZIP**, Windows virtual key constant `VK_F11 (0x7A)` to `VK_F1 (0x70)`. Specific sequence (original): `B9 7A 00 00 00 41 FF D7`, revised: `B9 70 00 00 00 41 FF D7`. No other ASI instruction changed. `dxgi.dll` unchanged. Source of the compiled ASI was not in this repository, so this patch is documented explicitly.
2. **Method C**: after the existing materials dump, collect and rank candidate `Class /Script/Aperion.*` UClasses by ownership, cosmetic, inventory, progression and player category, *excluding unrelated action-rule wrappers*. Read UFunction/property NAMES and bounded parameter metadata, without calling or hooking gameplay functions.
3. Retain original Method A apply and Method B safe restoration from H25, no save edits, no entitlement changes.
4. The ZIP has all files directly at archive ROOT.

## Test
- Back up prior mod files and extract H27 directly into directory containing `Aperion-Win64-Shipping.exe`.
- Launch, press **F1** (not F11) to open the overlay.
- Select **Method C ONCE** and send `GodfallEnhancedBridge.log` containing `H27_UNLOCK_AUDIT_END`.
- You may optionally test A and B to confirm H25 regression-free operation.
- Check whether F11 is no longer active and F1 toggles menu.
- If the scan is very slow or crashes, report the last `H27_CLASS` or `H27_FUNCTION` line. Do not repeatedly press C.

## Unimplemented features
`Unlock Gratitude` and `Unlock All` are **not** working features in H27. Discovering local inventory ownership state is a prerequisite; no attempt to write entitlement state or server rewards is included. H27 is an unvalidated discovery build, not a release.
