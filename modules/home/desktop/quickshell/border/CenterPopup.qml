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

    // Stay mapped while sliding out so the close animation can play.
    visible: barState.centerPopupVisible || slide.y > -content.hiddenY
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

    mask: Region { item: content }

    // One corner-flare piece: a wing whose outer edge meets the bar (top) with a
    // horizontal tangent and meets the body side with a vertical tangent.
    // Tip at local (0,0); the body-facing edge is at local x = fillet.
    component Flare: Shape {
        id: flare
        required property real r
        required property color fill
        preferredRendererType: Shape.CurveRenderer
        implicitWidth:  r
        implicitHeight: r

        ShapePath {
            fillColor:   flare.fill
            strokeColor: "transparent"
            strokeWidth: 0

            startX: 0; startY: 0                                   // outer tip, on the bar
            PathArc  { x: flare.r; y: flare.r                       // tangent flare into the side
                       radiusX: flare.r; radiusY: flare.r
                       direction: PathArc.Clockwise }
            PathLine { x: flare.r; y: 0 }                          // up the body-side edge
            PathLine { x: 0;       y: 0 }                          // close along the bar
        }
    }

    // Window ignores exclusion zones (full-screen, fixed), so fixed margins keep
    // the block anchored to the screen — it won't follow the bar as it expands.
    Item {
        id: content
        anchors.right:       parent.right
        anchors.rightMargin: Theme.barWidth
        anchors.top:         parent.top
        anchors.topMargin:   Theme.frameThickness
        implicitWidth:  root.bodyW + root.fillet
        implicitHeight: root.bodyH + root.fillet

        // Off-screen resting spot: fully above the top edge of the monitor.
        readonly property real hiddenY: implicitHeight + Theme.frameThickness

        // Slides down from off-screen-top; same curve/duration as the bar expand.
        transform: Translate {
            id: slide
            y: root.barState.centerPopupVisible ? 0 : -content.hiddenY

            Behavior on y {
                NumberAnimation {
                    duration:           700
                    easing.type:        Easing.BezierSpline
                    easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
                }
            }
        }

        Rectangle {
            id: body
            anchors.right: parent.right
            anchors.top:   parent.top
            width:  root.bodyW
            height: root.bodyH
            color:  root.blockColor

            bottomLeftRadius:  root.fillet
            bottomRightRadius: 0

            Text {
                anchors.centerIn: parent
                text:  "Fick Kimi"
                color: Theme.text
                font.pixelSize: 24
            }
        }

        // Top-left corner flare — into the top bar.
        Flare {
            r:    root.fillet
            fill: root.blockColor
            anchors.right: body.left
            anchors.top:   body.top
        }

        // Bottom-right corner flare — into the right bar.
        Flare {
            r:    root.fillet
            fill: root.blockColor
            anchors.right: body.right
            anchors.top:   body.bottom
        }
    }
}
