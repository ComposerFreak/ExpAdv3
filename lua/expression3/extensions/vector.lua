--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Vector Extension::
]]

local extension = EXPR_LIB.RegisterExtension("vector");

--[[
		CLASS
]]

local function notNil(v)
	return v ~= nil;
end

extension:RegisterClass("v", {"vector"}, isvector, notNil)

extension:RegisterWiredInport("v", "VECTOR");
extension:RegisterWiredOutport("v", "VECTOR");
extension:RegisterNativeDefault("v", "Vector(0, 0, 0)");
extension:RegisterSyncable("v", net.WriteVector, net.ReadVector);

extension:RegisterConstructor("v", "n,n,n", function(x,y,z) return Vector(x or 0, y or 0, z or 0); end, true)
extension:RegisterConstructor("v", "n", function(n) return Vector(n or 0, n or 0, n or 0); end, true)
extension:RegisterConstructor("v", "", function() return Vector(0, 0, 0); end, true)
extension:RegisterConstructor("v", "q", function(q) return Vector(q.i, q.j, q.k); end, true)

--[[
	Operators
]]

extension:RegisterOperator("eq", "v,v", "b", 4, function(a, b)
	local x = (a.x == b.x);
	local y = (a.y == b.y);
	local z = (a.z == b.z);

	return (x and y and z), x, y, z;
end, true);

extension:RegisterOperator("neq", "v,v", "b", 4, function(a, b)
	local x = (a.x ~= b.x);
	local y = (a.y ~= b.y);
	local z = (a.z ~= b.z);

	return (x and y and z), x, y, z;
end, true);

extension:RegisterOperator("lth", "v,v", "b", 4, function(a, b)
	local x = (a.x < b.x);
	local y = (a.y < b.y);
	local z = (a.z < b.z);

	return (x and y and z), x, y, z;
end, true);

extension:RegisterOperator("leg", "v,v", "b", 4, function(a, b)
	local x = (a.x <= b.x);
	local y = (a.y <= b.y);
	local z = (a.z <= b.z);

	return (x and y and z), x, y, z;
end, true);

extension:RegisterOperator("gth", "v,v", "b", 4, function(a, b)
	local x = (a.x > b.x);
	local y = (a.y > b.y);
	local z = (a.z > b.z);

	return (x and y and z), x, y, z;
end, true);

extension:RegisterOperator("geq", "v,v", "b", 4, function(a, b)
	local x = (a.x >= b.x);
	local y = (a.y >= b.y);
	local z = (a.z >= b.z);

	return (x and y and z), x, y, z;
end, true);

--[[
]]

extension:RegisterOperator("add", "v,v", "v", 1, nil, nil);

extension:RegisterOperator("sub", "v,v", "v", 1, nil, nil);

extension:RegisterOperator("mul", "v,v", "v", 1, nil, nil);

extension:RegisterOperator("div", "v,v", "v", 1, function(a, b)
	return Vector((a.x / b.x), (a.y / b.y), (a.z / b.z));
end, true);

--[[
]]

extension:RegisterOperator("add", "v,n", "v", 1, function(a, b)
	return Vector((a.x + b), (a.y + b), (a.z + b));
end, true);

extension:RegisterOperator("sub", "v,n", "v", 1, function(a, b)
	return Vector((a.x - b), (a.y - b), (a.z - b));
end, true);

extension:RegisterOperator("mul", "v,n", "v", 1, function(a, b)
	return Vector((a.x * b), (a.y * b), (a.z * b));
end, true);

extension:RegisterOperator("mul", "n,v", "v", 1, function(a, b)
	return Vector((a * b.x), (a * b.y), (a * b.z));
end, true);

extension:RegisterOperator("div", "v,n", "v", 1, function(a, b)
	return Vector((a.x / b), (a.y / b), (a.z / b));
end, true);

extension:RegisterOperator("div", "n,v", "v", 1, function(a, b)
	return Vector((a / b.x), (a / b.y), (a / b.z));
end, true);

--[[
]]

extension:RegisterOperator("is", "v", "b", 1, function(a)
	return (a.x ~= 0) and (a.y ~= 0) and (a.z ~= 0);
end, true);

extension:RegisterOperator("not", "v", "b", 1, function(a)
	return (a.x == 0) and (a.y == 0) and (a.z == 0);
end, true);

extension:RegisterOperator("neg", "v", "v", 1, function(a)
	return Vector(-a.x, -a.y, -a.z);
end, true);

--[[
]]

extension:RegisterCastingOperator("v", "a", function(ctx, obj)
	return obj:Angle();
end, false);

extension:RegisterCastingOperator("v", "c", function(ctx, obj)
	return obj:ToColor();
end, false);

--[[
	Method
]]

extension:RegisterAttribute("v", "x", "n");
extension:RegisterAttribute("v", "y", "n");
extension:RegisterAttribute("v", "z", "n");

extension:RegisterMethod("v", "getX", "", "n", 1, function(v)
	return v.x;
end, true);

extension:RegisterMethod("v", "getY", "", "n", 1, function(v)
	return v.y;
end, true);

extension:RegisterMethod("v", "getZ", "", "n", 1, function(v)
	return v.z;
end, true);

extension:RegisterMethod("v", "getXYZ", "", "n", 3, function(v)
	return v.x, v.y, v.z;
end, true);

