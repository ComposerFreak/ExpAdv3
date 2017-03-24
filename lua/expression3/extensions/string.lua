--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Advanced String Extension::
]]

local extention = EXPR_LIB.RegisterExtenstion("string");

extention:RegisterMethod("s", "char", "", "n", 1, "string.char", true);

extention:RegisterMethod("s", "endsWith", "s", "b", 1, "string.EndsWith", true);

extention:RegisterMethod("s", "replace", "ptr,s,n", "s", 1, "string.gsub", true);

extention:RegisterMethod("s", "lower", "", "s", 1, "string.lower", true);

extention:RegisterMethod("s", "PatternSafe", "", "s", 1, "string.PatternSafe", true);

extention:RegisterMethod("s", "rep", "n", "s", 1, "string.rep", true);

extention:RegisterMethod("s", "rep", "n,s", "s", 1, "string.rep", true);

extention:RegisterMethod("s", "Replace", "", "s", 1, "string.", true);

extention:RegisterMethod("s", "reverse", "", "s", 1, "string.reverse", true);

extention:RegisterMethod("s", "Right", "n", "s", 1, "string.Right", true);

extention:RegisterMethod("s", "SetChar", "n,s", "s", 1, "string.SetChar", true);

extention:RegisterMethod("s", "Split", "s", "s", 1, "string.Split", true);

extention:RegisterMethod("s", "StartWith", "s", "s", 1, "string.StartWith", true);

extention:RegisterMethod("s", "sub", "n,n", "s", 1, "string.sub", true);

extention:RegisterMethod("s", "Trim", "s", "s", 1, "string.Trim", true);

extention:RegisterMethod("s", "TrimLeft", "s", "s", 1, "string.TrimLeft", true);

extention:RegisterMethod("s", "TrimRight", "s", "s", 1, "string.TrimRight", true);

extention:RegisterMethod("s", "upper", "", "s", 1, "string.upper", true);

--[[
	FIND
]]

extention:RegisterMethod("s", "find", "s,s", "n", 2, function(a, b)
	local s, e = string.find(a, b, 1, true); -- No patterns
end, true);

extention:RegisterMethod("s", "find", "s,s,n", "n", 2, function(a, b, c)
	local s, e = string.find(a, b, c, true); -- No patterns
end, true);

extention:RegisterMethod("s", "find", "s,ptr", "n", 2, function(a, b)
	local s, e = string.find(a, b, 1); -- No patterns
end, true);

extention:RegisterMethod("s", "find", "s,ptr,n", "n", 2, function(a, b, c)
	local s, e = string.find(a, b, c); -- No patterns
end, true);

--[[
	GMATCH
]]

local invoke = EXPR_LIB.Invoke;

extention:RegisterMethod("s", "gmatch", "s,ptr,f", "s", 1, function(context, str, ptr, fun)
	for w in string.gmatch( str, ptr ) do
		invoke(context, "s", 1, func, {"s", w})
	end
end);

extention:RegisterMethod("s", "match", "s,ptr,n", "s", 1, "string.match", true);

extention:EnableExtenstion();