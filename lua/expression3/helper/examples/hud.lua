/***********************************************************************************
    E3 - HUD & 2D Rendering

    Draws a small information panel onto your screen. Everything here happens
    client-side, because rendering only exists on the player's own machine.
***********************************************************************************/

//@client tells E3 to run this whole script on the client only, which is
//required for any of the render library to work.
@name "E3 - HUD";
@client;

/*
    All 2D drawing must be done inside a render event:
      - "RenderHUD"    draws over the player's HUD. It is passed the screen
                       width and height.
      - "RenderScreen" draws onto a wired E3 screen entity instead.

    The event fires once every frame, so whatever you draw here is what the
    player sees. 2D positions are given as vector2 (x, y) in pixels, measured
    from the top-left corner of the screen.
*/
event.add("RenderHUD", "panel", function(number w, number h) {

    // setColor sets the colour used by the shape-drawing functions.
    // A colour is red, green, blue and an optional alpha (0 = see-through).
    render.setColor(new color(0, 0, 0, 150));

    // drawBox(position, size) fills a rectangle.
    render.drawBox(new vector2(20, 20), new vector2(230, 96));

    // Text has its own font and its own colour.
    // setFont(name, size) then setFontColor(colour) before you draw it.
    render.setFont("DermaLarge", 22);
    render.setFontColor(new color(0, 255, 128));
    render.drawText(new vector2(32, 28), "Expression 3");

    render.setFont("DermaDefault", 18);
    render.setFontColor(new color(255, 255, 255));

    // system.getOwner() is the player who spawned the gate.
    player owner = system.getOwner();
    render.drawText(new vector2(32, 62), "Owner: " + owner.name());

    // A live frames-per-second counter. time.frametime() is the length of the
    // last frame in seconds, so 1 / frametime is the current FPS.
    number fps = math.round(1 / time.frametime());
    render.drawText(new vector2(32, 84), "FPS: " + fps);

    // You can use the passed-in width/height to anchor things to a corner.
    render.setFontColor(new color(180, 180, 180));
    render.drawText(new vector2(32, 104), "Screen: " + w + " x " + h);
});
