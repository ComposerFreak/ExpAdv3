/*============================================================================================================================================
	Name: GOLEM_Button
	Author: Oskar
============================================================================================================================================*/

local surface = surface
local math = math

local gradient_down = Material( "vgui/gradient-u" )

local PANEL = { }

AccessorFunc( PANEL, "m_tColor", 			"Color" )
AccessorFunc( PANEL, "m_tTextColor", 		"TextColor" )
AccessorFunc( PANEL, "m_tTextShadow", 		"TextShadow" )

AccessorFunc( PANEL, "m_sFont", 			"Font", FORCE_STRING )

AccessorFunc( PANEL, "m_bOutline", 			"Outlined", FORCE_BOOL )
AccessorFunc( PANEL, "m_bTextCentered", 	"TextCentered", FORCE_BOOL )
AccessorFunc( PANEL, "m_bFading", 			"Fading", FORCE_BOOL )
AccessorFunc( PANEL, "m_bFlat", 			"Flat", FORCE_BOOL )

function PANEL:Init( )
	self:SetSize( 25, 25 )

	self:SetFont( "Trebuchet22" )
	self:SetText( "" )

	self:SetColor( Color( 100, 100, 100 ) )
	self:SetTextColor( Color( 255, 255, 255 ) )
	self:SetOutlined( false )
	self:SetTextCentered( false )
	self:SetFading( true )
	self:SetFlat( false )
end

function PANEL:SizeToContents(  )
	surface.SetFont( self:GetFont( ) )
	local Text = self:GetText( )
	local w, h = surface.GetTextSize( Text )
	self:SetSize( w + 10, h )
end

function PANEL:SizeToContentsX( )
	surface.SetFont( self:GetFont( ) )
	local Text = self:GetText( )
	local w, h = surface.GetTextSize( Text )
	self:SetWide( w + 10 )
end

function PANEL:SizeToContentsY( )
	surface.SetFont( self:GetFont( ) )
	local Text = self:GetText( )
	local w, h = surface.GetTextSize( Text )
	self:SetTall( h )
end

function PANEL:Paint( w, h )
	surface.SetDrawColor( self:GetColor( ) )
	surface.DrawRect( 0, 0, w, h )

	if not self:GetFlat( ) then
		surface.SetDrawColor( 200, 200, 200, 100 )
		surface.SetMaterial( gradient_down )
		surface.DrawTexturedRect( 0, 0, w, h )
	end

	if self:GetFading( ) then
		surface.SetDrawColor( 0, 0, 0, 0 )
		if self.Hovered then surface.SetDrawColor( 0, 0, 0, 100 ) end
		if self.Depressed then surface.SetDrawColor( 0, 0, 0, 150 ) end
		surface.DrawRect( 0, 0, w, h )
	end

	if self:GetOutlined( ) then
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawOutlinedRect( 0, 0, w, h )
	end

	surface.SetFont( self:GetFont( ) )
	local Text = self:GetText( )
	local tw, th = surface.GetTextSize( Text )
	local x, y = math.floor( w / 2 ) - math.floor( tw / 2 ), math.floor( h / 2 ) - math.floor( th / 2 )

	if not self:GetTextCentered( ) then x = 5 end

	if self:GetTextShadow( ) then
		surface.SetTextColor( self:GetTextShadow( ) )

		for _x = -1, 1 do
			for _y = -1, 1 do
				surface.SetTextPos( x + _x, y + _y )
				surface.DrawText( Text )
			end
		end
	end

	surface.SetTextColor( self:GetTextColor( ) )
	surface.SetTextPos( x, y )
	surface.DrawText( Text )

	return true
end

vgui.Register( "GOLEM_Button", PANEL, "DButton" )
