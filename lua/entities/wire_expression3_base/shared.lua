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

AddCSLuaFile();

ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"

ENT.PrintName       = "Expression 3"
ENT.Author          = "Rusketh"
ENT.Contact         = ""
ENT.Expression3 	= true

--[[
	Base Context:
]]

local CONTEXT = {};
CONTEXT.__index = CONTEXT;

function CONTEXT.Trace(this, level, max)
	local stack = {};

	for i = level + 1, level + max do
		local info = debug.getinfo( level, "Sln" );
		
		if (not info) then
			break;
		end

		if (info.short_src == "Expresion 3") then
			local trace = this:GetScriptPos(info.currentline, 0);

			if (trace) then
				trace.level = #stack + 1;
				stack[trace.level] = trace;
			end
		end
	end

	return trace;
end

function CONTEXT.Throw(this, error, fst, ...)
	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	local stack = this:Trace(1, 1);
	local trace = stack[1];
	
	local err = {};
	err.state = "runtime";
	err.char = trace[1];
	err.line = trace[2];
	err.msg = msg;

	error(err, 0);
end

function CONTEXT.GetScriptPos(this, line, char)
	for l, row in pairs(this.traceTable) do
		if (l >= line) then
			for c, trace in pairs(row) do
				if (c >= char) then
					return trace;
				end
			end
		end
	end

	return nil;
end

--[[
	Set Code
]]

function ENT:SetCode(script, run)
	self.script = script;

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

	self.nativeScript = res.compiled;

	self:BuildContext(res);

	if (run) then
		timer.Simple(1, function()
			self:InitScript();
		end);
	end

	return true;
end

--[[
	Building a new context
]]

function ENT:BuildContext(instance)
	self.context = setmetatable({}, CONTEXT);

	self.context.entity = self;
	self.context.player = self.player;
	self.context.traceTable = instance.traceTbl;

	self:BuildEnv(self.context, instance);

end

function ENT:BuildEnv(context, instance)

	local env = {};
	env.GLOBAL  = {};
	env.SERVER = SERVER;
	env.CLIENT = CLIENT;
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

	hook.Run("Expression3.BuildEntitySandbox", self, context, env);

	return setmetatable(env, meta);
end

function ENT:InitScript()
	local native = table.concat({
		"return function(env)",
		"	setfenv(1, env);",
			self.nativeScript,
		"end",
	}, "\n");

	print("Native Lua");
	print(native);
	print("-----------------------------");

	local main = CompileString(native, "Expression 3", false);

	if (isstring(main)) then
		self:HandelThrown(main);
		return;
	end

	local init = main();

	hook.Run("Expression3.StartEntity", self, self.context);

	self.context.status = self:Execute(init, self.context.env);
end

--[[
	Executing
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
	print("pre-execute");
end

function ENT:PostExecute()
	print("post-execute");
end

--[[
	Gate is running and exceptions
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

	print("Expression 3 Error:", self);

	if (not thrown) then
		print("nil info given.")
	end

	if (isstring(thrown)) then
		print("error:", thrown);
	end

	if (istable(thrown)) then
		print("state:", thrown.state);
		print("msg:", thrown.msg);
		print("char:", thrown.char);
		print("line:", thrown.line);
	end
end

--[[
]]


