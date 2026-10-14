# H39: exact Coherent child connection, bounded read-only

## H38 user result, 2026-10-14
The supplied H38 runtime log (34 lines, 2,446 bytes) completed both manual C presses without an error marker. While the original Hinterclaw cosmetic screen was open, `WBP_GT_Test_C` was present, with only two relevant reflected methods (`GetCoherentUIGTWidget`, `ToggleBgBlurWidget`) and two relevant properties (`BackgroundBlurWidget`, `CoherentUIGTWidget_Persistent_90`). A `CoherentUIGTWidget_Persistent` instance had an outer classified `GT_TEST`. No URL or cosmetic/eligibility data were exposed. **The host is likely a generic UMG wrapper, not the native cosmetic availability gate.**

## The one new question
Does `WBP_GT_Test_C.CoherentUIGTWidget_Persistent_90` actually hold the live Coherent widget, and does its **specific class** expose view/URL/resource or data bridge bind metadata?

## What H39 does
- Method **F1 → C** records lightweight existing two-state UI presence and a **direct property read** on the live `WBP_GT_Test_C` only. No UObject-wide traversal.
- Uses guarded `GetPropertyValue("CoherentUIGTWidget_Persistent_90")`, obtains the child's class and checks whether `GetOuter` refers to the GT host.
- Reads only native `URL`, `Url`, `SourceURL`, `InitialURL` as strings, and logs **sanitized URL route categories** only; full links, hosts, JS payloads, account/session data are excluded.
- Reflects only matching named class functions/properties on child UClass (up to 4 levels of superclass) and caps output to 48 functions/45 properties. Names are class metadata, **not invoked**.
- No call to the previously identified `GetCoherentUIGTWidget` method: its side effects are unknown.
- Keeps `GT_HOST_METADATA` for manual H38 host probe, `ALCOVE_MAP_AUDIT` for H36/37 map probe, `COHERENT_PROBE` for older watcher. None is run by C.
- C does **not** alter map, gameplay, inventory, save, entitlement, account, backend or Coherent JS state.
- Original ASI/DXGI binaries, F1 overlay, H25 visual apply/restore and H35 offline locator retained byte-for-byte. ZIP CRCs and contents verified, but the new code is not validated in game.

## Test
1. Back up H38 and extract full H39 ZIP beside `Aperion-Win64-Shipping.exe` (preserving `ue4ss/`). Restart Godfall and check `H39_BOOT_MARKER=OK`.
2. In loaded Sanctum before opening skins, press F1 → C once.
3. In the game's original Hinterclaw skins menu, press F1 → C once again.
4. Send `GodfallEnhancedBridge.log` without restarting.

## Stop criterion
If the child offers only generic Coherent plugin APIs and no usable route/source or specific cosmetics bridge data, **stop scanning reflected widgets**. Next requirement will be the **FModel `WBP_GT_Test` asset export** or actual React/Coherent frontend bundle to investigate the real eligibility query. Do not mutate `CosmeticTagToPlayerSkin` or ownership merely because Macros is missing from that map.

Native target still `Character.Player.Hinterclaw.MacrosCosmetic` in original skin UI, surviving refresh and restart.
