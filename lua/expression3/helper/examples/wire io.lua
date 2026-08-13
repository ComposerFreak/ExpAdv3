/***********************************************************************************
    E3 - Wiremod Input & Output

    This example shows how an Expression 3 gate talks to other Wiremod devices.
    Wire it up to some Constant Values and a Screen to see it working.
***********************************************************************************/
@name "E3 - Wire IO";

/*
    @input creates a wire INPUT port. The value is fed in from another wire device.
    @output creates a wire OUTPUT port. You write to it and other devices can read it.

    The class comes first, then the port name. Port names MUST be CamelCase
    (their first letter is capitalised) - this is how E3 tells ports apart from
    normal variables.
*/
@input number A;
@input number B;
@input entity Target;

@output number Sum;
@output number Product;
@output string Report;

/*
    The "Trigger" event fires every time one of your wired inputs changes.
    The name of the port that changed is passed to the callback as a string,
    so you can react to specific inputs if you want to.
*/
event.add("Trigger", "recalculate", function(string port) {

    // Inputs are read just like any other variable, using their port name.
    Sum = A + B;
    Product = A * B;

    // You can act on which input changed.
    if (port == "Target") {
        // Always check an entity is valid before using it.
        if (Target.isValid()) {
            // Note: when joining text, the string must be on the LEFT of the '+'.
            Report = "Target is a " + Target.getClass();
        } else {
            Report = "No target wired.";
        }
    }

    // Writing to an output variable instantly updates the wire port.
    // Here we push a quick status string out every time anything changes.
    Report = "A=" + A + " B=" + B + " Sum=" + Sum;
});

/*
    Outputs also hold whatever value they had last, so it is good practice to
    give them a sensible starting value when the gate first runs.
*/
Report = "Waiting for wire input...";
