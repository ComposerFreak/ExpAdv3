/*============================================================================================================================================
	Name: GOLEM_Options2
	Author: Oskar
============================================================================================================================================*/

local PANEL = {}

function PANEL:Init( )
	
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(30, 30, 30, 255)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:PerformLayout( )
	
end

vgui.Register( "GOLEM_Options2", PANEL, "EditablePanel" )
