# Godfall H29: in-game cosmetic UI read-only snapshot comparison

## Why a new approach is necessary
The user's H28 log completed with `H28_UNLOCK_AUDIT_END classes=10 functions=244 properties=55 signatures=90 mutated=0`. H28 successfully enumerated all 43 relevant APLocalPlayer functions, but it did not expose an API for granting a skin or for checking whether a catalogued skin is selectable.

- `APLocalPlayer::OnLootAcquired` has trigger/event parameters and is not evidence of a grant operation.
- `APPlayerController::UnlockAllValorplates` concerns Valorplates, not their optional cosmetic skins.
- `APInventoryComponent::UnlockDefaultItems` concerns standard items; no evidence links it to `cosmetics/collection`.
- `APCosmeticsManager` exposes visual overrides; previous bypass of `IsCosmeticEnabled` did not add missing entries to the vanilla menu.
- `APLocalPlayer::GetActiveEntitlements`, `GetAvailableEntitlements`, `GetPlayerSessionData`, `FetchPlayerData` exist but H28 only inspected metadata, not account values.

A new generic class dump would repeat work. The missing link is the *actual cosmetics menu* and its list filtering/selection logic.

## H29 objective
Capture and compare names of loaded UI/widget-related objects matching cosmetic, appearance, skin, Valorplate, customize, preview, etc., before and after opening the original cosmetic selection menu.

- **Method A/B:** preserve safe H25 application/restoration.
- **Method C / UNLOCK_UI_AUDIT:** first run captures baseline; second run logs added/removed UI objects, plus bounded selected Blueprint/UClass metadata.
- H29 never calls gameplay unlock, entitlement, account or inventory mutation functions.
- No broad UE4SS hooks (H20 crashed), no loadout/session mutation, no GC-unsafe object caches. Stores names only across snapshots.
- A false-negative result is possible: some menus may use persistent UI objects, Coherent/Slate rather than UMG, or naming conventions not matched by these filters.
- F1 overlay remains unchanged from H27; ZIP layout has files directly at root.

## Test
1. Replace H28 mod files with H29, maintaining `ue4ss/Mods/GodfallEnhancedBridge`. Avoid restarting between snapshots because the log and baseline reset at startup.
2. In Sanctum **outside** the vanilla cosmetics selection screen, open F1 and press **Method C** once, or write `UNLOCK_UI_AUDIT` to the bridge command file. Expect `H29_UI_BASELINE_SAVED`.
3. Open the game's native Hinterclaw cosmetics/skin selection screen.
4. Without leaving the cosmetics menu, press F1 and **Method C** again, or use `UNLOCK_UI_AUDIT`. Expect `H29_UI_DIFF`.
5. Send `GodfallEnhancedBridge.log` **before restarting**. If F1 conflicts with the cosmetics UI, the command file is a fallback.
6. For the UI comparison, note whether a known-owned Hinterclaw skin and `Character.Player.Hinterclaw.MacrosCosmetic` are listed, locked, hidden, or selectable. Do not use Method A to fake ownership.

`Unlock Gratitude` and `Unlock All` are **not** implemented. H29 is intended to identify the native cosmetic UI filter for a one-skin proof. No native unlock has been demonstrated.
