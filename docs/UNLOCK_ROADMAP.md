# Godfall cosmetics: Unlock Gratitude / Unlock All research priority

## Goal (priority over visual material swapping)
Expose cosmetics in the *vanilla* Godfall cosmetics menu as usable/unlocked by a local mechanism. Applying materials to CharacterMesh0 is only a proof that the cooked visual content exists, NOT a cosmetic unlock. Do not label visual overrides "Unlock".

## Candidate commands for a future F11 UI
- **Unlock Gratitude**: exactly the 12 official Gratitude Pack Valorplate cosmetics after resolving their local gameplay tags.
- **Unlock All Cosmetics**: up to the 163 locally discovered catalog entries (124 Valorplates, 26 weapons, 7 banners, 6 spectral weapons), with categories and fail-soft handling; do not assume every entry is unlockable or all assets exist.
- **Refresh Cosmetics**: rebuild/requery vanilla UI/inventory after a local unlock only if the game's safe API is identified.
- **Report Status**: owned/enabled/visible/available for each catalog item, before and after a targeted experiment.

These are *planned UI labels*, not confirmed engine commands or working features.

## Already established
- SourceData collection: `cosmetics/collection` yields 163 rows with `gameplayTag`, `forGameplayTag`, and `cosmeticClass`. No ownership field in those rows; filtering occurs downstream.
- Forcing `APLocalPlayer::HasEntitlement` and `APCosmeticsManager::IsCosmeticEnabled` true did not populate hidden entries in vanilla UI.
- H9-H19 JSON/loadout/session mutation was rejected/reverted by runtime; it did not produce reliable unlocking.
- H23 / H24 / H25 exact Material Equip is a visual replacement and must not be mistaken for a true unlock.
- H25 is the current technical restore test base. H23 remains the last historically validated release base on main.

## Investigation plan
1. Capture baseline in vanilla UI and runtime: known-owned Gratitude cosmetic, ordinary unlocked variant, locked/hidden variant, and current Valorplate. Only observe, do not write.
2. Search **narrowly** for inventory, cosmetics-manager and player-profile APIs and state: local owned/unlocked collection, reward entitlement ingestion, acquired cosmetics array/map, and vanilla UI query path. Avoid broad hooks (H20 crashed).
3. Compare how a normal vanilla cosmetic becomes visible when acquired; identify the exact local mutation and UI refresh.
4. Implement one *single-cosmetic* local unlock proof with explicit read-back after opening cosmetics menu; verify persistence after changing plate and restarting. Only then scale to Gratitude and to all categories.
5. Never claim SHiFT/EOS/server entitlements were granted without real server confirmation. Prefer client-local, reversible feature that is explicit about scope.
6. Preserve H25 A/B functionality and package files at ZIP root (no version-named folder).

## Gratitude official context
Gratitude Pack was a free 12-skin Godfall reward offered in 2022. Published SHiFT code: `99KT3-RRZBC-CTBJB-B3T3T-TCTCW`. Redemption may be associated with SHiFT account state; redeeming a code and seeing all skins in vanilla menus are different observable conditions. Xbox store also lists the 12-skin Gratitude Pack; Xbox listing alone does not confirm an equivalent standalone PC entitlement in 2026.

Sources (public):
- https://www.xbox.com/fr-FR/games/store/godfall-gratitude-content/9NPT9HBW8KC9
- https://www.playstationtrophies.org/forum/topic/324263-shift-codes/
- https://www.reddit.com/r/PlayGodfall/comments/1feawba/gratitude_pack_help_ps5/

## No premature guarantees
A true local unlock in the vanilla cosmetic selection screen is NOT proven yet. Do not build misleading `Unlock All` buttons that merely swap materials. Identify catalog-to-ownership pipeline before attempting an unlock.
