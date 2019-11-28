/*============================================================================================================================================
	Syntax handler for Golem editor
	Author: Oskar
============================================================================================================================================*/

Golem.Syntax = Golem.Syntax or { Colors = { } }
local Syntax = Golem.Syntax

local tLangList = { }
local tColorData = { }
local sSaveLocation = "golem-syntaxdata.txt"

if file.Exists( sSaveLocation,"DATA" ) then
	tColorData = util.JSONToTable( file.Read( sSaveLocation, "DATA" ) )
end

function Syntax:Update( )
	if Golem.Instance then
		Golem.Instance:UpdateSyntaxColors( )
	end
	
	file.Write( sSaveLocation, util.TableToJSON( tColorData, true ) )
end

function Syntax:SetColor( sName, sColor, cColor )
	if not tLangList[sName] then error( string.format( "Error tried to change color of unknown language %q", sName) ) end
	if not self.Colors[sName] then error( string.format( "Error tried to change color of language without color options %q", sName) ) end
	if not self.Colors[sName].Colors[sColor] then error( string.format( "Token %q does not exists in language %q", sColor, sName ) ) end
	
	cColor = cColor or self.Colors[sName].Defaults[sColor]
	
	tColorData[sName][sColor] = cColor
	self.Colors[sName].Colors[sColor] = cColor
	
	self:Update( )
end

function Syntax:GetColor( sName, sColor )
	if not tColorData[sName] or not tColorData[sName][sColor] then 
		ErrorNoHalt( string.format( "Tried to get invalid color %q from language %q", sColor, sName ) ) 
		return Color( 255, 255, 255, 255)
	end 
	return tColorData[sName][sColor]
end

function Syntax:Add( sName, tData )
	if tLangList[sName] then return ErrorNoHalt( string.format( "Syntax %q already created.\n", sName ) ) end
	tLangList[sName] = tData
	print( "Adding syntax:", sName )
end

function Syntax:Create( sName, dEditor )
	if not tLangList[sName] then error( "No syntax named " .. sName ) end
	local lang = setmetatable( { }, tLangList[sName] )
	
	lang:Init( dEditor )
	
	return lang
end

function Syntax:RegisterColors( sName, tColors )
	tColorData[sName] = tColorData[sName] or { }
	local defaults = { }
	
	for k, v in pairs( tColors ) do
		defaults[k] = Color( v.r, v.g, v.b )
		if tColorData[sName][k] then
			tColors[k] = Color( tColorData[sName][k].r, tColorData[sName][k].g, tColorData[sName][k].b )
		end
	end
	
	self.Colors[sName] = { Colors = tColors, Defaults = defaults }
end

local function command( pPly, sCommand, tArg, sArg )
	if tArg[1] == "color" and Syntax.Colors[tArg[2]] then
		if tArg[3] == "reset" then
			for token, data in pairs( Syntax.Colors[tArg[2]].Defaults ) do
				Syntax:SetColor( tArg[2], token, data )
				print( tArg[2], token, data )
			end
		else
			local r, g, b = string.match( tArg[4] or "", "(%d+)_(%d+)_(%d+)" )
			local def = Syntax.Colors[tArg[2]].Defaults[tArg[3]]

			Syntax:SetColor( tArg[2], tArg[3], Color( tonumber( r ) or def.r, tonumber( g ) or def.g, tonumber( b ) or def.b )  )
		end
	end
end

local tCommands = {
	-- "font_name",
	-- "font_size",
	"color",
}

-- TODO: Move font over to use this command
local function cmdhelp( sCommand, sArg )
	local tOut = { }
	sArg = string.TrimLeft( sArg )
	
	if sArg == "" then
		for i, name in ipairs( tCommands ) do
			tOut[#tOut+1] = sCommand .. " " .. name
		end
		return tOut
	end
	
	local tArg = string.Explode( "%s+", sArg, true )
	
	if tArg[1] == "color" then
		if tArg[2] and tArg[2] ~= "" then
			for name, data in pairs( Syntax.Colors ) do
				if name == tArg[2] then
					for token, color in pairs( data.Colors ) do
						if token == tArg[3] then
							tOut[#tOut+1] = sCommand .. " color " .. name .. " " .. token .. string.format( " %d_%d_%d", color.r, color.g, color.b )
						elseif string.StartWith( token, tArg[3] or "" ) then
							tOut[#tOut+1] = sCommand .. " color " .. name .. " " .. token
						end
					end
				elseif string.StartWith( name, tArg[2] ) then
					tOut[#tOut+1] = sCommand .. " color " .. name
				end
			end
		else
			for name, data in pairs( Syntax.Colors ) do
				tOut[#tOut+1] = sCommand .. " color " .. name
			end
		end
		
		return tOut
	-- elseif tArg[1] == "font_size" then
	-- elseif tArg[1] == "font_name" then
	end
	
	for i, name in ipairs( tCommands ) do
		if string.StartWith( string.lower( name ), tArg[1] ) then
			tOut[#tOut+1] = sCommand .. " " .. name
		end
	end
	
	return tOut
end

concommand.Add( "golem", command, cmdhelp, "Utility command for the Golem Editor", FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_SERVER_CANNOT_QUERY )