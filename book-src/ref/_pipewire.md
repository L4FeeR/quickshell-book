=== Pipewire
@@@ intro
Access to the **PipeWire** audio graph: every node (speakers, microphones, app streams), the links between them, and the default input and output. It updates live; no polling.

@@@ example Example: every property
```qml
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    implicitWidth: 560; implicitHeight: 520
    color: "#1e1e2e"
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    ColumnLayout {
        anchors { fill: parent; margins: 14 }
        Text { color: "white"; text: "ready: " + Pipewire.ready }
        Text { color: "white"; text: "default output: " + (Pipewire.defaultAudioSink?.description ?? "none") }
        Text { color: "white"; text: "default input: " + (Pipewire.defaultAudioSource?.description ?? "none") }
        Text { color: "white"; text: "nodes: " + Pipewire.nodes.values.length + " · links: " + Pipewire.links.values.length
                                   + " · link groups: " + Pipewire.linkGroups.values.length }
        Text { color: "#a6adc8"; text: "Outputs (click to make default):" }
        Repeater {
            model: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
            Text {
                required property PwNode modelData
                color: modelData === Pipewire.defaultAudioSink ? "#cba6f7" : "white"
                text: "  " + (modelData.description || modelData.name)
                TapHandler { onTapped: Pipewire.preferredDefaultAudioSink = modelData }
            }
        }
    }
}
```

@@@ member defaultAudioSink
The output currently in use. To *change* it, set `preferredDefaultAudioSink`; this property then follows.

@@@ member nodes
Every node in the graph, including video and internal ones. Filter: `isSink` (accepts audio), `isStream` (an application, not hardware), `audio !== null` (has audio).

@@@ notes
Remember [[PwObjectTracker]]: a node's `audio` properties are only valid while the node is tracked.

@@@ see
[[ch:41-services-tour]] · [[PwNode]] · [[PwNodeAudio]]

=== PwNode
@@@ intro
One node in the PipeWire graph: a device (speakers, headphones, microphone) or an application stream (Firefox playing sound). Get them from [[Pipewire.nodes]], [[Pipewire.defaultAudioSink]] and friends.

@@@ example Example: every property
```qml
import Quickshell.Services.Pipewire
import QtQuick

Column {
    readonly property PwNode n: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [n] }
    Text { text: "id " + n?.id + " · name " + n?.name }                // name = node.name (machine id)
    Text { text: "description: " + n?.description }                    // human readable
    Text { text: "nickname: " + n?.nickname }
    Text { text: "isSink " + n?.isSink + " · isStream " + n?.isStream + " · ready " + n?.ready }
    Text { text: "type: " + PwNodeType.toString(n?.type) }
    Text { text: "volume: " + Math.round((n?.audio?.volume ?? 0) * 100) + "%  muted " + n?.audio?.muted }
    Text { text: "app: " + (n?.properties["application.name"] ?? "-") }   // any PipeWire property
    Text { text: "media.class: " + (n?.properties["media.class"] ?? "-") }
}
```

@@@ member properties
All PipeWire properties as an object, e.g. `application.name`, `application.icon-name`, `media.name`, `node.nick`. Inspect them with `pw-cli info <id>`.

@@@ member audio
`null` for nodes without audio. Its values are only valid while the node is bound with [[PwObjectTracker]].

=== PwNodeAudio
@@@ intro
The audio part of a [[PwNode]] (`node.audio`): volume and mute, overall and per channel.

@@@ example Example: every property
```qml
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls

Column {
    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [sink] }

    Slider { from: 0; to: 1.5; value: sink?.audio?.volume ?? 0; onMoved: sink.audio.volume = value }   // average of all channels
    CheckBox { text: "muted"; checked: sink?.audio?.muted ?? false; onToggled: sink.audio.muted = checked }
    Repeater {                                                                // per-channel volumes
        model: sink?.audio?.channels ?? []
        Row {
            required property int index
            required property var modelData                                   // PwAudioChannel value
            Text { text: PwAudioChannel.toString(modelData) }
            Slider {
                from: 0; to: 1
                value: sink.audio.volumes[index]
                onMoved: { const v = [...sink.audio.volumes]; v[index] = value; sink.audio.volumes = v }  // assign a new list
            }
        }
    }
}
```

@@@ member volume
Can be set above 1.0 (amplification). Clamp it in your UI, e.g. to 1.5.

=== PwObjectTracker
@@@ intro
**Binds** PipeWire objects so their detailed properties (a node's `audio`, a link's `state`) become valid and live. Without it, `node.audio.volume` reads 0 and writes do nothing. Put every node you read or control into `objects`.

@@@ example Example
```qml
import Quickshell.Services.Pipewire
import QtQuick

Item {
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio)
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource, ...streams] }   // nulls are fine
}
```

@@@ notes
Tracking is cheap. A tracker anywhere in your shell (e.g. in your Audio service) is enough for all users of those nodes.

=== PwLink
@@@ intro
A single connection between two nodes (one channel). `source` sends audio, `target` receives. From [[Pipewire.links]]. Usually [[PwLinkGroup]] is more useful.

@@@ example Example
```qml
Repeater {
    model: Pipewire.links
    Text {
        required property PwLink modelData
        text: `${modelData.id}: ${modelData.source?.name} → ${modelData.target?.name} (${PwLinkState.toString(modelData.state)})`
    }
}
```

=== PwLinkGroup
@@@ intro
All channels between two nodes, merged into one connection. From [[Pipewire.linkGroups]] or [[PwNodeLinkTracker.linkGroups]]. Use it to answer questions like "which apps are playing into my headphones?" or "is any app recording from my microphone?".

@@@ example Example: microphone-in-use indicator
```qml
import Quickshell.Services.Pipewire
import QtQuick

Text {
    readonly property var recorders: Pipewire.linkGroups.values
        .filter(g => g.source === Pipewire.defaultAudioSource && g.target?.isStream)
        .map(g => g.target.properties["application.name"] ?? g.target.name)
    visible: recorders.length > 0
    text: "🎙 " + recorders.join(", ")
    color: "#f38ba8"
}
```

=== PwNodeLinkTracker
@@@ intro
Tracks the link groups connected to **one node**, excluding monitor links. For a sink, that's the streams playing into it; for a source, the streams recording from it.

@@@ example Example: apps playing on the default output
```qml
import Quickshell.Services.Pipewire
import QtQuick

Column {
    PwNodeLinkTracker { id: tracker; node: Pipewire.defaultAudioSink }
    Repeater {
        model: tracker.linkGroups
        Text {
            required property PwLinkGroup modelData
            text: modelData.source?.properties["application.name"] ?? modelData.source?.name ?? "?"
        }
    }
}
```

=== PwNodePeakMonitor
@@@ intro
Measures the live **peak level** of an audio node, per channel, from 0.0 to 1.0. That's a VU meter with no external program (unlike cava).

@@@ example Example: every property
```qml
import Quickshell.Services.Pipewire
import QtQuick

Row {
    spacing: 3
    PwNodePeakMonitor {
        id: peak
        node: Pipewire.defaultAudioSink      // must be an audio node
        enabled: parent.visible              // stop capturing when hidden
    }
    Repeater {
        model: peak.peaks                    // one value per channel (volume doesn't affect it)
        Rectangle {
            required property real modelData
            required property int index
            width: 8; height: 60 * modelData; anchors.bottom: parent.bottom
            color: "#a6e3a1"
            Text { anchors.top: parent.bottom; text: PwAudioChannel.toString(peak.channels[index]); font.pixelSize: 8 }
        }
    }
    Text { text: "max " + peak.peak.toFixed(2) }
}
```
