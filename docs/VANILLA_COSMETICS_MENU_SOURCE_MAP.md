# Godfall original cosmetics menu: evidence-based source audit (2026-10-14)

**Objective:** Find the actual decision point that generates and filters the *vanilla* cosmetics list, then the request that applies a selected cosmetic. The first target is `Character.Player.Hinterclaw.MacrosCosmetic`, the physically shipped Gratitude skin. We must not call an appearance swap a genuine unlock.

**This is RESEARCH ONLY.** No ASI/Lua build, game injection, native mutations, account entitlements, session edits, reward grants or need to restart Godfall.

## Confirmed structural observations (already in repository)

| Component | Concrete evidence | What it does NOT prove |
|---|---|---|
| SourceData `cosmetics/collection` | 163 local entries: 124 Valorplates, 26 weapons, 7 banners, 6 spectral weapons. Rows: `gameplayTag`, `forGameplayTag`, `cosmeticClass` | Neither ownership nor whether UI renders each row |
| Macros visual asset | FModel `BP_Hinterclaw_MacrosCosmetic_C` CDO tag `Character.Player.Hinterclaw.MacrosCosmetic`; four working Macros materials, H25 | Native selectable/owned cosmetic |
| Native loadout | H9–H19 vanilla equip experiment showed root `gameplayTag` and `cosmetics.valorplates["0"]` change upon explicit skin selection | That patching this JSON unlocks skins (it failed) |
| Original skins menu UI | H37–H39 show `WBP_GT_Test_C` loads when the actual cosmetics view is open; child `CoherentUIGTWidget_Persistent_90` belongs to the WidgetTree, not direct WBP outer | Native widget handles list, owns entitlements or contains JS UI code |
| Coherent host hierarchy | FModel: `WBP_GT_Test_C → WBP_GT_Settings_C → WBP_GT_Base_C → WBP_UserWidget_C` | All request types are cosmetic requests |
| DataBridge boundary | FModel: `WBP_GT_Base_C:OnDataBridgeIncomingRequest(Type:FString,Payload:JsonObjectWrapper,Promise:PromiseHandle)`; settings subclass override; H40 proved live events and clean hook removal | Returned list data, inbound/outbound business logic, ownership flag |
| Names from H40 | `UE_ROUTE_UI`, `UE4_SHOW_LOADOUT_VISUAL_REQUEST`, `UE4_HIDE_LOADOUT_VISUAL_REQUEST`, `UE4_SHOW_LOADOUT_WEAPON_VISUAL_REQUEST`, `UE4_PLAY_AUDIO_CUE`, `UE4_PLAY_MUSIC` | Cosmetic equip/unlock operations or distinct player actions |
| Menu navigation | FModel `WBP_Menu_Game_C`: `ReactSettingsURL="esc-menu/settings"`, `ReactCharacterSelectURL="character-select"`; `OpenCharacterSelect`, `DataBridgeOutgoingRequest`, `ThenPromiseJson` compiler-generated references | `character-select` definitely handles cosmetics list, or DataBridge responses contain skin inventory |
| Coherent resource | H33/H34 observed a live HTTP-scheme non-loopback URL, actual host/path redacted; H35 local install scan saw 23 container files and zero loose frontend resources | JS necessarily hosted online rather than embedded/packaged, or that observed URL is the cosmetics view |
| Alcove map | H36: 12 Sanctum alcoves, Hinterclaw nine maps entries and no Macros. H45 F7/F8 crash, F9 no visible result. | This map controls the native skins list or is a safe unlock gateway |

### Actual unknown edge

```text
cosmetics/collection
     │
     ▼
??? SourceData resolver + player/profile/session ownership state ???
     │
     ▼
??? Native DataBridge reply / frontend state selector/filter ???
     │
     ▼
Coherent/React UI  <-->  WBP_GT_Test / WBP_GT_Base
     │  user chooses skin
     ▼
??? DataBridge outgoing request + player loadout handler ???
     │
     ▼
cosmetics.valorplates["0"] / character gameplayTag
```

This is a **hypothesis diagram**, not a proven exact implementation sequence. The two unknown edges are what reverse engineering must recover.

## What source to inspect next (in priority order)

### A. Original frontend UI code, IF it can be located

Goal: find the JS/HTML bundle actually loaded into the Coherent view for the original player skins menu. Search locally packaged resources and Coherent base resource config for the `character-select` route, `UE_DATABRIDGE`, `UE_ROUTE_UI`, `UE4_SHOW_LOADOUT_VISUAL_REQUEST`, `cosmetics/collection`, `valorplates`, `Hinterclaw`, `cosmetic`, `skin`, `owned`, `unlocked`, and `disabled`. Search only **assets/source**; never extract account tokens, player profiles or sensitive network data into a shared log.

