/*============================================================================================================================================
	Name: GOLEM_CloseButton
	Author: Oskar 
============================================================================================================================================*/

local small_cross = Material( "fugue/cross-button.png" )

local PANEL = { }

function PANEL:Init( )
	self._x = 0
	self._y = 0
	self:SetMaterial( small_cross )
end

function PANEL:DoClick( )
	local Parent = self:GetParent( )
	if Parent then
		if Parent.Close then 
			Parent:Close( )
		else 
			Parent:Remove( ) 
		end 
	end
end

function PANEL:SetOffset( x, y )
	self._x = x 
	self._y = y 
end 

function PANEL:Think( )
	if self:GetParent() then
		local x = self:GetParent( ):GetWide( ) - self:GetWide( ) + self._x 
		local y = self._y 
		self:SetPos( x, y )
	end
end

vgui.Register( "GOLEM_CloseButton", PANEL, "GOLEM_ImageButton" )
