/***********************************************************************************
    Ruskeths - E3 Clock
***********************************************************************************/
@name "Ruskeths E3 Clock";
@server;

entity gate = system.getEntity();
    
/***********************************************************************************
    CLOCK BODY
***********************************************************************************/
hologram bg = hololib.create("models/sprops/geometry/t_fdisc_12.mdl");
bg.setPos(gate.toWorld(new vector(0, 0, -2)));
bg.setAng(gate.toWorld(new angle(0, 0, -90)));
bg.setScale(new vector(13, 1, 13));
bg.setMaterial("models/debug/debugwhite");
bg.setColor(new color(145, 140, 125));
bg.parent(gate);

hologram ring = hololib.create("models/sprops/geometry/fring_42.mdl");
ring.setPos(gate.toWorld(new vector(0, 0, 0)));
ring.setAng(gate.toWorld(new angle(0, 0, -90)));
ring.setScale(new vector(4.2, 1, 4.2));
ring.setMaterial("models/debug/debugwhite");
ring.setColor(new color(20, 20, 20));
ring.parent(gate);

hologram cog = hololib.create("models/sprops/geometry/t_fdisc_12.mdl");
cog.setPos(gate.toWorld(new vector(0, 0, 2)));
cog.setAng(gate.toWorld(new angle(0, 0, -90)));
cog.setScale(new vector(1, 3, 1));
cog.setMaterial("models/debug/debugwhite");
cog.setColor(new color(0, 0, 0));
cog.parent(gate);

/***********************************************************************************
    CLOCK FACE
***********************************************************************************/

function void buildHours(int x, int y, int hour) {
    string h = math.toString(hour);
    angle ang = gate.toWorld( new angle(0, -90, 90) );
    vector pos = gate.toWorld( new vector(x, y, 0) * 60);
    
    hologram frst = hololib.create("models/sprops/misc/alphanum/alphanum_" + h[1] + ".mdl");
    frst.setColor(new color(0, 0, 0));
    frst.setScale(new vector(0.5));
    frst.setAng(ang);
    if (2 == #h) pos += (frst.forward() * 2.5);
    
    frst.setPos(pos);
    frst.parent(gate);
    
    if (2 == #h) {
        hologram snd = hololib.create("models/sprops/misc/alphanum/alphanum_" + h[2] + ".mdl");
        snd.setColor(new color(0, 0, 0));
        snd.setScale(new vector(0.5));
        snd.setPos(pos - (frst.forward() * 5));
        snd.setAng(ang);
        snd.parent(gate);
    }
}

function void buildMinute(int x, int y, int minute) {
    hologram h = hololib.create("cube");
    h.setScale(new vector(0.1));
    h.setPos( gate.toWorld( new vector(x, y, 0) * 70) );
    h.parent(gate);
    
    if (minute % 5 == 0) {
        h.setColor(new color(0, 0, 0));
        int hour = minute / 5;
        if (hour == 0) hour = 12;
        buildHours(x, y, hour);
    }
}
    
function void buildDisplay(int minute) {
    int step = ((2*math.pi()) / 60);
    int j = (step * minute) - (step * 15);
    int x = math.sin(j);
    int y = math.cos(j);
    
    buildMinute(x, y, minute);
}

int i = 0;

timer.create("buildDisplay", 0.5, 60, function() {
    buildDisplay(i);
    i += 1;
});

/***********************************************************************************
    CLOCK HANDS
***********************************************************************************/
    
timer.create("buildHands", 7, 1, function() {
    
    hologram hs = hololib.create("cube");
    hs.setScale(new vector(6, 0.1, 0.1));
    hs.setColor(new color(227, 18, 53));
    hs.parent(gate);
    
    hologram hm = hololib.create("cube");
    hm.setScale(new vector(5, 0.1, 0.1));
    hm.parent(gate);
    
    hologram hh = hololib.create("cube");
    hh.setScale(new vector(3.5, 0.1, 0.1));
    hh.parent(gate);
    
    function void updateSeconds(int seconds) {
        int step = ((2*math.pi()) / 60);
        int j = (step * seconds) - (step * 15);
        int x = math.sin(j);
        int y = math.cos(j);
    
        vector of = gate.up() * 1;
        vector center = gate.getPos();
        vector aimpos = gate.toWorld( new vector(x, y, 0) * 70);
        angle ang = (center - aimpos).toAngle();
        hs.setPos((center + ((aimpos - center) * 0.5)) + (ang.forward() * 4) + of);
        hs.setAng(ang);
    };
    
    function void updateMinutes(int minutes) {
        int step = ((2*math.pi()) / 60);
        int j = (step * minutes) - (step * 15);
        int x = math.sin(j);
        int y = math.cos(j);
        
        vector of = gate.up() * 2;
        vector center = gate.getPos();
        vector aimpos = gate.toWorld( new vector(x, y, 0) * 60);
        angle ang = (center - aimpos).toAngle();
        hm.setPos((center + ((aimpos - center) * 0.5)) + (ang.forward() * 5) + of);
        hm.setAng(ang);
    };
    
    function void updateHours(int hours, int minutes) {
        int step = ((2*math.pi()) / 12);
        int j = (step * hours) + ((step / 60) * minutes) - (step * 15);
        int x = math.sin(j);
        int y = math.cos(j);
        
        vector of = gate.up() * 3;
        vector center = gate.getPos();
        vector aimpos = gate.toWorld( new vector(x, y, 0) * 60);
        angle ang = (center - aimpos).toAngle();
        hh.setPos((center + ((aimpos - center) * 0.5)) + (ang.forward() * 13) + of);
        hh.setAng(ang);
    };
        
    timer.create("moveHands", 1, 0, function() {
        date now = new date(time.now());
        updateSeconds(now.second);
        updateMinutes(now.minute);
        updateHours(now.hour, now.minute);
    });
});
    
/***********************************************************************************
    CLOCK TEXT
***********************************************************************************/ 
   
function void holoString(string text, hologram parent, vector pos, angle ang) {
    while(#text > 0) {
        string char = text[1];
        
        if (char != " ") {
            string prefix = "models/sprops/misc/alphanum/alphanum_";
            if (char.upper() != char) prefix += "l_";
            
            hologram letter = hololib.create(prefix + char + ".mdl");
            letter.setColor(new color(0, 255, 255));
            letter.setScale(new vector(0.5));
            letter.parent(parent);
            letter.setPos(pos);
            letter.setAng(ang);
            parent = letter;
        }
        
        text = text.sub(2);
        pos -= (parent.forward() * 5);
    }
}

timer.create("buildText", 5, 1, function() {
    angle ang = gate.toWorld( new angle(0, -90, 90) );
    
    vector pos = gate.toWorld( new vector(-10, -25, 0.5));
    holoString("Expression 3", bg, pos, ang);
    
    pos = gate.toWorld( new vector(10, -10, 0.5));
    holoString("Clock", bg, pos, ang);
});
    
/***********************************************************************************
    SCRIPT END
***********************************************************************************/