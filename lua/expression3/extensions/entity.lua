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

extension:RegisterWiredInport("e", "ENTITY", function(e)
	if not IsValid(e) then return Entity(0); end
	return e;
end);

extension:RegisterWiredOutport("e", "ENTITY");

extension:RegisterNativeDefault("e", "Entity(0)");

--[[
	Operators
]]
extension:RegisterOperator("eq", "e,e", "b", 1);
extension:RegisterOperator("neq", "e,e", "b", 1);

--[[
	IsValid
]]

extension:RegisterOperator("is",  "e", "b", 1, function(e) 
	return (e ~= nil) and (e.IsValid and e:IsValid());
end, true);

extension:RegisterOperator("not", "e", "b", 1, function(e)
	return !((e ~= nil) and (e.IsValid and e:IsValid()));
end, true);

extension:RegisterMethod("e", "isValid", "", "b", 1, IsValid, true);

--[[
	General Methods
]]

extension:RegisterMethod("e", "getClass", "", "s", 1, function(e)
	if IsValid(e) then return e:GetClass() or ""; end
	return "";
end, true);

extension:RegisterMethod("e", "getModel", "", "s", 1, function(e)
	if IsValid(e) then return e:GetModel() or ""; end
	return "";
end, true);

extension:RegisterMethod("e", "id", "", "n", 1, function(e)
	if IsValid(e) then return e:EntIndex() or -1; end
	return -1;
end, true);

extension:RegisterMethod("e", "parent", "", "e", 1, function(e)
	if IsValid(e) then return e:GetParent() or Entity(0); end
	return Entity(0);
end, true);

--[[
	Position & Angle
]]

local getPos = function(e)
	if IsValid(e) then return e:GetPos() or Vector(0, 0, 0); end
	return Vector(0, 0, 0);
end

local getAngles = function(e)
	if IsValid(e) then return e:GetAngles() or Angle(0, 0, 0); end
	return Angle(0, 0, 0);
end

extension:RegisterMethod("e", "getPos", "", "v", 1, getPos, true);

extension:RegisterMethod("e", "pos", "", "v", 1, getPos, true);

extension:RegisterMethod("e", "getAng", "", "a", 1, getAngles, true);

extension:RegisterMethod("e", "ang", "", "a", 1, getAngles, true);

--[[
	OBB Mins / Maxs
]]

