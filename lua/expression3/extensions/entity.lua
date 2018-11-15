--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Entity Extension::
]]

local extension = EXPR_LIB.RegisterExtension("entity");

extension:SetSharedState();

--[[
	Entity Class
]]

function isEnt(e)
	return IsEntity(e) and not e:IsPlayer();
end

extension:RegisterClass("e", {"entity"}, isEnt, IsValid);

extension:RegisterConstructor("e", "n", Entity, true);

extension:RegisterWiredInport("e", "ENTITY");

extension:RegisterWiredOutport("e", "ENTITY");

--[[
	Player Class
]]

local function isPlayer(p)
	return p:IsPlayer()
end

extension:RegisterExtendedClass("p", {"player"}, "e", isPlayer, IsValid);

extension:RegisterWiredInport("p", "ENTITY");

extension:RegisterWiredOutport("p", "ENTITY");

--[[
	Bone Class
]]

extension:RegisterClass("ph", {"bone", "physics"}, IsValid, IsValid);

extension:RegisterMethod("e", "physics", "", "ph", 1, "GetPhysicsObject");

extension:RegisterMethod("e", "getBoneCount", "", "n", 1, "GetPhysicsObjectCount");

extension:RegisterMethod("e", "getBoneIndex", "", "n", 1, "GetPhysicsObjectNum");

--[[
	Operators
]]

extension:RegisterOperator("eq", "e,e", "b", 1);
extension:RegisterOperator("neq", "e,e", "b", 1);

extension:RegisterOperator("eq", "e,p", "b", 1);
extension:RegisterOperator("neq", "e,p", "b", 1);

extension:RegisterOperator("eq", "ph,ph", "b", 1);
extension:RegisterOperator("neq", "ph,ph", "b", 1);

extension:RegisterOperator("eq", "p,p", "b", 1);
extension:RegisterOperator("neq", "p,p", "b", 1);

--[[
	Casting operators.
]]

extension:RegisterCastingOperator("e", "p", function(context, e)
	if (IsValid(e) and e:IsPlayer()) then
		return e;
	end

	context:Throw("Attempted to cast none player entity to player.");
end, false);

extension:RegisterCastingOperator("p", "e", function(ctx, p)
	return p
end, false);

--[[
	IsValid
]]

extension:RegisterMethod("e", "isValid", "", "b", 1, function(e)
	return IsValid(e);
end, true);

extension:RegisterMethod("ph", "isValid", "", "b", 1, function(e)
	return IsValid(e);
end, true);

--[[
	General Methods
]]

extension:RegisterMethod("e", "class", "", "s", 1, "GetClass");

extension:RegisterMethod("e", "getModel", "", "s", 1, "GetModel");

extension:RegisterMethod("e", "id", "", "n", 1, "EntIndex");

--[[
	Position & Angle
]]

extension:RegisterMethod("e", "getPos", "", "v", 1, "GetPos");

extension:RegisterMethod("e", "getAng", "", "a", 1, "GetAngles");

extension:RegisterMethod("ph", "pos", "", "v", 1, "GetPos");

extension:RegisterMethod("ph", "ang", "", "v", 1, "GetAng");

--[[
	OBB Mins / Maxs
]]

extension:RegisterMethod("e", "boxCenter", "", "v", 1, "OBBCenter");

extension:RegisterMethod("e", "boxMins", "", "v", 1, "OBBMins");

extension:RegisterMethod("e", "boxMaxs", "", "v", 1, "OBBMaxs");

extension:RegisterMethod("e", "boxSize", "", "v", 1, function(e)
	return e:OBBMaxs() - e:OBBMins();
end, true);

extension:RegisterMethod("e", "worldSpaceAABB", "", "v", 2, "WorldSpaceAABB");

extension:RegisterMethod("e", "worldSpaceCenter", "", "v", 2, "WorldSpaceCenter");

extension:RegisterMethod("e", "radius", "", "n", 2, "BoundingRadius");

--[[
	Get Direction
]]

extension:SetSharedState();

extension:RegisterMethod("e", "forward", "", "v", 1, "GetForward");

