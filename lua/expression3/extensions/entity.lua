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

extension:RegisterLibrary("entlib");

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

extension:RegisterOperator("eq", "e,p", "b", 1, function(a, b) return a == b end, true)
extension:RegisterOperator("neq", "e,p", "b", 1, function(a, b) return a != b end, true)

-- Entity <- Player
extension:RegisterCastingOperator("e", "p", function(ctx, obj)
	if (not IsValid(obj) and obj:IsPlayer()) then
		return obj
	end

	ctx:Throw("Attempted to cast none player entity to player.")
end, false)

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
extension:RegisterMethod("e", "getModel", "", "n", 0, "GetModel")

--[[
]]

extension:RegisterMethod("e", "getPos", "", "v", 1, "GetPos")

extension:RegisterMethod("e", "setPos", "v", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetPos(v)
	end
end, false)

--[[
]]

extension:RegisterMethod("e", "getAng", "", "a", 1, "GetAngles")

extension:SetServerState()
extension:RegisterMethod("e", "setAng", "a", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetAngles(v)
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "forward", "", "v", 1, "GetForward")
extension:RegisterMethod("e", "up", "", "v", 1, "GetUp")
extension:RegisterMethod("e", "right", "", "v", 1, "GetRight")

extension:RegisterMethod("e", "toWorld", "v", "v", 1, "LocalToWorld")
extension:RegisterMethod("e", "toWorld", "a", "a", 1, "LocalToWorldAngles")
extension:RegisterMethod("e", "toLocal", "v", "v", 1, "WorldToLocal")
extension:RegisterMethod("e", "toLocal", "a", "a", 1, "WorldToLocalAngles")

--[[
]]

extension:RegisterMethod("e", "getVel", "", "v", 1, "GetVelocity")

extension:SetServerState()
extension:RegisterMethod("e", "setVel", "v", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetVelocity(v)
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "getMaterial", "", "s", 1, "GetMaterial")

extension:SetServerState()
extension:RegisterMethod("e", "setMaterial", "s", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetMaterial(v)
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "getSubMaterial", "n", "s", 1, "GetSubMaterial")

extension:SetServerState()
extension:RegisterMethod("e", "setSubMaterial", "n,s", "", 0, function(context,e,n,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetSubMaterial(n,v)
	end
end, false)

extension:RegisterMethod("e", "resetSubMaterials", "", "", 0, function(context,e)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetSubMaterial()
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "getColor", "", "c", 1, function(e)
	if IsValid(e) then
		return e:GetColor()
	end
	
	return Color(0, 0, 0)
end, true)

extension:SetServerState()
extension:RegisterMethod("e", "setColor", "c", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetColor(v)
		e:SetRenderMode(v.a == 255 and 0 or 4 )
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "getGravity", "", "n", 1, "GetGravity")

extension:SetServerState()
extension:RegisterMethod("e", "setGravity", "n", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:SetGravity(v)
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "isOnFire", "", "b", 1, "IsOnFire")

extension:SetServerState()
extension:RegisterMethod("e", "ignite", "n", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:Ignite(v)
	end
end, false)

extension:RegisterMethod("e", "extinguish", "", "", 0, function(context,e)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:Extinguish()
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "onGround", "", "b", 1, "OnGround")
extension:RegisterMethod("e", "getGroundEntity", "", "e", 1, "GetGroundEntity")

--[[
]]

extension:RegisterMethod("e", "owner", "", "p", 1, "CPPIGetOwner")

extension:SetServerState()
extension:RegisterMethod("e", "remove", "", "", 0, function(context,e)
	if e:CPPICanTool(context.player, "wire_expression3") then
		e:Remove()
	end
end, false)
extension:SetSharedState()

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
]]

extension:SetServerState()
extension:RegisterMethod("e", "applyForce", "v", "", 0, function(context,e,v)
	if e:CPPICanTool(context.player, "wire_expression3") then
		local phys = e:GetPhysicsObject()
		
		if IsValid(phys) then
			e:ApplyForceCenter(v)
		end
	end
end, false)

extension:RegisterMethod("e", "applyOffsetForce", "v", "", 0, function(context,e)
	if e:CPPICanTool(context.player, "wire_expression3") then
		local phys = e:GetPhysicsObject()
		
		if IsValid(phys) then
			e:ApplyForceOffset(v)
		end
	end
end, false)
extension:SetSharedState()

--[[
]]

extension:RegisterMethod("e", "eyePos", "", "v", 2, "EyePos")
extension:RegisterMethod("e", "eyeAngles", "", "a", 1, "EyeAngles")

--[[
	Functions
]]

extension:RegisterFunction("entlib", "chip", "", "e", 1, function(context) return context.entity end, false)

--[[
]]

extension:EnableExtenstion()