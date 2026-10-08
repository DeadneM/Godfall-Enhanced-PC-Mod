# H28 targeted local cosmetic acquisition discovery

## H27 findings
H27 completed: 90 class candidates, 33 selected, 360 functions, 116 properties, 24 signatures, mutated=0.

Most important new signature:
`APLootManagerComponent::NotifyPlayerAcquiredLootWithoutRequest(PlayerState, LootClassName, LootGameplayTag, Amount, bPersistToAccount)`.
**A flag named bPersistToAccount does NOT prove client-only cosmetic ownership**; this could call a server function or only concern ordinary loot. Do not invoke until we establish semantics.

H27 also identified `APInventoryComponent::AddItemByClass`, `AddItem`, `ClaimItems`, and `APLocalPlayer::OnLootAcquired`.
The H27 global 360 function cap was exhausted by APInventoryComponent and APLootManagerComponent before APLocalPlayer functions were emitted. Fixing this lost coverage is H28's primary purpose.

`APCosmeticsManager` exposed `AddCosmeticOverride` and `GetCosmeticOverride`, but these are visual cosmetics APIs, not a verified ownership/unlock interface.

## H28
- Keeps existing F1 hotkey patched ASI (from H27) and unchanged dxgi.dll.
- Keeps visual Method A and safe Method B from H25.
- **Method C** now introspects only 9 specific Aperion classes plus up to 16 matching SourceData/SessionData/Entitlement/Profile classes. It prioritizes APLOCALPLAYER first.
- Dumps UFunction names, parameter metadata and relevant UProperty names, all *read-only*.
- No hooks, runtime function invocation, save modification or entitlement changes.
- `H28_UNLOCK_AUDIT_END` is completion marker.
- ZIP has all files at root as requested.

## Test
Equip default Hinterclaw, open overlay F1, select Method C once, and share `GodfallEnhancedBridge.log`.
Do NOT test `Unlock Gratitude`/`Unlock All` in this build: these features are not yet available.

Next goal: identify the precise persisted cosmetic ownership state, then test one local-only unlock with before/after vanilla UI verification; scale to Gratitude and All only if verified.
