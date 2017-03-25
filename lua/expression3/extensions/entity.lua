--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Entity Extension::
]]

local extension = EXPR_LIB.RegisterExtenstion("entity")

extension:RegisterLibrary("ent");

--[[
	CLASS
]]

function isEnt(e)
	return IsEntity(e) and not e:IsPlayer()
end

extension:RegisterClass("e", {"entity"}, isEnt, IsValid)

extension:RegisterConstructor("e", "n", Entity, true)

extension:RegisterWiredInport("e", "ENTITY")

extension:RegisterWiredOutport("e", "ENTITY")

--[[
	Operators
]]

extension:RegisterOperator("eq", "e,e", "b", 1, function(a, b) return a == b end, true)
extension:RegisterOperator("neq", "e,e", "b", 1, function(a, b) return a != b end, true)

--[[
	Methods
]]

extension:RegisterMethod("e", "isValid", "", "b", 1, function(e)
	return IsValid(e)
end, true)

--[[
]]

extension:RegisterMethod("e", "class", "", "s", 1, "GetClass")
extension:RegisterMethod("e", "id", "", "n", 0, "EntIndex")

--[[
]]

extension:RegisterMethod("e", "getPos", "", "v", 1, "GetPos")

extension:RegisterMethod("e", "setPos", "v", "", 0, function(context,e,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetPos(v)
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "getAng", "", "a", 1, "GetAngles")

extension:RegisterMethod("e", "setAng", "a", "", 0, function(context,e,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetAngles(v)
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "forward", "", "v", 1, "GetForward")
extension:RegisterMethod("e", "up", "", "v", 1, "GetUp")
extension:RegisterMethod("e", "right", "", "v", 1, "GetRight")

--[[
]]

extension:RegisterMethod("e", "getVel", "", "v", 1, "GetVelocity")

extension:RegisterMethod("e", "setVel", "v", "", 0, function(context,e,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetVelocity(v)
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "getMaterial", "", "s", 1, "GetMaterial")

extension:RegisterMethod("e", "setMaterial", "s", "", 0, function(context,e,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetMaterial(v)
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "getSubMaterial", "n", "s", 1, "GetSubMaterial")

extension:RegisterMethod("e", "setSubMaterial", "n,s", "", 0, function(context,e,n,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetSubMaterial(n,v)
	end
end, false)

extension:RegisterMethod("e", "resetSubMaterials", "", "", 0, function(context,e)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetSubMaterial()
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "getColor", "", "c", 1, "GetColor")

extension:RegisterMethod("e", "setColor", "c", "", 0, function(context,e,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetColor(v)
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "getGravity", "", "n", 1, "GetGravity")

extension:RegisterMethod("e", "setGravity", "n", "", 0, function(context,e,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:SetGravity(v)
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "isOnFire", "", "b", 1, "IsOnFire")

extension:RegisterMethod("e", "ignite", "n", "", 0, function(context,e,v)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:Ignite(v)
	end
end, false)

extension:RegisterMethod("e", "extinguish", "", "", 0, function(context,e)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:Extinguish()
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "onGround", "", "b", 1, "OnGround")
extension:RegisterMethod("e", "getGroundEntity", "", "e", 1, "GetGroundEntity")

--[[
]]

extension:RegisterMethod("e", "owner", "", "p", 1, "CPPIGetOwner")

extension:RegisterMethod("e", "remove", "", "", 0, function(context,e)
	if context.player:CPPICanTool(e, "wire_expression3") then
		e:Remove()
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "getMass", "", "n", 1, function(e)
	local phys = e:GetPhysicsObject()
	return IsValid(phys) and phys:GetMass() or -1
end, true)

extension:RegisterMethod("e", "getMassCenter", "", "v", 1, function(e)
	local phys = e:GetPhysicsObject()
	return IsValid(phys) and phys:GetMassCenter() or Vector()
end, true)

--[[
	Functions
]]

extension:RegisterFunction("ent", "chip", "", "e", 1, function(context) return context.entity end, false)

extension:RegisterMethod("p", "eyePos", "", "v", 2, EyePos)

extension:RegisterMethod("p", "eyeAngles", "", "a", 1, EyeAngles)

--[[
]]

extension:EnableExtenstion()