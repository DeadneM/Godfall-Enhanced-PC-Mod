# H40 user runtime result, second test (2026-10-14)

Input: user-uploaded `GodfallEnhancedBridge(20261014-162027).log`, **4,234 bytes**. H40 boot confirmed and capture tested on a Valorplate with unlocked skins. Original log not copied into repository.

## Exactly observed
- `H40_BOOT_MARKER=OK` at boot.
- First C: `H40_BRIDGE_HOOK_OK source=BASE`, `source=SETTINGS`, `H40_BRIDGE_ARMED hooks=2 max_events=48 timeout_approx_sec=90 mutated=0`.
- Both hooks observed identical named request families:
  - `UE_ROUTE_UI`
  - `UE4_PLAY_MUSIC`
  - `UE4_SHOW_LOADOUT_VISUAL_REQUEST`
  - `UE4_PLAY_AUDIO_CUE`
  - `UE4_HIDE_LOADOUT_VISUAL_REQUEST`
  - `UE4_SHOW_LOADOUT_WEAPON_VISUAL_REQUEST`
- Terminal result of the **first** window: `H40_BRIDGE_STOP reason=EVENT_LIMIT hits=48 filtered=0 unregistered=2 errors=0 mutated=0`. First hook window thus **successfully captured events and unregistered both hooks**.
- **Second C after stop:** the two hooks were registered again and `H40_BRIDGE_ARMED hooks=2` was printed. The uploaded log ends there, without its second `H40_BRIDGE_STOP`. We must not infer whether the second window finished or was manually stopped.
- User already explicitly reported H40 previously did not crash. The supplied second log also has no crash/error markers, though a log alone cannot prove overall stability.
- The emitted six request names are meaningful, but the mapping to actual gameplay/skin actions is an **inference**. The `UE4_SHOW_LOADOUT_VISUAL_REQUEST` and `UE4_SHOW_LOADOUT_WEAPON_VISUAL_REQUEST` names signal UI loadout visualization, not proof of cosmetic ownership checks or unlock commands.
- `source=BASE` and `source=SETTINGS` have strongly parallel type sequences and counts. Whether this duplication is due to inheritance dispatch, separate callback invocations or event forwarding **is not conclusively established**, but both hooks consume the shared event budget. 48 callbacks are not necessarily 48 distinct user interactions.
- No request **name** containing `COSMETIC`, `SKIN` or `UNLOCK` was captured. This does not mean such actions do not exist: callback cap may have stopped monitoring too early and `Payload` is intentionally untouched.
- H40 has an obsolete startup marker `H24_NO_HOOKS=TRUE`, despite optional H40 hooks, to correct in H41.

## H41 scoped next experiment
- Exactly **one hooked Blueprint UFunction**, `WBP_GT_Base_C:OnDataBridgeIncomingRequest`, installed on explicit F1 C in already-open vanilla skins menu, to remove the pair's repeated monitoring.
- Capture up to 160 hook events or 90 seconds, whichever first.
- Log sanitized request Type and event order for high-signal names, bound repetitive audio/music logging, plus a complete per-type summary upon auto/manual stop.
- Do not read `Payload`/`Promise` or change any return values, file saves, cosmetics ownership or backend entitlements. Keep H25 visual A/B, F1 overlay, original ASI/DXGI and H35 locator.
- **Acceptance:** observe distinct event types and their order while switching between skins, plus `H41_BRIDGE_STOP` with `unregistered=1 errors=0`. A lack of cosmetic-named events would still be inconclusive about the frontend's data filters.
- H41 is a new diagnostic build, **not** a native unlock.

Reference: [UE4SS RegisterHook](https://docs.ue4ss.com/dev/lua-api/global-functions/registerhook.html).
