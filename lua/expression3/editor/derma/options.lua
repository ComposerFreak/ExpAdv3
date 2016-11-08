/*============================================================================================================================================
	Name: GOLEM_Options
	Author: Oskar 
============================================================================================================================================*/
local PANEL = { }

function PANEL:Init( )
	local ColorPicker = self:Add( "Panel" ) 
	-- ColorPicker:SetTall( 175 ) 
	ColorPicker:SetWide( 256 ) 
	ColorPicker:Dock( LEFT ) 
	ColorPicker:DockMargin( 5, 5, 5, 0 )
	
	local Mixer = ColorPicker:Add( "DColorMixer" ) 
	Mixer:Dock( TOP ) 
	Mixer:SetTall( 150 ) 
	-- Mixer:DockMargin( 0, 25, 0, 0 )
	
	Mixer:SetPalette( false )
	Mixer:SetAlphaBar( false )
	
	
	local syntaxColor = ColorPicker:Add( "DComboBox" ) 
		syntaxColor:SetTall( 20 )
		-- syntaxColor:SetWide( 256 )
		syntaxColor:Dock( TOP ) 
		syntaxColor:DockMargin( 0, 0, 0, 5 )
		syntaxColor:MoveToBack( ) 
	
	local currentIndex
	function syntaxColor:OnSelect( index, value, data )
		local r, g, b = string.match( data:GetString( ), "(%d+)_(%d+)_(%d+)" ) 
		currentIndex = index
		Mixer:SetColor( Color( r, g, b ) ) 
	end
	
	--[[local first = true 
	for k, v in pairs( EXPADV.Syntaxer.ColorConvars ) do
		syntaxColor:AddChoice( k, v, k=="variable" )
		first = false 
	end ]]
	
	function Mixer:ValueChanged( color )
		-- RunConsoleCommand( "lemon_editor_color_" .. syntaxColor.Choices[currentIndex], color.r .. "_" .. color.g .. "_" .. color.b ) 
		-- EXPADV.Syntaxer:UpdateSyntaxColors( ) 
	end
	
	
	local reset = vgui.Create( "DButton" ) 
		reset:SetText( "Reset color" ) 
	
	function reset:DoClick( )
		-- RunConsoleCommand( "lemon_editor_resetcolors", syntaxColor.Choices[currentIndex] ) 
		-- timer.Simple( 0, function() 
		-- 	local r, g, b = string.match( EXPADV.Syntaxer.ColorConvars[syntaxColor.Choices[currentIndex]]:GetString( ), "(%d+)_(%d+)_(%d+)" ) 
		-- 	Mixer:SetColor( Color( r, g, b ) ) 
		-- end )
	end
	
	local resetall = vgui.Create( "DButton" ) 
		resetall:SetText( "Reset all colors" ) 
	
	function resetall:DoClick( )
		-- RunConsoleCommand( "lemon_editor_resetcolors", "1" ) 
		-- timer.Simple( 0, function() 
		-- 	local r, g, b = string.match( EXPADV.Syntaxer.ColorConvars[syntaxColor.Choices[currentIndex]]:GetString( ), "(%d+)_(%d+)_(%d+)" ) 
		-- 	Mixer:SetColor( Color( r, g, b ) ) 
		-- end )
	end
	
	
	local ResetDivider = ColorPicker:Add( "DHorizontalDivider" ) 
	ResetDivider:Dock( TOP ) 
	ResetDivider:DockMargin( 0, 5, 0, 0 ) 
	ResetDivider:SetLeft( reset )
	ResetDivider:SetRight( resetall )
	ResetDivider:SetLeftWidth( 120 )
	ResetDivider.StartGrab = function( ) end 
	ResetDivider.m_DragBar:SetCursor( "" )
end

function PANEL:Paint( w, h ) 
	surface.SetDrawColor( 30, 30, 30, 255 )
	surface.DrawRect( 0, 0, w, h ) 
end 

vgui.Register( "GOLEM_Options", PANEL, "EditablePanel" )
