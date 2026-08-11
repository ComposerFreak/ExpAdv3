/***********************************************************************************
    E3 - Rangers (Traces)

    A "ranger" fires an invisible line through the world and tells you what it
    hit - the ground, a wall, a prop or a player. This is how you make sensors,
    laser pointers, auto-turrets and distance finders.
***********************************************************************************/
@name "E3 - Rangers";
@server;

// The gate entity is where we will fire our rangers from.
entity gate = system.getEntity();

/*
    Before firing, you can configure how rangers behave. These settings stay
    active until you change them again (or call ranger.reset()).
*/
ranger.hitEntities(true);   // let rangers hit props / players, not just the world
ranger.hitWater(false);     // do not stop at the water surface
ranger.filter(gate);        // ignore the gate itself so it never hits us

/*
    We run the sensor on a repeating timer. 0 repetitions means "forever".
*/
timer.create("scan", 0.5, 0, function() {

    // ranger.offset(start, direction, length) fires from a start position,
    // along a direction, for a given number of units, and returns a
    // 'rangerdata' object describing the result.
    vector start = gate.getPos();
    vector down  = new vector(0, 0, -1);

    rangerdata ground = ranger.offset(start, down, 20000);

    // The rangerdata object exposes its result through attributes.
    if (ground.hit) {
        // ground.distance is how far away the hit was, in source units.
        system.print("Ground is ", math.round(ground.distance), " units below.");

        // ground.hit_pos is the exact world position that was hit.
        // ground.hit_entity is what we hit (the world, a prop, etc).
        if (ground.hit_world) {
            system.print("It is the map.");
        } else {
            system.print("It is entity: ", ground.hit_entity.getClass());
        }
    } else {
        system.print("Nothing below within range.");
    }

    // A second ranger fired straight ahead, to see what the gate is facing.
    rangerdata infront = ranger.offset(start, gate.forward(), 500);

    if (infront.hit && !infront.hit_world) {
        // infront.hit_norm is the surface normal - the direction the surface
        // faces - which is handy for reflections or aligning holograms.
        system.print("Facing a ", infront.hit_entity.getClass(),
            " at ", math.round(infront.distance), " units.");
    }
});
