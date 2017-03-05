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
	if (self:CanSetCode(ply)) then
		timer.Simple(1, function()
			if (IsValid(self)) then
				self:SetCode(script, true);
			end
		end);
	end
end

function ENT:PostInitScript()
	net.Start("Expression3.SendToClient")
		net.WriteEntity(self);
		net.WriteEntity(self.context.player);
		net.WriteString(self.script);
	net.Broadcast();
end

net.Receive("Expression3.InitalizedClient", function(len, ply)
	local ent = net.ReadEntity();

	if (IsValid(ent) and ent.CallEvent) then
		ent:CallEvent("", 0, "InitalizedClient", {"p", ply});
	end	
end)

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

local function SortPorts( PortA, PortB )
	local TypeA = PortA.wire or "NORMAL"
	local TypeB = PortB.wire or "NORMAL"

	if TypeA ~= TypeB then
		if TypeA == "NORMAL" then
			return true
		elseif TypeB == "NORMAL" then
			return false
		end

		return TypeA < TypeB
	else
		return PortA.wire[1] < PortB.wire[1]
	end
end

function ENT:TriggerInput(name, value, noTrig)
	local context = self.context;

	if (context) then
		local port = self.wire_inport_tbl[name];
		local wireport = self.Inputs[name];

		if (port and wireport) then
			if (port.wire == wireport.Type) then
				local v = port.func and port.func(value) or value;

				if (v ~= self.context.wire_in[name]) then
					context.wire_in[name] = v;
					self:CallEvent("", 0, "Trigger", {"s", name}, {port.class, v});
				end
			end
		end
	end
end

function ENT:TriggerOutputs()
	local context = self.context;

	if (context) then
		for name, wireport in pairs(self.OutPorts) do
			local port = self.wire_outport_tbl[name];

			if (port and port.wire == wireport.Type) then
				local value = context.wire_out[name];
				local v = port.func and port.func(value) or value;

				if (v ~= wireport.Value) then
					WireLib.TriggerOutput(self, name, v);
				end
			end
		end
	end
end

function ENT:BuildWiredPorts(sort_in, sort_out)
	local names_in = {};
	local types_in = {};

	local context = self.context;

	table.sort(sort_in, SortPorts);

	for var, port in pairs(sort_in) do
		names_in[#names_in + 1] = var;
		types_in[#types_in + 1] = port.wire;
	end
	
	self.wire_inport_tbl = sort_in;
	self.Inputs = WireLib.AdjustSpecialInputs(self, names_in, types_in);

	for name, wireport in pairs(self.Inputs) do
		self:TriggerInput(name, wireport.Value);
	end

	------------------------------------------------------------------------------

	local names_out = {};
	local types_out = {};
	
	table.sort(sort_out, SortPorts);

	for var, port in pairs(sort_out) do
		names_out[#names_out + 1] = var;
		types_out[#types_out + 1] = port.wire;
	end

	self.wire_outport_tbl = sort_out;
	self.OutPorts = WireLib.AdjustSpecialOutputs( self, names_out, types_out )

	for name, wireport in pairs(self.OutPorts) do
		local port = self.wire_outport_tbl[name];

		if (port and port.wire == wireport.Type) then
			local value = wireport.Value;
			context.wire_out[name] = port.func_in and port.func_in(value) or value;
		end
	end

	-------------------------------------------------------------------------------

	if self.extended then
		WireLib.CreateWirelinkOutput( self.player, self, { true } )
	end 
end

--[[

]]

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	self.Inputs = WireLib.CreateInputs( self, { } )
	self.Outputs = WireLib.CreateOutputs( self, { } )
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
	ent.player = ply;
	self:SetPlayer(ply);
	self:SetCode(info.script);
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID);
end

