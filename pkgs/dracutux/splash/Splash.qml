// Dracutux splash screen: the desktop wallpaper, so login -> desktop is
// seamless (the Arc look-and-feel used to show its own wallpaper here).
import QtQuick 2.15

Image {
    id: root

    // ksplashqml sets this on the root object.
    property int stage: 0

    source: "images/background.svg"
    fillMode: Image.PreserveAspectCrop
    asynchronous: false
}
