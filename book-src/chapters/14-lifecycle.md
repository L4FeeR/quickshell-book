# Object Lifecycle and Dynamic Creation

So far every object existed from the moment the file loaded. Real shells create things **on demand**: a popup when it opens, one delegate per notification, a settings page when you visit it. This chapter explains when objects are born and die, and the tools for controlling that.

## Lifecycle of an object

1. **Created**: the object is constructed and its properties get default values.
2. **Properties assigned**: your values and bindings are applied, in no guaranteed order.
3. **`Component.onCompleted`** runs once everything in the file is set up.
4. **Lives**: bindings update, signals fire.
5. **`Component.onDestruction`** runs just before it's destroyed.
6. **Destroyed**: its memory is freed and references to it become `null`.

> [!WARN] Don't rely on property order
> Within one object, QML doesn't promise which property is assigned first. Never write code in a property's change handler that assumes another property is already set during creation. Use bindings, or do setup in `Component.onCompleted`.

## Component: a blueprint, not an object

A `Component` is a **description** of an object that can be instantiated later, possibly many times:

```qml
Component {
    id: dotBlueprint
    Rectangle { width: 10; height: 10; radius: 5; color: "#cba6f7" }
}
```

Nothing is created yet. Many types take components: `Loader.sourceComponent`, `Repeater.delegate`, `ListView.delegate`, [[LazyLoader]], [[Variants]]. When you write

```qml
Repeater { model: 5; Rectangle { … } }
```

the `Rectangle { … }` is implicitly wrapped in a Component and stamped out five times.

## Loader: create and destroy on demand

`Loader` creates an object from a component while `active` is true and **destroys it** when false:

```qml
Item {
    property bool showDetails: false

    Loader {
        id: details
        active: parent.showDetails           // false → destroyed, memory freed
        asynchronous: true                   // build without freezing the UI
        sourceComponent: Rectangle {         // inline component
            width: 300; height: 200; color: "#1e1e2e"
        }
        // or: source: "DetailsPanel.qml"
        onLoaded: console.log("created", item)   // item = the created object
    }
}
```

| Loader property | Meaning |
|---|---|
| `active` | Whether the object should exist |
| `sourceComponent` / `source` | What to create (inline component or a file URL) |
| `item` | The created object (`null` while inactive) |
| `status` | `Loader.Null`, `Loading`, `Ready`, `Error` |
| `asynchronous` | Create in the background |
| `progress` | 0–1 while loading asynchronously |

Size: a Loader takes the size of its `item` unless you size the Loader, in which case the item is resized to fit.

Accessing the inner object's properties: `details.item.someProperty`, but guard against `null`: `details.item?.someProperty`.

> [!TIP] Loader vs visible
> `visible: false` keeps the object alive, using memory, with its timers and bindings still running. `Loader { active: false }` removes it entirely. For big, rarely shown UI (settings pages, the overview, the launcher), use a Loader. For small things that toggle often, `visible` is fine.

For whole **windows**, Quickshell has its own [[LazyLoader]], covered in [[ch:34-lazy-loading]].

## Repeater and views create and destroy too

A `Repeater` creates one delegate per model entry and destroys delegates when entries disappear. A `ListView` goes further and only creates delegates that are **visible on screen**. That's why a delegate must never store important state itself: it may be destroyed when it scrolls away. Keep state in the model or in a singleton.

## Creating objects from JavaScript

Rarely needed in shells, but good to know:

```qml
Item {
    id: container
    Component { id: toastComp; Rectangle { property string msg; width: 200; height: 40; color: "#313244"
        Text { anchors.centerIn: parent; text: parent.msg; color: "white" } } }

    function toast(msg) {
        const obj = toastComp.createObject(container, { msg: msg, y: 50 })   // parent + initial props
        destroyLater.createObject(container, { target: obj })
    }
    Component { id: destroyLater; Timer { property var target; interval: 2000; running: true
        onTriggered: { target.destroy(); destroy() } } }
}
```

- `component.createObject(parent, { props })` creates an instance.
- `obj.destroy()` (or `destroy(ms)`) removes it.
- `Qt.createComponent("File.qml")` loads a component from a file.

Prefer Loader, Repeater and models over manual creation: they clean up after themselves.

## Objects and hot reload

When you save, Quickshell **reloads your config**: old objects are destroyed and new ones created. That means:

- Plain property values reset to their defaults on every reload.
- To keep a value across reloads (e.g. "sidebar is open"), use [[PersistentProperties]].
- To keep a value across **restarts**, save it to a file with [[FileView]] + [[JsonAdapter]] ([[ch:38-files-json]]).
- Some Quickshell objects reuse their underlying resources across reloads to avoid flicker. Windows, for example, are reused when possible, and [[NotificationServer]] can keep notifications with `keepOnReload`.

Quickshell signals reload events on the [[Quickshell]] singleton: `reloadCompleted` and `reloadFailed(error)`.

> [!TRY] Exercises
> 1. Make a button that toggles a `Loader` showing a big rectangle. Add `Component.onCompleted` and `Component.onDestruction` logs inside the rectangle and watch them fire.
> 2. Do the same with `visible` instead and notice that no logs fire after the first creation.
> 3. Write a `toast("hi")` function like the one above and call it from a click.
