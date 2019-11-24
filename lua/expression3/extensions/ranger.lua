local extension = EXPR_LIB.RegisterExtension("ranger");

extension:SetSharedState();

extension:RegisterLibrary("ranger");

--[[
	Default Settings
]]

local setDefaults = function(ctx)
	ctx.data.ranger = {
		hit_water = false,
		hit_entitys = true,
		ignore_world = false,
		default_zero = true,
		filter = {},
	};
end

hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Rangers", function(entity, ctx)
	ctx.data.ranger_persist = true;
	setDefaults(ctx);
end);

--[[
	Ranger Data
]]

extension:RegisterClass("rd", {"rangerdata"}, istable, notnil);
extension:RegisterAttribute("rd", "hit", "b", "Hit");
extension:RegisterAttribute("rd", "hit_sky", "b", "HitSky");
extension:RegisterAttribute("rd", "hit_nodraw", "b", "HitNoDraw");
extension:RegisterAttribute("rd", "hit_world", "b", "HitWorld");
extension:RegisterAttribute("rd", "hit_noneworld", "b", "HitNonWorld");
extension:RegisterAttribute("rd", "start_solid", "b", "StartSolid");
extension:RegisterAttribute("rd", "hit_pos", "v", "HitPos");
extension:RegisterAttribute("rd", "hit_norm", "v", "HitNormal");
extension:RegisterAttribute("rd", "normal", "v", "Normal");
extension:RegisterAttribute("rd", "normal", "n", "Normal");
extension:RegisterAttribute("rd", "fraction", "n", "Fraction");
extension:RegisterAttribute("rd", "fraction_solid", "n", "FractionLeftSolid");
extension:RegisterAttribute("rd", "hit_group", "n", "HitGroup");
extension:RegisterAttribute("rd", "hitbox", "n", "HitBox");
extension:RegisterAttribute("rd", "hit_bone", "n", "PhysicsBone");
extension:RegisterAttribute("rd", "hitbox_bone", "n", "HitBoxBone");
extension:RegisterAttribute("rd", "material_type", "n", "MatType");
extension:RegisterAttribute("rd", "distance", "n", "Distance");
extension:RegisterAttribute("rd", "hit_texture", "s", "HitTexture");
extension:RegisterAttribute("rd", "entity", "e", "Entity");

--[[
	Ranger Settings
]]

extension:RegisterFunction("ranger", "reset", "", "", 0, setDefaults, false);

extension:RegisterFunction("ranger", "hitWater", "b", "", 0, function(ctx, value)
	ctx.data.ranger.hit_water = value;
end, false);

extension:RegisterFunction("ranger", "hitWater", "", "b", 1, function(ctx)
	return ctx.data.ranger.hit_water or false;
end, false);


extension:RegisterFunction("ranger", "hitEntities", "b", "", 0, function(ctx, value)
	ctx.data.ranger.hit_entitys = value;
end, false);

extension:RegisterFunction("ranger", "hitEntities", "", "b", 1, function(ctx)
	return ctx.data.ranger.hit_entitys or false;
end, false);


extension:RegisterFunction("ranger", "ignoreWorld", "b", "", 0, function(ctx, value)
	ctx.data.ranger.ignore_world = value;
end, false);

extension:RegisterFunction("ranger", "ignoreWorld", "", "b", 1, function(ctx)
	return ctx.data.ranger.ignore_world or false;
end, false);


extension:RegisterFunction("ranger", "defaultZero", "b", "", 0, function(ctx, value)
	ctx.data.ranger.default_zero = value;
end, false);

extension:RegisterFunction("ranger", "defaultZero", "", "b", 1, function(ctx)
	return ctx.data.ranger.default_zero or false;
end, false);


extension:RegisterFunction("ranger", "persist", "b", "", 0, function(ctx, value)
	ctx.data.ranger_persist = value;
end, false);

extension:RegisterFunction("ranger", "persist", "", "b", 1, function(ctx)
	return ctx.data.ranger_persist or false;
end, false);

--[[
	Filter
]]

