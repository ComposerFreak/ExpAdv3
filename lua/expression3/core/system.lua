--[[
	*****************************************************************************************************************************************************
		commonly needed functions
	*****************************************************************************************************************************************************
]]--
	
	local function notnil(obj)
		return obj ~= nil and obj ~= _nil
	end

	local function name(id)
		local obj = EXPR_LIB.GetClass(id);
		return obj and obj.name or id;
	end

	local func_tostring = EXPR_LIB.ToString;

--[[
	*****************************************************************************************************************************************************
		Invoke function
	*****************************************************************************************************************************************************
]]--

	local function func_invoke(context, result, count, func, ...)
		local r = func.result;
		local c = func.count;

		if (r == nil or r == "" or c == -1) then
			r, c = "_nil", 0;
		end

		if (result == nil or result == "" or count == -1) then
			result, count = "", 0;
		end

		if (result ~= r or count ~= c) then
			if (func.scr) then context = func.scr end
			context:Throw("Invoked function with incorrect return type %q:%i expected, got %q:%i.", name(result), count, name(r), c);
		end

		return func.op(...);
	end;

	EXPR_LIB.Invoke = func_invoke;

--[[
	*****************************************************************************************************************************************************
		create a new extention
	*****************************************************************************************************************************************************
]]--

	local extension = EXPR_LIB.RegisterExtension("system");

--[[
	*****************************************************************************************************************************************************
		system library
	*****************************************************************************************************************************************************
]]--

	extension:RegisterLibrary("system");

	extension:SetClientState();
	extension:RegisterFunction("system", "getClient", "", "p", 1, LocalPlayer);

	extension:SetSharedState();
	extension:RegisterFunction("system", "isServer", "", "b", 1, function(context) return SERVER end);
	extension:RegisterFunction("system", "isClient", "", "b", 1, function(context) return CLIENT end);
	extension:RegisterFunction("system", "getEntity", "", "e", 1, function(context) return context.entity end);
	extension:RegisterFunction("system", "getOwner", "", "p", 1, function(context) return context.player end);
	
--[[
	*****************************************************************************************************************************************************
		Print to chat and console
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterFunction("system", "print", "...", "", 0, function(context, ...)
		local values = {};

		for _, v in pairs({...}) do
			values[#values + 1] = func_tostring(context, v[1], v[2]);
		end

		print("System.Print->", unpack(values));
		context.entity:SendToOwner(EXPR_PRINT_CHAT, unpack(values));
	end);

	extension:RegisterFunction("system", "out", "...", "", 0, function(context, ...)
		local values = {};

		for _, v in pairs({...}) do
			values[#values + 1] = func_tostring(context, v[1], v[2])
		end

		context.entity:SendToOwner(EXPR_PRINT_GOLEM, unpack(values));
	end);

--[[
	*****************************************************************************************************************************************************
		Print Table
	*****************************************************************************************************************************************************
]]--

	local pntbl = CreateConVar("wire_expression3_printtbl", 100);

	local function tblString(t, l, ta, i)
		local s = s or ""
		local ta = ta or 0
		local i = i or 0
		local q = {}

		for k, v in pairs(t) do
			i = i + 1

			if i <= l then
				if v[1] == "t" then
					local d = tblString(v[2].tbl, l, ta + 1, i)

					s = s .. string.rep("	", ta) .. k .. ":\n"
					s = s .. d[1]
					i = d[2]
				else
					s = s .. string.rep("	", ta) .. k .. "	=	" .. tostring(v[2]) .. "\n"
				end
			else
				s = s .. "--- Max table print limit reached, printing cut off ---"

				break
			end
		end

		return {s, i}
	end
	
	extension:RegisterFunction("system", "printTable", "t", "", 0, function(context, t)
		local s = tblString(t.tbl, pntbl:GetInt())[1]

		context.entity:SendToOwner(EXPR_PRINT_GOLEM, s);
	end);

--[[
	*****************************************************************************************************************************************************
		system.invoke needs a custom compiler operation, 
	*****************************************************************************************************************************************************
]]--

	extension:RegisterFunction("system", "invoke", "cls,n,f,...", "", 0, EXPR_LIB.Invoke);

	hook.Add("Expression3.PostCompile.System.invoke", "Expression3.Core.Extensions", function(this, inst, token, data, compile)

		local r, c, prc = compile();
		-- We need to instruct the compiler what this actualy returns.
		local class = data.expressions[1].token.data; -- Return class was arg 1.
		local count = data.expressions[2].token.data; -- Return count was arg 2.

		return class, count, prc;
	end);

--[[
	*****************************************************************************************************************************************************
		Throwing errors
	*****************************************************************************************************************************************************
]]--

	extension:RegisterFunction("system", "throw", "er", "", 0, function(context, err)
		err.stack = context:Trace(1, 15);

		if (err.stack) then
			local trace = err.stack[1];

			if (trace) then
				err.char = trace[2];
				err.line = trace[1];
			end
		end

		error(err, 0);
	end, false);
	
--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();











