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

]]


local band = bit.band;
local SysTime = SysTime;

--[[
	Perfomance CVARS
	Based on StarFallEx, all credits for CPU benchmarking goes to origonal authors.
	Who advised that they stle it from Wiremod E2, so the plot thickens!
]]

local softtime;
local hardtime;
local hardlimit;
local softtimesize;
local netquota;
--[[

]]

if SERVER then
	local cvar_softtime = CreateConVar("e3_softtime", 0.05, FCVAR_ARCHIVE, "The max average the CPU time e3 can reach.");
	local cvar_hardtime = CreateConVar("e3_hardtime", 0.0001, FCVAR_ARCHIVE, "The max CPU time e3 can use per tick.");
	local cvar_softtimesize = CreateConVar("e3_timebuffersize", 100, FCVAR_ARCHIVE, "The window width of the CPU time quota moving average.");
	local cvar_netquota = CreateConVar("e3_netquota", 64000, FCVAR_ARCHIVE, "The max net usage quota in kb.");
	local cvar_hardlimit = CreateConVar("e3_hardlimit", 64000, FCVAR_ARCHIVE, "The max cost a tick.");

	local update = function()
		softtime = cvar_hardlimit:GetFloat();
		softtime = cvar_softtime:GetFloat();
		hardtime = cvar_hardtime:GetFloat();
		hardlimit = cvar_hardlimit:GetFloat();
		softtimesize = 1 / cvar_softtimesize:GetInt();
		netquota = cvar_netquota:GetInt();
	end

	timer.Create("e3_quota_cvars", 1, 0, update);

	update();

end

--[[

]]

if CLIENT then
	local cvar_softtime = CreateConVar("e3_softtime_cl", 0.05, FCVAR_ARCHIVE, "The max average the CPU time e3 can reach.");
	local cvar_hardtime = CreateConVar("e3_hardtime_cl", 0.0001, FCVAR_ARCHIVE, "The max CPU time e3 can use per tick.");
	local cvar_softtimesize = CreateConVar("e3_timebuffersize_cl", 100, FCVAR_ARCHIVE, "The window width of the CPU time quota moving average.");
	local cvar_netquota = CreateConVar("e3_netquota_cl", 64000, FCVAR_ARCHIVE, "The max net usage quota in kb.");
	local cvar_hardlimit = CreateConVar("e3_hardlimit_cl", 64000, FCVAR_ARCHIVE, "The max cost a tick.");

	local update = function()
		softtime = cvar_hardlimit:GetFloat();
		softtime = cvar_softtime:GetFloat();
		hardtime = cvar_hardtime:GetFloat();
		hardlimit = cvar_hardlimit:GetFloat();
		softtimesize = 1 / cvar_softtimesize:GetInt();
		netquota = cvar_netquota:GetInt();
	end

	timer.Create("e3_quota_cvars", 1, 0, update);

	update();
end

--[[
	Create a new context object
]]

function CONTEXT.New()
	local tbl = {};

	tbl.perms = {};
	tbl.net_total = 0;
	tbl.prf_total = 0;
	tbl.cpu_total = 0;
	tbl.cpu_average = 0;
	tbl.cpu_timestamp = 0;
	tbl.cpu_softusage = 0;
	tbl.cpu_hardusage = 0;
	tbl.cpu_check_tick = 0;
	tbl.cpu_deadline = 0;
	
	return setmetatable(tbl, CONTEXT);
end

--[[
	Placeholder: Overriden by runtime
]]

function CONTEXT:UpdateInternals() 

end

--[[
	CVar acessor methods
]]

function CONTEXT:hardLimit()
	return hardlimit;
end

function CONTEXT:softTimeLimit()
	return softtime;
end

function CONTEXT:hardTimeLimit()
	return hardtime;
end

function CONTEXT:softTimeLimitSize()
	return softtimesize;
end

function CONTEXT:GetNetQuota()
	return netquota;
end

--[[

]]

local throwQuota = function(ctx, msg)
	local line, char, inst = 0, 0, "";
	local trace = ctx:Trace(0, 10);
	if trace and #trace > 0 then line, char, inst = trace[1][1], trace[1][2], trace[1][3] or ""; end
	error({msg = msg, ctx = ctx, quota = true, line = line, char = char, instruction = inst}, 0);
end

function CONTEXT:CheckPrice(price, limit)
	self.prf_total = self.prf_total + price;

	if self.prf_total > (limit or hardlimit) then
		throwQuota(self, "Hard execution limit reached.");
	end

	local tick = self.cpu_check_tick + 1;

	self.cpu_check_tick = tick;

	if band(tick, 1023) == 0 and SysTime() > self.cpu_deadline then
		throwQuota(self, "CPU time quota exceeded.");
	end

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
	return self:ppCheck(entity, "PropControl");
end

--[[
	Reset quotas and update context.
]]

function CONTEXT:UpdateQuotaValues()
	if (self.status) then

		self.cpu_softusage = self:movingCPUAverage() / softtime;
		
		self.cpu_average = (self.cpu_average * 0.95) + (self.cpu_total * 0.05);

		self.net_total = 0;
		self.cpu_total = 0;
		self.prf_total = 0;

		if (self.update) then
			self.update = false;
			hook.Run("Expression3.Entity.Update", self.entity, self);
		end
	end
end

--[[
	Set up debug hook
]]

function CONTEXT:PreExecute()

	if (self.needsInternalUpdate) then
		self:UpdateInternals();
	end

	self.cpu_check_tick = 0;

	self.cpu_timestamp = SysTime();

	self.cpu_deadline = self.cpu_timestamp + hardtime;

	__exe = self;
end

--[[

]]

function CONTEXT:PostExecute()
	
	self.cpu_total = self.cpu_total + (SysTime() - self.cpu_timestamp);

	__exe = nil;
end

--[[
]]

function CONTEXT:movingCPUAverage()
	return self.cpu_average + (self.cpu_total - self.cpu_average) * softtimesize;
end

--[[
	API Call to add additonal methods
]]

hook.Run("Expression3.ExtendContext", CONTEXT);

EXPR_CONTEXT = CONTEXT;
