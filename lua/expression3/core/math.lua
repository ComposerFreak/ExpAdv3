--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

	local halfPi = math.pi/2;
	local tan  = math.tan;
	local atan = math.atan;

--[[
	*****************************************************************************************************************************************************
		Functions used by the math library
	*****************************************************************************************************************************************************
]]--

	local function notnil(obj)
		return obj ~= nil and obj ~= _nil
	end

	local function pi()
		return math.pi	
	end

	local function cot( radians )
		return 1 / tan( radians );
	end

	local function acot( radians )
		return halfPi - atan( radians );
	end

--[[
	*****************************************************************************************************************************************************
		create a new extention
	*****************************************************************************************************************************************************
]]--
	
	local extension = EXPR_LIB.RegisterExtension("math");

--[[
	*****************************************************************************************************************************************************
		register number class
	*****************************************************************************************************************************************************
]]--

	local class_num = extension:RegisterClass("n", {"number", "int", "integer", "double", "normal"}, isnumber, notnil);

	extension:RegisterWiredInport("n", "NORMAL");
	extension:RegisterWiredOutport("n", "NORMAL");

--[[
	*****************************************************************************************************************************************************
		number operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("add", "n,n", "n", 1);
	extension:RegisterOperator("sub", "n,n", "n", 1);
	extension:RegisterOperator("div", "n,n", "n", 1);
	extension:RegisterOperator("mul", "n,n", "n", 1);
	extension:RegisterOperator("exp", "n,n", "n", 1);
	extension:RegisterOperator("mod", "n,n", "n", 1);
	extension:RegisterOperator("bxor", "n,n", "n", 1); -- Uses bit.bxor
	extension:RegisterOperator("bor", "n,n", "n", 1);  -- Uses bit.bor
	extension:RegisterOperator("band", "n,n", "n", 1); -- Uses bit.band
	extension:RegisterOperator("bshl", "n,n", "n", 1); -- Uses bit.lshift
	extension:RegisterOperator("bshr", "n,n", "n", 1); -- Uses bit.rshift
	extension:RegisterOperator("neq", "n,n", "b", 1);
	extension:RegisterOperator( "eq", "n,n", "b", 1);
	extension:RegisterOperator("lth", "n,n", "b", 1);
	extension:RegisterOperator("leg", "n,n", "b", 1);
	extension:RegisterOperator("gth", "n,n", "b", 1);
	extension:RegisterOperator("geq", "n,n", "b", 1);

	extension:RegisterOperator("ten", "b,n,n", "n", 1);
	extension:RegisterOperator( "is", "n", "b", 1, tobool, true);
	extension:RegisterOperator("neg", "n", "n", 1);
	extension:RegisterOperator("not", "n", "b", 1, function (context, number) return number == 0 end, true);

--[[
	*****************************************************************************************************************************************************
		Math functions
	*****************************************************************************************************************************************************
]]--

	extension:RegisterLibrary("math");
	extension:RegisterFunction("math", "abs", "n", "n", 1, "math.abs", true);
	extension:RegisterFunction("math", "ceil", "n", "n", 1, "math.ceil", true);
	extension:RegisterFunction("math", "floor", "n", "n", 1, "math.floor", true);
	extension:RegisterFunction("math", "cos", "n", "n", 1, "math.cos", true);
	extension:RegisterFunction("math", "acos", "n", "n", 1, "math.acos", true);
	extension:RegisterFunction("math", "asin", "n", "n", 1, "math.asin", true);
	extension:RegisterFunction("math", "atan", "n", "n", 1, "math.atan", true);
	extension:RegisterFunction("math", "exp", "n", "n", 1, "math.exp", true);
	extension:RegisterFunction("math", "log", "n", "n", 1, "math.log", true);
	extension:RegisterFunction("math", "log", "n,n", "n", 1, "math.log", true);
	extension:RegisterFunction("math", "fmod", "n,n", "n", 1, "math.fmod", true);
	extension:RegisterFunction("math", "rad", "n", "n", 1, "math.rad", true);
	extension:RegisterFunction("math", "deg", "n", "n", 1, "math.deg", true);
	extension:RegisterFunction("math", "randomseed", "n", "", 1, "math.randomseed", true);
	extension:RegisterFunction("math", "random", "", "n", 1, "math.random", true);
	extension:RegisterFunction("math", "random", "n", "n", 1, "math.random", true);
	extension:RegisterFunction("math", "random", "n,n", "n", 1, "math.random", true);
	extension:RegisterFunction("math", "pi", "", "n", 1, pi, true);
	extension:RegisterFunction("math", "sin", "n", "n", 1, math.sin, true);
	extension:RegisterFunction("math", "sqrt", "n", "n", 1, math.sqrt, true);
	extension:RegisterFunction("math", "tan", "n", "n", 1, tan, true);
	extension:RegisterFunction("math", "cot", "n", "n", 1, cot, true);
	extension:RegisterFunction("math", "acot", "n", "n", 1, acot, true);
	extension:RegisterFunction("math", "atan2", "n,n", "n", 1, math.atan2, true);
	extension:RegisterFunction("math", "lerp", "n,n,n", "n", 1, Lerp, true);

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();
