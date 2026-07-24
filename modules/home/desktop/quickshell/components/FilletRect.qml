pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

// Rectangle replacement for this shell's rounded surfaces.
// Shape.CurveRenderer gives stable anti-aliased arcs and the path clamps radii
// during width/height animations, avoiding broken corner geometry.
Shape {
    id: root

    property color color: "transparent"
    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomRightRadius: radius
    property real bottomLeftRadius: radius

    containsMode: Shape.FillContains
    preferredRendererType: Shape.CurveRenderer

    CornerPath {
        x: 0
        y: 0
        width: root.width
        height: root.height
        radius: root.radius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomRightRadius: root.bottomRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        fillColor: root.color
    }
}
