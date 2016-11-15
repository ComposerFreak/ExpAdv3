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

local function isNil(o)
	return o == nil;
end

local function isNotNil(o)
	return o ~= nil;
end

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

local function RegisterVoidClass()
	EXPR_LIB.RegisterClass("nil", {"void"}, isnumber, isNil);
end

local function RegisterBooleanClass()
	EXPR_LIB.RegisterClass("b", {"boolean", "bool"}, isbool, isNotNil);

	hook.Add("Expression3.LoadOperators", "Expression3.Core.Boolean",
		function()
			EXPR_LIB.RegisterOperator("neq", "b,b", "b", 1);
			EXPR_LIB.RegisterOperator( "eq", "b,b", "b", 1);

			EXPR_LIB.RegisterOperator("and", "b,b", "b", 1);
			EXPR_LIB.RegisterOperator( "or", "b,b", "b", 1);

			EXPR_LIB.RegisterOperator( "is", "b", "b", 1);
			EXPR_LIB.RegisterOperator("not", "b", "b", 1); 
		end);
end

local function RegisterNumberClass()
	EXPR_LIB.RegisterClass("n", {"number", "normal", "int", "math.number"}, isnumber, isNotNil);

	hook.Add("Expression3.LoadOperators", "Expression3.Core.Number",
		function()
			EXPR_LIB.RegisterOperator("add", "n,n", "n", 1);
			EXPR_LIB.RegisterOperator("sub", "n,n", "n", 1);
			EXPR_LIB.RegisterOperator("div", "n,n", "n", 1);
			EXPR_LIB.RegisterOperator("mul", "n,n", "n", 1);
			EXPR_LIB.RegisterOperator("exp", "n,n", "n", 1);
			EXPR_LIB.RegisterOperator("mod", "n,n", "n", 1);

			EXPR_LIB.RegisterOperator("bxor", "n,n", "n", 1); -- Uses bit.bxor
			EXPR_LIB.RegisterOperator("bor", "n,n", "n", 1);  -- Uses bit.bor
			EXPR_LIB.RegisterOperator("band", "n,n", "n", 1); -- Uses bit.band
			EXPR_LIB.RegisterOperator("bshl", "n,n", "n", 1); -- Uses bit.lshift
			EXPR_LIB.RegisterOperator("bshr", "n,n", "n", 1); -- Uses bit.rshift

			EXPR_LIB.RegisterOperator("neq", "n,n", "b", 1);
			EXPR_LIB.RegisterOperator( "eq", "n,n", "b", 1); 
			EXPR_LIB.RegisterOperator("lth", "n,n", "b", 1);
			EXPR_LIB.RegisterOperator("leg", "n,n", "b", 1);
			EXPR_LIB.RegisterOperator("gth", "n,n", "b", 1);
			EXPR_LIB.RegisterOperator("geq", "n,n", "b", 1);

			EXPR_LIB.RegisterOperator("eq*", "n,n", "b", 1, eqM, true);
			EXPR_LIB.RegisterOperator("neq*", "n,n", "b", 1, neqM, true);

			-- TESTING
			EXPR_LIB.RegisterOperator("call", "n,n", "n", 1, function(a, b) return a + b end);

			local function notN(context, number)
				return number == 0;
			end

			EXPR_LIB.RegisterOperator( "is", "n", "b", 1, tobool, true);
			EXPR_LIB.RegisterOperator("neg", "n", "n", 1);
			EXPR_LIB.RegisterOperator("not", "n", "b", 1, notN, true);

	end);
end

local function RegisterStringClass()
	EXPR_LIB.RegisterClass("s", {"string"}, isstring, isNotNil);

	hook.Add("Expression3.LoadOperators", "Expression3.Core.String",
		function()
			EXPR_LIB.RegisterOperator("add", "s,n", "n", 1);
			EXPR_LIB.RegisterOperator("add", "n,s", "n", 1);
			EXPR_LIB.RegisterOperator("add", "s,s", "n", 1);

			EXPR_LIB.RegisterOperator("neq", "s,s", "b", 1);
			EXPR_LIB.RegisterOperator( "eq", "s,s", "b", 1); 
			EXPR_LIB.RegisterOperator("lth", "s,s", "b", 1);
			EXPR_LIB.RegisterOperator("leg", "s,s", "b", 1);
			EXPR_LIB.RegisterOperator("gth", "s,s", "b", 1);
			EXPR_LIB.RegisterOperator("geq", "s,s", "b", 1);

			EXPR_LIB.RegisterOperator("eq*", "s,s", "b", 1, eqM, true);
			EXPR_LIB.RegisterOperator("neq*", "s,s", "b", 1, neqM, true); 

			local function isS(context, string)
				return string and string ~= "";
			end

			local function notS(context, string)
				return string and string ~= "";
			end

			EXPR_LIB.RegisterOperator( "is", "s", "b", 1, isS, true);
			EXPR_LIB.RegisterOperator("not", "s", "b", 1, notS, true);
			EXPR_LIB.RegisterOperator("len", "s", "n", 1, string.len, true);
		end);
end

local function RegisterFunctionClass()
	EXPR_LIB.RegisterClass("f", {"function"}, istable, isNotNil);
end

local function RegisterVariantClass()
	EXPR_LIB.RegisterClass("vr", {"variant"}, istable, isNotNil);
end

hook.Add("Expression3.LoadClasses", "Expression3.Core.Classes", function()
	RegisterVoidClass();
	RegisterBooleanClass();
	RegisterNumberClass();
	RegisterStringClass();
	RegisterFunctionClass();
	RegisterVariantClass();
end);

hook.Add("Expression3.RegisterExtensions", "Expression3.Core.Extensions", function()
	-- TODO: Load extensions here.
	include("expression3/extensions/math.lua");

	include("expression3/extensions/vector.lua");
end);

hook.Add("Expression3.LoadLibraries", "Expression3.Core.Extensions", function()
	EXPR_LIB.RegisterLibrary("debug")
end);

hook.Add("Expression3.LoadFunctions", "Expression3.Core.Extensions", function()
	EXPR_LIB.RegisterFunction("debug", "print", "n", "", 0, function(n) print("OUT->", n) end, true);
end);
