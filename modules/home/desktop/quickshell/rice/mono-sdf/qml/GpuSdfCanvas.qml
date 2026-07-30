import QtQuick

Item {
    id: root

    default property alias shapes: shapeHost.data

    property color fillColor: "white"
    property real smoothness: 30
    property real edgeSoftness: 0.75

    readonly property var packedShapes: root.buildPackedShapes()
    readonly property int packedShapeCount: Math.min(8, root.packedShapes.length)

    function vector(x, y, z, w) {
        return Qt.vector4d(x, y, z, w)
    }

    function packItem(item, output) {
        if (!item || item.enabled === false)
            return

        if (typeof item.halfWidth !== "undefined") {
            output.push({
                a: root.vector(
                    item.x,
                    item.y,
                    Math.max(0, item.halfWidth),
                    1
                ),
                b: root.vector(
                    Math.max(0, item.halfHeight),
                    Math.max(0, item.cornerRadius),
                    Math.max(0, Math.min(1, item.cornerSmoothing)),
                    0
                )
            })
        } else if (typeof item.radius !== "undefined") {
            output.push({
                a: root.vector(
                    item.x,
                    item.y,
                    Math.max(0, item.radius),
                    0
                ),
                b: root.vector(0, 0, 0, 0)
            })
        }
    }

    function buildPackedShapes() {
        const output = []
        for (const item of shapeHost.children)
            root.packItem(item, output)
        return output
    }

    function shapeA(index) {
        return index < root.packedShapeCount
            ? root.packedShapes[index].a
            : root.vector(0, 0, 0, 0)
    }

    function shapeB(index) {
        return index < root.packedShapeCount
            ? root.packedShapes[index].b
            : root.vector(0, 0, 0, 0)
    }

    ShaderEffect {
        id: effect

        anchors.fill: parent
        blending: true
        vertexShader: "sdf_gpu.vert.qsb"
        fragmentShader: "sdf_gpu.frag.qsb"

        property vector4d resolutionParams: Qt.vector4d(
            width,
            height,
            root.edgeSoftness,
            root.smoothness
        )
        property color fillColor: root.fillColor
        property vector4d sceneParams: Qt.vector4d(
            root.packedShapeCount,
            0,
            0,
            0
        )

        property vector4d shapeA0: root.shapeA(0)
        property vector4d shapeA1: root.shapeA(1)
        property vector4d shapeA2: root.shapeA(2)
        property vector4d shapeA3: root.shapeA(3)
        property vector4d shapeA4: root.shapeA(4)
        property vector4d shapeA5: root.shapeA(5)
        property vector4d shapeA6: root.shapeA(6)
        property vector4d shapeA7: root.shapeA(7)
        property vector4d shapeB0: root.shapeB(0)
        property vector4d shapeB1: root.shapeB(1)
        property vector4d shapeB2: root.shapeB(2)
        property vector4d shapeB3: root.shapeB(3)
        property vector4d shapeB4: root.shapeB(4)
        property vector4d shapeB5: root.shapeB(5)
        property vector4d shapeB6: root.shapeB(6)
        property vector4d shapeB7: root.shapeB(7)

        onStatusChanged: {
            if (status === ShaderEffect.Error)
                console.warn("Mono.Sdf GPU shader:", log)
        }
    }

    Item {
        id: shapeHost
        anchors.fill: parent
    }
}
