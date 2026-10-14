# H44: four separate triggers, one experimental test session

## Design goal

Following H43's confirmed **UE4SS GameThread access violation** (`0xC0000005`, read `0xffffffffffffffff`, UE4SS `+0x3E60BE`), the user explicitly requested four separate triggers. The crashing H43 *combined* code is **not the parent** of this branch. H44 is based on the safer, previously user-tested **H41**, with H25 visual A/B and original compiled ASI/DXGI unchanged. Experimental native operations are **not invoked at startup or by F1 C**.

## Hotkey map

| Key | Independent action | Expected effect | Risk |
|---|---|---|---|
| **F6** | `H44_VISUAL` | Already validated H25: put Macros materials on Hinterclaw | Lower, but revert not exact for dynamic MIDs |
| **F7** | `H44_MAP` | Attempt one temporary `TMap:Add` to Hinterclaw Alcove map | **High native risk**, UClass→SoftClass conversion unproven |
| **F8** | `H44_OVERRIDE` | Attempt one `APCosmeticsManager:AddCosmeticOverride` local request | **High native risk**, native marshalling unproven |
| **F9** | `H44_PREVIEW` | Attempt one `BP_ValorplateAlcove:SetValorplateCosmetic` call | **High native risk**, guessed struct parameters |
| **F10** | `H44_REVERT` | Best-effort undo of this build's map, manager and materials | May also carry native risk; cannot undo original Alcove preview precisely |

The user's original F1 menu is unchanged: A/B material apply/restore; **C only prints key help** instead of arming hooks or triggering all native experiments. The H41 DataBridge tracer still exists as *manual* `DATABRIDGE_TRACE_TOGGLE` command, but is **not auto-started**. Each independent trigger has a manual fallback with the name in the table, to place as text in `ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt`; file is automatically consumed by existing bridge.

Every hotkey is registered using UE4SS documented `RegisterKeyBind(Key.F6, callback)`; callbacks schedule their own operation with `ExecuteInGameThread` and log `H44_TRIGGER` and `H44_NATIVE_BEGIN` **before any hazardous native call**. If the game crashes again, the latest marker isolates the trigger and stage. Key registration failures have a manual command fallback. No global process hooks added by H44.

## Explicit tradeoffs

- No acquisition, account ownership, save, reward, loot, session or server operations.
- F7 and F8 may fail gracefully if the Macros Blueprint isn't loaded: H42 already saw `NO_MACROS_CLASS`, so failure of the precondition is **not mistaken for a successful trial**. H44 tries exactly one known package `LoadAsset` if needed instead of H43's multi-path speculative class loading.
- F7 uses the real CDO gameplay tag and real Macros UClass; no fallback to Black. However the UClass may be incompatible with the map's SoftClass value type and could cause a C++ fault even under Lua `pcall`.
- F8 uses the previously reflected CosmeticsManager method, but `{GameplayTags={}}` is unverified marshalling. It is **unsafe without validating the native signature**. This remains a separately activated high-risk experiment rather than being silently executed.
- F9 only tests the Alcove Blueprint method, **not player-owned skin**. The struct `{TagName=FName(Macros)}` is a best-effort Lua struct conversion and may be rejected or crash.
- F10 only attempts to remove entries which H44 itself recorded inserting. A native preview call has no known safe inverse. If the Alcove display stays changed, reload the Sanctum.
- The Macros class package path is inferred from previous H42/H43 code and may be wrong. This does not justify retrying arbitrary `LoadAsset` paths: the user specifically wants a crash source isolated.

## One-session safe testing advice

Start **only with F6** on equipped Hinterclaw in loaded Sanctum, which uses the validated existing visual path. Then decide whether to test the unvalidated and explicitly high-risk F7, F8, or F9, **one trigger at a time**. Do not press all risky triggers blindly. If a native crash occurs, **do not retry the same key**; return to H41 and send the most recent log. F10 attempts rollback while still in the same level.

A test is a **native unlock** only if Macros appears as a selectable entry in the original cosmetics UI, not merely when an Alcove or material visually changes. Native actions have not been tested with the user's game yet, and no safety guarantee exists.

UE4SS keybind docs: https://docs.ue4ss.com/dev/lua-api/global-functions/registerkeybind.html

## Status
- H41: source baseline, confirmed by user for DataBridge capture.
- H43: **crashes**; not a safe build.
- H44: sources created, separately triggered experimental actions, awaiting in-game validation.
