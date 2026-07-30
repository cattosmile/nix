import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    required property real borderThickness
    required property real rightThickness

    readonly property real surfaceOverlap: 2
    readonly property real panelWidth: 400
    readonly property real panelHeight: 124
    readonly property real surfaceCornerRadius: 20
    readonly property real hiddenSurfaceTail: 20
    readonly property real surfaceWidth:
        panelWidth + hiddenSurfaceTail
    readonly property real entryDistance:
        panelHeight + borderThickness
    readonly property real exitDistance:
        panelWidth + rightThickness
    readonly property int springDuration: 280
    readonly property real springOvershoot: 1.15

    readonly property bool frontSurfaceVisible: frontVisible
    readonly property real frontSurfaceX: frontXOffset
    readonly property real frontSurfaceY: frontYOffset
    readonly property bool backSurfaceVisible: backVisible
    readonly property real backSurfaceX: backXOffset
    readonly property real backSurfaceY: backYOffset

    property bool frontVisible: false
    property bool backVisible: false
    property bool entering: false
    property bool closing: false
    property int notificationSerial: 0
    property real frontXOffset: 0
    property real frontYOffset: 0
    property real backXOffset: 0
    property real backYOffset: 0

    property var frontNotification: null
    property var backNotification: null
    property string frontTitle: ""
    property string frontBody: ""
    property string frontIcon: ""
    property string backTitle: ""
    property string backBody: ""
    property string backIcon: ""
    property bool frontIsDiscord: false
    property bool backIsDiscord: false
    property string frontDiscordRoute: ""
    property string backDiscordRoute: ""

    readonly property bool frontInteractive:
        frontVisible
            && (frontDiscordRoute !== ""
                || defaultAction(frontNotification) !== null)

    width: panelWidth
    height: panelHeight

    function displayTitle(notification) {
        const appName = PersonalNotificationRules.displayAppName(
            String(notification?.appName ?? "").trim()
        );
        const summary = String(notification?.summary ?? "").trim();

        if (appName !== "" && summary !== ""
                && appName.toLowerCase() !== summary.toLowerCase()) {
            return appName + " | " + summary;
        }

        return summary !== "" ? summary : appName;
    }

    function displayIcon(notification) {
        const candidate = String(
            notification?.image
                || notification?.appIcon
                || ""
        ).trim();

        if (candidate === "")
            return "";

        if (candidate.startsWith("/"))
            return "file://" + candidate;

        if (candidate.includes("://")
                || candidate.startsWith("data:")) {
            return candidate;
        }

        return Quickshell.iconPath(candidate, true);
    }

    function copyFrontToBack() {
        backNotification = frontNotification;
        backTitle = frontTitle;
        backBody = frontBody;
        backIcon = frontIcon;
        backIsDiscord = frontIsDiscord;
        backDiscordRoute = frontDiscordRoute;
        backXOffset = 0;
        backYOffset = 0;
        backVisible = frontVisible;
    }

    function releaseBack() {
        const notification = backNotification;

        backNotification = null;
        backVisible = false;
        backTitle = "";
        backBody = "";
        backIcon = "";
        backIsDiscord = false;
        backDiscordRoute = "";

        if (notification
                && notification !== frontNotification
                && notification.tracked) {
            notification.expire();
        }
    }

    function releaseFront() {
        const notification = frontNotification;

        frontNotification = null;
        frontVisible = false;
        frontTitle = "";
        frontBody = "";
        frontIcon = "";
        frontIsDiscord = false;
        frontDiscordRoute = "";

        if (notification && notification.tracked)
            notification.expire();
    }

    function showNotification(notification) {
        const serial = ++notificationSerial;

        expiryTimer.stop();
        entryAnimation.stop();
        exitAnimation.stop();

        releaseBack();

        if (frontVisible)
            copyFrontToBack();

        frontNotification = notification;
        frontTitle = displayTitle(notification);
        const rawBody = String(notification?.body ?? "");
        frontBody = PersonalNotificationRules
            .notificationBody(rawBody)
            .trim();
        frontIcon = displayIcon(notification);
        frontIsDiscord = PersonalNotificationRules.isDiscord(
            notification?.appName
        );
        frontDiscordRoute = frontIsDiscord
            ? PersonalNotificationRules.discordRoute(rawBody)
            : "";
        frontVisible = true;
        frontXOffset = 0;
        frontYOffset = -entryDistance;
        entering = true;
        closing = false;

        notification.closed.connect(reason => {
            if (serial !== root.notificationSerial
                    || root.frontNotification !== notification) {
                return;
            }

            root.frontNotification = null;
            root.requestClose(false);
        });

        entryAnimation.from = -entryDistance;
        entryAnimation.to = 0;
        entryAnimation.restart();
    }

    function requestClose(expireNotification = true) {
        if (!frontVisible || closing)
            return;

        expiryTimer.stop();
        entryAnimation.stop();
        releaseBack();
        entering = false;
        closing = true;
        frontYOffset = 0;

        if (!expireNotification)
            frontNotification = null;

        exitAnimation.from = frontXOffset;
        exitAnimation.to = exitDistance;
        exitAnimation.restart();
    }

    function defaultAction(notification) {
        const actions = notification?.actions ?? [];

        for (let index = 0; index < actions.length; ++index) {
            const action = actions[index];

            if (String(action?.identifier ?? "") === "default")
                return action;
        }

        return null;
    }

    function activateFrontNotification() {
        const notification = frontNotification;
        const action = defaultAction(notification);

        if (!notification)
            return;

        if (frontIsDiscord && frontDiscordRoute !== "") {
            discordRouteProcess.command = [
                "bash",
                Quickshell.shellPath(
                    "scripts/open-discord-route.sh"
                ),
                frontDiscordRoute
            ];
            discordRouteProcess.running = true;
        } else if (action) {
            action.invoke();
        } else {
            return;
        }

        if (notification.tracked)
            notification.dismiss();

        requestClose(false);
    }

    Process {
        id: discordRouteProcess

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Connections {
        target: NotificationController

        function onReceived(notification) {
            root.showNotification(notification);
        }
    }

    Timer {
        id: expiryTimer

        interval: 5000
        onTriggered: root.requestClose()
    }

    NumberAnimation {
        id: entryAnimation

        target: root
        property: "frontYOffset"
        duration: root.springDuration
        easing.type: Easing.OutBack
        easing.overshoot: root.springOvershoot

        onFinished: {
            if (!root.entering)
                return;

            root.frontYOffset = 0;
            root.entering = false;
            root.releaseBack();
            expiryTimer.restart();
        }
    }

    NumberAnimation {
        id: exitAnimation

        target: root
        property: "frontXOffset"
        duration: root.springDuration
        easing.type: Easing.OutBack
        easing.overshoot: root.springOvershoot

        onFinished: {
            if (!root.closing)
                return;

            root.closing = false;
            root.releaseFront();
            root.frontXOffset = 0;
            root.frontYOffset = 0;
        }
    }

    component CardContent: Item {
        id: cardContent

        required property string titleText
        required property string bodyText
        required property string iconSource
        required property bool discordNotification
        required property bool interactive

        readonly property bool privacyMode:
            discordNotification && ScreenShareController.active

        Item {
            id: iconBackground

            readonly property real artworkCornerRadius:
                root.surfaceCornerRadius - 10
            readonly property real artworkCornerControl:
                artworkCornerRadius * 0.7392083757

            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: 104
            height: 104

            Item {
                id: iconArtwork

                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    visible: !cardContent.privacyMode
                    color: Theme.notificationIconBackground
                }

                IconImage {
                    anchors.fill: parent
                    source: cardContent.iconSource
                    mipmap: true
                    visible: !cardContent.privacyMode
                        && source.toString() !== ""
                }

                Item {
                    anchors.fill: parent
                    visible: cardContent.privacyMode

                    Rectangle {
                        anchors.fill: parent
                        radius: 0
                        color: Theme.notificationPrivacyAvatar
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        text: "\uf392"
                        color: Theme.notificationPrivacyLogo
                        font {
                            family: "Font Awesome 7 Brands"
                            pixelSize: 59
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: !cardContent.privacyMode
                        && cardContent.iconSource === ""
                        && cardContent.titleText !== ""
                    text: cardContent.titleText
                        .charAt(0)
                        .toUpperCase()
                    color: Theme.notificationText
                    font {
                        family: "monospace"
                        pixelSize: 48
                    }
                }
            }

            ShaderEffectSource {
                id: iconTexture

                anchors.fill: parent
                visible: false
                sourceItem: iconArtwork
                hideSource: true
                live: true
                smooth: true
            }

            Shape {
                id: iconShape

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: -1
                    strokeColor: "transparent"
                    fillColor: "transparent"
                    fillItem: iconTexture
                    startX: iconBackground.artworkCornerRadius
                    startY: 0

                    PathLine {
                        x: iconShape.width
                            - iconBackground.artworkCornerRadius
                        y: 0
                    }
                    PathCubic {
                        control1X: iconShape.width
                            - iconBackground.artworkCornerRadius
                            + iconBackground.artworkCornerControl
                        control1Y: 0
                        control2X: iconShape.width
                        control2Y: iconBackground.artworkCornerRadius
                            - iconBackground.artworkCornerControl
                        x: iconShape.width
                        y: iconBackground.artworkCornerRadius
                    }
                    PathLine {
                        x: iconShape.width
                        y: iconShape.height
                            - iconBackground.artworkCornerRadius
                    }
                    PathCubic {
                        control1X: iconShape.width
                        control1Y: iconShape.height
                            - iconBackground.artworkCornerRadius
                            + iconBackground.artworkCornerControl
                        control2X: iconShape.width
                            - iconBackground.artworkCornerRadius
                            + iconBackground.artworkCornerControl
                        control2Y: iconShape.height
                        x: iconShape.width
                            - iconBackground.artworkCornerRadius
                        y: iconShape.height
                    }
                    PathLine {
                        x: iconBackground.artworkCornerRadius
                        y: iconShape.height
                    }
                    PathCubic {
                        control1X:
                            iconBackground.artworkCornerRadius
                            - iconBackground.artworkCornerControl
                        control1Y: iconShape.height
                        control2X: 0
                        control2Y: iconShape.height
                            - iconBackground.artworkCornerRadius
                            + iconBackground.artworkCornerControl
                        x: 0
                        y: iconShape.height
                            - iconBackground.artworkCornerRadius
                    }
                    PathLine {
                        x: 0
                        y: iconBackground.artworkCornerRadius
                    }
                    PathCubic {
                        control1X: 0
                        control1Y: iconBackground.artworkCornerRadius
                            - iconBackground.artworkCornerControl
                        control2X: iconBackground.artworkCornerRadius
                            - iconBackground.artworkCornerControl
                        control2Y: 0
                        x: iconBackground.artworkCornerRadius
                        y: 0
                    }
                }
            }
        }

        Column {
            anchors {
                left: iconBackground.right
                leftMargin: 18
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            Item {
                width: parent.width
                height: Math.max(
                    titleLabel.implicitHeight,
                    privacyTitle.implicitHeight
                )

                Text {
                    id: titleLabel

                    anchors.fill: parent
                    visible: !cardContent.privacyMode
                    text: cardContent.titleText
                    color: Theme.notificationText
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font {
                        family: "Iosevka"
                        pixelSize: 18
                        weight: Font.DemiBold
                    }
                }

                Row {
                    id: privacyTitle

                    visible: cardContent.privacyMode
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        text: "Discord | "
                        color: Theme.notificationText
                        font {
                            family: "Iosevka"
                            pixelSize: 18
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        width: Math.min(190, Math.max(0, parent.width - x))
                        text: "████████████"
                        color: Theme.notificationText
                        opacity: 0.72
                        clip: true
                        font {
                            family: "Iosevka"
                            pixelSize: 15
                            weight: Font.DemiBold
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1
                            blurMax: 30
                            autoPaddingEnabled: false
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: !cardContent.privacyMode && text !== ""
                text: cardContent.bodyText
                color: Theme.notificationBody
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
                font {
                    family: "Iosevka"
                    pixelSize: 14
                }
            }

            Text {
                width: Math.min(260, parent.width)
                visible: cardContent.privacyMode
                text: "██████████████████"
                color: Theme.notificationBody
                opacity: 0.62
                clip: true
                font {
                    family: "Iosevka"
                    pixelSize: 11
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 24
                    autoPaddingEnabled: false
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: cardContent.interactive
            acceptedButtons: Qt.LeftButton
            cursorShape: enabled
                ? Qt.PointingHandCursor
                : Qt.ArrowCursor
            onClicked: root.activateFrontNotification()
        }
    }

    Item {
        id: contentClip

        y: root.surfaceOverlap
        width: root.panelWidth - root.surfaceOverlap
        height: root.panelHeight - y
        clip: true

        Item {
            id: backReveal

            readonly property real coverBottom: root.entering
                ? root.frontYOffset + root.panelHeight
                : 0

            y: Math.max(
                0,
                Math.min(
                    parent.height,
                    coverBottom - contentClip.y
                )
            )
            width: parent.width
            height: parent.height - y
            clip: true
            visible: root.backVisible && height > 0

            CardContent {
                x: root.backXOffset
                y: root.backYOffset
                    - contentClip.y
                    - backReveal.y
                width: root.panelWidth
                height: root.panelHeight
                titleText: root.backTitle
                bodyText: root.backBody
                iconSource: root.backIcon
                discordNotification: root.backIsDiscord
                interactive: false
            }
        }

        CardContent {
            x: root.frontXOffset
            y: root.frontYOffset - contentClip.y
            width: root.panelWidth
            height: root.panelHeight
            visible: root.frontVisible
            titleText: root.frontTitle
            bodyText: root.frontBody
            iconSource: root.frontIcon
            discordNotification: root.frontIsDiscord
            interactive: root.frontInteractive
        }
    }
}
