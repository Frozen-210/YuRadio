import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import Main

FocusScope {
    id: root

    implicitHeight: 70

    required property real minimumHeight
    required property real maximumHeight

    required property DragHandler bottomBarDragHandler
    required property RadioPlayer player

    property alias playerButton: playerButton

    property string stationName
    property string stationTags
    property string stationIcon
    property string stationUrl
    property string stationHomepage
    property string stationCountry
    property string stationLanguage

    Binding {
        when: mainFlickable.dragging
        root.bottomBarDragHandler.enabled: false
    }

    states: [
        State {
            name: "dragStarted"
            when: root.height > root.minimumHeight + (root.maximumHeight - root.minimumHeight) / 5

            PropertyChanges {
                stationInfoColumn.visible: true
                //stationUrlText.visible: true
                playerButton.visible: false
                secondaryColumnLayout.visible: true
                bottomBarRowLayout.spacing: 20

                mainFlickable.anchors.leftMargin: 10
                mainFlickable.anchors.rightMargin: 10
                mainFlickable.anchors.topMargin: 10

                bottomBarTextColumn.anchors.rightMargin: 10

                stationName.wrapMode: Text.WordWrap
                musicTags.wrapMode: Text.WordWrap
            }
        }
    ]

    Flickable {
        id: mainFlickable

        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        contentWidth: width

        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn
            width: parent.width

            RowLayout {
                id: bottomBarRowLayout
                Layout.fillWidth: true

                Image {
                    id: imagePlayer

                    smooth: true
                    source: root.stationIcon ? root.stationIcon : "images/radio.png"

                    Layout.maximumHeight: Math.min(root.width / 3, root.height - 8)
                    Layout.maximumWidth: Layout.maximumHeight

                    Layout.leftMargin: 10
                    Layout.fillHeight: true
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: bottomBarTextColumn.implicitHeight

                    Column {
                        id: bottomBarTextColumn

                        width: parent.width

                        Label {
                            id: stationName
                            text: root.stationName ? root.stationName : "Station"

                            width: parent.width
                            elide: Text.ElideRight
                            font.bold: true
                            font.pointSize: 16
                        }

                        Label {
                            id: musicTags
                            text: root.stationTags ? root.stationTags : '⸻'
                            maximumLineCount: 3

                            width: parent.width
                            elide: Text.ElideRight
                            font.pointSize: 13
                        }

                        ColumnLayout {
                            id: stationInfoColumn
                            visible: false

                            width: parent.width

                            spacing: 2

                            Label {
                                id: country
                                Layout.topMargin: 20
                                Layout.fillWidth: true

                                visible: root.stationCountry

                                text: qsTr(`Country: ${root.stationCountry}`)
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                id: language

                                Layout.fillWidth: true

                                visible: root.stationLanguage

                                text: qsTr(`Language: ${root.stationLanguage}`)
                                font.pointSize: 14
                                wrapMode: Text.Wrap
                            }

                            ClickableLink {
                                id: homePage

                                Layout.fillWidth: true

                                visible: root.stationHomepage

                                linkText: qsTr('Homepage')
                                link: root.stationHomepage

                                font.pointSize: 14
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }

                IconButton {
                    id: playerButton

                    Layout.rightMargin: 10
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: Layout.preferredWidth

                    icon.source: root.player.playing ? "images/pause.svg" : "images/play.svg"
                    icon.sourceSize: Qt.size(height, height)
                    icon.color: Material.color(Material.Grey, Material.Shade800)

                    smooth: true

                    onClicked: {
                        if (root.player.playing) {
                            root.player.pause();
                        } else {
                            root.player.playRadio();
                        }
                    }
                }
            }

            ColumnLayout {
                id: secondaryColumnLayout
                visible: false

                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.topMargin: 10
                Layout.leftMargin: 10

                Text {
                    visible: musicInfoProvider.state == ItunesMusicInfoProvider.Failed || !root.player.icyMetaData["StreamTitle"]
                    text: "Music Info not avaialble"
                    opacity: 0.5
                    font.pointSize: 16
                    Layout.topMargin: 15
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                BusyIndicator {
                    visible: musicInfoProvider.state == ItunesMusicInfoProvider.Processing
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                RowLayout {
                    visible: musicInfoProvider.state == ItunesMusicInfoProvider.Done && musicInfoProvider.musicInfo && root.player.icyMetaData["StreamTitle"]
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Image {
                        source: musicInfoProvider.musicInfo ? musicInfoProvider.musicInfo.album.albumImageUrl : ''

                        Layout.minimumWidth: mainColumn.width * 4 / 9
                        Layout.minimumHeight: Layout.minimumWidth

                        Layout.maximumWidth: Layout.minimumWidth
                        Layout.maximumHeight: Layout.minimumHeight

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Label {
                            text: qsTr(`<b>Album</b>: ${musicInfoProvider.musicInfo ? musicInfoProvider.musicInfo.album.albumName : ''}`)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                        }
                        Label {
                            text: qsTr(`<b>Song</b>: ${musicInfoProvider.musicInfo ? musicInfoProvider.musicInfo.songName : ''}`)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                        }
                        Label {
                            text: qsTr(`<b>Artist</b>: ${musicInfoProvider.musicInfo ? musicInfoProvider.musicInfo.album.artists[0].artistName : ''}`)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                        }
                    }
                }
            }
        }
    }

    ItunesMusicInfoProvider {
        id: musicInfoProvider
    }

    Timer {
        id: icyMetaDataUpdateTimer
        interval: 500
        repeat: false

        onTriggered: {
            if (root.player.icyMetaData["StreamTitle"]) {
                musicInfoProvider.provide(root.player.icyMetaData["StreamTitle"]);
            }
        }
    }

    Connections {
        target: root.player

        function onIcyMetaDataChanged() {
            icyMetaDataUpdateTimer.start();
        }
    }
}
