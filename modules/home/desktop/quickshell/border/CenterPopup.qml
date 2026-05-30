pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

// Full-screen overlay; a red block hangs from the top bar. The upper corners
// flare outward with a tangent fillet (radius = Theme.innerRadius, matching the
// border's inner corners) so the block looks like it grows out of the border.
PanelWindow {
    id: root

    required property BarState barState

    // Stay mapped while the block is still unrolling / retracting.
    visible: barState.centerPopupVisible || (content.blockH > 0 && content.leftX < content.brX)
    color:   "transparent"

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "qs-center-popup"

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    readonly property color blockColor: Theme.frameColor
    readonly property real  fillet:     Theme.innerRadius
    readonly property real  bodyW:      400
    readonly property real  bodyH:      125

    // Shared bar-style motion (slowed for screenshots).
    readonly property int animDuration: 8000
    readonly property var animCurve:    [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]

    mask: Region { item: content }

    // Window ignores exclusion zones (full-screen, fixed), so fixed margins keep
    // the block anchored to the screen — it won't follow the bar as it expands.
    Item {
        id: content
        anchors.right:       parent.right
        anchors.rightMargin: Theme.barWidth
        anchors.top:         parent.top
        anchors.topMargin:   Theme.frameThickness
        implicitWidth:  root.bodyW + root.fillet
        implicitHeight: blockH + root.fillet

        // blockH: vertical unroll amount (0..bodyH), used by the IN animation.
        // leftX:  body left-edge x; the OUT animation retracts it toward the docked
        //         right edge (brX). The right + top edges always stay docked to the
        //         bars, so every corner stays attached and valid.
        // IN  → unroll top-to-bottom (grow blockH, leftX stays at fillet).
        // OUT → retract left-to-right (leftX → brX, width shrinks into the bar),
        //       then reset blockH/leftX off-screen so the next open unrolls fresh.
        property real blockH: 0
        property real leftX:  root.fillet

        state: root.barState.centerPopupVisible ? "open" : "closed"
        states: [
            State {
                name: "open"
                PropertyChanges { target: content; blockH: root.bodyH; leftX: root.fillet }
            },
            State {
                name: "closed"
                PropertyChanges { target: content; blockH: 0; leftX: root.fillet }
            }
        ]
        transitions: [
            Transition {
                from: "closed"; to: "open"
                SequentialAnimation {
                    PropertyAction { target: content; property: "leftX"; value: root.fillet }
                    NumberAnimation {
                        target: content; property: "blockH"; to: root.bodyH
                        duration:           root.animDuration
                        easing.type:        Easing.BezierSpline
                        easing.bezierCurve: root.animCurve
                    }
                }
            },
            Transition {
                from: "open"; to: "closed"
                SequentialAnimation {
                    NumberAnimation {
                        target: content; property: "leftX"; to: content.brX
                        duration:           root.animDuration
                        easing.type:        Easing.BezierSpline
                        easing.bezierCurve: root.animCurve
                    }
                    PropertyAction { target: content; property: "blockH"; value: 0 }
                    PropertyAction { target: content; property: "leftX";  value: root.fillet }
                }
            }
        ]

        // Body spans x ∈ [leftX, brX], y ∈ [0, blockH]; right edge docked to the bar.
        readonly property real brX:  root.fillet + root.bodyW   // body right edge
        readonly property real curW: brX - leftX                // current body width

        // Corner radii, capped so adjacent corners never overlap on a shared edge
        // as the block unrolls (height) or retracts (width). Same scaling idea as
        // the top fix, now also covering the bottom-left as the block narrows out.
        readonly property real frRight: Math.min(root.fillet, curW)                                 // bottom-right flare
        readonly property real bl:      Math.max(0, Math.min(root.fillet, blockH / 2, curW - frRight)) // bottom-left round
        readonly property real frLeft:  Math.min(root.fillet, blockH / 2, curW)                     // top-left flare

        // Whole block (body + top-left flare + bottom-right flare + bottom-left
        // round) as ONE continuous outline — no seam between separate primitives.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor:   root.blockColor
                strokeColor: "transparent"
                strokeWidth: 0

                // Top-left flare tip, on the bar.
                startX: content.leftX - content.frLeft
                startY: 0

                PathLine { x: content.brX;                   y: 0 }                               // top edge
                PathLine { x: content.brX;                   y: content.blockH + content.frRight } // right edge + flare drop
                PathArc  { x: content.brX - content.frRight; y: content.blockH                     // bottom-right flare
                           radiusX: content.frRight; radiusY: content.frRight
                           direction: PathArc.Counterclockwise }
                PathLine { x: content.leftX + content.bl;    y: content.blockH }                  // bottom edge
                PathArc  { x: content.leftX;                 y: content.blockH - content.bl       // bottom-left round
                           radiusX: content.bl; radiusY: content.bl
                           direction: PathArc.Clockwise }
                PathLine { x: content.leftX;                 y: content.frLeft }                  // left edge
                PathArc  { x: content.leftX - content.frLeft; y: 0                                // top-left flare
                           radiusX: content.frLeft; radiusY: content.frLeft
                           direction: PathArc.Counterclockwise }
            }
        }

        // Text clipped to the current body box. It's glued to the body geometry so
        // it travels 1:1 with the animation: horizontally it sits at a fixed offset
        // from the (moving) left edge, so it tracks leftX at full speed on OUT;
        // vertically it tracks the current height, so it rides down as it extends on IN.
        Item {
            x:      content.leftX
            y:      0
            width:  content.curW
            height: content.blockH
            clip:   true

            Text {
                x:     root.bodyW / 2 - width / 2                 // centred on the full body, tracks left edge
                y:     content.blockH - root.bodyH / 2 - height / 2  // fixed offset from the moving bottom edge
                text:  "Fick Kimi"
                color: Theme.text
                font.pixelSize: 24
            }
        }
    }
}
