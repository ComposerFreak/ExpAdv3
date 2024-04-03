--[[
	*****************************************************************************************************************************************************
		common functions
	*****************************************************************************************************************************************************
]]--
	
	local string_char = string.char
	local string_byte = string.byte
	local string_len = string.len
	local utf8_char = utf8.char
	local utf8_byte = utf8.codepoint

--[[
	*****************************************************************************************************************************************************
		create a new extention
	*****************************************************************************************************************************************************
]]--

	local extension = EXPR_LIB.RegisterExtension("string");

--[[
	*****************************************************************************************************************************************************
		register string class
	*****************************************************************************************************************************************************
]]--

	local class_str = extension:RegisterClass("s", {"string"}, isstring, EXPR_LIB.NOTNIL);

	extension:RegisterNativeDefault("s", "\"\"");
	extension:RegisterWiredInport("s", "STRING");
	extension:RegisterWiredOutport("s", "STRING");
	extension:RegisterSyncable("s", net.WriteString, net.ReadString);

--[[
	*****************************************************************************************************************************************************
		string operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("add", "s,n", "s", 1);
	extension:RegisterOperator("add", "n,s", "s", 1);
	extension:RegisterOperator("add", "s,s", "s", 1);
	extension:RegisterOperator("neq", "s,s", "b", 1);
	extension:RegisterOperator( "eq", "s,s", "b", 1);
	extension:RegisterOperator("lth", "s,s", "b", 1);
	extension:RegisterOperator("leg", "s,s", "b", 1);
	extension:RegisterOperator("gth", "s,s", "b", 1);
	extension:RegisterOperator("geq", "s,s", "b", 1);
	extension:RegisterOperator("get", "s,n", "s", 1);
	extension:RegisterOperator("ten", "b,s,s", "s", 1);
	extension:RegisterOperator( "is", "s", "b", 1, function (context, string) return string and string ~= "" end, true);
	extension:RegisterOperator("not", "s", "b", 1, function (context, string) return string and string ~= "" end, true);
	extension:RegisterOperator("len", "s", "n", 1, string.len, true);

--[[
	*****************************************************************************************************************************************************
		String methods
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterMethod("s", "char", "", "n", 1, "char", true);
	extension:RegisterMethod("s", "endsWith", "s", "b", 1, function(s, str) 
		return string.EndsWith(s, str);
	end, true);
	extension:RegisterMethod("s", "replace", "ptr,s,n", "s", 1, "gsub", true);
	extension:RegisterMethod("s", "lower", "", "s", 1, "lower", true);
	extension:RegisterMethod("s", "patternSafe", "", "s", 1, "PatternSafe", true);
	extension:RegisterMethod("s", "replace", "", "s", 1, "replace", true);
	extension:RegisterMethod("s", "reverse", "", "s", 1, "reverse", true);
	extension:RegisterMethod("s", "right", "n", "s", 1, "Right", true);
	extension:RegisterMethod("s", "setChar", "n,s", "s", 1, "SetChar", true);
	extension:RegisterMethod("s", "startWith", "s", "b", 1, function(s, str) 
		return string.StartWith(s, str);
	end, true);
	extension:RegisterMethod("s", "sub", "n", "s", 1, "sub", true);
	extension:RegisterMethod("s", "sub", "n,n", "s", 1, "sub", true);
	extension:RegisterMethod("s", "trim", "s", "s", 1, "Trim", true);
	extension:RegisterMethod("s", "trimLeft", "s", "s", 1, "TrimLeft", true);
	extension:RegisterMethod("s", "trimRight", "s", "s", 1, "TrimRight", true);
	extension:RegisterMethod("s", "upper", "", "s", 1, "upper", true);

	extension:RegisterMethod("s", "split", "s", "t", 1, function(str, sep)
		local t = string.Explode(sep, str);
		local c = #t;
		
		for i = 1, c do
			t[i] = {"s", t[i]};
		end

		return {tbl = t, children = {}, parents = {}, size = c};
		
	end, true);
--[[
	*****************************************************************************************************************************************************
		Repeate method
	*****************************************************************************************************************************************************
]]--

	local rep_chunk = 1000000
	local function str_rep(str, rep, sep) -- Author: edgarasf123
		if rep < 0.5 then return "" end

		local ret = {}
		for i = 1, rep / rep_chunk do
			ret[#ret+1] = string.rep( str, rep_chunk, sep )
		end

		local r = rep%rep_chunk
		if r>0.5 then
			ret[#ret+1] = string.rep(str, r, sep)
		end

		return table.concat(ret, sep)
	end

	extension:RegisterMethod("s", "rep", "n", "s", 1, str_rep, true);
	extension:RegisterMethod("s", "rep", "n,s", "s", 1, str_rep, true);
	extension:RegisterMethod("s", "rep", "n,s,s", "s", 1, str_rep, true);

--[[
	*****************************************************************************************************************************************************
		Pattern class
	*****************************************************************************************************************************************************
]]--

	local class_ptr = extension:RegisterClass("ptr", {"patern"}, isstring, notnil);

--[[
	*****************************************************************************************************************************************************
		Find functions
	*****************************************************************************************************************************************************
]]--

	extension:RegisterMethod("s", "find", "s,s", "n", 2, function(a, b)
		local s, e = string.find(a, b, 1, true); -- No patterns
		return s,e
	end, true);

	extension:RegisterMethod("s", "find", "s,s,n", "n", 2, function(a, b, c)
		local s, e = string.find(a, b, c, true); -- No patterns
		return s,e
	end, true);

	extension:RegisterMethod("s", "find", "s,ptr", "n", 2, function(a, b)
		local s, e = string.find(a, b, 1); -- No patterns
		return s,e
	end, true);

	extension:RegisterMethod("s", "find", "s,ptr,n", "n", 2, function(a, b, c)
		local s, e = string.find(a, b, c); -- No patterns
		return s,e
	end, true);


--[[
	*****************************************************************************************************************************************************
		Gmatch
	*****************************************************************************************************************************************************
]]--

	extension:RegisterMethod("s", "gmatch", "s,ptr,f", "s", 1, function(context, str, ptr, fun)
		for w in string.gmatch( str, ptr ) do
			EXPR_LIB.Invoke(context, "s", 1, func, {"s", w})
		end
	end);

	extension:RegisterMethod("s", "match", "s,ptr,n", "s", 1, "string.match", true);

--[[
	*****************************************************************************************************************************************************
		Create a new library
	*****************************************************************************************************************************************************
]]--

	extension:RegisterLibrary("string");

	extension:RegisterFunction("string", "toNumber", "s", "n", 1, function(s) return tonumber(s) or 0; end, true);

	extension:RegisterMethod("s", "toNumber", "n", "n", 1, function(n, b)
		return tonumber(n, base) or 0;
	end, true);

	extension:RegisterFunction("string", "toChar", "n,", "s", 1, function(n)
		return (n < 1 or n > 255) and "" or string_char(n);
	end, true);

	extension:RegisterFunction("string", "toByte", "s,", "n", 1, function(s)
		return (s ~= "") and (string_byte(s) or -1) or -1;
	end, true);

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();




