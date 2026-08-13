# Language Reference

A complete tour of the Expression 3 language. If you are new, read
[Getting Started](getting-started.md) first.

- [Lexical basics](#lexical-basics)
  - [Comments](#comments)
  - [Literals](#literals)
  - [Identifiers](#identifiers)
- [Types and variables](#types-and-variables)
  - [Declaring variables](#declaring-variables)
  - [Global variables](#global-variables)
  - [Type aliases](#type-aliases)
- [Operators](#operators)
  - [Arithmetic](#arithmetic)
  - [Assignment](#assignment)
  - [Comparison and logic](#comparison-and-logic)
  - [Bitwise](#bitwise)
  - [Special operators](#special-operators)
  - [The ternary operator](#the-ternary-operator)
  - [Multi‑comparison](#multi-comparison)
- [Casting](#casting)
- [Control flow](#control-flow)
  - [if / elseif / else](#if--elseif--else)
  - [while](#while)
  - [for](#for)
  - [foreach](#foreach)
  - [break, continue, return](#break-continue-return)
- [Tables and arrays](#tables-and-arrays)
- [Functions](#functions)
  - [Declared functions](#declared-functions)
  - [Inline and lambda functions](#inline-and-lambda-functions)
  - [Default parameters and varargs](#default-parameters-and-varargs)
  - [Table‑mapped parameters](#table-mapped-parameters)
  - [First‑class functions](#first-class-functions)
  - [Delegates](#delegates)
- [Error handling](#error-handling)
- [Object‑oriented programming](#object-oriented-programming)
  - [Classes](#classes)
  - [Inheritance and super](#inheritance-and-super)
  - [Interfaces](#interfaces)
  - [instanceof](#instanceof)
- [Events](#events)

---

## Lexical basics

### Comments

```cpp
// A single-line comment.

/*
    A block comment
    over several lines.
*/
```

### Literals

```cpp
42          // decimal number
3.14        // decimal number
0xFF        // hexadecimal number (255)
0b1010      // binary number (10)

true        // boolean
false       // boolean
nil         // the null / void value

"hello"     // string (may not contain a raw newline)
'hello'     // string (single quotes may span multiple lines)
"tab\there" // escapes: \n \t \r \" \' and \NNN (a byte value)

@"a.-b"     // a pattern literal (used by string pattern matching)
```

Numbers may be written in decimal, hexadecimal (`0x…`) or binary (`0b…`). All of
them are the same `number` type. Strings come in double‑quoted and single‑quoted
forms; single‑quoted strings are allowed to span multiple lines. Prefixing a
string with `@` makes it a **pattern** literal.

### Identifiers

Ordinary variable names follow the usual rules (letters, digits and
underscores, not starting with a digit). **Wire port names are special: they
must be CamelCase** (start with a capital letter). See
[Directives](getting-started.md#directives).

---

## Types and variables

E3 is **strongly typed**. Every variable has a fixed type, declared with the
type name first. The core value types are:

`number` (aka `int`), `string`, `boolean`, `vector`, `vector2`, `angle`,
`color`, `quaternion`, `entity`, `player`, `hologram`, `table`, and more — see
the [Standard Library & Types](standard-library.md) page for the full list.

### Declaring variables

```cpp
number health = 100;
string label  = "reactor";
boolean armed = true;

// Declare several of one type at once.
int x, y, z = 1, 2, 3;

// Assignment after declaration works as expected.
health = 50;
```

Because the language is typed, you cannot assign a value of the wrong type to a
variable — the compiler will reject it. Use a [cast](#casting) to convert
between types where a conversion exists.

### Global variables

By default a variable belongs to the block it is declared in. Prefix a
declaration with `global` to make it accessible throughout the script,
including inside functions and events:

```cpp
global number score = 0;
```

### Type aliases

Some types have more than one spelling; they are interchangeable:

| Canonical | Also accepted |
|-----------|---------------|
| `number` | `int` |
| `boolean` | `bool` |

---

## Operators

### Arithmetic

```cpp
a + b       // addition
a - b       // subtraction
a * b       // multiplication
a / b       // division
a % b       // modulo (remainder)
a ^ b       // exponent (power)
```

Many of these are overloaded for non‑number types where it makes sense — for
example `vector + vector`, `vector * number`, or `string + string` (and
`string + number`) for concatenation. When joining text, the **string must be
on the left** of the `+`.

### Assignment

```cpp
x = 5;      // assign

x += 2;     // add and assign      (x = x + 2)
x -= 2;     // subtract and assign
x *= 2;     // multiply and assign
x /= 2;     // divide and assign

x++;        // increment by one
x--;        // decrement by one

// Compound assignment supports multiple targets at once.
x, y += 1, 3;   // x = x + 1, y = y + 3
```

### Comparison and logic

```cpp
a == b      // equal
a != b      // not equal
a <  b      // less than
a <= b      // less than or equal
a >  b      // greater than
a >= b      // greater than or equal

a && b      // logical AND
a || b      // logical OR
!a          // logical NOT
```

### Bitwise

```cpp
a & b       // bitwise AND
a | b       // bitwise OR
a ^^ b      // bitwise XOR
a << b      // shift left
a >> b      // shift right
```

### Special operators

```cpp
#value      // length: characters in a string, entries in a table
$value      // delta: how much a value changed since the last assigment
```

`#` returns the length of a string or the size of a table. `$` (delta) returns
the difference between a value now and its previous value, which is
handy for detecting change over time on numbers, vectors and angles.

### The ternary operator

```cpp
int result = condition ? valueIfTrue : valueIfFalse;
```

### Multi‑comparison

You can compare one value against a **list** of values at once. This is true if
the value matches any entry in the list:

```cpp
if (state == [1, 2, 3, 4]) {
    // runs when state is 1, 2, 3 or 4
}
```

---

## Casting

The cast operator converts a value to another type, where a conversion exists.
Write the target type in parentheses immediately before the value (no space):

```cpp
number n = (number) "42";      // string -> number
string s = (string) 123;       // number -> string
boolean b = (boolean) someNumber;
```

If no conversion exists between the two types, the compiler reports an error.

---

## Control flow

### if / elseif / else

```cpp
if (health <= 0) {
    system.print("Dead");
} elseif (health < 25) {
    system.print("Critical");
} else {
    system.print("OK");
}
```

A branch may be a single statement instead of a block:

```cpp
if (armed) fire();
```

### while

```cpp
while (count < 10) {
    count++;
}
```

### for

E3's `for` is a **numeric** loop: an iterator variable counts from a start value
to an end value, optionally by a step. All three parts are numbers.

```cpp
// i goes 1, 2, 3, ... up to 10.
for (int i = 1; 10) {
    system.out(i);
}

// With a step: i goes 1, 3, 5, ... up to 20.
for (int i = 1; 20; 2) {
    system.out(i);
}
```

The three parts are **start**, **end**, and an optional **step** — not the
C‑style "condition; increment" form.

### foreach

`foreach` iterates over a table. Provide a type and name for the value, and
optionally a key before `as`:

```cpp
// Value only.
foreach (int value in myTable) {
    system.out(value);
}

// Key and value.
foreach (string key as int value in myTable) {
    system.out(key, " = ", value);
}
```

### break, continue, return

```cpp
for (int i = 1; 100) {
    if (i == 50) break;      // leave the loop entirely
    if (i % 2 == 0) continue; // skip to the next iteration
}

return;                       // leave a function
return a, b, c;               // functions may return multiple values
```

---

## Tables and arrays

Tables and arrays are the same structure in E3. Create them inline, or with the
`new` constructor:

```cpp
// Inline: array-style and/or keyed entries.
table t = { 10, 20, 30 };
table config = { name = "reactor", [42] = "answer" };

// Constructor style.
table nums = new table(1, 2, 3);
```

Because values in a table can be of any type, you specify the type when reading
a value so the result is typed:

```cpp
nums[1, int] = 22;                 // set index 1 to a number
int first = nums[1, int];          // read index 1 as a number

int count = #nums;                 // length with the # operator
```

---

## Functions

E3 functions are **first‑class values**: they have a type (`function`), can be
stored in variables, passed as arguments and returned from other functions.
There are several ways to define one.

### Declared functions

The traditional form names the return type, the function name, and its
parameters. A function may return **multiple values** of its return type.

```cpp
function int add(int a, int b) {
    return a + b;
}

function int stats(int a) {
    return a, a + 1, a + 2;   // three numbers
}

int x, y, z = stats(10);      // capture all three
```

Use `void` as the return type for a function that returns nothing.

### Inline and lambda functions

Assign a function to a variable of type `function`. Two spellings are available:

```cpp
// Inline form.
function multiply = function(int a, int b) {
    return a * b;
};

// Lambda (arrow) form.
function subtract = (int a, int b) => {
    return a - b;
};
```

Functions defined this way are values, so they can't be *called by name* like a
declared function; call them through the variable, an event, `system.invoke`,
or a [delegate](#delegates).

### Default parameters and varargs

Parameters may have default values, and a function may accept a variable number
of trailing arguments with `...`:

```cpp
function greet = (string name, string greeting = "Hello") => {
    return greeting + " " + name;
};

function int sumAll(int first, ...) {
    // ... collects any extra arguments
    return first;
}
```

### Table‑mapped parameters

A function can take a single table and map its keys to named parameters:

```cpp
function int build( {int width, int height = 10} ) {
    // width and height come from the passed table's keys.
    return width + height + depth;
}

table spec = { width = 5, depth = 2 };
build(spec);
```

### First‑class functions

Because functions are values, you can hand them to library functions that
expect a callback — most commonly events and timers:

```cpp
event.add("Think", "loop", function() {
    // runs every tick
});

int result = system.invoke(number, 1, add, 2, 4);
// system.invoke(returnType, returnCount, theFunction, arguments...)
```

### Delegates

A **delegate** is a named template describing a function's signature. You can
assign any matching function to it and then call it by name:

```cpp
// Declare the shape: returns 1 number, takes two numbers.
delegate int Operation(int, int) {
    return 1;   // the number of values returned
}

// Assign a matching function and call it.
Operation = add;
int total = Operation(2, 4);
```

---

## Error handling

Runtime problems are represented by the `error` type. Wrap risky code in
`try` / `catch` so a failure doesn't crash the whole script:

```cpp
try {
    // Create and throw an error.
    error e = new error("Something went wrong.");
    system.throw(e);
}
catch (theError) {
    // theError is the caught error object.
    string msg = theError.message();
    system.print("Caught: ", msg);
}
```

`system.throw(error)` raises an error up the stack; if nothing catches it, the
gate reports the error (with its E3 line and column) and shuts down.

---

## Object‑oriented programming

E3 has full OOP: classes with attributes, constructors and methods; single
inheritance with `super`; and interfaces.

### Classes

```cpp
class Reactor {
    // Attributes (fields) with default values.
    int power = 0;
    string label = "core";

    // A constructor creates an instance. Use `this` for the instance.
    Reactor(int startPower) {
        this.power = startPower;
    }

    // Methods operate on the instance.
    method int getPower() {
        return power;   // attributes are visible directly inside methods
    }

    method void addPower(int amount) {
        this.power += amount;
    }
}

// `new` calls the constructor.
Reactor core = new Reactor(50);
core.addPower(10);
int p = core.getPower();     // 60
```

### Inheritance and super

A class may `extend` another, inheriting its attributes and methods. Use
`super` to reach the parent:

```cpp
class BigReactor extends Reactor {
    BigReactor() {
        // ... set up
    }
}
```

### Interfaces

An `interface` is a template of methods a class must provide. A class states it
fulfils an interface with `implements`:

```cpp
interface Powered {
    // Method templates: the body's return states the number of return values.
    method int getPower(int, int) {
        return 1;
    }
}

class Battery implements Powered {
    Battery() { }

    // If this method were missing, the compiler would reject the class.
    method int getPower(int a, int b) {
        return a + b;
    }
}
```

An interface can be used as a type, letting you treat different classes
uniformly:

```cpp
Powered thing = (Powered) new Battery();
```

### instanceof

`instanceof` tests whether an object is, extends, or implements a given type:

```cpp
if (core instanceof Reactor) {
    // true
}
```

---

## Events

Events let your script react to things happening in the game. Attach a function
with `event.add(name, uniqueID, callback)`; the callback's parameters must match
what the event provides. Remove it later with `event.remove(name, uniqueID)`.

```cpp
event.add("OnPlayerChat", "chat", function(player ply, string text, number team) {
    if (text == "!ping") {
        system.print(ply.name(), " said ping");
    }
});
```

Common events include `Think` (every tick), `Trigger` (a wire input changed),
`RenderHUD` / `RenderScreen` (drawing), the `OnPlayer…` events, and
`PlayerButtonDown` / `PlayerButtonUp`. See the
[Standard Library & Types](standard-library.md#events) page for the full list
and their parameters.

---

Next: the **[Standard Library & Types](standard-library.md)**.
