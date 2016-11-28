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
	tbl.cpu_softquota = 1;
	tbl.cpu_warning = false;
	
	return setmetatable(tbl, CONTEXT);
end


--[[
	CPU Benchmarking / Quota
]]

local maxBufferSize = CreateConVar("e3_maxbuffersize", 100, { FCVAR_REPLICATED }, "Window width of the CPU time quota moving average.");
local maxAverageCPU

if (SERVER) then
	maxAverageCPU = CreateConVar("e3_maxaveragecpu", 0.004, {}, "Max average CPU time for serverside.");
else
	maxAverageCPU = CreateClientConVar("e3_maxaveragecpu", 0.015, false, false);
end

function CONTEXT:MaxBufferSize()
	return maxBufferSize:GetInt() or 3;
end

function CONTEXT:MaxCPUAverage()
	return maxAverageCPU:GetFloat();
end

function CONTEXT:movingCPUAverage()
	local size = self:MaxBufferSize();
	return (self.cpu_average * (size - 1) + self.cpu_total) / size;
end

--[[
]]

function CONTEXT:PreExecute()
	local cpuMarker = SysTime() - self.cpu_total;

	local cpuCheck = function()
		self.cpu_total = SysTime() - cpuMarker;

		local usage = self:movingCPUAverage() / self:MaxCPUAverage();

		if (usage > 1) then
			debug.sethook(nil);
			self:Throw("CPU Quota exceeded");
		elseif (usage > self.cpu_softquota) then
			self.cpu_warning = true;
		else
			self.cpu_warning = false;
		end
	end

	debug.sethook(cpuCheck, "", 500);
end

function CONTEXT:PostExecute()
	debug.sethook(nil);
end


EXPR_CONTEXT = CONTEXT;