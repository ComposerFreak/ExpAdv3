--[[
		 ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
		F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Wire Links::
	`````````````````
]]

local ext_wl = EXPR_LIB.RegisterExtension("wirelinks");
local class_wl = ext_wl:RegisterClass("wl", "wirelink", isentity, IsValid);

ext_wl:RegisterOperator("neq", "wl,wl", "b", 1);
ext_wl:RegisterOperator( "eq", "wl,wl", "b", 1);

ext_wl:RegisterWiredInport("wl", "WIRELINK");
ext_wl:RegisterWiredOutport("wl", "WIRELINK");

ext_wl:RegisterCastingOperator("e", "wl", function(e) return e; end, true);

ext_wl:RegisterCastingOperator("wl", "e", function(context, e)
	if context:CanUseEntity(e) then return e; end
	context:Throw("Unable to cast entity to wirelink.");
end, false);

--[[
	Basic Methods
]]

ext_wl:RegisterMethod("e", "getWirelink", "", "wl", 1, function(context, e)
	if context:CanUseEntity(e) then return e; end
	context:Throw("Unable to get wirelink from entity.");
end, false);

ext_wl:RegisterMethod("wl", "hasInput", "s", "b", 1, function(e, i)
	return IsValid( e ) and e.Inputs and e.Inputs[i];
end, true);

ext_wl:RegisterMethod("wl", "hasOutput", "s", "b", 1, function(e, i)
	return IsValid( e ) and e.Outputs and e.Outputs[i];
end, true);

ext_wl:RegisterMethod("wl", "isHighSpeed", "", "b", 1, function(e)
	return IsValid( e ) and (e.WriteCell or e.ReadCell);
end, true);

ext_wl:RegisterMethod("wl", "inputType", "s", "s", 1, function(e, i)
	if IsValid(e) and e.Inputs and e.Inputs[i] then
			return e.Inputs[i].Type or "";
	end
	return "";
end, false);

ext_wl:RegisterMethod("wl", "outputType", "s", "s", 1, function(e, i)
	if IsValid(e) and e.Outputs and e.Outputs[i] then
			return e.Outputs[i].Type or "";
	end
	return "";
end, false);

--[[----------------------------------------------------------------
	Ok, lets do wire link properly this time.
------------------------------------------------------------------]]
local TriggerInput = WireLib.TriggerInput;
local IsValid = IsValid;
local insert = table.insert;
local pairs = pairs;

local wirelinkGetOperator = function(class)
	return function(context, ent, index)
		if not IsValid(ent) or not ent.Outputs then
			context:Throw("Attempted to read Output %s from invalid wirelink.", index);
		end

		local port = ent.Outputs[index];
		if not port or port.Type ~= class.wire_in_class then
			context:Throw("No such Output WireLink[%q, %s].", index, class.name);
		end

		local value = port.Value;
		if value == nil and class.native_default_func then return class.native_default_func(); end
		if value ~= null and class.wire_out_func then return class.wire_out_func(value); end
		return value;
	end
end

local wirelinkSetOperator = function(class)
	return function(context, ent, index, value, bnow)
		if not IsValid(ent) or not ent.Inputs then
			context:Throw("Attempted to write to Input %s on invalid wirelink.", index);
		end

		local port = ent.Inputs[index];
		if not port or port.Type ~= class.wire_in_class then
			context:Throw("No such Input WireLink[%q, %s].", index, class.name);
		end

		if not context.data.wirelinks then context.data.wirelinks = { queue = {} }; end

		local wirelinks = context.data.wirelinks[ent];
		if not wirelinks then wirelinks = { }; context.data.wirelinks[ent] = wirelinks; insert(context.data.wirelinks.queue, ent); end
		if class.wire_in_func then value = class.wire_in_func(value); end
		if bnow ~= true then wirelinks[index] = value; else TriggerInput(ent, index, value); end
	end
end

local wirelinkReadInputOperator = function(class)
	return function(context, ent, index)
		if not IsValid(ent) or not ent.Inputs then
			context:Throw("Attempted to read Input %s from invalid wirelink.", index);
		end

		local port = ent.Inputs[index];
		if not port or port.Type ~= class.wire_in_class then
			context:Throw("No such Input WireLink[%q, %s].", index, class.name);
		end

		local value = port.Value;
		if value == nil and class.native_default_func then return class.native_default_func(); end
		if value ~= null and class.wire_out_func then return class.wire_out_func(value); end
		return value;
	end
end

local triggerWirelinkQueue = function(gate, context)
	local wirelinks = context.data.wirelinks;
	if not wirelinks then return; end

	local queue = wirelinks.queue;
	if not queue then return; end

	for i = 1, #queue do
		local ent = queue[i];
		if IsValid(ent) then 
			for k, v in pairs(wirelinks[ent] or {}) do
				TriggerInput(ent, k, v);
			end
		end
	end
end

--hook.Add("Expression3.Start.Entity", "Expression3.Wirelink", function(entity, context)
--	context.data.wirelinks = { queue = { } };
--end); -- Add a wirelink data table to the entity.

hook.Add("Expression3.Entity.Update", "Expression3.Wirelink", triggerWirelinkQueue);

function ext_wl:PostLoadClasses(classes)
	for _, class in pairs(classes) do
		local gop = wirelinkGetOperator(class);
		local sop = wirelinkSetOperator(class);
		local pname = string.upper(class.name[1]) .. string.sub(class.name, 2);
		if (class.wire_in_class) then ext_wl:RegisterOperator("get", "wl,s,"..class.id, class.id, 1, gop, false); end
		if (class.wire_out_class) then ext_wl:RegisterOperator("set", "wl,s,"..class.id, "", 0, sop, false); end
		if (class.wire_out_class) then ext_wl:RegisterMethod("wl", "writeToInput", "s,"..class.id, "", 0, sop, false); end
		if (class.wire_out_class) then ext_wl:RegisterMethod("wl", "writeToInput", "s,"..class.id..",b", "", 0, sop, false); end
		if (class.wire_in_class) then ext_wl:RegisterMethod("wl", "read" .. pname .. "FromInput", "s", class.id, 1, wirelinkReadInputOperator(class), false); end
		if (class.wire_in_class) then ext_wl:RegisterMethod("wl", "read" .. pname .. "FromOutput", "s", class.id, 1, gop, false); end
	end
end

--[[
To do HighSpeed functions :D
]]

ext_wl:EnableExtension();
