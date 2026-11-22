import QtQuick

// A layer that spawns ripples anywhere on it. Put it over (or under) any
// content and call burst():
//   RippleLayer { id: ripples; anchors.fill: parent }
//   ripples.burst(x, y)                                   // a default ripple
//   ripples.burst(x, y, { tint: "red", ring: true, endSize: 400, duration: 900 })
// Each ripple is created on demand and removes itself, so the layer costs
// nothing while idle.
Item {
    id: root

    property color tint: "white"
    property real endSize: 200
    property int duration: 600
    property real startOpacity: 0.35
    property int maxRipples: 24           // keep fast typing from piling up hundreds

    Component { id: rippleComponent; Ripple {} }

    function burst(x, y, options) {
        if (root.children.length >= root.maxRipples)
            root.children[0].destroy();   // drop the oldest
        const o = options ?? {};
        rippleComponent.createObject(root, {
            centerX: x,
            centerY: y,
            tint: o.tint ?? root.tint,
            endSize: o.endSize ?? root.endSize,
            duration: o.duration ?? root.duration,
            startOpacity: o.startOpacity ?? root.startOpacity,
            ring: o.ring ?? false
        });
    }

    // a ripple from the middle, big enough to cover the whole layer
    function flood(options) {
        const o = Object.assign({ endSize: Math.hypot(width, height) * 2 }, options ?? {});
        burst(width / 2, height / 2, o);
    }
}
