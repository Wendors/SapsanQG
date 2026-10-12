import QtQuick
import QtQuick.Window

import QGroundControl
import QGroundControl.Controls

Item {
    id:         _root
    width:      _pipSize
    height:     _slotHeight * Math.max(1, _pipItems.length)
    visible:    show && _pipItems.length > 0

    property var    item1:                  null    // Required
    property var    item2:                  null    // Optional, may come and go
    property var    item3:                  null    // Optional, may come and go
    property string item1IsFullSettingsKey          // Settings key to save whether item1 was saved in full mode
    property string item3IsFullSettingsKey: "MainFlyWindowIsVideo2"    // Settings key to save whether item3 was saved in full mode
    property bool   show:                   true

    // Area covering the parent, in PipView coordinates: just the restore button while collapsed
    readonly property rect occupiedRect: _isExpanded ? Qt.rect(0, 0, width, height) : Qt.rect(showPip.x, showPip.y, showPip.width, showPip.height)

    readonly property string _pipExpandedSettingsKey: "IsPIPVisible"

    property var    _fullItem
    property var    _pipItems:          _computeItems(true)     // Items currently shown in a pip slot, slot 0 is the bottom one
    property var    _windowItem:        _computeItems(false)[0] // Item currently shown in the pop-out window
    property alias  _windowContentItem: window.contentItem
    property alias  _pipContentItem:    pipContent0
    property bool   _isExpanded:        true
    property bool   _hovered:           false
    property real   _pipSize:           parent.width * 0.2
    property real   _slotHeight:        _pipSize * (9/16)
    property real   _maxSize:           0.75                // Percentage of parent control size
    property real   _minSize:           0.10
    property bool   _componentComplete: false

    Component.onCompleted: {
        _initForItems()
        _componentComplete = true
    }

    // item1 can swap at runtime (fly view map engine Loader), not just item2/item3
    onItem1Changed: _initForItems()
    onItem2Changed: _initForItems()
    onItem3Changed: _initForItems()

    function showWindow() {
        window.width = _root.width
        window.height = _slotHeight
        window.show()
    }

    function _itemAt(index) {
        return index === 0 ? item1 : (index === 1 ? item2 : item3)
    }

    function _containerAt(index) {
        return index === 0 ? pipContent0 : (index === 1 ? pipContent1 : pipContent2)
    }

    function _computeItems(forPip) {
        var result = []
        var wantedState = forPip ? "pip" : "window"
        for (var i = 0; i < 3; i++) {
            var item = _itemAt(i)
            if (item && item.pipState.state === wantedState) {
                result.push(item)
            }
        }
        return result
    }

    function _slotIndexOf(item) {
        return item ? _pipItems.indexOf(item) : -1
    }

    function _updateHovered() {
        var hovered = false
        for (var i = 0; i < slotRepeater.count; i++) {
            var slot = slotRepeater.itemAt(i)
            if (slot && slot.mouseArea.containsMouse) {
                hovered = true
            }
        }
        _hovered = hovered
    }

    function _initForItems() {
        if (!item1) {
            // Engine swap in flight: wait for the new item1
            _fullItem = null
            return
        }

        for (var i = 0; i < 3; i++) {
            var item = _itemAt(i)
            if (item) {
                item.pipState.pipContentItem = _containerAt(i)
            }
        }

        var fullItem = item1
        if (!QGroundControl.loadBoolGlobalSetting(item1IsFullSettingsKey, true)) {
            if (item3 && QGroundControl.loadBoolGlobalSetting(item3IsFullSettingsKey, false)) {
                fullItem = item3
            } else if (item2) {
                fullItem = item2
            }
        }
        _setFullItem(fullItem)
        _setPipIsExpanded(QGroundControl.loadBoolGlobalSetting(_pipExpandedSettingsKey, true))
    }

    function _setFullItem(fullItem) {
        _fullItem = fullItem
        for (var i = 0; i < 3; i++) {
            var item = _itemAt(i)
            if (!item) {
                continue
            }
            if (item === fullItem) {
                item.pipState.state = item.pipState.fullState
            } else if (item.pipState.state !== item.pipState.windowState) {
                item.pipState.state = item.pipState.pipState
            }
        }
    }

    function _swapPip(pipItem) {
        if (!item1 || !pipItem || !_fullItem || pipItem === _fullItem || pipItem.pipState.state !== pipItem.pipState.pipState) {
            // Engine swap in flight (see _initForItems)
            return
        }
        var oldFullItem = _fullItem
        _fullItem = pipItem
        oldFullItem.pipState.state = oldFullItem.pipState.pipState
        pipItem.pipState.state = pipItem.pipState.fullState
        QGroundControl.saveBoolGlobalSetting(item1IsFullSettingsKey, pipItem === item1)
        QGroundControl.saveBoolGlobalSetting(item3IsFullSettingsKey, pipItem === item3)
    }

    function _setPipIsExpanded(isExpanded) {
        QGroundControl.saveBoolGlobalSetting(_pipExpandedSettingsKey, isExpanded)
        _isExpanded = isExpanded
    }

    Window {
        id:         window
        visible:    false
        onClosing: {
            var item = contentItem.children[0]
            if (item) {
                item.pipState.windowAboutToClose()
                item.pipState.state = item.pipState.pipState
            }
        }
    }

    Item {
        id:         pipContent0
        width:      _root.width
        height:     _slotHeight
        y:          _root.height - (_slotIndexOf(item1) + 1) * _slotHeight
        visible:    _isExpanded && _slotIndexOf(item1) >= 0
        clip:       true
    }

    Item {
        id:         pipContent1
        width:      _root.width
        height:     _slotHeight
        y:          _root.height - (_slotIndexOf(item2) + 1) * _slotHeight
        visible:    _isExpanded && _slotIndexOf(item2) >= 0
        clip:       true
    }

    Item {
        id:         pipContent2
        width:      _root.width
        height:     _slotHeight
        y:          _root.height - (_slotIndexOf(item3) + 1) * _slotHeight
        visible:    _isExpanded && _slotIndexOf(item3) >= 0
        clip:       true
    }

    Repeater {
        id:     slotRepeater
        model:  3

        delegate: Item {
            id:         slot
            width:      _root.width
            height:     _slotHeight
            y:          _root.height - (_slotIndex + 1) * _slotHeight
            visible:    _isExpanded && _slotIndex >= 0

            property var   _slotItem:   _root._itemAt(index)
            property int   _slotIndex:  _root._slotIndexOf(_slotItem)
            property alias mouseArea:   pipMouseArea

            MouseArea {
                id:                 pipMouseArea
                anchors.fill:       parent
                enabled:            slot.visible
                preventStealing:    true
                hoverEnabled:       true
                onClicked:          _root._swapPip(slot._slotItem)
                onContainsMouseChanged: _root._updateHovered()
            }

            // Pip to Window
            Image {
                source:         "/qmlimages/PiP.svg"
                mipmap:         true
                fillMode:       Image.PreserveAspectFit
                anchors.left:   parent.left
                anchors.top:    parent.top
                visible:        !ScreenTools.isMobile && pipMouseArea.containsMouse && !_root._windowItem
                height:         ScreenTools.defaultFontPixelHeight * 2.5
                width:          ScreenTools.defaultFontPixelHeight * 2.5
                sourceSize.height:  height

                MouseArea {
                    anchors.fill:   parent
                    onClicked: {
                        if (slot._slotItem) {
                            slot._slotItem.pipState.state = slot._slotItem.pipState.windowState
                        }
                    }
                }
            }
        }
    }

    // MouseArea to drag in order to resize the PiP area
    MouseArea {
        id:                 pipResize
        anchors.fill:       pipResizeIcon
        preventStealing:    true
        cursorShape:        Qt.PointingHandCursor

        property real initialX:     0
        property real initialWidth: 0

        onPressed: (mouse) => {
            // Remove the anchor so the our mouse coordinates stay in the same original place for drag tracking
            pipResize.anchors.fill = undefined
            pipResize.initialX = mouse.x
            pipResize.initialWidth = _root.width
        }

        onReleased: pipResize.anchors.fill = pipResizeIcon

        // Drag
        onPositionChanged: (mouse) => {
            if (pipResize.pressed) {
                var parentWidth = _root.parent.width
                var newWidth = pipResize.initialWidth + mouse.x - pipResize.initialX
                if (newWidth < parentWidth * _maxSize && newWidth > parentWidth * _minSize) {
                    _pipSize = newWidth
                }
            }
        }
    }

    // Resize icon
    Image {
        id:             pipResizeIcon
        source:         "/qmlimages/pipResize.svg"
        fillMode:       Image.PreserveAspectFit
        mipmap:         true
        anchors.right:  parent.right
        anchors.top:    parent.top
        visible:        _isExpanded && (ScreenTools.isMobile || _hovered)
        height:         ScreenTools.defaultFontPixelHeight * 2.5
        width:          ScreenTools.defaultFontPixelHeight * 2.5
        sourceSize.height:  height
    }

    // Check min/max constraints on pip size when when parent is resized
    Connections {
        target: _root.parent

        function onWidthChanged() {
            if (!_componentComplete) {
                // Wait until first time setup is done
                return
            }
            var parentWidth = _root.parent.width
            if (_root.width > parentWidth * _maxSize) {
                _pipSize = parentWidth * _maxSize
            } else if (_root.width < parentWidth * _minSize) {
                _pipSize = parentWidth * _minSize
            }
        }
    }

    Image {
        id:             hidePIP
        source:         "/qmlimages/pipHide.svg"
        mipmap:         true
        fillMode:       Image.PreserveAspectFit
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        visible:        _isExpanded && (ScreenTools.isMobile || _hovered)
        height:         ScreenTools.defaultFontPixelHeight * 2.5
        width:          ScreenTools.defaultFontPixelHeight * 2.5
        sourceSize.height:  height
        MouseArea {
            anchors.fill:   parent
            onClicked:      _root._setPipIsExpanded(false)
        }
    }

    Rectangle {
        id:                     showPip
        anchors.left :          parent.left
        anchors.bottom:         parent.bottom
        height:                 ScreenTools.defaultFontPixelHeight * 2
        width:                  ScreenTools.defaultFontPixelHeight * 2
        radius:                 ScreenTools.defaultFontPixelHeight / 3
        visible:                !_isExpanded
        color:                  (_fullItem && !_fullItem.pipState.isDark) ? Qt.rgba(0,0,0,0.5) : Qt.rgba(0,0,0,0.75)
        Image {
            width:              parent.width  * 0.75
            height:             parent.height * 0.75
            sourceSize.height:  height
            source:             "/res/buttonRight.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.verticalCenter:     parent.verticalCenter
            anchors.horizontalCenter:   parent.horizontalCenter
        }
        MouseArea {
            anchors.fill:   parent
            onClicked:      _root._setPipIsExpanded(true)
        }
    }
}
