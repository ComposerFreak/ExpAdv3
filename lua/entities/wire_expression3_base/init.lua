--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Expression 3 Base::
]]

AddCSLuaFile("cl_init.lua");
include("shared.lua");

--[[
]]

net.Receive("Expression3.SubmitToServer", function(len, ply)
	local ent = net.ReadEntity();
	local script = net.ReadString();

	if (IsValid(ent) and ent.ReceiveFromClient) then
		ent:ReceiveFromClient(ply, script);
	end	
end)

function ENT:ReceiveFromClient(ply, script)
	-- print("SERVER");
	-- print("Reciveied:", self, ply);
	-- print(script);
	-- print("----------------------");

	if (self:CanSetCode(ply)) then
		timer.Simple(1, function()
			if (IsValid(self)) then
				self:SetCode(script, true);
			end
		end);
	end
end

function ENT:PostInitScript()
	print("Broadcasting to clients:");
	net.Start("Expression3.SendToClient")
		net.WriteEntity(self);
		net.WriteEntity(self.context.player);
		net.WriteString(self.script);
	net.Broadcast();
end

--[[
]]

function ENT:CanSetCode(ply)
	return true; -- TODO: Make this do somthing more secure.
end

--[[
]]

function ENT:Initialize( )
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);
end

--[[
]]

function ENT:SendToOwner(bConsole, ...)
	local const = bConsole and EXPR_CONSOLE or EXPR_CHAT;
	EXPR_LIB.SendToPlayer(self:CPPIGetOwner(), self, const, ...);
end

--[[
]]

function ENT:HandelThrown(thrown)
	self:ShutDown();

	if (not thrown) then
		self:SendToOwner(true, Color(255,0,0), "An unkown error ocurred.");
	end

	if (isstring(thrown)) then
		self:SendToOwner(true, Color(255,0,0), thrown);
	end

	if (istable(thrown)) then
		--self:SendThrownError(thrown);
		print("state:", thrown.state);
		print("msg:", thrown.msg);
		print("char:", thrown.char);
		print("line:", thrown.line);
	end

	self:SendToOwner(false, Color(255,0,0), "An expression3 gate has errored (see console).");
end

--[[
	DUPE
]]

function ENT:BuildDupeInfo()
  local info = self.BaseClass.BuildDupeInfo(self) or {}
  info.script = self.script
  return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
  self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
  self:SetCode( info.script )
end
