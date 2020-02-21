local extension = EXPR_LIB.RegisterExtension("bones");

extension:SetSharedState();

local NULL_BONE;

--[[
	Bone Class
]]

extension:RegisterClass("ph", {"bone", "physics"}, IsValid, IsValid);

extension:RegisterMethod("e", "physics", "", "ph", 1, function(e)
	if IsValid(e) then return e:GetPhysicsObject() or NULL_BONE; end
	return NULL_BONE;
end, true);

extension:RegisterMethod("e", "getBoneCount", "", "n", 1, function(e)
	if IsValid(e) then return e:GetPhysicsObjectCount(); end
	return 0;
end, true);

extension:RegisterMethod("e", "getBoneIndex", "", "n", 1, function(e)
	if IsValid(e) then return e:GetPhysicsObjectNum(); end
	return 0;
end, true);

--[[
	Operators
]]

extension:RegisterOperator("eq", "ph,ph", "b", 1);
extension:RegisterOperator("neq", "ph,ph", "b", 1);


--[[
	IsValid
]]

extension:RegisterMethod("ph", "isValid", "", "b", 1, function(e)
	return IsValid(e);
end, true);

--[[
	pos and angles
]]

local getPos = function(e)
	if IsValid(e) then return e:GetPos() or Vector(0, 0, 0); end
	return Vector(0, 0, 0);
end

local getAngles = function(e)
	if IsValid(e) then return e:GetAngles() or Angle(0, 0, 0); end
	return Angle(0, 0, 0);
end

extension:SetSharedState();

extension:RegisterMethod("ph", "getPos", "", "v", 1, getPos);

extension:RegisterMethod("ph", "pos", "", "v", 1, getPos);

extension:RegisterMethod("ph", "getAng", "", "v", 1, getAngles);

extension:RegisterMethod("ph", "ang", "", "v", 1, getAngles);


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

extension:RegisterMethod("ph", "toWorld", "v", "v", 1, function(ph, v)
	if IsValid(ph) then return ph:LocalToWorld(v); end
	return Vector(0, 0, 0);
end, true);

extension:RegisterMethod("ph", "toLocal", "v", "v", 1, function(ph, v)
	if IsValid(ph) then return ph:WorldToLocal(v); end
	return Vector(0, 0, 0);
end, true);

--[[
	Velecotity
]]

extension:RegisterMethod("ph", "Vel", "", "v", 1, function(ph)
	if IsValid(ph) then return ph:GetVelocity(); end
	return Vector(0, 0, 0);
end);

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

extension:RegisterMethod("ph", "rotDamping", "", "n", 1, function(ph)
	if IsValid(ph) then return ph:GetRotDamping(); end
	return 0;
end);

extension:RegisterMethod("ph", "speedDamping", "", "n", 1, function(ph)
	if IsValid(ph) then return ph:GetSpeedDamping(); end
	return 0;
end);



--[[
	Energy and Inertia
]]

extension:RegisterMethod("ph", "energy", "", "n", 1, function(ph)
	if IsValid(ph) then return ph:GetEnergy(); end
	return 0;
end, true);

extension:RegisterMethod("ph", "invInertia", "", "n", 1, function(ph)
	if IsValid(ph) then return ph:GetInvInertia(); end
	return 0;
end, true);

extension:RegisterMethod("ph", "inertia", "", "v", 1, function(ph)
	if IsValid(ph) then return ph:GetInertia(); end
	return Vector(0, 0, 0);
end, true);


--[[
	Bearing / Elevation
]]

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
	End of extention.
]]


extension:EnableExtension();