extension:RegisterMethod("v", "unpack", "", "n", 3, function(v)
	return v.x, v.y, v.z;
end, true);

--[[
]]

extension:RegisterMethod("v", "setX", "n", "", 0, function(v,n)
	v.x = n;
end, true);

extension:RegisterMethod("v", "setY", "n", "", 0, function(v,n)
	v.y = n;
end, true);

extension:RegisterMethod("v", "setZ", "n", "", 0, function(v,n)
	v.z = n;
end, true);

--[[
]]

extension:RegisterMethod("v", "withX", "n", "v", 1, function(v,n)
	return Vector(n, v.y, v.z);
end, true);

extension:RegisterMethod("v", "withY", "n", "v", 1, function(v,n)
	return Vector(v.x, n, v.z);
end, true);

extension:RegisterMethod("v", "withZ", "n", "v", 1, function(v,n)
	return Vector(v.x, v.y, n);
end, true);

--[[
]]

extension:RegisterMethod("v", "clone", "", "v", 1, function(v)
	return Vector(v.x, v.y, v.z);
end, true);

--[[
]]

extension:RegisterMethod("v", "dot", "v", "n", 1, "Dot", true)

extension:RegisterMethod("v", "rotate", "a", "", 1, "Rotate", true)

extension:RegisterMethod("v", "cross", "v", "v", 1, "Cross", true)

extension:RegisterMethod("v", "length", "", "n", 1, "Length", true)

extension:RegisterMethod("v", "lengthSqr", "", "n", 1, "LengthSqr", true)

extension:RegisterMethod("v", "distance", "v", "n", 1, "Distance", true)

extension:RegisterMethod("v", "normalized", "", "v", 1, "GetNormalized", true)

extension:RegisterMethod("v", "rotated", "a", "v", 1, function(v, a) 
	local vec = Vector(v.x, v.y, v.z);
	vec:Rotate(a);
	return vec;
end, true)

extension:RegisterMethod("v", "toScreen", "", "v2", 1, function(v)
	
	local v2 = Vector(v.x, v.y, v.z):ToScreen()
	return Vector2(v2.x, v2.y)

end, true)

--[[

]]

extension:RegisterMethod("v", "ceil", "", "", 0, function(v)
	v.x = math.ceil(v.x)
	v.y = math.ceil(v.y)
	v.z = math.ceil(v.z)
end, true)

extension:RegisterMethod("v", "floor", "", "", 0, function(v)
	v.x = math.floor(v.x)
	v.y = math.floor(v.y)
	v.z = math.floor(v.z)
end, true)

extension:RegisterMethod("v", "round", "n", "", 0, function(v,n)
	v.x = math.Round(v.x, n)
	v.y = math.Round(v.y, n)
	v.z = math.Round(v.z, n)
end, true)

extension:RegisterMethod("v", "round", "", "", 0, function(v)
	v.x = math.Round(v.x)
	v.y = math.Round(v.y)
	v.z = math.Round(v.z)
end, true)

--[[

]]

extension:RegisterMethod("v", "toAngle", "", "a", 1, "Angle")

extension:RegisterMethod("v", "toColor", "", "c", 1, "ToColor")

--[[
	
	Stuff stolen directly from e2
]]

local pi = math.pi;
local rad2deg = 180 / pi;
local deg2rad = pi / 180;

extension:RegisterMethod("v", "rotateAroundAxis", "v,n", "v", 1, function(vec, axis, deg)
	local ca, sa = math.cos(deg * deg2rad), math.sin(deg * deg2rad);
	local length = (axis.x * axis.x + axis.y * axis.y + axis.z * axis.z) ^ 0.5;
	local x, y, z = axis.x / length, axis.y / length, axis.z / length;

	return Vector(
		(ca + (x^2)*(1-ca)) * vec.x + (x*y*(1-ca) - z*sa) * vec.y + (x*z*(1-ca) + y*sa) * vec.z,
		(y*x*(1-ca) + z*sa) * vec.x + (ca + (y^2)*(1-ca)) * vec.y + (y*z*(1-ca) - x*sa) * vec.z,
		(z*x*(1-ca) - y*sa) * vec.x + (z*y*(1-ca) + x*sa) * vec.y + (ca + (z^2)*(1-ca)) * vec.z
	);
end, true);

extension:RegisterMethod("v", "rotate", "n,n,n", "v", 1, function(v, p, y, r)
	return Vector(v.x, v.y, v.z):Rotate(Angle(p, y, r));
end, true);

extension:RegisterMethod("v", "dehomogenized", "", "v2", 1, function(v)
	if (v.z == 0) then return { x = v.x, y = v.y}; end
	return { x = v.x / v.z, y = v.y / v.z };
end, true);

extension:RegisterMethod("v", "toRad", "", "v", 1, function(v)
	return Vector(v.x * deg2rad, v.y * deg2rad, v.z * deg2rad)
end, true);

extension:RegisterMethod("v", "toDeg", "", "v", 1, function(v)
	return Vector(v.x * rad2deg, v.y * rad2deg, v.z * rad2deg)
end, true);

--[[

]]

extension:RegisterOperator("dlt", "v", "v", 1, function(pre, new)
	return (pre or Vector(0, 0, 0)) - new;
end, true);

--[[

]]

extension:EnableExtension()
