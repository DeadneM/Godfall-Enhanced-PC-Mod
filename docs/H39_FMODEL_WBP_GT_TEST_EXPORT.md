# FModel WBP_GT_Test_C asset: parsed export and next inherited class targets

**Date:** 2026-10-14.
**Input:** user-provided Markdown-formatted FModel JSON attachment `Markdown collé.md`, ~21 KB, 449 lines. HTML entities, Markdown emphasis and escapes were normalized for local JSON parsing. 14 Unreal object records parsed. Original user export not copied into the repo.

## Exactly confirmed in the export

- Package: `/Game/Aperion/Blueprints/UI/Menus/WBP_GT_Test`.
- Generated class: `WBP_GT_Test_C` (cooked `WidgetBlueprintGeneratedClass`).
- **Direct parent:** `WBP_GT_Settings_C`, asset `/Game/Aperion/Blueprints/UI/WBP_GT_Settings`.
- Function `GetCoherentUIGTWidget` has an explicitly declared `Super` function `WBP_GT_Base_C:GetCoherentUIGTWidget`, asset `/Game/Aperion/Blueprints/UI/WBP_GT_Base`. This establishes that the method has an inherited implementation declaration from Base; it does not by itself prove that Test derives *directly* from Base. The class chain `Test → Settings` is explicit; `Settings → Base` still needs verification by exporting `WBP_GT_Settings`.
- Exactly **two functions** from `WBP_GT_Test_C` are exported:
  1. `GetCoherentUIGTWidget` (BlueprintCallable, BlueprintPure, Const, BlueprintEvent), `GTWidget` output `CoherentUIGTWidget_Persistent`, inherited signature from Base.
  2. `ToggleBgBlurWidget` (BlueprintCallable, BlueprintEvent), input `Visible: bool`, selected `ESlateVisibility` results.
- Class child object properties: `BackgroundBlurWidget` (BackgroundBlur), `BlurBG` (Overlay), `CoherentUIGTWidget_Persistent_90` (CoherentUIGTWidget_Persistent).
- Child Coherent object `CoherentUIGTWidget_Persistent_90` has **`Outer=WidgetTree'WBP_GT_Test_C:WidgetTree'`**, not `Outer=WBP_GT_Test_C`; this **fully explains** why H39 reported `H39_CHILD_OWNERSHIP direct=0` even though the host's property resolves the child. The widget is still part of the host's widget tree.
- Child Coherent object exported properties contain only `Slot`, referring to `CanvasPanelSlot_0`. There is **no URL, frontend route, JavaScript file reference, cosmetic list or bridge payload** in this package export.
- `BackgroundBlurWidget.BlurStrength=12.0`, and `BlurBG.Visibility=ESlateVisibility::Collapsed` by default. This fits a simple overlay/visual container.
- `Default__WBP_GT_Test_C` references a `WBP_GT_Settings_C` template. No native-cosmetic availability flag was exported.

## Interpretation (bounded)

This corroborates H37–H39 runtime diagnostics: `WBP_GT_Test_C` is **an active Coherent UI host**, but this concrete cooked asset appears to provide mostly layout/blur behavior. `GetCoherentUIGTWidget` has a signature from `WBP_GT_Base`; the export itself contains no operational implementation of the skin-selection bridge.

The export does **not** prove that a parent Blueprint contains cosmetic filtering. Nor does it establish whether the frontend code is locally packaged, embedded, or remote. A serialized class name and property signature is not an executable Blueprint graph.

## Next actionable FModel inputs

**Priority 1:** export **`/Game/Aperion/Blueprints/UI/WBP_GT_Settings`** as one JSON file. Determine its superclass, function map, relevant `DataBridge`/React/UI initialization names, named properties and defaults, and any references to resources.

**Priority 2:** export **`/Game/Aperion/Blueprints/UI/WBP_GT_Base`** as a second JSON file. Specifically inspect `GetCoherentUIGTWidget`, widget initialization, JS binding names and function references.

If both show only generic menu scaffolding, **stop following the Blueprint host inheritance chain**, then locate the actual React/Coherent frontend bundle or data-source method that builds `cosmetics/collection` and filters `Character.Player.Hinterclaw.MacrosCosmetic`. Do not build another runtime reflection probe without a new, testable causal hypothesis.

## Status

- H39 read-only child probe executed successfully in-game.
- This FModel export **validated the WidgetTree ownership explanation** and exact `WBP_GT_Test` superclass.
- H40 **not built**.
- H23/H25 validated visual materials preserved; native skin selection **not achieved**; `Unlock Gratitude` and `Unlock All` not implemented.
