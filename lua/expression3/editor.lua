/*============================================================================================================================================
	Golem Editor
============================================================================================================================================*/

Golem = { }

if SERVER then
	return
end

function Golem.Init( )
	Golem.Reload( )
end

function Golem.Create( )
	if Golem.Instance then return end
	Golem.Instance = vgui.Create( "GOLEM_IDE" )
	Golem.Instance:SetText( "Expression 3 IDE - Golem" )
	Golem.Instance:SetIcon( "fugue/application-sidebar-list.png" ) // Keep or not to keep, that is the question.
	Golem.Instance:Open( )
	
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
	
	include( "expression3/editor/derma/autocomplete.lua" )
	include( "expression3/editor/derma/button.lua" )
	include( "expression3/editor/derma/checkbox.lua" )
	include( "expression3/editor/derma/closebutton.lua" )
	include( "expression3/editor/derma/colorselect.lua" )
	include( "expression3/editor/derma/console.lua" )
	-- include( "expression3/editor/derma/console2.lua" )
	include( "expression3/editor/derma/dhtml.lua" )
	include( "expression3/editor/derma/editor.lua" )
	include( "expression3/editor/derma/filebrowser.lua" )
	include( "expression3/editor/derma/filemenu.lua" )
	include( "expression3/editor/derma/findreplace.lua" )
	include( "expression3/editor/derma/frame.lua" )
	include( "expression3/editor/derma/hscrollbar.lua" )
	include( "expression3/editor/derma/ide.lua" )
	include( "expression3/editor/derma/imagebutton.lua" )
	include( "expression3/editor/derma/options.lua" )
	include( "expression3/editor/derma/options2.lua" )
	include( "expression3/editor/derma/propertysheet.lua" )
	include( "expression3/editor/derma/simpletabs.lua" )
	include( "expression3/editor/derma/textentry.lua" )
	include( "expression3/editor/derma/toolbar.lua" )
	include( "expression3/editor/derma/tree.lua" )
		
	include( "expression3/editor/derma/syntax.lua" ) 
	include( "expression3/editor/derma/syntax/syntax_e3.lua" )
	include( "expression3/editor/derma/syntax/syntax_lua.lua" )
	include( "expression3/editor/derma/syntax/syntax_console.lua" )
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
		return Golem.Instance:PrintLine(...)
	end
end

function Golem.AddRow(...)
	if Golem.Instance then
		return Golem.Instance:AddRow(...)
	end
end

function Golem.Warning(...)
	if Golem.Instance then
		return Golem.Instance:Warning(...)
	end
end

function Golem.Info(...)
	if Golem.Instance then
		return Golem.Instance:Info(...)
	end
end

function Golem.GetDirective( directive )
	if Golem.Instance then
		local code = Golem.Instance:GetCode( ) or ""
		
		if string.find( code, directive ) then
			code = string.Replace(code,";","\n")
			local lines = string.Explode( "\n", code )
			local i = 1
			
			while i < #lines do
				local line = string.Trim( lines[i] )
				
				if line == "" then
					i = i + 1
					continue
				end
				
				if string.match( line, "^/[/%*]") then
					if line[2] == "/" then
						i = i + 1
						continue
					else
						while i < #lines do
							if string.match( line, "%*/" ) then
								local _, p = string.find( line, "%*/" )
								line = string.Trim( string.sub( line, p+1 ) )
								break
							end
							
							line = string.Trim( lines[i] )
							i = i + 1
						end
						continue
					end
				end
				
				if line[1] == "@" then
					local dir = string.match( line, "@" .. directive .. [[ *(%b"")]] ) or string.match( line, "@" .. directive .. [[ *(%b'')]] )
					
					if dir then
						return string.sub( dir, 2, -2 )
					end
					
					i = i + 1
					continue
				end
				
				return
			end
		end
		
		return
	end
end

--[[
	Open Editor
]]

net.Receive("Expression3.OpenGolem", function() 
	local entity;
	
	if net.ReadBool() then entity = net.ReadEntity(); end
	
	Golem.Open();
	
	if IsValid(entity) and entity.script then
		Golem.Instance:NewTab("editor", entity.script, false, entity:GetScriptName() or "generic");
	end
end);
