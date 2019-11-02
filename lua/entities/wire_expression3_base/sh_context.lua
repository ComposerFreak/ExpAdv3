--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Context::
]]

AddCSLuaFile();

local CONTEXT = {};

CONTEXT.__index = CONTEXT;

--[[
	Perfomance CVARS
	Based on StarFallEx, all credits for CPU benchmarking goes to origonal authors.
	Who advised that they stle it from Wiremod E2, so the plot thickens!
]]

local cvar_softtime;
local cvar_hardtime;
local cvar_softtimesize;
local cvar_netquota;
local cvar_ram_max;

if SERVER then
	cvar_softtime = CreateConVar("e3_softtime", 0.005, FCVAR_ARCHIVE, "The max average the CPU time e3 can reach.")
	cvar_hardtime = CreateConVar("e3_hardtime", 0.01, FCVAR_ARCHIVE, "The max CPU time e3 can reach.")
	cvar_softtimesize = CreateConVar("e3_timebuffersize", 100, FCVAR_ARCHIVE, "The window width of the CPU time quota moving average.");
	cvar_ram_max = CreateConVar("e3_ram_max", 1500000, "If ram exceeds this limit (in kB), e3s will be terminated");
	cvar_netquota = CreateConVar("e3_netquota", 64000, FCVAR_ARCHIVE, "The max net usage quota in kb.");
end

if CLIENT then
	cvar_softtime = CreateConVar("e3_softtime_cl", 0.005, FCVAR_ARCHIVE, "The max average the CPU time e3 can reach.");
	cvar_hardtime = CreateConVar("e3_hardtime_cl", 0.01, FCVAR_ARCHIVE, "The max CPU time e3 can reach.")
	cvar_softtimesize = CreateConVar("e3_timebuffersize_cl", 100, FCVAR_ARCHIVE, "The window width of the CPU time quota moving average.");
	cvar_ram_max = CreateConVar("e3_ram_max_cl", 1500000, "If ram exceeds this limit (in kB), e3s will be terminated");
	cvar_netquota = CreateConVar("e3_netquota_cl", 64000, FCVAR_ARCHIVE, "The max net usage quota in kb.");
end

--[[
	Create a new context object
]]

function CONTEXT.New()
	local tbl = {};

	tbl.perms = {};
	tbl.net_total = 0;
	tbl.cpu_total = 0;
	tbl.cpu_average = 0;
	tbl.cpu_timestamp = 0;
	tbl.cpu_softusage = 0;
	tbl.cpu_hardusage = 0;
	
	return setmetatable(tbl, CONTEXT);
end

--[[
	CVar acessor methods
]]

function CONTEXT:softTimeLimit()
	return cvar_softtime:GetFloat();
end

function CONTEXT:hardTimeLimit()
	return cvar_hardtime:GetFloat();
end

function CONTEXT:softTimeLimitSize()
	return 1 / cvar_softtimesize:GetInt();
end

function CONTEXT:maxRam()
	return cvar_ram_max:GetInt();
end

function CONTEXT:GetNetQuota()
	return cvar_netquota:GetInt();
end

--[[

]]

local __exe;

function EXPR_LIB.GetExecuting()
	return __exe;
end

--[[
	Error messages and tracing.
]]

function CONTEXT.Trace(this, level, max)
	local stack = {};

	for i = level + 1, level + max do
		local info = debug.getinfo( i, "Sln" );

		if (not info) then
			continue;
		end

		if (info.short_src == "Expression 3") then
			local trace = this:GetScriptPos(info.currentline, 0);

			if (trace) then
				trace.level = #stack + 1;
				stack[trace.level] = trace;
			end
		end
	end

	return stack;
end

function CONTEXT.GetScriptPos(this, line, char)
	for _, a in pairs(this.traceTable) do
		if (a.native_line >= line) then
			return{a.e3_line, a.e3_char, a.instruction};
		end
	end

	return nil;
end

function CONTEXT.Throw(this, msg, fst, ...)
	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	local err = {};
	err.state = "runtime";
	err.char = 0;
	err.line = 0;
	err.msg = msg;
	err.ctx = this;
	err.instruction = "";
	err.stack = this:Trace(1, 15);

	if (err.stack) then
		local trace = err.stack[1];

		if (trace) then
			err.line = trace[1];
			err.char = trace[2];
			err.instruction = trace[3] or "";
		end
	end

	error(err, 0);
end

--[[
	PERMISSIONS:
]]

function CONTEXT:CanUseEntity(entity)
	return self:ppCheck(entity, "Prop-Control");
end

--[[
	Reset quotas and update context.
]]

function CONTEXT:UpdateQuotaValues()
	if (self.status) then

		self.cpu_softusage = self:movingCPUAverage() / self:softTimeLimit();
		self.cpu_hardusage = self.cpu_total / self:hardTimeLimit();
		self.cpu_average = (self.cpu_average * 0.95) + (self.cpu_total * 0.05);

		self.net_total = 0;
		self.cpu_total = 0;

		if (self.update) then
			self.update = false;
			hook.Run("Expression3.Entity.Update", self.entity, self);
		end
	end
end

--[[
	Set up debug hook
]]

local bJit, fdhk, sdhk, ndhk;

function CONTEXT:PreExecute()

	self.cpu_timestamp = SysTime();

	local cpuCheck = function()
		self.cpu_total = SysTime() - self.cpu_timestamp;

		local used_ratio = self:movingCPUAverage() / self:softTimeLimit();

		self.cpu_warning = used_ratio > 0.7;

		if used_ratio > 1 then

			debug.sethook( nil );

			self:Throw( "CPU Soft Quota Exceeded!");

		--[[elseif self.cpu_total >= self:hardTimeLimit() then
			
			debug.sethook( nil );

			self:Throw( "CPU Hard Quota Exceeded!");]]

		end

	end

	__exe = self;

	bJit = jit.status();

	jit.off();

	fdhk, sdhk, ndhk = debug.gethook();

	debug.sethook(cpuCheck, "", 500);
end

--[[

]]

function CONTEXT:PostExecute()
	debug.sethook(fdhk, sdhk, ndhk);
	
	self.cpu_total = SysTime() - self.cpu_timestamp;

	if (bJit) then
		jit.on();
	end

	__exe = nil;
end

--[[
]]

function CONTEXT:movingCPUAverage()
	return self.cpu_average + (self.cpu_total - self.cpu_average) * self:softTimeLimitSize();
end

--[[
	API Call to add additonal methods
]]

hook.Run("Expression3.ExtendContext", CONTEXT);

EXPR_CONTEXT = CONTEXT;
