--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Core Features::
	`````````````````

	This file will impliment the primary types.
		*VOID
		*BOOLEAN
		*NUMBER
		*STRING
		*VARIANT
]]

--[[
	Core Extention.
]]

local ext_core = EXPR_LIB.RegisterExtension("core");

local function eqM(a, b, ...)
	for k, v in pairs({b, ...}) do
		if (a ~= v) then
			continue;
		end

		return true;
	end

	return false;
end

local function neqM(a, b, ...)
	for k, v in pairs({b, ...}) do
		if (a ~= v) then
			continue;
		end

		return false;
	end

	return true;
end

--[[
]]


--[[
	Class: NIL
]]

local _nil = {} -- Future implimentation of nil.
local isnil = function(obj) return obj == nil or obj == _nil end;
local notnil = function(obj) return obj ~= nil and obj ~= _nil end;

local class_nil = ext_core:RegisterClass("", {"void"}, isnumber, isnil);

--[[
	Class: CLASS
]]

local class_nil = ext_core:RegisterClass("cls", {"type"}, isstring, isnil);

--[[
	Class: BOOLEAN
]]

local class_bool = ext_core:RegisterClass("b", {"boolean", "bool"}, isbool, notnil);

ext_core:RegisterWiredInport("b", "NORMAL", function(i)
	return i ~= 0;
end);

ext_core:RegisterWiredOutport("b", "NORMAL", function(o)
	return o and 1 or 0;
end);

ext_core:RegisterOperator("neq", "b,b", "b", 1);
ext_core:RegisterOperator( "eq", "b,b", "b", 1);
ext_core:RegisterOperator("and", "b,b", "b", 1);
ext_core:RegisterOperator( "or", "b,b", "b", 1);
ext_core:RegisterOperator( "is", "b", "b", 1);
ext_core:RegisterOperator("not", "b", "b", 1); 

--[[
	Class: NUMBER
]]

local class_num = ext_core:RegisterClass("n", {"number", "int", "integer", "double", "normal"}, isnumber, notnil);

ext_core:RegisterWiredInport("n", "NORMAL");

ext_core:RegisterWiredOutport("n", "NORMAL");

ext_core:RegisterOperator("add", "n,n", "n", 1);
ext_core:RegisterOperator("sub", "n,n", "n", 1);
ext_core:RegisterOperator("div", "n,n", "n", 1);
ext_core:RegisterOperator("mul", "n,n", "n", 1);
ext_core:RegisterOperator("exp", "n,n", "n", 1);
ext_core:RegisterOperator("mod", "n,n", "n", 1);
ext_core:RegisterOperator("bxor", "n,n", "n", 1); -- Uses bit.bxor
ext_core:RegisterOperator("bor", "n,n", "n", 1);  -- Uses bit.bor
ext_core:RegisterOperator("band", "n,n", "n", 1); -- Uses bit.band
ext_core:RegisterOperator("bshl", "n,n", "n", 1); -- Uses bit.lshift
ext_core:RegisterOperator("bshr", "n,n", "n", 1); -- Uses bit.rshift
ext_core:RegisterOperator("neq", "n,n", "b", 1);
ext_core:RegisterOperator( "eq", "n,n", "b", 1); 
ext_core:RegisterOperator("lth", "n,n", "b", 1);
ext_core:RegisterOperator("leg", "n,n", "b", 1);
ext_core:RegisterOperator("gth", "n,n", "b", 1);
ext_core:RegisterOperator("geq", "n,n", "b", 1);
ext_core:RegisterOperator("eq*", "n,n", "b", 1, eqM, true);
ext_core:RegisterOperator("neq*", "n,n", "b", 1, neqM, true);

ext_core:RegisterOperator( "is", "n", "b", 1, tobool, true);
ext_core:RegisterOperator("neg", "n", "n", 1);
ext_core:RegisterOperator("not", "n", "b", 1, function (context, number) return number == 0 end, true);

--[[
	Class: STRING
]]

local class_str = ext_core:RegisterClass("s", {"string", "str"}, isstring, notnil);

ext_core:RegisterWiredInport("s", "STRING");

ext_core:RegisterWiredOutport("s", "STRING");

ext_core:RegisterOperator("add", "s,n", "s", 1);
ext_core:RegisterOperator("add", "n,s", "s", 1);
ext_core:RegisterOperator("add", "s,s", "s", 1);
ext_core:RegisterOperator("neq", "s,s", "b", 1);
ext_core:RegisterOperator( "eq", "s,s", "b", 1); 
ext_core:RegisterOperator("lth", "s,s", "b", 1);
ext_core:RegisterOperator("leg", "s,s", "b", 1);
ext_core:RegisterOperator("gth", "s,s", "b", 1);
ext_core:RegisterOperator("geq", "s,s", "b", 1);
ext_core:RegisterOperator("eq*", "s,s", "b", 1, eqM, true);
ext_core:RegisterOperator("neq*", "s,s", "b", 1, neqM, true); 
ext_core:RegisterOperator("get", "s,n", "s", 1); 

ext_core:RegisterOperator( "is", "s", "b", 1, function (context, string) return string and string ~= "" end, true);
ext_core:RegisterOperator("not", "s", "b", 1, function (context, string) return string and string ~= "" end, true);
ext_core:RegisterOperator("len", "s", "n", 1, string.len, true);

--[[
	Class: STRING-PATTERN
]]

local class_ptr = ext_core:RegisterClass("ptr", {"patern"}, isstring, notnil);

--[[
	Class: FUNCTION
]]

local class_function = ext_core:RegisterClass("f", {"function"}, istable, notnil);

--[[
	Class: OBJECT (VARIANT)
]]

local class_object = ext_core:RegisterClass("vr", {"variant", "object"}, istable, notnil);
	-- Yes this should known as an OBJECT, todo :D

function ext_core.PostLoadClasses(this, classes)
	for _, c in pairs(classes) do
		local id = c.id;
		
		if (id ~= "_vr" and id ~= "") then
			ext_core:RegisterCastingOperator(id, "vr", function(ctx, obj)
				return {id, obj};
			end);

			ext_core:RegisterCastingOperator("vr", id, function(ctx, vr)
				if (not vr or not vr[1] or vr[2] == nil) then
					ctx:Throw("attempt to cast variant of type nil to " .. c.name);
				end

				if (vr[1] ~= id) then
					ctx:Throw("attempt to cast variant of type " .. vr[1] .. " to " .. c.name);
				end

				return vr[2];
			end);
		end
	end
end

--[[
	Class: ERROR
]]

local class_error = ext_core:RegisterClass("er", {"error"}, istable, notnil);

ext_core:RegisterConstructor("er", "s", function(ctx, msg)
	local err = {};
	err.state = "runtime";
	err.char = 0;
	err.line = 0;
	err.msg = msg;
	err.ctx = ctx;
	return err;
end);

ext_core:RegisterMethod("er", "message", "", "s", 1, function(err)
	return err and err.msg or "n/a";
end, true)

ext_core:RegisterMethod("er", "char", "", "n", 1, function(err)
	return err and err.char or 0;
end, true)

ext_core:RegisterMethod("er", "line", "", "n", 1, function(err)
	return err and err.line or 0;
end, true)

--[[
	Library: SYSTEM
]]

local func_tostring = EXPR_LIB.ToString;

local func_invoke = function(context, result, count, func, ...)
	if (result ~= func.result or count ~= func.count) then
		context:Throw("Invoked function with incorrect return type %s expected, got %s.", result, func.result);
	end

	return func.op(...);
end; EXPR_LIB.Invoke = func_invoke;

-- \/ Library \/

ext_core:RegisterLibrary("system");

ext_core:RegisterFunction("system", "invoke", "cls,n,f,...", "", 0, EXPR_LIB.Invoke);

ext_core:RegisterFunction("system", "print", "...", "", 0, function(context, ...)
	local values = {};

	for _, v in pairs({...}) do
		values[#values + 1] = func_tostring(context, v[1], v[2]);
	end

	if (SERVER) then
		context.entity:SendToOwner(false, unpack(values));
	end

	if (CLIENT) then
		chat.AddText(unpack(values));
	end
end);

ext_core:RegisterFunction("system", "out", "...", "", 0, function(context, ...)
	local values = {};

	for _, v in pairs({...}) do
		values[#values + 1] = func_tostring(context, v[1], v[2])
	end

	context.entity:SendToOwner(true, unpack(values));
end);

	--[[ 
		::EXAMPLE - Compile time alterations for function call::
			* You should never need this, but you can alter the compilers output here.
			* When system.invoke is called, we take all peramaters and convert to variant.
	]] 

hook.Add("Expression3.PostCompile.System.invoke", "Expression3.Core.Extensions", function(this, inst, token, expressions)
	-- First all expressions passed to vararg need to be variants.

	if (#expressions > 3) then
		for i = 4, #expressions do
			local arg = expressions[i];

			if (arg.result ~= "_vr") then
				this:QueueInjectionBefore(inst, arg.token, "{", "\"" .. arg.result .. "\"", ",");

				this:QueueInjectionAfter(inst, arg.final, "}");
			end
		end
	end

	-- Secondly we need to instruct the compiler what this actualy returns.
	local class = expressions[1].token.data; -- Return class was arg 1.
	local count = expressions[2].token.data; -- Return count was arg 2.

	return class, count;
end);

ext_core:RegisterFunction("system", "throw", "er", "", 0, function(context, err)
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
	Library: EVENT
]]

-- When calling this you must always make your varargs into variants e.g "examp" -> {"s", "examp"}
local event_call = function(result, count, name, ...)
	for _, context in pairs(EXPR_LIB.GetAll()) do
		if (IsValid(context.entity)) then
			context.entity:CallEvent(result, count, name, ...);
		end
	end
end; EXPR_LIB.CallEvent = event_call;

ext_core:RegisterLibrary("event");

ext_core:RegisterFunction("event", "add", "s,s,f", "", 0, function(context, event, id, udf)
	local events = context.events[event];

	if (not events) then
		events = {};
		context.events[event] = events;
	end

	events[id] = udf;
end);

ext_core:RegisterFunction("event", "remove", "s,s", "", 0, function(context, event, id)
	local events = context.events[event];

	if (not events) then
		return;
	end

	events[id] = nil;
end);

ext_core:RegisterFunction("event", "call", "cls,n,s,...", "", 0, function(context, result, count, event, ...)
	local status, result = context.ent:CallEvent(result, count, event, ...);

	if (status) then
		return unpack(result);
	end
end);

--[[
	Library: MATH
]]

local math_floor = math.floor

ext_core:RegisterLibrary("math");

ext_core:RegisterFunction("math", "abs", "n", "n", 1, "math.abs", true);
ext_core:RegisterFunction("math", "acos", "n", "n", 1, "math.acos", true);
ext_core:RegisterFunction("math", "asin", "n", "n", 1, "math.asin", true);
ext_core:RegisterFunction("math", "atan", "n", "n", 1, "math.asin", true);
ext_core:RegisterFunction("math", "ceil", "n", "n", 1, "math.ceil", true);
ext_core:RegisterFunction("math", "cos", "n", "n", 1, "math.cos", true);
ext_core:RegisterFunction("math", "deg", "n", "n", 1, "math.deg", true);
ext_core:RegisterFunction("math", "exp", "n", "n", 1, "math.exp", true);
ext_core:RegisterFunction("math", "floor", "n", "n", 1, "math.floor", true);
ext_core:RegisterFunction("math", "fmod", "n", "n", 1, "math.asin", true);
ext_core:RegisterFunction("math", "huge", "n", "n", 1, "math.asin", true);
ext_core:RegisterFunction("math", "log", "n", "n", 1, "math.log", true);
ext_core:RegisterFunction("math", "modf", "n", "n", 1, "math.modf", true);
ext_core:RegisterFunction("math", "randomseed", "n", "n", 1, "math.randomseed", true);
ext_core:RegisterFunction("math", "rad", "n", "n", 1, "math.rad", true);
ext_core:RegisterFunction("math", "random", "", "n", 1, "math.random", true); -- math.random() with no arguments generates a real number between 0 and 1
ext_core:RegisterFunction("math", "random", "n", "n", 1, "math.random", true); -- math.random(upper) generates integer numbers between 1 and upper
ext_core:RegisterFunction("math", "random", "n,n", "n", 1, "math.random", true); -- math.random(lower, upper) generates integer numbers between lower and upper

--[[
	Library: STRING (including methods.)
]]

local string_char = string.char
local string_byte = string.byte
local string_len = string.len
local utf8_char = utf8.char
local utf8_byte = utf8.codepoint

ext_core:RegisterLibrary("string");

ext_core:RegisterFunction("string", "toNumber", "n", "s", 1, func, true);

ext_core:RegisterMethod("s", "toNumber", "n", "n", 1, function(n, b) return tonumber(n, base) or 0; end, true);

ext_core:RegisterFunction("string", "toChar", "n,", "s", 1, function(n)
	return (n < 1 or n > 255) and "" or string_char(n);
end, true);

ext_core:RegisterFunction("string", "toByte", "s,", "n", 1, function(s)
	return (s ~= "") and (string_byte(s) or -1) or -1;
end, true);

--[[
	MISC
]]

hook.Add("Think", "Expression3.Event", function()
	EXPR_LIB.CallEvent("", 0, "Think");
end);

--[[
	Register Extentions
]]

hook.Add("Expression3.RegisterExtensions", "Expression3.Core.Extensions", function()
	ext_core:EnableExtension(); -- Core is registered first :P

	include("expression3/extensions/math.lua");
	include("expression3/extensions/string.lua");
	include("expression3/extensions/vector.lua");
	include("expression3/extensions/angle.lua");
	include("expression3/extensions/entity.lua");
	include("expression3/extensions/table.lua");
	include("expression3/extensions/network.lua");
	include("expression3/extensions/color.lua");
	include("expression3/extensions/player.lua");


	-- Custom will go here.
end);


