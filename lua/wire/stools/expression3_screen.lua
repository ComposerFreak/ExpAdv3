--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Expression 3 Tool::
]]

AddCSLuaFile();

WireToolSetup.setCategory( "Chips, Gates" )
WireToolSetup.open("expression3_screen", "Expression 3 Screen", "wire_expression3_screen", nil, "Expression3s")

--[[
	Client side language, etc.
]]

if CLIENT then
	language.Add("Tool.wire_expression3_screen.name", "Expression 3 Scrren Tool (Wire)")
	language.Add("Tool.wire_expression3_screen.desc", "Spawns an Expression 3 chip for use with the wire system.")

	TOOL.Information = {
		{ name = "left", text = "Create " .. TOOL.Name },
		{ name = "right", text = "Open " .. TOOL.Name .. " in Editor" },
	}

	WireToolSetup.setToolMenuIcon( "vgui/e2logo" )
end

--[[
	Convars.
]]

TOOL.ClientConVar = {
	model = "models/props_phx/rt_screen.mdl",
}

WireToolSetup.SetupMax(20)
WireToolSetup.BaseLang()

duplicator.RegisterEntityClass( "wire_expression3_screen", WireLib.MakeWireEnt, "Data", "code_str" )

function TOOL:PostMake(ent)
	local ply = self:GetOwner();

	ent.player = ply;
	ent:SetPlayer(ply);

	timer.Simple(0.2, function()
		EXPR_UPLOADER.RequestFromClient(self:GetOwner(), ent);
	end);
end

function TOOL:CheckHitOwnClass( trace )
	return trace.Entity:IsValid() and trace.Entity.Expression3;
end

function TOOL:LeftClick_Update( trace )
	EXPR_UPLOADER.RequestFromClient(self:GetOwner(), trace.Entity);
end

function TOOL:GetModel()
	local script_model = self:GetClientInfo("script_model");

	if (script_model and script_model ~= "") then
		if (self:CheckValidModel(script_model)) then
			return script_model;
		end
	end

	return WireToolObj.GetModel(self);
end

if CLIENT then
	local TOOL = TOOL;

	function TOOL.BuildCPanel( CPanel )
		WireDermaExts.ModelSelect(CPanel, "wire_expression3_screen_model", list.Get( "WireScreenModels" ), 5)
	end
end

function TOOL:RightClick( Trace )
	if (SERVER) then
		local loadScript = self:CheckHitOwnClass(Trace);
		
		net.Start("Expression3.OpenGolem");

			net.WriteBool(loadScript);

			if loadScript then net.WriteEntity(Trace.Entity); end

		net.Send(self:GetOwner());
	end
end

if CLIENT then

	local background = surface.GetTextureID("omicron/bulb");

	function TOOL:DrawToolScreen(width, height)
		EXPR_UPLOADER.DrawUploadScreen(width, height, "Screen");
	end

end
