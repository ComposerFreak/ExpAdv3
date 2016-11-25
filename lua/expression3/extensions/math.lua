--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F
	::Math Extension::
]]

local extension = EXPR_LIB.RegisterExtension("math");

extension:RegisterLibrary("math");

extension:RegisterFunction("math", "abs", "n", "n", 1, math.abs, true);

extension:RegisterFunction("math", "acos", "n", "n", 1, math.acos, true);

extension:RegisterFunction("math", "asin", "n", "n", 1, math.asin, true);

extension:RegisterFunction("math", "atan", "n", "n", 1, math.asin, true);

extension:RegisterFunction("math", "ceil", "n", "n", 1, math.ceil, true);

extension:RegisterFunction("math", "cos", "n", "n", 1, math.cos, true);

extension:RegisterFunction("math", "deg", "n", "n", 1, math.deg, true);

extension:RegisterFunction("math", "exp", "n", "n", 1, math.exp, true);

extension:RegisterFunction("math", "floor", "n", "n", 1, math.floor, true);

extension:RegisterFunction("math", "fmod", "n", "n", 1, math.asin, true);

extension:RegisterFunction("math", "huge", "n", "n", 1, math.asin, true);

extension:RegisterFunction("math", "log", "n", "n", 1, math.log, true);

extension:RegisterFunction("math", "modf", "n", "n", 1, math.modf, true);

-- TODO: Add math.pi as constant

extension:RegisterFunction("math", "rad", "n", "n", 1, math.rad, true);

extension:RegisterFunction("math", "random", "", "n", 1, math.random, true); -- math.random() with no arguments generates a real number between 0 and 1
extension:RegisterFunction("math", "random", "n", "n", 1, math.random, true); -- math.random(upper) generates integer numbers between 1 and upper
extension:RegisterFunction("math", "random", "n,n", "n", 1, math.random, true); -- math.random(lower, upper) generates integer numbers between lower and upper


extension:RegisterFunction("math", "randomseed", "n", "n", 1, math.randomseed, true);

extension:RegisterFunction("math", "sin", "n", "n", 1, math.sin, true);

extension:RegisterFunction("math", "sqrt", "n", "n", 1, math.sqrt, true);

extension:RegisterFunction("math", "tan", "n", "n", 1, math.tan, true);

extension:EnableExtension();
