/*============================================================================================================================================
	Golem Editor
============================================================================================================================================*/
Golem = { }

if SERVER then 
	AddCSLuaFile( ) 
	
	AddCSLuaFile( "editor/font.lua" )
	AddCSLuaFile( "editor/vector2.lua" )
	
	AddCSLuaFile( "editor/derma/button.lua" )
	AddCSLuaFile( "editor/derma/closebutton.lua" )
	AddCSLuaFile( "editor/derma/editor.lua" )
	AddCSLuaFile( "editor/derma/filebrowser.lua" )
	AddCSLuaFile( "editor/derma/frame.lua" )
	AddCSLuaFile( "editor/derma/hscrollbar.lua" )
	AddCSLuaFile( "editor/derma/ide.lua" )
	AddCSLuaFile( "editor/derma/imagebutton.lua" )
	AddCSLuaFile( "editor/derma/options.lua" )
	AddCSLuaFile( "editor/derma/propertysheet.lua" )
	AddCSLuaFile( "editor/derma/toolbar.lua" )
	
	-- AddCSLuaFile "editor/derma/syntaxer.lua"
	return 
end 

function Golem.Init( )
	self:Reload( ) 
end

function Golem.Create( )
	if Golem.Instance then return end 
	Golem.Instance = vgui.Create( "GOLEM_IDE" ) 
	Golem.Instance:SetText( "Expression Advanced 3 IDE - Golem" )
	Golem.Instance:SetIcon( "fugue/application-sidebar-list.png" ) // Keep or not to keep, that is the question.
	Golem.Instance:MakePopup( ) 
end

function Golem.Reload( )
	include( "editor/font.lua" )
	include( "editor/vector2.lua" )
	
	if Golem.Instance and ValidPanel( Golem.Instance ) then 
		Golem.Instance:Close( )
		Golem.Instance:Remove( )
		Golem.Instance = nil
	end 
	
	include( "editor/derma/button.lua" )
	include( "editor/derma/closebutton.lua" )
	include( "editor/derma/editor.lua" )
	include( "editor/derma/filebrowser.lua" )
	include( "editor/derma/frame.lua" )
	include( "editor/derma/hscrollbar.lua" )
	include( "editor/derma/ide.lua" )
	include( "editor/derma/imagebutton.lua" )
	include( "editor/derma/options.lua" )
	include( "editor/derma/propertysheet.lua" )
	include( "editor/derma/toolbar.lua" )
	
	-- include "editor/derma/syntaxer.lua"
end

function Golem.Open( sFile ) 
	Golem.Create( ) 
	if sFile then 
		Golem.Instance:LoadFile( sFile )
	end 
end 

function Golem.GetCode( )
	if Golem.Instance then 
		return Golem.Instance:GetCode( ) 
	end 
end

function Golem.Validate( sCode ) 
	if Golem.Instance then
		return Golem.Instance:DoValidate( false, sCode )
	end
end 
