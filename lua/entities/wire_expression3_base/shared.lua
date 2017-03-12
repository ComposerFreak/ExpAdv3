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

include("sh_cppi.lua");
include("sh_context.lua");

ENT.Type 			= "anim";
ENT.Base 			= "base_wire_entity";

ENT.PrintName       = "Expression 3";
ENT.Author          = "Rusketh";
ENT.Contact         = "";

ENT.Expression3 	= true;

--[[
	Validate / Set Code
]]

function ENT:Validate(script)
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

	return ok, res;
end

function ENT:SetCode(script, run)
	self.script = script;

	local Toker = EXPR_TOKENIZER.New();

	Toker:Initalize("EXPADV", script);

	local ok, res = self:Validate(script);

	if (not ok) then
		self:HandelThrown(res);

		return false;
	end

	self.nativeScript = res.compiled;

	self:BuildContext(res);

	if (SERVER) then
		local name = "generic";

		if (res.directives and res.directives.name) then
			name = res.directives.name;
		end

		self:SetScriptName(name);
		self:BuildWiredPorts(res.directives.inport, res.directives.outport);
	end

	if (run) then
		timer.Simple(1, function()
			if (IsValid(self)) then
				self:InitScript();
			end
		end);
	end

	return true;
end

--[[
	Building a new context
]]

function ENT:BuildContext(instance)
	self.context = EXPR_CONTEXT.New();
	print("NEW CONTEXT:", self.context)
	self.context.events = {};
	self.context.entity = self;
	self.context.player = self.player;
	self.context.traceTable = instance.traceTbl;

	self:BuildEnv(self.context, instance);

	EXPR_LIB.RegisterContext(self.context);
end

local env_meta = {
	_index = function(_, v)
		error("Attempt to reach Lua environment " .. v, 1);
	end;

	__newindex = function(_, v)
		error("Attempt to write to lua environment " .. v, 1);
	end
}

function ENT:BuildEnv(context, instance)

	context.env = instance.enviroment;

	local env = context.env;

	-- Enviroment Values
		env.GLOBAL  = {};
		env.DELTA = {};
		env.INPUT = {}
		env.OUTPUT = {};
		env.SERVER = SERVER;
		env.CLIENT = CLIENT;
		env.CONTEXT = context;

	-- Main Operations
		env._OPS	= instance.operators;
		env._CONST	= instance.constructors;
		env._METH	= instance.methods;
		env._FUN	= instance.functions;
	
	-- Fucntions we need
		env.invoke  = EXPR_LIB.Invoke;
		env.setmetatable = setmetatable;
		env.error   = error;
		env.pcall   = pcall;

	-- Store previous value for delta and changed.
		local glob = {};
		local delta = {};

		setmetatable(env.GLOBAL, {
			__index = function(t, k)
				return glob[k];
			end;

			__newindex = function(t, k, v)
				delta[k] = glob[k];
				glob[k] = v;
			end;
		});

		setmetatable(env.DELTA, {
			__index = function(t, k)
				local v = delta[k];
				delta[k] = glob[k];
				return v;
			end;

			__newindex = function(t, k, v)
				delta[k] = v;
			end;
		});

	-- Get wire changes
		local out_changed = {};
		local out_values = {};

		context.wire_in = env.INPUT;
		context.wire_out = env.OUTPUT;
		context.wire_clk = out_changed;

		setmetatable(env.OUTPUT, {
			__index = function(t, k)
				return out_values[k];
			end;

			__newindex = function(t, k, v)
				out_changed[k] = out_changed[k] or (out_values[k] ~= v);
				out_values[k] = v;
			end;
		});

	hook.Run("Expression3.Entity.BuildSandbox", self, context, env);

	return setmetatable(env, env_meta);
end

function ENT:InitScript()
	local main = CompileString(self.nativeScript, "Expression 3", false);

	if (isstring(main)) then
		self:HandelThrown(main);
		return;
	end

	local init = main();

	hook.Run("Expression3.Entity.Start", self, self.context);

	self.context.status = self:Execute(init, self.context.env);

	self:PostInitScript();
