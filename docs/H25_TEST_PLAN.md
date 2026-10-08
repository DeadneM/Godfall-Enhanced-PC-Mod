# Godfall H25 - Safe Material Restore test

## Why H25 exists
H24 succeeded at applying four Macros materials; the user log shows `H24_APPLY_OK changed=4 verified=4`. B crashed directly after locating live `CharacterMesh0`, before any reported SetMaterial success. The UE4 crash is EXCEPTION_ACCESS_VIOLATION (read 0x38) on GameThread. Original slots 0 and 1 were runtime `MaterialInstanceDynamic` and were stored as Lua userdata across calls. Such references are not proven safe against UE4 garbage collection.

## H25 changes
- Store string-only material restoration descriptors instead of raw UE4SS Lua UObject references.
- Inspect MID Parent chain while original MID remains attached, resolve stable asset parent names.
- Restore by reloading and resolving asset objects on demand; never dereference old MID Lua userdata during Method B.
- Resolve all four original/parent assets before writing anything.
- Fail closed when a stable asset cannot be resolved.
- Verify changes with GetMaterial; retain restoration descriptors for retries.
- Keep H23-compatible F11 A/B/C controls and all H23 loader binaries untouched.
- ZIP contents at archive root, NOT inside a version-named top-level folder.

## Important limitation
Restoring the parent material of a runtime MID is a safety fallback. It can restore the base material visually but may not preserve runtime scalar/vector parameter overrides. A completely identical appearance is NOT guaranteed. Re-equipping default Hinterclaw via the game's native UI should reinitialize runtime materials if needed.

## Test procedure
1. Back up existing Godfall Enhanced files and replace them from the H25 ZIP.
2. Start game, equip default Hinterclaw and stay in Sanctum.
3. Press F11, Method C to dump slots (optional).
4. Method A: verify Macros skin and `H25_APPLY_OK changed=4 verified=4`.
5. Method B ONCE: verify no crash and report whether normal appearance returns. Check `H25_RESTORE_OK` or `H25_RESTORE_REFUSED`.
6. Provide `GodfallEnhancedBridge.log` and crash report if any issue remains.

H25 is an UNVALIDATED test candidate and does not yet unlock or cycle through other skins. H23 remains canonical.
