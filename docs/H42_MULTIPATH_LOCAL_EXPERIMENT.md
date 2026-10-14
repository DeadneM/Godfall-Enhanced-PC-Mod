# H42: Multi-path, local cosmetic tests in ONE game session

## Why we stopped shipping trace-only builds
The user expressly rejected repeated one-thing-per-version F1→C log cycles. H40 observed real DataBridge event names but none gives a cosmetic unlock method. H23/H25 visual Macros substitution is validated; H28 recorded the exact reflected argument names for local `APCosmeticsManager::AddCosmeticOverride` and `RemoveCosmeticOverrideByRequest`. H36 verified that placed Hinterclaw Alcove's `CosmeticTagToPlayerSkin` map has 9 entries but omits the shipped Macros tag, and FModel verified `BP_Hinterclaw_MacrosCosmetic_C` has the matching native `GameplayTag`.

## F1 C: four experiments (no extra builds or restarts between them)
Preflight requires a *live Sanctum Hinterclaw Alcove actor*, loaded cooked `BP_Hinterclaw_MacrosCosmetic_C`, its class-default `GameplayTag` exactly equal to `Character.Player.Hinterclaw.MacrosCosmetic`, and the existing bridge. Fail closed if absent.

1. **H25 visual preview**, via unchanged `apply_macros()` on live CharacterMesh0. Known to work if player character/mesh available.
2. **Alcove map registration**: obtain a real `FGameplayTag` from Macros' CDO; attempt `TMap:Add(tag, MacrosUClass)` with verified `Contains`. If the custom UClass cannot be converted to the map's `SoftClass` value type, immediately remove it and try a real existing native soft-class value from the Black skin (tests *inclusion* of the Macros **tag**, but that fallback points to Black and **is not the genuine Macros class**). All paths log result, no overwrite of a pre-existing Macros tag.
3. **Native `APCosmeticsManager::AddCosmeticOverride`**: attempt guarded call on a local Alcove actor with a unique request ID, Macros native `FGameplayTag`, an empty gameplay tag filter container and the Macros generated class. Signature is **observed** in the user's H28 log, but coercion and semantics are **not validated**. Type mismatch results in a rejected call. `RemoveCosmeticOverrideByRequest` is the inverse action.
4. **Native `BP_ValorplateAlcove_C:SetValorplateCosmetic`**, called once on the *Sanctum Hinterclaw Alcove*, with the two FModel-confirmed parameters (tag string, FGameplayTag). This may change an **alcove preview**, not own/equip state. No known exact inverse exists, so the game may require re-entering Sanctum to restore that preview.

The existing F1 overlay controls do not have to be rebuilt. The **first C** runs all four steps once, guarded independently; **second C** attempts removal of the unique cosmetics override request, the new Macros TMap entry, and H25 material restoration. Each step reports status immediately. There is **no request to send a log after every click**. Instead the user can directly check whether Macros **appears in the original cosmetic list** or whether **only the visuals change**.

## Important safety constraints
- Changes are only intended to be local runtime/actor state. We **do not call** `APLootManagerComponent::NotifyPlayerAcquiredLootWithoutRequest` even with `bPersistToAccount=false`: its ability to persist remotely or grant player progression has not been established.
- No server entitlement spoofing, inventory grants, account writes, save edits or direct JavaScript injections. No H41 hook is started by Method C.
- Native Unreal calls can still crash. This is an **experimental** build; back up the prior installation. If a crash occurs, return to H25/H41; don't retry blindly.
- Map/manager undo is attempted with explicit matching tag and request ID, but **cannot be guaranteed** after a level transition or unloaded actor. The alcove preview function has no validated inverse: **do not describe second C as a perfect rollback**.
- For precise visual restore H25 may restore a parent asset rather than dynamic MID parameters. Switching back to the default skin/re-entering Sanctum may be necessary.
- This is NOT a genuine unlock until Macros is listed and selectable in the original UI after refresh/restart. No `Unlock Gratitude` / `Unlock All` feature yet.

## Single short test
1. Back up game mod files, unpack cumulative H42 ZIP at the game EXE and start the game once.
2. **Equip Hinterclaw**, visit the **loaded Sanctum** near its alcove, open F1 overlay and press C **once**. Let the four local experiments run, then **look at the native Hinterclaw skins list**. No need to navigate four other skins or wait 90 seconds.
3. If Macros appears, select it in the *vanilla UI*, close/reopen that screen, and see whether it persists. If it appears only visually, note it.
4. Press F1 C a second time **before changing areas** to attempt local rollback; if the vanilla preview remains altered, reload Sanctum. Send **one screenshot or the log only if needed** to diagnose outcomes.

## Regression and implementation
- H25 A/B apply+restore, previous A/B paths, F1, existing manually callable diagnostic functions, H35 standalone frontend locator and the exact original ASI/DXGI are preserved.
- Uses no engine-level global object crawl beyond the existing H25 mesh search and the specific 12 Alcove actors.
- Validation needs the installed UE4SS and native Godfall behavior; a successful code packaging/CRC check does not prove the native calls succeed.
