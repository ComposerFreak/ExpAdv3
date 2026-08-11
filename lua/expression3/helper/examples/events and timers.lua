/***********************************************************************************
    E3 - Events & Timers

    Events let your gate react to things that happen in the game.
    Timers let your gate do things later, or on a repeating schedule.
***********************************************************************************/
@name "E3 - Events and Timers";
@server;

/*
    event.add(eventName, uniqueID, callback) attaches a function to an event.
    The unique ID lets you add (or later remove) a specific listener.
    The callback's parameters must match what the event provides.
*/

// OnPlayerJoin gives you the player who just connected.
event.add("OnPlayerJoin", "welcome", function(player ply) {
    system.print(ply.name(), " joined the server!");
});

// OnPlayerChat gives the speaker, their message, and whether it was team chat.
event.add("OnPlayerChat", "chatbot", function(player ply, string text, number team) {

    // A tiny chat command: anyone who types !time gets the server uptime.
    if (text == "!time") {
        number up = math.round(time.curtime());
        system.print(ply.name(), ", the server has been up ", up, " seconds.");
    }
});

// OnPlayerDeath gives the victim, the inflictor and the attacker.
event.add("OnPlayerDeath", "obituary", function(player victim, entity inflictor, entity attacker) {
    system.print(victim.name(), " was killed.");
});

/*
    Timers.
    timer.simple(delay, callback) runs a function once, after a delay.
    timer.create(name, delay, repetitions, callback) runs it repeatedly;
    a repetition count of 0 means forever.
*/

// Run something a single time, two seconds after the gate starts.
timer.simple(2, function() {
    system.print("Gate is now online.");
});

// A heartbeat that ticks five times, then a summary.
int ticks = 0;

timer.create("heartbeat", 1, 5, function() {
    ticks += 1;
    system.print("Tick ", ticks);

    // On the final tick, tidy up and remove one of our event listeners.
    if (ticks == 5) {
        system.print("Done ticking.");

        // event.remove(eventName, uniqueID) detaches a listener you added.
        event.remove("OnPlayerDeath", "obituary");
    }
});