The Coherent SDK explicitly supports loading a whole UI over HTTP(S), but H34's observed non-loopback URL is **not proof** that Godfall's entire frontend is remote. Inspect the **view's actual resource URL/config** or original UI resource references, rather than guessing a CDN.

If JS is found, map:
1. component/data selector builds list; source of its collection;
2. filter/label conditions for locked, hidden or unavailable;
3. the exact outgoing request Type and payload *schema* when selecting a normal owned skin;
4. game-side request handler and how it refreshes the UI.

### B. Decompile cooked Blueprint execution logic (not merely FModel JSON metadata)

FModel JSON exports previously gave UClass properties and compiler-generated `CallFunc_...` names, **not Blueprint bytecode control flow**. Request **decompiled Kismet pseudocode/bytecode** for these 4 specific assets, in this order:

1. `/Game/Aperion/Blueprints/UI/WBP_GT_Base`, especially `OnDataBridgeIncomingRequest`, `ExecuteUbergraph_WBP_GT_Base`, `GetCoherentUIGTWidget`.
2. `/Game/Aperion/Blueprints/UI/WBP_GT_Settings`, especially its override of `OnDataBridgeIncomingRequest` and the `Super` call behavior.
3. `/Game/Aperion/Blueprints/UI/Menus/WBP_Menu_Game`, especially `OpenCharacterSelect`, `DataBridgeOutgoingRequest`, `ThenPromiseJson`, route changes/refresh.
4. `BP_GameInstance` (FModel search by package name; exact path not established), especially DataBridge binding/incoming request dispatch, UI routing and cosmetic-lookup calls. `APGameInstance` is a native class, so Blueprint decompilation can reveal CALLS to it, not its C++ function body.

If H35 FModel archives have no HTML/JS, check frontend-related package names/resource paths before larger extraction. A full game dump is not requested.

**Tooling (read-only, offline):**
- Current FModel releases report Blueprint decompilation support (release notes `dec-2025`) and asset property extraction. Verify available decompile/export UI on the installed version; options can vary.
  https://github.com/4sval/FModel/releases
- `KismetKompiler` documents `decompile -v 4.27 -i input.uasset -o output.kms`, with `--usmap <mapping.usmap>`, `--global <global.ucas/utoc>` when IOStore assets require it; this is a secondary option, not guaranteed to handle every Godfall 4.27 asset.
  https://github.com/tge-was-taken/KismetKompiler
- Another option, `UE4Decompiler graph <input> <asset-path> --format pseudo`, is documented in its CLI, but **compatibility with this specific Godfall container is unverified**.
  https://github.com/ODModdingHub/UE4Decompiler/blob/main/docs/cli.md

**Smallest useful input from user:** a single decompiled code/text export from `WBP_GT_Base` and `WBP_Menu_Game` focused on the named functions, plus a screenshot/list of any actual `character-select` frontend resource file FModel discovers. No game launch or F1 interaction. A plain FModel property JSON alone cannot fully resolve the call graph; do not falsely interpret compiler temp properties as executable logic.

## What the next engineering task should output

Produce a grounded, line-supported graph with **four nodes**:
1. Catalogue retrieval (call and data structures)
2. Possession/eligibility decision (function + precise condition, if found)
3. UI list assembly and refresh (frontend/Coherent/Blueprint path)
4. Vanilla selection/equip command and target handler (argument format, return check)

Explicitly annotate **PROVEN / INFERRED / UNKNOWN** and give a focused read-only artifact request for missing edges, not another repeating in-game logger.

Only once we can identify an **actual local-only visible/owned flag** with safe schema and rollback should we consider new mutation tests. No `H46` runtime build justified yet. H41 remains the safer user-tested source base; H43 and H45 native acquisition calls are retired after crashes.

## Precise criteria for native success

`Character.Player.Hinterclaw.MacrosCosmetic` appears in the game's **original** cosmetics list and is selectable through it, survives UI reopening and ideally game restart. Only then consider mapping the rest of Gratitude's 12 known skins and optional Unlock All.

## Source references (internal)
- [TECHNICAL_NOTES](TECHNICAL_NOTES.md), [OWNERSHIP_PIPELINE_ANALYSIS](OWNERSHIP_PIPELINE_ANALYSIS.md), [H35_FMODEL_EXPORTED_ASSET_ANALYSIS](H35_FMODEL_EXPORTED_ASSET_ANALYSIS.md)
- [H34 runtime](H34_RUNTIME_LOG_ANALYSIS.md), [H39 FModel host](H39_FMODEL_WBP_GT_TEST_EXPORT.md)
- [H40 live DataBridge](H40_RUNTIME_RESULT_SECOND_TEST.md), [H45 crashes](https://github.com/DeadneM/Godfall-Enhanced-PC-Mod/blob/dev/h45-native-asset-tag-repair/docs/H45_CRASH_AUDIT.md)
