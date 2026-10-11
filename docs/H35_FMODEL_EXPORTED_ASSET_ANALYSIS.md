# H35 FModel asset exports: WBP_Menu_Game and MacrosCosmetic

**Date:** 2026-10-11. **Source:** user-provided FModel-exported JSON-like attachment `Texte collé(1).txt` and Markdown-formatted JSON export `Markdown collé (2).md`. Files were parsed locally, **not** copied wholesale into the repo. Status: **confirmed asset structure; no unlock**.

## Export 1: WBP_Menu_Game

- File parses as a JSON array of **227 Unreal-exported objects**, including **69 Function** objects, one `WidgetBlueprintGeneratedClass` (`WBP_Menu_Game_C`) and one class default object (`Default__WBP_Menu_Game_C`).
- Package: `/Game/Aperion/Blueprints/UI/Menus/WBP_Menu_Game`.
- The CDO contains **exact values** (more precise than H34's URL *leaf* summary):
  - `ReactSettingsURL = esc-menu/settings`
  - `ReactCharacterSelectURL = character-select`
- The `WBP_Menu_Game_C` class has both as `StrProperty`, with `Edit | BlueprintVisible | DisableEditOnInstance`.
- Named functions include `OpenCharacterSelect`, `OnPersonalMenu`, `OnProgressionDone`, `Construct`, `ReturnToBase`, and multiple confirmation / input handlers.
- Its widget tree includes buttons for Resume, Settings, Quit, CharacterSelect, SkipTutorial and other menu actions. **It is a game/pause/menu navigation widget, not yet identified as the cosmetic-selector implementation.**
- The function export for `ExecuteUbergraph_WBP_Menu_Game` has **205** generated child properties. It includes:
  - `CallFunc_DataBridgeOutgoingRequest_ReturnValue` (`StructProperty`)
  - `CallFunc_DataBridgeOutgoingRequest_ReturnValue_1` (`StructProperty`)
  - `K2Node_MakeStruct_JsonObjectWrapper`
  - `CallFunc_MakeJsonObject_ReturnValue`
  - `CallFunc_ThenPromiseJson_ReturnValue`
- These generated property names are **evidence of Blueprint-compiled references to the DataBridge request/promise pipeline**; the JSON export does not reconstruct execution order, bridge payload, resulting JavaScript endpoint or cosmetics eligibility test. **Do not claim that the bridge is a cosmetic unlock check.**
- No `Cosmetic`, `Skin`, `Entitlement` or `Unlock` property relevant to ownership was located in the CDO or class export. Generic `FUNC_BlueprintCosmetic` is a UE function attribute unrelated to cosmetic inventory.

## Export 2: BP_Hinterclaw_MacrosCosmetic

The uploaded Markdown was an escaped and HTML-entity-encoded copy of FModel JSON. After stripping Markdown escaping/formatting and converting non-breaking spaces, the file **parsed as 28 objects**.

- Package: `/Game/Aperion/Blueprints/Characters/Player/Hinterclaw/Skins/BP_Hinterclaw_MacrosCosmetic`.
- Child Blueprint `BP_Hinterclaw_MacrosCosmetic_C` derives from `BP_Hinterclaw_C`.
- CDO `Default__BP_Hinterclaw_MacrosCosmetic_C` has `GameplayTag.TagName = Character.Player.Hinterclaw.MacrosCosmetic`.
- `SkeletalMeshComponent CharacterMesh0` contains 4 material overrides in order:
  0. `/Game/Aperion/Characters/Macros/Materials/MI_Macros_lower`
  1. `/Game/Aperion/Characters/Macros/Materials/MI_Macros_Fur`
  2. `/Game/Aperion/Characters/Macros/Materials/MI_MAcros_Cloth` (note capitalization `MI_MAcros` in FModel path)
  3. `/Game/Aperion/Characters/Macros/Materials/MI_Macros_Upper`
- These findings corroborate the already visually proven H23-H25 technique. They do **not** reveal ownership, menu visibility or account entitlements.

## What to inspect next, and why

**First priority: `BP_ValorplateAlcove` (export only).** The H29 runtime findings previously mentioned its `CosmeticTagToPlayerSkin` map. This is a *specific* candidate bridge from gameplay cosmetic tags to displayed/equipped Valorplate appearances, closer to the in-game selection interaction than the pause menu.

Request a focused FModel `Export > JSON` for the actual `BP_ValorplateAlcove` package (or the matching package that defines `CosmeticTagToPlayerSkin`), especially class default object, map/property names, and relevant functions.

**Second priority, only if found:** actual Coherent bridge host `WBP_GT_Test` / `WBP_GT_Test_C`, or a widget/Blueprint whose name clearly references `Cosmetic` or `Valorplate`. Check for actual menu filtering rather than broad unrelated UI searches.

No H36 build is justified on these two exports alone. Only build a targeted local reversible test once a genuine inventory/filter path is identified. No saving/network/entitlement manipulation without evidence and rollback. The original menu should show and equip `MacrosCosmetic` before attempting `Unlock Gratitude` / `Unlock All`.
