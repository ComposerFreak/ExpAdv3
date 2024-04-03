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

	local function pi()
		return math.pi	
	end

	local function huge()
		return math.huge
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

	local class_num = extension:RegisterClass("n", {"number", "int", "integer", "double", "normal"}, isnumber, EXPR_LIB.NOTNIL);

	extension:RegisterNativeDefault("n", "0");
	extension:RegisterWiredInport("n", "NORMAL");
	extension:RegisterWiredOutport("n", "NORMAL");
	extension:RegisterSyncable("n", net.WriteFloat, net.ReadFloat);
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
	extension:RegisterOperator("not", "n", "b", 1, function(context, number) return number == 0 end, true);

	extension:RegisterOperator("dlt", "n", "n", 1, function(pre, new) return (pre or 0) - new; end, true);

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
	extension:RegisterFunction("math", "angleDifference", "n,n", "n", 1, math.AngleDifference, true);
	extension:RegisterFunction("math", "approach", "n,n,n", "n", 1, math.Approach, true);
	extension:RegisterFunction("math", "approachAngle", "n,n,n", "n", 1, math.ApproachAngle, true);
	extension:RegisterFunction("math", "binToInt", "s", "n", 1, math.BinToInt, true);
	extension:RegisterFunction("math", "bSplinePoint", "n,t,n", "v", 1, math.BSplinePoint, true);
	extension:RegisterFunction("math", "clamp", "n,n,n", "n", 1, math.Clamp, true);
	extension:RegisterFunction("math", "cosh", "n", "n", 1, math.cosh, true);
	extension:RegisterFunction("math", "distance", "n,n,n,n", "n", 1, math.Distance, true);
	extension:RegisterFunction("math", "easeInOut", "n,n,n", "n", 1, math.EaseInOut, true);
	extension:RegisterFunction("math", "frexp", "n", "n", 1, math.frexp, true);
	extension:RegisterFunction("math", "intToBin", "n", "s", 1, math.IntToBin, true);
	extension:RegisterFunction("math", "ldexp", "n,n", "n", 1, math.ldexp, true);
	extension:RegisterFunction("math", "log10", "n", "n", 1, math.log10, true);
	extension:RegisterFunction("math", "max", "...", "n", 1, math.max, true);
	extension:RegisterFunction("math", "min", "...", "n", 1, math.min, true);
	extension:RegisterFunction("math", "modf", "n", "n", 1, math.modf, true);
	extension:RegisterFunction("math", "normalizeAngle", "n", "n", 1, math.NormalizeAngle, true);
	extension:RegisterFunction("math", "pow", "n,n", "n", 1, math.pow, true);
	extension:RegisterFunction("math", "remap", "n,n,n,n,n", "n", 1, math.Remap, true);
	extension:RegisterFunction("math", "sinh", "n", "n", 1, math.sinh, true);
	extension:RegisterFunction("math", "tanh", "n", "n", 1, math.tanh, true);
	extension:RegisterFunction("math", "timeFraction", "n,n,n", "n", 1, math.TimeFraction, true);
	extension:RegisterFunction("math", "truncate", "n,n", "n", 1, math.Truncate, true);
	extension:RegisterFunction("math", "huge", "", "n", 1, huge, true);
	extension:RegisterFunction("math", "lerpAngle", "n,a,a", "a", 1, LerpAngle, true);
	extension:RegisterFunction("math", "lerpVector", "n,v,v", "v", 1, LerpVector, true);

	extension:RegisterFunction("math", "round", "n", "n", 1, function(n)
		return math.floor(n + 0.5);
	end, true);
	
	extension:RegisterFunction("math", "round", "n,n", "n", 1, function(n, d)
		local shf = 10 ^ floor(d + 0.5);
		return math.floor(n * shf + 0.5) / shf;
	end, true);

	extension:RegisterFunction("math", "toString", "n", "s", 1, function(n)
		return "" .. (n or 0);
	end, true);

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();
