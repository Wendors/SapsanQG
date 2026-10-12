import QtQuick

import QGroundControl
import QGroundControl.Controls

// Second, independent video stream. Shown as a pip/full/window item next to the map and the first stream.
Item {
    id: _root

    property Item pipView
    property Item pipState: video2PipState

    PipState {
        id:         video2PipState
        pipView:    _root.pipView
        isDark:     true

        onWindowAboutToOpen: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onWindowAboutToClose: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }
    }

    Timer {
        id:           videoStartDelay
        interval:     2000
        running:      false
        repeat:       false
        onTriggered:  QGroundControl.videoManager.startVideo()
    }

    FlightDisplayViewVideo {
        anchors.fill:   parent
        secondary:      true
        useSmallFont:   _root.pipState.state !== _root.pipState.fullState
    }

    MouseArea {
        anchors.fill:   parent
        enabled:        _root.pipState.state === _root.pipState.fullState
        onDoubleClicked: QGroundControl.videoManager.fullScreen = !QGroundControl.videoManager.fullScreen
    }
}
