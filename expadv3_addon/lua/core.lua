--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Core Component::
	``````````````````
]]

hook.Add("Expression3.RegisterComponents", "Expression3.Extention.Core", function()
	local ext = EXPR_LIB.RegisterExtention("math")

	local function n_isType(v)
		return type(v) == "number";
	end

	local function n_isValid(v)
		return n ~= nil;
	end

	ext:RegisterClass("n", {"number", "normal", "int"}, n_isType, n_isValid);

	ext:EnableExtention();

	ext:RegisterOperator("add", "n,n", "n", 1, nil); -- the nill here indicates that we use native to handle this.

	ext:RegisterLibrary("math");

	ext:RegisterFunction("math", "clamp", "n,n,n", "n", 1, function(ctx, min, max, val)
		if (val < min) then
			return min;
		elseif (val > max) then
			return max;
		else
			return val;
		end
	end); -- n = math.clam(n,n,n);

	ext:RegisterFunction("math", "range", "n,n,n,n,n", "n", 2, function(ctx, fst, ...)
		local min = fst;
		local max = fst;

		for _, v in pairs({...}) do
			if (v < min) then
				min = v;
			end

			if (v > max) then
				max = v;
			end
		end

		return min, max; -- A good example of a function that can return more then 1 value.
	end); -- n, n = math.range(n,n,n,n,n);

end);