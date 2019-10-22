--[[
	*****************************************************************************************************************************************************
		create a new extention
	*****************************************************************************************************************************************************
]]--
	
	local extension = EXPR_LIB.RegisterExtension("variant");

--[[
	*****************************************************************************************************************************************************
		register variant or object class
	*****************************************************************************************************************************************************
]]--
	
	local class_object = extension:RegisterClass("vr", {"variant", "object"}, istable, EXPR_LIB.NOTNIL);

--[[
	*****************************************************************************************************************************************************
		When all classes have loaded, register the casting operations.
	*****************************************************************************************************************************************************
]]--

	function extension.PostLoadClasses(this, classes)

		for _, c in pairs(classes) do
			local id = c.id;

			if (id ~= "_vr" and id ~= "") then
				extension:RegisterCastingOperator("vr", id, function(ctx, obj)
					return {id, obj};
				end);

				extension:RegisterCastingOperator(id, "vr", function(ctx, vr)
					if (not vr or not vr[1] or vr[2] == nil) then
						ctx:Throw("attempt to cast variant of type nil to " .. c.name);
					end

					if (vr[1] ~= id) then
						ctx:Throw("attempt to cast variant of type " .. vr[1] .. " to " .. c.name);
					end

					return vr[2];
				end);
			end
		end

	end

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();











