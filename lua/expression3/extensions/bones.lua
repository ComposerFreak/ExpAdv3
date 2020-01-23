local extension = EXPR_LIB.RegisterExtension("bones");

extension:SetSharedState();

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

extension:RegisterOperator("eq", "ph,ph", "b", 1);
extension:RegisterOperator("neq", "ph,ph", "b", 1);


--[[
	IsValid
]]

extension:RegisterMethod("ph", "isValid", "", "b", 1, function(e)
	return IsValid(e);
end, true);

--[[
	Get Direction
]]

extension:SetSharedState();


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

extension:RegisterMethod("ph", "toWorld", "v", "v", 1, "LocalToWorld");

extension:RegisterMethod("ph", "toLocal", "v", "v", 1, "WorldToLocal");

--[[
	Velecotity
]]

extension:RegisterMethod("ph", "Vel", "", "v", 1, "GetVelocity");

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

extension:RegisterMethod("ph", "energy", "", "n", 1, "GetEnergy");

extension:RegisterMethod("ph", "inertia", "", "v", 1, "GetInertia");

extension:RegisterMethod("ph", "invInertia", "", "n", 1, "GetInvInertia");


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