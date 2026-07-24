pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../services"

// Full-screen overlay that renders the notification stack. Each entry in
// barState.notifications becomes one block that slides down into place from above
// the top border (as if coming in from outside the monitor), lives for ~5s, then
// retracts left-to-right into the bar and removes itself. Entries are appended, and
// since every block shares the same rest position the newest is simply drawn on top.
PanelWindow {
    id: root

    required property BarState barState

    visible: barState.notifications.count > 0
    color:   "transparent"

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "qs-center-popup"

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    // Notifications are non-interactive — let clicks pass through the overlay.
    mask: Region {}

    readonly property color blockColor: Theme.frameColor
    readonly property real  fillet:     Theme.innerRadius
    readonly property real  bodyW:      400
    readonly property real  bodyH:      125

    // Avatar (dummy profile picture) — left-side counterpart to the text. Sized so
    // its top, left and bottom gaps are all equal to avatarMargin.
    readonly property real avatarMargin: Theme.frameThickness
    readonly property real avatarSize:   bodyH - 2 * avatarMargin

    // Shared bar-style motion.
    readonly property int  notifLifetime: 5000   // how long a notification stays before auto-retracting
    readonly property int  animDuration:  700
    readonly property var  animCurve:     [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]

    // Stack container fixed to the top-right, nudged down by one border thickness so
    // the block's top-left fillet meets the border's inner edge cleanly. Shares the
    // Top layer with the border but is instantiated after it, so it draws on top.
    Item {
        anchors.right:       parent.right
        anchors.rightMargin: Theme.barWidth
        anchors.top:         parent.top
        anchors.topMargin:   Theme.frameThickness
        anchors.bottom:      parent.bottom
        width:               root.bodyW + root.fillet

        Repeater {
            model: root.barState.notifications

            delegate: Item {
                id: block

                required property int    notifId
                required property string  app
                required property string  username
                required property string  preview
                required property string  image
                required property bool    circle

                width:  root.bodyW + root.fillet
                height: root.bodyH + root.fillet

                // All blocks share the same rest position; the newest (appended last,
                // drawn last) stacks on top. On open the block slides DOWN into place
                // from above the screen edge, fully formed — so it reads as coming in
                // from outside the monitor, with no corner deformation and no gap.
                y: slideY

                // slideY: vertical slide offset — starts fully above the screen and
                //         animates to 0 (rest) on open.
                // leftX:  body left edge; OUT retracts it to brX so the block shrinks
                //         into the bar before removal.
                property real slideY: -(root.bodyH + root.fillet + Theme.frameThickness)
                property real leftX:  root.fillet

                readonly property real brX:  root.fillet + root.bodyW
                readonly property real curW: brX - leftX

                // Corner radii — full at rest, capped only by the current width so they
                // collapse cleanly as the block retracts into the bar on OUT.
                // Discord: bottom-left follows the circular avatar (+6px ≈ half margin + 1px).
                readonly property real frRight: Math.min(root.fillet, curW)
                readonly property real blRadius:  block.circle
                    ? (root.avatarSize / 2 + 6)
                    : root.fillet
                readonly property real bl:      Math.max(0, Math.min(blRadius, curW - frRight))
                readonly property real frLeft:  Math.min(root.fillet, curW)

                // IN: slide down from above the screen into the rest position.
                NumberAnimation {
                    id: inAnim
                    target: block; property: "slideY"; to: 0
                    duration:           root.animDuration
                    easing.type:        Easing.BezierSpline
                    easing.bezierCurve: root.animCurve
                }

                // OUT: retract left-to-right, then drop the entry from the model.
                SequentialAnimation {
                    id: outAnim
                    NumberAnimation {
                        target: block; property: "leftX"; to: block.brX
                        duration:           root.animDuration
                        easing.type:        Easing.BezierSpline
                        easing.bezierCurve: root.animCurve
                    }
                    ScriptAction { script: root.barState.removeNotification(block.notifId) }
                }

                Timer {
                    interval: root.notifLifetime
                    running:  true
                    onTriggered: outAnim.start()
                }

                Component.onCompleted: inAnim.start()

                // Whole block as ONE continuous, always full-size outline — corners
                // never deform, so the top-left fillet always meets the border (no gap).
                Shape {
                    width:  block.width
                    height: block.height
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor:   root.blockColor
                        strokeColor: "transparent"
                        strokeWidth: 0

                        startX: block.leftX - block.frLeft
                        startY: 0

                        PathLine { x: block.brX;                 y: 0 }
                        PathLine { x: block.brX;                 y: root.bodyH + block.frRight }
                        PathArc  { x: block.brX - block.frRight; y: root.bodyH
                                   radiusX: block.frRight; radiusY: block.frRight
                                   direction: PathArc.Counterclockwise }
                        PathLine { x: block.leftX + block.bl;    y: root.bodyH }
                        PathArc  { x: block.leftX;               y: root.bodyH - block.bl
                                   radiusX: block.bl; radiusY: block.bl
                                   direction: PathArc.Clockwise }
                        PathLine { x: block.leftX;               y: block.frLeft }
                        PathArc  { x: block.leftX - block.frLeft; y: 0
                                   radiusX: block.frLeft; radiusY: block.frLeft
                                   direction: PathArc.Counterclockwise }
                    }
                }

                // Content clipped to the body box; horizontally it rides the left edge
                // into the bar on OUT. It's centred and slides in with the block.
                Item {
                    x:      block.leftX
                    y:      0
                    width:  block.curW
                    height: root.bodyH
                    clip:   true

                    Item {
                        id: avatar

                        x:      root.avatarMargin
                        y:      (root.bodyH - root.avatarSize) / 2
                        width:  root.avatarSize
                        height: root.avatarSize

                        // Circle for Discord (its avatar is pre-masked round), rounded
                        // square for everything else (Spotify, …) which send full squares.
                        // A radius/clip alone does NOT round a child Image's corners, so
                        // the image is masked explicitly below via MultiEffect.
                        readonly property real radius: block.circle ? width / 2 : (Theme.innerRadius - root.avatarMargin)
                        readonly property bool discordLogo: block.circle && Recorder.recording

                        Rectangle {
                            anchors.fill: parent
                            radius:  avatar.radius
                            color:   Theme.islandBg
                        }

                        // Screenshare: bundled Discord app icon, clipped to a circle.
                        Image {
                            id: discordLogoImg
                            anchors.fill: parent
                            visible: avatar.discordLogo
                            source: Quickshell.shellPath("assets/discord.png")
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource:  avatarMask
                            }
                        }

                        // Fallback "?" while the image loads or is missing.
                        Text {
                            anchors.centerIn: parent
                            visible: !avatar.discordLogo && avatarImg.status !== Image.Ready
                            text: "?"
                            color: Theme.islandMuted
                            font.pixelSize: avatar.width * 0.5
                            font.bold: true
                        }

                        // Sender's image (e.g. Discord avatar / Spotify art), masked to
                        // `avatar.radius` so its corners are actually rounded.
                        Image {
                            id: avatarImg
                            anchors.fill:      parent
                            source:            block.image ? Qt.resolvedUrl(block.image) : ""
                            fillMode:          Image.PreserveAspectCrop
                            sourceSize.width:  root.avatarSize
                            sourceSize.height: root.avatarSize
                            cache:             false
                            asynchronous:      true
                            visible:           !avatar.discordLogo && status === Image.Ready
                            layer.enabled:     true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource:  avatarMask
                            }
                        }

                        // Mask: a white rounded rect whose alpha cuts the image corners.
                        Item {
                            id: avatarMask
                            anchors.fill:  avatar
                            layer.enabled: true
                            visible:       false

                            Rectangle {
                                anchors.fill: parent
                                radius:       avatar.radius
                                antialiasing: true
                            }
                        }
                    }

                    // Username + message preview, stacked to the right of the avatar.
                    Column {
                        readonly property real leftPad:  root.avatarMargin + root.avatarSize + 16
                        readonly property real rightPad: 16
                        readonly property bool privacyBlur: block.circle && Recorder.recording

                        x:       leftPad
                        y:       (root.bodyH - height) / 2
                        width:   root.bodyW - leftPad - rightPad
                        spacing: 10

                        Row {
                            width: parent.width
                            spacing: 0

                            Text {
                                id: appLabel
                                text: block.app + " | "
                                color: Theme.notifUsername
                                font.family: "Iosevka"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            Text {
                                width: Math.max(0, parent.width - appLabel.width)
                                text: block.username
                                color: Theme.notifUsername
                                font.family: "Iosevka"
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight

                                layer.enabled: parent.parent.privacyBlur
                                layer.effect: MultiEffect {
                                    blurEnabled: true
                                    blur: 1
                                    blurMax: 40
                                }
                            }
                        }

                        Text {
                            width:           parent.width
                            text:            block.preview
                            color:           Theme.notifPreview
                            font.family:     "Iosevka"
                            font.pixelSize:  14
                            wrapMode:        Text.Wrap
                            maximumLineCount: 2
                            elide:           Text.ElideRight

                            layer.enabled: parent.privacyBlur
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: 1
                                blurMax: 28
                            }
                        }
                    }
                }
            }
        }
    }
}
