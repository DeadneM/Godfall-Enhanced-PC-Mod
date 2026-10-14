# H43: fix H42 early abort and try independent native cosmetic paths

## Actual H42 user test, 2026-10-14
The user-provided `GodfallEnhancedBridge(20261014-172923).log` (14 lines / 1,174 bytes) shows `H42_BOOT_MARKER=OK`, followed by two identical `METHOD_C` commands. Both aborted at `H42_TARGET status=NO_MACROS_CLASS` and `H42_PRECHECK_FAIL reason=NO_VALID_MACROS_ASSET`. **No part of the four-path H42 runtime experiment executed**, and no crash was logged. The result does not invalidate H23/H25's separately proven material overrides.

### Engineering mistakes in H42
1. A single `h42_target()` class load/lookup gate aborted the whole suite before `apply_macros()` ran, including a path already proven to work.
2. `h42_target()` discarded the `LoadAsset()` return value and only tried `StaticFindObject()` on a too narrow set of names. UE4SS `StaticFindObject` only locates UObjects **currently loaded in memory**. Asset loading and class lookup are different operations.
3. H42's fallback for a missing Macros soft-class value pointed `Macros` at an existing **Black** skin class. That would never constitute a genuine Macros entry. **Removed in H43.**
4. H42 checked only `APCosmeticsManager`, while H28 reflected a separate `APCosmeticsFunctionLibrary::AddCosmeticOverride` with a different argument order. H43 tries that existing local API as a guarded alternative.
5. H42's rollback might have restored a material override that pre-existed C. H43 tracks whether the H43 suite itself captured a new snapshot before invoking `restore()`.

## What H43 tests in ONE press
1. **H25 visual**: always run first, independent of Alcove actor and class load. No new material system implementation.
2. **Asset class acquisition**: try four explicit package/class asset paths with `LoadAsset`, check returned loaded object and `GeneratedClass` property, then `StaticFindObject` multiple exact names and `FindObject("BlueprintGeneratedClass","BP_Hinterclaw_MacrosCosmetic_C")`. Class type/ref compatibility remains unvalidated; each attempt is guarded.
3. **Temporary map registration**: only if a native `FGameplayTag` was recovered from the **actual Macros CDO** and a Macros generated class is present, try the named Alcove `TMap:Add`. No Black-asset fallback; no overwriting an existing tag; immediate removal on partial type-conversion failure. `TMap` may reject direct UClass into TSoftClass value, which is allowed as an individual branch failure.
4. **Local native cosmetic override**: attempt `APCosmeticsManager::AddCosmeticOverride`, alternatively `APCosmeticsFunctionLibrary::AddCosmeticOverride` with H28 observed parameter order, using an H43-unique request ID. A guarded `pcall` success is only an invocation, **not proof the game applied the override**. Rollback attempts `RemoveCosmeticOverrideByRequest`.
5. **Alcove native selection**: attempt `SetValorplateCosmetic` on the Hinterclaw Alcove with real tag or, if native CDO not available, UE4SS documented **table-based struct argument** `{TagName=FName(...)}`. This may affect only Alcove visuals and has no proven exact inverse; re-enter Sanctum after test.

**Independent execution:** An unavailable Macros class no longer prevents the H25 visual step, local tag-construction attempt or Alcove preview. Every method reports its own result, `H43_MULTIPATH_END` always follows normal execution, and the first C press never fails closed for an unrelated stage.

## User protocol
1. Back up H42 files. Extract cumulative H43 ZIP in the EXE directory, preserving `ue4ss/`. Restart and verify `H43_BOOT_MARKER=OK`.
2. Equip Hinterclaw, stay in fully loaded Sanctum near its Alcove, press **F1 → C ONCE**. Inspect original Hinterclaw cosmetics menu for **new selectable Macros entry**. Also observe whether character/Alcove appearance changed; this is not the same as native unlock.
3. Press F1 → C a second time **before traveling** for best-effort rollback; native preview may require Sanctuary reload. One screenshot of the native menu or a single short log is enough.

**Safety:** No `NotifyPlayerAcquiredLootWithoutRequest`, no inventory/reward/profile/account grant, save/network/entitlement spoofing or Javascript injections. UE4SS native calls can crash even inside `pcall`. H25 A/B, F1 overlay, H35 locator, original ASI/DXGI, and previous manually invoked diagnostic code are preserved.

**Status:** H43 code packaged for experimental test; no native unlock success claimed or in-game validation yet.
