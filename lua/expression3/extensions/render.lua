--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Rendering Features::
	``````````````````````
]]

local FONT, FSIZE;
local TEXTURE, MATERIAL;
local DRED, DGREEN, DBLUE, DALPHA;
local TRED, TGREEN, TBLUE, TALPHA;

E3Fonts = {};

local function setFont(basefont, size)
	local font = "WireEGP_" .. size .. "_" .. basefont;

	if (not E3Fonts[font]) then
		local fontTable = {
			font = basefont,
			size = size,
			weight = 800,
			antialias = true,
			additive = false
		};

		surface.CreateFont(font, fontTable);

		E3Fonts[font] = font;
	end

	FONT = font;
	FSIZE = size;
end

local function resetRenderer()
	DRED, DGREEN, DBLUE, DALPHA = 255, 255, 255, 255;
	TRED, TGREEN, TBLUE, TALPHA = 0, 0, 0, 255;
	TEXTURE, MATERIAL = 0, Material("");
	setFont("Arial", 12);
end

if (CLIENT) then
	resetRenderer();
	hook.Add("Expression3.Entity.PostDrawScreen", "Expression3.Render.Reset", resetRenderer);
end

local function preDraw(ctx, textured)
	if (not EXPR3_DRAWSCREEN) then
		ctx:Throw("Attempted to render outside of a rendering event.");
	end

	surface.SetDrawColor(DRED, DGREEN, DBLUE, DALPHA);

	if (textured and TEXTURE > 0) then
		surface.SetTexture(TEXTURE);
		return true;
	else
		draw.NoTexture();
		return false;
	end
end

local function preText(ctx)
	if (not EXPR3_DRAWSCREEN) then
		ctx:Throw("Attempted to render outside of a rendering event.");
	end

	surface.SetFont(FONT);
	surface.SetTextColor(TRED, TGREEN, TBLUE, TALPHA);
end

--[[
	Extension
]]

local extension = EXPR_LIB.RegisterExtension("render");

extension:SetClientState();

extension:RegisterLibrary("render");

extension:RegisterFunction("render", "setScreenRefresh", "b", "", 0, function(ctx, b)
	ctx.entity.NoScreenRefresh = not b;
end, false);

extension:RegisterFunction("render", "getScreenRefresh", "", "b", 1, function(ctx)
	return not (ctx.entity.NoScreenRefresh or false);
end, false);

--[[
	Getter and Setter for color and font
]]

extension:RegisterFunction("render", "setFontColor", "n,n,n", "", 0, function(r, g, b)
	TRED, TGREEN, TBLUE, TALPHA = r, g, b, 255;
end, true);

extension:RegisterFunction("render", "setFontColor", "n,n,n,n", "", 0, function(r, g, b, a)
	TRED, TGREEN, TBLUE, TALPHA= r, g, b, a;
end, true);

extension:RegisterFunction("render", "setFontColor", "c", "", 0, function(c)
	TRED, TGREEN, TBLUE, TALPHA = c.r, c.g, c.b, c.a;
end, true);

extension:RegisterFunction("render", "getFontColor", "", "c", 1, function()
	return Color(TRED, TGREEN, TBLUE, TALPHA);
end, true);

extension:RegisterFunction("render", "setColor", "n,n,n", "", 0, function(r, g, b)
	DRED, DGREEN, DBLUE, DALPHA = r, g, b, 255;
end, true);

extension:RegisterFunction("render", "setColor", "n,n,n,n", "", 0, function(r, g, b, a)
	DRED, DGREEN, DBLUE, DALPHA = r, g, b, a;
end, true);

extension:RegisterFunction("render", "setColor", "c", "", 0, function(c)
	DRED, DGREEN, DBLUE, DALPHA = c.r, c.g, c.b, c.a;
end, true);

extension:RegisterFunction("render", "getColor", "", "c", 1, function()
	return Color(DRED, DGREEN, DBLUE, DALPHA);
end, true);

extension:RegisterFunction("render", "setFont", "s,n", "", 0, setFont, true);

--[[
	Materials and Textures
]]

extension:RegisterFunction("render", "setTexture", "", "", 0, function(texture)
	TEXTURE = 0;
end, true);

extension:RegisterFunction("render", "setTexture", "s", "", 0, function(texture)
	TEXTURE = surface.GetTextureID(texture) or 0;
end, true);

