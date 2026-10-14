# H40 user runtime result: hook installation confirmed, observation inconclusive

**Input:** user-uploaded `GodfallEnhancedBridge(20261014-154737).log` on 2026-10-14. The actual file was inspected: **1,225 bytes / 16 lines**. Original raw log not committed.

## Exact observed sequence

```text
V0.6H40 Short-Lived DataBridge Type Probe / F1 overlay starting (H25 base)
H40_BOOT_MARKER=OK
COMMAND METHOD_C AUTO_NEXT
H40_BRIDGE_ARM_BEGIN scope=GT_TEST request_type_only
H40_BRIDGE_NOT_ARMED reason=GT_TEST_NOT_LOADED; open_original_skins_menu_first
COMMAND METHOD_C AUTO_NEXT
H40_BRIDGE_ARM_BEGIN scope=GT_TEST request_type_only
H40_BRIDGE_HOOK_OK source=BASE
H40_BRIDGE_HOOK_OK source=SETTINGS
H40_BRIDGE_ARMED hooks=2 max_events=48 timeout_approx_sec=90 mutated=0
```

- Correct H40 script was loaded.
- First C was pressed before the `WBP_GT_Test_C` widget could be resolved and did **not** install any hooks.
- Second C resolved the widget and **registered both narrowly scoped Blueprint UFunction hooks** on `WBP_GT_Base_C:OnDataBridgeIncomingRequest` and `WBP_GT_Settings_C:OnDataBridgeIncomingRequest`.
- **No `H40_BRIDGE_TYPE`**, **no `H40_CALLBACK_READ_ERROR`**, **no `H40_BRIDGE_STOP`**, and no third `COMMAND METHOD_C` occur in the provided 16 lines.
- The boot line `H24_NO_HOOKS=TRUE` is a **stale inherited startup banner** in this H40 code. It does not describe H40's optional hooks, which the same log subsequently verifies were registered. Correct the label in a future build, without altering H25 behavior.

## What this does not establish

**Do not mark H40 as fully validated or declare that the hook intercepted nothing in a complete test.** The uploaded log ends immediately after the `H40_BRIDGE_ARMED` record. This is consistent with several possibilities, none proven by the log:
- The file was copied while the hooks were still armed / before 90 seconds.
- The game exited or crashed after registration (no explicit crash line is present).
- The Lua bridge timer did not complete, the script stopped running, or the user navigated away.
- The specific handlers did not execute in that interval (or callback context was filtered).

Because no stop record exists, we cannot confirm successful unregistration or the callback counter. The lack of a `H40_BRIDGE_TYPE` line **cannot yet be treated as a complete zero-event result**.

## Source audit & limitations

- `h40_start()` logs two `H40_BRIDGE_HOOK_OK` only when `RegisterHook` returns numeric pre/post IDs. Per [UE4SS RegisterHook documentation](https://docs.ue4ss.com/dev/lua-api/global-functions/registerhook.html), the hook is for an already-loaded UFunction and receives `RemoteUnrealParam` wrappers.
- `h40_on_event` deliberately restricts callbacks to `ctx:GetFullName()` containing `WBP_GT_Test`; the `hits` count increments **only after** that filter. Even if a base/settings handler ran on another context, the current log would remain silent. This is a known measurement limitation, not proof that no bridge activity exists.
- `h40_tick()` is called by `LoopAsync(250)`, and intends to call `UnregisterHook` when `ticks>=360` (approx. 90 s). The code has **no periodic heartbeat while armed**. We cannot tell whether the async loop remained active, and the automatic cleanup is not proven in this log.
- The callback body intentionally does not inspect `Payload` or `Promise` and returns no value. There is no evidence of state mutation from the log, but observing hook registration is not evidence of complete gameplay stability.
- The new H40 hooks carry more native crash risk than H39's read-only property reflection, especially given prior crashes with broad hooks in the project history.

## Recommended next action

**First identify whether there was a crash** during or after the second C. If yes, revert to H39 and **do not repeat H40 hook tests** without a redesigned safer mechanism. Obtain Windows crash context only if readily available. If no crash and game was still running when log copied, keep H40 installed, open original skins menu, press C **once only while `WBP_GT_Test_C` is loaded**, navigate several skins, press C a second time, then copy the log before restarting. A useful result must show either `H40_BRIDGE_TYPE` or `H40_BRIDGE_STOP reason=MANUAL_STOP/TIME_LIMIT` with hit and unregistered counts.

Do **not** build H41 as another broader hook sweep. If H40 demonstrates no callback activity after a complete stop, prioritize actual frontend JS/cooked Blueprint graph/known DataBridge request source instead of expanding the hooks. H23/H25 stable visual A/B must remain intact.

## Status

- H39: completed as targeted read-only diagnosis.
- H40: **partially exercised: installation of two hooks confirmed; event observation and hook cleanup unverified**.
- H41: not built.
- Native `Character.Player.Hinterclaw.MacrosCosmetic` menu unlock: not achieved.
