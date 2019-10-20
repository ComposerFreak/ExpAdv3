--[[
	*****************************************************************************************************************************************************
		Add this file to cs lua
	*****************************************************************************************************************************************************
]]--
	if SERVER then
		AddCSLuaFile();
	end

--[[
	*****************************************************************************************************************************************************
		Define the core libraries
	*****************************************************************************************************************************************************
]]--

	local core_files = {
		"expression3/core/void.lua",
		"expression3/core/math.lua",
		"expression3/core/boolean.lua",
		"expression3/core/string.lua",
		"expression3/core/variant.lua",
		"expression3/core/userfunctions.lua",
		"expression3/core/userclasses.lua",
		"expression3/core/error.lua",
		"expression3/core/system.lua",
		"expression3/core/events.lua",
	};

	local path = "expression3/extensions/";
	local extensions = file.Find(path .. "*.lua", "LUA");
	
--[[
	*****************************************************************************************************************************************************
		add client side files
	*****************************************************************************************************************************************************
]]--

	if SERVER then
		for _, filepath in pairs(core_files) do
			AddCSLuaFile(filepath);
		end

		for i, filename in pairs( extensions ) do
			AddCSLuaFile(path .. filename);
		end
	end

--[[
	*****************************************************************************************************************************************************
		load the game
	*****************************************************************************************************************************************************
]]--

hook.Add("Expression3.RegisterExtensions", "Expression3.Core.Extensions", function()
	
	for i, filename in pairs( core_files ) do
		include(filename);
		--print("[E3] Loading core file " .. filename);
	end

	for i, filename in pairs( extensions ) do
		include(path .. filename);
		--print("[E3] Loading file " .. path .. filename);
	end

end);
