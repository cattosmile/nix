# CenterPopup animated block — session handoff

**Date:** 2026-05-30
**Directory:** /home/user/nix/modules/home/desktop/quickshell
**Focus for next session:** continue where we left off — polish/finalize the `CenterPopup` block + its text animation

## Summary

Built a new `CenterPopup` component: a black block that "grows" out of the top/right border when a dummy `+` button (above the workspace switcher in the bar) is clicked. The block has tangent-fillet corners that blend into the border, an asymmetric IN/OUT animation, and a centered test label ("Fick Kimi"). This session ended after fixing the label so it moves 1:1 with the block during both animations. The animation is currently **slowed to 8000ms for screenshotting** and must be restored before normal use.

## Decisions

- **Single `Shape`/`ShapePath` for the whole block** (body + top-left flare + bottom-right flare + bottom-left round) instead of separate `Rectangle`+`Shape` primitives — eliminated a 1px seam / anti-alias shimmer at corner junctions.
- **Asymmetric animation via QML states/transitions** (per explicit user request):
  - IN (`closed`→`open`): unroll **top-to-bottom** by animating `blockH` 0→`bodyH`; `leftX` stays at `fillet`.
  - OUT (`open`→`closed`): retract **left-to-right** by animating `leftX` `fillet`→`brX` (width shrinks into the bar), then reset `blockH`/`leftX` off-screen for a fresh next open.
  - Rejected the earlier rigid `Translate` approach — it sliced hard corners past the fixed bar.
- **Corner radii are dynamically capped** (`Math.min(fillet, blockH/2, curW...)`) so corners scale as the block grows/shrinks — prevents "floating corner" and hard-corner artifacts at small sizes.
- **Layering:** `CenterPopup` on `WlrLayer.Top`, `BarWindow` moved to `WlrLayer.Overlay` so the bar always draws **above** the block (block appears to slide behind the bar). Same-layer reordering in `Border.qml` was unreliable; changing the layer was the reliable fix.
- **Block is NOT anchored to the bar** — uses fixed screen margins + `exclusionMode: Ignore` so it stays put when the bar expands/contracts.
- **Text glued to the moving edges** (final fix this session): horizontally at a fixed offset from the container's moving left edge (`x: bodyW/2 - width/2`), vertically at a fixed offset from the moving bottom edge (`y: blockH - bodyH/2 - height/2`). Both reduce to dead-centre when fully open. Centering the text in the box made it move at half-speed and lag the window — the fixed-offset-from-moving-edge approach makes it track at full speed ("moves out with the window"). User confirmed both IN and OUT now correct.

## Learnings

- **[portable]** Centering an element inside a box whose edge animates makes it move at *half* the edge speed (centre = (fixed+moving)/2). To make a child track the window 1:1, pin it at a fixed offset from the *moving* edge, not the box centre.
- **[portable]** For grow/shrink (non-rigid) animations, fillet corners must have radii capped to the current dimension (`min(fillet, dim/2, ...)`) or they detach / overlap.
- **[portable]** A single continuous `ShapePath` avoids sub-pixel seams that appear between adjacent `Shape`/`Rectangle` primitives.
- **[env]** Reliable Wayland stacking between two surfaces is best controlled by `WlrLayershell.layer` (Background<Bottom<Top<Overlay), not by instantiation order within the same layer.
- **[env]** `Theme.innerRadius` is the border's inner corner radius; reuse it (`fillet`) so the block blends into the border. `Theme.barWidth`/`Theme.frameThickness` are the right/top inset sizes.

## Files

| Path | Role |
|------|------|
| `border/CenterPopup.qml` | The animated block (new this session). All animation/shape/text logic lives here. |
| `border/BarState.qml` | Added `property bool centerPopupVisible` — the open/close toggle. |
| `border/BarWindow.qml` | Added the `+` dummy button (above `WorkspaceSwitcher`) that toggles `centerPopupVisible`; layer changed `Top`→`Overlay`. |
| `border/Border.qml` | Instantiates `CenterPopup` per screen (passes `screen` + `barState`). |
| `border/qmldir` | Registered `CenterPopup 1.0 CenterPopup.qml`. |

Note: `modules/nixos/virtualization/{qemu,xmls}.nix` are also modified in the working tree but are unrelated to this session.

## Current state

- **Done:** Block geometry, fillet corners, layering behind bar, asymmetric IN/OUT animation, and text tracking — all confirmed working by the user.
- **In progress / open:** `animDuration` in `CenterPopup.qml` is `8000` (slowed for screenshots). Normal value was `700`ms.
- **Blocked / open questions:** None. "Fick Kimi" is placeholder text; real content TBD.

## Next steps

1. Restore `readonly property int animDuration: 8000` → `700` in `border/CenterPopup.qml` (line ~35).
2. Replace placeholder "Fick Kimi" text with the intended popup content.
3. (Optional) Decide whether the easing should stay `BezierSpline` w/ `animCurve` or the `Easing.InQuad` variant discussed earlier.

## Resume

- Open: `border/CenterPopup.qml` (animation lives at lines ~34-160), `border/BarState.qml`, `border/BarWindow.qml`.
- Verify: rebuild the home-manager/nixos config and click the `+` button above the workspace switcher; confirm the block unrolls top-to-bottom, retracts left-to-right behind the bar, and the label tracks the motion 1:1.
