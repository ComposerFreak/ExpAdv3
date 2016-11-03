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

local CONTEXT = {};
CONTEXT.__index = CONTEXT;

function CONTEXT.Throw(this, error, fst, ...)
	local err = {};

	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	local trace;
	local level = 1;

	while(true) do
		local info = debug.getinfo( level, "Sln" );
		
		if (not info) then
			break;
		end

		if (info.short_src == "Expresion 3") then
			trace = this:GetScriptPos(info.currentline, 0)
			break;
		end
	end

	err.state = "runtime";
	err.char = trace and trace[1] or 0;
	err.line = trace and trace[2] or 0;
	err.msg = msg;

	error(err, 0);
end

function CONTEXT.GetScriptPos(this, line, char)
	for l, row in pairs(this.traceTable) do
		if (l >= line) then
			for c = 1, trace in pairs(row) do
				if (c >= char) then
					return true, trace[1], trace[2];
				end
			end
		end
	end

	return false, 0, 0;
end

--[[
]]

function ENT:SetCode(script, run)
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
		self:HandelThrown(res);

		return false;
	end

	self.nativeScript = res.script;

	self:BuildContext(res);

	if (run) then
		timer.Simple(1, function()
			self:InitScript();
		end);
	end

	return true;
end

--[[
]]

function ENT:BuildContext(instance)
	local context = setmetatable({}, CONTEXT);

	context.entity = self;
	context.player = self.player;
	context.traceTable = instance.traceTbl;

	self:BuildEnv(context, instance);

	self.context = this;
end

function ENT:BuildEnv(Context, instance)

	local env = {};
	env.GLOBAL  = {};
	env.CONTEXT = context;
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

	context.env = env;

	hook.Run("Expression3.BuildEntitySandbox", self, self.context, env);

	return setmetatable(env, meta);
end

function ENT:InitScript()
	local native = table.concat({
		"return function(env)",
		"	setfenv(1, env);",
			self.nativeScript,
		"end",
	}, "\n");

	local main = CompileString(native, "Expression 3", false);

	if (isstring(main)) then
		self:HandelThrown(main);
		return;
	end

	local init = main(self.context);

	hook.Run("Expression3.StartEntity", self, self.context);

	self.context.status = self:Execute(init);
end

--[[
]]

function ENT:Execute(func, ...)
	self:PreExecute();

	local results = {pcall(func, ...)};

	self:PostExecute();

	if (results[1]) then
		hook.Run("Expression3.UpdateEntity", self, self.context);
	else
		self:HandelThrown(results[2]);
	end

	return unpack(results);
end

function ENT:PreExecute()

end

function ENT:PostExecute()

end

--[[
]]

function ENT:IsRunning()
	return (self.context and self.context.status);
end

function ENT:ShutDown()
	if (self:IsRunning()) then
		self.context.status = false;
		hook.Run("Expression3.StopEntity", self, self.context);
	end
end

function ENT:HandelThrown(thrown)
	self:ShutDown();

	if (not thrown) then

	end

	if (isstring(thrown)) then

	end

	if (istable(thrown)) then
		
	end
end

--[[
]]


