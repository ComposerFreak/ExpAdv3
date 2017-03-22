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

WireToolSetup.setCategory( "Chips, Gates" )
WireToolSetup.open("expression3", "Expression 3", "wire_expression3_base", nil, "Expression3s")

--[[
	Client side language, etc.
]]

if CLIENT then
	language.Add("Tool.wire_expression3.name", "Expression 3 Tool (Wire)")
	language.Add("Tool.wire_expression3.desc", "Spawns an Expression 3 chip for use with the wire system.")

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
	model = "models/nezzkryptic/e3_chip.mdl",
	script_model = "";
}

WireToolSetup.SetupMax(20)
WireToolSetup.BaseLang()

duplicator.RegisterEntityClass( "wire_expression3_base", WireLib.MakeWireEnt, "Data", "code_str" )

function TOOL:PostMake(ent)
	local ply = self:GetOwner();

	ent.player = ply;
	ent:SetPlayer(ply);
	
	timer.Simple(0.2, function()
		net.Start("Expression3.RequestUpload");
			net.WriteEntity(ent);
		net.Send(ply);
	end);
end

local GateModels = {
	"models/nezzkryptic/e3_chip.mdl",
	"models/lemongate/lemongate.mdl",
	"models/shadowscion/lemongate/gate.mdl",
	"models/mandrac/wire/e3.mdl",
	"models/bull/gates/processor.mdl",
	"models/expression 2/cpu_controller.mdl",
	"models/expression 2/cpu_expression.mdl",
	"models/expression 2/cpu_interface.mdl",
	"models/expression 2/cpu_microchip.mdl",
	"models/expression 2/cpu_processor.mdl",
};

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

		local PropList = vgui.Create( "PropSelect" )

		PropList:SetConVar( "wire_expression3_model" )

		for _, Model in pairs( GateModels ) do
			PropList:AddModel( Model, false )
		end

		CPanel:AddItem( PropList )
	end

	hook.Add("Expression3.CloseGolem", "Expression3.Tool.ChooseModel", function()
		local model = Golem.GetDirective("model") or "";
		RunConsoleCommand( "wire_expression3_script_model", model);
		MsgN("E3 - Closed editor got model ", model)
	end)
end

function TOOL:RightClick( Trace )
	if (SERVER) then
		self:GetOwner():SendLua( [[
		if (Golem) then
			local editor = Golem.GetInstance();
			editor:SetVisible(true);
			editor:MakePopup();
		end]]);
	end
end