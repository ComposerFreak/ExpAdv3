--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Expression 3 CPPI::

	E3 Will require CPPI interface for the entity,
	if it doesnt exist it needs to fake one.
]]

AddCSLuaFile();

--[[
]]

if (not CPPI) then
	function ENT:CPPIGetOwner()
		return self:GetCreator();
	end

	if (SERVER) then
		function ENT:CPPISetOwner(ply)
			if (IsValid(ply) and ply:IsPlayer()) then
				self:SetCreator(ply);
			end

			return true
		end

		function ENT:CPPICanTool(ply, tool)
			return ply == self:GetCreator();
		end

		function ENT:CPPICanPhysgun(ply)
			return ply == self:GetCreator();
		end

		function ENT:CPPICanPickup(ply)
			return ply == self:GetCreator();
		end

		function ENT:CPPICanPunt(ply)
			return ply == self:GetCreator();
		end

		function ENT:CPPICanUse(ply)
			return ply == self:GetCreator();
		end

		function ENT:CPPICanDamage(ply)
			return ply == self:GetCreator();
		end

		function ENT:CPPICanProperty(ply, property)
			return ply == self:GetCreator();
		end

		function ENT:CPPICanEditVariable(ply, key, val, editTbl)
			return ply == self:GetCreator();
		end
	end
end