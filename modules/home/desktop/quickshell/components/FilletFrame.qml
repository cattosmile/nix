pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

// Fullscreen border frame with a rounded inner cut-out.
// The inner cut-out radius is clamped to the live cut-out dimensions, so bar
// expand/collapse animation cannot make arcs self-intersect.
Shape {
    id: root

    property color color: "black"
    property real thickness: 10
    property real rightReserved: 54
    property real innerRadius: 24

    readonly property real ix: thickness
    readonly property real iy: thickness
    readonly property real iw: Math.max(0, width - thickness - rightReserved)
    readonly property real ih: Math.max(0, height - 2 * thickness)
    readonly property real r: Math.max(0, Math.min(innerRadius, iw / 2, ih / 2))

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        fillRule: ShapePath.WindingFill
        strokeColor: "transparent"
        strokeWidth: 0

        // Outer rect: clockwise.
        startX: 0; startY: 0
        PathLine { x: root.width; y: 0 }
        PathLine { x: root.width; y: root.height }
        PathLine { x: 0; y: root.height }
        PathLine { x: 0; y: 0 }

        // Inner hole: counter-clockwise rounded rect.
        PathMove { x: root.ix; y: root.iy + root.r }
        PathLine { x: root.ix; y: root.iy + root.ih - root.r }
        PathArc {
            x: root.ix + root.r; y: root.iy + root.ih
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.ix + root.iw - root.r; y: root.iy + root.ih }
        PathArc {
            x: root.ix + root.iw; y: root.iy + root.ih - root.r
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.ix + root.iw; y: root.iy + root.r }
        PathArc {
            x: root.ix + root.iw - root.r; y: root.iy
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.ix + root.r; y: root.iy }
        PathArc {
            x: root.ix; y: root.iy + root.r
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
    }
}
