# H26 read-only unlock discovery TEST

**Purpose:** find the native local gameplay/inventory ownership path that turns a cosmetic in `cosmetics/collection` into a selectable entry in Godfall's **vanilla** cosmetic UI.

## Not an unlocker yet

H26 DOES NOT unlock any cosmetic. It adds a targeted reflected metadata audit for future `Unlock Gratitude` / `Unlock All` functionality. Do not label a material replacement as a true unlock.

## Existing validated features preserved
- F11 Method A: original H25 apply MacrosCosmetic materials.
- F11 Method B: original H25 safe material-asset restoration.
- `dxgi.dll` and `GodfallEnhanced.asi` come unchanged from H23.
- INI log controls unchanged.

## New diagnostics
- F11 **Method C**: dumps current Hinterclaw materials as before, then runs H26's metadata audit.
- The read-only audit enumerates a bounded set of *native UClass metadata* for cosmetics, inventory, rewards, entitlements, local player, SourceData and player profile.
- It lists only relevant UFunction and property **names**. No function that modifies gameplay state is called; property values are not read.
- No new UE4SS hooks (H20 broad hooks crashed).
- `H26_UNLOCK_AUDIT_BEGIN`, `H26_FUNCTION`, `H26_PROPERTY`, `H26_UNLOCK_AUDIT_END` are the diagnostic markers.
- Optional manual command `UNLOCK_AUDIT` can be entered in `ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt` and is consumed by the existing bridge.

## In-game test
1. Replace H25 files with the H26 ZIP, extract **directly in game root**. Back up H25 first.
2. Load gameplay, ideally Hinterclaw, and open F11.
3. Press **Method C once** and avoid repeated taps until the log finishes.
4. Send the new `GodfallEnhancedBridge.log`. Target: find owned/cosmetics state and safe local mutation paths.
5. Optional regression check: A still applies and B restores, but unlock discovery itself does not need those presses.

Do NOT try `Unlock All` prematurely. We need identify local ownership storage and a safe status comparison before any mutation tests.

## Open questions
- Is ownership a persisted locally stored array, a resolved server-backed profile, or a transient inventory projection?
- Does a vanilla UI refresh consult the local inventory or an external entitlement cache?
- Can cosmetic visibility be modified locally without mutating backend entitlements?

A true native unlock is not yet demonstrated.
