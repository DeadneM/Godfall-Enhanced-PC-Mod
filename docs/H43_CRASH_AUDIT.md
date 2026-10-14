# H43 crash analysis — BLOCKED / DO NOT RETEST

**Status:** H43 experimental release `releases/H43/GodfallEnhanced_V0.6H43_MULTIPATH_NONBLOCKING_F1_TEST.zip` is **UNSAFE / NOT VALIDATED**. **Do not test again as-is**. Return to H41 or the validated H25 materials build. This is not an in-game successful unlock.

## Source evidence (user's 2026-10-14 crash upload)

User provided:
- `CrashContext.runtime-xml`
- `UE4Minidump.dmp` (1,103,168 bytes; local inspection only, **do not commit**)
- `CrashReportClient.ini`

The crash context reports:
- `CrashType=Crash`, `IsEnsure=false`, `IsAssert=false`.
- `Unhandled Exception: EXCEPTION_ACCESS_VIOLATION reading address 0xffffffffffffffff`.
- Native minidump exception code **`0xC0000005`**, exception address **`0x00007FF894F760BE`**, loaded UE4SS base **`0x00007FF894B90000`**, i.e. **UE4SS RVA `+0x3E60BE`**.
- The crashed thread is **GameThread** (thread 28224); engine target UE4 4.27.1; crash at **52 seconds after process start**.
- Native call stack contains many repeating UE4SS frames. Offsets `+0xC6CA6E`, `+0xC6B439`, `+0xC6C1C3`, `+0xC6BA84`, `+0xC63B3C` each appear **four times**. This is **consistent with recursive native property/argument conversion or repeated reflection**, but symbols are not available to determine a precise operation.
- Exact crash source (e.g. `LoadAsset`, `GetCDO`, `CosmeticTagToPlayerSkin:Add`, `AddCosmeticOverride`, `SetValorplateCosmetic`) **cannot be determined from the crash context and minidump alone**. An accompanying `GodfallEnhancedBridge.log` would identify the last completed diagnostic stage if available; none is included in the crash upload.
- `CrashReportClient.ini` contains Unreal Crash Reporter settings only and provides no cause.

## H43 source-level hazards requiring removal before any next native build

1. H43 packed multiple **untested UE4SS reflected native calls** in a single synchronous GameThread callback. `pcall` protects Lua exceptions, **not C++ access violations**; any native call can terminate the game.
2. `h43_class()` calls `LoadAsset()` repeatedly with speculative package paths and reads a `GeneratedClass` property on returned objects without any verified object-class compatibility.
3. `h43_map()` attempts `TMap:Add(nativeGameplayTag, generatedUClass)`, while `CosmeticTagToPlayerSkin` is a `TMap<GameplayTag, SoftClass<BP_Player>>`, so direct UClass→SoftClass conversion is **not validated**.
4. `h43_override()` passes a synthetic Lua `{GameplayTags={}}` struct and `UClass` to `APCosmeticsManager` or `APCosmeticsFunctionLibrary` methods without validated argument marshalling or a confirmed in-memory target.
5. `h43_preview()` invokes `SetValorplateCosmetic` on a live Alcove using a guessed string/struct signature, without confirmed Blueprint pin types or an exact restoration path.
6. All risky paths are *different methods but not independent execution environments*. Their `pcall` wrappers do **not** isolate native faults. The crash invalidates treating H43 as a safe multi-method diagnostic. **Do not rerun as-is.**

## Decision

- Freeze H43; archive remains for development forensics, **not installation recommendation**.
- Keep main/stable base untouched; use H41 experimental (which the user ran without a crash and which has a validated clean hook unregister in H40), or H25 for visually proven Macros material apply/restore.
- **No H44 bundled native reflection probe** until an offending stage is established by log or verified function signature and a crash-resistant workflow is designed. Otherwise it would repeat the user's costly crash experience.
- Do not perform server entitlement grants, persisted loot attribution, account/save changes in an attempt to mask the issue.
- Future goal stays: Macros visible and selectable in vanilla cosmetics menu; H43 achieved neither.

**Crash files are sensitive local diagnostic artifacts and have intentionally not been uploaded to GitHub.**
