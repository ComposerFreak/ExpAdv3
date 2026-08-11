# Standard Library & Types

This page covers the built‑in **types** you work with and the **libraries** that
make up E3's standard library, plus the cross‑cutting systems: **events**,
**wiring**, **networking** and **permissions**.

It is a conceptual map, not an exhaustive symbol list. The complete,
always‑accurate reference — every function, method, attribute and its exact
signature — lives in the Golem editor's **helper browser** (see
[Using the in‑editor reference](#using-the-in-editor-reference)).

- [Types](#types)
- [Working with objects](#working-with-objects)
- [The libraries](#the-libraries)
- [Events](#events)
- [Wiring (inputs & outputs)](#wiring-inputs--outputs)
- [Networking](#networking)
- [Permissions](#permissions)
- [Rendering](#rendering)
- [World objects: holograms, props and rangers](#world-objects-holograms-props-and-rangers)
- [Using the in‑editor reference](#using-the-in-editor-reference)

---

## Types

Every value in E3 has a type. The built‑in types are:

| Type | Aliases | What it is |
|------|---------|------------|
| `number` | `int`, `integer`, `double`, `normal` | A numeric value. |
| `string` | | Text. |
| `boolean` | `bool` | `true` or `false`. |
| `vector` | | A 3D vector (x, y, z). |
| `vector2` | | A 2D vector (x, y), used for screen coordinates. |
| `angle` | | An orientation (pitch, yaw, roll). |
| `color` | `colour` | An RGBA colour. |
| `quaternion` | `quat` | A quaternion, for smooth rotations. |
| `matrix2` / `matrix3` / `matrix4` | | 2×2 / 3×3 / 4×4 matrices. |
| `entity` | | Any entity in the world. |
| `player` | | A player (a kind of entity). |
| `hologram` | | An E3 hologram (a kind of entity). |
| `table` | `array` | A key/value container; also used as an array. |
| `function` | | A function value. |
| `date` | | A date/time value. |
| `rangerdata` | | The result of a ranger (trace). |
| `wirelink` | | A link to another entity's wire ports. |
| `stream` | | A network message being written or read. |
| `recipientfilter` | | A set of players to send a network message to. |
| `constraint` | | A physics constraint. |
| `sound` | | A playable sound. |
| `canvas` | | A render target you can draw onto. |
| `find` | | An entity‑finder with filters and results. |
| `physics` / `bone` | | A physics object (bone) of an entity. |
| `pattern` | | A string pattern (from an `@"…"` literal). |
| `error` | | A thrown error. |
| `type` / `class` | | A reference to a type itself. |
| `variant` / `object` | | A value whose type is decided at runtime. |
| `void` | `nil` | No value. |

`player` and `hologram` **extend** `entity`, so every entity method also works
on players and holograms.

## Working with objects

Most non‑number types are created with the `new` keyword and a **constructor**,
then used through **methods** (`object.method(...)`) and **attributes**
(`object.attribute`):

```cpp
vector pos = new vector(0, 0, 100);   // constructor
number height = pos.z;                 // attribute
vector flat = pos.withZ(0);            // method (see the reference for names)

color red = new color(255, 0, 0);
angle look = new angle(0, 90, 0);
```

Constructors, methods and attributes for every type are listed in the
[in‑editor reference](#using-the-in-editor-reference).

## The libraries

Functions are grouped into libraries and called as `library.function(...)`.
Here is what each built‑in library is for.

| Library | Purpose |
|---------|---------|
| `system` | The gate and its context: owner, entity, realm checks, CPU/quota readings, `print`, `out`, `invoke`, `throw`. |
| `math` | Mathematics: trig, rounding, interpolation, random numbers, and constants like `pi`. |
| `string` | String helpers (many string operations are also methods on the `string` type). |
| `game` | Information about the server, map and physics environment. |
| `time` | Clocks and timing: uptime, frame time, high‑precision time, and dates. |
| `timer` | Named one‑shot and repeating timers. |
| `event` | Attaching to, removing and calling events. |
| `players` | Finding players by name, SteamID, etc. |
| `team` | Team information: names, colours, scores, members. |
| `permissions` | Checking permissions and finding entity owners. |
| `render` | 2D drawing to the HUD or a screen (client‑side). |
| `hololib` | Creating and configuring holograms. |
| `prop` | Spawning props and seats. |
| `ranger` | Configuring and firing rangers (traces). |
| `net` | Networking between server and clients. |
| `http` | Making HTTP requests. |
| `entlib` | Finding entities (creates `find` objects). |
| `clr` | Colour helpers (HSV conversion, randomisation, alpha). |
| `quaternion` | Building and interpolating quaternions. |
| `matrix2` / `matrix3` / `matrix4` | Matrix mathematics. |
| `key` | Named key‑code constants (e.g. `key.a`, `key.space`). |
| `numpad` | Named numpad key‑code constants. |

Some libraries also expose **constants** (for example `math.pi()` or the
`key.*` codes). The exact members of each library are in the in‑editor
reference.

## Events

Attach a function to an event with `event.add(name, uniqueID, callback)`. The
callback's parameters must match the event. Remove it with
`event.remove(name, uniqueID)`.

| Event | Callback parameters | Fires when |
|-------|--------------------|-----------|
| `Think` | — | Every tick. |
| `Trigger` | `string port` | A wired input changes; `port` is its name. |
| `RenderHUD` | `number w, number h` | Drawing to the HUD (client). |
| `RenderScreen` | `number w, number h, entity screen` | Drawing to a wired screen (client). |
| `UseScreen` | `number x, number y, player ply, entity screen` | A player uses a screen. |
| `OnPlayerChat` | `player ply, string text, number team` | A player sends a chat message. |
| `OnPlayerJoin` | `player ply` | A player connects. |
| `OnPlayerSpawn` | `player ply` | A player spawns. |
| `OnPlayerDisconnect` | `player ply` | A player disconnects. |
| `OnPlayerDeath` | `player victim, entity inflictor, entity attacker` | A player dies. |
| `PlayerButtonDown` | `player ply, number button` | A player presses a button/key. |
| `PlayerButtonUp` | `player ply, number button` | A player releases a button/key. |
| `InitializedClient` | `player ply` | A client finishes initialising the script. |
| `ShutDown` | — | Just before the gate is removed or reset. |
| `PermissionChanged` | `player ply, string permission, boolean granted` | A permission is granted or revoked. |

Key‑related events use the numeric key codes from the `key` and `numpad`
libraries, so you can compare against, say, `key.e`.

## Wiring (inputs & outputs)

E3 chips are Wiremod devices. Declare ports with directives; read and write them
like variables. Port names must be **CamelCase**.

```cpp
@input number A;
@input entity Target;
@output number Result;

event.add("Trigger", "io", function(string port) {
    if (Target.isValid()) {
        Result = A * 2;
    }
});
```

- `@input <type> Name;` — a value fed in from another wire device.
- `@output <type> Name;` — a value you write for other devices to read.
- `@synced <type> name;` — a variable automatically kept in sync between the
  server and clients (useful for HUD/screen scripts).

Wireable types: `number`, `string`, `boolean`, `vector`, `vector2`, `angle`,
`entity`, `player`, `table`, `function`, `wirelink`, and the E2 table type. Use
the `wirelink` type and its methods to read/write another entity's ports
directly.

## Networking

Networking sends data between the server and clients. You build a **stream**,
write values into it, and send it; the other side reads the values back **in the
same order**.

```cpp
@name "Net Demo";

server {
    timer.simple(2, function() {
        stream msg = net.start("hello");
        msg.writeString("Hi from the server");
        msg.writeFloat(time.curtime());
        net.sendToClients(msg);           // to everyone
    });
}

client {
    net.receive("hello", function(stream msg) {
        string text = msg.readString();
        number when = msg.readFloat();
        system.print("Server said: ", text);
    });
}
```

- `net.start(name)` begins a message and returns a `stream`.
- `stream` methods `writeString` / `writeFloat` / `writeBool` / … write values;
  `readString` / `readFloat` / … read them back in order.
- `net.sendToServer(stream)` (from a client) and `net.sendToClients(stream)`
  (from the server) send the message. A `recipientfilter` can target specific
  clients.
- `net.receive(name, callback)` handles an incoming message.

Networking counts against the gate's **net quota** — see the
[project README](../README.md#performance-monitoring).

## Permissions

Some capabilities require the affected player's permission before they work.
A gate that hasn't been granted a permission simply can't perform that action.
The built‑in permissions are:

| Permission | Guards |
|------------|--------|
| `PropControl` | Altering another player's props/entities. |
| `KeyPress` | Reading a player's key presses. |
| `HTTPRequests` | Making HTTP requests. |
| `URLMaterials` | Downloading images as materials. |
| `RenderCanvas` | Creating and drawing to canvases. |
| `RenderScreen` | Drawing to a gate's screen. |
| `RenderHUD` | Drawing to a player's HUD. |

From a script you can check permissions and find owners with the `permissions`
library:

```cpp
if (permissions.check(someEntity)) {
    // this gate's owner is allowed to modify someEntity
}

player boss = permissions.owner(someEntity);
```

Players grant permissions through the in‑game menu;

## Rendering

The `render` library draws 2D graphics, and only runs **client‑side**. Do your
drawing inside a `RenderHUD` event (the player's HUD) or a `RenderScreen` event
(a wired E3 screen). Positions are `vector2` values in pixels.

```cpp
@name "HUD";
@client;

event.add("RenderHUD", "hud", function(number w, number h) {
    render.setColor(new color(0, 0, 0, 150));
    render.drawBox(new vector2(20, 20), new vector2(200, 60));

    render.setFont("DermaLarge", 22);
    render.setFontColor(new color(0, 255, 128));
    render.drawText(new vector2(30, 30), "Expression 3");
});
```

`render` provides shape drawing (boxes, circles, lines, triangles, polygons),
text with configurable fonts and colours, screen size queries (`scrW`, `scrH`),
and canvases (render targets) for advanced effects.

## World objects: holograms, props and rangers

- **Holograms** (`hololib` + the `hologram` type) are lightweight models you
  spawn and control — position, angle, scale, colour, material, parenting,
  animation and clipping. Great for displays and effects. See the `holograms`
  example in the editor.
- **Props and seats** (`prop`) let a gate spawn physical props and vehicle
  seats, subject to the server's rate and permission limits.
- **Rangers** (`ranger` + the `rangerdata` type) fire traces through the world
  to detect the ground, walls, props and players. Configure filters and flags,
  fire with `ranger.offset(...)`, then read the result's attributes (`hit`,
  `hit_pos`, `hit_entity`, `distance`, …). See the `rangers` example.

## Using the in‑editor reference

The Golem editor's **helper browser** is the exhaustive, always‑current
reference. Because it is generated from the extensions your server actually has
installed, it never drifts out of date. In it you can browse and search:

- **Classes** — every type, its constructors, attributes and methods.
- **Libraries** — every library and the functions and constants it provides.
- **Operators** — every operator and the type combinations it supports.
- **Events** — every event and its parameters.
- **Examples** — runnable, commented scripts.

Each entry shows its signature, a description and often an example. When these
guides say "see the in‑editor reference for the exact names", this is where to
look — and it is the best companion to keep open while you write E3.

---

Back to the **[documentation index](README.md)**.
