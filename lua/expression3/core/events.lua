--[[
	*****************************************************************************************************************************************************
		create a new extention
	*****************************************************************************************************************************************************
]]--
	
	local extension = EXPR_LIB.RegisterExtension("events");

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--
	
	-- When calling this you must always make your varargs into variants e.g "examp" -> {"s", "examp"}
	
	local function event_call(result, count, name, ...)
		for _, context in pairs(EXPR_LIB.GetAll()) do
			if (IsValid(context.entity)) then
				context.entity:CallEvent(result, count, name, ...);
			end
		end
	end;

	EXPR_LIB.CallEvent = event_call;

--[[
	*****************************************************************************************************************************************************
		Default events
	*****************************************************************************************************************************************************
]]--

	hook.Add("Think", "Expression3.Event", function()
		EXPR_LIB.CallEvent("", 0, "Think");
	end);

--[[
	*****************************************************************************************************************************************************
		Results to table
	*****************************************************************************************************************************************************
]]--

	local function resultsToTable(status, class, results)
		local t = {{"b", status}};
		for i = 1, #results do t[i + 1] = {class, results[i]} end
		return {tbl = t, children = {}, parents = {}, size = #t};
	end

--[[
	*****************************************************************************************************************************************************
		event library
	*****************************************************************************************************************************************************
]]--

	extension:RegisterLibrary("event");
	
	extension:RegisterFunction("event", "add", "s,s,f", "", 0, function(context, event, id, udf)
		local events = context.events[event];

		if (not events) then
			events = {};
			context.events[event] = events;
		end

		events[id] = udf;
	end);

	extension:RegisterFunction("event", "remove", "s,s", "", 0, function(context, event, id)
		local events = context.events[event];

		if (not events) then
			return;
		end

		events[id] = nil;
	end);

	extension:RegisterFunction("event", "call", "s,...", "b", 1, function(context, event, ...)
		local status = context.ent:CallEvent("", 0, event, ...);
		return status;
	end);

	extension:RegisterFunction("event", "call", "cls,n,s,...", "t", 1, function(context, class, count, event, ...)
		local status, results = context.ent:CallEvent(class, count, event, ...);
		return resultsToTable(status, class, results);
	end);

	extension:RegisterFunction("event", "call", "e,s,...", "b", 1, function(context, entity, event, ...)
		if (not IsValid(entity) or not entity.Expression3) then return end
		if not context:CanUseEntity(entity) then return end
		local status = entity:CallEvent("", 0, event, ...);
		return status;
	end);

	extension:RegisterFunction("event", "call", "cls,n,e,s,...", "", 0, function(context, class, count, entity, event, ...)
		if (not IsValid(entity) or not entity.Expression3) then return end
		if not context:CanUseEntity(entity) then return end
		local status, results = entity:CallEvent(class, count, event, ...);
		return resultsToTable(status, class, results);
	end);

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

	extension:RegisterEvent("Trigger", "s", "", 0, "Called when a wire input is triggered,");
	extension:RegisterEvent("UseScreen", "n,n,p,e", "", 0);
	extension:RegisterEvent("RenderScreen", "n,n,e", "", 0);
	extension:RegisterEvent("RenderHUD", "n,n", "", 0);
	extension:RegisterEvent("Think", "", "", 0, "Called every interval.");
	extension:RegisterEvent("OnPlayerChat","p,s,n", "", 0);
	extension:RegisterEvent("OnPlayerSpawn", "p", "", 0);
	extension:RegisterEvent("OnPlayerJoin", "p", "", 0);
	extension:RegisterEvent("OnPlayerDisconnect", "p", "", 0);
	extension:RegisterEvent("OnPlayerDeath", "p,e,e", "", 0);
	extension:RegisterEvent("InitializedClient", "p", "", 0, "Called once a client has initalized this script.");
	extension:RegisterEvent("ShutDown", "", "", 0, "Called before the gate is removed or reset.");
--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();











