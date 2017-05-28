--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Vector2 Extension::
]]

local extension = EXPR_LIB.RegisterExtension("vector2");

--[[
		CLASS
]]

local function notNil(v)
	return v ~= nil;
end

local function isVector2(v)
	return istable(v) and #v == 2 and v.x and v.y
end

extension:RegisterClass("v2", {"vector2", "vector.2d"}, isVector2, notNil)

extension:RegisterWiredInport("v2", "VECTOR2");
extension:RegisterWiredOutport("v2", "VECTOR2");

extension:RegisterConstructor("v2", "n,n", function(x, y) return {x = x, y = y} end, true)
extension:RegisterConstructor("v2", "n", function(v) return {x = v, y = v} end, true)
extension:RegisterConstructor("v2", "", function() return {x = 0, y = 0} end, true)

--[[
	Operators
]]

extension:RegisterOperator("eq", "v2,v2", "b", 1, function(a, b)
	return (a.x == b.x) and (a.y == b.y);
end, true);

extension:RegisterOperator("neq", "v2,v2", "b", 1, function(a, b)
	return (a.x ~= b.x) and (a.y ~= b.y);
end, true);

extension:RegisterOperator("lth", "v2,v2", "b", 1, function(a, b)
	return (a.x < b.x) and (a.y < b.y);
end, true);

extension:RegisterOperator("leg", "v2,v2", "b", 1, function(a, b)
	return (a.x <= b.x) and (a.y <= b.y);
end, true);

extension:RegisterOperator("gth", "v2,v2", "b", 1, function(a, b)
	return (a.x > b.x) and (a.y > b.y);
end, true);

extension:RegisterOperator("geq", "v2,v2", "b", 1, function(a, b)
	return (a.x >= b.x) and (a.y >= b.y);
end, true);

--[[
]]

extension:RegisterOperator("add", "v2,v2", "v2", 1, function(a, b)
	return {x = a.x + b.x, y = a.y + b.y};
end, true);

extension:RegisterOperator("sub", "v2,v2", "v2", 1, function(a, b)
	return {x = a.x - b.x, y = a.y - b.y};
end, true);

extension:RegisterOperator("mul", "v2,v2", "v2", 1, function(a, b)
	return {x = a.x * b.x, y = a.y * b.y};
end, true);

extension:RegisterOperator("div", "v2,v2", "v2", 1, function(a, b)
	return {x = a.x / b.x, y = a.y / b.y};
end, true);

--[[
]]

extension:RegisterOperator("add", "v2,n", "v2", 1, function(a, b)
	return {x = a.x + b, y = a.y + b};
end, true);

extension:RegisterOperator("sub", "v2,n", "v2", 1, function(a, b)
	return {x = a.x - b, y = a.y - b};
end, true);

extension:RegisterOperator("mul", "v2,n", "v2", 1, function(a, b)
	return {x = a.x * b, y = a.y * b};
end, true);

extension:RegisterOperator("div", "v2,n", "v2", 1, function(a, b)
	return {x = a.x / b, y = a.y / b};
end, true);

--[[
]]

extension:RegisterOperator("is", "v2", "b", 1, function(a)
	return (a.x ~= 0) and (a.y ~= 0);
end, true);

extension:RegisterOperator("not", "v2", "b", 1, function(a)
	return (a.x == 0) and (a.y == 0);
end, true);

extension:RegisterOperator("neg", "v", "v", 1, function(a)
	return {x = -a.x, y = -a.y};
end, true);

--[[
]]
extension:RegisterAtribute("v2", "x", "n");
extension:RegisterAtribute("v2", "y", "n");

extension:RegisterMethod("v2", "getX", "", "n", 1, function(v)
	return v.x;
end, true);

extension:RegisterMethod("v2", "getY", "", "n", 1, function(v)
	return v.y;
end, true);

extension:RegisterMethod("v2", "getXY", "", "n", 2, function(v)
	return v.x, v.y;
end, true);

--[[
]]

extension:RegisterMethod("v2", "setX", "n", "", 0, function(v,n)
	v.x = n;
end, true);

extension:RegisterMethod("v2", "setY", "n", "", 0, function(v,n)
	v.y = n;
end, true);

--[[
]]

extension:RegisterMethod("v2", "withX", "n", "v2", 1, function(v,n)
	return {x = n, y = v.y};
end, true);

extension:RegisterMethod("v2", "withY", "n", "v2", 1, function(v,n)
	return {x = v.x, y = n};
end, true);

--[[
]]

extension:RegisterMethod("v2", "clone", "", "v2", 1, function(v)
	return {x = v.x, y = v.y};
end, true);

--[[
]]

--extension:RegisterMethod("v2", "dot", "v2", "n", 1, Dot, true)

--extension:RegisterMethod("v2", "cross", "v2", "v2", 1, Cross, true)

extension:RegisterMethod("v2", "length", "", "n", 1, function(a)
	return Vector(a.x, a.y, 0):Length2D()
end, true);

extension:RegisterMethod("v2", "distance", "v2", "n", 1, function(a,b)
	return math.Distance(a.x, a.y, b.x, b.y)
end, true);

extension:RegisterMethod("v2", "normalized", "", "v2", 1, function(a)
	local nv = Vector(a.x, a.y, 0):GetNormalized()
	return {x = nv.x, y = nv.y}
end, true);

extension:RegisterMethod("v2", "ceil", "", "", 0, function(v)
	v.x = math.ceil(v.x)
	v.y = math.ceil(v.y)
end, true);

extension:RegisterMethod("v2", "floor", "", "", 0, function(v)
	v.x = math.floor(v.x)
	v.y = math.floor(v.y)
end, true);

extension:RegisterMethod("v2", "round", "n", "", 0, function(v,n)
	v.x = math.Round(v.x, n)
	v.y = math.Round(v.y, n)
end, true)

extension:RegisterMethod("v2", "round", "", "", 0, function(v)
	v.x = math.Round(v.x)
	v.y = math.Round(v.y)
end, true);

--[[
]]

extension:EnableExtension();
