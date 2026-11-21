## How to read a reference page

Every type page has the same sections:

| Section | What it tells you |
|---|---|
| **Badges** | `creatable` (you write `Type { }`), `singleton` (use by name, never create), `provided by Quickshell` (you receive instances from another property), `enum` (named values only) |
| **Import** | the `import` line you need |
| **Inherits** | parent types; inherited properties are listed in collapsible sections |
| **How to get one** | exactly how to obtain an instance, with links to the properties that provide it |
| **Overview / Examples** | plain-language explanation and complete, runnable examples |
| **Properties** | every property with its type, whether you can write it, and what it means |
| **Functions** | every callable method with parameter types |
| **Signals** | every event, with the handler name to use (`onSomething`) |
| **Enum values** | every value, written as you type it in QML |
| **Where this type appears** | every property, function or signal elsewhere in the API that uses this type |

**Access badges:** <span class="acc rw">read / write</span> you can assign it; <span class="acc ro">read-only</span> you can only read and bind to it; <span class="acc const">constant</span> never changes; <span class="acc req">required</span> must be set when you create the object.

Every property also has a change signal: property `volume` → signal `volumeChanged` → handler `onVolumeChanged`.
