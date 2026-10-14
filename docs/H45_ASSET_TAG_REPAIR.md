# H45: correct the two H44 blockers, preserve four independent triggers

## Facts from real H44 user test (2026-10-14)

`GodfallEnhancedBridge(20261014-190040).log` was **142 lines, 16,068 bytes**. All F6-F10 keybinds registered; F6 succeeded **twice** (`H25_APPLY_OK changed=4 verified=4` each time) and F10 restored four parent material assets (`H25_RESTORE_OK restored=4 verified=4`). F7/F8 each ran twice but did **not** reach `TMap:Add` or `AddCosmeticOverride`; `BP_Hinterclaw_MacrosCosmetic_C` was not found. F9 twice returned `FNAME_API_MISSING`, before any `SetValorplateCosmetic` call. **None of the three native cosmetic experiments actually ran**, and the log shows no fatal errors.

## Verified underlying API problems

- User's FModel export of `BP_Hinterclaw_MacrosCosmetic` confirms the package path already used in H44 was **correct**, but H44's `StaticFindObject("BlueprintGeneratedClass " .. path)` included a type prefix. UE4SS's single-string form expects **only the full object path**: https://docs.ue4ss.com/lua-api/global-functions/staticfindobject.html . H45 uses the unprefixed full UClass path and `FindObject("BlueprintGeneratedClass",short_name)`.
- H44's only `LoadAsset` attempt was by bare package name, returning `nil`; that does not establish cooked-class absence. H45 tries three **FModel-derived exact forms**, generated class object, Blueprint object, bare package, each followed by unloaded/resident class lookup. Never calls methods on the returned asset unless its true class name matches.
- The user's UE4SS runtime **does not expose the global FName constructor**, despite UE4SS documentation. H45 does **not** fabricate a Lua gameplay-tag struct. For F9 it reads the genuine `FGameplayTag` from Macros' *cooked Blueprint CDO*, only if the class can be loaded. For F8 RequestID, it reuses the **native FName field from that same tagged CDO**, checked to match the Macros tag. This deliberately avoids synthetic string marshalling, but could collide with a game request using the same tag as request ID, so F8 remains high risk and is strictly user-triggered.

## Controls and limits

- **F6**: unchanged known-good H25 material apply.
- **F7**: one user-triggered `CosmeticTagToPlayerSkin:Add(real_CDO_Tag,real_Macros_UClass)` attempt, **high risk**: `TSoftClassPtr` value conversion remains unproven.
- **F8**: one user-triggered `APCosmeticsManager:AddCosmeticOverride` attempt with native CDO tag and request FName, **high risk**: `FGameplayTagContainer` conversion and local override semantics still not verified. One request name is the Macros gameplay tag string; this may overlap an existing game's request ID. Undo uses the same native FName.
- **F9**: one user-triggered `BP_ValorplateAlcove:SetValorplateCosmetic(CosmeticGameplayTagString,CosmeticGameplayTag)` call with both parameters grounded in the user FModel exports. May only alter Alcove appearance, **not unlock**.
- **F10**: best effort map/manager/material undo; preview has no proven inverse. Re-enter Sanctum if necessary.
- **F1 C**: help only, never triggers risky operations. A/B H25 unchanged.
- **No** entitlement spoof, reward/inventory grant, save mutation or server call.

**Safety caveat:** H43 previously crashed with speculative UE4SS GameThread calls. Although H45 fixes source-level API misuse, `pcall` cannot prevent access violations. All F7/F8/F9 remain opt-in experimental calls; if one crashes, do not retest it.

## One useful outcome

**Do not repeat F6 or F10 just to reconfirm H25**; these already worked twice and once respectively. If testing H45, start with **F9** as the separate native preview, then observe the original Hinterclaw skins list. F7/F8 carry greater unverified marshaling risk and are not required for the initial UI observation. If the class is still not found, **do not perform further F7/F8/F9 attempts**; the mod must instead address game asset registration/static frontend path before another runtime mutation experiment.

**H45 packaged != H45 game-tested. Native unlock remains unproven.**
