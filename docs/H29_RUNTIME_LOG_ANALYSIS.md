# H29 user test log analysis - 2026-10-09

## Source and validation

Source: user-uploaded `GodfallEnhancedBridge(2).log` (208 lines). This note records observed log facts, not inferred success of any cosmetic unlock. The raw user log is intentionally not committed.

Build: `V0.6H29 Cosmetic UI State Trace / F1 overlay`. `H29_BOOT_MARKER=OK`, and `H24_NO_HOOKS=TRUE`.

- `COMMAND METHOD_A AUTO_NEXT` at source line 8.
- `H25_APPLY_OK changed=4 verified=4 target=Character.Player.Hinterclaw.MacrosCosmetic` at source line 39. The existing Gratitude Macros visual material override still works.
- `COMMAND METHOD_C AUTO_NEXT` at source line 41.
- `H29_UI_AUDIT_BEGIN snapshot=1 mode=READ_ONLY` at source line 53.
- `H29_UI_SNAPSHOT id=1 scanned=245390 names=91 candidate_classes=35 other=56` at source line 54.
- `H29_UI_BASELINE_SAVED` at source line 146.
- `H29_UI_AUDIT_END snapshot=1 objects=91 classes_inspected=14 functions=38 properties=9 mutated=0` at source line 208.
- There is **no** `H29_UI_AUDIT_BEGIN snapshot=2`, `H29_UI_DIFF`, `H29_UI_ADDED`, or `H29_UI_REMOVED`. The central before/after menu comparison **did not run**. No crash or fatal diagnostic message is visible in the supplied log.

### New reflected affordance worth following up

The class `BlueprintGeneratedClass /Game/Aperion/Blueprints/Environment/BP_ValorplateAlcove.BP_ValorplateAlcove_C` was inspected. Its reflection includes:

- `CosmeticTagToPlayerSkin` as a **MapProperty** (log line 172);
- `SetValorplateCosmetic` (line 168);
- `CompleteExaltedCosmeticObjective` (line 162);
- `SetAlcoveToOwned` and `ResetAlcoveToUnowned` (lines 163-164);
- `Asset_AlcoveAccent_Owned` and `Asset_AlcoveAccent_Unowned` (lines 177-178).

**Interpretation:** the Sanctuary alcove plausibly holds an internal mapping from cosmetic gameplay tags to player-skin assets, which is a concrete link between the cosmetic tag and visual representation. This is *not* evidence that the alcove's `SetAlcoveToOwned` flips a cosmetic entitlement. The "Owned" terminology may refer to the Valorplate alcove/plate state, not a Gratitude skin. **Do not call those methods until their semantics are understood.**

The baseline included `WBP_Menu_Game` character-selection button/tree references and `WBP_HUD_Valorplate_Title` HUD tree objects, but no proven live native **cosmetics selection screen** widget. Therefore the snapshot cannot yet describe the cosmetic menu's visibility/eligibility checks.

## Limitations of H29 implementation

1. It stores baseline object **names**, not properties/visibility flags, and a menu made of persistent widgets can yield few or no added objects.
2. Name filter contains broad tokens such as `skin`, `preview` and `valorplate`, so 91 matches include unrelated class defaults, Niagara preview classes, Silvermane skin objects and generic HUD widgets.
3. Class metadata scan includes the first 14 class candidates (encounter/inclusion then sorted), rather than prioritizing actual UI widget classes. This can miss the UMG class performing catalog filtering.
4. This single log was taken after applying Method A. For a clean comparison, avoid Method A before the first snapshot; it changes materials and can influence the widget/object set.
5. Nothing in H29 reveals actual account entitlement values or performs a native unlock.

## Next concrete test, *no new ZIP required*

With H29 in a **single uninterrupted session**:

1. At Sanctum, outside Hinterclaw's vanilla skin menu, launch Method C once (**without Method A**). Expect `H29_UI_BASELINE_SAVED`.
2. Open the vanilla Hinterclaw cosmetic selection screen and keep it open.
3. Launch Method C again. If F1 conflicts with game UI, put the exact text `UNLOCK_UI_AUDIT` into `ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt` while the game is running.
4. Check the final log for `H29_UI_DIFF` and `H29_UI_AUDIT_END snapshot=2`; share the full log before quitting/restarting, because the logger resets and snapshots are process-local.

If the second snapshot's diff contains no UI clues, improve the *next* read-only build to identify **live `UserWidget` instances**, ranking UI classes above unrelated skins; do not repeat global native inventories.

## Fixed goal

The test target is the known Gratitude Pack skin `Character.Player.Hinterclaw.MacrosCosmetic`. Visual swapping has been proven. Only a skin **visible and selectable in the game's native cosmetics list**, with persistence tested after refresh/restart, qualifies as a true unlock. Continue toward `Unlock Gratitude`, then `Unlock All` only after one native unlock has been shown.

**Status:** H29 launched, material A verified, snapshot 1 succeeded; native unlock still NOT validated. H29 remains the current test release.
