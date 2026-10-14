# H45 two native crashes and ineffective F9 — stop runtime mutation lineage

**Date:** 2026-10-14. **Status:** `H45` experimental ZIP is **UNSAFE** for F7/F8 and **not an unlock**. Do **not** repeat F7/F8 or ship them in future builds. The user reports: `F9 ne marche pas / F8 crash / F7 crash`.

## Evidence: user-supplied crash reports, read directly

Two new crash contexts, CrashReportClient configs and native Windows minidumps were supplied and inspected locally. **Raw crash reports and dump contents are not in this repository**, and their process IDs/unique crash identifiers have intentionally been omitted here.

| Field | `CrashContext(1)` and minidump `(1)` | `CrashContext(2)` and minidump `(2)` |
|---|---|---|
| Engine | Unreal 4.27.1 | Unreal 4.27.1 |
| Exception | `0xC0000005` / read access violation | `0xC0000005` / read access violation |
| Invalid read address | `0xffffffffffffffff` | `0x0000028c08ab39a9` |
| Crashed thread | `GameThread` | `GameThread` |
| Runtime | 59 seconds | 47 seconds |
| Top recorded module | `VCRUNTIME140 +0x1C177` | `UE4SS +0xC71C60` |
| Top following UE4SS address | `UE4SS +0x234560` | `UE4SS +0xC71C60` |
| Repetition | Multiple repeating UE4SS frame groups `+0xC6CA6E`, `+0xC6B439`, `+0xC6C1C3`, `+0xC6BA84`, `+0xC63B3C` | Similar groups of repeated UE4SS frames |
| Certainty | Confirmed native access violation, exact Lua operation **not identified** | Confirmed native access violation, exact Lua operation **not identified** |

**Important identification limit:** The user has reported **F7 and F8 both crash**, but the two runtime-XML/minidump pairs are **not reliably mapped to F7 versus F8** without the corresponding `GodfallEnhancedBridge.log` files from those launches. Do not claim `Crash(1) = F7` or `Crash(2) = F8` without that evidence. The stack has no UE4SS private symbols. Both were initiated during the H45 native experiments according to the user's report. The crash module being UE4SS does **not** imply a defect in stock Godfall.

## Root cause candidates, ordered by evidence (not confirmed symbols)

**F7** `h44_map()` follows:
- Live Alcove lookup, `h44_find_class()`, `GetCDO`, `GameplayTag` read.
- `CosmeticTagToPlayerSkin:Contains(tag)`.
- If prechecks pass, `CosmeticTagToPlayerSkin:Add(tag,class)`.
- **Critical incompatibility**: cooked map is `TMap<FGameplayTag,TSoftClassPtr<BP_Player>>`, but the implementation supplies a **UClass** as its second argument; no UE4SS safe UClass-to-soft-class conversion has been verified. Native C++ property marshaling can crash. The earlier H43 native crash also occurred during multi-action reflection, but lacked a runtime last-stage log.

**F8** `h44_override()` follows:
- Same class/cooked tag retrieval, then uses `TagName` from the GameplayTag as a pseudo-request ID.
- The `APCosmeticsManager::AddCosmeticOverride` call passes `actor, req, tag, {GameplayTags={}}, class`.
- **Critical incompatibilities**: synthetic `FGameplayTagContainer` argument, unverified `UClass` versus required `UObject` parameter, and a request ID reused from the game's own cosmetic tag instead of a unique reserved FName. No valid conversion/persistence semantics were verified.
- The F7 and F8 first-stage `h44_find_class()` also performs several `LoadAsset` attempts and `GetCDO`. **Without corresponding bridge logs, the exception might have occurred *before* the final mutating call**. Do not assert that `TMap:Add` or `AddCosmeticOverride` was reached.

`pcall` cannot catch an SEH/C++ access violation and cannot make any of these calls safe.

## F9: objective mismatch even if it returned successfully

H45 `h44_preview()` resolves an Alcove and the Macros native CDO tag and invokes `BP_ValorplateAlcove:SetValorplateCosmetic(FString,FGameplayTag)`. This is an **Alcove display/preview function**, not evidence of altering the player's native cosmetic catalogue or owned skins. The user says **F9 has no visible effect**; no H45 bridge log was attached in the crash report turn, so we cannot verify whether F9 failed a precondition, Lua call returned normally, or changed an unseen Alcove preview. **Do not chase this as a native acquisition path.**

## Confirmed good and next work

- **H25 material override:** user-validated, four Macros materials applied and H25 restore works via parent asset.
- **H40 DataBridge trace:** exact native request names captured and hooks unregistered without error in the completed test.
- **H44 F6/F10:** independently user-validated. They are appearance-only.
- **H43:** crashed on GameThread during combined unsafe native call(s).
- **H45:** user reports **two additional crashes (F7 and F8)**, F9 ineffective. **Retire the H43/H45 acquisition experiments**. Do not rebind these exact native invocations as separate methods.
- For a **true native cosmetic unlock**, focus on the original UI's **ownership/filter/list assembly**, not an Alcove preview or a speculative map cast. Existing local `cosmetics/collection` contains 163 entries (including physically shipped assets), but no ownership columns were exposed. The gate is downstream. Inspect actual offline frontend/Blueprint-owned cosmetic list source and the contrast between owned skin and Macros; do not fabricate account entitlements.
- `H46` **not built**. Do not create another speculative crash-prone H46. `main` remains untouched.

## Safety recommendation

Uninstall H45 and use the tested [H41 ZIP](../releases/H41/GodfallEnhanced_V0.6H41_SINGLE_DATABRIDGE_EVENT_TRACE_F1_TEST.zip) (or validated H25 visual base). Restart the game after restoring the older mod. Do not use H45 F7/F8 again. Keep the reports as diagnostic evidence offline.
