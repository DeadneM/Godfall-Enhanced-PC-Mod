# H24 - Verified Material Equip TEST

Built from the validated H23 Lua implementation. H23 binaries (dxgi.dll and GodfallEnhanced.asi) are unchanged in this test build.

## Target
Hinterclaw equipped with its normal/default appearance, F11 overlay:
- Method A: apply MacrosCosmetic via four material overrides.
- Method B: restore the saved original four materials.
- Method C: dump current material slots.

## Changes
- Preserve the initial original material snapshot across repeated Method A calls; repeat now logs H24_ALREADY_APPLIED.
- Read back and verify each SetMaterial change, instead of assuming a successful invocation changes the render material.
- Roll back all changed slots if any write or readback fails.
- Preserve originals for a Method B retry if rollback cannot be fully verified.
- Verify every restored material and retain recovery state on partial restore.
- Optional INI: VerboseVerification=0 hides only successful readback logs, never disables safety checks.
- H23 loader, ASI, F11 controls, asset paths, and command bridge remain unchanged.

## What is not yet implemented
This is not an automatic cosmetic selector. No new Valorplates/skins, save edits, entitlements, or backend access.

## Test
1. Start Godfall with default Hinterclaw. Open F11, select Method C (optional initial baseline).
2. Select Method A and check visible Macros appearance. Log must contain H24_APPLY_OK changed=4 verified=4.
3. Select Method A again; expect H24_ALREADY_APPLIED, no overwritten originals.
4. Select Method B; expect H24_RESTORE_OK restored=4 verified=4 and original appearance.
5. Select Method A and then B once again; both must work.

Do not publish H24 as a validated release until it is tested in game.