extension:RegisterMethod("e", "boxCenter", "", "v", 1, function(e)
	if IsValid(e) then return e:OBBCenter(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "boxMins", "", "v", 1, function(e)
	if IsValid(e) then return e:OBBMins(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "boxMaxs", "", "v", 1, function(e)
	if IsValid(e) then return e:OBBMaxs(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "boxSize", "", "v", 1, function(e)
	if IsValid(e) then return e:OBBMaxs() - e:OBBMins(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "worldSpaceAABB", "", "v", 2, function(e)
	if IsValid(e) then return e:WorldSpaceAABB(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "worldSpaceCenter", "", "v", 2, function(e)
	if IsValid(e) then return e:WorldSpaceCenter(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "radius", "", "n", 2, function(e)
	if IsValid(e) then return e:BoundingRadius(); end
	return 0;
end, true);

--[[
	Get Direction
]]

extension:SetSharedState();

extension:RegisterMethod("e", "forward", "", "v", 1, function(e)
	if IsValid(e) then return e:GetForward(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "up", "", "v", 1, function(e)
	if IsValid(e) then return e:GetUp(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "right", "", "v", 1, function(e)
	if IsValid(e) then return e:GetRight(); end
	return Vector(0, 0, 0);
end, true);

--[[
	World and Local Vector and Angles
]]

extension:RegisterMethod("e", "toWorld", "v", "v", 1, function(e, v)
	if IsValid(e) then return e:LocalToWorld(v); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "toWorld", "a", "a", 1, function(e, a)
	if IsValid(e) then return e:LocalToWorldAngles(a); end
	return Angle(0, 0, 0);
end, true);

extension:RegisterMethod("e", "toLocal", "v", "v", 1, function(e, v)
	if IsValid(e) then return e:WorldToLocal(v); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "toLocal", "a", "a", 1, function(e, a)
	if IsValid(e) then return e:WorldToLocalAngles(a); end
	return Angle(0, 0, 0);
end, true);


--[[
	Velecotity
]]

extension:RegisterMethod("e", "Vel", "", "v", 1, function(e)
	if IsValid(e) then return e:GetVelocity(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "VelL", "", "v", 1, function(e)
	if IsValid(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			return ph:WorldToLocal(ph:GetVelocity() + ph:GetPos());
		end
	end

	return Vector(0,0,0);
end, true);

extension:RegisterMethod("e", "angVel", "", "a", 1, function(e)
	if IsValid(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			local a = ph:GetAngleVelocity();
			return Angle(a.x, a.y, a.z);
		end
	end

	return Angle(0, 0, 0);
end, true);

extension:RegisterMethod("e", "angVelVector", "", "v", 1, function(e)
	if IsValid(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			return ph:GetAngleVelocity();
		end
	end

	return Vector(0,0,0);
end, true);

--[[
	Energy and Inertia
]]

extension:RegisterMethod("e", "energy", "", "n", 1, function(e)
	if IsValid(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			return ph:GetEnergy();
		end
	end

	return 0;
end, true);

extension:RegisterMethod("e", "inertia", "", "v", 1, function(e)
	if IsValid(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			return ph:GetInertia();
		end
	end

	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "invInertia", "", "n", 1, function(e)
	if IsValid(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			return ph:GetInvInertia();
		end
	end

	return 0;
end, true);

--[[
	Materials
]]

local BannedMats = {};

BannedMats["pp/copy"] = true;
BannedMats["engine/writez"] = true;
BannedMats["effects/ar2_altfire1"] = true;

hook.Call("Expression3.Banned.Materials", BannedMats);

EXPR_LIB.BannedMats = BannedMats;

--[[
	Materials
]]

extension:SetSharedState();

extension:RegisterMethod("e", "getMaterial", "", "s", 1, function(e)
	if IsValid(e) then return e:GetMaterial() or ""; end
	return "";
end, true);

extension:RegisterMethod("e", "getSubMaterial", "n", "s", 1, function(e, n)
	if IsValid(e) then return e:GetSubMaterial(n) or ""; end
	return "";
end, true);

extension:SetServerState();

extension:RegisterMethod("e", "setMaterial", "s", "", 0, function(context, e, s)
	if context:CanUseEntity(e) and not BannedMats[s] then
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

extension:RegisterMethod("e", "getColor", "", "c", 1, function(e)
	if IsValid(e) then return e:GetColor(); end
	return Color(0, 0, 0, 0);
end, true);

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


extension:RegisterMethod("e", "getGravity", "", "n", 1, function(e)
	if IsValid(e) then return e:GetGravity(); end
	return 0;
end, true);

extension:SetServerState();

extension:RegisterMethod("e", "setGravity", "b", "", 0, function(context, e, b)
	if context:CanUseEntity(e) then
		local ph = e:GetPhysicsObject();
		if IsValid(ph) then
			ph:EnableGravity(b);
		end
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
	Use Entity
]]

extension:SetServerState();

extension:RegisterMethod("e", "use", "", "", 0, function(context, e)
	if context:CanUseEntity(e) then
		if e.Use then
			e:Use(context.player,context.player,1,0)
		else
			e:Fire("use","1",0)
		end
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
		return ph:LocalToWorld(ph:GetMassCenter());
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

extension:SetServerState();

extension:RegisterMethod("e", "setMass", "n", "", 0, function(context, e, n)
	if context:CanUseEntity(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			ph:SetMass(n);
		end
	end
end, false);

extension:RegisterMethod("ph", "setMass", "n", "", 0, function(context, ph, n)
	if context:CanUseEntity(e) then
		if IsValid(ph) then
			ph:SetMass(n);
		end
	end
end, false);

--[[
	General properties
]]

extension:SetSharedState();

extension:RegisterMethod("e", "onGround", "", "b", 1, function(e)
	if IsValid(e) then return e:OnGround(); end
	return false;
end, true);

extension:RegisterMethod("e", "groundEntity", "", "e", 1, function(e)
	if IsValid(e) then return e:GetGroundEntity(); end
	return Entity(0);
end, true);

extension:RegisterMethod("e", "waterLevel", "", "n", 1, function(e)
	if IsValid(e) then return e:WaterLevel(); end
	return 0;
end, true);

extension:RegisterMethod("e", "isHeldByPlayer", "", "b", 1, function(e)
	if IsValid(e) then return e:IsPlayerHolding(); end
	return false;
end, true);

--[[
	Entity Types
]]

extension:RegisterMethod("e", "isWeapon", "", "b", 1, function(e)
	if IsValid(e) then return e:IsWeapon(); end
	return false;
end, true);

extension:RegisterMethod("e", "isVehicle", "", "b", 1, function(e)
	if IsValid(e) then return e:IsVehicle(); end
	return false;
end, true);

extension:RegisterMethod("e", "isNPC", "", "b", 1, function(e)
	if IsValid(e) then return e:IsNPC(); end
	return false;
end, true);

extension:RegisterMethod("e", "isPlayer", "", "b", 1, function(e)
	if IsValid(e) then return e:IsPlayer(); end
	return false;
end, true);

extension:RegisterMethod("e", "isRagdoll", "", "b", 1, function(e)
	if IsValid(e) then return e:IsRagdoll(); end
	return false;
end, true);


--[[
	Health and Armor
]]

extension:RegisterMethod("e", "health", "", "n", 1, function(e)
	if IsValid(e) then return e:Health(); end
	return 0;
end, true);

extension:RegisterMethod("e", "maxHealth", "", "n", 1, function(e)
	if IsValid(e) then return e:GetMaxHealth(); end
	return 0;
end, true);

extension:RegisterMethod("e", "armor", "", "n", 1, function(e)
	if IsValid(e) then return e:Armor(); end
	return 0;
end, true);

extension:RegisterMethod("e", "maxArmor", "", "n", 1, function(e)
	if IsValid(e) then return e:MaxArmor(); end
	return 0;
end, true);

--[[
	Ownership
]]

if CPPI then
	extension:RegisterMethod("e", "owner", "", "p", 1, function(e)
		if IsValid(e) then return e:CPPIGetOwner(); end
		return Entity(0);
	end, true);
else
	extension:RegisterMethod("e", "owner", "", "p", 1, function(e)
		if IsValid(e) then return e:GetPlayer(); end
		return Entity(0);
	end, true);
end

--[[
	Eye Pos / Vector
]]

extension:RegisterMethod("e", "eyePos", "", "v", 1, function(e)
	if IsValid(e) then return e:EyePos(); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("e", "eyeAngles", "", "a", 1, function(e)
	if IsValid(e) then return e:EyeAngles(); end
	return Angle(0, 0, 0);
end, true);

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

extension:RegisterMethod( "e", "heading", "v", "a", 1, function(e, v)
	if IsValid(e) then
		local p = e:WorldToLocal( v );
		local b = (180 / math.pi) * -math.atan2(p.y, p.x);
		local l = p:Length();
		return Angle((180 / math.pi) * math.asin(p.z / l), b, 0 )	;
	end

	return Angle(0, 0, 0);
end, true);

--[[
	Attachments
]]

extension:RegisterMethod( "e", "lookupAttachment", "s", "n", 1, function(e, s)
	if IsValid(e) then return e:LookupAttachment(s) or -1; end
	return -1;
end);

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
	Vehicles
]]

extension:RegisterMethod("e", "getDriver", "", "p", 1, function(e)
	if IsValid(e) and e:IsVehicle() then return e:GetDriver(); end;
	return Entity(0);
end, true);

extension:RegisterMethod("e", "setPassenger", "", "p", 1, function(e)
	if IsValid(e) and e:IsVehicle() then return e:GetPassenger(); end;
	return Entity(0);
end, true);

--[[
	Apply Damage
]]

extension:RegisterMethod("e", "applyDamage", "n", "", 0, function(context, e, n)
	if context:CanUseEntity(e) then
		if IsValid(e) then
			e:TakeDamage(n, context.entity, context.player);
		end
	end
end, false);

--[[
	End of extention.
]]

extension:EnableExtension();
