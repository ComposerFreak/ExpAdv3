local extension = EXPR_LIB.RegisterExtension("propcore");

extension:SetSharedState();


--[[
	Prop Core methods
]]

local propcore;

local spawn_rate;

local spawnProp = function() end;

if SERVER then

	EXPR_LIB.ModelBL = {}

	EXPR_LIB.PropSpawnRate = EXPR_LIB.PropSpawnRate or {};

	hook.Call("Expression3.Extension.ModelBlackList", EXPR_LIB.ModelBL);

	spawn_rate = CreateConVar("wire_expression3_prop_rate", 4);

	timer.Create("Expression3.Props", 1, 0, function()
		EXPR_LIB.PropSpawnRate = {};
	end)

	hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Props", function(entity, ctx, env)
		ctx.data.props = {};
	end);

	hook.Add("Expression3.Entity.Stop", "Expression3.Props",function(entity, ctx)
		for _, prop in pairs( ctx.data.props ) do
			if IsValid(prop) then
				prop:Remove();
			end
		end

		ctx.data.props = nil
	end);

	hook.Add("PlayerDisconnected", "Expression3.Props", function( ply )
		for _, ctx in pairs(EXPR_LIB.GetAll()) do
			if (ctx.player == ply) then
				for _, prop in pairs( ctx.data.props ) do
					if IsValid(prop) then
						prop:Remove();
					end
				end

				ctx.data.props = nil
			end
		end
	end );

	local function incSpawn(context)

		local count = EXPR_LIB.PropSpawnRate[ context.player ] or 0;

		if count >= spawn_rate:GetInt() then
			return false;
		end

		EXPR_LIB.PropSpawnRate[ context.player ] = count + 1;

		return true;
	end

	function spawnProp(context, model, pos, ang, freeze)

		if not incSpawn(context) then
			return;
		end

		if EXPR_LIB.ModelBL[model] then
			return;
		end

		local p = context.player;
		local e = ents.Create("prop_physics");

		if not e then
			return;
		end

		e:SetOwner(p);

		e:SetModel(model);

		e:SetPos(pos or context.entity:GetPos());

		e:SetAngles(ang or Angle(0, 0, 0));

		e:Spawn();


		undo.Create("E3 spawned prop");

			undo.AddEntity(e);

			undo.SetPlayer(p);

		undo.Finish();

		local ph = e:GetPhysicsObject();

		if freeze and ph then
			ph:EnableMotion(false);
		end

		if CPPI then
			e:CPPISetOwner(p);
		end

		return e;
	end

--[[

]]

	function spawnSeat(context, model, pos, ang, freeze)

		if not incSpawn(context) then
			return;
		end

		if not model or model == "" then
			model = "models/nova/airboat_seat.mdl";
		end

		local p = context.player;
		local e = ents.Create("prop_vehicle_prisoner_pod");

		if not e then
			return;
		end

		e:SetOwner(p);

		e:SetModel(model);

		e:SetPos(pos or context.entity:GetPos());

		e:SetAngles(ang or Angle(0, 0, 0));

		e:Spawn();

		e:SetKeyValue( "limitview", 0 );

		table.Merge( e, { HandleAnimation = function(_, p) return p:SelectWeightedSequence( ACT_HL2MP_SIT ); end } );
		
		hook.Run("PlayerSpawnedVehicle", p, e);

		undo.Create("E3 spawned seat");

			undo.AddEntity(e);

			undo.SetPlayer(p);

		undo.Finish();

		local ph = e:GetPhysicsObject();

		if freeze and ph then
			ph:EnableMotion(false);
		end

		if CPPI then
			e:CPPISetOwner(p);
		end

		return e;
	end
	
end

extension:SetServerState();

--[[
	Prop Spawn Functions
]]

extension:RegisterLibrary("prop");

extension:RegisterFunction("prop", "spawn", "s", "e", 1, spawnProp, false);
extension:RegisterFunction("prop", "spawn", "s,v", "e", 1, spawnProp, false);
extension:RegisterFunction("prop", "spawn", "s,v,a", "e", 1, spawnProp, false);
extension:RegisterFunction("prop", "spawn", "s,v,a,b", "e", 1, spawnProp, false);

extension:RegisterFunction("prop", "spawn", "s,b", "e", 1, function(context, s, b)
	spawnProp(context, s, nil, nil, b);
end, false);

