# H35: Offline Frontend Resource Locator

## Why H35 exists
H34 actually ran in game (four samples; `H34_BOOT_MARKER=OK`; no fatal diagnostic). The `WBP_Menu_Game_C` class default revealed React routes `settings` and `character-select`, and the live Coherent bridge produced the event name `UE_DATABRIDGE`. These are concrete entry points into the frontend; **they are not cosmetic ownership checks**.

After H26–H34, additional generic `ForEachUObject` scans would repeat old work. The project repository does **not** contain Godfall's original HTML/JS frontend or extracted `WBP_Menu_Game` assets. H35 therefore changes the information source instead of dumping more runtime classes.

## H35 build content
- Keeps **the same H34 Lua behavior**, renaming only the explicit script boot banner and `H35_BOOT_MARKER` for unambiguous installation verification. All H34 probing, H25 A/B material logic and F1 overlay behavior remain unchanged.
- Retains `GodfallEnhanced.asi` and `dxgi.dll` **byte-for-byte** from H34.
- Adds `GodfallFrontendLocator.ps1` and `Run_GodfallFrontendLocator.cmd` at archive root.
- The locator runs **with the game closed**, searches only the installation root (or the script directory if Content/Paks is not found) and writes `GodfallFrontendAssetsReport.txt` at script location. Uses relative paths only.
- Inventories `.pak`, `.ucas`, `.utoc` container **names and sizes** plus plausible loose UI files, and searches small loose text assets for nine marker **names only**. Never copies file contents, uses the network, reads game saves, changes entitlements or extracts packs.
- Output cap: 100 container names, 180 frontend name candidates, 300 text files, max 12MB per scanned loose text. No binary package scanning. Processing time depends on the install size.
- `Run_GodfallFrontendLocator.cmd` starts **PowerShell for this process only** with `-ExecutionPolicy Bypass` so a downloaded unsigned script can run. It does not change any persistent Windows policy. User can inspect the `.ps1` first.
- If packaged assets are all that exist, H35 identifies the relevant container inventory. A follow-up may require targeted manifest listing or a legitimate game asset extractor; **do not ask to upload all multi-GB game archives**.

## One test (no game launch needed)
1. Back up existing mod files. Extract entire H35 ZIP at root beside `Aperion-Win64-Shipping.exe`; preserve `ue4ss/`.
2. Exit Godfall.
3. Double-click `Run_GodfallFrontendLocator.cmd` in the game executable folder.
4. Send `GodfallFrontendAssetsReport.txt` from that folder in the conversation.
5. If the locator reports an error, send its console text. Do not upload entire game archives.

## Acceptance criterion
A **useful H35 result** is a reproducible inventory identifying an actual candidate frontend resource or a packaged content container to inspect next. This is **not** a native unlock. The native unlock succeeds only when `Character.Player.Hinterclaw.MacrosCosmetic` appears in the original cosmetic menu and can be selected (and survives menu refresh/restart).

**Status:** experimental offline resource-discovery helper; new script has not been run on the user's Windows game directory.
