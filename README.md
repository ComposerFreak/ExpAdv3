# Expression 3

**Expression 3** (E3, also known as *Expression Advanced 3*) is a programmable
[Wiremod](https://github.com/wiremod/wire) chip for **Garry's Mod**. It lets you
write real programs — with variables, functions, classes, events and a full
standard library — inside the game, compile them, and run them on a chip that
interacts with the world and the rest of your Wiremod contraptions.

It is the successor to Expression 2 and the older *Expression Advanced 2 /
Lemongate* projects, rebuilt from the ground up around a **strongly‑typed**
language, an **extensible runtime**, and a **per‑gate performance and permission
system** designed to keep servers safe.

> This README is aimed at **server owners** and **people who want to understand
> what E3 is and how it works**. It is not a language tutorial — a full
> language guide will live in the [`/docs`](docs) folder, and an interactive
> reference ships inside the in‑game editor (see [The Golem editor](#the-golem-editor)).

---

## Table of contents

- [What Expression 3 is](#what-expression-3-is)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
  - [From GitHub](#from-github)
  - [From the Steam Workshop](#from-the-steam-workshop)
  - [Removing older versions](#removing-older-versions)
- [Using E3 in game](#using-e3-in-game)
- [The Golem editor](#the-golem-editor)
- [Performance monitoring](#performance-monitoring)
  - [The quota model](#the-quota-model)
  - [What happens when a gate goes over budget](#what-happens-when-a-gate-goes-over-budget)
  - [Reading quotas from inside a script](#reading-quotas-from-inside-a-script)
- [Permissions](#permissions)
- [Console variables (convars)](#console-variables-convars)
- [Console commands](#console-commands)
- [Tuning E3 for your server](#tuning-e3-for-your-server)
- [Repository layout](#repository-layout)
- [Contributing](#contributing)
- [Links](#links)
- [Credits & attributions](#credits--attributions)

---

## What Expression 3 is

At its core E3 is:

- **A language.** A statically‑typed language with `int`/`number`, `string`,
  `boolean`, `vector`, `angle`, `color`, `quaternion`, `entity`, `player`,
  `hologram`, `table`, matrices and more. It supports first‑class functions,
  closures, delegates, `try`/`catch` error handling, and full object‑oriented
  programming with `class`, `interface`, `extends` and `implements`.
- **A compiler.** Your code is tokenized, parsed and compiled down to native
  Lua for speed, rather than being interpreted instruction‑by‑instruction.
- **A runtime.** Each chip runs inside a sandboxed *context* that meters CPU
  time, networking and other resources, and enforces per‑player permissions.
- **A Wiremod device.** Gates expose typed `@input`/`@output` ports that wire
  to any other Wiremod component, so E3 can read sensors and drive contraptions.
- **An in‑game IDE.** The **Golem** editor provides syntax highlighting,
  auto‑complete, an example browser and a live searchable reference for every
  type, library, function, method and event.

Everything above the core — vectors, holograms, props, rangers (traces),
networking, HTTP, sound, rendering, and so on — is provided by **extensions**.
Extensions register the classes, libraries, functions, methods, operators,
events and permissions that make up the language you actually write against,
which keeps the core small and makes the feature set easy to extend.

---

## How it works

When you spawn a chip and upload code, E3 runs it through a small pipeline:

```
 your code
    │
    ▼
 Tokenizer  ──►  Parser  ──►  Compiler  ──►  native Lua function
    │              │            │                    │
  tokens          AST     type‑checking          Runtime
                          & directives         (sandboxed context)
```

1. **Tokenizer** breaks the source into tokens.
2. **Parser** builds a syntax tree and reads *directives* (the `@name`,
   `@model`, `@input`, `@output`, `@server`, `@client`, `@include`, `@synced`
   lines at the top of a script).
3. **Compiler** type‑checks everything (E3 is strongly typed, so most mistakes
   are caught here, before the code ever runs) and emits a native Lua function.
4. **Runtime** executes that function inside a per‑gate **context** that tracks
   resource usage, checks permissions, and catches errors.

The chip entity is built on Wiremod's `base_wire_entity`, so it participates in
the wire system like any other gate: `@input` ports appear as wire inputs,
`@output` ports as wire outputs, and changes propagate through your build.

E3 runs on **both the server and the client**. By default a script is *shared*;
you can restrict whole scripts or individual blocks to one realm with the
`@server` / `@client` directives (or `server { }` / `client { }` blocks). This
is what makes client‑side HUD rendering and server↔client networking possible
from a single chip.

---

## Requirements

- **Garry's Mod** (a reasonably recent build).
- **[Wiremod](https://github.com/wiremod/wire)** — E3 is a Wiremod addon and
  will not function without it. Install Wire first.

---

## Installation

### From GitHub

1. Download or clone this repository into your `garrysmod/addons` folder:

   ```
   garrysmod/addons/ExpAdv3/
   ```

2. **Linux servers:** the folder name must be **lower‑case**. Rename it to
   `expadv3` (or any all‑lowercase name), otherwise the addon will not mount:

   ```
   garrysmod/addons/expadv3/
   ```

   (Windows is case‑insensitive, so the casing does not matter there.)

3. Make sure **Wiremod** is installed as well.
4. Restart the server / game. On start‑up E3 prints a banner to the console and
   locates its own addon directory automatically.

### From the Steam Workshop

You can subscribe to the Workshop release instead of using Git. The Workshop
build is updated regularly, but **GitHub is always the most up‑to‑date source**.
See [Links](#links).

### Removing older versions

E3 replaces the older **Expression Advanced 2** and **Lemongate** addons.
Remove any of those before installing E3 to avoid conflicts. If you installed
them through the Workshop, also delete the corresponding files from your
`addons` folder (or unsubscribe) so the old code does not get mounted.

---

## Using E3 in game

1. Open the **Tool** menu and find **Expression 3 Tool (Wire)** under the
   **Chips, Gates** category.
2. **Left‑click** in the world to spawn an Expression 3 chip.
3. **Right‑click** the chip (or empty air) to open the chip in the **Golem**
   editor.
4. Write your code, then **upload** it to the chip from the editor.

A companion **Expression 3 Screen** tool is also included for scripts that draw
to a E3 screen (see the `RenderScreen` event and the `render` library).

---

## The Golem editor

Golem is the in‑game IDE that ships with E3. It provides:

- **Syntax highlighting** and **auto‑complete** for the E3 language.
- A **helper browser** listing every type, library, function, method, operator,
  attribute and event, each with a description and often an example. This data
  lives in `lua/expression3/helper/csv` and can be extended or overridden
  locally, so the reference always matches the extensions you actually have
  installed.
- An **examples** section (`lua/expression3/helper/examples`) with runnable,
  fully‑commented scripts you can open in a new tab and learn from.
- **Bookmarks**, an in‑editor **console**, and the ability to **export** your
  own custom helper documentation.

---

## Performance monitoring

Because E3 lets players run arbitrary code on your server, it ships with a
**resource metering** system that runs on every gate. The design follows the
same lineage as Wiremod E2 and StarfallEx: each gate is given a CPU‑time budget,
and a gate that consistently exceeds it is shut down rather than being allowed to
lag the server.

Every gate owns a **context** object that measures, on each execution:

- **CPU time** actually spent (measured with `SysTime`).
- A running, smoothed **average** of that CPU time.
- An accumulated **operation cost** ("price") for the current tick.
- **Networking** usage.

### The quota model

There are three independent limits, each backed by a convar (with a client‑side
mirror ending in `_cl`):

| Limit | Convar | Default | Meaning |
|-------|--------|---------|---------|
| **Soft time** | `e3_softtime` | `0.05` | The target **average** CPU time (in seconds) a gate should stay under. Used to compute the moving average and the "% of budget used" figure shown on gates and returned to scripts. |
| **Hard time** | `e3_hardtime` | `0.0001` | The maximum CPU time (in seconds) a **single execution** may take. A deadline is set at the start of each run and checked periodically while the code executes. |
| **Hard limit** | `e3_hardlimit` | `64000` | The maximum accumulated **operation cost** allowed in a single tick. |

Two further convars shape the metering:

| Convar | Default | Meaning |
|--------|---------|---------|
| `e3_timebuffersize` | `100` | Window width of the CPU‑time **moving average**. Larger values react more slowly (smoother), smaller values react faster (spikier). |
| `e3_netquota` | `64000` | Maximum networking usage quota, in kb. |

The soft average is smoothed each tick (roughly `average = average * 0.95 +
thisTick * 0.05`), and the gate's reported usage is that moving average divided
by the soft‑time budget — so `1.0` means a gate is sitting right at its soft
limit.

### What happens when a gate goes over budget

Execution is wrapped so that when a limit is hit, the runtime throws a quota
error which is caught by the gate:

- Exceeding the **hard‑time deadline** raises *"CPU time quota exceeded."*
- Exceeding the **hard limit** (operation cost) raises *"Hard execution limit
  reached."*

In either case the gate is **shut down**, the owner is notified in chat, and the
full error (with the E3 line and column) is written to the Golem console. This
contains a runaway or infinite‑loop script to a single failing tick instead of
letting it hang the server.

### Reading quotas from inside a script

The `system` library exposes the same numbers to script authors so they can
budget their own code:

- `system.quota()` — CPU time used this tick.
- `system.quotaMax()` — the soft‑time budget.
- `system.quotaUsage()` — current soft usage (fraction of the budget).
- `system.quotaAverage()` / `system.movingQuotaAverage()` — smoothed averages.
- `system.netQuota()` / `system.netQuotaMax()` — networking usage and limit.
- `system.hardQuotaMax()` / `system.hardQuotaUse()` — the hard limit and the
  cost used against it this tick.

---

## Permissions

E3 gates cannot silently mess with your props, sniff your keys or render to your
screen. Sensitive capabilities are gated behind a **per‑player, per‑gate
permission** system. A gate must be granted a permission by the affected player
before the corresponding action will work.

The permissions registered by the built‑in extensions are:

| Permission | Guards |
|------------|--------|
| `PropControl` | Altering another player's props/entities. |
| `KeyPress` | Reading a player's key/button presses. |
| `HTTPRequests` | Making HTTP requests (the URL filter still applies). |
| `URLMaterials` | Downloading images as materials (the URL filter still applies). |
| `RenderCanvas` | Creating and drawing to canvases (render targets). |
| `RenderScreen` | Drawing to a gate's built‑in screen. |
| `RenderHUD` | Drawing to a player's HUD. |

Permissions can be managed through the in‑game menu, and there are console
commands for setting them directly or globally — see
[Console commands](#console-commands). Extensions can register their own
permissions, so third‑party additions can participate in the same system.

---

## Console variables (convars)

All server convars can be set in `server.cfg` or at the console. Values with an
`_cl` counterpart are duplicated so that client‑side execution (HUD/screen
rendering, etc.) can be limited independently of the server. Convars marked
*archived* persist across restarts.

### Performance / quotas

| Convar | Default | Archived | Description |
|--------|---------|:--------:|-------------|
| `e3_softtime` / `e3_softtime_cl` | `0.05` | ✔ | Soft CPU‑time budget (average, seconds). |
| `e3_hardtime` / `e3_hardtime_cl` | `0.0001` | ✔ | Max CPU time for a single execution (seconds). |
| `e3_hardlimit` / `e3_hardlimit_cl` | `64000` | ✔ | Max operation cost per tick. |
| `e3_timebuffersize` / `e3_timebuffersize_cl` | `100` | ✔ | Moving‑average window width. |
| `e3_netquota` / `e3_netquota_cl` | `64000` | ✔ | Max networking quota (kb). |

### Holograms

| Convar | Default | Description |
|--------|---------|-------------|
| `wire_expression3_hologram_max` | `250` | Max holograms per player. |
| `wire_expression3_hologram_rate` | `50` | Max holograms created per second. |
| `wire_expression3_hologram_clips` | `5` | Max clipping planes per hologram. |
| `wire_expression3_hologram_size` | `50` | Max hologram scale. |
| `wire_expression3_hologram_model_any` | `1` | Allow any model (`1`) or restrict to an allow‑list (`0`). |

### Props

| Convar | Default | Description |
|--------|---------|-------------|
| `wire_expression3_prop_rate` | `4` | Props a gate may spawn per second. |

### Sounds

| Convar | Default | Description |
|--------|---------|-------------|
| `wire_expression3_sound_max` / `wire_expression3_sound_max_cl` | `20` | Max simultaneous sounds per gate. |

### Canvases (render targets — client)

| Convar | Default | Description |
|--------|---------|-------------|
| `e3_canvas_max` | `10` | Max canvases per gate. |
| `e3_canvas_burst` | `10` | Max canvases a gate may create per second. |

### URL materials

| Convar | Default | Description |
|--------|---------|-------------|
| `expression3_maxurlmaterials` | `15` | Max downloaded URL materials per gate. |
| `expression3_maxurlmatsize` | `512` | Max URL material size (px). |

### Timers

| Convar | Default | Archived | Description |
|--------|---------|:--------:|-------------|
| `e3_max_timers` / `e3_max_timers_cl` | `100` | ✔ | Max timers per gate. |

### Miscellaneous

| Convar | Default | Description |
|--------|---------|-------------|
| `wire_expression3_printtbl` | `100` | Max size of a table printed with `printTable`. |

### Editor (client)

| Convar | Default | Description |
|--------|---------|-------------|
| `golem_font_name` | `Courier New` | Golem editor font. |
| `golem_font_size` | `16` | Golem editor font size. |

---

## Console commands

| Command | Usage | Description |
|---------|-------|-------------|
| `e3_permission` | `e3_permission <entIndex> <permission> <value>` | Set a permission for a specific gate. |
| `e3_global_permission` | `e3_global_permission <permission> <value>` | Set a permission globally for your gates. |
| `e3_show_golem_anim` | — | Enable the Golem editor's intro animation. |
| `e3_hide_golem_anim` | — | Disable the Golem editor's intro animation. |

> Permissions are normally granted through the in‑game menu; the console
> commands exist for scripting and for players who prefer the console.

---

## Tuning E3 for your server

A few practical notes for operators:

- **Start from the defaults.** They are deliberately conservative and suit most
  servers. Only change quotas if you understand the trade‑off.
- **CPU headroom vs. capability.** Raising `e3_softtime` / `e3_hardtime` lets
  gates do more work per tick but reduces the protection against laggy scripts.
  Lowering them is safer but will shut down heavier (legitimate) builds sooner.
- **Smoothing.** `e3_timebuffersize` controls how forgiving the average is of
  short spikes. A larger window tolerates brief bursts; a smaller one clamps
  down quickly.
- **Entity limits.** The hologram, prop, sound and canvas limits are the main
  levers for controlling how many objects players can spawn from a chip. Tune
  these to match your server's population and performance target.
- **Networking.** `e3_netquota` caps how much bandwidth a gate can use. Lower it
  on busy servers if networking‑heavy scripts become a problem.
- **Client mirrors.** Remember the `_cl` convars limit *client‑side* execution
  (HUD, screens, canvases). They are set on the client, so consider them a
  default rather than an enforced server rule.
- **Persistence.** Quota and timer convars are archived (`FCVAR_ARCHIVE`) and
  persist across restarts; the entity‑limit convars are not, so set those in
  `server.cfg` if you want them to stick.

---

## Repository layout

```
ExpAdv3/
├── addon.json                         Workshop addon metadata
├── lua/
│   ├── autorun/expression3.lua        Entry point / loader
│   ├── entities/                      Chip, hologram and screen entities
│   ├── wire/stools/                   The Wire tools (chip + screen)
│   └── expression3/
│       ├── tokenizer.lua              Source → tokens
│       ├── parser.lua                 Tokens → syntax tree (+ directives)
│       ├── compiler.lua               Type‑checking + Lua code generation
│       ├── expr_lib.lua               Extension/registration API
│       ├── core/                      Core language types & libraries
│       ├── extensions/                Feature extensions (holo, prop,
│       │                              ranger, render, net, http, …)
│       ├── permissions/               Permission system + menus
│       ├── editor/                    The Golem in‑game IDE
│       └── helper/                    In‑editor reference data & examples
│           ├── csv/                   Type / function / method reference
│           └── examples/              Runnable example scripts
├── materials/  models/                Assets
└── docs/                              (Language guide — work in progress)
```

---

## Contributing

Contributions are welcome. The most useful things to know:

- **Extensions** are the intended way to add features. Look at the files in
  `lua/expression3/extensions/` for the patterns used to register classes,
  libraries, functions, methods, operators, events and permissions via
  `lua/expression3/expr_lib.lua`.
- **Reference/help text** for the editor lives in
  `lua/expression3/helper/csv/`. It is keyed by *signature* and merged over the
  auto‑generated defaults, so you only need to fill in what you want to document.
- **Example scripts** for the editor live in
  `lua/expression3/helper/examples/` — plain, well‑commented `.lua` files.

Please keep changes focused and test them in‑game before opening a pull request.

---

## Links

- **GitHub:** <https://github.com/ComposerFreak/ExpAdv3>
- **Steam Workshop:** <https://steamcommunity.com/sharedfiles/filedetails/?id=2001386268>

---

## Credits & attributions

- **Expression 3** by **Rusketh** and contributors.
- The CPU‑benchmarking / quota approach follows the lineage of **Wiremod E2**
  and **StarfallEx** — credit to their original authors.

### Fugue Icons — Yusuke Kamiyamane

<https://p.yusukekamiyamane.com/>

All rights to the Fugue Icons belong to their original author. Used under the
[Creative Commons Attribution 3.0 License](https://creativecommons.org/licenses/by/3.0).
