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
	print( "Adding syntax:", sName )
end

function Syntax:Create( sName, dEditor )
	if not LangList[sName] then error( "No syntax named " .. sName ) end 
	local lang = setmetatable( { }, LangList[sName] )
	
	print( "Loading syntax:", sName )
	PrintTable( lang )
	
	lang:Init( dEditor )
	
	return lang
end

function Syntax:RegisterColors( sName, tColors )
	self.Colors[sName] = { sName, tColors } 
end

local function command( pPly, sCommand, tArg, sArg )
	
end

local function cmdhelp( sCommand, sArg )
	return { } 
end

concommand.Add( "golem", command, cmdhelp, "", FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_SERVER_CANNOT_QUERY )