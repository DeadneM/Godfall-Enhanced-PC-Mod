# H44 actual user runtime result, 2026-10-14: two validated controls, three blocked experiments

**Input:** `GodfallEnhancedBridge(20261014-190040).log`, **142 lines / 16,068 bytes**, inspected as uploaded. Raw user log not committed.

## Verified runtime behavior

- Boot `H44_BOOT_MARKER=OK`; **F6, F7, F8, F9, F10 all successfully registered**.
- **F6 pressed twice**: both commands reached `H25_APPLY_OK changed=4 verified=4 target=Character.Player.Hinterclaw.MacrosCosmetic`, one initial application and one after F10. All four materials verified each time. **This is only a visual swap, not native ownership.**
- **F7 pressed twice**: first attempted `LoadAsset` once (`H44_CLASS_LOAD_END status=RETURNED object=NIL`); both attempts ended `H44_CLASS status=NOT_FOUND`, `H44_ACTION_END action=F7 result=CLASS_OR_TAG_MISSING`. **No TMap:Add was invoked**.
- **F8 pressed twice**: `H44_CLASS status=NOT_FOUND`, `CLASS_OR_TAG_MISSING`; **no CosmeticsManager:AddCosmeticOverride was invoked**.
- **F9 pressed twice**: `H44_ACTION_END action=F9 result=FNAME_API_MISSING`; **no SetValorplateCosmetic was invoked**.
- **F10 pressed once**: `H25_RESTORE_OK restored=4 verified=4 mode=PARENT_ASSET`, `H44_REVERT_END map_pending=false manager_pending=false visual_pending=false`. It restored the four saved **parent assets**, not guaranteed original dynamic MID parameter values. No map or manager state needed removing.
- The **last operation in the log was another successful F6**, so Macros materials were applied again when the log ended.
- No `H44_NATIVE_BEGIN action=TMAP_ADD`, `MANAGER_ADD_OVERRIDE` or `SET_VALORPLATE_COSMETIC` exists. No recorded crashes or Lua errors. The log alone does not prove overall crash-free run.

## Root cause audit using previously supplied FModel and current UE4SS documentation

1. **FModel confirms the Macros Blueprint package path is correct**: `/Game/Aperion/Blueprints/Characters/Player/Hinterclaw/Skins/BP_Hinterclaw_MacrosCosmetic` and exported class `BP_Hinterclaw_MacrosCosmetic_C` (user file `Markdown collé (2).md`). Therefore do **not** guess that the package is absent based on H44's return value.
2. **H44 used the incorrect prefixed `StaticFindObject("BlueprintGeneratedClass /Game/...")` form.** UE4SS documents the one-string form expects the object's **full path without the type prefix**. Correct future usage to `StaticFindObject(Package..".BP_Hinterclaw_MacrosCosmetic_C")` if that UClass is actually loaded. Reference: https://docs.ue4ss.com/lua-api/global-functions/staticfindobject.html .
3. The UE4SS `LoadAsset` function is documented to load by path on the game thread, but **does not guarantee a non-nil returned class**; H44 only tried the package once and reported nil, then could not find the class. Path and object residency/loader compatibility remain distinct questions. Reference: https://docs.ue4ss.com/lua-api/global-functions/loadasset.html .
4. **Global `FName` is unavailable in this user's actual runtime**, even though UE4SS docs normally provide it: https://docs.ue4ss.com/lua-api/global-functions/fname.html . Therefore, **do not gate F9 by creating `FName(...)` from a non-existent global**, nor fabricate a GameplayTag `{TagName=...` struct before determining proper runtime construction. The *native* Macros CDO `GameplayTag` exported by FModel is a preferable source if the cooked class can be reliably loaded.
5. Previously supplied FModel `BP_ValorplateAlcove` export confirms `SetValorplateCosmetic(CosmeticGameplayTagString: FString, CosmeticGameplayTag: FGameplayTag)`; H44's attempted signature mirrors those two fields but still needs a genuine marshalled native `FGameplayTag`.
6. The `CosmeticTagToPlayerSkin` map value is `TSoftClassPtr<BP_Player>` rather than `UClass`; direct `map:Add(FGameplayTag, UClass)` may be a native crash risk even when the class lookup is fixed. **Do not enable F7's mutating add until SoftClass marshalling is established.**
7. `APCosmeticsManager::AddCosmeticOverride` expects `ForActor, RequestID(FName), CosmeticTag(FGameplayTag), FilterTags(FGameplayTagContainer), AssetOverride(UObject)`; H44's synthetic FilterTags table and missing FName are separate blockers. Native call must not be made blindly (H43 already crashed while multiple such operations ran).

## Conclusion and next implementation gate

**H44 is successful as an isolation test**: independent key registration, F6 visual, F10 restoring work; F7/F8/F9 **did not reach their risky native methods**. Merely calling each method one-at-a-time will not produce new results until the runtime object types are correct. No unlock was achieved.

Next iteration should address **two actual compatibility defects together**: correct unprefixed `StaticFindObject` and the unavailable global `FName`, prefer CDO native GameplayTag, and preserve four separate keys. However, stop short of guessing invalid `TSoftClass`, `FGameplayTagContainer` or `FGameplayTag` marshalling in production builds. Request no repeated F6/F10 visual verification; they are known working.

## Version status

- H41: user-tested DataBridge controls, no reported crash.
- H43: user-reported UE4SS GameThread crash, unsafe.
- H44: user-tested independent hotkeys, **F6/F10 validated, F7/F8/F9 precondition-blocked**.
- Native skin unlock: not implemented; H45 not built at this step.
