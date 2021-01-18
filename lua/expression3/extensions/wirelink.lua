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

--[[
	Basic Methods
]]

ext_wl:RegisterMethod("e", "getWirelink", "", "wl", 1, function(context, e)
	if context:CanUseEntity(e) then return e; end
	context:Throw("Unable to cast entity to wirelink.");
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

--[[
	Basic IO using get / set
]]

function ext_wl:PostLoadClasses(classes)

	for _, class in pairs(classes) do
		
		local id = class.id;

		if (class.wire_in_class) then
			ext_wl:RegisterOperator("get", string.format("wl,s,%s", id), id, 1,function(c, e, i)

				if IsValid(e) and e.Outputs then
					local port = e.Outputs[i];

					if port and port.Type == class.wire_in_class then
						local v = port.Value;
	
						if class.wire_out_func then
							v = class.wire_out_func(v);
						end
						
						return v;
					end

					if class.native_default_func then
						return class.native_default_func();
					end

					c:Throw("No such Output WireLink[%s, %s].", i, id);
				end

				c:Throw("Attempted to read Output %s from invalid wirelink.", i);

			end, false);
		end

		if (class.wire_out_class) then
			
			ext_wl:RegisterOperator("set", string.format("wl,s,%s", id), "", 0, function(c, e, i, v)

				if IsValid(e) and e.Outputs then
					local port = e.Outputs[i];

					if port and port.Type == class.wire_in_class then

						if class.wire_in_func then
							v = class.wire_in_func(v);
						end

						WireLib.TriggerInput(e, i, v);
					end
				
					--c:Throw("No such Input WireLink[%s, %s].", i, c.id);
				end

			end, false);
		end
	end
end

--[[
To do HighSpeed functions :D
]]

ext_wl:EnableExtension();
