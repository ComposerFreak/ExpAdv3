--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 
	
	::Color Extension::
]]

local extension = EXPR_LIB.RegisterExtension("color");

extension:RegisterLibrary("clr");

--[[
	CLASS
]]

local function notNil(c)
	return c ~= nil;
end

extension:RegisterClass("c", {"color", "colour"}, isColor, notNil)

extension:RegisterConstructor("c", "n,n,n", Color, true) -- E3 new color(n,n,n) == Color(N, N, N) Lua
extension:RegisterConstructor("c", "n,n,n,n", Color, true) -- E3 new color(n,n,n,n) == Color(N, N, N, N) Lua

--[[
	Operators
]]

extension:RegisterOperator("eq", "c,c", "b", 1, function(a, b)
	return (a.r == b.r) and (a.g == b.g) and (a.b == b.b) and (a.a == b.a);
end, true);

extension:RegisterOperator("neq", "c,c", "b", 1, function(a, b)
	return (a.r ~= b.r) and (a.g ~= b.g) and (a.b ~= b.b) and (a.a ~= b.a);
end, true);

extension:RegisterOperator("lth", "c,c", "b", 1, function(a, b)
	return (a.r < b.r) and (a.g < b.g) and (a.b < b.b) and (a.a < b.a);
end, true);

extension:RegisterOperator("leg", "c,c", "b", 1, function(a, b)
	return (a.r <= b.r) and (a.g <= b.g) and (a.b <= b.b) and (a.a <= b.a);
end, true);

extension:RegisterOperator("gth", "c,c", "b", 1, function(a, b)
	return (a.r > b.r) and (a.g > b.g) and (a.b > b.b) and (a.a > b.a);
end, true);

extension:RegisterOperator("geq", "c,c", "b", 1, function(a, b)
	return (a.r >= b.r) and (a.g >= b.g) and (a.b >= b.b) and (a.a >= b.a);
end, true);

--[[
]]

extension:RegisterOperator("add", "c,c", "c", 1, function(a, b)
	return Color((a.r + b.r), (a.g + b.g), (a.b + b.b), (a.a + b.a));
end, true);

extension:RegisterOperator("sub", "c,c", "c", 1, function(a, b)
	return Color((a.r - b.r), (a.g - b.g), (a.b - b.b), (a.a - b.a));
end, true);

extension:RegisterOperator("mul", "c,c", "c", 1, function(a, b)
	return Color((a.r * b.r), (a.g * b.g), (a.b * b.b), (a.a * b.a));
end, true);

extension:RegisterOperator("div", "c,c", "c", 1, function(a, b)
	return Color((a.r / b.r), (a.g / b.g), (a.b / b.b), (a.a / b.a));
end, true);

--[[
]]

extension:RegisterOperator("add", "c,n", "c", 1, function(a, b)
	return Color((a.r + b), (a.g + b), (a.b + b), (a.a + b));
end, true);

extension:RegisterOperator("sub", "c,n", "c", 1, function(a, b)
	return Color((a.r - b), (a.g - b), (a.b - b), (a.a - b));
end, true);

extension:RegisterOperator("mul", "c,n", "c", 1, function(a, b)
	return Color((a.r * b), (a.g * b), (a.b * b), (a.a * b));
end, true);

extension:RegisterOperator("div", "c,n", "c", 1, function(a, b)
	return Color((a.r / b), (a.g / b), (a.b / b), (a.a / b));
end, true);

--[[
]]

extension:RegisterOperator("is", "c", "b", 1, function(a)
	return (a.r ~= 0) and (a.g ~= 0) and (a.b ~= 0) and (a.a ~= 0);
end, true);

extension:RegisterOperator("not", "c", "b", 1, function(a)
	return (a.r == 0) and (a.g == 0) and (a.b == 0) and (a.a == 0);
end, true);

extension:RegisterOperator("neg", "v", "v", 1, function(a)
	return Color(-a.r, -a.g, -a.b, -a.a);
end, true);

--[[
	Method
]]

extension:RegisterAtribute("c", "r", "n");
extension:RegisterAtribute("c", "g", "n");
extension:RegisterAtribute("c", "b", "n");
extension:RegisterAtribute("c", "a", "n");

extension:RegisterMethod("c", "getR", "", "n", 1, function(c)
	return c.r;
end, true);

extension:RegisterMethod("c", "getG", "", "n", 1, function(c)
	return c.g;
end, true);

extension:RegisterMethod("c", "getB", "", "n", 1, function(c)
	return c.b;
end, true);

extension:RegisterMethod("c", "getA", "", "n", 1, function(c)
	return c.a;
end, true);

extension:RegisterMethod("c", "getRGB", "", "n", 3, function(c)
	return c.r, c.g, c.b;
end, true);

extension:RegisterMethod("c", "getRGBA", "", "n", 3, function(c)
	return c.r, c.g, c.b, c.a;
end, true);

extension:RegisterMethod("c", "unpack", "", "n", 3, function(c)
	return c.r, c.g, c.b, c.a;
end, true);

--[[
]]

extension:RegisterMethod("c", "setR", "n", "", 0, function(c,n)
	c.r = n;
end, true);

extension:RegisterMethod("c", "setG", "n", "", 0, function(c,n)
	c.g = n;
end, true);

extension:RegisterMethod("c", "setB", "n", "", 0, function(c,n)
	c.b = n;
end, true);

extension:RegisterMethod("c", "setA", "n", "", 0, function(c,n)
	c.a = n;
end, true);

--[[
]]

extension:RegisterMethod("c", "withR", "n", "c", 1, function(c,n)
	return Color(n, c.g, c.b, c.a);
end, true);

extension:RegisterMethod("c", "withG", "n", "c", 1, function(c,n)
	return Color(c.r, n, c.b, c.a);
end, true);

extension:RegisterMethod("c", "withB", "n", "c", 1, function(c,n)
	return Color(c.r, c.g, n, c.a);
end, true);

extension:RegisterMethod("c", "withA", "n", "c", 1, function(c,n)
	return Color(c.r, c.g, c.b, n);
end, true);

--[[
]]

extension:RegisterMethod("c", "ceil", "", "", 0, function(c)
	c.r = math.ceil(c.r)
	c.g = math.ceil(c.g)
	c.b = math.ceil(c.b)
	c.a = math.ceil(c.a)
end, true)

extension:RegisterMethod("c", "floor", "", "", 0, function(c)
	c.r = math.floor(c.r)
	c.g = math.floor(c.g)
	c.b = math.floor(c.b)
	c.a = math.floor(c.a)
end, true)

extension:RegisterMethod("c", "round", "n", "", 0, function(c,n)
	c.r = math.Round(c.r, n)
	c.g = math.Round(c.g, n)
	c.b = math.Round(c.b, n)
	c.a = math.Round(c.a, n)
end, true)

extension:RegisterMethod("c", "round", "", "", 0, function(c)
	c.r = math.Round(c.r)
	c.g = math.Round(c.g)
	c.b = math.Round(c.b)
	c.a = math.Round(c.a)
end, true)

--[[
	Functions
]]

extension:RegisterFunction("clr", "colorAlpha", "c,n", "c", 1, ColorAlpha, true);

extension:RegisterFunction("clr", "colorRand", "c,n", "c", 1, ColorRand, true);

extension:RegisterFunction("clr", "colorToHSV", "c", "n", 1, ColorToHSV, true);

extension:RegisterFunction("clr", "hsvToColor", "n,n,n", "c", 1, HSVToColor, true);

--[[
]]

extension:EnableExtension()