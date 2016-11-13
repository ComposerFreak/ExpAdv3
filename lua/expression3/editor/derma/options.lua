/*============================================================================================================================================
	Name: GOLEM_Options
	Author: Oskar 
============================================================================================================================================*/
local PANEL = { }

function PANEL:Init( )
	self:DockPadding(5,5,5,5)
	
	local Mixer = self:Add( "DColorMixer" ) 
	Mixer:Dock( TOP ) 
	Mixer:SetTall( 150 ) 
	
	Mixer:SetPalette( false )
	Mixer:SetAlphaBar( false )
	
	
	local syntaxColor = self:Add( "DComboBox" ) 
		syntaxColor:SetTall( 20 )
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
	
	
	local ResetDivider = self:Add( "DHorizontalDivider" ) 
	ResetDivider:Dock( TOP ) 
	ResetDivider:DockMargin( 0, 5, 0, 0 ) 
	ResetDivider:SetLeft( reset )
	ResetDivider:SetRight( resetall )
	ResetDivider:SetLeftWidth( 120 )
	ResetDivider.StartGrab = function( ) end 
	ResetDivider.m_DragBar:SetCursor( "" )
	
	
	local editorFont = self:Add( "DComboBox" ) 
		editorFont:SetValue( GetConVarString( "golem_font_name" ) )
	
	
	editorFont:AddChoice( "Consolas" ) 
	editorFont:AddChoice( "Courier New" )
	editorFont:AddChoice( "DejaVu Sans Mono" )
	editorFont:AddChoice( "Lucida Console" )
	
	if system.IsOSX( ) then 
		editorFont:AddChoice( "Monaco", "", false ) 
	end 
	
	function editorFont:OnSelect( index, value, data )
		Golem.Font:SetFont( value ) 
	end
	
	local editorFontSize = self:Add( "DComboBox" ) 
		editorFontSize:SetValue( GetConVarNumber( "golem_font_size" ) )
	
	
	for i = 10, 30 do
		editorFontSize:AddChoice( i ) 
	end
	
	function editorFontSize:OnSelect( index, value, data )
		-- Golem.Font:SetFont( value ) 
		Golem.Font:ChangeFontSize( value, true )
	end
	
	
	
	local FontDivider = self:Add( "DHorizontalDivider" ) 
	FontDivider:Dock( TOP ) 
	FontDivider:DockMargin( 0, 5, 0, 0 ) 
	FontDivider:SetLeft( editorFont )
	FontDivider:SetRight( editorFontSize )
	FontDivider:SetLeftWidth( 200 )
	FontDivider.StartGrab = function( ) end 
	FontDivider.m_DragBar:SetCursor( "" )
	
	local resetfont = self:Add( "DButton" ) 
		resetfont:SetText( "Reset font to default" ) 
		resetfont:Dock( TOP ) 
		resetfont:DockMargin( 0, 5, 0, 0 )
	
	function resetfont:DoClick( )
		Golem.Font:SetFont( "Courier New", 16 ) 
		editorFont:SetValue( "Courier New" )
		editorFontSize:SetValue( 16 )
	end
end

function PANEL:Paint( w, h ) 
	surface.SetDrawColor( 30, 30, 30, 255 )
	surface.DrawRect( 0, 0, w, h ) 
end 

vgui.Register( "GOLEM_Options", PANEL, "EditablePanel" )
