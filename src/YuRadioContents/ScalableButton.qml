import QtQuick.Controls

Button {
    property alias fontPointSize: scalableFontPicker.fontPointSize

    ScalableFontPicker {
        id: scalableFontPicker
    }
}
