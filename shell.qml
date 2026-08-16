import Quickshell
import QtQuick
import "components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        Bar {
            property var modelData
            screen: modelData
        }
    }
}
