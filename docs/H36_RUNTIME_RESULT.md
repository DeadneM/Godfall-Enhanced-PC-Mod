# H36 runtime result: actual Sanctum Alcove map contents

**Date:** 2026-10-12

**Input:** user-supplied `GodfallEnhancedBridge(8).log`, 56 lines, 5,471 bytes. Original user log not committed to GitHub. **Status: targeted read-only diagnostic validated in game, not a cosmetic unlock.**

## Exactly verified in the user log

- `V0.6H36 Valorplate Alcove Runtime Map Audit` and `H36_BOOT_MARKER=OK`.
- `COMMAND METHOD_C AUTO_NEXT`, `H36_ALCOVE_AUDIT_BEGIN mode=read_only`.
- `H36_INSTANCES_FOUND count=12`, all in `/Game/Aperion/Maps/Development/SeventhSanctum/Seventh_UI`.
- All **12** instances exposed `CosmeticTagToPlayerSkin`, all **12** map iterators finished successfully, yielding **126 entries** across the Sanctuary.
- Per-instance map sizes (actual actor names from log):
  - Beetle: 10
  - Grayehawk: 12
  - Hinterclaw: **9**
  - Illumina: 9
  - Mars: 9
  - Mesa: 9
  - Moebius: 9
  - Mothra: 11
  - Phoenix: 11
  - Silvermane: 16
  - Taurus: 10
  - Typhoon: 11
- Hinderc law [sic: **Hinterclaw**] alcove actor **#3** `BP_VPAlcove_Hinterclaw` listed precisely nine gameplay tags:
  1. `Character.Player.Hinterclaw.Black`
  2. `Character.Player.Hinterclaw.Yellow`
  3. `Character.Player.Hinterclaw.Ice`
  4. `Character.Player.Hinterclaw.Void`
  5. `Character.Player.Hinterclaw.Damascus`
  6. `Character.Player.Hinterclaw.Red`
  7. `Character.Player.Hinterclaw.Pearl`
  8. `Character.Player.Hinterclaw.Lava`
  9. `Character.Player.Hinterclaw.Exalted`
- **`Character.Player.Hinterclaw.MacrosCosmetic` is not present among these nine runtime alcove-map entries.** H23/H25 previously established that its cooked materials and Blueprint do exist locally.
- Each detected class value was reported as `SOFTCLASS_UNRESOLVED`: the H36 inspector successfully decoded the key but did **not** decode the corresponding `TSoftClassPtr` references.
- `H36_ALCOVE_AUDIT_END actors=12 maps=12 visited=126 hinterclaw_matches=9 mutated=0`. No fatal or error messages in the provided 56-line log.

## What this proves, and what it does not

**Proven:** `BP_ValorplateAlcove_C.CosmeticTagToPlayerSkin` is populated at the *placed-level actor* layer even though its FModel class default map was empty; the runtime Hinterclaw list excludes the known shipped `MacrosCosmetic` tag. This is a **specific, testable content difference**, not a general UObject scan. It establishes an actual runtime presentation mapping candidate.

**Not proven:** this actor map is the sole/controlling eligibility gate for the original player cosmetics menu. It may drive Sanctum alcove visual previews only. The count of 126 actor-map entries is not directly comparable to the 124 Valorplate rows in `cosmetics/collection` without deduplication and semantics. Presence in the map is **not proof of account ownership or equip availability**. Absence also does not prove that adding it would unlock the original interface.

## Next decision

Do **not** immediately issue an `Add` on `CosmeticTagToPlayerSkin`, invoke `SetValorplateCosmetic`, or call reward/entitlement/inventory functions. The documented UE4SS `TMap:Add(key,value)` is inherently **mutating** and requires a valid Unreal `FGameplayTag` key and `SoftClass` value. H36 did **not** successfully decode any of those value objects; constructing an unverified `SoftClass` risks bad data or a crash.

**Focused next milestone:** identify an actual reader/consumer of `CosmeticTagToPlayerSkin` (`SetValorplateCosmetic` Blueprint graph/bytecode or related character-selection/alcove UI binding). For this, use FModel export/path navigation around the `Seventh_UI` placed `BP_VPAlcove_Hinterclaw` actor, or a targeted Blueprint graph decompiler if available, rather than yet another broad runtime reflection scan. Independently verify whether the vanilla Hinterclaw cosmetics menu lists precisely these nine entries; a match alone would still be correlation.

If the map is confirmed to control actual cosmetic availability, obtain a reversible, local-only test protocol with validated types and guaranteed rollback. Otherwise, redirect to the correct original UI data-source/filter.

## Version status

- H23: user-validated visual material application.
- H25: material apply/restore in logs.
- H34: React menu routes identified, read-only.
- H35: offline package inventory and FModel exports obtained.
- **H36: live Alcove `TMap` enumeration executed successfully and validated as diagnostic.**
- **Native `MacrosCosmetic` equip: not achieved**. `Unlock Gratitude` and `Unlock All`: not implemented.

No H37 runtime build was created as part of analyzing this log. The GitHub branch `main` remains untouched.

## References

- [UE4SS TMap API](https://docs.ue4ss.com/dev/lua-api/classes/tmap.html): `ForEach`, `Add`, `Remove` semantics.
- [UE4SS FindAllOf API](https://docs.ue4ss.com/dev/lua-api/global-functions/findallof.html): loaded actor discovery (expensive; bounded manual use).
