# H40: targeted DataBridge incoming request TYPE-only tracer

## Evidence: FModel exports supplied 2026-10-14

**WBP_GT_Settings** (user `Texte collé(3).txt`, 21 parsed exports, 18 UFunction objects):
- `WBP_GT_Settings_C` **directly derives from `WBP_GT_Base_C`**, confirming the full chain `WBP_GT_Test_C → WBP_GT_Settings_C → WBP_GT_Base_C → WBP_UserWidget_C`.
- Overrides `OnDataBridgeIncomingRequest(Type: FString, Payload: JsonObjectWrapper, Promise: PromiseHandle)` and `Construct`, each declared with `Super` referencing `WBP_GT_Base_C`.
- Its Blueprint compiler-generated fields include `CallFunc_GetCoherentUIGTWidget_GTWidget`, `CallFunc_ThrowPromise_ReturnValue`, `CallFunc_CatchPromise_ReturnValue`, JSON decoding and settings fields.
- Its declared functions focus on video settings, input capture, keybind blacklists and game-user settings, **not cosmetics**.
- Declares `CapturingDatabridgePromise: PromiseHandle`, not a cosmetic ownership state.

**WBP_GT_Base** (user `Markdown collé (2)(1).md`, Markdown-decoded as 10 exports, 7 UFunction objects):
- Direct parent `WBP_UserWidget_C`.
- Defines `OnDataBridgeIncomingRequest(Type: FString, Payload: JsonObjectWrapper, Promise: PromiseHandle)` and `GetCoherentUIGTWidget`.
- Exposes `CoherentUIGTInput`, multicast `TargetURLReadyForBindings`, boolean `IsTargetURLReadyForBindings`.
- `ExecuteUbergraph_WBP_GT_Base` contains compiler-generated `CallFunc_GetAPGameInstance_ReturnValue` and custom DataBridge event argument fields. This **suggests but does not prove** an execution flow involving `APGameInstance`: FModel reflection JSON is **not** Blueprint bytecode, so does not prove which methods are called or message dispatch direction.

**No `Cosmetic`, `Skin`, `Entitlement`, `Inventory`, or cosmetic query string** was exposed in either Blueprint export.

## Why H40 is justified despite rejected broad H20 hooks

Unlike H20's broad UE4SS intercept experiment, H40 attempts **at most two exact, asset-proven Blueprint UFunction hooks**, and only when manually armed in the **already-open original Hinterclaw skins screen**.

Paths:
- `/Game/Aperion/Blueprints/UI/WBP_GT_Base.WBP_GT_Base_C:OnDataBridgeIncomingRequest`
- `/Game/Aperion/Blueprints/UI/WBP_GT_Settings.WBP_GT_Settings_C:OnDataBridgeIncomingRequest`

UE4SS documents `RegisterHook` and `UnregisterHook`: callbacks receive wrapped context and ordered parameters; they must already be loaded, so registration may safely fail, and Blueprint-path callback is invoked **after** the call. This is API-grounded, though the user's Godfall/UE4SS version may behave differently or crash.

## Specific test behavior and privacy

- **F1 → C** in the native cosmetics screen first checks `WBP_GT_Test_C` is loaded; if not, logs `H40_BRIDGE_NOT_ARMED`. Does **not** install hooks at game boot or globally.
- On success, attempts only these two exact hooks. Reports `H40_BRIDGE_HOOK_OK source=BASE/SETTINGS` or `H40_BRIDGE_HOOK_UNAVAILABLE` on missing function/signature.
- For each callback, filters context object to `WBP_GT_Test` and reads **only the first FString `Type`**. `Payload` and `Promise` callback parameters are present but **never accessed or logged**. Rejects non-simple event names, token-like names, long strings or secret/account markers; repeated names capped to 3 lines each.
- Maximum **48 callbacks**, or approximately **90 seconds** via existing 250ms LoopAsync. Then `UnregisterHook` for every successful pair and `H40_BRIDGE_STOP` summary; can also stop early via second **F1 → C** press or manual `DATABRIDGE_TRACE_STOP`. No permanent hook installation.
- Callback **returns no value** and never calls setters or changes any request/return value, so intended behavior is observation only. Hooking is nonetheless an invasive native operation and has **nonzero stability risk**. Test on a backed-up installation.
- No broad UObject scan, no raw JS/body URL, no headers, no save files, no server spoofing, no account entitlements.

Other operations remain cumulative: H25 A/B visual methods, H35 offline file locator, H36/37 alcove map via manual `ALCOVE_MAP_AUDIT`, H39 Coherent child via `COHERENT_CHILD_AUDIT`; original ASI/DXGI unchanged.

## User test, one session

1. Back up H39 files. Extract complete H40 ZIP next to `Aperion-Win64-Shipping.exe` preserving `ue4ss/`. Restart and confirm `H40_BOOT_MARKER=OK` in `GodfallEnhancedBridge.log`.
2. Enter the loaded Sanctum and open **original Hinterclaw skins menu first**.
3. Open F1 overlay and press **C once** to ARM tracing. Close overlay; navigate **three or four ordinary skins** in the original menu to provoke requests. Do **not** attempt reward/entitlement mutations.
4. Open F1 and press **C again** to disable (or allow the 90-sec automatic limit). Send `GodfallEnhancedBridge.log` **before game restart**.
5. Look for `H40_BRIDGE_HOOK_OK`, `H40_BRIDGE_TYPE`, `H40_BRIDGE_STOP`. **If game crashes**, roll back to validated H39 and report the step, no repeated crashing.

## Outcomes

- If request types appear and correlate with native skin menu interactions, investigate only the **known Type's local handler** and where it assembles the cosmetics list. Do not capture payloads or intercept entitlements.
- If hooks unavailable or zero events, **stop hooking**. Next source needed is actual compiled Blueprint execution flow or Coherent frontend bundle; do not blindly broaden hooks to every UFunction.
- **Native unlock is NOT implemented**: only when `Character.Player.Hinterclaw.MacrosCosmetic` appears and is selected in original UI after refresh/restart can it be considered validated.

UE4SS API reference: https://docs.ue4ss.com/dev/lua-api/global-functions/registerhook.html
