/*============================================================================================================================================
	Name: GOLEM_HScrollBar
	Author: Oskar 
============================================================================================================================================*/

local PANEL = { }

function PANEL:Init( )
	self.Offset = 0
	self.Scroll = 0
	self.CanvasSize = 1
	self.BarSize = 1	
	
	self.btnUp:Remove( ) 
	self.btnDown:Remove( ) 
	self.btnGrip:Remove( ) 
	
	self.btnLeft = vgui.Create( "DButton", self )
	self.btnLeft:SetText( "" )
	self.btnLeft.DoClick = function ( self ) self:GetParent( ):AddScroll( -1 ) end
	self.btnLeft.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonLeft", panel, w, h ) end
	
	self.btnRight = vgui.Create( "DButton", self )
	self.btnRight:SetText( "" )
	self.btnRight.DoClick = function ( self ) self:GetParent( ):AddScroll( 1 ) end
	self.btnRight.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonRight", panel, w, h ) end
	
	self.btnGrip = vgui.Create( "DScrollBarGrip", self )
	
	self:SetSize( 15, 15 )
end

function PANEL:AddScroll( dlta )
	local OldScroll = self:GetScroll( )
	
	dlta = dlta
	self:SetScroll( self:GetScroll( ) + dlta )
	
	return OldScroll == self:GetScroll( ) 
end

function PANEL:SetScroll( scroll )
	if not self.Enabled then self.Scroll = 0 return end
	self.Scroll = math.Clamp( scroll, 0, self.CanvasSize )
	self:InvalidateLayout( )
end

function PANEL:OnMouseWheeled( dlta )
	if not self:IsVisible( ) then return false end
	return self:AddScroll( dlta )
end

function PANEL:OnMousePressed( )
	local x, y = self:CursorPos( )
	local PageSize = self.BarSize
	
	if x > self.btnGrip.x then
		self:SetScroll( self:GetScroll( ) + PageSize )
	else
		self:SetScroll( self:GetScroll( ) - PageSize )
	end	
end

function PANEL:OnCursorMoved( x, y )
	if !self.Enabled then return end
	if !self.Dragging then return end
	
	local x = self:ScreenToLocal( gui.MouseX( ), 0 )
	local TrackSize = self:GetWide( ) - self:GetTall( ) * 2 - self.btnGrip:GetWide( )
	 
	x = x - self.btnRight:GetWide( ) - self.HoldPos
	x = x / TrackSize
	
	self:SetScroll( x * self.CanvasSize )	
end

function PANEL:Grip( )
	if not self.Enabled then return end
	if self.BarSize == 0 then return end
	
	self:MouseCapture( true )
	self.Dragging = true
	
	self.HoldPos = self.btnGrip:ScreenToLocal( gui.MouseX( ), 0 )
	
	self.btnGrip.Depressed = true
end

function PANEL:PerformLayout( )
	local Tall = self:GetTall( )
	local Scroll = self:GetScroll( ) / self.CanvasSize
	local BarSize = math.max( self:BarScale( ) * (self:GetWide( ) - (Tall * 2)), 10 )
	local Track = self:GetWide( ) - (Tall * 2) - BarSize
	Track = Track + 1
	
	Scroll = Scroll * Track
	
	self.btnGrip:SetPos( Tall + Scroll, 0 )
	self.btnGrip:SetSize( BarSize, Tall )
	
	self.btnLeft:SetPos( 0, 0 )
	self.btnLeft:SetSize( Tall, Tall )
	
	self.btnRight:SetPos( self:GetWide( ) - Tall, 0 )
	self.btnRight:SetSize( Tall, Tall )
end


vgui.Register( "GOLEM_HScrollBar", PANEL, "DVScrollBar" )
