import QtQuick
import Mono.Sdf.Rust

SdfBlob {
    id: root

    property real targetX: 0
    property real targetY: 0
    property int followDuration: 80
    property real _frameAccumulator: 0

    radius: 10

    onTargetXChanged: {
        if (root.followDuration <= 0)
            root.x = root.targetX
    }

    onTargetYChanged: {
        if (root.followDuration <= 0)
            root.y = root.targetY
    }

    onFollowDurationChanged: {
        if (root.followDuration <= 0) {
            root.x = root.targetX
            root.y = root.targetY
        }
    }

    function advance(frameTime) {
        const interval = 1 / 144
        root._frameAccumulator += frameTime
        if (root._frameAccumulator + 0.0005 < interval)
            return

        const stepTime = root._frameAccumulator
        root._frameAccumulator %= interval
        const duration = Math.max(0, root.followDuration) / 1000

        if (duration === 0) {
            root.x = root.targetX
            root.y = root.targetY
            return
        }

        const alpha = 1 - Math.pow(0.05, stepTime / duration)
        root.x += (root.targetX - root.x) * alpha
        root.y += (root.targetY - root.y) * alpha
        if (Math.abs(root.targetX - root.x) < 0.05)
            root.x = root.targetX
        if (Math.abs(root.targetY - root.y) < 0.05)
            root.y = root.targetY
    }

    FrameAnimation {
        running: root.followDuration > 0
            && (Math.abs(root.targetX - root.x) > 0.01
                || Math.abs(root.targetY - root.y) > 0.01)
        onTriggered: root.advance(frameTime)
    }

    Component.onCompleted: {
        root.x = root.targetX
        root.y = root.targetY
    }
}
