--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::MISC::
	For things that need a home.
]]

local extenstion = EXPR_LIB.RegisterExtenstion("util");

--[[
	Game for all your game information.
]]

extenstion:RegisterLibrary("game");

extenstion:RegisterFunction("game", "map", "", "s", 1, game.GetMap);

extenstion:RegisterFunction("game", "hostname", "", "s", 1, function()
	return GetConVar("hostname"):GetString();
end, true);

extenstion:RegisterFunction("game", "isLan", "", "b", 1, function()
	return GetConVar("sv_lan"):GetBool()
end, true);

extenstion:RegisterFunction("game", "gamemode", "", "s", 1, function()
	return gmod.GetGamemode().Name;
end, true);

extenstion:RegisterFunction("game", "isSinglePlayer", "", "b", 1, game.SinglePlayer, true);

extenstion:RegisterFunction("game", "isSinglePlayer", "", "b", 1, game.IsDedicated, true);

extenstion:RegisterFunction("game", "numPlayers", "", "n", 1, function()
	return #player.GetAll();
end, true);

extenstion:RegisterFunction("game", "maxPlayers", "", "n", 1, game.MaxPlayers, true);

extenstion:RegisterFunction("game", "gravity", "", "n", 1, function()
	return GetConVar("sv_gravity"):GetFloat()
end, true);

extenstion:RegisterFunction("game", "propGravity", "", "v", 1, physenv.GetGravity, true);

extenstion:RegisterFunction("game", "airDensity", "", "n", 1, physenv.GetAirDensity, true);

extenstion:RegisterFunction("game", "maxFrictionMass", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxFrictionMass"];
end, true);

extenstion:RegisterFunction("game", "minFrictionMass", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MinFrictionMass"];
end, true);

extenstion:RegisterFunction("game", "speedLimit", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxVelocity"];
end, true);

extenstion:RegisterFunction("game", "angSpeedLimit", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxAngularVelocity"];
end, true);

extenstion:RegisterFunction("game", "tickInterval", "", "n", 1, engine.TickInterval, true);

extenstion:RegisterFunction("game", "tickRate", "", "n", 1, function()
	return 1 / engine.TickInterval();
end, true);

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

extenstion:RegisterClass("tr", {"trace.ranger", "ranger"}, istable, notnil);

extenstion:RegisterConstructor("tr", "", function()
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

extenstion:RegisterAtribute("tr", "default_zero", "b");
extenstion:RegisterAtribute("tr", "ignore_world", "b");
extenstion:RegisterAtribute("tr", "ignore_entitys", "b");
extenstion:RegisterAtribute("tr", "hit_water", "b");

extenstion:RegisterAtribute("tr", "start", "v", "start");
extenstion:RegisterAtribute("tr", "end", "v", "stop");

extenstion:RegisterMethod("tr", "setHull", "v,v", "", 0, function(trace, min, max)
	trace.mins = min;
	trace.maxs = max;
end, true);

extenstion:RegisterMethod("tr", "setNoHull", "", "", 0, function(trace)
	trace.mins = nil;
	trace.maxs = nil;
end, true);

extenstion:RegisterMethod("tr", "getHull", "", "v", 2, function(trace)
	return trace.mins or vector_zero, trace.maxs or vector_zero;
end, true);

extenstion:RegisterMethod("tr", "fire", "", "trr", 1, DoTrace, true);

extenstion:RegisterMethod("tr", "fire", "v,v", "trr", 1, DoTrace, true);

extenstion:RegisterMethod("tr", "fire", "v,v,n", "trr", 1, DoTrace, true);

--[[
	Trace Results
]]

extenstion:RegisterClass("trr", {"trace.result", "rangerData"}, istable, notnil);

extenstion:RegisterAtribute("trr", "hit", "b", "Hit");
extenstion:RegisterAtribute("trr", "hit_sky", "b", "HitSky");
extenstion:RegisterAtribute("trr", "hit_nodraw", "b", "HitNoDraw");
extenstion:RegisterAtribute("trr", "hit_world", "b", "HitWorld");
extenstion:RegisterAtribute("trr", "hit_noneworld", "b", "HitNonWorld");
extenstion:RegisterAtribute("trr", "start_solid", "b", "StartSolid");
extenstion:RegisterAtribute("trr", "hit_pos", "v", "HitPos");
extenstion:RegisterAtribute("trr", "hit_norm", "v", "HitNormal");
extenstion:RegisterAtribute("trr", "normal", "v", "Normal");
extenstion:RegisterAtribute("trr", "normal", "n", "Normal");
extenstion:RegisterAtribute("trr", "fraction", "n", "Fraction");
extenstion:RegisterAtribute("trr", "fraction_solid", "n", "FractionLeftSolid");
extenstion:RegisterAtribute("trr", "hit_group", "n", "HitGroup");
extenstion:RegisterAtribute("trr", "hitbox", "n", "HitBox");
extenstion:RegisterAtribute("trr", "hit_bone", "n", "PhysicsBone");
extenstion:RegisterAtribute("trr", "hitbox_bone", "n", "HitBoxBone");
extenstion:RegisterAtribute("trr", "material_type", "n", "MatType");
extenstion:RegisterAtribute("trr", "distance", "n", "Distance");
extenstion:RegisterAtribute("trr", "hit_texture", "s", "HitTexture");
extenstion:RegisterAtribute("trr", "entity", "e", "Entity");

extenstion:EnableExtenstion();