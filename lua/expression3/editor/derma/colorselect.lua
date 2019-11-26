/*============================================================================================================================================
	Name: GOLEM_ColorSelect
	Author: Oskar
============================================================================================================================================*/

local PANEL = { }
local Syntax = Golem.Syntax


function PANEL:Init( )
	self.cbLanguageSelector = self:Add( "DComboBox" )
	self.cbLanguageSelector:Dock( TOP )
	self.cbLanguageSelector:SetTall( )
	
	
end

function PANEL:Paint(w, h)
	-- surface.SetDrawColor(30, 30, 30, 255)
	-- surface.DrawRect(0, 0, w, h)
end

function PANEL:PerformLayout( )
	
end

vgui.Register( "GOLEM_ColorSelect", PANEL, "EditablePanel" )
