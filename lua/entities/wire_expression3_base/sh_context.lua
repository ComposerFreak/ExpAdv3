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
	Error messages and tracing.
]]

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

local soft, hard, len;

if (SERVER) then
	soft = CreateConVar("e3_hardquota", 120, { FCVAR_REPLICATED }, "Absolute max usage quota per one tick.");
	hard = CreateConVar("e3_softquota", 100, { FCVAR_REPLICATED }, "The max average usage quota.");
	len = CreateConVar("e3_maxbuffersize", 100, { FCVAR_REPLICATED }, "Window width of the CPU time quota moving average.");
end

if (CLIENT) then
	soft = CreateClientConVar("e3_hardquota", 120, false, false);
	hard = CreateClientConVar("e3_softquota", 100, false, false); 
	len = CreateClientConVar("e3_maxbuffersize", 100, false, false);
end

function CONTEXT:MaxSampleSize()
	return len:GetInt() or 3;
end

function CONTEXT:GetSoftQuota()
	return soft:GetInt() * 0.0001;
end

function CONTEXT:GetHardQuota()
	return hard:GetInt() * 0.0001;
end

--

function CONTEXT:UpdateQuotaValues()
	if (self.status) then
		self.cpu_average = (self.cpu_average * 0.95) + (self.cpu_total * 0.05);

		local samples, size = self.cpu_samples, #self.cpu_samples
		
		if (size >= self:MaxSampleSize()) then
			for i = 1, size do
				samples[i] = samples[i + 1];
			end -- Move all samples down 1.
		end

		samples[size] = self.cpu_average;

		-- TODO: Perform test on samples?

		self.cpu_total = 0;
		self.cpu_warning = false;
	end

	if (r and self.update) then
		self.context.update = false;
		hook.Run("Expression3.Entity.Update", self, context);
	end
end

--[[
]]

local bJit, fdhk, sdhk, ndhk;

function CONTEXT:PreExecute()
	local cpuMarker = SysTime() - self.cpu_total;

	local cpuCheck = function()
		self.cpu_total = SysTime() - cpuMarker;

		local usage = self:GetHardtQuota() / self.cpu_total;

		if (usage > 1) then
			debug.sethook(nil);
			self:Throw("CPU Quota exceeded");
		elseif (usage > self:GetsoftQuota()) then
			self.cpu_warning = true;
		else
			self.cpu_warning = false;
		end
	end

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
end


EXPR_CONTEXT = CONTEXT;