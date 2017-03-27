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
	New Context
]]

function CONTEXT.New()
	local tbl = {};

	tbl.cpu_total = 0;
	tbl.cpu_average = 0;
	tbl.cpu_samples = {};
	tbl.cpu_warning = false;
	
	return setmetatable(tbl, CONTEXT);
end


--[[
	CPU Benchmarking / Quota
	Measure: 1000th's of a second.
]]

local len = 100;
local soft, hard;

if (SERVER) then
	hard = CreateConVar("e3_hardquota", 500, { FCVAR_REPLICATED }, "Absolute max usage quota per one tick.");
	soft = CreateConVar("e3_softquota", 100, { FCVAR_REPLICATED }, "The max average usage quota.");
	--len = CreateConVar("e3_maxbuffersize", 100, { FCVAR_REPLICATED }, "Window width of the CPU time quota moving average.");
end

if (CLIENT) then
	hard = CreateClientConVar("e3_hardquota", 500, false, false);
	soft = CreateClientConVar("e3_softquota", 100, false, false); 
	--len = CreateClientConVar("e3_maxbuffersize", 100, false, false);
end

function CONTEXT:MaxSampleSize()
	return len; -- len:GetInt();
end

function CONTEXT:GetSoftQuota()
	return soft:GetInt() * 0.0001;
end

function CONTEXT:GetHardQuota()
	return hard:GetInt() * 0.0001;
end

--

function CONTEXT:AddSample(sample)
	local samples, size = self.cpu_samples, #self.cpu_samples
		
	if (size >= self:MaxSampleSize()) then
		for i = 1, size do
			samples[i] = samples[i + 1];
		end -- Move all samples down 1.
	end

	samples[size] = sample;

	return size;
end

function CONTEXT:GetBufferAverage()
	local average = 0;
	local samples = #self.cpu_samples;

	for i = 1, samples do
		average = average + self.cpu_samples[i];
	end

	return average / samples;
end

function CONTEXT:GetBufferVariance(average)
	local average = average or self:GetBufferAverage();

	local sum = 0;
	local samples = #self.cpu_samples;

	for i = 1, samples do
		sum = sum + (self.cpu_samples[i] - average) ^ 2;
	end

	return sum / (samples - 1);
end

--


function CONTEXT:UpdateQuotaValues()
	if (self.status) then

		local average = self:GetBufferAverage()

		local hard = self:GetHardQuota();
		
		if self.cpu_warning then
			if self.cpu_total < hard * 0.75 then
				self.cpu_warning = false;
			end
		end

		self.cpu_total = 0;

		self.cpu_average = average;

		if (self.update) then
			self.update = false;
			hook.Run("Expression3.Entity.Update", self.entity, self);
		end
	end
end

--[[
]]

local bJit, fdhk, sdhk, ndhk;

function CONTEXT:PreExecute()

	local cpuMarker = SysTime();

	-- http://www.usablestats.com/calcs/tinv
	-- Degrees of Freedom = BufferN - 1
	-- One-sided
	-- Proportion of Area = 1 - x where x is a percentage that represents a level of significance. 
	-- A higher significance means it is harder to quota but you are more sure that the limit has been exceeded.
	-- A lower significance means it is easier to quota but you are less sure that the limit has been exceeded.
	-- The default value for x is 0.99
	local criticalValue = 2.3646;

	local cpuCheck = function()
		local dt = SysTime() - cpuMarker;

		local samples = self:AddSample(dt);

		local average = self:GetBufferAverage();

		local variance = self:GetBufferVariance(average);

		local soft = self:GetSoftQuota();

		local hard = self:GetHardQuota();

		local statistic = (average - soft) / math.sqrt(variance / samples);

		self.cpu_total = self.cpu_total + dt;

		if statistic > criticalValue then
			debug.sethook( nil );
			self:Throw( "Soft CPU Quota Exceeded!");
		elseif self.cpu_total > hard then
			debug.sethook( nil );
			self:Throw( "Hard CPU Quota Exceeded!");
		elseif self.cpu_total > hard * 0.75 then
			self.cpu_warning = true;
		end

		cpuMarker = SysTime();
	end

	__exe = self;

	bJit = jit.status();

	jit.off();

	fdhk, sdhk, ndhk = debug.gethook();

	debug.sethook(cpuCheck, "", 500);
end

function CONTEXT:PostExecute()
	debug.sethook(fdhk, sdhk, ndhk);

	if (bJit) then
		jit.on();
	end

	__exe = nil;
end


EXPR_CONTEXT = CONTEXT;