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

local extension = EXPR_LIB.RegisterExtension("string");

extension:RegisterMethod("s", "char", "", "n", 1, "string.char", true);

extension:RegisterMethod("s", "endsWith", "s", "b", 1, "string.EndsWith", true);

extension:RegisterMethod("s", "replace", "ptr,s,n", "s", 1, "string.gsub", true);

extension:RegisterMethod("s", "lower", "", "s", 1, "string.lower", true);

extension:RegisterMethod("s", "patternSafe", "", "s", 1, "string.PatternSafe", true);

extension:RegisterMethod("s", "replace", "", "s", 1, "string.", true);

extension:RegisterMethod("s", "reverse", "", "s", 1, "string.reverse", true);

extension:RegisterMethod("s", "right", "n", "s", 1, "string.Right", true);

extension:RegisterMethod("s", "setChar", "n,s", "s", 1, "string.SetChar", true);

extension:RegisterMethod("s", "split", "s", "s", 1, "string.Split", true);

extension:RegisterMethod("s", "startWith", "s", "s", 1, "string.StartWith", true);

extension:RegisterMethod("s", "sub", "n,n", "s", 1, "string.sub", true);

extension:RegisterMethod("s", "trim", "s", "s", 1, "string.Trim", true);

extension:RegisterMethod("s", "trimLeft", "s", "s", 1, "string.TrimLeft", true);

extension:RegisterMethod("s", "trimRight", "s", "s", 1, "string.TrimRight", true);

extension:RegisterMethod("s", "upper", "", "s", 1, "string.upper", true);

--[[
	REP
]]

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
	FIND
]]

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
	GMATCH
]]

local invoke = EXPR_LIB.Invoke;

extension:RegisterMethod("s", "gmatch", "s,ptr,f", "s", 1, function(context, str, ptr, fun)
	for w in string.gmatch( str, ptr ) do
		invoke(context, "s", 1, func, {"s", w})
	end
end);

extension:RegisterMethod("s", "match", "s,ptr,n", "s", 1, "string.match", true);

extension:EnableExtension();
