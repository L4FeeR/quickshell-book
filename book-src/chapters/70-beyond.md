# Beyond QML: Plugins and Helpers

QML and JavaScript cover almost everything. When they don't (heavy number crunching, a library only available in C++ or Python, a protocol Quickshell doesn't speak), you have three escape hatches, from easiest to most powerful.

## 1. Helper programs over stdout (easiest)

Write a small program in any language that prints **one JSON object per line**. Run it with [[Process]] + [[SplitParser]].

```python file="scripts/sysinfo.py"
#!/usr/bin/env python3
import json, time, psutil

while True:
    print(json.dumps({
        "cpu": psutil.cpu_percent() / 100,
        "ram": psutil.virtual_memory().percent / 100,
        "net_rx": psutil.net_io_counters().bytes_recv,
    }), flush=True)                     # flush! otherwise output is buffered
    time.sleep(2)
```

```qml
Process {
    command: ["python3", Quickshell.shellPath("scripts/sysinfo.py")]
    running: true
    stdout: SplitParser {
        onRead: line => {
            try { const d = JSON.parse(line); root.cpu = d.cpu; root.ram = d.ram } catch (e) {}
        }
    }
}
```

Pros: any language, crash-isolated, easy to test in a terminal. Cons: an extra process; data only flows one way unless you use stdin (`stdinEnabled` + `write()`).

> [!TIP] Always flush
> Most languages buffer stdout when it isn't a terminal. Use `flush=True` (Python), `fflush(stdout)` (C), `std::io::stdout().flush()` (Rust), or `stdbuf -oL` in front of the command.

## 2. Sockets and D-Bus

- A long-running helper can expose a Unix socket; connect with [[Socket]] for two-way communication.
- Many services already speak D-Bus. Without a Quickshell module, use `busctl`/`gdbus` through Process:

```bash
gdbus monitor --system --dest org.freedesktop.login1        # watch logind events (lid, sleep)
busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications GetServerInformation
```

```qml
Process {
    command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
    running: true
    stdout: SplitParser { onRead: l => { if (l.includes("PrepareForSleep") && l.includes("true")) GlobalStates.locked = true } }
}
```

That snippet locks your screen right before suspend, without hypridle.

## 3. C++ QML plugins (most powerful)

A QML module written in C++ can expose new types with the same performance as Quickshell's own. Caelestia uses one for its audio visualizer and beat detection.

### Minimal plugin

```text
myplugin/
├── CMakeLists.txt
├── counter.hpp
└── counter.cpp
```

```cmake file="myplugin/CMakeLists.txt"
cmake_minimum_required(VERSION 3.20)
project(myplugin LANGUAGES CXX)
find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.6)

qt_add_qml_module(myplugin
    URI MyPlugin
    VERSION 1.0
    SHARED
    SOURCES counter.hpp counter.cpp
)
target_link_libraries(myplugin PRIVATE Qt6::Quick)
```

```cpp file="myplugin/counter.hpp"
#pragma once
#include <QObject>
#include <QTimer>
#include <qqmlintegration.h>

class Counter : public QObject {
    Q_OBJECT
    QML_ELEMENT                                       // usable as `Counter {}` in QML
    Q_PROPERTY(int value READ value NOTIFY valueChanged)
public:
    explicit Counter(QObject* parent = nullptr);
    int value() const { return m_value; }
    Q_INVOKABLE void reset();
signals:
    void valueChanged();
private:
    int m_value = 0;
    QTimer m_timer;
};
```

```cpp file="myplugin/counter.cpp"
#include "counter.hpp"

Counter::Counter(QObject* parent) : QObject(parent) {
    connect(&m_timer, &QTimer::timeout, this, [this] { m_value++; emit valueChanged(); });
    m_timer.start(1000);
}
void Counter::reset() { m_value = 0; emit valueChanged(); }
```

```bash
cmake -B build -G Ninja && cmake --build build
# install to a QML import path, e.g. user-local:
mkdir -p ~/.local/lib/qt6/qml && cp -r build/MyPlugin ~/.local/lib/qt6/qml/
```

Make Quickshell find it:

```qml file="shell.qml"
//@ pragma Env QML_IMPORT_PATH=/home/you/.local/lib/qt6/qml
import MyPlugin

ShellRoot { Counter { onValueChanged: console.log(value) } }
```

> [!WARN] Qt version must match
> A C++ plugin must be compiled against the **same Qt version** Quickshell uses. After a Qt update you must rebuild it, or Quickshell fails to load the module.

## 4. Contributing to Quickshell

If what you built is generally useful (a protocol, a service), consider contributing upstream. The source uses the same `Q_PROPERTY` + doc-comment style shown above; the API reference in this book is generated from those comments.

> [!TRY] Exercises
> 1. Write a helper in any language that prints the number of unread emails as JSON lines, and show it in your bar.
> 2. Lock the screen before suspend using the `gdbus monitor` snippet.
> 3. Build the minimal C++ plugin and use `Counter` in a test config.
