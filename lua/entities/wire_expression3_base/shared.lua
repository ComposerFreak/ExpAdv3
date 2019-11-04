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

local function name(id)
	local obj = E3Class(id);
	return obj and obj.name or id;
end

--[[
	Validate / Set Code
]]

function ENT:SetCode(script, files, run)
	self:ShutDown();

	self.script = script;
	self.files = files;

	-- local ok, res = self:Validate(script, files);

	if (self.validator and not self.validator.finished) then
		self.validator.stop();
	end

	local cb = function(ok, res)
		if (not ok) then
			self:HandelThrown(res);

			return false;
		end

		self.validator = nil;
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
			timer.Simple(0.2, function()
				if (IsValid(self)) then
					self:InitScript();
				end
			end);
		end
	end

	self.validator = EXPR_LIB.Validate(cb, script, files);

	self.validator.start();

	return true;
end

--[[
	Building a new context
]]

function ENT:BuildContext(instance)
	self.context = EXPR_CONTEXT.New();
	self.context.data = {};
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
		env.VOID = EXPR_LIB._NIL_;

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

	-- Need a way to confirm user classes are the right has.
		local hashTable = instance.hashTable;

		function env.CheckHash(hash, class)
			local valid = hashTable[hash];
			if (valid) then return valid[class.hash]; end
		end

		-- hashtable[extends][class] = is isinstance of;

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

	local results = {xpcall(func, cb, ...)};

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

function ENT:OnRemove()
	self:ShutDown();
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
			self:WriteToLogger(Color(0,255, 255), "External Trace: ", Color(255, 255, 255), "Line ", thrown.line, " Char ", thrown.char, " ", thrown.instruction);
			self:PrintStackTrace(stackTrace);
			self:FlushLogger();
			self:ShutDown();

			if (IsValid(thrown.ctx.entity)) then
				thrown.ctx.entity:SendToOwner(false, Color(255,0,0), "One of your Expression3 gate's has errored (see golem console).");
				thrown.ctx.entity:WriteToLogger(Color(255,0,0), "Suffered a ", thrown.state, " error:\n")
				thrown.ctx.entity:WriteToLogger(Color(0,255, 255), "Message: ", Color(255, 255, 255), "A function executed from a remote source threw an error.", "\n")
				thrown.ctx.entity:WriteToLogger(Color(0,255, 255), "Thrown error: ", Color(255, 255, 255), thrown.msg, "\n");
				thrown.ctx.entity:WriteToLogger(Color(0,255, 255), "At: ", Color(255, 255, 255), "Line ", thrown.line, " Char ", thrown.char, " ", thrown.instruction);
				thrown.ctx.entity:PrintStackTrace(stackTrace);
				thrown.ctx.entity:FlushLogger();
				thrown.ctx.entity:ShutDown();
			end
		else
			self:WriteToLogger(Color(255,0,0), "Suffered a ", thrown.state, " error:\n")
			self:WriteToLogger("    ", Color(0,255, 255), "Message: ", Color(255, 255, 255), thrown.msg, "\n")
			self:WriteToLogger("    ", Color(0,255, 255), "At: ", Color(255, 255, 255), "Line ", thrown.line, " Char ", thrown.char, " ", thrown.instruction);
			self:FlushLogger()
			self:ShutDown();
		end
	end
end

--[[
	Invoke: postfix your result type with * if you do not need a result, or the result type is irrelivant.
]]

function ENT:Invoke(where, result, count, udf, ...)
	if (self:IsRunning()) then

		local optional = string.sub(result, -1) == "*";

		if (optional) then
			result = string.sub(result, 1, -2);
		end

		if (udf and udf.op) then

			local r = udf.result;
			local c = udf.count;

			if (r == nil or r == "" or c == -1) then
				r, c = "_nil", 0;
			end

			if (r ~= "_nil" and optional) then
				optional = false;
			end

			if (result == nil or result == "" or count == -1) then
				result, count = "_nil", 0;
			end

			if ( (result ~= r or count ~= c) and not optional ) then
				local context = self.context;

				if (udf.scr) then
					context = udf.scr;
				end

				local msg = string.format("Invoked function with incorrect return type %q:%i expected, got %q:%i (%s).", name(result), count, name(r), c, where);

				if context then
					context:Throw(msg);
				else
					self:HandelThrown(msg);
					return false, msg;
				end

			end

			self.context:PreExecute();

			local results = {pcall(udf.op, ...)};

			local status = table.remove(results, 1);

			self.context:PostExecute();

			if (status) then
				self.context.update = true;
			else
				self:HandelThrown(results[1]);
			end

			return status, results;
		end
	end

	return false, "Gate is offline";
