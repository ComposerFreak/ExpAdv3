--[[============================================================================================================================================
	Custom color schemes for Golem editor
	Author: Oskar
============================================================================================================================================]]

local Style = { sActiveStyle = "dark" }
Golem.Style = Style 

local tStyleData = { }
local sSaveLocation = "golem-styledata.txt"

if file.Exists( sSaveLocation, "DATA" ) then
	tStyleData = util.JSONToTable( file.Read( sSaveLocation, "DATA" ) )
else
	tStyleData["dark"] = {
		["main-bg"] 			= Color( 100, 100, 100, 255 ),
		["main-bg-g"] 			= Color( 80, 80, 80, 255 ),
		["main-tt"] 			= Color( 240, 240, 240, 255 ),
		
		["toolbar-bg"] 			= Color( 70, 70, 70, 255 ),
		["toolbar-btn"] 		= Color( 70, 70, 70, 255 ),
		
		["editor-bg"] 			= Color( 0, 0, 0, 255 ),
		["editor-side-bg"] 		= Color( 32, 32, 32, 255 ),
		["editor-side-idx"] 	= Color( 255, 255, 255, 255 ),
		["editor-caret"] 		= Color( 240, 240, 240, 255 ),
		["editor-status"] 		= Color( 50, 50, 50, 100 ),
		["editor-status-txt"] 	= Color( 235, 235, 235, 255 ),
		
		["options-bg"] 			= Color( 30, 30, 30, 255 ),
		
		["tab-bg"] 				= Color( 100, 100, 100, 255 ),
		["tab-bg-active"] 		= Color( 20, 20, 20, 255 ),
		["tab-txt"] 			= Color( 255, 255, 255, 255 ),
	}
	
	tStyleData["blue"] = {
		["main-bg"] 			= Color( 60, 100, 180, 255 ),
		["main-bg-g"] 			= Color( 40, 80, 160, 255 ),
		["main-tt"] 			= Color( 240, 240, 240, 255 ),
		
		["toolbar-bg"] 			= Color( 40, 80, 160, 255 ),
		["toolbar-btn"] 		= Color( 40, 80, 160, 255 ),
		
		["editor-bg"] 			= Color( 0, 0, 0, 255 ),
		["editor-side-bg"] 		= Color( 32, 32, 32, 255 ),
		["editor-side-idx"] 	= Color( 255, 255, 255, 255 ),
		["editor-caret"] 		= Color( 240, 240, 240, 255 ),
		["editor-status"] 		= Color( 50, 50, 50, 100 ),
		["editor-status-txt"] 	= Color( 235, 235, 235, 255 ),
		
		["options-bg"] 			= Color( 20, 30, 40, 255 ),
		
		["tab-bg"] 				= Color( 80, 100, 120, 255 ),
		["tab-bg-active"] 		= Color( 20, 40, 60, 255 ),
		["tab-txt"] 			= Color( 255, 255, 255, 255 ),
	}
	
	tStyleData["light"] = {
		["main-bg"] 			= Color( 220, 220, 220, 255 ),
		["main-bg-g"] 			= Color( 200, 200, 200, 255 ),
		["main-tt"] 			= Color( 60, 60, 60, 255 ),
		
		["toolbar-bg"] 			= Color( 180, 180, 180, 255 ),
		["toolbar-btn"] 		= Color( 180, 180, 180, 255 ),
		
		["editor-bg"] 			= Color( 255, 255, 255, 255 ),
		["editor-side-bg"] 		= Color( 240, 240, 240, 255 ),
		["editor-side-idx"] 	= Color( 0, 0, 0, 255 ),
		["editor-caret"] 		= Color( 0, 0, 0, 255 ),
		["editor-status"] 		= Color( 50, 50, 50, 100 ),
		["editor-status-txt"] 	= Color( 50, 50, 50, 255 ),
		
		["options-bg"] 			= Color( 240, 240, 240, 255 ),
		
		["tab-bg"] 				= Color( 220, 220, 220, 255 ),
		["tab-bg-active"] 		= Color( 130, 130, 130, 255 ),
		["tab-txt"] 			= Color( 0, 0, 0, 255 ),
	}
	
	-- file.Write( sSaveLocation, util.TableToJSON( tStyleData, true ) )
end

function Style:GetStyles( )
	return table.GetKeys( tStyleData )
end

function Style:SetActiveStyle( sName )
	if not tStyleData[sName] then error( string.format( "[GOLEM][Style] Tried to change active style to invalid style %q", sName) ) end
	self.sActiveStyle = sName
end

local c_white = Color(255, 255, 255, 255)
function Style:GetColor( sName, bColor )
	local tActiveStyle = tStyleData[self.sActiveStyle]
	
	if not tActiveStyle[sName] then 
		ErrorNoHalt( string.format( "[GOLEM][Style] Tried to get invalid color %q", sName or "" ) ) 
		if bColor then return c_white else return 255, 255, 255, 255 end 
	end 
	
	if bColor then return tActiveStyle[sName] else return tActiveStyle[sName].r,tActiveStyle[sName].g,tActiveStyle[sName].b,tActiveStyle[sName].a end 
end