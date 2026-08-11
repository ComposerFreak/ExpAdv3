# Expression 3 — Full Reference

A complete reference to Expression 3, organised by **subsystem**. Each section gathers everything about one topic in one place: the library and what it does, its functions and constants, and the related type(s) with their constructors, attributes, operators and methods.

> New to E3? Start with [Getting Started](getting-started.md) and the [Language Reference](language.md). This page is a reference, not a tutorial. It lists the built-in extensions; a server with add-ons will have more, and the Golem editor's helper browser always reflects exactly what is installed.

**Notation.** Signatures use E3 type names — `clamp(number, number, number) → number`. `→ void` means nothing is returned; a trailing `...` means any number of further arguments.

## Contents

- [The Gate & System](#the-gate-system)
- [Events](#events)
- [Timers](#timers)
- [Numbers & Maths](#numbers-maths)
- [Strings](#strings)
- [Booleans](#booleans)
- [Tables & Arrays](#tables-arrays)
- [Vectors](#vectors)
- [2D Vectors](#2d-vectors)
- [Angles](#angles)
- [Colours](#colours)
- [Quaternions](#quaternions)
- [Matrices](#matrices)
- [Time & Dates](#time-dates)
- [Entities](#entities)
- [Players & Teams](#players-teams)
- [Holograms](#holograms)
- [Props](#props)
- [Physics Objects](#physics-objects)
- [Constraints](#constraints)
- [Rangers (Traces)](#rangers-traces)
- [Finding Entities](#finding-entities)
- [Wirelink](#wirelink)
- [E2 Table Compatibility](#e2-table-compatibility)
- [Rendering](#rendering)
- [Keyboard Input](#keyboard-input)
- [Networking](#networking)
- [HTTP](#http)
- [Game & Server](#game-server)
- [Permissions](#permissions)
- [Sound](#sound)
- [Errors](#errors)
- [Types & Variants](#types-variants)

---

## The Gate & System

The `system` library is your window onto the chip itself: who owns it, which entity it is, which realm the code is running in, how much CPU and networking budget it is using, and the functions for printing and error handling.

#### Library: `system`

- **`system.destroy() → void`**  
  Permanently removes this Expression 3 gate.
- **`system.getClient() → player`**  
  Returns the local player. This is only meaningful client-side, where it is the player viewing the gate.
- **`system.getEntity() → entity`**  
  Returns the entity of the Expression 3 gate this code is running on.
- **`system.getOwner() → player`**  
  Returns the player who owns (spawned) this Expression 3 gate.
- **`system.getTickRate() → number`**  
  Returns the gate's current tick rate (how many times per second its think runs).
- **`system.hardQuotaMax() → number`**  
  Returns the hard CPU time limit; a single tick exceeding it shuts the gate down immediately.
- **`system.hardQuotaUse() → number`**  
  Returns the CPU time used against the hard limit on this tick.
- **`system.invoke(type, number, function, ...) → void`**  
  Calls the given function immediately and returns a value of the specified class and count, passing along any extra arguments.
- **`system.isClient() → boolean`**  
  Returns true when the code is currently running on a client.
- **`system.isServer() → boolean`**  
  Returns true when the code is currently running on the server.
- **`system.movingQuotaAverage() → number`**  
  Returns the gate's moving (smoothed) average CPU usage.
- **`system.netQuota() → number`**  
  Returns the amount of the networking (bandwidth) quota used so far.
- **`system.netQuotaMax() → number`**  
  Returns the maximum networking (bandwidth) quota available to the gate.
- **`system.out(...) → void`**  
  Prints the given values to the Golem IDE console.
- **`system.print(...) → void`**  
  Prints the given values to the gate owner's chat.
- **`system.printTable(table) → void`**  
  Prints the contents of a table to the Golem IDE console for inspection.
- **`system.quota() → number`**  
  Returns the total CPU time (in seconds) used by the gate on the current tick.
- **`system.quotaAverage() → number`**  
  Returns the gate's average CPU usage over recent ticks.
- **`system.quotaMax() → number`**  
  Returns the soft CPU time limit; exceeding it repeatedly will shut the gate down.
- **`system.quotaUsage() → number`**  
  Returns the gate's current soft CPU usage on this tick.
- **`system.setTickRate(number) → void`**  
  Sets how many times per second the gate's think runs. Higher rates cost more CPU quota.
- **`system.throw(error) → void`**  
  Throws an error object up through the stack, stopping execution unless it is caught.

---

## Events

Events let a script react to things happening in the game. Attach a function with `event.add(name, uniqueID, callback)` and detach it with `event.remove(name, uniqueID)`. Every built-in event and its callback parameters are listed at the end of this section.

#### Library: `event`

- **`event.add(string, string, function) → void`**  
  Registers a function to be called whenever the named event fires. The second argument is a unique id so the listener can be removed later.
- **`event.call(type, number, entity, string, ...) → void`**  
  Fires the named event on a specific gate entity and collects a return value of the given class and count.
- **`event.call(type, number, string, ...) → table`**  
  Fires the named event and collects a return value of the given class and count from the listeners.
- **`event.call(entity, string, ...) → boolean`**  
  Fires the named event on a specific gate entity, passing any extra arguments to its listeners.
- **`event.call(string, ...) → boolean`**  
  Fires the named event, passing any extra arguments to its listeners, and returns whether it was handled.
- **`event.remove(string, string) → void`**  
  Removes a previously added event listener by its event name and unique id.

**All events**

| Event | Callback parameters |
|-------|--------------------|
| `GatherPermissions` | — |
| `InitializedClient` | `player` |
| `OnPlayerChat` | `player, string, number` |
| `OnPlayerDeath` | `player, entity, entity` |
| `OnPlayerDisconnect` | `player` |
| `OnPlayerJoin` | `player` |
| `OnPlayerSpawn` | `player` |
| `PermissionChanged` | `player, string, boolean` |
| `PlayerButtonDown` | `player, number` |
| `PlayerButtonUp` | `player, number` |
| `RenderHUD` | `number, number` |
| `RenderScreen` | `number, number, entity` |
| `ShutDown` | — |
| `Think` | — |
| `Trigger` | `string` |
| `UseScreen` | `number, number, player, entity` |

---

## Timers

The `timer` library schedules code to run later or on a repeating interval.

#### Library: `timer`

- **`timer.create(string, number, number, function, ...) → void`**  
  Creates a named repeating timer. Arguments are: name, delay in seconds, number of repetitions (0 for infinite), and the function to run.
- **`timer.exists(string) → boolean`**  
  Returns true if a timer with the given name currently exists.
- **`timer.pause(string) → void`**  
  Pauses the named timer, freezing its countdown until it is resumed.
- **`timer.remove(string) → void`**  
  Stops and removes the timer with the given name.
- **`timer.resume(string) → void`**  
  Resumes a previously paused timer.
- **`timer.simple(number, function, ...) → void`**  
  Runs the given function once after a delay (in seconds), passing any extra arguments to it.

---

## Numbers & Maths

`number` is E3's single numeric type (its aliases include `int`). The `math` library provides the mathematical functions and constants.

#### Library: `math`

- **`math.abs(number) → number`**  
  Returns the absolute value of a number, removing any negative sign so the result is always positive or zero.
- **`math.acos(number) → number`**  
  Returns the arccosine (inverse cosine) of the given number, in radians. The input must be in the range -1 to 1.
- **`math.acot(number) → number`**  
  Returns the arccotangent (inverse cotangent) of the given number, in radians.
- **`math.angleDifference(number, number) → number`**  
  Returns the signed difference between two angles in degrees, wrapped to the range -180 to 180.
- **`math.approach(number, number, number) → number`**  
  Moves the current value (second argument) toward the target value (third argument) by at most the given step (first argument), without overshooting.
- **`math.approachAngle(number, number, number) → number`**  
  Like approach, but treats the values as angles in degrees and takes the shortest way around the circle.
- **`math.asin(number) → number`**  
  Returns the arcsine (inverse sine) of the given number, in radians. The input must be in the range -1 to 1.
- **`math.atan(number) → number`**  
  Returns the arctangent (inverse tangent) of the given number, in radians.
- **`math.atan2(number, number) → number`**  
  Returns the angle in radians between the positive X axis and the point (x, y), correctly handling every quadrant. Pass y first, then x.
- **`math.bSplinePoint(number, table, number) → vector`**  
  Returns a point along a B-spline curve. The first argument is the position along the curve, the table holds the control points, and the last argument is the tension.
- **`math.binToInt(string) → number`**  
  Converts a string of binary digits ("0" and "1") into its integer value.
- **`math.ceil(number) → number`**  
  Rounds a number up to the smallest integer that is greater than or equal to it.
- **`math.clamp(number, number, number) → number`**  
  Constrains a value to lie between a minimum and a maximum. The first argument is the value, then the low and high bounds.
- **`math.cos(number) → number`**  
  Returns the cosine of an angle given in radians.
- **`math.cosh(number) → number`**  
  Returns the hyperbolic cosine of a number.
- **`math.cot(number) → number`**  
  Returns the cotangent of an angle given in radians (the reciprocal of the tangent).
- **`math.deg(number) → number`**  
  Converts an angle from radians into degrees.
- **`math.distance(number, number, number, number) → number`**  
  Returns the straight-line distance between two 2D points (x1, y1) and (x2, y2).
- **`math.easeInOut(number, number, number) → number`**  
  Eases a value between a start and end using a smooth accelerate-then-decelerate curve. The first argument is the progress (0-1).
- **`math.exp(number) → number`**  
  Returns e (Euler's number) raised to the given power.
- **`math.floor(number) → number`**  
  Rounds a number down to the largest integer that is less than or equal to it.
- **`math.fmod(number, number) → number`**  
  Returns the remainder of dividing the first number by the second, keeping the sign of the dividend (floating-point modulo).
- **`math.frexp(number) → number`**  
  Splits a number into a normalized fraction (between 0.5 and 1) and an integer exponent such that fraction * 2^exponent equals the input.
- **`math.huge() → number`**  
  Returns a value representing positive infinity.
- **`math.intToBin(number) → string`**  
  Converts an integer into a string of binary digits.
- **`math.ldexp(number, number) → number`**  
  Returns the first argument multiplied by 2 raised to the power of the second argument (the inverse of frexp).
- **`math.lerp(number, number, number) → number`**  
  Linearly interpolates between two numbers. The first argument is the fraction (0 returns the start, 1 returns the end).
- **`math.lerpAngle(number, angle, angle) → angle`**  
  Linearly interpolates between two angles, taking the shortest path. The first argument is the fraction (0-1).
- **`math.lerpVector(number, vector, vector) → vector`**  
  Linearly interpolates between two vectors. The first argument is the fraction (0-1).
- **`math.log(number) → number`**  
  Returns the natural logarithm (base e) of a number.
- **`math.log(number, number) → number`**  
  Returns the logarithm of the first number in the base given by the second number.
- **`math.log10(number) → number`**  
  Returns the base-10 logarithm of a number.
- **`math.max(...) → number`**  
  Returns the largest of all the numbers passed to it.
- **`math.min(...) → number`**  
  Returns the smallest of all the numbers passed to it.
- **`math.modf(number) → number`**  
  Splits a number into its integral part and its fractional part, returning both.
- **`math.normalizeAngle(number) → number`**  
  Wraps an angle in degrees into the range -180 to 180.
- **`math.pi() → number`**  
  Returns the mathematical constant pi (~3.14159).
- **`math.pow(number, number) → number`**  
  Raises the first number to the power of the second number.
- **`math.rad(number) → number`**  
  Converts an angle from degrees into radians.
- **`math.random() → number`**  
  Returns a random floating-point number between 0 and 1.
- **`math.random(number) → number`**  
  Returns a random integer between 1 and the given value, inclusive.
- **`math.random(number, number) → number`**  
  Returns a random integer between the two given values, inclusive.
- **`math.randomseed(number) → void`**  
  Seeds the random number generator so that a sequence of random values can be reproduced.
- **`math.remap(number, number, number, number, number) → number`**  
  Remaps a value from one range to another. Arguments are: value, inMin, inMax, outMin, outMax.
- **`math.round(number) → number`**  
  Rounds a number to the nearest whole integer.
- **`math.round(number, number) → number`**  
  Rounds a number to the given number of decimal places.
- **`math.sin(number) → number`**  
  Returns the sine of an angle given in radians.
- **`math.sinh(number) → number`**  
  Returns the hyperbolic sine of a number.
- **`math.sqrt(number) → number`**  
  Returns the square root of a number.
- **`math.tan(number) → number`**  
  Returns the tangent of an angle given in radians.
- **`math.tanh(number) → number`**  
  Returns the hyperbolic tangent of a number.
- **`math.timeFraction(number, number, number) → number`**  
  Returns how far the current value (third argument) has progressed from a start (first) to an end (second), as a fraction from 0 to 1.
- **`math.toString(number) → string`**  
  Converts a number into its string representation.
- **`math.truncate(number, number) → number`**  
  Cuts a number off at the given number of decimal places without rounding.

#### Type: `number`

*Aliases:* `int`, `integer`, `double`, `normal`

**Operators**

- `!`  (`number` → `boolean`)
- `!=`  (`number, number` → `boolean`)
- `$`  (`number` → `number`)
- `%`  (`number, number` → `number`)
- `&`  (`number, number` → `number`)
- `*`  (`number, angle` → `angle`)
- `*`  (`number, matrix2` → `matrix2`)
- `*`  (`number, matrix3` → `matrix3`)
- `*`  (`number, matrix4` → `matrix4`)
- `*`  (`number, number` → `number`)
- `*`  (`number, quaternion` → `quaternion`)
- `*`  (`number, vector` → `vector`)
- `+`  (`number, number` → `number`)
- `+`  (`number, quaternion` → `quaternion`)
- `+`  (`number, string` → `string`)
- `-`  (`number, number` → `number`)
- `-`  (`number, quaternion` → `quaternion`)
- `- (unary)`  (`number` → `number`)
- `/`  (`number, angle` → `angle`)
- `/`  (`number, number` → `number`)
- `/`  (`number, quaternion` → `quaternion`)
- `/`  (`number, vector` → `vector`)
- `<`  (`number, number` → `boolean`)
- `<<`  (`number, number` → `number`)
- `<=`  (`number, number` → `boolean`)
- `==`  (`number, number` → `boolean`)
- `>`  (`number, number` → `boolean`)
- `>=`  (`number, number` → `boolean`)
- `>>`  (`number, number` → `number`)
- `^`  (`number, number` → `number`)
- `^`  (`number, quaternion` → `quaternion`)
- `^^`  (`number, number` → `number`)
- `|`  (`number, number` → `number`)
- cast `(boolean) number` → `boolean`

---

## Strings

The `string` type holds text. Many operations are methods on the value itself; the `string` library provides a few standalone helpers. Pattern literals (`@"..."`) produce the `patern` type used for matching.

#### Library: `string`

- **`string.toByte(string, void) → number`**  
  Returns the numeric byte (character code) of the character at the given position in a string. The optional second argument is the index (defaults to the first character).
- **`string.toChar(number, void) → string`**  
  Returns the character represented by the given byte (character code).
- **`string.toNumber(string) → number`**  
  Parses a string into a number, or returns 0 if the string is not a valid number.

#### Type: `string`

**Operators**

- `!`  (`string` → `boolean`)
- `!=`  (`string, string` → `boolean`)
- `#`  (`string` → `number`)
- `+`  (`string, number` → `string`)
- `+`  (`string, string` → `string`)
- `<`  (`string, string` → `boolean`)
- `<=`  (`string, string` → `boolean`)
- `==`  (`string, string` → `boolean`)
- `>`  (`string, string` → `boolean`)
- `>=`  (`string, string` → `boolean`)
- `[]`  (`string, number` → `string`)

**Methods**

- **`char() → number`**  
  Returns the character at the specified index in the string.
- **`endsWith(string) → boolean`**  
  Checks if the string ends with the specified substring.
- **`find(string, patern) → number`**  
  Searches for a substring in the string and returns its index.
- **`find(string, patern, number) → number`**  
  Searches for a substring in the string and returns its index, starting from a specified position.
- **`find(string, string) → number`**  
  Searches for a pattern in the string and returns its index.
- **`find(string, string, number) → number`**  
  Searches for a pattern in the string and returns its index, starting from a specified position.
- **`gmatch(string, patern, function) → string`**  
  Iterates over the string, finding all matches to the given pattern and invoking a function for each match.
- **`lower() → string`**  
  Converts the string to lowercase.
- **`match(string, patern, number) → string`**  
  Attempts to match a string against a pattern and returns the matches.
- **`patternSafe() → string`**  
  Escapes special characters in the string so it can be used safely as a pattern.
- **`rep(number) → string`**  
  Repeats the string a specified number of times.
- **`rep(number, string) → string`**  
  Replaces a specified number of occurrences of a pattern in the string.
- **`rep(number, string, string) → string`**  
  Replaces a specified number of occurrences of a pattern in the string, starting from a specified position.
- **`replace() → string`**  
  Replaces all occurrences of a specified pattern in the string.
- **`replace(patern, string, number) → string`**  
  Replaces all occurrences of a specified pattern in the string, up to a specified limit.
- **`reverse() → string`**  
  Reverses the string.
- **`right(number) → string`**  
  Returns the last n characters of the string.
- **`setChar(number, string) → string`**  
  Sets the character at the specified index in the string.
- **`split(string) → table`**  
  Splits the string into substrings based on a specified separator and returns them as a table.
- **`startWith(string) → boolean`**  
  Checks if the string starts with the specified substring.
- **`sub(number) → string`**  
  Returns a substring starting from the specified index.
- **`sub(number, number) → string`**  
  Returns a substring starting from the specified start index to the end index.
- **`toNumber(number) → number`**  
  Converts the string to a number.
- **`trim(string) → string`**  
  Removes specified characters from both ends of the string.
- **`trimLeft(string) → string`**  
  Removes specified characters from the beginning of the string.
- **`trimRight(string) → string`**  
  Removes specified characters from the end of the string.
- **`upper() → string`**  
  Converts the string to uppercase.

#### Type: `patern`

---

## Booleans

The `boolean` type is `true` or `false`.

#### Type: `boolean`

*Aliases:* `bool`

**Operators**

- `!`  (`boolean` → `boolean`)
- `!=`  (`boolean, boolean` → `boolean`)
- `&&`  (`boolean, boolean` → `boolean`)
- `==`  (`boolean, boolean` → `boolean`)
- `?:`  (`boolean, boolean, boolean` → `boolean`)
- `?:`  (`boolean, number, number` → `number`)
- `?:`  (`boolean, string, string` → `string`)
- `||`  (`boolean, boolean` → `boolean`)
- cast `(number) boolean` → `number`

---

## Tables & Arrays

`table` (alias `array`) is E3's key/value container, also used as an array. Values are read with a type, e.g. `t[1, number]`.

#### Type: `table`

*Aliases:* `array`

**Constructors**

- `new table()`
- `new table(...)`

**Operators**

- `!=`  (`table, table` → `boolean`)
- `#`  (`table` → `number`)
- `==`  (`table, table` → `boolean`)

**Methods**

- **`contains(type) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(constraint) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(recipientfilter) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(canvas) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(_e2t) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(find) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(error) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(matrix2) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(matrix3) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(matrix4) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(void) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(bone) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(patern) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(rangerdata) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(sound) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(date) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(stream) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(vector2) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(variant) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(wirelink) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(angle) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(boolean) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(color) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(entity) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(function) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(hologram) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(number) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(player) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(quaternion) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(string) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(table) → boolean`**  
  Returns true if the value is present on the table.
- **`contains(vector) → boolean`**  
  Returns true if the value is present on the table.
- **`exists(entity) → boolean`**  
  Returns true if ta value is present on the table at index.
- **`exists(hologram) → boolean`**  
  Returns true if ta value is present on the table at index.
- **`exists(number) → boolean`**  
  Returns true if ta value is present on the table at index.
- **`exists(player) → boolean`**  
  Returns true if ta value is present on the table at index.
- **`exists(string) → boolean`**  
  Returns true if ta value is present on the table at index.
- **`insert(number, type) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, constraint) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, recipientfilter) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, canvas) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, _e2t) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, find) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, error) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, matrix2) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, matrix3) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, matrix4) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, void) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, bone) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, patern) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, rangerdata) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, sound) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, date) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, stream) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, vector2) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, variant) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, wirelink) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, angle) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, boolean) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, color) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, entity) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, function) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, hologram) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, number) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, player) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, quaternion) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, string) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, table) → void`**  
  Inserts a value onto the table at index.
- **`insert(number, vector) → void`**  
  Inserts a value onto the table at index.
- **`keys() → table`**  
  Returns a table containing all keys on the table.
- **`popangle() → angle`**  
  Removes and returns the last value from the table.
- **`popbone() → bone`**  
  Removes and returns the last value from the table.
- **`popboolean() → boolean`**  
  Removes and returns the last value from the table.
- **`popcanvas() → canvas`**  
  Removes and returns the last value from the table.
- **`popcolor() → color`**  
  Removes and returns the last value from the table.
- **`popconstraint() → constraint`**  
  Removes and returns the last value from the table.
- **`popdate() → date`**  
  Removes and returns the last value from the table.
- **`pope2.table() → _e2t`**  
  Removes and returns the last value from the table.
- **`popentity() → entity`**  
  Removes and returns the last value from the table.
- **`poperror() → error`**  
  Removes and returns the last value from the table.
- **`popfind() → find`**  
  Removes and returns the last value from the table.
- **`popfunction() → function`**  
  Removes and returns the last value from the table.
- **`pophologram() → hologram`**  
  Removes and returns the last value from the table.
- **`popmatrix2() → matrix2`**  
  Removes and returns the last value from the table.
- **`popmatrix3() → matrix3`**  
  Removes and returns the last value from the table.
- **`popmatrix4() → matrix4`**  
  Removes and returns the last value from the table.
- **`popnumber() → number`**  
  Removes and returns the last value from the table.
- **`poppatern() → patern`**  
  Removes and returns the last value from the table.
- **`popplayer() → player`**  
  Removes and returns the last value from the table.
- **`popquaternion() → quaternion`**  
  Removes and returns the last value from the table.
- **`poprangerdata() → rangerdata`**  
  Removes and returns the last value from the table.
- **`poprecipientfilter() → recipientfilter`**  
  Removes and returns the last value from the table.
- **`popsound() → sound`**  
  Removes and returns the last value from the table.
- **`popstream() → stream`**  
  Removes and returns the last value from the table.
- **`popstring() → string`**  
  Removes and returns the last value from the table.
- **`poptable() → table`**  
  Removes and returns the last value from the table.
- **`poptype() → type`**  
  Removes and returns the last value from the table.
- **`popvariant() → variant`**  
  Removes and returns the last value from the table.
- **`popvector() → vector`**  
  Removes and returns the last value from the table.
- **`popvector2() → vector2`**  
  Removes and returns the last value from the table.
- **`popvoid() → void`**  
  Removes and returns the last value from the table.
- **`popwirelink() → wirelink`**  
  Removes and returns the last value from the table.
- **`push(type) → void`**  
  Pushes a value onto the table.
- **`push(constraint) → void`**  
  Pushes a value onto the table.
- **`push(recipientfilter) → void`**  
  Pushes a value onto the table.
- **`push(canvas) → void`**  
  Pushes a value onto the table.
- **`push(_e2t) → void`**  
  Pushes a value onto the table.
- **`push(find) → void`**  
  Pushes a value onto the table.
- **`push(error) → void`**  
  Pushes a value onto the table.
- **`push(matrix2) → void`**  
  Pushes a value onto the table.
- **`push(matrix3) → void`**  
  Pushes a value onto the table.
- **`push(matrix4) → void`**  
  Pushes a value onto the table.
- **`push(void) → void`**  
  Pushes a value onto the table.
- **`push(bone) → void`**  
  Pushes a value onto the table.
- **`push(patern) → void`**  
  Pushes a value onto the table.
- **`push(rangerdata) → void`**  
  Pushes a value onto the table.
- **`push(sound) → void`**  
  Pushes a value onto the table.
- **`push(date) → void`**  
  Pushes a value onto the table.
- **`push(stream) → void`**  
  Pushes a value onto the table.
- **`push(vector2) → void`**  
  Pushes a value onto the table.
- **`push(variant) → void`**  
  Pushes a value onto the table.
- **`push(wirelink) → void`**  
  Pushes a value onto the table.
- **`push(angle) → void`**  
  Pushes a value onto the table.
- **`push(boolean) → void`**  
  Pushes a value onto the table.
- **`push(color) → void`**  
  Pushes a value onto the table.
- **`push(entity) → void`**  
  Pushes a value onto the table.
- **`push(function) → void`**  
  Pushes a value onto the table.
- **`push(hologram) → void`**  
  Pushes a value onto the table.
- **`push(number) → void`**  
  Pushes a value onto the table.
- **`push(player) → void`**  
  Pushes a value onto the table.
- **`push(quaternion) → void`**  
  Pushes a value onto the table.
- **`push(string) → void`**  
  Pushes a value onto the table.
- **`push(table) → void`**  
  Pushes a value onto the table.
- **`push(vector) → void`**  
  Pushes a value onto the table.
- **`shiftangle() → angle`**  
      Removes and returns the first angle from the table.
- **`shiftbone() → bone`**  
      Removes and returns the first bone from the table.
- **`shiftboolean() → boolean`**  
      Removes and returns the first boolean value from the table.
- **`shiftcanvas() → canvas`**  
      Removes and returns the first canvas from the table.
- **`shiftcolor() → color`**  
      Removes and returns the first color from the table.
- **`shiftconstraint() → constraint`**  
  Removes and returns the first constraint from the table.
- **`shiftdate() → date`**  
      Removes and returns the first date from the table.
- **`shifte2.table() → _e2t`**  
  Removes and returns the first E2 table from the table.
- **`shiftentity() → entity`**  
      Removes and returns the first entity from the table.
- **`shifterror() → error`**  
      Removes and returns the first error from the table.
- **`shiftfind() → find`**  
      Removes and returns the first find result from the table.
- **`shiftfunction() → function`**  
      Removes and returns the first function from the table.
- **`shifthologram() → hologram`**  
      Removes and returns the first hologram from the table.
- **`shiftmatrix2() → matrix2`**  
      Removes and returns the first 2x2 matrix from the table.
- **`shiftmatrix3() → matrix3`**  
      Removes and returns the first 3x3 matrix from the table.
- **`shiftmatrix4() → matrix4`**  
      Removes and returns the first 4x4 matrix from the table.
- **`shiftnumber() → number`**  
      Removes and returns the first number from the table.
- **`shiftpatern() → patern`**  
      Removes and returns the first pattern from the table.
- **`shiftplayer() → player`**  
      Removes and returns the first player from the table.
- **`shiftquaternion() → quaternion`**  
      Removes and returns the first quaternion from the table.
- **`shiftrangerdata() → rangerdata`**  
  Removes and returns the first range data from the table.
- **`shiftrecipientfilter() → recipientfilter`**  
  Removes and returns the first recipient filter from the table.
- **`shiftsound() → sound`**  
      Removes and returns the first sound from the table.
- **`shiftstream() → stream`**  
      Removes and returns the first stream from the table.
- **`shiftstring() → string`**  
      Removes and returns the first string from the table.
- **`shifttable() → table`**  
      Removes and returns the first table from the table.
- **`shifttype() → type`**  
      Removes and returns the first type from the table.
- **`shiftvariant() → variant`**  
      Removes and returns the first variant from the table.
- **`shiftvector() → vector`**  
      Removes and returns the first vector from the table.
- **`shiftvector2() → vector2`**  
      Removes and returns the first 2D vector from the table.
- **`shiftvoid() → void`**  
      Removes and returns the first void value from the table.
- **`shiftwirelink() → wirelink`**  
      Removes and returns the first wirelink from the table.
- **`type(entity) → type`**  
  Returns the class type of the value stored at index.
- **`type(hologram) → type`**  
  Returns the class type of the value stored at index.
- **`type(number) → type`**  
  Returns the class type of the value stored at index.
- **`type(player) → type`**  
  Returns the class type of the value stored at index.
- **`type(string) → type`**  
  Returns the class type of the value stored at index.
- **`unshiftangle(angle) → void`**  
  Adds an angle to the beginning of the table.
- **`unshiftbone(bone) → void`**  
  Adds a bone to the beginning of the table.
- **`unshiftboolean(boolean) → void`**  
  Adds a boolean value to the beginning of the table.
- **`unshiftcanvas(canvas) → void`**  
  Adds a canvas to the beginning of the table.
- **`unshiftcolor(color) → void`**  
  Adds a color to the beginning of the table.
- **`unshiftconstraint(constraint) → void`**  
  Adds a constraint to the beginning of the table.
- **`unshiftdate(date) → void`**  
  Adds a date to the beginning of the table.
- **`unshifte2.table(_e2t) → void`**  
  Adds a E2 table to the beginning of the table.
- **`unshiftentity(entity) → void`**  
  Adds an entity to the beginning of the table.
- **`unshifterror(error) → void`**  
  Adds an error to the beginning of the table.
- **`unshiftfind(find) → void`**  
  Adds a find result to the beginning of the table.
- **`unshiftfunction(function) → void`**  
  Adds a function to the beginning of the table.
- **`unshifthologram(hologram) → void`**  
  Adds a hologram to the beginning of the table.
- **`unshiftmatrix2(matrix2) → void`**  
  Adds a 2x2 matrix to the beginning of the table.
- **`unshiftmatrix3(matrix3) → void`**  
  Adds a 3x3 matrix to the beginning of the table.
- **`unshiftmatrix4(matrix4) → void`**  
  Adds a 4x4 matrix to the beginning of the table.
- **`unshiftnumber(number) → void`**  
  Adds a number to the beginning of the table.
- **`unshiftpatern(patern) → void`**  
  Adds a pattern to the beginning of the table.
- **`unshiftplayer(player) → void`**  
  Adds a player to the beginning of the table.
- **`unshiftquaternion(quaternion) → void`**  
  Adds a quaternion to the beginning of the table.
- **`unshiftrangerdata(rangerdata) → void`**  
  Adds range data to the beginning of the table.
- **`unshiftrecipientfilter(recipientfilter) → void`**  
  Adds a recipient filter to the beginning of the table.
- **`unshiftsound(sound) → void`**  
  Adds a sound to the beginning of the table.
- **`unshiftstream(stream) → void`**  
  Adds a stream to the beginning of the table.
- **`unshiftstring(string) → void`**  
  Adds a string to the beginning of the table.
- **`unshifttable(table) → void`**  
  Adds a table to the beginning of the table.
- **`unshifttype(type) → void`**  
  Adds a type to the beginning of the table.
- **`unshiftvariant(variant) → void`**  
  Adds a variant to the beginning of the table.
- **`unshiftvector(vector) → void`**  
  Adds a vector to the beginning of the table.
- **`unshiftvector2(vector2) → void`**  
  Adds a 2D vector to the beginning of the table.
- **`unshiftvoid(void) → void`**  
  Adds a void value to the beginning of the table.
- **`unshiftwirelink(wirelink) → void`**  
  Adds a wirelink to the beginning of the table.
- **`values() → table`**  
  Returns a tables contansing all values on the table.

---

## Vectors

`vector` is a 3D vector. Vector interpolation helpers such as `lerpVector` live in the `math` library.

#### Type: `vector`

**Constructors**

- `new vector()`
- `new vector(number)`
- `new vector(quaternion)`
- `new vector(number, number, number)`

**Attributes**

- **`.x`** → `number`  
  The X component of the vector (the east/west axis in world space).
- **`.y`** → `number`  
  The Y component of the vector (the north/south axis in world space).
- **`.z`** → `number`  
  The Z component of the vector (the vertical up/down axis in world space).

**Operators**

- `!`  (`vector` → `boolean`)
- `!=`  (`vector, vector` → `boolean`)
- `$`  (`vector` → `vector`)
- `*`  (`vector, number` → `vector`)
- `*`  (`vector, quaternion` → `quaternion`)
- `*`  (`vector, vector` → `vector`)
- `+`  (`vector, number` → `vector`)
- `+`  (`vector, vector` → `vector`)
- `-`  (`vector, number` → `vector`)
- `-`  (`vector, vector` → `vector`)
- `- (unary)`  (`vector` → `vector`)
- `/`  (`vector, number` → `vector`)
- `/`  (`vector, vector` → `vector`)
- `<`  (`vector, vector` → `boolean`)
- `<=`  (`vector, vector` → `boolean`)
- `==`  (`vector, vector` → `boolean`)
- `>`  (`vector, vector` → `boolean`)
- `>=`  (`vector, vector` → `boolean`)

**Methods**

- **`ceil() → void`**  
  Returns a new vector with each component rounded up to the nearest integer.
- **`clone() → vector`**  
  Returns a copy of the vector.
- **`cross(vector) → vector`**  
  Calculates the cross product of two vectors.
- **`dehomogenized() → vector2`**  
  Returns the dehomogenized form of a vector.
- **`distance(vector) → number`**  
  Calculates the distance between two vectors.
- **`dot(vector) → number`**  
  Calculates the dot product of two vectors.
- **`floor() → void`**  
  Returns a new vector with each component rounded down to the nearest integer.
- **`getX() → number`**  
  Returns the x-component of the vector.
- **`getXYZ() → number`**  
  Returns the x, y, and z components of the vector as separate values.
- **`getY() → number`**  
  Returns the y-component of the vector.
- **`getZ() → number`**  
  Returns the z-component of the vector.
- **`length() → number`**  
  Calculates the length of the vector.
- **`lengthSqr() → number`**  
  Calculates the squared length of the vector.
- **`normalized() → vector`**  
  Returns a normalized version of the vector.
- **`rotate(angle) → void`**  
  Rotates the vector by the given angle.
- **`rotate(number, number, number) → vector`**  
  Rotates the vector around the specified axis.
- **`rotateAroundAxis(vector, number) → vector`**  
  Rotates the vector around the given axis by the specified angle.
- **`rotated(angle) → vector`**  
  Returns a new vector rotated by the given angle.
- **`round() → void`**  
  Returns a new vector with each component rounded to the nearest integer.
- **`round(number) → void`**  
  Rounds each component of the vector to the specified number of decimal places.
- **`setX(number) → void`**  
  Sets the x-component of the vector.
- **`setY(number) → void`**  
  Sets the y-component of the vector.
- **`setZ(number) → void`**  
  Sets the z-component of a vector to the given value.
- **`toAngle() → angle`**  
  Converts a vector to an angle.
- **`toColor() → color`**  
  Converts a vector to a color.
- **`toDeg() → vector`**  
  Converts a vector from radians to degrees.
- **`toRad() → vector`**  
  Converts a vector from degrees to radians.
- **`toScreen() → vector2`**  
  Converts a vector to screen coordinates.
- **`unpack() → number`**  
  Returns the x, y, and z components of a vector as separate values.
- **`withX(number) → vector`**  
  Creates a new vector with the x-component set to the given value.
- **`withY(number) → vector`**  
  Creates a new vector with the y-component set to the given value.
- **`withZ(number) → vector`**  
  Creates a new vector with the z-component set to the given value.

---

## 2D Vectors

`vector2` is a 2D vector, used mostly for screen coordinates when rendering.

#### Type: `vector2`

**Constructors**

- `new vector2()`
- `new vector2(number)`
- `new vector2(number, number)`

**Attributes**

- **`.x`** → `number`  
  The X (horizontal) component of the 2D vector, usually measured in pixels when used for rendering.
- **`.y`** → `number`  
  The Y (vertical) component of the 2D vector, usually measured in pixels when used for rendering.

**Operators**

- `!`  (`vector2` → `boolean`)
- `!=`  (`vector2, vector2` → `boolean`)
- `$`  (`vector2` → `vector2`)
- `*`  (`vector2, number` → `vector2`)
- `*`  (`vector2, vector2` → `vector2`)
- `+`  (`vector2, number` → `vector2`)
- `+`  (`vector2, vector2` → `vector2`)
- `-`  (`vector2, number` → `vector2`)
- `-`  (`vector2, vector2` → `vector2`)
- `- (unary)`  (`vector2` → `vector`)
- `/`  (`vector2, number` → `vector2`)
- `/`  (`vector2, vector2` → `vector2`)
- `<`  (`vector2, vector2` → `boolean`)
- `<=`  (`vector2, vector2` → `boolean`)
- `==`  (`vector2, vector2` → `boolean`)
- `>`  (`vector2, vector2` → `boolean`)
- `>=`  (`vector2, vector2` → `boolean`)

**Methods**

- **`ceil() → void`**  
  Rounds each component of the 2D vector up to the next whole number, in place.
- **`clone() → vector2`**  
  Returns a copy of the 2D vector.
- **`distance(vector2) → number`**  
  Returns the distance between this 2D vector and another.
- **`floor() → void`**  
  Rounds each component of the 2D vector down to the previous whole number, in place.
- **`getX() → number`**  
  Returns the X component of the 2D vector.
- **`getXY() → number`**  
  Returns the X and Y components of the 2D vector.
- **`getY() → number`**  
  Returns the Y component of the 2D vector.
- **`length() → number`**  
  Returns the length (magnitude) of the 2D vector.
- **`lengthSqr(vector2) → number`**  
  Returns the squared length of the 2D vector (cheaper than length as it avoids a square root).
- **`normalized() → vector2`**  
  Returns a unit-length copy of the 2D vector.
- **`round() → void`**  
  Rounds each component of the 2D vector to the nearest whole number, in place.
- **`round(number) → void`**  
  Rounds each component of the 2D vector to the given number of decimal places, in place.
- **`setX(number) → void`**  
  Sets the X component of the 2D vector.
- **`setY(number) → void`**  
  Sets the Y component of the 2D vector.
- **`withX(number) → vector2`**  
  Returns a copy of the 2D vector with the X component replaced.
- **`withY(number) → vector2`**  
  Returns a copy of the 2D vector with the Y component replaced.

---

## Angles

`angle` is an orientation of pitch, yaw and roll (in degrees).

#### Type: `angle`

**Constructors**

- `new angle()`
- `new angle(number)`
- `new angle(number, number, number)`

**Attributes**

- **`.p`** → `number`  
  The pitch of the angle in degrees. Pitch tilts the orientation up and down (rotation about the right axis).
- **`.r`** → `number`  
  The roll of the angle in degrees. Roll banks the orientation like an aircraft rolling (rotation about the forward axis).
- **`.y`** → `number`  
  The yaw of the angle in degrees. Yaw turns the orientation left and right (rotation about the up axis).

**Operators**

- `!`  (`angle` → `boolean`)
- `!=`  (`angle, angle` → `boolean`)
- `$`  (`angle` → `angle`)
- `*`  (`angle, angle` → `angle`)
- `*`  (`angle, number` → `angle`)
- `+`  (`angle, angle` → `angle`)
- `-`  (`angle, angle` → `angle`)
- `- (unary)`  (`angle` → `angle`)
- `/`  (`angle, angle` → `angle`)
- `/`  (`angle, number` → `angle`)
- `<`  (`angle, angle` → `boolean`)
- `<=`  (`angle, angle` → `boolean`)
- `==`  (`angle, angle` → `boolean`)
- `>`  (`angle, angle` → `boolean`)
- `>=`  (`angle, angle` → `boolean`)
- cast `(vector) angle` → `vector`

**Methods**

- **`ceil() → void`**  
  Rounds each component of the angle up to the next whole number, in place.
- **`floor() → void`**  
  Rounds each component of the angle down to the previous whole number, in place.
- **`forward() → vector`**  
  Returns the forward direction of the angle as a unit vector.
- **`getP() → number`**  
  Returns the pitch component of the angle.
- **`getPYR() → number`**  
  Returns the pitch, yaw and roll components of the angle.
- **`getR() → number`**  
  Returns the roll component of the angle.
- **`getY() → number`**  
  Returns the yaw component of the angle.
- **`isValid() → boolean`**  
  Returns whether the angle contains only valid numbers.
- **`normalize() → void`**  
  Wraps each component of the angle into the range -180 to 180, in place.
- **`right() → vector`**  
  Returns the right direction of the angle as a unit vector.
- **`rotate(vector, number) → void`**  
  Rotates the angle about the given axis by the given number of degrees, in place.
- **`round() → void`**  
  Rounds each component of the angle to the nearest whole number, in place.
- **`round(number) → void`**  
  Rounds each component of the angle to the given number of decimal places, in place.
- **`setP(number) → void`**  
  Sets the pitch component of the angle.
- **`setR(number) → void`**  
  Sets the roll component of the angle.
- **`setY(number) → void`**  
  Sets the yaw component of the angle.
- **`unpack() → number`**  
  Returns the pitch, yaw and roll of the angle as three separate numbers.
- **`up() → vector`**  
  Returns the up direction of the angle as a unit vector.
- **`withP(number) → angle`**  
  Returns a copy of the angle with the pitch replaced by the given value.
- **`withR(number) → angle`**  
  Returns a copy of the angle with the roll replaced by the given value.
- **`withY(number) → angle`**  
  Returns a copy of the angle with the yaw replaced by the given value.

---

## Colours

`color` (alias `colour`) is an RGBA colour. The `clr` library adds HSV conversion and randomisation helpers.

#### Library: `clr`

- **`clr.colorAlpha(color, number) → color`**  
  Returns a copy of the colour with its alpha (opacity) replaced by the given value (0-255).
- **`clr.colorRand(color, number) → color`**  
  Returns a copy of the colour with randomized red, green and blue channels. If the alpha argument is true, alpha is randomized too.
- **`clr.colorToHSV(color) → number`**  
  Converts an RGB colour into hue, saturation and value components.
- **`clr.hsvToColor(number, number, number) → color`**  
  Builds a colour from hue (0-360), saturation (0-1) and value (0-1).

#### Type: `color`

*Aliases:* `colour`

**Constructors**

- `new color()`
- `new color(number)`
- `new color(number, number, number)`
- `new color(number, number, number, number)`

**Attributes**

- **`.a`** → `number`  
  The alpha (opacity) channel of the colour, in the range 0-255. 0 is fully transparent and 255 is fully opaque.
- **`.b`** → `number`  
  The blue channel of the colour, in the range 0-255.
- **`.g`** → `number`  
  The green channel of the colour, in the range 0-255.
- **`.r`** → `number`  
  The red channel of the colour, in the range 0-255.

**Operators**

- `!`  (`color` → `boolean`)
- `!=`  (`color, color` → `boolean`)
- `*`  (`color, color` → `color`)
- `*`  (`color, number` → `color`)
- `+`  (`color, color` → `color`)
- `+`  (`color, number` → `color`)
- `-`  (`color, color` → `color`)
- `-`  (`color, number` → `color`)
- `- (unary)`  (`color` → `color`)
- `/`  (`color, color` → `color`)
- `/`  (`color, number` → `color`)
- `<`  (`color, color` → `boolean`)
- `<=`  (`color, color` → `boolean`)
- `==`  (`color, color` → `boolean`)
- `>`  (`color, color` → `boolean`)
- `>=`  (`color, color` → `boolean`)
- cast `(vector) color` → `vector`

**Methods**

- **`ceil() → void`**  
  Rounds each channel of the colour up to the next whole number, in place.
- **`floor() → void`**  
  Rounds each channel of the colour down to the previous whole number, in place.
- **`getA() → number`**  
  Returns the alpha (opacity) channel of the colour.
- **`getB() → number`**  
  Returns the blue channel of the colour.
- **`getG() → number`**  
  Returns the green channel of the colour.
- **`getR() → number`**  
  Returns the red channel of the colour.
- **`getRGB() → number`**  
  Returns the red, green and blue channels of the colour.
- **`getRGBA() → number`**  
  Returns the red, green, blue and alpha channels of the colour.
- **`round() → void`**  
  Rounds each channel of the colour to the nearest whole number, in place.
- **`round(number) → void`**  
  Rounds each channel of the colour to the given number of decimal places, in place.
- **`setA(number) → void`**  
  Sets the alpha (opacity) channel of the colour.
- **`setB(number) → void`**  
  Sets the blue channel of the colour.
- **`setG(number) → void`**  
  Sets the green channel of the colour.
- **`setR(number) → void`**  
  Sets the red channel of the colour.
- **`unpack() → number`**  
  Returns the red, green, blue and alpha channels of the colour as separate numbers.
- **`withA(number) → color`**  
  Returns a copy of the colour with the alpha channel replaced.
- **`withB(number) → color`**  
  Returns a copy of the colour with the blue channel replaced.
- **`withG(number) → color`**  
  Returns a copy of the colour with the green channel replaced.
- **`withR(number) → color`**  
  Returns a copy of the colour with the red channel replaced.

---

## Quaternions

`quaternion` represents a rotation without the gimbal problems of angles. The `quaternion` library builds and interpolates them.

#### Library: `quaternion`

- **`quaternion.nlerp(quaternion, quaternion, number) → quaternion`**  
  Normalized linear interpolation between two quaternions. The last argument is the fraction (0-1); faster than slerp but less constant in speed.
- **`quaternion.qRotation(vector) → quaternion`**  
  Returns a quaternion representing a rotation around the given axis vector, by the length of that vector in degrees.
- **`quaternion.qRotation(vector, number) → quaternion`**  
  Returns a quaternion representing a rotation of the given number of degrees around the given axis vector.
- **`quaternion.qi() → quaternion`**  
  Returns the quaternion i (0,1,0,0), the first imaginary unit.
- **`quaternion.qi(number) → quaternion`**  
  Returns the quaternion i scaled by the given number (0,n,0,0).
- **`quaternion.qj() → quaternion`**  
  Returns the quaternion j (0,0,1,0), the second imaginary unit.
- **`quaternion.qj(number) → quaternion`**  
  Returns the quaternion j scaled by the given number (0,0,n,0).
- **`quaternion.qk() → quaternion`**  
  Returns the quaternion k (0,0,0,1), the third imaginary unit.
- **`quaternion.qk(number) → quaternion`**  
  Returns the quaternion k scaled by the given number (0,0,0,n).
- **`quaternion.rotationAngle(quaternion) → angle`**  
  Returns the rotation angle (in degrees) represented by the quaternion.
- **`quaternion.rotationAxis(quaternion) → vector`**  
  Returns the axis of rotation represented by the quaternion, as a unit vector.
- **`quaternion.rotationVector(quaternion) → vector`**  
  Returns the rotation of the quaternion as an axis vector whose length is the angle in degrees.
- **`quaternion.slerp(quaternion, quaternion, number) → quaternion`**  
  Spherical linear interpolation between two quaternions, giving smooth constant-speed rotation. The last argument is the fraction (0-1).

#### Type: `quaternion`

*Aliases:* `quat`

**Constructors**

- `new quaternion()`
- `new quaternion(angle)`
- `new quaternion(entity)`
- `new quaternion(number)`
- `new quaternion(vector)`
- `new quaternion(vector, vector)`
- `new quaternion(number, number, number, number)`

**Attributes**

- **`.i`** → `number`  
  The i component of the quaternion (the first imaginary/vector part).
- **`.j`** → `number`  
  The j component of the quaternion (the second imaginary/vector part).
- **`.k`** → `number`  
  The k component of the quaternion (the third imaginary/vector part).
- **`.r`** → `number`  
  The real (scalar) component of the quaternion.

**Operators**

- `!=`  (`quaternion, quaternion` → `boolean`)
- `*`  (`quaternion, number` → `quaternion`)
- `*`  (`quaternion, quaternion` → `quaternion`)
- `*`  (`quaternion, vector` → `quaternion`)
- `+`  (`quaternion, number` → `quaternion`)
- `+`  (`quaternion, quaternion` → `quaternion`)
- `-`  (`quaternion, number` → `quaternion`)
- `-`  (`quaternion, quaternion` → `quaternion`)
- `/`  (`quaternion, number` → `quaternion`)
- `/`  (`quaternion, quaternion` → `quaternion`)
- `==`  (`quaternion, quaternion` → `boolean`)
- `^`  (`quaternion, number` → `quaternion`)

**Methods**

- **`abs() → quaternion`**  
  Returns the absolute value of the quaternion.
- **`clone() → quaternion`**  
  Returns a copy of the quaternion.
- **`conj() → quaternion`**  
  Returns the conjugate of the quaternion.
- **`dot(quaternion) → number`**  
  Computes the dot product of two quaternions.
- **`exp() → quaternion`**  
  Computes the exponential of the quaternion.
- **`forward() → vector`**  
  Returns the forward vector from the quaternion.
- **`getI() → number`**  
  Retrieves the I component of the quaternion.
- **`getJ() → number`**  
  Retrieves the J component of the quaternion.
- **`getK() → number`**  
  Retrieves the K component of the quaternion.
- **`getR() → number`**  
  Retrieves the real part of the quaternion.
- **`inv() → quaternion`**  
  Computes the inverse of the quaternion.
- **`log() → quaternion`**  
  Computes the natural logarithm of the quaternion.
- **`normalized() → quaternion`**  
  Returns the normalized form of the quaternion.
- **`qMod() → quaternion`**  
  Computes the quaternion modulus.
- **`right() → vector`**  
  Returns the right vector from the quaternion.
- **`setI(number) → void`**  
  Sets the I component of the quaternion.
- **`setJ(number) → void`**  
  Sets the J component of the quaternion.
- **`setK(number) → void`**  
  Sets the K component of the quaternion.
- **`setR(number) → void`**  
  Sets the real part of the quaternion.
- **`toAngle() → angle`**  
  Converts the quaternion to an angle.
- **`toString() → void`**  
  Converts the quaternion to a string representation.
- **`up() → vector`**  
  Returns the up vector from the quaternion.
- **`vec() → vector`**  
  Returns the vector part of the quaternion.
- **`withI() → quaternion`**  
  Sets the I component of the quaternion and returns a new quaternion.
- **`withJ() → quaternion`**  
  Sets the J component of the quaternion and returns a new quaternion.
- **`withK() → quaternion`**  
  Sets the K component of the quaternion and returns a new quaternion.
- **`withR() → quaternion`**  
  Sets the R component of the quaternion and returns a new quaternion.

---

## Matrices

2x2, 3x3 and 4x4 matrices, with a library of operations for each.

#### Library: `matrix2`

- **`matrix2.adj2(matrix2) → number`**  
  Returns the adjugate (classical adjoint) of a 2x2 matrix.
- **`matrix2.det2(matrix2) → number`**  
  Returns the determinant of a 2x2 matrix.
- **`matrix2.diagonal2(matrix2) → vector2`**  
  Returns the diagonal of a 2x2 matrix as a 2D vector.
- **`matrix2.trace2(matrix2) → number`**  
  Returns the trace (sum of the diagonal elements) of a 2x2 matrix.
- **`matrix2.transpose2(matrix2) → number`**  
  Returns the transpose of a 2x2 matrix (rows and columns swapped).

#### Library: `matrix3`

- **`matrix3.adj3(matrix3) → matrix3`**  
  Returns the adjugate (classical adjoint) of a 3x3 matrix.
- **`matrix3.det3(matrix3) → number`**  
  Returns the determinant of a 3x3 matrix.
- **`matrix3.diagonal3(matrix3) → vector`**  
  Returns the diagonal of a 3x3 matrix as a vector.
- **`matrix3.mRotation(vector, number) → matrix3`**  
  Returns a 3x3 rotation matrix for a rotation of the given number of degrees around the given axis vector.
- **`matrix3.trace3(matrix3) → number`**  
  Returns the trace (sum of the diagonal elements) of a 3x3 matrix.
- **`matrix3.transpose3(matrix3) → matrix3`**  
  Returns the transpose of a 3x3 matrix (rows and columns swapped).

#### Library: `matrix4`

- **`matrix4.inverseA(matrix4) → matrix4`**  
  Returns the inverse of a 4x4 affine transformation matrix.
- **`matrix4.trace4(matrix4) → number`**  
  Returns the trace (sum of the diagonal elements) of a 4x4 matrix.
- **`matrix4.transpose4(matrix4) → matrix4`**  
  Returns the transpose of a 4x4 matrix (rows and columns swapped).

#### Type: `matrix2`

**Constructors**

- `new matrix2()`
- `new matrix2(vector2, vector2)`
- `new matrix2(number, number, number, number)`

**Operators**

- `!=`  (`matrix2, matrix2` → `boolean`)
- `*`  (`matrix2, matrix2` → `matrix2`)
- `*`  (`matrix2, number` → `matrix2`)
- `*`  (`matrix2, vector2` → `vector2`)
- `+`  (`matrix2, matrix2` → `matrix2`)
- `-`  (`matrix2, matrix2` → `matrix2`)
- `- (unary)`  (`matrix2` → `matrix2`)
- `/`  (`matrix2, number` → `matrix2`)
- `==`  (`matrix2, matrix2` → `boolean`)
- `^`  (`matrix2, number` → `matrix2`)

**Methods**

- **`column(number) → vector2`**  
  Returns the given column of the 2x2 matrix as a 2D vector.
- **`element(number, number) → number`**  
  Returns the element of the 2x2 matrix at the given row and column.
- **`row(number) → vector2`**  
  Returns the given row of the 2x2 matrix as a 2D vector.
- **`setColumn(number, vector2) → matrix2`**  
  Returns a copy of the 2x2 matrix with the given column replaced by a 2D vector.
- **`setColumn(number, number, number) → matrix2`**  
  Returns a copy of the 2x2 matrix with the given column replaced by two numbers.
- **`setElement(number, number, number) → matrix2`**  
  Returns a copy of the 2x2 matrix with the element at the given row and column replaced.
- **`setRow(number, vector2) → matrix2`**  
  Returns a copy of the 2x2 matrix with the given row replaced by a 2D vector.
- **`setRow(number, number, number) → matrix2`**  
  Returns a copy of the 2x2 matrix with the given row replaced by two numbers.
- **`swapColumns() → matrix2`**  
  Returns a copy of the 2x2 matrix with its two columns swapped.
- **`swapElement(number, number, number, number) → matrix2`**  
  Returns a copy of the 2x2 matrix with two elements swapped.
- **`swapRows() → matrix2`**  
  Returns a copy of the 2x2 matrix with its two rows swapped.
- **`toString() → string`**  
  Returns a readable string representation of the 2x2 matrix.

#### Type: `matrix3`

**Constructors**

- `new matrix3()`
- `new matrix3(angle)`
- `new matrix3(entity)`
- `new matrix3(matrix2)`
- `new matrix3(quaternion)`
- `new matrix3(vector, vector, vector)`
- `new matrix3(number, number, number, number, number, number, number, number, number)`

**Operators**

- `!=`  (`matrix3, matrix3` → `boolean`)
- `*`  (`matrix3, matrix3` → `matrix3`)
- `*`  (`matrix3, number` → `matrix3`)
- `*`  (`matrix3, vector` → `vector`)
- `+`  (`matrix3, matrix3` → `matrix3`)
- `-`  (`matrix3, matrix3` → `matrix3`)
- `- (unary)`  (`matrix3` → `matrix3`)
- `/`  (`matrix3, number` → `matrix3`)
- `==`  (`matrix3, matrix3` → `boolean`)
- `^`  (`matrix3, number` → `matrix3`)

**Methods**

- **`column(number) → vector`**  
  Returns the given column of the 3x3 matrix as a vector.
- **`element(number, number) → number`**  
  Returns the element of the 3x3 matrix at the given row and column.
- **`getX() → vector`**  
  Returns the X axis (first column) of the 3x3 matrix as a vector.
- **`getY() → vector`**  
  Returns the Y axis (second column) of the 3x3 matrix as a vector.
- **`getZ() → vector`**  
  Returns the Z axis (third column) of the 3x3 matrix as a vector.
- **`row(number) → vector`**  
  Returns the given row of the 3x3 matrix as a vector.
- **`setColumn(number, number, number, number) → matrix3`**  
  Returns a copy of the 3x3 matrix with the given column replaced by three numbers.
- **`setColumn(number, vector) → matrix3`**  
  Returns a copy of the 3x3 matrix with the given column replaced by a vector.
- **`setDiagonal(number, number, number) → matrix3`**  
  Returns a copy of the 3x3 matrix with its diagonal set from three numbers.
- **`setDiagonal(vector) → matrix3`**  
  Returns a copy of the 3x3 matrix with its diagonal set from a vector.
- **`setElement(number, number, number) → matrix3`**  
  Returns a copy of the 3x3 matrix with the element at the given row and column replaced.
- **`setRow(number, number, number, number) → matrix3`**  
  Returns a copy of the 3x3 matrix with the given row replaced by three numbers.
- **`setRow(number, vector) → matrix3`**  
  Returns a copy of the 3x3 matrix with the given row replaced by a vector.
- **`swapColumns(number, number) → matrix3`**  
  Returns a copy of the 3x3 matrix with the two given columns swapped.
- **`swapElement(number, number, number, number) → matrix3`**  
  Returns a copy of the 3x3 matrix with two elements swapped.
- **`swapRows(number, number) → matrix3`**  
  Returns a copy of the 3x3 matrix with the two given rows swapped.
- **`toAngle() → angle`**  
  Returns the rotation represented by the 3x3 matrix as an angle.
- **`toString() → string`**  
  Returns a readable string representation of the 3x3 matrix.

#### Type: `matrix4`

**Constructors**

- `new matrix4()`
- `new matrix4(angle)`
- `new matrix4(entity)`
- `new matrix4(matrix2)`
- `new matrix4(matrix3)`
- `new matrix4(angle, vector)`
- `new matrix4(matrix2, matrix2, matrix2, matrix2)`
- `new matrix4(number, number, number, number, number, number, number, number, number, number, number, number, number, number, number, number)`

**Operators**

- `!=`  (`matrix4, matrix4` → `boolean`)
- `*`  (`matrix4, matrix4` → `matrix4`)
- `*`  (`matrix4, number` → `matrix4`)
- `+`  (`matrix4, matrix4` → `matrix4`)
- `-`  (`matrix4, matrix4` → `matrix4`)
- `- (unary)`  (`matrix4` → `matrix4`)
- `/`  (`matrix4, number` → `matrix4`)
- `==`  (`matrix4, matrix4` → `boolean`)
- `^`  (`matrix4, number` → `matrix4`)

**Methods**

- **`element(number, number) → number`**  
  Returns the element of the 4x4 matrix at the given row and column.
- **`getPos() → vector`**  
  Returns the translation (position) stored in the 4x4 matrix.
- **`getX() → vector`**  
  Returns the X axis of the 4x4 matrix as a vector.
- **`getY() → vector`**  
  Returns the Y axis of the 4x4 matrix as a vector.
- **`getZ() → vector`**  
  Returns the Z axis of the 4x4 matrix as a vector.
- **`setColumn(number, number, number, number, number) → matrix4`**  
  Returns a copy of the 4x4 matrix with the given column replaced by four numbers.
- **`setDiagonal(number, number, number, number) → matrix4`**  
  Returns a copy of the 4x4 matrix with its diagonal set from four numbers.
- **`setElement(number, number) → matrix4`**  
  Returns a copy of the 4x4 matrix with the given element replaced.
- **`setRow(number, number, number, number, number) → matrix4`**  
  Returns a copy of the 4x4 matrix with the given row replaced by four numbers.
- **`swapColumns(number, number) → matrix4`**  
  Returns a copy of the 4x4 matrix with the two given columns swapped.
- **`swapElements(number, number, number, number) → matrix4`**  
  Returns a copy of the 4x4 matrix with two elements swapped.
- **`swapRows(number, number) → matrix4`**  
  Returns a copy of the 4x4 matrix with the two given rows swapped.
- **`toString() → string`**  
  Returns a readable string representation of the 4x4 matrix.

---

## Time & Dates

The `time` library reads clocks and uptime; the `date` type breaks a moment down into year, month, day and so on.

#### Library: `time`

- **`time.curtime() → number`**  
  Returns the server's current uptime in seconds. This advances with the game and is the same across a single tick.
- **`time.frametime() → number`**  
  Returns the time in seconds since the previous frame.
- **`time.now() → number`**  
  Returns the current date and time as a date object.
- **`time.now(date) → number`**  
  Returns a date object for the given unix timestamp.
- **`time.realtime() → number`**  
  Returns the game's real uptime in seconds, to at least four decimal places.
- **`time.systime() → number`**  
  Returns a high-precision system time in seconds, useful for benchmarking.

#### Type: `date`

**Constructors**

- `new date()`
- `new date(boolean)`
- `new date(number)`
- `new date(number, boolean)`

**Attributes**

- **`.day`** → `number`  
  The day-of-month component of the date, in the range 1-31.
- **`.hour`** → `number`  
  The hour component of the date, in 24-hour form (0-23).
- **`.minute`** → `number`  
  The minute component of the date, in the range 0-59.
- **`.month`** → `number`  
  The month component of the date, in the range 1-12.
- **`.second`** → `number`  
  The second component of the date, in the range 0-59.
- **`.year`** → `number`  
  The year component of the date (e.g. 2026).

**Methods**

- **`getDay() → number`**  
  Returns the day-of-month component of the date (1-31).
- **`getHour() → number`**  
  Returns the hour component of the date (0-23).
- **`getMinute() → number`**  
  Returns the minute component of the date (0-59).
- **`getMonth() → number`**  
  Returns the month component of the date (1-12).
- **`getSecond() → number`**  
  Returns the second component of the date (0-59).
- **`getYear() → number`**  
  Returns the year component of the date.
- **`setDate(number, number, number) → void`**  
  Sets the year, month and day of the date at once.
- **`setDay(number) → void`**  
  Sets the day-of-month component of the date (1-31).
- **`setHour(number) → void`**  
  Sets the hour component of the date (0-23).
- **`setMinute(number) → void`**  
  Sets the minute component of the date (0-59).
- **`setMonth(number) → void`**  
  Sets the month component of the date (1-12).
- **`setSecond(number) → void`**  
  Sets the second component of the date (0-59).
- **`setTime(number, number, number) → void`**  
  Sets the hour, minute and second of the date at once.
- **`setYear(number) → void`**  
  Sets the year component of the date.

---

## Entities

`entity` is any entity in the world. Its methods cover position and orientation, physics, constraints, appearance and more. Players and holograms extend this type and inherit every method here.

#### Type: `entity`

**Constructors**

- `new entity(number)`

**Operators**

- `!`  (`entity` → `boolean`)
- `!=`  (`entity, entity` → `boolean`)
- `!=`  (`entity, player` → `boolean`)
- `==`  (`entity, entity` → `boolean`)
- `==`  (`entity, player` → `boolean`)
- cast `(hologram) entity` → `hologram`
- cast `(player) entity` → `player`
- cast `(wirelink) entity` → `wirelink`

**Methods**

- **`Vel() → vector`**  
  Returns the entity's velocity.
- **`VelL() → vector`**  
  Returns the entity's velocity in its own local coordinates.
- **`ang() → angle`**  
  Returns the entity's orientation as an angle.
- **`angVel() → angle`**  
  Returns the entity's angular velocity as an angle, in degrees per second about each local axis.
- **`angVelVector() → vector`**  
  Returns the entity's angular velocity as a vector.
- **`applyAngForce(angle) → void`**  
  Applies an angular (turning) force to the entity's physics object, expressed as an angle.
- **`applyDamage(number) → void`**  
  Deals the given amount of damage to the entity.
- **`applyForce(vector) → void`**  
  Applies a linear force to the entity's physics object, in the direction and magnitude of the vector.
- **`applyOffsetForce(vector) → void`**  
  Applies a force to the entity's physics object offset from its centre of mass, so it spins as well as moves.
- **`applyTorque(vector) → void`**  
  Applies torque to the entity's physics object about the given axis vector.
- **`armor() → number`**  
  Returns the entity's current armor (mainly for players and NPCs).
- **`attachmentAng(number) → angle`**  
  Returns the world angle of the model attachment point with the given index.
- **`attachmentPos(number) → vector`**  
  Returns the world position of the model attachment point with the given index.
- **`attachments() → table`**  
  Returns a table describing the entity model's attachment points.
- **`axis(vector, entity, vector) → void`**  
  Creates an axis constraint between this entity and another entity, at positions local to each.
- **`axis(vector, entity, vector, number) → void`**  
  Creates an axis constraint between this entity and another with the given friction.
- **`axis(vector, entity, vector, number, vector) → void`**  
  Creates an axis constraint between this entity and another with the given friction and rotation axis.
- **`ballsocket(entity, vector) → void`**  
  Creates a ballsocket constraint between this entity and another at a position local to this entity.
- **`ballsocket(entity, vector, number) → void`**  
  Creates a ballsocket constraint between this entity and another with the given friction.
- **`ballsocket(vector, entity, vector, vector, vector, number) → void`**  
  Creates an advanced ballsocket constraint between this entity and another, with force/torque limits and friction.
- **`bearing(vector) → number`**  
  Returns the bearing (horizontal angle in degrees) from the entity toward the given world position.
- **`boxCenter() → vector`**  
  Returns the centre of the entity's bounding box, in local coordinates.
- **`boxMaxs() → vector`**  
  Returns the maximum corner of the entity's bounding box, in local coordinates.
- **`boxMins() → vector`**  
  Returns the minimum corner of the entity's bounding box, in local coordinates.
- **`boxSize() → vector`**  
  Returns the size (dimensions) of the entity's bounding box.
- **`constraintBreak() → void`**  
  Breaks every constraint attached to the entity.
- **`constraintBreak(string) → void`**  
  Breaks all constraints of the given type on the entity.
- **`elevation(vector) → number`**  
  Returns the elevation (vertical angle in degrees) from the entity toward the given world position.
- **`energy() → number`**  
  Returns the kinetic energy of the entity's physics object.
- **`extinguish() → void`**  
  Puts the entity out if it is on fire.
- **`eyeAngles() → angle`**  
  Returns the angle the entity is looking along (its eye angles).
- **`eyePos() → vector`**  
  Returns the world position of the entity's eyes.
- **`forward() → vector`**  
  Returns the entity's forward direction as a unit vector.
- **`getAng() → angle`**  
  Returns the entity's orientation as an angle.
- **`getBoneCount() → number`**  
  Returns the number of bones in the entity's model.
- **`getBoneIndex() → number`**  
  Returns the index of the entity's main physics bone.
- **`getChildren() → table`**  
  Returns a table of the entities parented to this entity.
- **`getClass() → string`**  
  Returns the entity's class name.
- **`getColor() → color`**  
  Returns the entity's render colour.
- **`getConstraints() → table`**  
  Returns a table of every constraint attached to the entity.
- **`getConstraintsByType(string) → table`**  
  Returns a table of the entity's constraints of the given type.
- **`getDriver() → player`**  
  Returns the player driving this entity, if it is a vehicle.
- **`getGravity() → number`**  
  Returns the gravity setting of the entity's physics object.
- **`getMass() → number`**  
  Returns the mass of the entity's physics object.
- **`getMassCenter() → vector`**  
  Returns the centre of mass of the entity's physics object, in local coordinates.
- **`getMaterial() → string`**  
  Returns the entity's override material, or an empty string if none is set.
- **`getModel() → string`**  
  Returns the entity's model path.
- **`getParent() → entity`**  
  Returns the entity this entity is parented to.
- **`getPos() → vector`**  
  Returns the entity's world position.
- **`getSubMaterial(number) → string`**  
  Returns the override material for the given sub-material index.
- **`getWeld() → constraint`**  
  Returns the first weld constraint attached to the entity.
- **`getWeld(number) → constraint`**  
  Returns the weld constraint at the given index on the entity.
- **`getWirelink() → wirelink`**  
  Returns the entity's wirelink, for reading and writing its wire ports.
- **`groundEntity() → entity`**  
  Returns the entity this entity is currently standing on.
- **`heading(vector) → angle`**  
  Returns the heading toward the given world position as an angle combining bearing and elevation.
- **`health() → number`**  
  Returns the entity's current health.
- **`id() → number`**  
  Returns the entity's numeric id (its EntIndex).
- **`ignite(number) → void`**  
  Sets the entity on fire for the given number of seconds.
- **`inertia() → vector`**  
  Returns the moment of inertia of the entity's physics object as a vector.
- **`invInertia() → number`**  
  Returns the inverse inertia of the entity's physics object.
- **`isConstrained() → number`**  
  Returns a non-zero value if the entity has any constraints attached.
- **`isConstrainedTo() → entity`**  
  Returns an entity that this entity is constrained to.
- **`isConstrainedTo(number) → entity`**  
  Returns the entity constrained to this one at the given index.
- **`isConstrainedTo(number, string) → entity`**  
  Returns the entity constrained to this one at the given index by a constraint of the given type.
- **`isFrozen() → boolean`**  
  Returns whether the entity's physics object is frozen.
- **`isHeldByPlayer() → boolean`**  
  Returns whether a player is currently holding the entity with the physgun or gravity gun.
- **`isNPC() → boolean`**  
  Returns whether the entity is an NPC.
- **`isOnFire() → boolean`**  
  Returns whether the entity is currently on fire.
- **`isPlayer() → boolean`**  
  Returns whether the entity is a player.
- **`isRagdoll() → boolean`**  
  Returns whether the entity is a ragdoll.
- **`isValid() → boolean`**  
  Returns whether the entity is valid (it exists and can be used).
- **`isVehicle() → boolean`**  
  Returns whether the entity is a vehicle.
- **`isWeapon() → boolean`**  
  Returns whether the entity is a weapon.
- **`isWeldedTo() → entity`**  
  Returns an entity this entity is welded to.
- **`isWeldedTo(number) → entity`**  
  Returns the entity welded to this one at the given index.
- **`lookupAttachment(string) → number`**  
  Returns the index of the named attachment point on the entity's model.
- **`maxArmor() → number`**  
  Returns the entity's maximum armor.
- **`maxHealth() → number`**  
  Returns the entity's maximum health.
- **`noCollide(entity) → void`**  
  Stops this entity from colliding with the given entity.
- **`noCollideAll(boolean) → void`**  
  Sets whether the entity collides with everything, like the right-click of the No-Collide tool.
- **`onGround() → boolean`**  
  Returns whether the entity is standing on the ground.
- **`owner() → player`**  
  Returns the player who owns the entity, according to prop protection.
- **`parent() → entity`**  
  Returns the entity this entity is parented to.
- **`physics() → bone`**  
  Returns the entity's main physics bone object.
- **`pos() → vector`**  
  Returns the entity's world position.
- **`radius() → number`**  
  Returns the entity's bounding radius.
- **`remove() → void`**  
  Removes the entity. Only entities owned by this gate can be removed.
- **`removeTrails() → void`**  
  Removes any trail effect from the entity.
- **`resetSubMaterials() → void`**  
  Clears all sub-material overrides on the entity.
- **`right() → vector`**  
  Returns the entity's right direction as a unit vector.
- **`setAng(angle) → void`**  
  Sets the entity's orientation to the given angle.
- **`setColor(color) → void`**  
  Sets the entity's render colour.
- **`setFrozen(boolean) → void`**  
  Freezes or unfreezes the entity's physics object.
- **`setGravity(boolean) → void`**  
  Enables or disables gravity on the entity's physics object.
- **`setMass(number) → void`**  
  Sets the mass of the entity's physics object.
- **`setMaterial(string) → void`**  
  Sets the entity's override material.
- **`setNotSolid(boolean) → void`**  
  Sets whether the entity is non-solid (passable).
- **`setParent(entity) → void`**  
  Parents this entity to the given entity so it follows its movement.
- **`setPassenger() → player`**  
  Returns the passenger player of the vehicle.
- **`setPos(vector) → void`**  
  Moves the entity to the given world position.
- **`setSubMaterial(number, string) → void`**  
  Sets the override material for the given sub-material index.
- **`setTrails(number, number, number, string, color, number, boolean) → void`**  
  Adds a trail to the entity. Arguments: start width, end width, lifetime, material, colour, end width alpha, and whether it is additive.
- **`setVel(vector) → void`**  
  Sets the entity's velocity.
- **`toLocal(angle) → angle`**  
  Converts a world angle into one local to the entity's orientation.
- **`toLocal(vector) → vector`**  
  Converts a world position into one local to the entity.
- **`toWorld(angle) → angle`**  
  Converts an angle local to the entity into a world angle.
- **`toWorld(vector) → vector`**  
  Converts a position local to the entity into a world position.
- **`totalConstraints() → number`**  
  Returns the number of constraints attached to the entity.
- **`unParent() → void`**  
  Removes the entity's parent so it moves independently again.
- **`up() → vector`**  
  Returns the entity's up direction as a unit vector.
- **`use() → void`**  
  Simulates a player pressing Use on the entity.
- **`waterLevel() → number`**  
  Returns how deeply the entity is submerged in water, from 0 (dry) to 3 (fully underwater).
- **`weld(entity) → void`**  
  Welds this entity to the given entity so they move as one rigid object.
- **`weldAng(vector, entity) → void`**  
  Creates an angular weld between this entity and another at a position local to this entity, fixing their relative angle but not position.
- **`worldSpaceAABB() → vector`**  
  Returns the minimum and maximum corners of the entity's world-space bounding box.
- **`worldSpaceCenter() → vector`**  
  Returns the centre of the entity's world-space bounding box.

---

## Players & Teams

`player` is a player entity (it inherits every `entity` method). The `players` library finds players; the `team` library reads team information.

#### Library: `players`

- **`players.getAllByName(string) → table`**  
  Returns a table of every player whose name contains the given text.
- **`players.getByName(string) → player`**  
  Returns the first player whose name contains the given text.
- **`players.getBySteamID(string) → player`**  
  Returns the player with the given SteamID (STEAM_0:... form).
- **`players.getBySteamID64(string) → player`**  
  Returns the player with the given 64-bit SteamID.
- **`players.localPlayer() → player`**  
  Returns the local player (the client viewing the gate). Client-side only.

#### Library: `team`

- **`team.bestAutoJoin() → number`**  
  Returns the id of the team a player would be placed on by auto-assign (usually the smallest joinable team).
- **`team.getClass(number) → table`**  
  Returns the class table associated with the team of the given id.
- **`team.getColor(number) → color`**  
  Returns the colour of the team with the given id.
- **`team.getName(number) → string`**  
  Returns the display name of the team with the given id.
- **`team.getPlayers(number) → table`**  
  Returns a table of the players currently on the team with the given id.
- **`team.getScore(number) → number`**  
  Returns the score of the team with the given id.
- **`team.getSpawnPoints(number) → table`**  
  Returns a table of the spawn point entities for the team with the given id.
- **`team.joinable(number) → boolean`**  
  Returns true if players are allowed to join the team with the given id.
- **`team.playerCount(number) → number`**  
  Returns the number of players on the team with the given id.
- **`team.totalDeaths(number) → number`**  
  Returns the total number of deaths accumulated by the team with the given id.
- **`team.totalKills(number) → number`**  
  Returns the total number of kills accumulated by the team with the given id.
- **`team.valid(number) → boolean`**  
  Returns true if a team with the given id exists.

#### Type: `player` — extends `entity`

**Operators**

- `!=`  (`player, player` → `boolean`)
- `==`  (`player, player` → `boolean`)
- cast `(entity) player` → `entity`

**Methods**
  
*Also has every `entity` method.*

- **`aimEntity() → entity`**  
  Returns the entity the player is currently looking at.
- **`aimPos() → vector`**  
  Returns the world position the player is currently looking at.
- **`deaths() → number`**  
  Returns the number of times the player has died.
- **`eyeAngles() → angle`**  
  Returns the angle the player is looking along.
- **`eyePos() → vector`**  
  Returns the world position of the player's eyes (camera).
- **`getAllWeapons() → table`**  
  Returns a table of every weapon the player is carrying.
- **`getAmmoPrimary() → string`**  
  Returns how much primary-fire ammunition the player has in reserve for their active weapon.
- **`getAmmoSecondary() → string`**  
  Returns how much secondary-fire ammunition the player has in reserve for their active weapon.
- **`getAngles() → vector`**  
  Returns the player's view angles.
- **`getClipPrimary() → string`**  
  Returns how many rounds are in the primary clip of the player's active weapon.
- **`getClipSecondary() → string`**  
  Returns how many rounds are in the secondary clip of the player's active weapon.
- **`getPos() → vector`**  
  Returns the player's world position.
- **`getTool() → string`**  
  Returns the internal name of the tool the player currently has equipped.
- **`getToolName() → string`**  
  Returns the display name of the tool the player currently has equipped.
- **`getVehicle() → entity`**  
  Returns the vehicle the player is currently sitting in.
- **`isAdmin() → boolean`**  
  Returns whether the player is an admin.
- **`isBot() → boolean`**  
  Returns whether the player is a bot.
- **`isCrouching() → boolean`**  
  Returns whether the player is crouching.
- **`isFlashlightOn() → boolean`**  
  Returns whether the player's flashlight is switched on.
- **`isInVehicle() → boolean`**  
  Returns whether the player is currently in a vehicle.
- **`isSuperAdmin() → boolean`**  
  Returns whether the player is a super admin.
- **`isTyping() → boolean`**  
  Returns whether the player is currently typing in chat.
- **`isValid() → boolean`**  
  Returns whether the player is valid (connected and usable).
- **`keyAttack1() → boolean`**  
  Returns whether the player is holding the primary attack (fire) button.
- **`keyAttack2() → boolean`**  
  Returns whether the player is holding the secondary attack button.
- **`keyBack() → boolean`**  
  Returns whether the player is holding the move-back key.
- **`keyDown(number) → boolean`**  
  Returns whether the player is holding the button with the given key code.
- **`keyDuck() → boolean`**  
  Returns whether the player is holding the crouch key.
- **`keyForward() → boolean`**  
  Returns whether the player is holding the move-forward key.
- **`keyJump() → boolean`**  
  Returns whether the player is holding the jump key.
- **`keyLeft() → boolean`**  
  Returns whether the player is holding the strafe-left key.
- **`keyLeftTurn() → boolean`**  
  Returns whether the player is holding the turn-left key.
- **`keyReload() → boolean`**  
  Returns whether the player is holding the reload key.
- **`keyRight() → boolean`**  
  Returns whether the player is holding the strafe-right key.
- **`keyRightTurn() → boolean`**  
  Returns whether the player is holding the turn-right key.
- **`keySprint() → boolean`**  
  Returns whether the player is holding the sprint key.
- **`keyUse() → boolean`**  
  Returns whether the player is holding the use key.
- **`keyWalk() → boolean`**  
  Returns whether the player is holding the walk key.
- **`keyZoom() → boolean`**  
  Returns whether the player is holding the zoom key.
- **`kills() → number`**  
  Returns the number of kills for the player.
- **`name() → string`**  
  Returns the name of the player.
- **`ping() → number`**  
  Returns the ping of the player.
- **`steamFriendStatus() → string`**  
  Returns the Steam friend status of the player.
- **`steamID() → string`**  
  Returns the Steam ID of the player.
- **`steamID64() → string`**  
  Returns the Steam ID64 of the player.
- **`teamID() → number`**  
  Returns the team ID of the player.

---

## Holograms

Holograms are lightweight client-side models a gate can spawn and control. The `hololib` library creates and limits them; the `hologram` type (which extends `entity`) manipulates them.

#### Library: `hololib`

- **`hololib.anyModel() → boolean`**  
  Returns true if holograms are allowed to use any model, rather than a restricted list.
- **`hololib.canCreate() → boolean`**  
  Returns true if this gate is currently allowed to create another hologram (within the limit and spawn rate).
- **`hololib.clipLimit() → number`**  
  Returns the maximum number of clipping planes a hologram may use.
- **`hololib.create() → hologram`**  
  Creates a hologram at the gate's position and returns it.
- **`hololib.create(string) → hologram`**  
  Creates a hologram with the given model and returns it.
- **`hololib.create(string, vector) → hologram`**  
  Creates a hologram with the given model at the given position.
- **`hololib.create(string, vector, angle) → hologram`**  
  Creates a hologram with the given model at the given position and angle.
- **`hololib.getByID(number) → entity`**  
  Returns the hologram entity with the given id, or an invalid entity if none exists.
- **`hololib.limit() → number`**  
  Returns the maximum number of holograms a player may have at once.
- **`hololib.maxScale() → number`**  
  Returns the largest scale a hologram may be set to.
- **`hololib.modelName(string) → string`**  
  Returns the full model path for a short hologram model name, or an empty string if unknown.
- **`hololib.spawnRate() → number`**  
  Returns how many holograms may be created per second.

#### Type: `hologram` — extends `entity`

**Constructors**

- `new hologram()`
- `new hologram(string)`
- `new hologram(string, vector)`
- `new hologram(string, vector, angle)`

**Operators**

- cast `(entity) hologram` → `entity`

**Methods**
  
*Also has every `entity` method.*

- **`animationLength() → number`**  
  Returns the length in seconds of the hologram's current animation.
- **`boneCount() → number`**  
  Returns the number of bones in the hologram's model.
- **`boneParent(number) → number`**  
  Returns the index of the parent bone of the bone with the given index.
- **`enableClip(number, boolean) → void`**  
  Enables or disables the clipping plane with the given index.
- **`getAnimation() → number`**  
  Returns the index of the hologram's current animation.
- **`getAnimationName(number) → string`**  
  Returns the name of the animation with the given index.
- **`getBoneAng(number) → angle`**  
  Returns the angle of the bone with the given index.
- **`getBonePos(number) → vector`**  
  Returns the position of the bone with the given index.
- **`getBoneScale(number) → vector`**  
  Returns the scale of the bone with the given index.
- **`getColor() → color`**  
  Returns the hologram's render colour.
- **`getID() → number`**  
  Returns the hologram's id.
- **`getMaterial() → string`**  
  Returns the hologram's override material.
- **`getModel() → string`**  
  Returns the hologram's model path.
- **`getParentEntity() → void`**  
  Returns the entity this hologram is parented to.
- **`getParentHologram() → void`**  
  Returns the hologram this hologram is parented to.
- **`getParentPlayer() → void`**  
  Returns the player this hologram is parented to.
- **`getPose() → number`**  
  Returns the hologram's current pose parameter value.
- **`getScale() → vector`**  
  Returns the hologram's scale as a vector.
- **`getScaleUnits() → vector`**  
  Returns the hologram's scale measured in world units.
- **`getSkin() → number`**  
  Returns the hologram's current skin index.
- **`getSkinCount() → number`**  
  Returns the number of skins the hologram's model has.
- **`hasShading() → boolean`**  
  Returns whether the hologram is rendered with shading.
- **`isVisible() → boolean`**  
  Returns whether the hologram is currently visible.
- **`jiggleBone(number, boolean) → void`**  
  Enables or disables jiggle physics on the bone with the given index.
- **`moveTo(vector, number) → void`**  
  Smoothly moves the hologram toward the given position at the given speed.
- **`parent(entity) → void`**  
  Parents the hologram to the given entity so it follows its movement.
- **`parent(hologram) → void`**  
  Parents the hologram to the given hologram so it follows its movement.
- **`parent(player) → void`**  
  Parents the hologram to the given player so it follows their movement.
- **`parentAttachment(entity, string) → void`**  
  Parents the hologram to the named attachment point of the given entity.
- **`parentAttachment(hologram, string) → void`**  
  Parents the hologram to the named attachment point of the given hologram.
- **`parentAttachment(player, string) → void`**  
  Parents the hologram to the named attachment point of the given player.
- **`pushClip(number, vector, vector, boolean) → void`**  
  Sets up the clipping plane with the given index from an origin, a normal, and whether the plane is local to the hologram.
- **`remove() → void`**  
  Removes the hologram.
- **`removeClip(number) → void`**  
  Removes the clipping plane with the given index.
- **`rotateTo(angle, number) → void`**  
  Smoothly rotates the hologram toward the given angle at the given speed.
- **`scaleTo(vector, number) → void`**  
  Smoothly scales the hologram toward the given scale at the given speed.
- **`scaleToUnits(vector, number) → void`**  
  Smoothly scales the hologram toward the given size in world units.
- **`setAng(angle) → void`**  
  Sets the hologram's orientation to the given angle.
- **`setAnimation(number) → void`**  
  Plays the hologram animation with the given index.
- **`setAnimation(number, number) → void`**  
  Plays the hologram animation with the given index, starting at the given frame.
- **`setAnimation(number, number, number) → void`**  
  Plays the hologram animation with the given index, starting frame and playback rate.
- **`setAnimation(string) → void`**  
  Plays the hologram animation with the given name.
- **`setAnimation(string, number) → void`**  
  Plays the hologram animation with the given name, starting at the given frame.
- **`setAnimation(string, number, number) → void`**  
  Plays the hologram animation with the given name, starting frame and playback rate.
- **`setAnimationRate(number) → void`**  
  Sets the playback speed of the hologram's current animation.
- **`setBodygroup(number, number) → void`**  
  Sets the value of the bodygroup with the given index on the hologram.
- **`setBoneAngle(number, angle) → void`**  
  Sets the angle of the bone with the given index.
- **`setBonePos(number, vector) → void`**  
  Sets the position of the bone with the given index.
- **`setBoneScale(number, vector) → void`**  
  Sets the scale of the bone with the given index.
- **`setClipNormal(number, vector) → void`**  
  Sets the normal direction of the clipping plane with the given index.
- **`setClipOrigin(number, vector) → void`**  
  Sets the origin position of the clipping plane with the given index.
- **`setColor(color) → void`**  
  Sets the hologram's render colour.
- **`setID(number) → void`**  
  Sets the hologram's id.
- **`setMaterial(string) → void`**  
  Sets the hologram's override material.
- **`setModel(string) → void`**  
  Sets the hologram's model.
- **`setPos(vector) → void`**  
  Moves the hologram to the given world position.
- **`setPose(string, number) → void`**  
  Sets the named pose parameter of the hologram to the given value.
- **`setScale(vector) → void`**  
  Sets the hologram's scale.
- **`setScaleUnits(vector) → void`**  
  Sets the hologram's scale measured in world units.
- **`setShading(boolean) → void`**  
  Sets whether the hologram is rendered with shading.
- **`setShadow(boolean) → void`**  
  Sets whether the hologram casts a shadow.
- **`setSkin(number) → void`**  
  Sets the hologram's skin index.
- **`setVisible(boolean) → void`**  
  Sets whether the hologram is visible.
- **`startMove(vector) → void`**  
  Starts the hologram moving smoothly toward the given position.
- **`startRotate(angle) → void`**  
  Starts the hologram rotating smoothly toward the given angle.
- **`stopMove() → void`**  
  Stops the hologram's smooth movement.
- **`stopRotate() → void`**  
  Stops the hologram's smooth rotation.
- **`stopScale() → void`**  
  Stops the hologram's smooth scaling.
- **`unparent() → void`**  
  Removes the hologram's parent so it moves independently again.

---

## Props

The `prop` library spawns physical props and vehicle seats.

#### Library: `prop`

- **`prop.canSpawn() → boolean`**  
  Returns true if this gate's owner is currently allowed to spawn a prop (within limits and cooldown).
- **`prop.spawn(string) → entity`**  
  Spawns a prop with the given model at the gate's position and returns it.
- **`prop.spawn(string, boolean) → entity`**  
  Spawns a prop with the given model, the boolean setting whether it spawns frozen.
- **`prop.spawn(string, vector) → entity`**  
  Spawns a prop with the given model at the given position.
- **`prop.spawn(string, vector, angle) → entity`**  
  Spawns a prop with the given model at the given position and angle.
- **`prop.spawn(string, vector, angle, boolean) → entity`**  
  Spawns a prop with the given model at the given position and angle, the boolean setting whether it spawns frozen.
- **`prop.spawn(string, vector, boolean) → entity`**  
  Spawns a prop with the given model at the given position, the boolean setting whether it spawns frozen.
- **`prop.spawnSeat(string) → entity`**  
  Spawns a seat (vehicle pod) with the given model at the gate's position and returns it.
- **`prop.spawnSeat(string, boolean) → entity`**  
  Spawns a seat with the given model, the boolean setting whether it spawns frozen.
- **`prop.spawnSeat(string, vector) → entity`**  
  Spawns a seat with the given model at the given position.
- **`prop.spawnSeat(string, vector, angle) → entity`**  
  Spawns a seat with the given model at the given position and angle.
- **`prop.spawnSeat(string, vector, angle, boolean) → entity`**  
  Spawns a seat with the given model at the given position and angle, the boolean setting whether it spawns frozen.
- **`prop.spawnSeat(string, vector, boolean) → entity`**  
  Spawns a seat with the given model at the given position, the boolean setting whether it spawns frozen.

---

## Physics Objects

The `physics` type (alias `bone`) is an entity's physics object, obtained from `entity.physics()`, giving lower-level control over mass, velocity and forces.

#### Type: `bone`

*Aliases:* `physics`

**Operators**

- `!=`  (`bone, bone` → `boolean`)
- `==`  (`bone, bone` → `boolean`)

**Methods**

- **`Vel() → vector`**  
  Returns the velocity of the physics object.
- **`ang() → vector`**  
  Returns the angles of the physics object.
- **`angDamping() → number`**  
  Returns the angular (rotational) damping of the physics object.
- **`angVel() → angle`**  
  Returns the angular velocity of the physics object.
- **`applyAngForce(angle) → void`**  
  Applies an angular (turning) force to the physics object.
- **`applyForce(vector) → void`**  
  Applies a linear force to the physics object.
- **`applyOffsetForce(vector) → void`**  
  Applies a force to the physics object offset from its centre of mass.
- **`bearing(vector) → number`**  
  Returns the bearing from the physics object toward the given world position.
- **`damping() → number`**  
  Returns the linear damping of the physics object.
- **`elevation(vector) → number`**  
  Returns the elevation from the physics object toward the given world position.
- **`energy() → number`**  
  Returns the kinetic energy of the physics object.
- **`forward() → vector`**  
  Returns the forward direction of the physics object as a unit vector.
- **`getAng() → vector`**  
  Returns the angles of the physics object.
- **`getMass() → number`**  
  Returns the mass of the physics object.
- **`getMassCenter() → vector`**  
  Returns the centre of mass of the physics object, in local coordinates.
- **`getPos() → vector`**  
  Returns the position of the physics object.
- **`heading(vector) → number`**  
  Returns the heading from the physics object toward the given world position.
- **`inertia() → vector`**  
  Returns the moment of inertia of the physics object as a vector.
- **`invInertia() → number`**  
  Returns the inverse inertia of the physics object.
- **`isFrozen() → boolean`**  
  Returns whether the physics object is frozen.
- **`isValid() → boolean`**  
  Returns whether the physics object is valid.
- **`pos() → vector`**  
  Returns the position of the physics object.
- **`right() → vector`**  
  Returns the right direction of the physics object as a unit vector.
- **`rotDamping() → number`**  
  Returns the rotational damping of the physics object.
- **`setAng(angle) → void`**  
  Sets the angles of the physics object.
- **`setFrozen(boolean) → void`**  
  Freezes or unfreezes the physics object.
- **`setMass(number) → void`**  
  Sets the mass of the physics object.
- **`setPos(vector) → void`**  
  Sets the position of the physics object.
- **`setVel(vector) → void`**  
  Sets the velocity of the physics object.
- **`speedDamping() → number`**  
  Returns the linear speed damping of the physics object.
- **`toLocal(vector) → vector`**  
  Converts a world position into one local to the physics object.
- **`toWorld(vector) → vector`**  
  Converts a position local to the physics object into a world position.
- **`up() → vector`**  
  Returns the up direction of the physics object as a unit vector.

---

## Constraints

The `constraint` type represents a physics constraint. Constraints are usually created through entity methods such as `weld`, `axis` and `ballsocket`.

#### Type: `constraint`

**Operators**

- `!=`  (`constraint, constraint` → `boolean`)
- `==`  (`constraint, constraint` → `boolean`)

**Methods**

- **`getType() → string`**  
  Returns the type of the constraint, such as "Weld" or "Axis".

---

## Rangers (Traces)

The `ranger` library fires traces through the world; each trace returns a `rangerdata` value describing what, if anything, it hit.

#### Library: `ranger`

- **`ranger.clearFilter() → void`**  
  Empties the ranger filter so rangers no longer ignore anything.
- **`ranger.defaultZero() → boolean`**  
  Returns whether rangers default their hit position to a zero point when nothing is hit.
- **`ranger.defaultZero(boolean) → void`**  
  Sets whether rangers default their hit position to zero when nothing is hit.
- **`ranger.filter() → table`**  
  Returns the current ranger filter as a table of entities.
- **`ranger.filter(entity) → void`**  
  Adds an entity to the ranger filter so rangers ignore it.
- **`ranger.filter(player) → void`**  
  Adds a player to the ranger filter so rangers ignore them.
- **`ranger.filter(table) → void`**  
  Replaces the ranger filter with the entities in the given table.
- **`ranger.hitEntities() → boolean`**  
  Returns whether rangers are currently set to hit entities.
- **`ranger.hitEntities(boolean) → void`**  
  Sets whether the next rangers should hit entities.
- **`ranger.hitWater() → boolean`**  
  Returns whether rangers are currently set to hit water.
- **`ranger.hitWater(boolean) → void`**  
  Sets whether the next rangers should hit water.
- **`ranger.ignoreWorld() → boolean`**  
  Returns whether rangers are currently set to ignore the world.
- **`ranger.ignoreWorld(boolean) → void`**  
  Sets whether the next rangers should ignore the world (map geometry).
- **`ranger.offset(vector, vector) → rangerdata`**  
  Fires a ranger between two world positions and returns the ranger data describing what it hit.
- **`ranger.offset(vector, vector, number) → rangerdata`**  
  Fires a ranger from a start position in a direction for the given length and returns the ranger data.
- **`ranger.offsetHull(vector, vector, number, vector, vector) → rangerdata`**  
  Fires a box-shaped (hull) ranger from a start position in a direction for the given length, using the given min and max corners.
- **`ranger.offsetHull(vector, vector, vector, vector) → rangerdata`**  
  Fires a box-shaped (hull) ranger between two positions using the given min and max corners.
- **`ranger.persist() → boolean`**  
  Returns whether ranger settings persist between calls instead of resetting.
- **`ranger.persist(boolean) → void`**  
  Sets whether ranger settings persist between calls instead of resetting each time.
- **`ranger.reset() → void`**  
  Resets all ranger settings (filters, flags, ranges) back to their defaults.

#### Type: `rangerdata`

**Attributes**

- **`.distance`** → `number`  
  The distance in source units from the ranger's start position to its hit position.
- **`.fraction`** → `number`  
  How far along the ranger the hit occurred, from 0 (at the start) to 1 (at the end). Multiply by the ranger length to get the distance.
- **`.fraction_solid`** → `number`  
  If the ranger began inside a solid, this is the fraction (0-1) at which it left that solid. Only meaningful against the world, not against brush entities.
- **`.hit`** → `boolean`  
  True if the ranger hit anything (either the world or an entity), false if it reached its end point without contact.
- **`.hit_bone`** → `number`  
  The physics object (bone) index of the object that was hit.
- **`.hit_entity`** → `entity`  
  The entity the ranger hit. This is a world/invalid entity when the ranger hit the map or nothing at all.
- **`.hit_group`** → `number`  
  The hitgroup that was hit (head, chest, arms, legs, etc.). See https://wiki.facepunch.com/gmod/Enums/HITGROUP
- **`.hit_nodraw`** → `boolean`  
  True if the ranger hit an invisible (nodraw) brush.
- **`.hit_noneworld`** → `boolean`  
  True if the ranger hit a non-world object, such as a prop or other entity.
- **`.hit_norm`** → `vector`  
  The surface normal of whatever the ranger hit, as a unit-length vector pointing away from the surface.
- **`.hit_pos`** → `vector`  
  The world position where the ranger stopped. If nothing was hit this is the end point of the ranger.
- **`.hit_sky`** → `boolean`  
  True if the ranger hit the skybox.
- **`.hit_texture`** → `string`  
  The surface material name (not the texture) of whatever the ranger hit. Returns "**displacement**" for a displacement surface and "**studio**" when a model/prop was hit.
- **`.hit_world`** → `boolean`  
  True if the ranger hit the world (map geometry) rather than an entity.
- **`.hitbox`** → `number`  
  The index of the hitbox that was hit on the entity.
- **`.hitbox_bone`** → `number`  
  The bone index associated with the hitbox that was hit.
- **`.material_type`** → `number`  
  The material type of the surface that was hit (metal, wood, flesh, etc.). See https://wiki.facepunch.com/gmod/Enums/MAT
- **`.normal`** → `vector`  
  The direction the ranger was travelling, from its start toward its end, as a unit-length (normalized) vector.
- **`.start_solid`** → `boolean`  
  True if the ranger started inside a solid object.

---

## Finding Entities

The `entlib` library and the `find` type build filtered searches for entities in the world.

#### Library: `entlib`

*(No standalone functions in the base install — this library's features are provided through the related type below.)*

#### Type: `find`

**Constructors**

- `new find()`

**Methods**

- **`addBlackList(entity) → void`**  
  Adds an entity to the blacklist so find results never include it.
- **`addBlackList(table) → void`**  
  Adds a table of entities to the blacklist so find results never include them.
- **`addWhiteList(entity) → void`**  
  Adds an entity to the whitelist so only whitelisted entities can appear in results.
- **`addWhiteList(table) → void`**  
  Adds a table of entities to the whitelist so only whitelisted entities can appear in results.
- **`clearBlackList() → void`**  
  Empties the blacklist.
- **`clearClassFilters() → void`**  
  Clears any class include/exclude filters.
- **`clearFilters() → void`**  
  Clears every filter, blacklist and whitelist on this finder.
- **`clearModelFilters() → void`**  
  Clears any model include/exclude filters.
- **`clearPlayerFilters() → void`**  
  Clears any player-prop include/exclude filters.
- **`clearWhiteList() → void`**  
  Empties the whitelist.
- **`clipFromBox(vector, vector) → void`**  
  Removes from the results any entity inside the box between the two corners.
- **`clipFromRegion(vector, vector) → void`**  
  Removes from the results any entity inside the given region.
- **`clipFromSphere(vector, number) → void`**  
  Removes from the results any entity inside the sphere of the given centre and radius.
- **`clipToBox(vector, vector) → void`**  
  Keeps only the results inside the box between the two corners.
- **`clipToSphere(vector, number) → void`**  
  Keeps only the results inside the sphere of the given centre and radius.
- **`copyFilters(find) → void`**  
  Copies all filters, blacklist and whitelist from another finder onto this one.
- **`excludeClass(string) → void`**  
  Excludes entities of the given class from the results.
- **`excludeModel(string) → void`**  
  Excludes entities with the given model from the results.
- **`excludePlayerPpops(player) → void`**  
  Excludes props owned by the given player from the results.
- **`finInPVS(entity) → number`**  
  Finds all entities in the potentially-visible set of the given entity and returns how many were found.
- **`finInPVS(vector) → number`**  
  Finds all entities in the potentially-visible set of the given position and returns how many were found.
- **`findByClass(string) → number`**  
  Finds all entities of the given class and returns how many were found.
- **`findByModel(string) → number`**  
  Finds all entities with the given model and returns how many were found.
- **`findInBox(vector, vector) → number`**  
  Finds all entities inside the box between the two corners and returns how many were found.
- **`findInCone(vector, vector, number, angle) → number`**  
  Finds all entities inside a cone from an origin along a direction, with the given length and spread angle, and returns how many were found.
- **`findInSphere(vector, number) → number`**  
  Finds all entities inside the sphere of the given centre and radius and returns how many were found.
- **`first() → entity`**  
  Returns the first entity in the results.
- **`includeClass(string) → void`**  
  Restricts the results to entities of the given class.
- **`includeModel(string) → void`**  
  Restricts the results to entities with the given model.
- **`includePlayerPpops(player) → void`**  
  Restricts the results to props owned by the given player.
- **`removeFromBlackList(entity) → void`**  
  Removes an entity from the blacklist.
- **`removeFromWhiteList(entity) → void`**  
  Removes an entity from the whitelist.
- **`results() → number`**  
  Returns the number of entities currently in the results.
- **`sortByDistance(vector) → void`**  
  Sorts the results by their distance from the given position, nearest first.
- **`toArray() → table`**  
  Returns the found entities as a table.

---

## Wirelink

A `wirelink` lets a gate read and write another entity's wire ports directly.

#### Type: `wirelink`

**Operators**

- `!=`  (`wirelink, wirelink` → `boolean`)
- `==`  (`wirelink, wirelink` → `boolean`)
- cast `(entity) wirelink` → `entity`

**Methods**

- **`hasInput(string) → boolean`**  
  Returns whether the wirelinked entity has an input port with the given name.
- **`hasOutput(string) → boolean`**  
  Returns whether the wirelinked entity has an output port with the given name.
- **`inputType(string) → string`**  
  Returns the wire type of the named input port.
- **`isHighSpeed() → boolean`**  
  Returns whether the wirelinked entity is a high-speed device.
- **`outputType(string) → string`**  
  Returns the wire type of the named output port.
- **`readAngleFromInput(string) → angle`**  
  Reads the value of the named input port as an angle.
- **`readAngleFromOutput(string) → angle`**  
  Reads the value of the named output port as an angle.
- **`readE2.tableFromInput(string) → _e2t`**  
  Reads the value of the named input port as an E2 table.
- **`readE2.tableFromOutput(string) → _e2t`**  
  Reads the value of the named output port as an E2 table.
- **`readEntityFromInput(string) → entity`**  
  Reads the value of the named input port as an entity.
- **`readEntityFromOutput(string) → entity`**  
  Reads the value of the named output port as an entity.
- **`readFunctionFromInput(string) → function`**  
  Reads the value of the named input port as a function.
- **`readFunctionFromOutput(string) → function`**  
  Reads the value of the named output port as a function.
- **`readNumberFromInput(string) → number`**  
  Reads the value of the named input port as a number.
- **`readNumberFromOutput(string) → number`**  
  Reads the value of the named output port as a number.
- **`readPlayerFromInput(string) → player`**  
  Reads the value of the named input port as a player.
- **`readPlayerFromOutput(string) → player`**  
  Reads the value of the named output port as a player.
- **`readStringFromInput(string) → string`**  
  Reads the value of the named input port as a string.
- **`readStringFromOutput(string) → string`**  
  Reads the value of the named output port as a string.
- **`readTableFromInput(string) → table`**  
  Reads the value of the named input port as a table.
- **`readTableFromOutput(string) → table`**  
  Reads the value of the named output port as a table.
- **`readVector2FromInput(string) → vector2`**  
  Reads the value of the named input port as a 2D vector.
- **`readVector2FromOutput(string) → vector2`**  
  Reads the value of the named output port as a 2D vector.
- **`readVectorFromInput(string) → vector`**  
  Reads the value of the named input port as a vector.
- **`readVectorFromOutput(string) → vector`**  
  Reads the value of the named output port as a vector.
- **`readWirelinkFromInput(string) → wirelink`**  
  Reads the value of the named input port as a wirelink.
- **`readWirelinkFromOutput(string) → wirelink`**  
  Reads the value of the named output port as a wirelink.
- **`writeToInput(string, _e2t) → void`**  
  Writes an E2 table to the named input port of the wirelinked entity.
- **`writeToInput(string, _e2t, boolean) → void`**  
  Writes an E2 table to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, vector2) → void`**  
  Writes a 2D vector to the named input port of the wirelinked entity.
- **`writeToInput(string, vector2, boolean) → void`**  
  Writes a 2D vector to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, wirelink) → void`**  
  Writes a wirelink to the named input port of the wirelinked entity.
- **`writeToInput(string, wirelink, boolean) → void`**  
  Writes a wirelink to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, angle) → void`**  
  Writes an angle to the named input port of the wirelinked entity.
- **`writeToInput(string, angle, boolean) → void`**  
  Writes an angle to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, boolean) → void`**  
  Writes a boolean to the named input port of the wirelinked entity.
- **`writeToInput(string, boolean, boolean) → void`**  
  Writes a boolean to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, entity) → void`**  
  Writes an entity to the named input port of the wirelinked entity.
- **`writeToInput(string, entity, boolean) → void`**  
  Writes an entity to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, function) → void`**  
  Writes a function to the named input port of the wirelinked entity.
- **`writeToInput(string, function, boolean) → void`**  
  Writes a function to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, number) → void`**  
  Writes a number to the named input port of the wirelinked entity.
- **`writeToInput(string, number, boolean) → void`**  
  Writes a number to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, player) → void`**  
  Writes a player to the named input port of the wirelinked entity.
- **`writeToInput(string, player, boolean) → void`**  
  Writes a player to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, string) → void`**  
  Writes a string to the named input port of the wirelinked entity.
- **`writeToInput(string, string, boolean) → void`**  
  Writes a string to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, table) → void`**  
  Writes a table to the named input port of the wirelinked entity.
- **`writeToInput(string, table, boolean) → void`**  
  Writes a table to the named input port, the boolean choosing whether to force the value even if the port already holds it.
- **`writeToInput(string, vector) → void`**  
  Writes a vector to the named input port of the wirelinked entity.
- **`writeToInput(string, vector, boolean) → void`**  
  Writes a vector to the named input port, the boolean choosing whether to force the value even if the port already holds it.

---

## E2 Table Compatibility

The `e2table` type interoperates with Wiremod Expression 2 tables passed over wire.

---

## Rendering

The `render` library draws 2D graphics client-side, inside a `RenderHUD` or `RenderScreen` event. The `canvas` type is an off-screen render target.

#### Library: `render`

- **`render.downloadURLMaterial(string, string) → void`**  
  Downloads an image from a URL and stores it as a named render material for later use.
- **`render.downloadURLMaterial(string, string, number, number) → void`**  
  Downloads an image from a URL at the given width and height and stores it as a named render material.
- **`render.drawBox(vector2, vector2) → void`**  
  Draws a filled rectangle at the given position with the given size (in pixels).
- **`render.drawBox(vector2, vector2, number) → void`**  
  Draws a filled rectangle at the given position and size, rotated by the given number of degrees about its centre.
- **`render.drawBoxOutline(vector2, vector2) → void`**  
  Draws the outline of a rectangle at the given position with the given size.
- **`render.drawCircle(vector2, number) → void`**  
  Draws a filled circle centred at the given position with the given radius.
- **`render.drawCircleOutline(vector2, number) → void`**  
  Draws the outline of a circle centred at the given position with the given radius.
- **`render.drawLine(vector2, vector2) → void`**  
  Draws a straight line between two screen positions.
- **`render.drawPoly(table) → void`**  
  Draws a filled polygon from a table of 2D points.
- **`render.drawPolyOutline(table) → void`**  
  Draws the outline of a polygon from a table of 2D points.
- **`render.drawText(vector2, string) → number`**  
  Draws text at the given position using the current font and font colour, and returns the size it occupied.
- **`render.drawText(vector2, string, number) → number`**  
  Draws text at the given position rotated by the given number of degrees, and returns the size it occupied.
- **`render.drawTriangle(vector2, vector2, vector2) → void`**  
  Draws a filled triangle between three screen positions.
- **`render.drawTriangleOutline(vector2, vector2, vector2) → void`**  
  Draws the outline of a triangle between three screen positions.
- **`render.getColor() → color`**  
  Returns the colour currently used to render shapes.
- **`render.getFontColor() → color`**  
  Returns the colour currently used to render text.
- **`render.getScreenRefresh() → boolean`**  
  Returns whether the screen is cleared before each new frame is drawn.
- **`render.getTextSize(string) → number`**  
  Returns the width and height, in pixels, that the given text would occupy with the current font.
- **`render.popCanvas() → void`**  
  Stops drawing onto a canvas pushed with pushCanvas and returns to the previous target.
- **`render.pushCanvas(canvas) → void`**  
  Redirects all following draw calls onto the given canvas until popCanvas is called.
- **`render.scrH() → number`**  
  Returns the height in pixels of the current rendering surface (HUD or screen).
- **`render.scrSize() → number`**  
  Returns the width and height in pixels of the current rendering surface.
- **`render.scrW() → number`**  
  Returns the width in pixels of the current rendering surface (HUD or screen).
- **`render.setColor(color) → void`**  
  Sets the colour used to draw following shapes to the given colour.
- **`render.setColor(number, number, number) → void`**  
  Sets the colour used to draw following shapes from red, green and blue channels (0-255).
- **`render.setColor(number, number, number, number) → void`**  
  Sets the colour used to draw following shapes from red, green, blue and alpha channels (0-255).
- **`render.setFont(string, number) → void`**  
  Sets the font name and size used to draw following text.
- **`render.setFontColor(color) → void`**  
  Sets the colour used to draw following text to the given colour.
- **`render.setFontColor(number, number, number) → void`**  
  Sets the colour used to draw following text from red, green and blue channels (0-255).
- **`render.setFontColor(number, number, number, number) → void`**  
  Sets the colour used to draw following text from red, green, blue and alpha channels (0-255).
- **`render.setScreenRefresh(boolean) → void`**  
  Sets whether the screen is cleared before each new frame is drawn. Disable it to draw persistent images.
- **`render.setTexture() → void`**  
  Clears the render texture so following shapes are drawn as a solid colour.
- **`render.setTexture(canvas) → void`**  
  Uses the given canvas as the texture when drawing following shapes.
- **`render.setTexture(string) → void`**  
  Sets the texture (by material name) used when drawing following shapes.
- **`render.setURLMaterial(string) → void`**  
  Sets the render texture to a previously downloaded URL material.

#### Type: `canvas`

**Constructors**

- `new canvas(number, number, number)`

**Operators**

- `!=`  (`canvas, canvas` → `boolean`)
- `==`  (`canvas, canvas` → `boolean`)

**Methods**

- **`height() → number`**  
  Returns the height of the canvas in pixels.
- **`id() → number`**  
  Returns the canvas's internal id.
- **`width() → number`**  
  Returns the width of the canvas in pixels.

---

## Keyboard Input

The `key` and `numpad` libraries are collections of key-code constants used with the button events and `player.keyDown`.

#### Library: `key`

*Constants:* `key.a`, `key.apostrophe`, `key.b`, `key.backquote`, `key.backslash`, `key.backspace`, `key.break`, `key.c`, `key.capslock`, `key.comma`, `key.d`, `key.delete`, `key.down`, `key.e`, `key.eight`, `key.end`, `key.enter`, `key.equal`, `key.escape`, `key.f`, `key.f1`, `key.f10`, `key.f11`, `key.f12`, `key.f2`, `key.f3`, `key.f4`, `key.f5`, `key.f6`, `key.f7`, `key.f8`, `key.f9`, `key.five`, `key.four`, `key.g`, `key.h`, `key.home`, `key.i`, `key.insert`, `key.j`, `key.k`, `key.l`, `key.left`, `key.left_alt`, `key.left_bracket`, `key.left_control`, `key.left_shift`, `key.m`, `key.minus`, `key.n`, `key.nine`, `key.numlock`, `key.o`, `key.one`, `key.p`, `key.pagedown`, `key.pageup`, `key.period`, `key.q`, `key.r`, `key.right`, `key.right_alt`, `key.right_bracket`, `key.right_control`, `key.right_shift`, `key.s`, `key.scrolllock`, `key.semicolon`, `key.seven`, `key.six`, `key.slash`, `key.space`, `key.t`, `key.tab`, `key.three`, `key.two`, `key.u`, `key.up`, `key.v`, `key.w`, `key.x`, `key.y`, `key.z`, `key.zero`

#### Library: `numpad`

*Constants:* `numpad.decimal`, `numpad.divide`, `numpad.eight`, `numpad.enter`, `numpad.five`, `numpad.four`, `numpad.minus`, `numpad.multiply`, `numpad.nine`, `numpad.one`, `numpad.plus`, `numpad.seven`, `numpad.six`, `numpad.three`, `numpad.two`, `numpad.zero`

---

## Networking

The `net` library sends messages between the server and clients. A `stream` carries the written values; a `recipientfilter` chooses which clients receive a message.

#### Library: `net`

- **`net.receive(string, function) → void`**  
  Registers a function to run whenever a network message with the given name is received.
- **`net.sendToClients(stream) → void`**  
  Sends the given network stream from the server to every client.
- **`net.sendToClients(stream, recipientfilter) → void`**  
  Sends the given network stream from the server only to the clients in the given recipient filter.
- **`net.sendToServer(stream) → void`**  
  Sends the given network stream from a client to the server.
- **`net.start(string) → stream`**  
  Begins building a network message with the given name and returns a stream to write values into.

#### Type: `stream`

**Methods**

- **`readBool() → boolean`**  
  Reads a boolean from the stream.
- **`readChar() → number`**  
  Reads a single signed byte (char) from the stream.
- **`readFloat() → number`**  
  Reads a floating-point number from the stream.
- **`readLong() → number`**  
  Reads a 32-bit integer (long) from the stream.
- **`readPos() → number`**  
  Reads a compressed world position from the stream.
- **`readShort() → number`**  
  Reads a 16-bit integer (short) from the stream.
- **`readString() → string`**  
  Reads a string from the stream.
- **`remain() → number`**  
  Returns how many bytes are left to read in the stream.
- **`size() → number`**  
  Returns the total size of the stream in bytes.
- **`writeBool(boolean) → void`**  
  Writes a boolean into the stream.
- **`writeChar(number) → void`**  
  Writes a single signed byte (char) into the stream.
- **`writeFloat(number) → void`**  
  Writes a floating-point number into the stream.
- **`writeLong(number) → void`**  
  Writes a 32-bit integer (long) into the stream.
- **`writeShort(number) → void`**  
  Writes a 16-bit integer (short) into the stream.
- **`writeString(string) → void`**  
  Writes a string into the stream.

#### Type: `recipientfilter`

**Constructors**

- `new recipientfilter()`

**Methods**

- **`addAllPlayers() → void`**  
  Adds every player on the server to the recipient filter.
- **`addPAS(vector) → void`**  
  Adds every player who could potentially hear audio at the given position.
- **`addPVS(vector) → void`**  
  Adds every player who could potentially see the given position.
- **`addPlayer(player) → void`**  
  Adds a single player to the recipient filter.
- **`addRecipientsByTeam(number) → void`**  
  Adds every player on the team with the given id.
- **`getCount() → number`**  
  Returns the number of players currently in the recipient filter.
- **`getPlayers() → table`**  
  Returns a table of the players currently in the recipient filter.
- **`removeAllPlayers() → void`**  
  Removes every player from the recipient filter.
- **`removePAS(vector) → void`**  
  Removes the players who could potentially hear audio at the given position.
- **`removePVS(vector) → void`**  
  Removes the players who could potentially see the given position.
- **`removePlayer(player) → void`**  
  Removes a single player from the recipient filter.
- **`removeRecipientsByTeam(number) → void`**  
  Removes every player on the team with the given id.
- **`removeRecipientsNotOnTeam(number) → void`**  
  Removes every player who is not on the team with the given id.

---

## HTTP

The `http` library makes HTTP requests.

#### Library: `http`

- **`http.encode(string) → string`**  
  Percent-encodes a string so it is safe to use inside a URL.
- **`http.request(string, function) → boolean`**  
  Sends an HTTP GET request to the given URL and calls the success function with the response body.
- **`http.request(string, function, function) → boolean`**  
  Sends an HTTP GET request to the given URL, calling the first function on success and the second on failure.

---

## Game & Server

The `game` library reports information about the server, the map and the physics environment.

#### Library: `game`

- **`game.airDensity() → number`**  
  Returns the density of the air in the physics environment.
- **`game.angSpeedLimit() → number`**  
  Returns the maximum angular velocity a physics object may reach (MaxAngularVelocity).
- **`game.gamemode() → string`**  
  Returns the name of the gamemode the server is running.
- **`game.gravity() → number`**  
  Returns the strength of world gravity (units per second squared).
- **`game.hostname() → string`**  
  Returns the server's host name.
- **`game.isLan() → boolean`**  
  Returns true if the server is running as a LAN game.
- **`game.isSinglePlayer() → boolean`**  
  Returns true if the game is running in single-player.
- **`game.map() → string`**  
  Returns the file name of the map currently being played.
- **`game.maxFrictionMass() → number`**  
  Returns the maximum mass the physics engine applies full friction to.
- **`game.maxPlayers() → number`**  
  Returns the maximum number of players the server allows.
- **`game.minFrictionMass() → number`**  
  Returns the minimum mass the physics engine applies friction to.
- **`game.numPlayers() → number`**  
  Returns the number of players currently connected to the server.
- **`game.propGravity() → vector`**  
  Returns the world gravity as a direction vector.
- **`game.speedLimit() → number`**  
  Returns the maximum linear velocity a physics object may reach (MaxVelocity).
- **`game.tickInterval() → number`**  
  Returns the length of one server tick in seconds.
- **`game.tickRate() → number`**  
  Returns how many server ticks occur per second.

---

## Permissions

The `permissions` library checks what this gate's owner is allowed to do and who owns an entity.

#### Library: `permissions`

- **`permissions.check(entity) → boolean`**  
  Returns true if this gate's owner is allowed to interact with the given entity.
- **`permissions.check(entity, string) → boolean`**  
  Returns true if this gate's owner holds the named permission on the given entity.
- **`permissions.getAll() → table`**  
  Returns a table of every permission the permissions system knows about.
- **`permissions.owner(entity) → player`**  
  Returns the player who owns the given entity, according to the prop-protection system.

---

## Sound

The `sound` type plays sounds from a gate.

#### Type: `sound`

**Constructors**

- `new sound(string)`
- `new sound(entity, string)`
- `new sound(string, boolean)`
- `new sound(entity, string, boolean)`
- `new sound(string, boolean, number)`
- `new sound(entity, string, boolean, number)`
- `new sound(string, boolean, number, number)`
- `new sound(entity, string, boolean, number, number)`

**Methods**

- **`fadeOut(number) → void`**  
  Fades a sound out over <int> seconds.
- **`getPitch() → number`**  
  Returns the pitch of the sound.
- **`getVolume() → number`**  
  Returns the volume of the sound.
- **`isPlaying() → boolean`**  
  Returns true if the sound is playing.
- **`play() → void`**  
  Plays the sound.
- **`remove() → void`**  
  Destroys the sound object.
- **`setPitch(number) → void`**  
  Sets the pitch of the sound to <int>.
- **`setPitch(number, number) → void`**  
  Sets the pitch of the sound to <int1>, over time <int2>.
- **`setVolume(number) → void`**  
  Sets the volume of the sound to <int>.
- **`setVolume(number, number) → void`**  
  Sets the volume of the sound to <int1>, over time <int2>.
- **`stop() → void`**  
  Stops the sound.

---

## Errors

The `error` type is what `try`/`catch` catches and `system.throw` raises.

#### Type: `error`

**Constructors**

- `new error(string)`

**Methods**

- **`char() → number`**  
  Returns the character position on the line where the error occurred.
- **`line() → number`**  
  Returns the line number in the source where the error occurred.
- **`message() → string`**  
  Returns the error's message text.

---

## Types & Variants

The `type` value refers to a type itself (used with typed table access and `system.invoke`). `variant` holds a value whose type is decided at runtime.

#### Type: `type`

*Aliases:* `class`

**Operators**

- `!=`  (`type, type` → `boolean`)
- `==`  (`type, type` → `boolean`)

#### Type: `variant`

*Aliases:* `object`

---

*Generated from the Expression 3 helper data. For the always-current, installed-extension view, use the helper browser inside the Golem editor.*
