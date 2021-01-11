--[[============================================================================================================================================
	Name: GOLEM_Options
	Author: Oskar
============================================================================================================================================]]
local PANEL = { }

function PANEL:Init( )
	self:DockPadding( 5, 5, 5, 5)
	
	self.pColorSelect = self:Add( "GOLEM_ColorSelect" ) 
	self.pColorSelect:Dock( TOP )
end

function PANEL:Paint( w, h )
	surface.SetDrawColor( 30, 30, 30, 255 )
	if GOLEM_LIGHT then surface.SetDrawColor( 240, 240, 240, 255 ) end
	surface.DrawRect( 0, 0, w, h )
end

function PANEL:PerformLayout( )
	
end

vgui.Register( "GOLEM_Options", PANEL, "EditablePanel" )