--[[
	Polys
]]

local function cc(a, b, c)
	local area = (a.x - c.x) * (b.y - c.y) - (b.x - c.x) * (a.y - c.y)
	return area > 0
end

local function drawPoly(points)
	render.CullMode(cc(points[1], points[2], points[3]) and MATERIAL_CULLMODE_CCW or MATERIAL_CULLMODE_CW);
	surface.DrawPoly(points)
	render.CullMode(MATERIAL_CULLMODE_CCW);
end

local function drawPolyOutline(points)
	for i=1, #points do
		if i==#points then
			surface.DrawLine( points[i].x, points[i].y, points[1].x, points[1].y )
		else
			surface.DrawLine( points[i].x, points[i].y, points[i+1].x, points[i+1].y )
		end
	end
end

--[[
	Basic Shapes
]]

extension:RegisterFunction("render", "drawLine", "v2,v2", "", 0, function(ctx, s, e)
	preDraw(ctx, false);
	surface.DrawLine(s.x, s.y, e.x, e.y);
end, false);

extension:RegisterFunction("render", "drawBox", "v2,v2", "", 0, function(ctx, p, w)
	preDraw(ctx, true);
	surface.DrawTexturedRect(p.x, p.y, w.x, w.y);
end, false)

extension:RegisterFunction("render", "drawBox", "v2,v2,n", "", 0, function(ctx, p, w, a)
	preDraw(ctx, true);
	surface.DrawTexturedRectRotated(p.x, p.y, w.x, w.y, a);
end, false);

extension:RegisterFunction("render", "drawBoxOutline", "v2,v2", "", 0, function(ctx, p, w)
	preDraw(ctx, false);

	local x, y = p.x, p.y;
	local w, h = w.x, w.y;

	drawPolyOutline({x = x, y = y}, {x = x + w, y = y}, {x = x + w, y = y + h}, {x = x, y = y + h});
end, false);

extension:RegisterFunction("render", "drawTriangle", "v2,v2,v2", "", 0, function(ctx, a, b, c)
	preDraw(ctx, true);
	drawPoly({a, b, c});
end, false);

extension:RegisterFunction("render", "drawTriangleOutline", "v2,v2,v2", "", 0, function(ctx, a, b, c)
	preDraw(ctx, false);
	drawPolyOutline({a, b, c});
end, false);

extension:RegisterFunction("render", "drawCircle", "v2,n", "", 0, function(ctx, p, r)
	preDraw(ctx, true);

	local vertices = { }

	for i=1, 30 do
		vertices[i] = {x = p.x + math.sin(-math.rad(i/30*360)) * r, y = p.y + math.cos(-math.rad(i/30*360)) * r};
	end

	drawPoly(vertices);
end, false);

extension:RegisterFunction("render", "drawCircleOutline", "v2,n", "", 0, function(ctx, p, r)
	preDraw(ctx, false);

	local vertices = { };

	for i=1, 30 do
		vertices[i] = {x = p.x + math.sin(-math.rad(i/30*360)) * r, y = p.y + math.cos(-math.rad(i/30*360)) * r};
	end

	drawPolyOutline(vertices);
end, false);

extension:RegisterFunction("render", "drawPoly", "t", "", 0, function(ctx, tbl)
	preDraw(ctx, true);

	local vertices = { };

	for _, v in pairs(tbl.tbl) do
		if (v and v[1] == "_v2") then
			vertices[#vertices + 1] = v[2];
		end
	end

	drawPoly(vertices);
end, false);

extension:RegisterFunction("render", "drawPolyOutline", "t", "", 0, function(ctx, tbl)
	preDraw(ctx, false);

	local vertices = { };

	for _, v in pairs(tbl.tbl) do
		if (v and v[1] == "_v2") then
			vertices[#vertices + 1] = v[2];
		end
	end

	drawPolyOutline(vertices);
end, false);

--[[
	Text
]]

extension:RegisterFunction("render", "getTextSize", "s", "n", 2, function(str)
	surface.setFont(FONT);
	return surface.GetTextSize(str);
end, true);

extension:RegisterFunction("render", "drawText", "v2,s", "n", 2, function(ctx, p, str)
	preText(ctx);
	surface.SetTextPos(p.x, p.y);
	surface.DrawText(str);
end, false);

extension:EnableExtension();
