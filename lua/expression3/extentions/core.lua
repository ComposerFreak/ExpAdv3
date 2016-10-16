--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Core Features::
	``````````````````
]]

hook.add("Expression3.LoadClasses", "Expression3.Core", function()
	EXPR_LIB.RegisterClass("n", {"number", "int"},
		function(n)
			return type(n) == "number"
		end, function(n)
			return n ~= nil
		end);

	EXPR_LIB.RegisterClass("b", {"boolean", "bool"},
		function(n)
			return type(n) == "boolean"
		end, function(n)
			return n ~= nil
		end);

	EXPR_LIB.RegisterClass("s", "string",
		function(n)
			return type(n) == "string"
		end, function(n)
			return n ~= nil
		end);
end);

hook.add("Expression3.LoadOperators", "Expression3.Core", function()
	EXPR_LIB.RegisterOperator("add", "n,n", "n", 1); -- Native

	EXPR_LIB.RegisterOperator("add", "s,s", "s", 1); -- Native

	EXPR_LIB.RegisterOperator("sub", "n,n", "n", 1); -- Native

	EXPR_LIB.RegisterOperator("div", "n,n", "n", 1); -- Native

	EXPR_LIB.RegisterOperator("mul", "n,n", "n", 1); -- Native

	EXPR_LIB.RegisterOperator("exp", "n,n", "n", 1); -- Native

	EXPR_LIB.RegisterOperator("mod", "n,n", "n", 1); -- Native

	EXPR_LIB.RegisterOperator("bxor", "n,n", "n", 1); -- Uses bit.bxor

	EXPR_LIB.RegisterOperator("bor", "n,n", "n", 1);  -- Uses bit.bor

	EXPR_LIB.RegisterOperator("band", "n,n", "n", 1); -- Uses bit.band

	EXPR_LIB.RegisterOperator("bshl", "n,n", "n", 1); -- Uses bit.lshift

	EXPR_LIB.RegisterOperator("bshr", "n,n", "n", 1); -- Uses bit.rshift

	EXPR_LIB.RegisterOperator("neq", "n,n", "b", 1); -- Native

	EXPR_LIB.RegisterOperator("neq", "s,s", "b", 1); -- Native

	EXPR_LIB.RegisterOperator("eq", "n,n", "b", 1);  -- Native

	EXPR_LIB.RegisterOperator("eq", "s,s", "b", 1);  -- Native

	EXPR_LIB.RegisterOperator("lth", "n,n", "b", 1); -- Native

	EXPR_LIB.RegisterOperator("leg", "n,n", "b", 1); -- Native

	EXPR_LIB.RegisterOperator("gth", "n,n", "b", 1); -- Native

	EXPR_LIB.RegisterOperator("geq", "n,n", "b", 1); -- Native

	EXPR_LIB.RegisterOperator("neg", "n", "n", 1); -- Native

	EXPR_LIB.RegisterOperator("not", "n", "b", 1,
		function(context, number)
			return number == 0;
		end); -- None Native

	EXPR_LIB.RegisterOperator("is", "n", "b", 1,
		function(context, number)
			return number ~= 0;
		end); -- None Native


	EXPR_LIB.RegisterOperator("ten", "b,b,b", "b", 1) -- Native;

	EXPR_LIB.RegisterOperator("ten", "b,n,n", "n", 1) -- Native;

	EXPR_LIB.RegisterOperator("ten", "b,s,s", "s", 1) -- Native;

end);

hook.add("Expression3.RegisterExtensions", "Expression3.Core", function()
	-- TODO: Load extentions here.
end);


