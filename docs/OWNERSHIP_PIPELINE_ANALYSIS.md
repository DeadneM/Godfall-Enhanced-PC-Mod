# Godfall cosmetic ownership pipeline: H27/H28 evidence audit

> **Status:** research analysis, not a working unlocker. H28 is an unvalidated read-only audit build. No SHiFT/EOS or game entitlement state was changed.

## Verified in H27 runtime log

- Test command: `COMMAND METHOD_C AUTO_NEXT`; the bridge detected the current Hinterclaw mesh and dumped its four material slots.
- H27 ended normally: `H27_UNLOCK_AUDIT_END classes=33 functions=360 properties=116 signatures=24 mutated=0`.
- 90 UClass candidates were detected, split across ownership (2), cosmetics (6), inventory (30), progression (44), player (8), with 33 selected.
- **False positives:** both selected `ownership` classes were `RequestChangeData_CollisionProfileName` / `RequestChange_CollisionProfileName`. These represent collision profiles, not ownership/account profiles.
- **Critical coverage defect:** `APLocalPlayer` was selected but no `H27_FUNCTION ... APLocalPlayer:` line was emitted. The global cap of 360 UFunctions was consumed before that class was examined.
- **Another coverage defect:** `APCosmeticsFunctionLibrary` appeared as a selected class, but its functions were not emitted after the cap.
- `APCosmeticsManager` provides visual state/actor APIs including `IsCosmeticEnabled(ForActor, CosmeticTag, FilterTags)`, `GetCosmeticOverride`, `AddCosmeticOverride(ForActor, RequestID, CosmeticTag, FilterTags, AssetOverride)`. These signatures are more consistent with live appearance composition than persistence of unlocked cosmetics. The previous test forcing `IsCosmeticEnabled` true did not reveal hidden vanilla-menu entries.
- `APInventoryComponent` exposes ordinary item commands and many `Server*` network-facing variants, including `AddItemByClass`, `ClaimItems`, `ServerAddItemByClassWithCustomData`, and `OnPlayerSessionDataLoggedInChanged`. These do **not** prove Valorplate cosmetics are inventory-item subclasses.
- `APLootManagerComponent::NotifyPlayerAcquiredLootWithoutRequest` has metadata for `PlayerState`, `LootClassName`, `LootGameplayTag`, `Amount`, and `bPersistToAccount`. The parameter name is **not evidence** that this method can safely grant a local cosmetic, and invoking it may have account/network effects.
- `APLocalPlayer` exposes `OnLootAcquireHandle` as a reflected property, but the actual handler and its relation to cosmetic ownership are not yet established.
- H27 log contains **no Method A or B test**; it only runs Method C. Their retained code must not be confused with H27 runtime validation.

## Confirmed project correction: MacrosCosmetic is Gratitude Pack content

The user has confirmed from direct game knowledge that `Character.Player.Hinterclaw.MacrosCosmetic` is a **Gratitude Pack** skin. Therefore the visually successful H23–H25 application proves that an actual Gratitude cosmetic's cooked Blueprint and four Macros materials work on the user's PC installation. Earlier notes implying MacrosCosmetic might be unrelated to Gratitude were incorrect.

This is a content/visual validation, **not** proof of native cosmetic ownership or unlock. Its precise official display-name mapping within the Gratitude Pack is not yet documented by a verified in-game string.

**Target for first local-native unlock experiment:** the already identified `Character.Player.Hinterclaw.MacrosCosmetic`, not an arbitrarily selected new hidden skin. Compare its locked/hidden visibility against a selectable Hinterclaw cosmetic in the vanilla UI, then inspect the ownership/availability query. The acceptance test requires MacrosCosmetic to appear and be equippable from the vanilla cosmetics menu; a material-only swap is insufficient. Retain rollback and confirm behavior after UI refresh and game restart.

## What we can and cannot infer

Three distinct layers should be separated:

