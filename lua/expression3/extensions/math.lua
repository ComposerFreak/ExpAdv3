--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Advanced Math Extension::
]]

local extension = EXPR_LIB.RegisterExtension("math");

local halfPi = math.pi/2;
local tan  = math.tan;
local atan = math.atan;


local function cot( radians )
	return 1 / tan( radians );
end

local function acot( radians )
	return halfPi - atan( radians );
end

extension:RegisterFunction("math", "pi", "", "n", 1, math.pi, true);

extension:RegisterFunction("math", "sin", "n", "n", 1, math.sin, true);

extension:RegisterFunction("math", "cos", "n", "n", 1, math.cos, true);

extension:RegisterFunction("math", "sqrt", "n", "n", 1, math.sqrt, true);

extension:RegisterFunction("math", "tan", "n", "n", 1, tan, true);

extension:RegisterFunction("math", "cot", "n", "n", 1, cot, true);

extension:RegisterFunction("math", "acot", "n", "n", 1, acot, true);

extension:RegisterFunction("math", "atan2", "n,n", "n", 1, math.atan2, true);

extension:RegisterFunction("math", "lerp", "n,n,n", "n", 1, Lerp, true);

extension:EnableExtension();
