/*============================================================================================================================================
	Name: GOLEM_PropertySheet
	Author: Oskar
============================================================================================================================================*/

local PANEL = { }

function PANEL:Init( )
	self.pnlTabs = vgui.Create( "DPanel", self )
	self.pnlTabs:Dock( TOP )
	self.pnlTabs.Paint = function( pnl, w, h ) end

	self.btnNewTab = vgui.Create( "GOLEM_ImageButton", self.pnlTabs )
	self.btnNewTab:Dock( LEFT )
	self.btnNewTab:DockMargin( 0, 0, 2, 0 )
	self.btnNewTab:SetIconFading( false )
	self.btnNewTab:SetIconCentered( true )
	self.btnNewTab:SetTooltip( "New tab" )
	self.btnNewTab:SetPadding( 2 )
	self.btnNewTab:SetFlat( true )
	self.btnNewTab:SetOutlined( true )
	self.btnNewTab:DrawButton( true )
	self.btnNewTab:SetMaterial( Material( "fugue/script--plus.png" ) )
	
	if GOLEM_LIGHT then 
		self.btnNewTab:SetColor( Color( 255, 255, 255 ) )
		self.btnNewTab:SetTextColor( Color( 0, 0, 0 ) )
	end 

	self.btnNewTab.DoClick = function( btn )
		self:GetParent( ):NewTab( "editor", false, nil, "generic" )
	end

	self.tabScroller:Remove( )
	self.tabScroller = vgui.Create( "DHorizontalScroller", self.pnlTabs )
	self.tabScroller:Dock( FILL )
	self.tabScroller:SetOverlap( -2 )
end

function PANEL:AddSheet( strName, pnlContent, strMaterial, fClose )
	if not IsValid( pnlContent ) then return end

	local Sheet = { }
	Sheet.Name = strLabel

	Sheet.Tab = vgui.Create( "GOLEM_ImageButton", self )
	Sheet.Tab.DoClick = function( tab ) self:SetActiveTab( tab ) end
	Sheet.Tab:SetFont( "Trebuchet18" )
	Sheet.Tab:SetTall( 24 )
	Sheet.Tab:SetFlat( true )
	Sheet.Tab:SetOutlined( true )
	Sheet.Tab:DrawButton( true )
	Sheet.Tab:SetPadding( 5 )
	Sheet.Tab:SetMaterial( Material( strMaterial ) )
	Sheet.Tab:SetIconFading( false )
	if GOLEM_LIGHT then 
		Sheet.Tab:SetColor( Color( 255, 255, 255, 255 ) )
		Sheet.Tab:SetTextColor( Color( 0, 0, 0, 255 ) )
	end 


	Sheet.Tab.btnClose = vgui.Create( "GOLEM_ImageButton", Sheet.Tab )
	Sheet.Tab.btnClose.DoClick = fClose
	Sheet.Tab.btnClose:SetMaterial( Material( "oskar/close.png" ) )
	Sheet.Tab.btnClose:SetSize( 16, 16 )
	Sheet.Tab.btnClose:Dock( RIGHT )
	Sheet.Tab.btnClose:DockMargin( 2, 2, 5, 2 )
	Sheet.Tab.Sheet = Sheet

	Sheet.Tab.PerformLayout = function( tab )
		tab:SizeToContentsX( )
		tab:SetWide( tab:GetWide( ) + tab.btnClose:GetWide( ) )
	end

	Sheet.Tab.SetName = function( tab, name )
		tab:SetText( name )
		tab.Sheet.Name = name
		self:InvalidateLayout( true )
	end
	Sheet.Tab:SetName( strName )

	Sheet.Tab.GetName = function( tab )
		return string.Trim( tab:GetText( ) )
	end

	Sheet.Tab.GetPanel = function( tab ) return tab.m_pPanel end
	Sheet.Tab.SetPanel = function( tab, panel ) tab.m_pPanel = panel end
	Sheet.Tab:SetPanel( pnlContent )

	Sheet.Panel = pnlContent
	Sheet.Panel:SetVisible( false )
	Sheet.Panel:SetParent( self )
	Sheet.Panel.Tab = Sheet.Tab

	self.Items[#self.Items + 1] = Sheet

	if not self:GetActiveTab( ) then
		self:SetActiveTab( Sheet.Tab )
		Sheet.Panel:SetVisible( true )
	end

	self.tabScroller:AddPanel( Sheet.Tab )

	return Sheet
end

function PANEL:CloseTab( tab, bRemovePanelToo )
	local idx = 0
	for k, v in pairs( self.Items ) do
		if v.Tab ~= tab then continue end
		table.remove( self.Items, k )
		idx = k
		break
	end

	for k, v in pairs( self.tabScroller.Panels ) do
		if v ~= tab then continue end
		table.remove( self.tabScroller.Panels, k )
		break
	end
	self.tabScroller:InvalidateLayout( true )

	if tab == self:GetActiveTab( ) then
		if #self.Items > 0 then self:SetActiveTab( self.Items[math.min(idx,#self.Items)].Tab )
		else self:SetActiveTab( nil ) end
	end

	local pnl = tab:GetPanel( )
	if bRemovePanelToo then pnl:Remove( ) end

	tab:Remove( )
	self:InvalidateLayout( true )
	return pnl
end

function PANEL:SetActiveTab( active )
	if self.m_pActiveTab == active then return end
	if not IsValid(self.m_pActiveTab) or not ispanel(self.m_pActiveTab) then self.m_pActiveTab = nil end
	if self.m_pActiveTab then
		self.m_pActiveTab:GetPanel( ):SetVisible( false )
		self.m_pActiveTab:SetColor( Color( 180, 180, 180 ) )
	end

	if active then
		if GOLEM_LIGHT then 
			active:SetColor( Color( 255, 255, 255 ) )
		else
			active:SetColor( Color( 20, 20, 20 ) )
		end
	end

	self.m_pActiveTab = active
	self:InvalidateLayout( )
end

function PANEL:Paint( w, h )
end

function PANEL:PerformLayout( )
	local ActiveTab = self:GetActiveTab( )

	if not ActiveTab then return end
	if not IsValid( ActiveTab ) or not ispanel(ActiveTab) then return end

	ActiveTab:InvalidateLayout( true )
	self.pnlTabs:SetTall( ActiveTab:GetTall( ) )

	local ActivePanel = ActiveTab:GetPanel( )

	for k, v in pairs( self.Items ) do
		if v.Tab:GetPanel( ) == ActivePanel then
			v.Tab:GetPanel( ):SetVisible( true )
			v.Tab:SetZPos( 100 )
		else
			v.Tab:GetPanel( ):SetVisible( false )
			v.Tab:SetZPos( 1 )
		end
		v.Tab:InvalidateLayout( true )
	end

	ActivePanel:SetPos( 0, ActiveTab:GetTall( ) )
	ActivePanel:SetWide( self:GetWide( ) )
	ActivePanel:SetTall( self:GetTall( ) - ActiveTab:GetTall( ) )

	ActivePanel:InvalidateLayout( )
	self.animFade:Run( )
end

vgui.Register( "GOLEM_PropertySheet", PANEL, "DPropertySheet" )