extension:RegisterMethod("e", "up", "", "v", 1, "GetUp");

extension:RegisterMethod("e", "right", "", "v", 1, "GetRight");

extension:RegisterMethod( "ph", "forward", "", "v", 1, function(e)
	if IsValid(e) then
		return e:LocalToWorld( Vector(1,0,0) ) - e:GetPos( );
	end

	return Vector(0, 0, 0);
end, true );

extension:RegisterMethod( "ph", "right", "", "v", 1, function(e)
	if IsValid(e) then
		return e:LocalToWorld( Vector(0,-1,0) ) - e:GetPos( );
	end

	return Vector(0, 0, 0);
end, true );

extension:RegisterMethod( "ph", "up", "", "v", 1, function(e)
	if IsValid(e) then
		return e:LocalToWorld( Vector(0,0,1) ) - e:GetPos( );
	end

	return Vector(0, 0, 0);
end, true );

--[[
	World and Local Vector and Angles
]]

extension:RegisterMethod("e", "toWorld", "v", "v", 1, "LocalToWorld");

extension:RegisterMethod("e", "toWorld", "a", "a", 1, "LocalToWorldAngles");

extension:RegisterMethod("ph", "toWorld", "v", "v", 1, "LocalToWorld");

extension:RegisterMethod("ph", "toLocal", "v", "v", 1, "WorldToLocal");

extension:RegisterMethod("e", "toLocal", "v", "v", 1, "WorldToLocal");

extension:RegisterMethod("e", "toLocal", "a", "a", 1, "WorldToLocalAngles");


--[[
	Velecotity
]]

extension:RegisterMethod("e", "Vel", "", "v", 1, "GetVelocity");

extension:RegisterMethod("ph", "Vel", "", "v", 1, "GetVelocity");

extension:RegisterMethod("e", "angVel", "", "a", 1, function(e)
	local ph = e:GetPhysicsObject();

	if IsValid(ph) then
		local a = ph:GetAngleVelocity();
		return Angle(a.x, a.y, a.z);
	end

	return Angle(0, 0, 0);
end, true);

extension:RegisterMethod("ph", "angVel", "", "a", 1, function(ph)
	if IsValid(ph) then
		local a = ph:GetAngleVelocity();
		return Angle(a.x, a.y, a.z);
	end

	return Angle(0, 0, 0);
end, true);

--[[
	Damping
]]

extension:RegisterMethod("ph", "damping", "", "n", 1, function(ph)
	if IsValid(ph) then
		return ph:GetDamping(), nil;
	end

	return 0;
end, true);

extension:RegisterMethod("ph", "angDamping", "", "n", 1, function(ph)
	if IsValid(ph) then
		local a, b = ph:GetDamping();
		return b;
	end

	return 0;
end, true);

extension:RegisterMethod("ph", "rotDamping", "", "n", 1, "GetRotDamping");

extension:RegisterMethod("ph", "speedDamping", "", "n", 1, "GetSpeedDamping");

--[[
	Energy and Inertia
]]

extension:RegisterMethod("e", "energy", "", "n", 1, function(e)
	local ph = e:GetPhysicsObject();

	if IsValid(ph) then
		return ph:GetEnergy();
	end

	return 0;
end, true);

extension:RegisterMethod("e", "inertia", "", "v", 1, function(e)
	local ph = e:GetPhysicsObject();

	if IsValid(ph) then
		return ph:GetInertia();
	end

	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "invInertia", "", "n", 1, function(e)
	local ph = e:GetPhysicsObject();

	if IsValid(ph) then
		return ph:GetInvInertia();
	end

	return 0;
end, true);


extension:RegisterMethod("ph", "energy", "", "n", 1, "GetEnergy");

extension:RegisterMethod("ph", "inertia", "", "v", 1, "GetInertia");

extension:RegisterMethod("ph", "invInertia", "", "n", 1, "GetInvInertia");

--[[
	Set Velocity
]]

extension:SetServerState();

extension:RegisterMethod("e", "setVel", "v", "", 0, function(context, e, v)
	if context:CanUseEntity(e) then
		e:SetVelocity(v);
	end
end, false);

