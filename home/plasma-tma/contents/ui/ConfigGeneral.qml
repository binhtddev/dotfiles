import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Kirigami.FormLayout {
    QQC2.CheckBox {
        Kirigami.FormData.label: i18n("Visibility:")
        text: i18n("Hide when the VPN is down and no session is running")
        checked: Plasmoid.configuration.hideWhenIdle
        onToggled: Plasmoid.configuration.hideWhenIdle = checked
    }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Left click toggles the VPN. Right click opens the actions: connect, disconnect, open the office desktop, update the RDP password.")
        wrapMode: Text.WordWrap
    }
}
