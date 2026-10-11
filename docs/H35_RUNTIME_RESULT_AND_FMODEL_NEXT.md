# H35 – User runtime report and next asset-inspection milestone

**Date:** 2026-10-11
**Source:** user-supplied `GodfallFrontendAssetsReport.txt`, 39 lines, 1,996 bytes (raw user file not committed).
**H35 status:** offline locator **executed successfully** on user's Windows installation. It is a diagnostic, **not an unlock**.

## Exact findings

- `ScanRoot=GAME_CONTENT_ROOT`
- `PACKAGED_GAME_DATA count=23`
- `FRONTEND_NAMED_ASSETS count=0`
- `LOOSE_TEXT_FILE_SCAN available=0 max_files=300`
- `TEXT_SCAN_SUMMARY checked=0 matched_files=0`
- `Mutation=report_file_only; game_files_unchanged`

The installation has:
- `global.ucas` / `global.utoc`.
- Seven sets `pakchunk0-WindowsNoEditor` through `pakchunk6-WindowsNoEditor`, each with `.pak`, `.utoc` and `.ucas` files (7 × 3 = 21; global pair = 2; total 23).
- The largest listed `.ucas` is `pakchunk0-WindowsNoEditor.ucas` at `27184.19MB`; other listed chunks range down to `149.79MB`. Do **not** ask users to upload multi-GB chunks.

## Interpretation and limitation

The target Godfall installation uses **IoStore** containers (`.utoc` = table of contents/index, `.ucas` = content). Finding zero loose frontend filenames or text files means H35 could not inspect a local standalone React/JS bundle. It **does not prove** that the React UI is actually packaged locally, that it exists under a searchable name, or that any specific archive contains the original cosmetics menu.

**Important unresolved contrast:** H34 observed a live Coherent HTTP URL classified `origin=non_loopback` (redacted). It is possible that some frontend code/resources come from a remote HTTP service rather than the installed game. `ReactCharacterSelectURL = character-select` is only a WBP_Menu_Game_C class-default relative route, not a cosmetic ownership gate.

## Decision

**No H36 generic runtime scan.** Next obtain a **targeted IoStore package listing / selected asset export**, not all files:

1. Run [FModel](https://github.com/4sval/FModel/releases) on the game's `Content\Paks` directory (see [official getting started](https://github.com/4sval/FModel/wiki/Getting-Started)). Use the engine version corresponding to the user's game build; do not assume a particular UE4/UE5 version based solely on `.ucas` files. If the game is encrypted, FModel may require an AES key; do not guess one.
2. Search the visible *package names/paths* (not every object in memory) for `WBP_Menu_Game`, `BP_ValorplateAlcove`, `Coherent`, `Cosmetic`, `CharacterSelect`, `Hinterclaw`; collect only matched package **paths** plus small JSON property exports, beginning with `WBP_Menu_Game`. Do not dump textures, movies, the entire character asset bank or account/network payloads.
3. If FModel lists IoStore but cannot read it, record the tool's error / engine version / encryption indicator and stop rather than attempting blind extraction.
4. Compare the selected exported metadata against previous findings: `UE_DATABRIDGE`, `settings`, `character-select`, `cosmetics/collection` and the known local `Character.Player.Hinterclaw.MacrosCosmetic` catalog entry. Seek the **actual query that determines menu inclusion and selection**.
5. Only then propose a safe, reversible H36 test explicitly tied to that query. No server entitlement changes.

References:
- [FModel Getting Started](https://github.com/4sval/FModel/wiki/Getting-Started)
- [Understanding Pak vs IoStore](https://modding.wiki/en/UnrealEngineModdingGuides/UnderstandingPakVsIoStore)
- [FModel settings explanation](https://github.com/4sval/FModel/wiki/Settings-Explanation)

## Final status

**H23**: visual Macros application validated.
**H25**: visual application/restoration logs confirmed.
**H34**: React route/default-value diagnostic performed in game.
**H35**: offline inventory completed; 23 packaged containers, no loose frontend assets.
**Native cosmetic unlock**: still not demonstrated. `Unlock Gratitude` and `Unlock All` not implemented.

**Next input:** FModel screenshot or exported text/JSON showing the relevant package tree / `WBP_Menu_Game` properties. Only that narrowly scoped content, not complete game archives.