extension:RegisterFunction("ranger", "filter", "e", "", 0, function(ctx, ent)
	local filter = ctx.data.ranger.filter;
	filter[#filter + 1] = ent;
end, false);

extension:RegisterFunction("ranger", "filter", "t", "", 0, function(ctx, tbl)
	if not tbl or not tbl.tbl then return; end
	local filter = ctx.data.ranger.filter;
	for _, vr in pairs(tbl.tbl) do
		if vr and vr[1] == "e" and vr[2] then filter[#filter + 1] = vr[2]; end
	end
end, false);

extension:RegisterFunction("ranger", "filter", "", "t", 1, function(ctx)
	local t = {};
	local filter = ctx.data.ranger.filter;

	for _, e in pairs(filter) do
		t[#t + 1] = e;
	end

	return {tbl = t, children = {}, parents = {}, size = #t};
end, false);

extension:RegisterFunction("ranger", "clearFilter", "", "", 0, function(ctx, ent)
	ctx.data.ranger.filter = {};
end, false);

--[[
	Ranger Trace Function
]]

local vector_zero = Vector(0, 0 , 0)

local DoTrace = function(ctx, start, stop, min, max)

	local mask;
	local persist = ctx.data.ranger_persist;
	local data = ctx.data.ranger or {};
	local iworld = data.ignore_world;

	if data.hit_water then
		if data.hit_entitys then
			mask = -1;
		elseif (iworld) then
			iworld = false;
			mask = MASK_WATER;
		else
			mask = bit.bor(MASK_WATER, CONTENTS_SOLID);
		end
	elseif not data.hit_entitys then
		if iworld then
			iworld = false;
			mask = 0;
		else
			mask = MASK_NPCWORLDSTATIC;
		end
	end

	local result;

	if not min or not max then
		result = util.TraceLine({start = start, endpos = stop, filter = data.filter, mask = mask, ignoreworld = iworld});
	else
		result = util.TraceHull({start = start, endpos = stop, filter = data.filter, mask = mask, ignoreworld = iworld, maxs = max, mins = min});
	end

	if data.ignore_world and result.HitWorld then
		result.HitPos = data.default_zero and start or stop;
		result.HitWorld = false;
		result.Hit = false;
	elseif data.default_zero and not result.Hit then
		result.HitPos = start
	end

	result.Hit = result.Hit or false;
	result.HitSky = result.HitSky or false;
	result.HitNoDraw = result.HitNoDraw or false;
	result.HitWorld = result.HitWorld or false;
	result.HitNonWorld = result.HitNonWorld or false;
	result.StartSolid = result.StartSolid or false;
	result.HitPos = result.HitPos or vector_zero;
	result.HitNormal = result.HitNormal or vector_zero;
	result.Normal = result.Normal or vector_zero;
	result.Normal = result.Normal or vector_zero;
	result.Fraction = result.Fraction or 0;
	result.FractionLeftSolid = result.FractionLeftSolid or 0;
	result.HitGroup = result.HitGroup or 0;
	result.HitBox = result.HitBox or 0;
	result.PhysicsBone = result.PhysicsBone or 0;
	result.HitBoxBone = result.HitBoxBone or 0;
	result.MatType = result.MatType or 0;
	result.HitTexture = result.HitTexture or "";
	result.Entity = result.Entity or Entity(0);
	result.Distance = start:Distance(result.HitPos or start);

	if not persist then
		setDefaults(ctx);
	end

	return result;
end

--[[
	Ranger Offset
]]

extension:RegisterFunction("ranger", "offset", "v,v", "rd", 1, DoTrace, false);

extension:RegisterFunction("ranger", "offset", "v,v,n", "rd", 1, function(ctx, start, dir, range)
	return DoTrace(ctx, start, start + (dir * range));
end, false);

--[[
	Ranger OffsetHull
]]

extension:RegisterFunction("ranger", "offsetHull", "v,v,v,v", "rd", 1, function(ctx, start, stop, min, max)
	return DoTrace(ctx, start, stop, min, max);
end, false);

extension:RegisterFunction("ranger", "offsetHull", "v,v,n,v,v", "rd", 1, function(ctx, start, dir, range, min, max)
	return DoTrace(ctx, start, start + (dir * range), min, max);
end, false);

--[[
	Enable Extention
]]

extension:EnableExtension();