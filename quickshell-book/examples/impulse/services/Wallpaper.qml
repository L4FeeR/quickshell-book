pragma Singleton
import Quickshell
import QtQuick
import qs.modules.common

// Applying a wallpaper: save it in the config and regenerate colours with matugen.
Singleton {
    function apply(path: string): void {
        Config.options.background.wallpaperPath = path;
        Quickshell.execDetached(["matugen", "image", path]);
    }
}
