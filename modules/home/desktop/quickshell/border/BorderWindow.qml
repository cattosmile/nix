pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

// Full-screen overlay that draws the border frame as a GPU-native Shape.
// WindingFill: CW outer rect (+1) + CCW inner rounded rect (−1) = 0 → hole.
PanelWindow {
    id: root

    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "qs-border"

    mask: Region {}

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    Shape {
        id: frame
        anchors.fill: parent

        readonly property real t:  Theme.frameThickness
        readonly property real bw: Theme.activeBarWidth
        readonly property real r:  Theme.innerRadius
        readonly property real ix: t
        readonly property real iy: t
        readonly property real iw: width - t - bw
        readonly property real ih: height - 2 * t

        ShapePath {
            fillColor:   Theme.frameColor
            fillRule:    ShapePath.WindingFill
            strokeColor: "transparent"
            strokeWidth: 0

            // Outer rect — CW (+1 winding)
            startX: 0; startY: 0
            PathLine { x: frame.width;  y: 0 }
            PathLine { x: frame.width;  y: frame.height }
            PathLine { x: 0;            y: frame.height }
            PathLine { x: 0;            y: 0 }

            // Inner rounded rect — CCW (−1 winding → hole)
            // CCW: down → right → up → left; each arc sweeps 90° CCW.
            PathMove { x: frame.ix;                       y: frame.iy + frame.r }
            PathLine { x: frame.ix;                       y: frame.iy + frame.ih - frame.r }
            PathArc  { x: frame.ix + frame.r;             y: frame.iy + frame.ih
                       radiusX: frame.r; radiusY: frame.r; direction: PathArc.Counterclockwise }
            PathLine { x: frame.ix + frame.iw - frame.r;  y: frame.iy + frame.ih }
            PathArc  { x: frame.ix + frame.iw;            y: frame.iy + frame.ih - frame.r
                       radiusX: frame.r; radiusY: frame.r; direction: PathArc.Counterclockwise }
            PathLine { x: frame.ix + frame.iw;            y: frame.iy + frame.r }
            PathArc  { x: frame.ix + frame.iw - frame.r;  y: frame.iy
                       radiusX: frame.r; radiusY: frame.r; direction: PathArc.Counterclockwise }
            PathLine { x: frame.ix + frame.r;             y: frame.iy }
            PathArc  { x: frame.ix;                       y: frame.iy + frame.r
                       radiusX: frame.r; radiusY: frame.r; direction: PathArc.Counterclockwise }
        }
    }
}
