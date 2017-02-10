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
WireToolSetup.open("expression3", "Expression 3", "gmod_wire_expression3", nil, "Expression3s")
WireToolSetup.BaseLang()

--[[
	Client side language, etc.
]]

if CLIENT then
	language.Add("Tool.wire_expression3.name", "Expression 3 Tool (Wire)")
	language.Add("Tool.wire_expression3.desc", "Spawns an Expression 3 chip for use with the wire system.")
	language.Add("sboxlimit_wire_expressions", "You've hit the Expression 3 limit!")

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
}

--[[

]]

WireToolSetup.SetupMax(30, "Max wire expression 3.")

--[[

]]

function TOOL:MakeEnt(ply, model, Ang, trace)
    return WireLib.MakeWireEnt(ply, {Class = self.WireClass, Pos = trace.HitPos, Angle = Ang, Model = model})
end

