/*============================================================================================================================================
	Golem Editor
============================================================================================================================================*/
Golem = { }

if SERVER then 
	-- AddCSLuaFile "editor/derma/syntaxer.lua"
	return 
end 

function Golem.Init( )
	Golem.Reload( ) 
end

function Golem.Create( )
	if Golem.Instance then return end 
	Golem.Instance = vgui.Create( "GOLEM_IDE" ) 
	Golem.Instance:SetText( "Expression Advanced 3 IDE - Golem" )
	Golem.Instance:SetIcon( "fugue/application-sidebar-list.png" ) // Keep or not to keep, that is the question.
	Golem.Instance:Open( )
	
	local function SyntaxColorLine( self, Row ) 
		local Tokens, Ok 
		
		Ok, Tokens = pcall( Golem.Syntaxer.Highlight, self, Row )
		
		if not Ok then 
			ErrorNoHalt( Tokens .. "\n" )
			Tokens = {{self.Rows[Row], Color(255,255,255)}} 
		end 
		
		return Tokens 
	end
	
	Golem.Instance:SetSyntaxColorLine( SyntaxColorLine )
	
	hook.Run( "Expression3.GolemInit" ) 
end

function Golem.Reload( )
	include( "expression3/editor/font.lua" )
	include( "expression3/editor/vector2.lua" )
	
	if Golem.Instance then 
		if ValidPanel( Golem.Instance ) then 
			Golem.Instance:Close( )
			Golem.Instance:Remove( )
		end
		Golem.Instance = nil
	end 
	
	
	include( "expression3/editor/derma/button.lua" )
	include( "expression3/editor/derma/closebutton.lua" )
	include( "expression3/editor/derma/editor.lua" )
	include( "expression3/editor/derma/dhtml.lua" )
	include( "expression3/editor/derma/filebrowser.lua" )
	include( "expression3/editor/derma/frame.lua" )
	include( "expression3/editor/derma/hscrollbar.lua" )
	include( "expression3/editor/derma/ide.lua" )
	include( "expression3/editor/derma/imagebutton.lua" )
	include( "expression3/editor/derma/options.lua" )
	include( "expression3/editor/derma/wiki.lua" )
	include( "expression3/editor/derma/propertysheet.lua" )
	include( "expression3/editor/derma/toolbar.lua" )
	include( "expression3/editor/derma/filemenu.lua" )
	
	include( "expression3/editor/derma/syntaxer.lua" )
end

function Golem.GetInstance( )
	Golem.Create( ) 
	return Golem.Instance 
end

function Golem.Open( sFile ) 
	if not Golem.Instance then Golem.Create( ) 
	else Golem.Instance:Open( ) end 
	
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

function Golem.Print(...)
	if Golem.Instance then 
		return Golem.Instance:AddPrintOut(...) 
	end 
end