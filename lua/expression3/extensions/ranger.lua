local extension = EXPR_LIB.RegisterExtension("ranger");

--[[
	Traces aka rangers
]]

local function notNil(v)
	return v ~= nil;
end

local vector_zero = Vector(0, 0 , 0);

local function DoTrace(trace, start, stop, distance)
	start, stop = start or trace.start, stop or trace.stop;

	if (distance) then
		stop = start + (stop:GetNormalized( ) * distance);
	end

	trace.start, trace.stop = start, stop;

	local iworld = trace.ignore_world;
	local data = {start = start, endpos = stop, filter = filter};

	if (trace.hit_water) then
		if (not trace.ignore_entitys) then
			data.mask = -1;
		elseif (iworld) then
			iworld = false;
			data.mask = MASK_WATER;
		else
			data.mask = bit.bor(MASK_WATER, CONTENTS_SOLID);
		end
	elseif (trace.ignore_entitys) then
		if (iworld) then
			iworld = false;
			data.mask = 0;
		else
			data.mask = MASK_NPCWORLDSTATIC;
		end
	end

	local result;

	if (trace.mins and trace.maxs) then
		data.mins, data.maxs = trace.maxs, trace.maxs;
		result = util.TraceHull(data);
	else
		result = util.TraceLine(data);
	end

	if (iworld and result.HitWorld) then
		result.HitPos = trace.default_zero and start or stop;
		result.HitWorld = false;
		result.Hit = false;
	elseif (trace.default_zero and not trace.Hit) then
		trace.HitPos = start
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

	return result;
end

extension:RegisterClass("tr", {"trace", "trace.ranger", "ranger"}, istable, notnil);

extension:RegisterConstructor("tr", "", function()
	return {
		start = vector_zero,
		stop = vector_zero,
		default_zero = false,
		ignore_world = false,
		hit_water = false,
		ignore_entitys = false,
		mins = false,
		maxs = false,
		filter = {},
	}
end, true);

extension:RegisterAttribute("tr", "default_zero", "b");
extension:RegisterAttribute("tr", "ignore_world", "b");
extension:RegisterAttribute("tr", "ignore_entitys", "b");
extension:RegisterAttribute("tr", "hit_water", "b");

extension:RegisterAttribute("tr", "start", "v", "start");
extension:RegisterAttribute("tr", "end", "v", "stop");

extension:RegisterMethod("tr", "setHull", "v,v", "", 0, function(trace, min, max)
	trace.mins = min;
	trace.maxs = max;
end, true);

extension:RegisterMethod("tr", "setNoHull", "", "", 0, function(trace)
	trace.mins = nil;
	trace.maxs = nil;
end, true);

extension:RegisterMethod("tr", "getHull", "", "v", 2, function(trace)
	return trace.mins or vector_zero, trace.maxs or vector_zero;
end, true);

extension:RegisterMethod("tr", "fire", "", "trr", 1, DoTrace, true);

extension:RegisterMethod("tr", "fire", "v,v", "trr", 1, DoTrace, true);

extension:RegisterMethod("tr", "fire", "v,v,n", "trr", 1, DoTrace, true);

--[[
	Trace Results
]]

extension:RegisterClass("trr", {"trace.result", "rangerData"}, istable, notnil);

extension:RegisterAttribute("trr", "hit", "b", "Hit");
extension:RegisterAttribute("trr", "hit_sky", "b", "HitSky");
extension:RegisterAttribute("trr", "hit_nodraw", "b", "HitNoDraw");
extension:RegisterAttribute("trr", "hit_world", "b", "HitWorld");
extension:RegisterAttribute("trr", "hit_noneworld", "b", "HitNonWorld");
extension:RegisterAttribute("trr", "start_solid", "b", "StartSolid");
extension:RegisterAttribute("trr", "hit_pos", "v", "HitPos");
extension:RegisterAttribute("trr", "hit_norm", "v", "HitNormal");
extension:RegisterAttribute("trr", "normal", "v", "Normal");
extension:RegisterAttribute("trr", "normal", "n", "Normal");
extension:RegisterAttribute("trr", "fraction", "n", "Fraction");
extension:RegisterAttribute("trr", "fraction_solid", "n", "FractionLeftSolid");
extension:RegisterAttribute("trr", "hit_group", "n", "HitGroup");
extension:RegisterAttribute("trr", "hitbox", "n", "HitBox");
extension:RegisterAttribute("trr", "hit_bone", "n", "PhysicsBone");
extension:RegisterAttribute("trr", "hitbox_bone", "n", "HitBoxBone");
extension:RegisterAttribute("trr", "material_type", "n", "MatType");
extension:RegisterAttribute("trr", "distance", "n", "Distance");
extension:RegisterAttribute("trr", "hit_texture", "s", "HitTexture");
extension:RegisterAttribute("trr", "entity", "e", "Entity");


extension:EnableExtension();