--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Expression 3 Base::
]]

function ENT:SetCode(script)
	this.script = script;

	local Toker = EXPR_TOKENIZER.New();

	Toker:Initalize("EXPADV", script);

	local ok, res = Toker:Run();

	if ok then
		local Parser = EXPR_PARSER.New();

		Parser:Initalize(res);

		ok, res = Parser:Run();

		if ok then
			local Compiler = EXPR_COMPILER.New();

			Compiler:Initalize(res);

			ok, res = Compiler:Run();
		end
	end

	if (not ok) then
		self:Throw(res);

		return false;
	end

	self:BuildContext(res);

	return true;
end

--[[ I dont need this yet.
local function import(env, object)
	local G = _G;
	local E = env;
	local exp = string.Explode(".", object);

	for i = 1, #exp do
		local k = exp[i];

		if (i == #exp) then
			E[k] = G[k];
			break;
		end

		if (G[k]) then
			local v = G[k];

			if (istable(v)) then
				
				if (not E[v]) then
					E[v] = {};
				end

				E = E[v];
				G = G[V];
			else
				error("Failed to import " .. object, 1);
			end
		end
	end
end
]]

function ENT:BuildEnv(Context, instance)

	local env = {};
	env.GLOBAL  = {};
	env.CONTEXT = Context;
	env._OPS	= instance.operators;
	env._CONST	= instance.constructors;
	env._METH	= instance.methods;
	env._FUN	= instance.functions;
	
	local meta = {};

	meta.__index = function(_, v)
		error("Attempt to reach Lua environment " .. v, 1);
	end

	meta.__newindex = function(_, v)
		error("Attempt to write to lua environment " .. v, 1);
	end 

	Context.env = env;

	-- TODO: Initalize global variables.

	return setmetatable(env, meta);
end