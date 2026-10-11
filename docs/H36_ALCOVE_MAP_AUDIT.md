# H36: Focused BP_ValorplateAlcove live map audit

## FModel evidence, 2026-10-11
User provided `Texte collé(2).txt` (205,856 bytes), a valid FModel JSON export of **44 objects** from `/Game/Aperion/Blueprints/Environment/BP_ValorplateAlcove`: 37 functions, one generated class, one class-default actor, scene components and construction script objects.

**Confirmed:**
- `CosmeticTagToPlayerSkin` is a reflected `MapProperty` with **GameplayTag struct keys** and **SoftClass<BP_Player_C> values** (editable, Blueprint visible).
- `SetValorplateCosmetic(CosmeticGameplayTagString: StrProperty, CosmeticGameplayTag: GameplayTag)` is a reflected BlueprintCallable/BlueprintEvent function.
- `ExecuteUbergraph_BP_ValorplateAlcove` generated parameter list includes custom event cosmetic tag fields and `CallFunc_MakePrimaryAssetIdFromGameplayTag_ReturnValue`.
- Class default object `Default__BP_ValorplateAlcove_C` has **no `CosmeticTagToPlayerSkin` values** in its 22 exported Properties. The map may be empty by default or edited in placed level actors. No map contents can be inferred from the class declaration alone.
- This Blueprint governs *Sanctum alcove presentation/progression*: functions include `SetAlcoveToOwned`, `ResetAlcoveToUnowned`, `SetAlcoveToAscendant`, `SetAlcoveToExalted`, `CompleteExaltedCosmeticObjective`. These do **not** prove ownership over Gratitude cosmetics, and calls may affect gameplay state. Do not invoke them.

**No** `MacrosCosmetic`, `GetCosmeticOverride`, `IsCosmeticEnabled`, `DataBridge` or entitlement-query reference was found in the export. FModel JSON lists reflected signatures, **not executable Blueprint graph instructions**.

## H36 experiment: one-shot, in-game and read-only
- Starts from H35 Lua source, keeps F1 overlay/H25 A+B visual methods and H34 React watcher available by `COHERENT_PROBE` command.
- Makes **Method C** perform a single `FindAllOf("BP_ValorplateAlcove_C")`, UE4SS documented API. Finds **only non-default instances**, so this specifically tests whether placed Sanctum instances provide map entries absent from the CDO.
- Reads `CosmeticTagToPlayerSkin` with guarded UE4SS `GetPropertyValue()` or direct field; when possible invokes documented `TMap:ForEach` **without mutation**. Logs actor counts, map sizes and only keys matching `hinterclaw`, `macros` or `gratitude`, with any safe class names; caps 20 actors, 128 map entries/actor and 48 matching lines.
- Uses GameThread existing bridge for Method C. Runs no hooks, no `Add`, no map edits, no `SetValorplateCosmetic`, no entitlement or network operations. Native UE4SS access still carries nonzero crash risk; run manually only once after Sanctum load finishes, never during transition.
- If `FindAllOf` finds no instances, or map/struct support is unavailable, the build logs explicit failures. That result does not mean the ownership filter is absent.

## Test and acceptance
1. Back up H35. Extract H36 at exe root, preserving `ue4ss/`. Close / restart the game to ensure H36 loaded (`H36_BOOT_MARKER=OK`).
2. In Sanctum, wait for all loads to complete. Press **F1 → C** once. Do not use A or B for this test.
3. Send `GodfallEnhancedBridge.log` before restart. Focus on `H36_INSTANCES_FOUND`, `H36_ALCOVE_MAP_SIZE`, `H36_ALCOVE_MATCH`, `H36_ALCOVE_AUDIT_END`.
4. A useful diagnostic is evidence of which cosmetic tags/classes are present in placed alcoves. It is **not** native unlock. No new skin can be claimed as selectable without testing in the original UI.

**Status:** built from new concrete FModel signature; in-game untested. H23 remains validated visual application; H35 offline locator previously user-tested. Respect `DEVELOPMENT_RULES.md`.
