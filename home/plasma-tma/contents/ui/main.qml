import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

/*
 * Panel badge for the TMA VPN and the office desktop.
 *
 *   left click  -> toggle the VPN
 *   right click -> Plasma's applet menu, with our contextual actions
 *
 * Status is polled from the kernel: charon's route table (220) for the tunnel
 * and a pgrep for the xfreerdp session. Both need no privileges.
 */
PlasmoidItem {
    id: root

    // Absolute: QML has no notion of $HOME.
    readonly property string vpnScript: "/home/binhtd/dotfiles/vpn/vpn.sh"
    readonly property string rdpScript: "/home/binhtd/dotfiles/vpn/rdp.sh"

    property bool vpnUp: false
    property bool rdpUp: false

    // Nothing is going on: the badge is only useful while the tunnel is up or
    // a session is open. Collapsing to zero width gives the space back to the
    // task list; it reappears on its own as soon as either is in use.
    readonly property bool idle: !root.vpnUp && !root.rdpUp
    readonly property bool shown: !root.hideWhenIdle || !root.idle
    readonly property bool hideWhenIdle: Plasmoid.configuration.hideWhenIdle === undefined
        ? true : Plasmoid.configuration.hideWhenIdle

    readonly property string statusCommand:
        "sh -c 'ip route show table 220 2>/dev/null | grep -q 192.168.104. && echo up || echo down; pgrep -x xfreerdp >/dev/null && echo up || echo down'"

    function run(command) {
        exec.connectSource("sh -c '" + command + "'");
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            if (source === root.statusCommand) {
                var lines = String((data && data["stdout"]) || "").trim().split("\n");
                root.vpnUp = lines[0] === "up";
                root.rdpUp = lines[1] === "up";
            }
            disconnectSource(source);
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: exec.connectSource(root.statusCommand)
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "VPN: connect"
            icon.name: "network-vpn"
            enabled: !root.vpnUp
            onTriggered: root.run(root.vpnScript + " up")
        },
        PlasmaCore.Action {
            text: "VPN: disconnect"
            icon.name: "network-offline"
            enabled: root.vpnUp
            onTriggered: root.run(root.vpnScript + " down")
        },
        PlasmaCore.Action {
            text: "Open office desktop"
            icon.name: "preferences-desktop-remote-desktop"
            onTriggered: root.run(root.rdpScript)
        },
        PlasmaCore.Action {
            text: "Update RDP password"
            icon.name: "dialog-password"
            onTriggered: root.run(root.rdpScript + " --set-password")
        }
    ]

    fullRepresentation: Item {
        id: badge

        readonly property int itemWidth: Math.ceil(grid.implicitWidth) + Kirigami.Units.smallSpacing * 2

        visible: root.shown
        Layout.minimumWidth: root.shown ? itemWidth : 0
        Layout.preferredWidth: root.shown ? itemWidth : 0
        Layout.maximumWidth: root.shown ? itemWidth : 0
        implicitWidth: root.shown ? itemWidth : 0
        implicitHeight: Math.max(grid.implicitHeight, Kirigami.Units.iconSizes.small)

        GridLayout {
            id: grid
            anchors.centerIn: parent
            columns: 2
            rowSpacing: 0
            columnSpacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: "TMA:"
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Layout.row: 0
                Layout.column: 0
            }
            PlasmaComponents.Label {
                text: "VPN " + (root.vpnUp ? "●" : "○")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: root.vpnUp ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                Layout.row: 0
                Layout.column: 1
            }
            PlasmaComponents.Label {
                text: "RDP " + (root.rdpUp ? "●" : "○")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: root.rdpUp ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                Layout.row: 1
                Layout.column: 1
            }
        }

        // Only the left button, so right-click opens Plasma's applet menu.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.run(root.vpnScript + " toggle")
        }
    }

    preferredRepresentation: fullRepresentation
}