extension:RegisterFunction("prop", "spawn", "s,v,b", "e", 1, function(context, s, v, b)
	spawnProp(context, s, v, nil, b);
end, false);

--[[
	Seat Functions
]]

extension:RegisterFunction("prop", "spawnSeat", "s", "e", 1, spawnSeat, false);
extension:RegisterFunction("prop", "spawnSeat", "s,v", "e", 1, spawnSeat, false);
extension:RegisterFunction("prop", "spawnSeat", "s,v,a", "e", 1, spawnSeat, false);
extension:RegisterFunction("prop", "spawnSeat", "s,v,a,b", "e", 1, spawnSeat, false);

extension:RegisterFunction("prop", "spawnSeat", "s,b", "e", 1, function(context, s, b)
	spawnSeat(context, s, nil, nil, b);
end, false);

extension:RegisterFunction("prop", "spawnSeat", "s,v,b", "e", 1, function(context, s, v, b)
	spawnSeat(context, s, v, nil, b);
end, false);

--[[
	Spawn Functions
]]

extension:RegisterFunction("prop", "canSpawn", "", "b", 1, function(context)
	local count = EXPR_LIB.PropSpawnRate[ context.player ] or 0;

	if count >= spawn_rate:GetInt() then
		return false;
	end

	return true;
end, false);

--[[
	Manipulation
]]

extension:RegisterMethod("e", "remove", "", "", 0, function(context, e)
	if context:CanUseEntity(e) then
		e:Remove();
	end
end, false);

extension:RegisterMethod("e", "setPos", "v", "", 0, function(context, e, v)
	if context:CanUseEntity(e) then
		e:SetPos(v);
	end
end, false);

extension:RegisterMethod("e", "setAng", "a", "", 0, function(context, e, v)
	if context:CanUseEntity(e) then
		e:SetAngles(v);
	end
end, false);

extension:RegisterMethod("e", "setFrozen", "b", "", 0, function(context, e, b)
	if context:CanUseEntity( e ) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) and ph:GetUnFreezable() ~= true then
			ph:EnableMotion(b);
			ph:Wake();
		end
	end
end, false);

extension:RegisterMethod("e", "isFrozen", "", "b", 1, function(context, e)
	if IsValid(e) then
		local ph = e:GetPhysicsObject();
		if IsValid(ph) then return ph:IsMotionEnabled(); end
	end
	return false;
end, false);

extension:RegisterMethod("e", "setNotSolid", "b", "", 0, function(context, e, b)
	if context:CanUseEntity( e ) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) and ph:GetUnFreezable() ~= true then
			ph:SetSolid( b and SOLID_NONE or SOLID_VPHYSICS );
			ph:Wake();
		end
	end
end, false);

extension:RegisterMethod("e", "setParent", "e", "", 0, function(context, e, p)
	if context:CanUseEntity( e ) and IsValid(p) then
		e:SetParent(p);
	end
end, false);

extension:RegisterMethod("e", "unParent", "", "", 0, function(context, e)
	if context:CanUseEntity( e ) then
		e:SetParent(nil);
	end
end, false);

extension:RegisterMethod("e", "getParent", "", "e", 1, function(context, e)
	if IsValid(e) then return e:GetParent(); end
	--return Entity(0);
end, false);

extension:RegisterMethod("ph", "setPos", "v", "", 0, function(context, ph, v)
	if IsValid(ph) then
		if context:CanUseEntity( ph:GetEntity() ) then
			ph:SetPos(v);
		end
	end
end, false);

extension:RegisterMethod("ph", "setAng", "a", "", 0, function(context, ph, v)
	if IsValid(ph) then
		if context:CanUseEntity( ph:GetEntity() ) then
			ph:SetAngles(v);
		end
	end
end, false);

extension:RegisterMethod("ph", "setFrozen", "b", "", 0, function(context, ph, b)
	if IsValid(ph) then
		if context:CanUseEntity( ph:GetEntity() ) then
			ph:EnableMotion(b);
		end
	end
end, false);

extension:RegisterMethod("ph", "isFrozen", "", "b", 1, function(context, ph)
	if IsValid(ph) then return ph:IsMotionEnabled(b); end
	return false;
end, false);

--[[
	End of extention.
]]

extension:EnableExtension();