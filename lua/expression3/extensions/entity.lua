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

local extension = EXPR_LIB.RegisterExtension("entity")

--[[
	CLASS
]]

extension:RegisterClass("e", {"entity"}, IsEntity, IsValid)

extension:RegisterConstructor("e", "n", Entity, true)

--[[
	Operators
]]

extension:RegisterOperator("==", "e,e", "b", 1, nil)

--[[
	Methods
]]

extension:RegisterMethod("e", "isValid", "", "b", 1, function(e)
	return IsValid(e)
end, true)

extension:RegisterMethod("e", "class", "", "s", 1, "GetClass")

extension:RegisterMethod("e", "getPos", "", "v", 1, "GetPos")
extension:RegisterMethod("e", "setPos", "v", "", 0, "SetPos")

extension:RegisterMethod("e", "getAng", "", "a", 1, "GetAngles")
extension:RegisterMethod("e", "setAng", "a", "", 0, "SetAngles")

extension:RegisterMethod("e", "forward", "", "v", 1, "GetForward")
extension:RegisterMethod("e", "up", "", "v", 1, "GetUp")
extension:RegisterMethod("e", "right", "", "v", 1, "GetRight")

extension:RegisterMethod("e", "getVel", "", "v", 1, "GetVelocity")
extension:RegisterMethod("e", "setVel", "v", "", 0, "SetVelocity")

extension:RegisterMethod("e", "getMaterial", "", "s", 1, "GetMaterial")
extension:RegisterMethod("e", "setMaterial", "s", "", 0, "SetMaterial")

extension:RegisterMethod("e", "getSubMaterial", "n", "s", 1, "GetSubMaterial")
extension:RegisterMethod("e", "setSubMaterial", "n,s", "", 0, "SetSubMaterial")
extension:RegisterMethod("e", "resetSubMaterials", "", "", 0, "SetSubMaterial")

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

extension:EnableExtension()