end

--[[
	Executing
]]

function ENT:Execute(func, ...)
	self.context:PreExecute(); -- This is the stable working one.

	local results = {pcall(func, ...)};

	self.context:PostExecute();

	if (results[1]) then
		self.context.update = true;
	else
		self:HandelThrown(results[2]);
	end

	return unpack(results);
end

function ENT:Execute(func, ...) -- This is the new one.
	local tb, es = {};
	local cb = function(err)
		es = err;
		local i = 1;

		while true do

			local info = debug.getinfo(i, "Sln");
			
			if ( !info ) then
				break;
			end

			tb[i] = info;

			i = i + 1;
		end
	end;

	self.context:PreExecute();

	local results = {xpcall(func, cb,  ...)};

	self.context:PostExecute();

	if (results[1]) then
		self.context.update = true;
	else
		self:HandelThrown(results[2] or es, tb);
	end

	return unpack(results);
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
		hook.Run("Expression3.Entity.Stop", self, self.context);
		EXPR_LIB.UnregisterContext(self.context);
	end
end

--[[
]]

function ENT:WriteToLogger(...)
	local log, logger = {...}, self.Logger;
	
	if (not logger) then
		self.Logger = log;
		return;
	end

	for i = 1, #log do
		logger[#logger + 1] = log[i];
	end
end

function ENT:FlushLogger()
	if (self.Logger and #self.Logger > 0) then
		self:SendToOwner(true, unpack(self.Logger));
		self.Logger = nil;
	end
end

function ENT:PrintStackTrace(stackTrace)
if (stackTrace and #stackTrace > 0) then
		self:WriteToLogger("{\n");
		for level, info in pairs(stackTrace) do
			if (info.what == "C") then
				self:WriteToLogger(string.format( "\t%i: C function\t\"%s\"\n", level, info.name));
			else
				self:WriteToLogger(string.format("\t%i: Line %d\t\"%s\"\t\t%s\n", level, info.currentline, info.name, info.short_src));
			end
		end
		self:WriteToLogger("}\n");
	end
end

function ENT:HandelThrown(thrown, stackTrace)
	self:SendToOwner(false, Color(255,0,0), "One of your Expression3 gate's has errored (see golem console).");

	if (not thrown) then
		self:WriteToLogger(Color(255,0,0), "Suffered an unkown error (no reason given).");
		self:PrintStackTrace(stackTrace)
		self:FlushLogger();
		self:ShutDown();

	elseif (isstring(thrown)) then
		self:WriteToLogger(Color(255,0,0), "Suffered a lua error:\n");
		self:WriteToLogger("    ", Color(0,255, 255), "Error: ", Color(255, 255, 255), thrown);
		self:PrintStackTrace(stackTrace);
		self:FlushLogger();
		self:ShutDown();

	elseif (istable(thrown)) then
		if (thrown.ctx and thrown.ctx ~= self.context) then
			self:WriteToLogger(Color(255,0,0), "Suffered a ", thrown.state, " error:\n");
			self:WriteToLogger(Color(0,255, 255), "Message: ", Color(255, 255, 255), "Remotly executed function threw an error", "\n");
			self:WriteToLogger(Color(0,255, 255), "Thrown error: ", Color(255, 255, 255), thrown.msg, "\n");
			self:WriteToLogger(Color(0,255, 255), "External Trace: ", Color(255, 255, 255), "Line ", thrown.line, " Char ", thrown.char);
			self:PrintStackTrace(stackTrace);
			self:FlushLogger();
			self:ShutDown();

			if (IsValid(thrown.ctx.entity)) then
				thrown.ctx.entity:SendToOwner(false, Color(255,0,0), "One of your Expression3 gate's has errored (see golem console).");
				thrown.ctx.entity:WriteToLogger(Color(255,0,0), "Suffered a ", thrown.state, " error:\n")
				thrown.ctx.entity:WriteToLogger(Color(0,255, 255), "Message: ", Color(255, 255, 255), "A function executed from a remote source threw an error.", "\n")
				thrown.ctx.entity:WriteToLogger(Color(0,255, 255), "Thrown error: ", Color(255, 255, 255), thrown.msg, "\n");
				thrown.ctx.entity:WriteToLogger(Color(0,255, 255), "At: ", Color(255, 255, 255), "Line ", thrown.line, " Char ", thrown.char);
				thrown.ctx.entity:PrintStackTrace(stackTrace);
				thrown.ctx.entity:FlushLogger();
				thrown.ctx.entity:ShutDown();
			end
		else
			self:WriteToLogger(Color(255,0,0), "Suffered a ", thrown.state, " error:\n")
			self:WriteToLogger("    ", Color(0,255, 255), "Message: ", Color(255, 255, 255), thrown.msg, "\n")
			self:WriteToLogger("    ", Color(0,255, 255), "At: ", Color(255, 255, 255), "Line ", thrown.line, " Char ", thrown.char)
			self:FlushLogger()
			self:ShutDown();
		end
	end
end

--[[
]]

function ENT:Invoke(where, result, count, udf, ...)
	if (self:IsRunning()) then

		if (udf and udf.op) then

			if (result ~= udf.result or count ~= udf.count) then
				self:HandelThrown("Invoked function with incorrect return type " .. result .. " expected, got " .. udf.result .. ".");
			end

			self.context:PreExecute();

			local results = {pcall(udf.op, ...)};

			local status = table.remove(results, 1);

			self.context:PostExecute();

			if (status) then
				self.context.update = true;
				-- Moving this hook to run once per think instead.
				-- hook.Run("Expression3.UpdateEntity", self, self.context);
			else
				self:HandelThrown(results[1]);
			end

			return staus, results;
		end
	end
end

function ENT:CallEvent(result, count, event, ...)
	if (self:IsRunning()) then
		local events = self.context.events[event];

		if (events) then
			for id, udf in pairs(events) do
				local where = string.format("Event.%s.%s", event, id);
				local status, results = self:Invoke(where, result, count, udf, ...)

				if (not status) then
					return false;
				end

				if (results[1] ~= nil) then
					return true, results;
				end
			end
		end
	end
end

--[[
	Performance Related Stuff
]]

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ScriptName");
	self:NetworkVar("Float", 0, "ServerAverageCPU");
	self:NetworkVar("Float", 1, "ServerTotalCPU");
	self:NetworkVar("Bool", 1, "ServerWarning");end

if (CLIENT) then
	AccessorFunc(ENT, "cl_average_cpu", "ClientAverageCPU", FORCE_NUMBER);
	AccessorFunc(ENT, "cl_total_cpu", "ClientTotalCPU", FORCE_NUMBER);
	AccessorFunc(ENT, "cl_cpu_warning", "ClientWarning", FORCE_BOOL);
end

function ENT:UpdateQuotaValues()
	local r = self:IsRunning();

	local context = self.context;

	if (SERVER) then
		self:SetServerAverageCPU((r and context.cpu_average or 0) * 1000);
		self:SetServerTotalCPU((r and context.cpu_total or 0) * 1000);
		self:SetServerWarning(r and context.cpu_warning or false);
	end

	if (CLIENT) then
		self:SetClientAverageCPU((r and context.cpu_average or 0) * 1000);
		self:SetClientTotalCPU((r and context.cpu_total or 0) * 1000);
		self:SetClientWarning(r and context.cpu_warning or false);
	end

	if (r) then
		context:UpdateQuotaValues();
	end
end

function ENT:Think()
	self:UpdateQuotaValues();

	if (SERVER) then
		self:TriggerOutputs();
	end

	hook.Run("Expression3.Entity.Think", self, self.context);
end