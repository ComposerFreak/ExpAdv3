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
include("shared.lua");

--[[
]]

local ValidateError;

function ValidateError(Thrown )
	local Error;

	if (istable(Thrown)) then
		if (string.sub(Thrown.msg, -1) == ".") then
			Thrown.msg = string.sub(Thrown.msg, 1, -2);
		end

		Error = string.format("%s, at line %i char %i.", Thrown.msg, Thrown.line, Thrown.char);

		if (Thrown.file) then
			Error = string.format("%s in %s.txt", string.sub(Error, 1, -2), Thrown.file);
		end
	else
		Error = Thrown
		Thrown = nil
	end

	chat.AddText(Color(255, 255, 255), "Upload failed see editor console.");
	Golem.Print(Error);
end

--[[
]]

function ENT:ReceiveFromServer(ply, script, files)
	timer.Simple(1, function()
		if (IsValid(self)) then
			self.player = ply;
			self:SetCode(script, files, true);
		end
	end);
end

function ENT:PostInitScript()
	net.Start("Expression3.InitializedClient");
		net.WriteEntity(self);
	net.SendToServer();
end

-- function ENT:GetOverlayText()
function ENT:GetOverlayData()
	return {txt = table.concat({
		"::Expression 3::",
		self:GetPlayerName(),
		self:GetScriptName() or "generic",
		"----------------------",
		"SEVER: " .. self:GetServerDisplayData(),
		"CLIENT: " .. self:GetClientDisplayData(),
	}, "\n")};
end

local function percent(part, whole)
	part, whole = part or 0, whole or 0;
	
	if part <= 0 or whole <= 0 then return 0; end
	
	local p = math.ceil((part / whole) * 100);
	
	if p < 0 then p = 0; end
	
	return p;
end

function ENT:GetDisplayLine(soft, average, warning)
	if not self.context or not self.context.status then
		return "Offline";
	end

	return math.ceil(average * 100) .. "% (" .. math.ceil(soft * 1000000) .. "us" .. (warning and "!" or "") .. ")";
end

function ENT:GetClientDisplayData()
	return self:GetDisplayLine(self:GetClientSoftCPU(), self:GetClientAverageCPU(), self:GetClientWarning());
end

function ENT:GetServerDisplayData()
	return self:GetDisplayLine(self:GetServerSoftCPU(), self:GetServerAverageCPU(), self:GetServerWarning());
end
