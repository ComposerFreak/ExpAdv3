--[[
	*****************************************************************************************************************************************************
		create a new extention
	*****************************************************************************************************************************************************
]]--
	
	local extension = EXPR_LIB.RegisterExtension("boolean");

--[[
	*****************************************************************************************************************************************************
		register boolean class
	*****************************************************************************************************************************************************
]]--
	
	local class_bool = extension:RegisterClass("b", {"boolean", "bool"}, isbool, EXPR_LIB.NOTNIL);

	extension:RegisterNativeDefault("b", "false");

	extension:RegisterWiredInport("b", "NORMAL", function(i)
		return i ~= 0;
	end);

	extension:RegisterWiredOutport("b", "NORMAL", function(o)
		return o and 1 or 0;
	end);

	extension:RegisterSyncable("b", net.WriteBool, net.ReadBool);

--[[
	*****************************************************************************************************************************************************
		boolean operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("neq", "b,b", "b", 1);
	extension:RegisterOperator( "eq", "b,b", "b", 1);
	extension:RegisterOperator("and", "b,b", "b", 1);
	extension:RegisterOperator( "or", "b,b", "b", 1);
	extension:RegisterOperator( "is", "b", "b", 1);
	extension:RegisterOperator("not", "b", "b", 1);
	extension:RegisterOperator("ten", "b,b,b", "b", 1);

--[[
	*****************************************************************************************************************************************************
		Boolean to number and back
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterCastingOperator("n", "b", function(b)
		return b and 1 or 0;
	end, false);

	extension:RegisterCastingOperator("b", "n", function(n)
		return n ~= 0 and true or false;
	end, false);

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();











