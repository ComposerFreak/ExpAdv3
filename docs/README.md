# Expression 3 — Documentation

Welcome to the **Expression 3 (E3)** documentation. These pages are the
language user guide: they teach you how to write E3 code, what the language can
do, and how to use its standard library.

> New here? If you just want to know **what E3 is**, how to **install** it, or
> how to run it as a **server owner** (convars, performance, permissions), read
> the [project README](../README.md) first. This folder is about *writing* E3.

## The guides

| Guide | What it covers |
|-------|----------------|
| **[Getting Started](getting-started.md)** | Spawning a chip, the Golem editor, your first script, uploading, directives, and server/client realms. |
| **[Language Reference](language.md)** | The complete language: comments, literals, types, variables, operators, control flow, functions, error handling and object‑oriented programming. |
| **[Standard Library & Types](standard-library.md)** | The built‑in types, a tour of every library (math, render, net, ranger, holograms…), events, wiring, networking and permissions — plus how to read the in‑editor reference. |

## How to read these docs

E3 is a **strongly‑typed** language that compiles to native Lua and runs on a
Wiremod chip. If you have used Wiremod's Expression 2 before, a lot will feel
familiar, but E3 is stricter about types and adds real functions, classes and
error handling.

The fastest way to learn is to read [Getting Started](getting-started.md), skim
the [Language Reference](language.md), then keep the
[Standard Library](standard-library.md) page open while you write.

## The in‑editor reference is the source of truth

These guides teach the language and explain *how* each part of the standard
library works. They deliberately **do not** list every single function, method
and attribute — that reference is built into the **Golem** editor and always
matches the extensions you actually have installed.

Open the editor's **helper browser** to search every type, library, function,
method, operator, attribute and event, each with a description and often an
example. The [Standard Library](standard-library.md) page explains how to use
it.

## A taste of E3

```cpp
@name "Hello World";

// Runs once when the chip starts.
player owner = system.getOwner();
system.print("Hello, ", owner.name(), "!");

// Runs every tick.
event.add("Think", "counter", function() {
    // ... your logic here
});
```

Ready? Start with **[Getting Started](getting-started.md)**.
