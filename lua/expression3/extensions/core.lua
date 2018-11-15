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
	Core Extension.
]]

local ext_core = EXPR_LIB.RegisterExtension("core");

ext_core.enabled = true;

--[[
]]


local pntbl = CreateConVar("wire_expression3_printtbl", 100)

--[[
	Class: NIL
]]

local _nil = {} -- Future implimentation of nil.
local isnil = function(obj) return obj == nil or obj == _nil end;
local notnil = function(obj) return obj ~= nil and obj ~= _nil end;

EXPR_LIB._NIL_ = _nil;

local class_nil = ext_core:RegisterClass("nil", {"void"}, isnil, isnil);

--[[
	Class: CLASS
]]

local class_type = ext_core:RegisterClass("cls", {"type", "class"}, isstring, isnil);

ext_core:RegisterOperator("neq", "cls,cls", "b", 1);
ext_core:RegisterOperator( "eq", "cls,cls", "b", 1);

--[[ Would work, but not keeping it because it could break invoke.
Class objects are to defined at compile time and not to movable objects!
ext_core:RegisterCastingOperator("s", "cls", function(cls)
	return cls;
end, false)]]

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
ext_core:RegisterOperator("ten", "b,b,b", "b", 1);

ext_core:RegisterCastingOperator("n", "b", function(b)
	return b and 1 or 0;
end, false)

ext_core:RegisterCastingOperator("b", "n", function(n)
	return n ~= 0 and true or false;
end, false)

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

ext_core:RegisterOperator("ten", "b,n,n", "n", 1);
ext_core:RegisterOperator( "is", "n", "b", 1, tobool, true);
ext_core:RegisterOperator("neg", "n", "n", 1);
ext_core:RegisterOperator("not", "n", "b", 1, function (context, number) return number == 0 end, true);

--[[
	Class: STRING
]]


local class_str = ext_core:RegisterClass("s", {"string"}, isstring, notnil);

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
ext_core:RegisterOperator("get", "s,n", "s", 1);

ext_core:RegisterOperator("ten", "b,s,s", "s", 1);
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

if (SERVER) then
	WireLib.DT.E3_API = {
		op = function() end; signature = ""; result = ""; count = 0
	}
end

ext_core:RegisterWiredInport("f", "E3_API");
ext_core:RegisterWiredOutport("f", "E3_API");

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

local function name(id)
	local obj = EXPR_LIB.GetClass(id);
	return obj and obj.name or id;
end

local func_tostring = EXPR_LIB.ToString;

local func_invoke = function(context, result, count, func, ...)
	local r = func.result;
	local c = func.count;

	if (r == nil or c == -1) then
		r, c = "", 0
	end

	if (result == nil or count == -1) then
		result, count = "", 0
	end

	if (result ~= r or count ~= c) then
		if (func.scr) then context = func.scr end
		context:Throw("Invoked function with incorrect return type %q:%i expected, got %q:%i.", name(result), count, name(r), c);
	end

	return func.op(...);
end; EXPR_LIB.Invoke = func_invoke;

-- \/ Library \/

ext_core:RegisterLibrary("system");

ext_core:RegisterFunction("system", "isServer", "", "b", 1, function(context) return SERVER end);

ext_core:RegisterFunction("system", "isClient", "", "b", 1, function(context) return CLIENT end);

ext_core:RegisterFunction("system", "getEntity", "", "e", 1, function(context) return context.entity end);

ext_core:RegisterFunction("system", "getOwner", "", "p", 1, function(context) return context.player end);

ext_core:SetClientState();

ext_core:RegisterFunction("system", "getClient", "", "p", 1, LocalPlayer);

ext_core:SetSharedState();

ext_core:RegisterFunction("system", "invoke", "cls,n,f,...", "", 0, EXPR_LIB.Invoke);

