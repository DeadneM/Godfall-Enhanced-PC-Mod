# H37 in-game test: native cosmetics view correlation (2026-10-14)

**Source:** user-provided `GodfallEnhancedBridge(9).log` (141 lines, 17,474 bytes). Full user log not committed. **Status:** runtime probes executed without a logged fatal error; cosmetic unlock still not achieved.

## Confirmed execution

- Correct bridge: `V0.6H37 Multi-Probe Alcove + UI`, `H37_BOOT_MARKER=OK`.
- Two `COMMAND METHOD_C AUTO_NEXT` invocations were logged.
- `H36_ALCOVE_AUDIT_END actors=12 maps=12 visited=126 hinterclaw_matches=9 mutated=0`; all 12 maps still readable.
- `H37_CLASS_AUDIT_END functions=36 properties=28 mutated=0`; names from `BP_ValorplateAlcove_C` include `SetValorplateCosmetic`, `SetAlcoveToOwned`, `ResetAlcoveToUnowned`, and `CosmeticTagToPlayerSkin`. These names **do not** establish a menu availability decision.
- Nine live Hinterclaw cosmetic keys remain Black, Yellow, Ice, Void, Damascus, Red, Pearl, Lava, Exalted; `Character.Player.Hinterclaw.MacrosCosmetic` is absent from this alcove map.
- All nine value probe results: `type=TSoftObjectPtrUserdata path=UNRESOLVED`. H37's broad heuristic accessors did **not** reveal an asset path. No additional value inference should be made.

## Crucial two-state UI comparison

```text
H37_UI_SNAPSHOT_BEGIN sample=1 stage=SANCTUM_BASELINE
H37_UI_WIDGET class=WBP_GT_Test_C present=0
H37_UI_WIDGET class=WBP_Menu_Game_C present=0
H37_UI_SNAPSHOT_END sample=1 mutated=0

H37_UI_SNAPSHOT_BEGIN sample=2 stage=VANILLA_MENU_COMPARISON
H37_UI_WIDGET class=WBP_GT_Test_C present=1
H37_UI_WIDGET class=WBP_Menu_Game_C present=0
H37_UI_SNAPSHOT_END sample=2 mutated=0
```

The user followed the intended sequence: Sanctum baseline, then opening original Hinterclaw cosmetics. The `WBP_GT_Test_C` instance was **absent before and present after**. This is the first tightly controlled native-widget correlation with the relevant menu.

**Interpretation:** `WBP_GT_Test_C` is a strong candidate for the *frontend host active while the cosmetics screen is open*. This is **not proof** that the widget implements the cosmetics filter or owns any entitlement data. `WBP_Menu_Game_C` was absent on both snapshots, suggesting its settings/character-select routes were an adjacent navigation path, not the active cosmetics frontend during these samples.

## Targeted next steps

1. Prioritize `WBP_GT_Test_C` and its attached `CoherentUIGTWidget` in the active vanilla cosmetics screen. Compare class property/function **names and safe property types**, and read sanitized `URL` / resource **route categories only**. No JavaScript event payloads or headers, no account/server data, no user paths.
2. Ask FModel for a **single `WBP_GT_Test` package JSON export** if available; trace native widgets/bridge functions to menu cosmetics query. FModel reflected JSON does not directly give compiled Blueprint call edges.
3. Build H38 only as a bounded read-only *frontend-instance* probe with a defined test (one baseline, one cosmetics state). Do **not** add/modify `CosmeticTagToPlayerSkin` or call `SetValorplateCosmetic` based on this correlation.
4. Keep A/B H25, F1, original ASI/DXGI, and H35 offline locator byte-identical. Keep `main` stable.

**Acceptance for actual unlock:** `Character.Player.Hinterclaw.MacrosCosmetic` must appear in original cosmetics UI and be equipable there, surviving refresh and restart. H37 did not achieve this.
