/***********************************************************************************
    E3 - Holograms

    Holograms are lightweight, client-side models you can spawn, move, colour
    and animate from your gate. They are perfect for displays, effects and UI.
    (For a much bigger build using these ideas, see the "clock" example.)
***********************************************************************************/
@name "E3 - Holograms";
@server;

entity gate = system.getEntity();

/*
    hololib.create(model) spawns a hologram and returns it. You can pass a full
    model path, or one of the built-in short names like "cube".
    Always check hololib.canCreate() if you are spawning a lot at once, so you
    stay within the server's hologram limit.
*/
hologram cube = hololib.create("cube");

// Place it one metre (about 40 units) above the gate.
// gate.toWorld(...) turns a position that is local to the gate into a world one,
// so the cube stays above the gate no matter how the gate is turned.
cube.setPos(gate.toWorld(new vector(0, 0, 40)));

// setScale takes a vector so you can stretch each axis independently.
cube.setScale(new vector(0.5, 0.5, 0.5));

// A material and colour to make it look nice.
cube.setMaterial("models/debug/debugwhite");
cube.setColor(new color(0, 200, 255));

// Parenting makes the hologram follow the gate around.
cube.parent(gate);

/*
    Animate it. We keep a spin angle and nudge it a little every tick,
    then feed it back into the cube's angle. Because the cube is parented to
    the gate, we build the angle in the gate's local space with toWorld().
*/
number spin = 0;

timer.create("spin", 0.03, 0, function() {
    spin += 2;                       // two degrees per tick
    if (spin >= 360) spin -= 360;    // keep it tidy within 0-360

    // Rotate around the up (yaw) axis.
    cube.setAng(gate.toWorld(new angle(0, spin, 0)));

    // Gently pulse the colour using a sine wave over time.
    number pulse = math.round((math.sin(time.curtime() * 2) + 1) * 127);
    cube.setColor(new color(pulse, 200, 255));
});