ext_core:RegisterFunction("system", "print", "...", "", 0, function(context, ...)
	local values = {};

	for _, v in pairs({...}) do
		values[#values + 1] = func_tostring(context, v[1], v[2]);
	end

	context.entity:SendToOwner(EXPR_PRINT_CHAT, unpack(values));
end);

---------------------
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
---------------------

ext_core:RegisterFunction("system", "printTable", "t", "", 0, function(context, t)
	local s = tblString(t.tbl, pntbl:GetInt())[1]

	context.entity:SendToOwner(EXPR_PRINT_GOLEM, s);
end);

ext_core:RegisterFunction("system", "out", "...", "", 0, function(context, ...)
	local values = {};

	for _, v in pairs({...}) do
		values[#values + 1] = func_tostring(context, v[1], v[2])
	end

	context.entity:SendToOwner(EXPR_PRINT_GOLEM, unpack(values));
end);

	--[[
		::EXAMPLE - Compile time alterations for function call::
			* You should never need this, but you can alter the compilers output here.
			* When system.invoke is called, we take all parameters and convert to variant.
	]]

hook.Add("Expression3.PostCompile.System.invoke", "Expression3.Core.Extensions", function(this, inst, token, data)

	-- We need to instruct the compiler what this actualy returns.
	local class = data.expressions[1].token.data; -- Return class was arg 1.
	local count = data.expressions[2].token.data; -- Return count was arg 2.

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

local function resultsToTable(status, class, results)
	local t = {{"b", status}};
	for i = 1, #results do t[i + 1] = {class, results[i]} end
	return {tbl = t, children = {}, parents = {}, size = #t};
end

ext_core:RegisterFunction("event", "call", "s,...", "b", 1, function(context, event, ...)
	local status = context.ent:CallEvent("", 0, event, ...);
	return status;
end);

ext_core:RegisterFunction("event", "call", "cls,n,s,...", "t", 1, function(context, class, count, event, ...)
	local status, results = context.ent:CallEvent(class, count, event, ...);
	return resultsToTable(status, class, results);
end);

ext_core:RegisterFunction("event", "call", "e,s,...", "b", 1, function(context, entity, event, ...)
	if (not IsValid(entity) or not entity.Expression3) then return end
	if not context:CanUseEntity(entity) then return end
	local status = entity:CallEvent("", 0, event, ...);
	return status;
end);

ext_core:RegisterFunction("event", "call", "cls,n,e,s,...", "", 0, function(context, class, count, entity, event, ...)
	if (not IsValid(entity) or not entity.Expression3) then return end
	if not context:CanUseEntity(entity) then return end
	local status, results = entity:CallEvent(class, count, event, ...);
	return resultsToTable(status, class, results);
end);

--[[
	Library: MATH
]]

local math_floor = math.floor

ext_core:RegisterLibrary("math");

--ext_core:RegisterFunction("math", "huge", "n", "n", 1, "math.huge", true);	--Isn't function
ext_core:RegisterFunction("math", "abs", "n", "n", 1, "math.abs", true);
ext_core:RegisterFunction("math", "ceil", "n", "n", 1, "math.ceil", true);
ext_core:RegisterFunction("math", "floor", "n", "n", 1, "math.floor", true);
ext_core:RegisterFunction("math", "cos", "n", "n", 1, "math.cos", true);
ext_core:RegisterFunction("math", "acos", "n", "n", 1, "math.acos", true);
ext_core:RegisterFunction("math", "asin", "n", "n", 1, "math.asin", true);
ext_core:RegisterFunction("math", "atan", "n", "n", 1, "math.atan", true);
ext_core:RegisterFunction("math", "exp", "n", "n", 1, "math.exp", true);
ext_core:RegisterFunction("math", "log", "n", "n", 1, "math.log", true);
ext_core:RegisterFunction("math", "log", "n,n", "n", 1, "math.log", true);
ext_core:RegisterFunction("math", "fmod", "n,n", "n", 1, "math.fmod", true);
--ext_core:RegisterFunction("math", "modf", "n,n", "n", 2, "math.modf", true);	--In Lua math.modf returns two values: http://wiki.garrysmod.com/page/math/modf
ext_core:RegisterFunction("math", "rad", "n", "n", 1, "math.rad", true);
ext_core:RegisterFunction("math", "deg", "n", "n", 1, "math.deg", true);
ext_core:RegisterFunction("math", "randomseed", "n", "", 1, "math.randomseed", true);
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
	Register Extensions
]]

hook.Add("Expression3.RegisterExtensions", "Expression3.Core.Extensions", function()
	ext_core:EnableExtension(); -- Core is registered first :P

	local path = "expression3/extensions/";
	local extensions = file.Find( path .. "*.lua", "LUA" );

	for i, filename in pairs( extensions ) do
		print("Loading E3 ext: " .. filename);
		include( path .. filename );
	end
end);
