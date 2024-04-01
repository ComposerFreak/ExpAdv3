--[[============================================================================================================================================
	Name: GOLEM_ColorSelect
	Author: Oskar
============================================================================================================================================]]
local PANEL = { }

function PANEL:Init( )
	self:SetTall( 335 )
	
	self.pLanguageSelector = self:Add( "DComboBox" )
	self.pLanguageSelector:Dock( TOP )
	self.pLanguageSelector:SetTall( 20 )
	self.pLanguageSelector:DockMargin( 0, 0, 0, 5 )
	-- self.pLanguageSelector:SetVisible( false )
	
	self.pLanguageSelector:AddChoice( "Expression 3", "e3" )
	self.pLanguageSelector:AddChoice( "Lua", "lua" )
	
	self.pLanguageSelector.OnSelect = function(pnl, index, value, data)
		self.pColorSelector:Clear( )
		
		for k, v in pairs( Golem.Syntax.Colors[data].Colors ) do
			self.pColorSelector:AddChoice( k )
		end
		
		self.pColorSelector:ChooseOptionID( 1 )
	end
	
	
	self.pColorMixer = self:Add( "DColorMixer" ) 
	self.pColorMixer:Dock( TOP )
	self.pColorMixer:SetTall( 171 )
	self.pColorMixer:SetPalette( false )
	self.pColorMixer:SetAlphaBar( false )
	self.pColorMixer:DockPadding( 0, 0, 0, 5 )
	
	self.pColorMixer.ValueChanged = function(pnl,cColor)
		local _, lang = self.pLanguageSelector:GetSelected( )
		Golem.Syntax:SetColor( lang, self.pColorSelector:GetSelected( ), cColor )
	end
	
	
	self.pColorSelector = self:Add( "DComboBox" )
	self.pColorSelector:Dock( TOP )
	self.pColorSelector:SetTall( 20 )
	self.pColorSelector:DockMargin( 0, 0, 0, 5 )
	
	self.pColorSelector.OnSelect = function( pln, index, value, data )
		local _, lang = self.pLanguageSelector:GetSelected( )
		self.pColorMixer:SetColor( Golem.Syntax:GetColor( lang, value ) ) 
	end
	
	
	self.pColorPreview = self:Add( "Panel" )
	self.pColorPreview:Dock( TOP )
	self.pColorPreview:DockMargin( 0, 0, 0, 5 )
	self.pColorPreview:SetTall( 30 )
	
	self.pColorPreview.Paint = function( pnl, w, h )
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawRect( 0, 0, w / 2, h )
		
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawRect( w / 2, 0, w / 2, h )
		
		surface.SetFont( Golem.Font:GetFont( ) )
		
		local Text = self.pColorSelector:GetSelected( )
		local tw, th = surface.GetTextSize( Text )
		local xl, xr = math.floor( w / 4 ) - math.floor( tw / 2 ), math.floor( ( w / 4 ) * 3 ) - math.floor( tw / 2 )
		local y = math.floor( h / 2 ) - math.floor( th / 2 )
		
		surface.SetTextColor( self.pColorMixer:GetColor( ) )
		
		surface.SetTextPos( xl, y )
		surface.DrawText( Text )
		
		surface.SetTextPos( xr, y )
		surface.DrawText( Text )
	end
	
	
	self.pColorReset = vgui.Create( "GOLEM_Button" ) 
	self.pColorReset:SetText( "Reset color" )
	self.pColorReset:SetTextCentered( true )
	self.pColorReset:SetFont( "Trebuchet18" )
	self.pColorReset:SetFlat( true )
	self.pColorReset:SetStyleNames( { "toolbar-btn" } )
	self.pColorReset.DoClick = function(btn)
		local _, lang = self.pLanguageSelector:GetSelected( )
		Golem.Syntax:ResetColor( lang, self.pColorSelector:GetSelected( ) )
		self.pColorMixer:SetColor( Golem.Syntax:GetColor( lang, self.pColorSelector:GetSelected( ) ) ) 
	end
	
	self.pColorResetAll = vgui.Create( "GOLEM_Button" ) 
	self.pColorResetAll:SetText( "Reset all colors" )
	self.pColorResetAll:SetTextCentered( true )
	self.pColorResetAll:SetFont( "Trebuchet18" )
	self.pColorResetAll:SetFlat( true )
	self.pColorResetAll:SetStyleNames( { "toolbar-btn" } )
	self.pColorResetAll.DoClick = function(btn)
		local _, lang = self.pLanguageSelector:GetSelected( )
		Golem.Syntax:ResetColors( lang )
		self.pColorMixer:SetColor( Golem.Syntax:GetColor( lang, self.pColorSelector:GetSelected( ) ) ) 
	end
	
	self.pResetDivider = self:Add( "DHorizontalDivider" )
	self.pResetDivider:Dock( TOP )
	self.pResetDivider:DockMargin( 0, 0, 0, 5 )
	self.pResetDivider:SetLeft( self.pColorReset )
	self.pResetDivider:SetRight( self.pColorResetAll )
	self.pResetDivider:SetLeftWidth( 120 )
	self.pResetDivider:SetLeftMin( 120 )
	self.pResetDivider.StartGrab = function( ) end
	self.pResetDivider.m_DragBar:SetCursor( "" )
	
	
	self.pFontName = vgui.Create( "DComboBox" )
	self.pFontName:SetValue( Golem.Font:GetFontName( ) )
	self.pFontName:AddChoice( "Consolas" )
	self.pFontName:AddChoice( "Courier New" )
	self.pFontName:AddChoice( "Lucida Console" )
	
	if system.IsOSX( ) then
		self.pFontName:AddChoice( "Monaco" )
	end
	
	self.pFontName.OnSelect = function( pnl, index, value, data )
		Golem.Font:SetFont( value )
	end
	
	
	self.pFontSize = self:Add( "DComboBox" )
	self.pFontSize:SetValue( Golem.Font:GetFontSize( ) )
	for i = 10, 30 do self.pFontSize:AddChoice( i ) end
	
	self.pFontSize.OnSelect = function( pnl, index, value, data )
		Golem.Font:ChangeFontSize( value, true )
	end
	
	
	self.pFontSelect = self:Add( "DHorizontalDivider" )
	self.pFontSelect:Dock( TOP )
	self.pFontSelect:DockMargin( 0, 0, 0, 5 )
	self.pFontSelect:SetLeft( self.pFontName )
	self.pFontSelect:SetRight( self.pFontSize )
	self.pFontSelect:SetLeftWidth( 160 )
	self.pFontSelect:SetLeftMin( 160 )
	self.pFontSelect:SetTall( 20 )
	self.pFontSelect.StartGrab = function( ) end
	self.pFontSelect.m_DragBar:SetCursor( "" )
	
	
	self.pFontReset = self:Add( "GOLEM_Button" )
	self.pFontReset:SetText( "Reset font to default" )
	self.pFontReset:Dock( TOP )
	self.pFontReset:DockMargin( 0, 0, 0, 5 )
	self.pFontReset:SetTextCentered( true )
	self.pFontReset:SetFont( "Trebuchet18" )
	self.pFontReset:SetFlat( true )
	self.pFontReset:SetStyleNames( { "toolbar-btn" } )
	self.pFontReset.DoClick = function( btn )
		Golem.Font:SetFont( "Courier New", 16 )
		self.pFontName:SetValue( "Courier New" )
		self.pFontSize:SetValue( 16 )
	end
	
	self.pLanguageSelector:ChooseOptionID( 1 )
end

function PANEL:Paint( w, h )
	-- surface.SetDrawColor( 240, 240, 240, 255 ) 
	-- surface.DrawRect( 0, 0, w, h )
end

function PANEL:PerformLayout( )
end

vgui.Register( "GOLEM_ColorSelect", PANEL, "EditablePanel" )