end

function ENT:CallEvent(result, count, event, ...)
	if (self:IsRunning()) then
		local events = self.context.events[event];

		if (events) then
			for id, udf in pairs(events) do
				local where = string.format("Event.%s.%s", event, id);
				local status, results = self:Invoke(where, result .. "*", count, udf, ...);

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
	self:NetworkVar("Float", 0, "ServerSoftCPU");
	self:NetworkVar("Float", 0, "ServerAverageCPU");
	self:NetworkVar("Bool", 1, "ServerWarning");
end

if (CLIENT) then
	AccessorFunc(ENT, "cl_soft_cpu", "ClientSoftCPU", FORCE_NUMBER);
	AccessorFunc(ENT, "cl_average_cpu", "ClientAverageCPU", FORCE_NUMBER);
	AccessorFunc(ENT, "cl_cpu_warning", "ClientWarning", FORCE_BOOL);
end

function ENT:UpdateQuotaValues()
	local context = self.context;

	if (context) then

		if (SERVER) then
			self:SetServerSoftCPU(context.cpu_softusage);
			self:SetServerAverageCPU(context.cpu_average);
			self:SetServerWarning(context.cpu_warning);
		end

		if (CLIENT) then
			self:SetClientSoftCPU(context.cpu_softusage);
			self:SetClientAverageCPU(context.cpu_average);
			self:SetClientWarning(context.cpu_warning);
		end

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

--[[
	Network Messages
]]

if SERVER then
	util.AddNetworkString("Expression3.EntMessage");
end

function ENT:SendNetMessage(name, target, ...)

	if CLIENT then
		if IsValid(target) and target == LocalPlayer() then
			self:ReceiveNetMessage(name, target, {...});
		end
	end

	net.Start("Expression3.EntMessage");

	net.WriteEntity(self);

	net.WriteString(name);

	if CLIENT then net.WriteEntity(target); end

	net.WriteTable( {...} );

	local context = EXPR_LIB.GetExecuting();

	if context then
		local usage = context.net_total + net.BytesWritten();

		if usage > context:GetNetQuota() then
			context:Throw("Network que overflow.");
		end

		context.net_total = usage;
	end

	if CLIENT then
		net.SendToServer();
	elseif target then
		net.Send(target);
	else
		net.Broadcast();
	end
end

function ENT:ReceiveNetMessage(name, target, values)
	local cb = self["Net" .. name];

	-- No CB?, Forward this to the cleint for now.
	if not cb then return true; end

	return cb(self, target, values);
end

net.Receive("Expression3.EntMessage", function()
	local entity = net.ReadEntity();

	local name = net.ReadString();

	local target = SERVER and net.ReadEntity() or LocalPlayer();

	local values = net.ReadTable();

	if not IsValid(entity) or not entity.ReceiveNetMessage then return; end

	local sendToClient = entity:ReceiveNetMessage(name, target, values);

	if SERVER and sendToClient then

		net.Start("Expression3.EntMessage");

		net.WriteEntity(self);

		net.WriteString(name);

		net.WriteTable( values );

		net.Send(target);
	end
end);

--[[
	Chat Messages
]]

if SERVER then
	util.AddNetworkString("SendToChat");
	util.AddNetworkString("SendToGolem");
end

EXPR_LIB.RegisterPermission("SendToChat", "fugue/balloon-ellipsis.png", "This gate is allowed to send messages to your chatbox.")
EXPR_LIB.RegisterPermission("SendToGolem", "fugue/terminal--arrow.png", "This gate is allowed to send messages to your Golem console.")

EXPR_PRINT_GOLEM = 0;
EXPR_PRINT_CHAT = 1;

function ENT:SendToOwner( type, ... )
	if type == EXPR_PRINT_CHAT then
		self:SendNetMessage("ChatMessage", self.player, ...);
	else
		self:SendNetMessage("GolemMessage", self.player, ...);
	end
end

function ENT:NetChatMessage(target, values)
	
	if self.getPerm then
		if not self:getPerm(target, "SendToChat") then
			return false;
		end
	end

	if CLIENT then
		chat.AddText( unpack(values) );
	end

	return true;

end


function ENT:NetGolemMessage(target, values)

	if self.getPerm then
		if not self:getPerm(target, "SendToGolem") then
			return false;
		end
	end

	if CLIENT then
		Golem.Print( unpack(values) );
	end

	return true;
end

--[[
	API Call to add additonal methods
]]

hook.Run("Expression3.ExtendBaseEntity", ENT);
