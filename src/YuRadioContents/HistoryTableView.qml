pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import Qt.labs.qmlmodels

import YuRadioContents
import Main

Rectangle {
    id: root

    property string queryFilters

    function refreshModel() {
        let storedContentY = tableView.contentY;
        let yPositionBefore = tableView.visibleArea.yPosition;
        let heightRatioBefore = tableView.visibleArea.heightRatio;
        queryModel.refresh();
        tableView.contentY = yPositionBefore * tableView.contentHeight;
    }

    color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade600 : Material.Shade400)

    HorizontalHeaderView {
        id: horizontalHeader

        visible: tableView.rows > 0
        anchors.left: tableView.left
        anchors.top: parent.top

        boundsBehavior: Flickable.StopAtBounds
        resizableColumns: false
        clip: true

        delegate: TableDelegate {
            color: Material.background.darker(AppConfig.isDarkTheme ? 1.2 : 0.8)
        }
        model: ListModel {
            ListElement {
                display: qsTr("Track Name")
            }
            ListElement {
                display: qsTr("Radio Station")
            }
            ListElement {
                display: qsTr("Started At")
            }
            ListElement {
                display: qsTr("Ended At")
            }
        }

        syncView: tableView
    }

    TableView {
        id: tableView

        anchors {
            left: parent.left
            top: horizontalHeader.bottom
            right: parent.right
            bottom: parent.bottom

            topMargin: 1
        }

        clip: true

        alternatingRows: true
        columnSpacing: 0
        rowSpacing: 1
        boundsBehavior: Flickable.StopAtBounds

        function largeScreenWidthProvider(column) {
            if (column == 0) {
                return width * 3 / 7;
            }
            return (width - (width * 3 / 7)) / (columns - 1);
        }

        function smallScreenWidthProvider(column) {
            if (column === 0) {
                return 300;
            }
            if (column === 1) {
                return 300;
            }
            return 150;
        }
        columnWidthProvider: (width < AppConfig.portraitLayoutWidth ? smallScreenWidthProvider : largeScreenWidthProvider)

        model: SqlQueryModel {
            id: queryModel

            queryString: `SELECT track_name, json_object('stationName', station_name, 'stationImageUrl', station_image_url) as station, started_at, ended_at
                  FROM track_history
                  ${root.queryFilters}
                  ORDER BY datetime(started_at) DESC`

            onQueryStringChanged: {
                Qt.callLater(root.refreshModel);
            }
        }

        delegate: DelegateChooser {
            DelegateChoice {
                column: 1
                StationDelegate {}
            }

            DelegateChoice {
                column: 2
                DateTableDelegate {}
            }

            DelegateChoice {
                column: 3
                DateTableDelegate {}
            }
            DelegateChoice {
                TableDelegate {}
            }
        }

        ScrollBar.vertical: ScrollBar {}
        ScrollBar.horizontal: ScrollBar {}
    }

    component AlternatingRectangle: Rectangle {
        required property int row
        required property int column

        color: tableView.alternatingRows && row % 2 !== 0 ? Material.background.lighter(AppConfig.isDarkTheme ? 1.4 : 0.9) : Material.background
    }

    component TableDelegate: AlternatingRectangle {
        id: tableDelegate

        required property var display
        property alias label: delegateLabel

        implicitWidth: delegateLabel.fullTextImplicitWidth + 20
        implicitHeight: delegateLabel.fullTextImplicitHeight + 40

        ElidedTextEdit {
            id: delegateLabel

            fontPointSize: 13
            anchors.fill: parent

            fullText: tableDelegate.display

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component DateTableDelegate: TableDelegate {
        readonly property date currentDate: new Date(display)
        readonly property string displayDate: currentDate.toLocaleDateString(Qt.locale(AppSettings.locale), Locale.ShortFormat) + " " + currentDate.toLocaleTimeString(Qt.locale(AppSettings.locale), Locale.ShortFormat)

        label.fullText: displayDate
    }

    component StationDelegate: AlternatingRectangle {
        id: stationDelegateComponent

        required property var display

        readonly property var parsedDisplay: JSON.parse(display)
        readonly property string stationName: parsedDisplay.stationName
        readonly property url stationImageUrl: parsedDisplay?.stationImageUrl ?? ""

        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight

        RowLayout {
            id: rowLayout

            anchors.fill: parent

            Image {
                source: stationDelegateComponent.stationImageUrl

                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(height * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                smooth: true

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: parent.height
                Layout.preferredHeight: parent.height - 10
                Layout.minimumWidth: height
            }

            ElidedTextEdit {
                fullText: stationDelegateComponent.stationName
                fontPointSize: 13

                Layout.preferredWidth: Math.max(fullTextImplicitWidth, 200)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft

                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
