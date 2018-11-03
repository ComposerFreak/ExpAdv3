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

function Syntax:Add( sName, tData )
	if tLangList[sName] then return ErrorNoHalt( string.format( "Syntax %q already created.", sName ) ) end 
	tLangList[sName] = tData 
	print( "Adding syntax:", sName )
end

function Syntax:Create( sName, dEditor )
	if not tLangList[sName] then error( "No syntax named " .. sName ) end 
	local lang = setmetatable( { }, tLangList[sName] )
	
	print( "Loading syntax:", sName )
	
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
			-- print( tArg[2], tArg[3], Color( tonumber( r ) or def.r, tonumber( g ) or def.g, tonumber( b ) or def.b )  )
		end 
	end 
end

local tCommands = {
	-- "font_name",
	-- "font_size",
	"color",
}


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
				if string.StartWith( name, tArg[2] ) then 
					tOut[#tOut+1] = sCommand .. " color " .. name 
				end 
			end
		else
			for name, data in pairs( Syntax.Colors ) do
				tOut[#tOut+1] = sCommand .. " color " .. name 
			end
		end 
		
		
		/*if not tArg[2] or tArg[2] == "" then 
			for name, _ in pairs( Syntax.Colors ) do
				tOut[#tOut+1] = sCommand .. " color " .. name 
			end 
			
			-- tOut[#tOut+1] = sCommand .. " color reset"
		else 
			local sToken = string.lower( tArg[2] )
			
			for name, _ in pairs( Syntax.Colors ) do
				if string.StartWith( string.lower( name ), sToken ) then 
					if not tArg[3] then 
						-- for tokenname, color in pairs( Syntax.Colors[name].Colors ) do
						-- 	tOut[#tOut+1] = sCommand .. " color " .. name .. " " .. tokenname
						-- end
						
						
						-- tOut[#tOut+1] = sCommand .. " color " .. name .. " reset"
					elseif sToken == name:lower() then 
						local sColor = string.lower( tArg[3]  )
						
						for tokenname, color in pairs( Syntax.Colors[name].Colors ) do
							if string.lower( tokenname ) == sColor then 
								tOut[#tOut+1] = sCommand .. " color " .. name .. " " .. tokenname .. string.format( " %d_%d_%d", color.r, color.g, color.b )
							elseif string.StartWith( string.lower( tokenname ), sColor ) then 
								tOut[#tOut+1] = sCommand .. " color " .. name .. " " .. tokenname
							end 
						end
						
						if string.StartWith( "reset", sColor ) then 
							tOut[#tOut+1] = sCommand .. " color " .. name .. " reset"
						end 
					end 
				end 
			end
			
			-- if string.StartWith( "reset", sToken ) then 
			-- 	tOut[#tOut+1] = sCommand .. " color reset"
			-- end 
			
		end */
		
		return tOut
	-- elseif tArg[1] == "font_size" then 
	-- elseif tArg[1] == "font_name" then 
	end 
	
	for i, name in ipairs( tCommands ) do
		if string.StartWith( string.lower( name ), tArg[1] ) then 
			tOut[#tOut+1] = sCommand .. " " .. name 
		end 
	end
	
	
	return tOut //{ sCommand .. " " .. sArg } 
end

concommand.Add( "golem", command, cmdhelp, "Utility command for the Golem Editor", FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_SERVER_CANNOT_QUERY )