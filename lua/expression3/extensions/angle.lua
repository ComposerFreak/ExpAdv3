--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Angle Extension::
]]

local extension = EXPR_LIB.RegisterExtenstion("angle")

--[[
	CLASS
]]

extension:RegisterClass("a", {"angle"}, isangle, IsValid)

extension:RegisterWiredInport("a", "ANGLE");
extension:RegisterWiredOutport("a", "ANGLE");

extension:RegisterConstructor("a", "n,n,n", Angle, true)
extension:RegisterConstructor("a", "n", function(n) return Angle(n, n, n) end, true)
extension:RegisterConstructor("a", "", function() return Angle(0, 0, 0) end, true)

--[[
	Operators
]]

extension:RegisterOperator("eq", "a,a", "b", 1, nil)

extension:RegisterOperator("neq", "a,a", "b", 1, nil)

extension:RegisterOperator("lth", "a,a", "b", 1, function(a, b)
	return (a.p < b.p) and (a.y < b.y) and (a.r < b.r);
end, true);

extension:RegisterOperator("leg", "a,a", "b", 1, function(a, b)
	return (a.p <= b.p) and (a.y <= b.y) and (a.r <= b.r);
end, true);

extension:RegisterOperator("gth", "a,a", "b", 1, function(a, b)
	return (a.p > b.p) and (a.y > b.y) and (a.r > b.r);
end, true);

extension:RegisterOperator("geq", "a,a", "b", 1, function(a, b)
	return (a.p >= b.p) and (a.y >= b.y) and (a.r >= b.r);
end, true);

--[[
]]

extension:RegisterOperator("add", "a,a", "a", 1, nil, nil);

extension:RegisterOperator("sub", "a,a", "a", 1, nil, nil);

extension:RegisterOperator("mul", "a,a", "a", 1, function(a, b)
	return Angle(a.p * b.p, a.y * b.y, a.r * b.r);
end, true);

extension:RegisterOperator("div", "a,a", "a", 1, function(a, b)
	return Angle(a.p / b.p, a.y / b.y, a.r / b.r);
end, true);

--[[
]]

extension:RegisterOperator("is", "a", "b", 1, function(a)
	return (a.p ~= 0) and (a.y ~= 0) and (a.r ~= 0);
end, true);

extension:RegisterOperator("not", "a", "b", 1, function(a)
	return (a.p == 0) and (a.y == 0) and (a.r == 0);
end, true);

extension:RegisterOperator("neg", "a", "a", 1, function(a)
	return Angle(-a.p, -a.y, -a.r);
end, true);

--[[
	Methods
]]

extension:RegisterAtribute("a", "p", "n");
extension:RegisterAtribute("a", "y", "n");
extension:RegisterAtribute("a", "r", "n");

extension:RegisterMethod("a", "isValid", "", "b", 1, function(a)
	return IsValid(a)
end, true)

--[[
]]

extension:RegisterMethod("a", "forward", "", "v", 1, Forward)
extension:RegisterMethod("a", "up", "", "v", 1, Up)
extension:RegisterMethod("a", "right", "", "v", 1, Right)

--[[
]]

extension:RegisterMethod("a", "getP", "", "n", 1, function(a)
	return a.p
end, true)

extension:RegisterMethod("a", "getY", "", "n", 1, function(a)
	return a.y
end, true)

extension:RegisterMethod("a", "getR", "", "n", 1, function(a)
	return a.r
end, true)

extension:RegisterMethod("a", "getPYR", "", "n", 3, function(a)
	return a.p, a.y, a.r
end, true)

extension:RegisterMethod("a", "unpack", "", "n", 3, function(a)
	return a.p, a.y, a.r
end, true)

--[[
]]

extension:RegisterMethod("a", "setP", "n", "", 0, function(a,n)
	a.p = n
end, true)

extension:RegisterMethod("a", "setY", "n", "", 0, function(a,n)
	a.y = n
end, true)

extension:RegisterMethod("a", "setR", "n", "", 0, function(a,n)
	a.r = n
end, true)

--[[
]]

extension:RegisterMethod("a", "withP", "n", "a", 1, function(a,n)
	return Angle(n, p.y, p.r)
end, true)

extension:RegisterMethod("a", "withY", "n", "a", 1, function(a,n)
	return Angle(a.p, n, p.r)
end, true)

extension:RegisterMethod("a", "withR", "n", "a", 1, function(a,n)
	return Angle(a.p, a.y, n)
end, true)

--[[
]]

extension:RegisterMethod("a", "rotate", "v,n", "", 0, RotateAroundAxis)

extension:RegisterMethod("a", "normalize", "", "", 0, Normalize)

extension:RegisterMethod("a", "ceil", "", "", 0, function(a)
	a.p = math.ceil(a.p)
	a.y = math.ceil(a.y)
	a.r = math.ceil(a.r)
end, true)

extension:RegisterMethod("a", "floor", "", "", 0, function(a)
	a.p = math.floor(a.p)
	a.y = math.floor(a.y)
	a.r = math.floor(a.r)
end, true)

extension:RegisterMethod("a", "round", "n", "", 0, function(a,n)
	a.p = math.Round(a.p, n)
	a.y = math.Round(a.y, n)
	a.r = math.Round(a.r, n)
end, true)

extension:RegisterMethod("a", "round", "", "", 0, function(a)
	a.p = math.Round(a.p)
	a.y = math.Round(a.y)
	a.r = math.Round(a.r)
end, true)

--[[
]]

extension:EnableExtenstion()