extension:RegisterMethod("ph", "setVel", "v", "", 0, function(context, ph, v)
	if IsValid(ph) then
		local e = ph:GetEntity();

		if context:CanUseEntity(e) then
			ph:SetVelocity(v);
		end
	end
end, false);

--[[
	Materials
]]

extension:SetSharedState();

extension:RegisterMethod("e", "getMaterial", "", "s", 1, "GetMaterial");

extension:RegisterMethod("e", "getSubMaterial", "n", "s", 1, "GetSubMaterial")

extension:SetServerState();

extension:RegisterMethod("e", "setMaterial", "s", "", 0, function(context, e, s)
	if context:CanUseEntity(e) then
		e:SetMaterial(s);
	end
end, false);

extension:RegisterMethod("e", "setSubMaterial", "n,s", "", 0, function(context, e, n, v)
	if context:CanUseEntity(e) then
		e:SetSubMaterial(n,v);
	end
end, false);

extension:RegisterMethod("e", "resetSubMaterials", "", "", 0, function(context, e)
	if context:CanUseEntity(e) then
		e:SetSubMaterial();
	end
end, false);

--[[
	Colors
]]

extension:SetSharedState();

extension:RegisterMethod("e", "getColor", "", "c", 1, "GetColor");

extension:SetServerState();

extension:RegisterMethod("e", "setColor", "c", "", 0, function(context, e, c)
	if context:CanUseEntity(e) then
		e:SetColor(c);
	end
end, false);

--[[
	Gravity
]]

extension:SetSharedState();


extension:RegisterMethod("e", "getGravity", "", "n", 1, "GetGravity");

extension:SetServerState();

extension:RegisterMethod("e", "setGravity", "n", "", 0, function(context, e, n)
	if context:CanUseEntity(e) then
		e:SetGravity(n);
	end
end, false);

--[[
	Let there be FIRE!
]]

extension:SetSharedState();

extension:RegisterMethod("e", "isOnFire", "", "b", 1, "IsOnFire");

extension:SetServerState();

extension:RegisterMethod("e", "ignite", "n", "", 0, function(context, e, n)
	if context:CanUseEntity(e) then
		e:Ignite(n)
	end
end, false);

extension:RegisterMethod("e", "extinguish", "", "", 0, function(context, e)
	if context:CanUseEntity(e) then
		e:Extinguish();
	end
end, false);

--[[
	Mass
]]

extension:SetSharedState();

extension:RegisterMethod("e", "getMass", "", "n", 1, function(e)
	local ph = e:GetPhysicsObject();

	if IsValid(ph) then
		return ph:GetMass();
	end

	return -1;
end, true);

