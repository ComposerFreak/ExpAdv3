/*
surface.CreateFont( "GOLEM_Fixedsys_17", {
	font = "Fixedsys",
	size = 17,
	weight = 400,
	antialias = false
} )
*/


-- surface.CreateFont( "Trebuchet24", { // Goddamit Garry!
-- 	font 		= "Trebuchet MS",
-- 	size 		= 24,
-- 	weight 		= 900,
-- 	blursize 	= 0,
-- 	scanlines 	= 0,
-- 	antialias 	= true,
-- 	underline 	= false,
-- 	italic 		= false,
-- 	strikeout 	= false,
-- 	symbol 		= false,
-- 	rotary 		= false,
-- 	shadow 		= false,
-- 	additive 	= false,
-- 	outline 	= false
-- } )

surface.CreateFont( "Trebuchet22", {
	font 		= "Trebuchet MS",
	size 		= 22,
	weight 		= 900,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= false,
	additive 	= false,
	outline 	= false
} )

surface.CreateFont( "Trebuchet20", {
	font 		= "Trebuchet MS",
	size 		= 20,
	weight 		= 900,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= false,
	additive 	= false,
	outline 	= false
} )


/*============================================================================================================================================
	Fonts
============================================================================================================================================*/
/** Windows
	
	Courier New
	DejaVu Sans Mono
	Consolas 
	Fixedsys
	Lucida Console
*/

/** Mac
	Monaco
*/

local Font = { sFontID = "Trebuchet24" }
Golem.Font = Font

table.Empty( cvars.GetConVarCallbacks( "golem_font_name", true ) ) 
table.Empty( cvars.GetConVarCallbacks( "golem_font_size", true ) ) 

CreateClientConVar( "golem_font_name", "Courier New", true, false ) 
CreateClientConVar( "golem_font_size", 16, true, false )

cvars.AddChangeCallback( "golem_font_name", function( sCVar, sOld, sNew ) Font:SetFont( sNew, GetConVarNumber( "golem_font_size" ), true ) end ) 
cvars.AddChangeCallback( "golem_font_size", function( sCVar, sOld, sNew ) Font:SetFont( GetConVarString( "golem_font_name" ), sNew, true ) end ) 

function Font:GetFont( )
	return self.sFontID
end

local CreatedFonts = { } 
local function CreateFont( sFont, nSize ) 
	local sFontID = "golem_" .. string.Replace( string.lower( sFont ), " ", "_" ) .. "_" .. nSize
	if not CreatedFonts[sFontID] then 
		surface.CreateFont( sFontID, { font = sFont, size = nSize, weight = 400 } )
		surface.CreateFont( sFontID .. "_bold", { font = sFont, size = nSize, weight = 800, antialias = false } )
		CreatedFonts[sFontID] = true 
	end 
	
	return sFontID
end 

// Override 
function Font:OnFontChange( ) end

function Font:SetFont( sFont, nSize, bConVar ) 
	sFont = sFont or GetConVarString( "golem_font_name" ) 
	nSize = tonumber(nSize) or GetConVarNumber( "golem_font_size" ) 
	
	if not bConVar then 
		if sFont ~= GetConVarString( "golem_font_name" ) then RunConsoleCommand( "golem_font_name", sFont ) end 
		if nSize ~= GetConVarNumber( "golem_font_size" ) then RunConsoleCommand( "golem_font_size", nSize ) end 
	end 
	
	self.sFontID = CreateFont( sFont, nSize )
	
	self:OnFontChange( self.sFontID, sFont, nSize )
end

function Font:ChangeFontSize( nInc, bAbs )
	return self:SetFont( nil, bAbs and nInc or GetConVarNumber( "golem_font_size" ) + nInc )
end

timer.Simple( 0, function( )
	-- Font.sFontID = CreateFont( GetConVarString( "golem_font_name" ), GetConVarString( "golem_font_size" ) )
	Font:SetFont( )
end )

