//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.widgets

// The theme switcher kit from "The Quickshell Book". Run with:  qs -c theming
ShellRoot {
    DemoBar {}
    ThemePicker {}

    // start the exporter at login (singletons are created when first used)
    Component.onCompleted: ThemeExport.kitty

    GlobalShortcut { appid: "theming"; name: "picker"; onPressed: Ui.pickerOpen = !Ui.pickerOpen }
    GlobalShortcut { appid: "theming"; name: "next"; onPressed: Theme.step(1) }
    GlobalShortcut { appid: "theming"; name: "toggleVariant"; onPressed: Theme.toggleVariant() }
}
