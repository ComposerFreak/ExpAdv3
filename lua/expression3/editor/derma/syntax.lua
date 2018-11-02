/*============================================================================================================================================
	Syntax handler for Golem editor
	Author: Oskar
============================================================================================================================================*/

Golem.Syntax = Golem.Syntax or { Colors = { } }
local Syntax = Golem.Syntax

local LangList = { }

function Syntax:Add( sName, tData )
	if LangList[sName] then error( "Syntax already created." ) end 
	LangList[sName] = tData 
	-- print( "Adding syntax:", sName )
end

function Syntax:Create( sName, dEditor )
	if not LangList[sName] then error( "No syntax named " .. sName ) end 
	local lang = setmetatable( { }, LangList[sName] )
	
	-- print( "Loading syntax:", sName )
	
	lang:Init( dEditor )
	
	return lang
end

function Syntax:RegisterColors( sName, tColors )
	local defaults = {}
	
	for k,v in pairs( tColors ) do 
		defaults[k] = Color( v.r, v.g, v.b ) 
	end 
		
	self.Colors[sName] = { sName, tColors, defaults } 
end

local function command( pPly, sCommand, tArg, sArg )
	if tArg[1] == "font_name" then 
	elseif tArg[1] == "font_size" then 
	elseif tArg[1] == "color" then 
		if tArg[2] == "reset" then 
			print( "Reset" )
		end 
	end 
end

local function cmdhelp( sCommand, sArg )
	if sArg == "" or sArg == " " then return {"golem font_name", "golem font_size", "golem color"} end 
	if sArg == " color" then return {"golem color reset"} end 
	return { "golem" .. sArg } 
end

concommand.Add( "golem", command, cmdhelp, "", FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_SERVER_CANNOT_QUERY )