# Getting Started

This page gets you from an empty chip to a running program, and explains the
handful of concepts you need before reading the [Language Reference](language.md).

- [Prerequisites](#prerequisites)
- [Spawning a chip](#spawning-a-chip)
- [The Golem editor](#the-golem-editor)
- [Your first script](#your-first-script)
- [Uploading and running](#uploading-and-running)
- [Directives](#directives)
- [Server, client and shared](#server-client-and-shared)
- [Includes](#includes)
- [Where to go next](#where-to-go-next)

---

## Prerequisites

E3 is a **Wiremod** addon for **Garry's Mod**. Make sure both Wiremod and
Expression 3 are installed (see the [project README](../README.md) for
installation). You need the ability to spawn tools — most sandbox and build
servers allow this by default.

## Spawning a chip

1. Open the **Tool** menu and select **Expression 3 Tool (Wire)** from the
   **Chips, Gates** category.
2. **Left‑click** in the world to place an Expression 3 chip.
3. **Right‑click** to open the chip in the **Golem** editor.

## The Golem editor

Golem is E3's in‑game IDE. The parts you will use most:

- The **code area**, with syntax highlighting and auto‑complete.
- The **helper browser**, a searchable reference of every type, library,
  function, method, operator, attribute and event.
- The **examples** list — fully commented, runnable scripts you can open and
  learn from.
- An in‑editor **console** where prints, errors and compile messages appear.

## Your first script

Every script can begin with **directives** — lines starting with `@` that
describe the chip. Then comes your code. Here is a complete first program:

```cpp
// The @name directive sets the chip's display name.
@name "My First E3";

// This line runs once, when the chip starts.
system.print("Hello from Expression 3!");

// The Think event runs every tick. We use a counter and a timer
// to print a message once per second for five seconds.
int seconds = 0;

timer.create("tick", 1, 5, function() {
    seconds++;
    system.print("Running for ", seconds, " seconds.");
});
```

A few things to notice:

- Statements end with a semicolon `;`.
- Comments are `//` for a single line, or `/* ... */` for a block.
- Variables are declared **type first**: `int seconds = 0;`.
- Libraries group related functions: `system.print(...)`, `timer.create(...)`.
- Functions are **first‑class** — you can pass one straight into `timer.create`.

## Uploading and running

Press the editor's **upload** control to compile and send your code to the
chip. Because E3 is strongly typed, most mistakes are caught **at compile time**
and reported (with the exact line and column) before the code ever runs. Fix the
error and upload again.

Once running, prints go to the gate owner's chat (`system.print`) or the Golem
console (`system.out`). Runtime errors are also reported to the owner and the
console, and the gate shuts down so a broken script can't lag the server.

## Directives

Directives configure the chip and its wire ports. They are written at the top
of the script (though `@input`/`@output` may appear anywhere) and are **not**
executable statements.

| Directive | Example | Purpose |
|-----------|---------|---------|
| `@name` | `@name "Reactor";` | Sets the chip's display name. |
| `@model` | `@model "models/...";` | Sets the chip's model. |
| `@input` | `@input number Throttle;` | Declares a wire **input** port. |
| `@output` | `@output vector Aim;` | Declares a wire **output** port. |
| `@synced` | `@synced number State;` | Declares a variable kept in sync between server and client. |
| `@server` | `@server;` | Runs the whole script on the **server** only. |
| `@client` | `@client;` | Runs the whole script on the **client** only. |
| `@include` | `@include "lib.txt";` | Includes code from another file. |

Wire port **names must be CamelCase** (their first letter capitalised). This is
how E3 tells ports apart from ordinary variables. Read and write them like
normal variables:

```cpp
@input number A;
@input number B;
@output number Sum;

// The Trigger event fires when a wired input changes.
event.add("Trigger", "add", function(string port) {
    Sum = A + B;
});
```

Valid port types are `number`, `string`, `boolean`, `vector`, `vector2`,
`angle`, `entity`, `player`, `table`, `function`, `wirelink` and the E2 table
type.

## Server, client and shared

E3 runs on **both** the server and every client. By default a script is
**shared**, meaning it runs in both realms. You control this in two ways:

- **Whole script:** `@server;` or `@client;` at the top.
- **Blocks:** `server { ... }` and `client { ... }` for realm‑specific sections
  inside an otherwise shared script.

```cpp
@name "Realms";

server {
    // Only the server runs this.
}

client {
    // Only clients run this — required for rendering to the screen/HUD.
}
```

Why it matters:

- **Rendering** (the `render` library, `RenderHUD` / `RenderScreen` events) is
  client‑side only.
- **Networking** needs both realms: one side sends, the other receives (see the
  `net` library in the [Standard Library](standard-library.md)).
- Some world interactions (spawning props, firing rangers) are typically done
  on the server.

## Includes

Large projects can be split across files and pulled together with `@include`:

```cpp
@include "helpers.txt";
```

Included code is compiled as part of your script, so functions and classes
defined in an include are available to the main file.

## Where to go next

- Learn the language in the **[Language Reference](language.md)**.
- Explore what's available in the **[Standard Library & Types](standard-library.md)**.
- Open the **examples** in the Golem editor and read them end to end.
