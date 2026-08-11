--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Timers/Time::
]]

local max_timers;

if SERVER then
	local cvar = CreateConVar("e3_max_timers", 100, FCVAR_ARCHIVE, "The max number of timers per e3 gate.");
	local function update() max_timers = cvar:GetInt(); end
	timer.Create("e3_timer_cvars", 1, 0, update);
	update();
end

if CLIENT then
	local cvar = CreateConVar("e3_max_timers_cl", 100, FCVAR_ARCHIVE, "The max number of timers per e3 gate.");
	local function update() max_timers = cvar:GetInt(); end
	timer.Create("e3_timer_cvars", 1, 0, update);
	update();
end

--[[

]]


hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Timers", function(entity, ctx, env)
	ctx.data.timers = {};
	ctx.data.timer_count = 0;
end);

local extension = EXPR_LIB.RegisterExtension("timers");

extension:RegisterLibrary("timer");

extension:RegisterFunction("timer", "simple", "n,f,...", "", 0, function(ctx, d, f, ...)
	
	local timers = ctx.data.timers;
	local count = ctx.data.timer_count;

	if (count > max_timers) then
		ctx:Throw("Maximum number of timers reached.");
	end

	timers[#timers + 1] = {
		delay = d;
		next = CurTime() + d;
		paused = false;
		reps = 1;
		count = 0;
		func = f;
		values = {...};
		simple = true;
	};

	ctx.data.timer_count = count + 1;
end, false);

extension:RegisterFunction("timer", "create", "s,n,n,f,...", "", 0, function(ctx, n, d, r, f, ...)
	local timers = ctx.data.timers;
	local count = ctx.data.timer_count;

	if (count > max_timers) then
		ctx:Throw("Maximum number of timers reached.");
	end

	timers[n] = {
		delay = d;
		next = CurTime() + d;
		paused = false;
		reps = r;
		count = 0;
		func = f;
		values = {...};
	};

	ctx.data.timer_count = count + 1;

end, false);

extension:RegisterFunction("timer", "exists", "s", "b", 1, function(ctx, name)
	local timers = ctx.data.timers;
	return timers[name] != nil;
end, false);

extension:RegisterFunction("timer", "remove", "s", "", 0, function(ctx, name)
	local timers = ctx.data.timers;

	if (timer[name]) then
		timers[name] = nil;
		ctx.data.timer_count = ctx.data.timer_count - 1;
	end
end, false);

extension:RegisterFunction("timer", "pause", "s", "", 0, function(ctx, name)
	local timers = ctx.data.timers;

	if (timers[name]) then
		timers[name].paused = true;
	end
end, false);

extension:RegisterFunction("timer", "resume", "s", "", 0, function(ctx, name)
	local timers = ctx.data.timers;

	if (timers[name]) then
		timers[name].paused = false;
	end
end, false);

hook.Add( "Think", "Expression3.Timers.Run", function( )
	local now = CurTime();

	for _, ctx in pairs(EXPR_LIB.GetAll()) do
		if (IsValid(ctx.entity)) then
			local timers = ctx.data.timers;
			local count = ctx.data.timer_count;

			if (timers) then
				local i = 0;
				for k, timer in pairs(timers) do

					i = i + 1; -- Limit the amount we do in one think.

					if (i > max_timers) then break; end

					if (not timer.paused and now >= timer.next) then
						timer.next = now + timer.delay;

						if (timer.reps > 0) then
							timer.count = timer.count + 1;

							if (timer.count >= timer.reps) then
								timers[k] = nil;
								count = count - 1;
							end
						end

						if (timer.simple) then
							timers[k] = nil;
							count = count - 1;
						end

						local where = "timer." .. k;
						ctx.entity:Invoke(where, "", 0, timer.func, unpack(timer.values));
					end
				end
			end

			ctx.data.timer_count = count;
		end
	end

end);


extension:EnableExtension();
