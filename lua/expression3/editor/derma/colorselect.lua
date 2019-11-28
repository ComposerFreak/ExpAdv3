--[[============================================================================================================================================
	Name: GOLEM_ColorSelect
	Author: Oskar
============================================================================================================================================]]
local PANEL = { }

function PANEL:Init( )
	self.pLanguageSelector = self:Add( "DComboBox" )
	self.pLanguageSelector:Dock( TOP )
	self.pLanguageSelector:SetTall( 20 )
	self.pLanguageSelector:DockMargin( 5, 5, 5, 0 )
	
	self.pLanguageSelector:AddChoice( "E3", nil ,true )
	
	self.pColorMixer = self:Add( "DColorMixer" ) 
	self.pColorMixer:Dock( TOP )
	self.pColorMixer:SetTall( 171 )
	self.pColorMixer:SetPalette( false )
	self.pColorMixer:SetAlphaBar( false )
	self.pColorMixer:DockPadding( 5, 5, 5, 0 )
	
	self.pColorSelector = self:Add( "DComboBox" )
	self.pColorSelector:Dock( TOP )
	self.pColorSelector:SetTall( 20 )
	self.pColorSelector:DockMargin( 5, 5, 5, 0 )
	
	self.pColorSelector.OnSelect = function( pln, index, value, data )
		self.pColorMixer:SetColor( data ) 
		-- print( data )
	end
	
	for k, v in pairs( Golem.Syntax.Colors.e3.Defaults ) do
		self.pColorSelector:AddChoice( k, v, false )
	end
	
	self.pColorSelector:ChooseOptionID( 1 )
end

function PANEL:Paint( w, h )
	-- surface.SetDrawColor(30, 30, 30, 255)
	-- surface.DrawRect(0, 0, w, h)
end

function PANEL:PerformLayout( )
end

vgui.Register( "GOLEM_ColorSelect", PANEL, "EditablePanel" )