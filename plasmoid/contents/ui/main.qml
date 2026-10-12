// SPDX-License-Identifier: MIT
// System tray applet for kbd-autolight.

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property string cli: "/usr/bin/kbd-autolight"

    property bool active: false
    property bool busy: false
    property bool hasSensor: true
    property real lux: -1
    property int level: -1
    property int maxLevel: 0
    property int pauseLeft: 0

    readonly property string iconName: "input-keyboard-brightness"
    readonly property string luxText: lux >= 0
        ? i18n("Ambient light: %1 lux", Math.round(lux))
        : i18n("Light sensor not available")

    Plasmoid.icon: iconName
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    toolTipMainText: i18n("Automatic keyboard brightness")
    toolTipSubText: (active ? i18n("Active") : i18n("Inactive")) + "\n" + luxText

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 8

    // ---------------------------------------------------------------- backend
    function run(arg) {
        executable.connectSource(cli + " " + arg)
    }

    function refresh() {
        run("status")
    }

    function setActive(on) {
        busy = true
        active = on
        run(on ? "enable" : "disable")
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: (source, data) => {
            disconnectSource(source)
            if (source === root.cli + " status") {
                let s = null
                try {
                    s = JSON.parse(data["stdout"])
                } catch (e) {
                    return
                }
                if (!root.busy) {
                    root.active = s.active
                }
                root.hasSensor = s.sensor
                root.lux = (s.lux === null) ? -1 : s.lux
                root.level = (s.level === null) ? -1 : s.level
                root.maxLevel = (s.max === null) ? 0 : s.max
                root.pauseLeft = s.pause_left
            } else {
                // enable / disable / resume finished
                root.busy = false
                root.refresh()
            }
        }
    }

    Timer {
        interval: root.expanded ? 2000 : 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    onExpandedChanged: if (expanded) refresh()

    // ------------------------------------------------------------------ panel
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.setActive(!root.active)
            } else {
                root.expanded = !root.expanded
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: root.iconName
            fallback: "input-keyboard"
            active: compact.containsMouse
            opacity: root.active ? 1.0 : 0.45
        }
    }

    // ------------------------------------------------------------------ popup
    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: root.iconName
                fallback: "input-keyboard"
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: i18n("Automatic keyboard brightness")
                    wrapMode: Text.WordWrap
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: i18n("Adjusts the keyboard backlight to the ambient light")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                }
            }

            PlasmaComponents3.Switch {
                checked: root.active
                enabled: !root.busy && root.hasSensor
                onToggled: root.setActive(checked)
                Accessible.name: i18n("Automatic keyboard brightness")
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: root.luxText
            wrapMode: Text.WordWrap
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.level >= 0 && root.maxLevel > 0
            text: i18n("Keyboard backlight: level %1 of %2", root.level, root.maxLevel)
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.active && root.pauseLeft > 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: i18n("Paused after a manual change (%1 min left)",
                           Math.ceil(root.pauseLeft / 60))
                wrapMode: Text.WordWrap
                opacity: 0.8
            }
            PlasmaComponents3.Button {
                text: i18n("Resume now")
                icon.name: "media-playback-start"
                onClicked: {
                    root.busy = true
                    root.run("resume")
                }
            }
        }
    }
}