extension:RegisterMethod("e", "getMassCenter", "", "v", 1, function(e)
	local ph = e:GetPhysicsObject();

	if IsValid(ph) then
		return ph:GetMassCenter();
	end

	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("ph", "getMass", "", "n", 1, function(ph)
	if IsValid(ph) then
		return ph:GetMass();
	end

	return -1;
end, true);

extension:RegisterMethod("ph", "getMassCenter", "", "v", 1, function(ph)
	if IsValid(ph) then
		return ph:GetMassCenter();
	end

	return Vector(0, 0, 0);
end, true);

--[[
	General properties
]]

extension:SetSharedState();

extension:RegisterMethod("e", "onGround", "", "b", 1, "OnGround");

extension:RegisterMethod("e", "groundEntity", "", "e", 1, "GetGroundEntity");

extension:RegisterMethod("e", "waterLevel", "", "n", 1, "WaterLevel");

extension:RegisterMethod("e", "isHeldByPlayer", "", "b", 1, "IsPlayerHolding");

--[[
	Entity Types
]]

extension:RegisterMethod("e", "isWeapon", "", "b", 1, "IsWeapon");

extension:RegisterMethod("e", "isVehicle", "", "b", 1, "IsVehicle");

extension:RegisterMethod("e", "isNPC", "", "b", 1, "IsNPC");

extension:RegisterMethod("e", "isPlayer", "", "b", 1, "IsPlayer");

extension:RegisterMethod("e", "isRagdoll", "", "b", 1, "IsRagdoll");


--[[
	Health and Armor
]]

extension:RegisterMethod("e", "health", "", "n", 1, "Health");

extension:RegisterMethod("e", "maxHealth", "", "n", 1, "GetMaxHealth");

extension:RegisterMethod("e", "armor", "", "n", 1, "Armor");

extension:RegisterMethod("e", "maxArmor", "", "n", 1, "MaxArmor");

--[[
	Ownership
]]

if CPPI then
	extension:RegisterMethod("e", "owner", "", "p", 1, "CPPIGetOwner");
else
	extension:RegisterMethod("e", "owner", "", "p", 1, "GetPlayer");
end

--[[
	Eye Pos / Vector
]]

extension:RegisterMethod("e", "eyePos", "", "v", 1, "EyePos");

extension:RegisterMethod("e", "eyeAngles", "", "a", 1, "EyeAngles");

--[[
	Bearing / Elevation
]]

extension:RegisterMethod( "e", "bearing", "v", "n", 1, function(e, v)
	if IsValid(e) then
		local p = e:WorldToLocal( v );
		return (180 / math.pi) * -math.atan2(p.y, p.x);
	end

	return 0;
end, true);

extension:RegisterMethod( "e", "elevation", "v", "n", 1, function(e, v)
	if IsValid(e) then
		local p = e:WorldToLocal( v );
		local l = p:Length();
		return (180 / math.pi) * -math.asin(p.z / l);
	end

	return 0;
end, true);

extension:RegisterMethod( "e", "heading", "v", "n", 1, function(e, v)
	if IsValid(e) then
		local p = e:WorldToLocal( v );
		local b = (180 / math.pi) * -math.atan2(p.y, p.x);
		local l = p:Length();
		return Angle((180 / math.pi) * math.asin(p.z / l), b, 0 )	;
	end

	return Angle(0, 0, 0);
end, true);


extension:RegisterMethod( "ph", "bearing", "v", "n", 1, function(ph, v)
	if IsValid(ph) then
		local p = ph:WorldToLocal( v );
		return (180 / math.pi) * -math.atan2(p.y, p.x);
	end

	return 0;
end, true);

extension:RegisterMethod( "ph", "elevation", "v", "n", 1, function(ph, v)
	if IsValid(ph) then
		local p = ph:WorldToLocal( v );
		local l = p:Length();
		return (180 / math.pi) * -math.asin(p.z / l);
	end

	return 0;
end, true);

extension:RegisterMethod( "ph", "heading", "v", "n", 1, function(ph, v)
	if IsValid(ph) then
		local p = ph:WorldToLocal( v );
		local b = (180 / math.pi) * -math.atan2(p.y, p.x);
		local l = p:Length();
		return Angle((180 / math.pi) * math.asin(p.z / l), b, 0 )	;
	end

	return Angle(0, 0, 0);
end, true);

--[[
	Attachments
]]

extension:RegisterMethod( "e", "lookupAttachment", "s", "n", 1, "LookupAttachment" );

extension:RegisterMethod( "e", "attachmentPos", "n", "v", 1, function(e, n)
	if IsValid(e) then
		local attachment = e:GetAttachment(n);

		if attachment then
			return attachment.Pos;
		end
	end

	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod( "e", "attachmentAng", "n", "a", 1, function(e, n)
	if IsValid(e) then
		local attachment = e:GetAttachment(n);

		if attachment then
			return attachment.Ang;
		end
	end

	return Angle(0, 0, 0);
end, true);

extension:RegisterMethod( "e", "attachments", "", "t", 1, function(e)
	local t = {};

	if IsValid(e) then
		local attachments = e:GetAttachments();

		for i = 1, #attachments do
			t[i] = attachments[i].name
		end
	end

	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

--[[
	Trails
]]

extension:RegisterMethod( "e", "removeTrails", "", "", 0, function(context, e)
	if context:CanUseEntity(e) then
		duplicator.EntityModifiers.trail(context.player, e, nil);
	end
end, false);

extension:RegisterMethod( "e", "setTrails", "n,n,n,s,c,n,b", "", 0, function(context, e, n1, n2, n3, s, c, n4, b)
	if context:CanUseEntity(e) then
		if not string.find(s, '"', 1, true) then
			duplicator.EntityModifiers.trail(context.player, e, {
				Color = c,
				Length = n3,
				StartSize = n1,
				EndSize = n2,
				Material = s,
				AttachmentID = n4,
				Additive = b
			} );
		end
	end
end, true);

--[[
	Prop Core methods
]]

local propcore;

local spawn_rate

local spawnProp = function() end;

if SEVER then
	propcore = CreateConVar("e3_propcore", 0, { FCVAR_REPLICATED }, "Enable E3 gates to manipulate and spawn props.");
else
	propcore = CreateClientConVar("e3_propcore", 0, false, false);
end

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

end

extension:SetServerState();

if propcore:GetBool() then

	--[[
		Spawn Functions
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

end

--[[
	Apply Force methods
]]

local applyForce;

if SEVER then
	applyForce = CreateConVar("e3_applyforce", 1, { FCVAR_REPLICATED }, "Enable E3 gates to applyforce to props.");
else
	applyForce = CreateClientConVar("e3_applyforce", 1, false, false);
end

if applyForce:GetBool() then

	local function applyangForce(ph, a)
		if a.p != 0 or a.y != 0 or a.r != 0 then

			local pos = ph:GetPos();

			local up = ph:LocalToWorld(Vector(0,0,1)) - pos;
			local left = ph:LocalToWorld(Vector(0,1,0)) - pos;
			local forward = ph:LocalToWorld(Vector(1,0,0)) - pos;

			if a.p ~= 0 then
				local pitch = up * (Angle.p * 0.5);
				ph:ApplyForceOffset( forward, pitch );
				ph:ApplyForceOffset( forward * -1, pitch * -1 );
			end

			if a.y ~= 0  then
				local yaw = forward * (Angle.y * 0.5);
				ph:ApplyForceOffset( left, yaw );
				ph:ApplyForceOffset( left * -1, yaw * -1 );
			end

			if a.r ~= 0 then
				local roll = left * (Angle.r * 0.5);
				ph:ApplyForceOffset( up, roll );
				ph:ApplyForceOffset( up * -1, roll * -1 );
			end
		end
	end

	extension:SetServerState();

	extension:RegisterMethod("e", "applyForce", "v", "", 0, function(context, e, v)
		if context:CanUseEntity(e) then
			local ph = e:GetPhysicsObject();

			if IsValid(ph) then
				phys:ApplyForceCenter(v);
			end
		end
	end, false);

	extension:RegisterMethod("e", "applyOffsetForce", "v", "", 0, function(context, e, v)
		if context:CanUseEntity(e) then
			local ph = e:GetPhysicsObject();

			if IsValid(ph) then
				phys:ApplyForceOffset(v);
			end
		end
	end, false);

	extension:RegisterMethod("e", "applyAngForce", "a", "", 0, function(context, e, a)
		if context:CanUseEntity(e) then
			local ph = e:GetPhysicsObject();

			if IsValid(ph) then
				applyangForce(ph, a);
			end
		end
	end, false);

	extension:RegisterMethod("ph", "applyForce", "v", "", 0, function(context, ph, v)
		if IsValid(ph) then
			local e = ph:GetEntity();

			if context:CanUseEntity(e) then
				phys:ApplyForceCenter(v);
			end
		end
	end, false);

	extension:RegisterMethod("ph", "applyOffsetForce", "v", "", 0, function(context, ph, v)
		if IsValid(ph) then
			local e = ph:GetEntity();

			if context:CanUseEntity(e) then
				phys:ApplyForceOffset(v);
			end
		end
	end, false);

	extension:RegisterMethod("ph", "applyAngForce", "a", "", 0, function(context, ph, a)
		if IsValid(ph) then
			local e = ph:GetEntity();

			if context:CanUseEntity(e) then
				applyangForce(ph, a);
			end
		end
	end, false);

end


--[[
	End of extention.
]]


extension:EnableExtension();
