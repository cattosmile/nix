import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property real borderThickness

    readonly property alias activationRegion: activationZone
    readonly property alias interactionRegion: panelInteraction
    readonly property real surfaceWidth: 640
    readonly property real baseSurfaceHeight: 72
    readonly property real resultRowStep: 48
    readonly property real resultRowHeight: 40
    readonly property real surfaceCornerRadius: 20
    readonly property real surfaceInset: 16
    readonly property real searchCornerRadius:
        Math.max(0, surfaceCornerRadius - surfaceInset)
    readonly property real surfaceX: (width - surfaceWidth) / 2
    readonly property real visibleY: borderThickness - 2
    readonly property real hiddenY: -surfaceHeight - 4
    readonly property var results: searchApplications()
    readonly property real targetSurfaceHeight:
        baseSurfaceHeight + results.length * resultRowStep
    readonly property bool pointerInside:
        activationHover.hovered || panelHover.hovered

    property real surfaceY: hiddenY
    property real surfaceHeight: targetSurfaceHeight
    property bool openRequested: false
    property bool surfaceVisible: false
    property bool keyboardActive: false
    property int selectedIndex: 0

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.openRequested)
                root.requestClose();
            else
                root.requestOpen();
        }

        function open(): void {
            root.requestOpen();
        }

        function close(): void {
            root.requestClose();
        }
    }

    function searchableText(entry) {
        const keywords = entry.keywords
            ? Array.from(entry.keywords).join("")
            : "";
        const categories = entry.categories
            ? Array.from(entry.categories).join("")
            : "";

        // Wofi's drun mode concatenates all searchable desktop metadata into
        // one string before applying multi-contains.
        return [
            entry.name || "",
            entry.id || "",
            entry.execString || "",
            entry.comment || "",
            categories,
            keywords,
            entry.genericName || ""
        ].join("").toLocaleLowerCase();
    }

    function applicationIcon(entry) {
        return Quickshell.iconPath(
            entry.icon || "application-x-executable"
        );
    }

    function papirusApplicationIconPath(entry) {
        const icon = entry.icon || "";

        if (!/^[A-Za-z0-9._+-]+$/.test(icon))
            return "";

        return "/etc/profiles/per-user/user/share/icons/"
            + "Papirus/64x64/apps/" + icon + ".svg";
    }

    function multiContainsScore(entry, tokens) {
        const haystack = searchableText(entry);
        let score = 0;

        for (const token of tokens) {
            const position = haystack.indexOf(token);

            if (position < 0)
                return -1;

            score += position;
        }

        return score;
    }

    function searchApplications() {
        const query = searchInput.text.trim().toLocaleLowerCase();

        if (query.length === 0)
            return [];

        const tokens = query.split(/\s+/).filter(token => token.length > 0);

        return DesktopEntries.applications.values
            .filter(entry => !entry.noDisplay)
            .map((entry, order) => {
                const name = (entry.name || "").toLocaleLowerCase();

                return {
                    entry: entry,
                    order: order,
                    score: multiContainsScore(entry, tokens),
                    exactName: name === query ? 0 : 1,
                    namePrefix: name.startsWith(query) ? 0 : 1,
                    nameLength: name.length
                };
            })
            .filter(candidate => candidate.score >= 0)
            .sort((left, right) =>
                left.exactName - right.exactName
                    || left.namePrefix - right.namePrefix
                    || left.score - right.score
                    || left.nameLength - right.nameLength
                    || left.order - right.order)
            .slice(0, 3)
            .map(candidate => candidate.entry);
    }

    function launchResult(index) {
        if (index < 0 || index >= results.length)
            return;

        const entry = results[index];

        // Steam's split-tunnel desktop entry starts a second process even when
        // the client already exists. Focus that window first. On a fresh start,
        // prefer Mullvad's wrapper and fall back to Steam if the local cgroup
        // permission currently prevents mullvad-exclude from launching it.
        if (entry.id === "mullvad-excluded-steam") {
            Quickshell.execDetached([
                "bash",
                "-lc",
                "if hyprctl repl 'for _,w in pairs(hl.get_windows()) "
                    + "do if w.class == \"steam\" then print(\"yes\") "
                    + "end end' | grep -qx yes; then "
                    + "exec hyprctl dispatch 'hl.dsp.focus({ "
                    + "window = \"class:^steam$\" })'; "
                    + "else mullvad-exclude steam || exec steam; fi"
            ]);
        } else {
            entry.execute();
        }

        requestClose();
    }

    function requestOpen() {
        closeTimer.stop();

        if (openRequested && surfaceVisible)
            return;

        openRequested = true;
        surfaceVisible = true;
        keyboardActive = true;
        slideAnimation.stop();
        slideAnimation.from = surfaceY;
        slideAnimation.to = visibleY;
        slideAnimation.start();
    }

    function requestClose() {
        if (!surfaceVisible || !openRequested)
            return;

        openRequested = false;
        keyboardActive = false;
        searchInput.focus = false;
        slideAnimation.stop();
        slideAnimation.from = surfaceY;
        slideAnimation.to = hiddenY;
        slideAnimation.start();
    }

    anchors.fill: parent

    onResultsChanged: selectedIndex = 0

    onPointerInsideChanged: {
        if (pointerInside) {
            requestOpen();
        } else if (surfaceVisible) {
            closeTimer.restart();
        }
    }

    Item {
        id: activationZone

        x: root.surfaceX
        y: 0
        width: root.surfaceWidth
        height: root.borderThickness

        HoverHandler {
            id: activationHover
        }
    }

    Item {
        id: panelInteraction

        visible: root.surfaceVisible
        x: root.surfaceX
        y: root.surfaceY
        width: root.surfaceWidth
        height: root.surfaceHeight

        HoverHandler {
            id: panelHover
        }
    }

    Item {
        id: contentClip

        x: 0
        y: root.borderThickness
        width: root.width
        height: root.height - y
        clip: true

        Item {
            id: panelContent

            x: root.surfaceX
            y: root.surfaceY - contentClip.y
            width: root.surfaceWidth
            height: root.surfaceHeight
            clip: true

            Rectangle {
                id: searchField

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: root.surfaceInset
                }

                height: 40
                radius: root.searchCornerRadius
                color: Theme.launcherField
                antialiasing: true

                Text {
                    visible: searchInput.text.length === 0
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }

                    text: "Start typing..."
                    color: Theme.launcherPlaceholder
                    font {
                        family: "Iosevka"
                        pixelSize: 16
                    }
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                TextInput {
                    id: searchInput

                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }

                    color: Theme.launcherText
                    selectionColor: Theme.launcherSelection
                    selectedTextColor: Theme.launcherSelectedText
                    clip: true
                    cursorDelegate: Item {
                        width: 0
                        visible: false
                    }
                    font {
                        family: "Iosevka"
                        pixelSize: 16
                    }
                    verticalAlignment: TextInput.AlignVCenter

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.requestClose();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down
                                && root.results.length > 0) {
                            root.selectedIndex =
                                (root.selectedIndex + 1)
                                % root.results.length;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up
                                && root.results.length > 0) {
                            root.selectedIndex =
                                (root.selectedIndex
                                    + root.results.length - 1)
                                % root.results.length;
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_Return
                                    || event.key === Qt.Key_Enter)
                                && root.results.length > 0) {
                            root.launchResult(root.selectedIndex);
                            event.accepted = true;
                        }
                    }
                }
            }

            Column {
                id: resultColumn

                x: root.surfaceInset
                y: 64
                width: parent.width - 2 * root.surfaceInset
                spacing: root.resultRowStep - root.resultRowHeight

                Repeater {
                    model: ScriptModel {
                        values: root.results
                    }

                    Item {
                        id: resultRow

                        required property var modelData
                        required property int index

                        width: resultColumn.width
                        height: root.resultRowHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: root.searchCornerRadius
                            color: resultMouse.containsMouse
                                    || root.selectedIndex === resultRow.index
                                ? Theme.launcherResultHover
                                : Theme.transparent
                            antialiasing: true
                        }

                        Item {
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            width: 28
                            height: 28

                            FileView {
                                id: papirusIconFile

                                property string readyPath: ""

                                path: root.papirusApplicationIconPath(
                                    resultRow.modelData
                                )
                                preload: true
                                printErrors: false
                                onPathChanged: readyPath = ""
                                onLoaded: readyPath = path
                                onLoadFailed: readyPath = ""
                            }

                            IconImage {
                                anchors.fill: parent
                                source: papirusIconFile.readyPath !== ""
                                    ? "file://" + papirusIconFile.readyPath
                                    : root.applicationIcon(
                                        resultRow.modelData
                                    )
                                mipmap: false
                            }
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 50
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }

                            text: resultRow.modelData.name
                            color: Theme.launcherText
                            font {
                                family: "Iosevka"
                                pixelSize: 15
                                weight: Font.Medium
                            }
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: resultMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = resultRow.index
                            onClicked: root.launchResult(resultRow.index)
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: closeTimer

        interval: 160
        onTriggered: {
            if (!root.pointerInside)
                root.requestClose();
        }
    }

    NumberAnimation {
        id: slideAnimation

        target: root
        property: "surfaceY"
        duration: 280
        easing.type: Easing.OutBack
        easing.overshoot: 1.15
        onFinished: {
            if (root.openRequested) {
                Qt.callLater(() => searchInput.forceActiveFocus());
            } else {
                root.surfaceY = root.hiddenY;
                root.surfaceVisible = false;
                searchInput.clear();
            }
        }
    }

    Behavior on surfaceHeight {
        enabled: root.surfaceVisible

        NumberAnimation {
            duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }
}
