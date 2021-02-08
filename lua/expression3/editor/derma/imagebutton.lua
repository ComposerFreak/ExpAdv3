/*============================================================================================================================================
	Name: GOLEM_ImageButton
	Author: Oskar
============================================================================================================================================*/

local gradient_down = Material( "vgui/gradient-u" )

local PANEL = { }

AccessorFunc( PANEL, "m_mMaterial", 	"Material" )
AccessorFunc( PANEL, "m_nPadding", 		"Padding" )

AccessorFunc( PANEL, "m_bIconFading", 	"IconFading", 	FORCE_BOOL )
AccessorFunc( PANEL, "m_bIconCentered", "IconCentered", FORCE_BOOL )
AccessorFunc( PANEL, "m_bIconStretch", 	"IconStretch", 	FORCE_BOOL )
AccessorFunc( PANEL, "m_bAutoResize", 	"AutoResize", 	FORCE_BOOL )

function PANEL:Init( )
	self:SetText( "" )
	self:SetPadding( 0 )
	self:SetIconFading( true )
	self:SetTextCentered( false )
	self:SetIconCentered( false )
	self:SetAutoResize( true )
	self:SetIconStretch( false )
end

function PANEL:DrawButton( bool )
	self.m_bDrawButton = bool
end

function PANEL:SetMaterial( mat )
	if type( mat ) ~= "IMaterial" or mat:IsError( ) then return end // TODO: Fling some shit here
	self.m_mMaterial = mat
	if self:GetAutoResize( ) then self:SizeToContents( ) end
end

function PANEL:SizeToContents( )
	local w, h = 0, 0
	if self.m_mMaterial then
		w, h = self.m_mMaterial:Width( ) + self.m_nPadding * 2, self.m_mMaterial:Height( ) + self.m_nPadding * 2
	end
	
	if self.m_bDrawButton then
		surface.SetFont( self:GetFont() )
		local Text = self:GetText( )
		local x, y = surface.GetTextSize( Text )
		if x > 0 then
			w = w + x + 4 + self.m_nPadding * ( self.m_mMaterial and 1 or 2 )
			h = math.max( h, y + self.m_nPadding * 2 )
		end
	end
	
	self:SetSize( w, h )
end

function PANEL:SizeToContentsX( )
	local w = 0
	if self.m_mMaterial then
		w = self.m_mMaterial:Width( ) + self.m_nPadding * 2
	end
	
	if self.m_bDrawButton then
		surface.SetFont( self:GetFont( ) )
		local Text = self:GetText( )
		local x = surface.GetTextSize( Text )
		if x > 0 then
			w = w + x + 4 + self.m_nPadding * ( self.m_mMaterial and 1 or 2 )
		end
	end
	
	self:SetWide( w )
end

function PANEL:SizeToContentsY( )
	local h = 0
	if self.m_mMaterial then
		h = self.m_mMaterial:Height( ) + self.m_nPadding * 2
	end
	
	if self.m_bDrawButton then
		surface.SetFont( self:GetFont( ) )
		local Text = self:GetText( )
		local _, y = surface.GetTextSize( Text )
		h = math.max( h, y + self.m_nPadding * 2 )
	end
	
	self:SetTall( h )
end

local function PaintButton( self, w, h )
	surface.SetDrawColor( self:GetColor( ):Unpack( ) )
	if self.m_sStyleNames and self.m_sStyleNames[1] then 
		surface.SetDrawColor( Golem.Style:GetColor( self.m_sStyleNames[1] ) )
	end 
	surface.DrawRect( 0, 0, w, h )
	
	if not self:GetFlat( ) then
		surface.SetDrawColor( 200, 200, 200, 100 )
		if self.m_sStyleNames and self.m_sStyleNames[2] then surface.SetDrawColor( Golem.Style:GetColor( self.m_sStyleNames[2] ) ) end
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
	
	if not self.m_bTextCentered then x = self.m_nPadding end
	
	if self.m_mMaterial then x = x + 2 + self.m_mMaterial:Width( ) + self.m_nPadding end
	
	if self:GetTextShadow( ) then
		surface.SetTextColor( self:GetTextShadow( ):Unpack() )
		if self.m_sStyleNames and self.m_sStyleNames[3] then surface.SetTextColor( Golem.Style:GetColor( self.m_sStyleNames[3] ) ) end
		
		for _x = -1, 1 do
			for _y = -1, 1 do
				surface.SetTextPos( x + _x, y + _y )
				surface.DrawText( Text )
			end
		end
	end
	
	surface.SetTextColor( self:GetTextColor( ):Unpack( ) )
	if self.m_sStyleNames and self.m_sStyleNames[4] then surface.SetTextColor( Golem.Style:GetColor( self.m_sStyleNames[4] ) ) end
	surface.SetTextPos( x, y )
	surface.DrawText( Text )
end

function PANEL:Paint( w, h )
	if self.m_bDrawButton then PaintButton( self, w, h ) end
	
	if self.m_mMaterial then
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( self.m_mMaterial )
		
		local n = math.max( self.m_mMaterial:Width( ), self.m_mMaterial:Height( ) )
		local x, y = w/2 - n/2, h/2 - n/2
		
		if not self.m_bIconCentered then x = self.m_nPadding end
		
		if self:GetIconStretch( ) then x, y, n = 0, 0, math.max( w, h ) end
		
		surface.DrawTexturedRect( x, y, n, n )
		
		if self:GetIconFading( ) then
			surface.SetDrawColor( 0, 0, 0, 0 )
			if self.Hovered then surface.SetDrawColor( 0, 0, 0, 50 ) end
			if self.Depressed then surface.SetDrawColor( 0, 0, 0, 100 ) end
		end
		
		surface.DrawTexturedRect( x, y, n, n )
	end
	
	return true
end

vgui.Register( "GOLEM_ImageButton", PANEL, "GOLEM_Button" )