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

extension:RegisterClass("v", {"vector", "vector.3d"}, isvector, notNil)

extension:RegisterConstructor("v", "n,n,n", Vector, true) -- E3 new vector(n,n,n) == Vector(N, N, N) Lua

--[[
	Operators
]]

extension:RegisterOperator("==", "v,v", "b", 1, function(a, b)
	return (a.x == b.x) and (a.y == b.y) and (a.z == b.z);
end, true);

extension:RegisterOperator("!=", "v,v", "b", 1, function(a, b)
	return (a.x ~= b.x) and (a.y ~= b.y) and (a.z ~= b.z);
end, true);

extension:RegisterOperator("<", "v,v", "b", 1, function(a, b)
	return (a.x < b.x) and (a.y < b.y) and (a.z < b.z);
end, true);

extension:RegisterOperator("<=", "v,v", "b", 1, function(a, b)
	return (a.x <= b.x) and (a.y <= b.y) and (a.z <= b.z);
end, true);

extension:RegisterOperator(">", "v,v", "b", 1, function(a, b)
	return (a.x > b.x) and (a.y > b.y) and (a.z > b.z);
end, true);

extension:RegisterOperator(">=", "v,v", "b", 1, function(a, b)
	return (a.x >= b.x) and (a.y >= b.y) and (a.z >= b.z);
end, true);

--[[
]]

extension:RegisterOperator("+", "v,v", "v", 1, nil, nil);

extension:RegisterOperator("-", "v,v", "v", 1, nil, nil);

extension:RegisterOperator("*", "v,v", "v", 1, nil, nil);

extension:RegisterOperator("/", "v,v", "v", 1, function(a, b)
	return Vector((a.x / b.x), (a.y / b.y), (a.z / b.z));
end, true);

--[[
]]

extension:RegisterOperator("+", "v,n", "v", 1, function(a, b)
	return Vector((a.x + b), (a.y + b), (a.z + b));
end, true);

extension:RegisterOperator("-", "v,n", "v", 1, function(a, b)
	return Vector((a.x - b), (a.y - b), (a.z - b));
end, true);

extension:RegisterOperator("*", "v,n", "v", 1, function(a, b)
	return Vector((a.x * b), (a.y * b), (a.z * b));
end, true);

extension:RegisterOperator("/", "v,n", "v", 1, function(a, b)
	return Vector((a.x / b), (a.y / b), (a.z / b));
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

extension:RegisterMethod("v", "clone", "", "v", 1, function(v,n)
	return Vector(v.x, v.y, v.z);
end, true);

--[[
]]

extension:RegisterMethod("v", "toAngle", "", "a", 1, Angle);

--[[
]]

extension:EnableExtension()
