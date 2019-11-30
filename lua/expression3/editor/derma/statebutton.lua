--[[============================================================================================================================================
	Name: GOLEM_StateButton
	Author: Oskar
============================================================================================================================================]]
local PANEL = { }

AccessorFunc( PANEL, "m_nState", "State", FORCE_NUMBER )

function PANEL:Init( )
	self.tStates = { }
	self.m_nState = 0
	self:SetAutoResize( false )
end

--fugue/ui-check-box.png
--fugue/ui-check-box-uncheck.png
--fugue/ui-check-box-mix.png

function PANEL:AddState( sIcon, cColor, sText, sTooltip, tValue, bNoCycle )
	local nID = #self.tStates + 1
	if isstring( sIcon ) then sIcon = Material( sIcon ) end 
	self.tStates[nID] = { nID = nID, mIcon = sIcon, cColor = cColor, sText = sText, sTooltip = sTooltip, tValue = tValue, bNoCycle = bNoCycle }
end

function PANEL:RemoveState( nID ) 
	if nID > #self.tStates then return end 
	if not self.tStates[nID] then return end 
	table.remove( self.tStates, nID )
end 

function PANEL:UpdateState( nID, sIcon, cColor, sText, sTooltip, tValue, bNoCycle )
	local tState = self.tStates[nID]
	
	if not tState then return end
	if isstring( sIcon ) then sIcon = Material( sIcon ) end 
	
	tState.mIcon = sIcon or tState.mIcon
	tState.cColor = cColor or tState.cColor
	tState.sText = sText or tState.sText
	tState.sTooltop = sTooltip or tState.sTooltop
	tState.tValue = tValue or tState.tValue
	if bNoCycle ~= nil then tState.bNoCycle = bNoCycle end
	
	if self.m_nState == nID then self:SetState( nID, true ) end
end 

function PANEL:SetState( nID, bNoChange )
	local tState = self.tStates[nID]
	
	if tState then
		if tState.mIcon then self:SetMaterial( tState.mIcon ) end 
		if tState.cColor then self:SetColor( tState.cColor ) end 
		if tState.sText then self:SetText( tState.sText ) end
		if tState.sTooltip then self:SetTooltip( tState.sTooltip ) end 
		
		if not bNoChange then self:StateChanged( self.m_nState, nID ) end
		
		self.m_nState = nID
	end
end

function PANEL:StateChanged( nOldState, nNewState ) end 

function PANEL:GetStateData( nID ) 
	return self.tStates[nID or self.m_nState]
end 

function PANEL:GetValue( ) 
	return self.tStates[self.m_nState].tValue
end 

function PANEL:NextState( nLoop ) 
	local nID = self.m_nState + 1
	if nID > #self.tStates then nID = 1 end 
	
	if nLoop and nLoop > #self.tStates * 2 then return self:SetState( nID ) end 
	
	if self.tStates[nID].bNoCycle then 
		nLoop = (nLoop or 0) + 1
		self.m_nState = nID
		return self:NextState( nLoop )
	end 
	
	self:SetState( nID )
end 

function PANEL:PrevState( nLoop )
	local nID = self.m_nState - 1
	if nID < 1 then nID = #self.tStates end 
	
	if nLoop and nLoop > #self.tStates * 2 then return self:SetState( nID ) end 
	
	if self.tStates[nID].bNoCycle then 
		nLoop = (nLoop or 0) + 1
		self.m_nState = nID
		return self:PrevState( nLoop )
	end 
	
	self:SetState( nID )
end 

function PANEL:DoClick( ) 
	self:NextState( )
end 

function PANEL:DoRightClick( ) 
	self:PrevState( )
end 

vgui.Register( "GOLEM_StateButton", PANEL, "GOLEM_ImageButton" )