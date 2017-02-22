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
		currentIndex = value
		-- print(index,value,data)
		Mixer:SetColor( Color( r, g, b ) ) 
	end
	
	for k, v in pairs( Golem.Syntaxer.ColorConvars ) do
		syntaxColor:AddChoice( k, v, k=="variable" )
	end
	
	function Mixer:ValueChanged( color )
		RunConsoleCommand( "golem_editor_color_" .. currentIndex, color.r .. "_" .. color.g .. "_" .. color.b )
		Golem.Syntaxer:UpdateSyntaxColors( )
	end
	
	
	local reset = vgui.Create( "DButton" ) 
		reset:SetText( "Reset color" ) 
	
	function reset:DoClick( )
		RunConsoleCommand( "golem_editor_resetcolors", currentIndex ) 
		timer.Simple( 0, function() 
			local r, g, b = string.match( Golem.Syntaxer.ColorConvars[currentIndex]:GetString( ), "(%d+)_(%d+)_(%d+)" ) 
			Mixer:SetColor( Color( r, g, b ) ) 
		end )
	end
	
	local resetall = vgui.Create( "DButton" ) 
		resetall:SetText( "Reset all colors" ) 
	
	function resetall:DoClick( )
		RunConsoleCommand( "golem_editor_resetcolors", "1" ) 
		timer.Simple( 0, function() 
			local r, g, b = string.match( Golem.Syntaxer.ColorConvars[currentIndex]:GetString( ), "(%d+)_(%d+)_(%d+)" ) 
			Mixer:SetColor( Color( r, g, b ) ) 
		end )
	end
	
	
	local ResetDivider = self:Add( "DHorizontalDivider" ) 
	self.ResetDivider = ResetDivider
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
	self.FontDivider = FontDivider
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

function PANEL:PerformLayout( )
	self.ResetDivider:SetLeftWidth( 120 )
	self.FontDivider:SetLeftWidth( 200 )
end

vgui.Register( "GOLEM_Options", PANEL, "EditablePanel" )
