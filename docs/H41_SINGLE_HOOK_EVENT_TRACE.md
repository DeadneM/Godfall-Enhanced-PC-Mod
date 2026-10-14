# H41: single native DataBridge hook, request-order timeline and counters

**Why:** the validated H40 session on a Valorplate with unlocked skins produced 48 events and clean `unregistered=2 errors=0`, but BASE and SETTINGS hooks logged the same six request types in parallel. The 48-event budget was exhausted rapidly. H40 was armed a second time when the log ended, so the second cleanup was not observed. [Primary evidence](../docs/H40_RUNTIME_RESULT_SECOND_TEST.md).

## H41 changes, no broad hook expansion

- Only **one exact proven Blueprint UFunction** remains active after manual **F1 → C**:
  `/Game/Aperion/Blueprints/UI/WBP_GT_Base.WBP_GT_Base_C:OnDataBridgeIncomingRequest`.
- Names of requests are logged in callback **order** with ordinal `n` and running counts (`H41_BRIDGE_EVENT`), capped at 32 lines per name for loadout/route/skin/cosmetic/weapon-like types and 2 for background audio or other types.
- A single `H41_BRIDGE_STOP` at manual stop, 160 callback events or approximately 90 seconds, followed by sorted `H41_BRIDGE_SUMMARY` type→count entries, max 30 types.
- Native UFunction is registered **only when `WBP_GT_Test_C` is loaded** and never at game boot. Uses documented numeric hook IDs for `UnregisterHook`.
- Logs only sanitized request **Type**, not Payload, Promise, game/account IDs, full UI routes or other content. Native callback returns no value. No changes to achievements, inventories, cosmetic ownership, saves, account or network state.
- Corrects inherited misleading boot line to `H41_HOOKS=OPTIONAL_ON_C_ONLY`.
- Keeps previous H40 helper code but makes H41 the only C-exposed tracer. Keeps H25 A/B, overlay F1, previous manually available alcove and Coherent probes and H35 offline locator, same ASI/DXGI binaries.

## Procedure

1. Back up H40 files, install H41 full ZIP beside `Aperion-Win64-Shipping.exe`, retain `ue4ss/`, restart. Verify `H41_BOOT_MARKER=OK`.
2. In loaded Sanctum, open original cosmetics screen on a Valorplate with multiple **owned** skins.
3. **F1 → C once** to arm. Close mod overlay; navigate and select 3–4 *owned* skins in normal menu.
4. **F1 → C again** to stop before 90 seconds (or let auto-stop). If auto-stopped, do **not** press C again, as it would start a new window.
5. Send `GodfallEnhancedBridge.log` before game restart. Expect `H41_BRIDGE_STOP .. unregistered=1 errors=0` and sorted summary.

**Why this matters:** matching events to manually selected skins may reveal which native requests update presentation. Names such as `UE4_SHOW_LOADOUT_VISUAL_REQUEST` do **not** prove entitlement or actual catalog membership. The user’s `MacrosCosmetic` original-menu unlock remains **unimplemented**. If this trace shows no new relevant Type, the next step is static Blueprint/React data-source analysis, not further broad hooks.

**Risks:** UE4SS native function hooks are intrusive even read-only; stop and roll back to H39 if unstable. No game-time testing has yet validated H41.

References: [UE4SS hook API](https://docs.ue4ss.com/dev/lua-api/global-functions/registerhook.html), [H40 result](H40_RUNTIME_RESULT_SECOND_TEST.md).