1. **Cooked content registry:** `cosmetics/collection` yields 163 local rows (`gameplayTag`, `forGameplayTag`, `cosmeticClass`). This proves that assets are indexed, not that the account owns them.
2. **Active appearance:** Blueprint materials/mesh overrides, `APCosmeticsManager`, and loadout cosmetics. H23-H25 demonstrate client-side appearance changes, but not a vanilla-menu unlock. Do not relabel visual substitution as `Unlock`.
3. **Eligibility/ownership and UI projection:** the missing link. It may live in player session/profile data, a distinct unlock ledger, a reward resolver, or a server-derived cached view. No specific structure is proven.

`cosmetics.valorplates["0"]` in the character loadout JSON is evidence for **equipped selection**, not for entitlement ownership. The H9-H19 attempted loadout changes were rolled back, so that branch is not a confirmed native unlocking pathway.

## External corroboration, not an internal implementation proof

The official Godfall Gratitude Content pack lists 12 Valorplate skins: Bulwark (Kosmera's Might, Royal Fortitude, Spoils of War), Hinterclaw (Archon of Power, Pristine Predator), Illumina (Renzai's Bounty), Mesa (Herald of Unification), Phoenix (Ashengod), Silvermane (Archon Royalty), Typhon (Hand of the Dragon, Harbinger of Destruction), and Vertigo (Divine Scholar).
Source: https://www.xbox.com/en-us/games/store/godfall-gratitude-content/9NPT9HBW8KC9
This confirms intended user-visible names, **not** the PC internal gameplay-tag mappings. A Gratitude pack entitlement for Xbox does not itself prove the same PC entitlement mechanism.

Reports exist of players whose SHiFT gift history shows the Gratitude pack but whose game does not show the skins:
https://www.reddit.com/r/PlayGodfall/comments/187etol/
A public user report cannot identify the internal cause. It reinforces the need to distinguish redemption, entitlement delivery, menu availability and asset presence.

## H28 actual changes already staged

H28 replaces H27's broad global scan with a target-first metadata audit:
`APLocalPlayer`, `APCosmeticsManager`, `APCosmeticsFunctionLibrary`, `APLootManagerComponent`, `APInventoryComponent`, player controllers, `APGameSession`, and `APInventoryItem`. It tries to recover lost player functions and metadata while limiting crash-prone deep introspection. H28 has **not** run in game yet.

### Limitations to be aware of

- H28 metadata scans do not read *instance values* or reveal the vanilla UI call chain. Even a perfect function list is insufficient to prove local unlock.
- H28's 290-function global cap may truncate later target classes, although `APLocalPlayer` is now processed first.
- Candidate classes whose exact native names differ or whose implementations reside in Blueprint UI classes may be missed.
- No gameplay function should be called based only on its name or parameter list, especially one mentioning persistence to an account.

## Next concrete research milestone

Do **not** issue another broad class-dump build immediately.

1. Complete H28 targeted signatures and inspect **APLocalPlayer**, cosmetic function library and session/login handling before any mutation.
2. Identify the cosmetics-screen query path: the function that selects which rows from `cosmetics/collection` can be shown/selected.
3. Compare **one known-unlocked Hinterclaw skin vs the Gratitude Pack skin `Character.Player.Hinterclaw.MacrosCosmetic`** under the same Valorplate, first in read-only mode. Track whether the relevant state is player/session/cache rather than inventory.
4. Try one reversible local-only unlock **only after** identifying the ownership state, refresh path, and safe rollback. Verify *actual appearance in the vanilla cosmetics list* and ability to equip there, before/after menu refresh and game restart.
5. Only after a successful single-cosmetic proof, map exactly the 12 official Gratitude skins to internal tags, then add `Unlock Gratitude`; generalize to `Unlock All` only when ownership semantics are understood.
6. Preserve F1 keybinding, H25 A/B functionality, no broad hooks, and ZIP-root packaging.

**No actual native unlock is verified as of this note.**
