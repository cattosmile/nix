pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

// One continuous rounded surface with an optional soft side lobe.
// This is intentionally QML-native: it does not copy Caelestia's shader/SDF code,
// but it gives this shell a clean visible "merged surface" primitive.
Shape {
    id: root

    property color color: "transparent"
    property real radius: 20
    property real connectorWidth: 0
    property real connectorRadius: radius
    property bool connectRight: false
    property bool connectLeft: false

    readonly property real lobeW: Math.max(0, connectorWidth)
    readonly property real leftInset: connectLeft ? lobeW : 0
    readonly property real rightInset: connectRight ? lobeW : 0
    readonly property real bodyX: leftInset
    readonly property real bodyW: Math.max(0, width - leftInset - rightInset)
    readonly property real bodyR: Math.max(0, Math.min(radius, bodyW / 2, height / 2))
    readonly property real lobeR: Math.max(0, Math.min(connectorRadius, height * 0.42))
    readonly property real midY: height / 2
    readonly property real rightX: bodyX + bodyW
    readonly property real leftX: bodyX

    preferredRendererType: Shape.CurveRenderer
    containsMode: Shape.FillContains

    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"
        strokeWidth: 0

        startX: root.leftX + root.bodyR
        startY: 0

        PathLine { x: root.rightX - root.bodyR; y: 0 }
        PathArc {
            x: root.rightX; y: root.bodyR
            radiusX: root.bodyR; radiusY: root.bodyR
            direction: PathArc.Clockwise
        }

        PathLine { x: root.rightX; y: root.connectRight ? root.midY - root.lobeR : root.height - root.bodyR }
        PathCubic {
            x: root.connectRight ? root.width : root.rightX
            y: root.connectRight ? root.midY : root.height - root.bodyR
            control1X: root.rightX + root.lobeW * 0.45
            control1Y: root.midY - root.lobeR
            control2X: root.width
            control2Y: root.midY - root.lobeR * 0.55
        }
        PathCubic {
            x: root.rightX
            y: root.connectRight ? root.midY + root.lobeR : root.height - root.bodyR
            control1X: root.width
            control1Y: root.midY + root.lobeR * 0.55
            control2X: root.rightX + root.lobeW * 0.45
            control2Y: root.midY + root.lobeR
        }

        PathLine { x: root.rightX; y: root.height - root.bodyR }
        PathArc {
            x: root.rightX - root.bodyR; y: root.height
            radiusX: root.bodyR; radiusY: root.bodyR
            direction: PathArc.Clockwise
        }
        PathLine { x: root.leftX + root.bodyR; y: root.height }
        PathArc {
            x: root.leftX; y: root.height - root.bodyR
            radiusX: root.bodyR; radiusY: root.bodyR
            direction: PathArc.Clockwise
        }

        PathLine { x: root.leftX; y: root.connectLeft ? root.midY + root.lobeR : root.bodyR }
        PathCubic {
            x: root.connectLeft ? 0 : root.leftX
            y: root.connectLeft ? root.midY : root.bodyR
            control1X: root.leftX - root.lobeW * 0.45
            control1Y: root.midY + root.lobeR
            control2X: 0
            control2Y: root.midY + root.lobeR * 0.55
        }
        PathCubic {
            x: root.leftX
            y: root.connectLeft ? root.midY - root.lobeR : root.bodyR
            control1X: 0
            control1Y: root.midY - root.lobeR * 0.55
            control2X: root.leftX - root.lobeW * 0.45
            control2Y: root.midY - root.lobeR
        }

        PathLine { x: root.leftX; y: root.bodyR }
        PathArc {
            x: root.leftX + root.bodyR; y: 0
            radiusX: root.bodyR; radiusY: root.bodyR
            direction: PathArc.Clockwise
        }
    }
}
