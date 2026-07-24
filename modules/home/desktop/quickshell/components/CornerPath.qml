pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

// Reusable rounded-rectangle path with per-corner radii and hard clamping.
// This keeps animated/very small shapes from producing inverted or jagged arcs.
ShapePath {
    id: root

    property real x: 0
    property real y: 0
    property real width: 0
    property real height: 0
    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomRightRadius: radius
    property real bottomLeftRadius: radius

    readonly property real maxRadius: Math.max(0, Math.min(width, height) / 2)
    readonly property real tl: Math.max(0, Math.min(topLeftRadius, maxRadius))
    readonly property real tr: Math.max(0, Math.min(topRightRadius, maxRadius))
    readonly property real br: Math.max(0, Math.min(bottomRightRadius, maxRadius))
    readonly property real bl: Math.max(0, Math.min(bottomLeftRadius, maxRadius))
    readonly property real right: x + Math.max(0, width)
    readonly property real bottom: y + Math.max(0, height)

    strokeColor: "transparent"
    strokeWidth: 0

    startX: root.x + root.tl
    startY: root.y

    PathLine { x: root.right - root.tr; y: root.y }
    PathArc {
        x: root.right; y: root.y + root.tr
        radiusX: root.tr; radiusY: root.tr
        direction: PathArc.Clockwise
    }
    PathLine { x: root.right; y: root.bottom - root.br }
    PathArc {
        x: root.right - root.br; y: root.bottom
        radiusX: root.br; radiusY: root.br
        direction: PathArc.Clockwise
    }
    PathLine { x: root.x + root.bl; y: root.bottom }
    PathArc {
        x: root.x; y: root.bottom - root.bl
        radiusX: root.bl; radiusY: root.bl
        direction: PathArc.Clockwise
    }
    PathLine { x: root.x; y: root.y + root.tl }
    PathArc {
        x: root.x + root.tl; y: root.y
        radiusX: root.tl; radiusY: root.tl
        direction: PathArc.Clockwise
    }
}
