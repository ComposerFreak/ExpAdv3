--[[============================================================================================================================================
	Name: GOLEM_Options
	Author: Oskar
============================================================================================================================================]]
local PANEL = { }

function PANEL:Init( )
	self:DockPadding( 5, 5, 5, 5 )
	
	self.pColorSelect = self:Add( "GOLEM_ColorSelect" ) 
	self.pColorSelect:Dock( TOP )
end

function PANEL:Paint( w, h )
	surface.SetDrawColor( Golem.Style:GetColor( "options-bg" ) )
	surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "GOLEM_Options", PANEL, "EditablePanel" )