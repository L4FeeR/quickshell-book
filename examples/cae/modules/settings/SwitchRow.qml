import QtQuick
import qs.modules.settings

// A true/false setting.
SettingRow {
    id: root

    M3Switch {
        checked: root.value === true
        onToggled: {
            root.edited(checked);
            checked = Qt.binding(() => root.value === true);   // keep following the real value
        }
    }
}
