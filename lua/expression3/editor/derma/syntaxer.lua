/*============================================================================================================================================
	Expression 3 Syntax Highlighting
	Autor: Oskar
	Credits: The authors of the E2 syntax highlighter 
============================================================================================================================================*/

Golem.Syntaxer = Golem.Syntaxer or { First = true } 
local Syntaxer = Golem.Syntaxer
Syntaxer.First = true

/********************************************************************************************************************************************/

local tonumber, pairs, Color = tonumber, pairs, Color 

local table_concat = table.concat 
local string_find = string.find 
local string_gmatch = string.gmatch 
local string_gsub = string.gsub 
local string_match = string.match 
local string_sub = string.sub 

/*============================================================================================================================================
Build Syntaxer Tables
============================================================================================================================================*/
function Syntaxer:BuildFunctionTable( )
	local Functions = { }
	
	for sName, tData in pairs( EXPR_LIBRARIES ) do
		if tData._functions then 
			for _, tFunc in pairs( tData._functions ) do
				Functions[tFunc.name] = true
			end
		end 
	end
	
	self.Functions = Functions
end

function Syntaxer:BuildTokensTable( ) 
	local Tokens = { } 
	
	for k,v in pairs( EXPR_TOKENS.EXPADV ) do
		Tokens[#Tokens+1] = string_gsub( v[1], "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
	end
	
	self.Tokens = Tokens 
end 

function Syntaxer.Rebuild( )
	if EXPADV.IsLoaded then
		Syntaxer:BuildFunctionTable( )
		Syntaxer:BuildTokensTable( )
		Syntaxer.UserFunctions = { } 
		-- Syntaxer.UserDirective = { } 
		Syntaxer.Variables = { } 
		-- Syntaxer.MetaMethods = { }
	end
end

Syntaxer.Rebuild( ) -- For the editor reload command
hook.Add( "Expression3.LoadGolem", "Expression3", Syntaxer.Rebuild )

/*============================================================================================================================================
Syntaxer Functions
============================================================================================================================================*/
local function istype( word )
	return EXPR_LIB.GetClass( word ) and true or false
end

local function isvar( word, row )
	return (Syntaxer.Variables[word] and (row and Syntaxer.Variables[word] <= row or true)) and true or false 
	-- return Syntaxer.Variables[word] and true or false 
end

function Syntaxer:ResetTokenizer( Row )
	self.nPosition = 0
	self.sChar = ""
	self.sTokenData = ""
	self.bBlockComment = nil
	self.bMultilineString = nil
	local singlelinecomment = false
	local singlelinestring = false 
	
	local tmp = self.Editor:ExpandAll( )
	self.sLine = self.Editor.Rows[Row] //.. " "
	local str = string_gsub( table_concat( self.Editor.Rows, "\n", self.Editor.Scroll.x, Row-1 ), "\r", "" )
	self.Editor:FoldAll( tmp )
	
	for before, char, after in string_gmatch( str, "()([/'\"\n])()" ) do
		local before = string_sub( str, before - 1, before - 1  )
		local after = string_sub( str, after, after )
		if not self.bBlockComment and not self.bMultilineString and not singlelinecomment and not singlelinestring then
			if char == "'" and before ~= "\\" then 
				self.bMultilineString = true 
			elseif char == "\"" and before ~= "\\" then 
				singlelinestring = true 
			elseif char == "/" then 
				if after == "*" then
					self.bBlockComment = true
				elseif after == "/" then 
					singlelinecomment = true 
				end 
			end
		elseif self.bMultilineString and before ~= "\\" then
			self.bMultilineString = nil
		elseif singlelinestring and before ~= "\\" then
			singlelinestring = nil
		elseif self.bBlockComment and char == "/" and before == "*" then
			self.bBlockComment = nil
		elseif singlelinecomment and char == "\n" then
			singlelinecomment = false
		end
	end
	
	-- self.MetaMethods = { }
	
	for Function, Line in pairs( self.UserFunctions ) do
		if Line == Row then
			self.UserFunctions[Function] = nil
		end
	end
	
	-- for Directive, Line in pairs( self.UserDirective ) do
	-- 	if Line == Row then
	-- 		self.UserDirective[Directive] = nil
	-- 	end
	-- end
	
	for Variables, Line in pairs( self.Variables ) do
		if Line == Row then
			self.Variables[Variables] = nil
		end
	end
	
	for sType, sVar in string_gmatch( str, "([a-zA-Z][a-zA-Z0-9_]*) +([a-zA-Z][a-zA-Z0-9_]*)" ) do 
		if istype( sType ) then 
			self.Variables[sVar] = 0
		end 
	end 
end

function Syntaxer:NextCharacter( )
	if not self.sChar then return end

	self.sTokenData = self.sTokenData .. self.sChar
	self.nPosition = self.nPosition + 1

	if self.nPosition <= #self.sLine then
		self.sChar = self.sLine[self.nPosition]
		-- PrintTableGrep{ ["NEXTCHAR"] = { Position = self.nPosition, Line = self.sLine, Char = self.sChar, Token = self.sTokenData } }
	else
		self.sChar = nil
	end
end

function Syntaxer:NextPattern( sPattern, bSkip )
	if not self.sChar then return false end
	local startpos, endpos, text = string_find( self.sLine, sPattern, self.nPosition  )
	
	if startpos ~= self.nPosition then return false end 
	text = text or string_sub( self.sLine, startpos, endpos ) 
	-- PrintTableGrep{ ["NEXTPATTERN"] = { Substr = self.sLine:sub(self.nPosition), Position = self.nPosition, Start = startpos, End = endpos, Pattern = sPattern, Line = self.sLine, Char = self.sChar, Token = self.sTokenData, Data = text } }
	
	if not bSkip then 
		self.sTokenData = self.sTokenData .. text
	end 
	
	self.nPosition = endpos + 1
	if self.nPosition <= #self.sLine then
		self.sChar = self.sLine[self.nPosition]
	else
		self.sChar = nil
	end
	
	return bSkip and text or true 
end

/*============================================================================================================================================
Syntaxer Keywords
============================================================================================================================================*/

-- operator_<key>
-- local MetaMethods = {
-- 	["addition"] = true, 
-- 	["call"] = true, 
-- 	["division"] = true, 
-- 	["equal"] = true, 
-- 	["exponent"] = true, 
-- 	["greater"] = true, 
-- 	["modulus"] = true, 
-- 	["multiply"] = true, 
-- 	["subtraction"] = true, 
-- }


local keywords = {
	-- keywords that can be followed by a "(":
	["if"]       = { true, true }, 
	["elseif"]   = { true, true }, 
	["while"]    = { true, true }, 
	["for"]      = { true, true }, 
	["foreach"]  = { true, true }, 
	-- ["try"]      = { true, true }, 
	-- ["catch"]    = { true, true }, 
	-- ["final"]    = { true, true }, 
	
	-- keywords that cannot be followed by a "(":
	["else"]     = { true, false },
	["delegate"] = { true, false },
	["break"]    = { true, false },
	["continue"] = { true, false },
	["return"]   = { true, false },
	["global"]   = { true, false },
	["true"]     = { true, false },
	["false"]    = { true, false },
	["void"]     = { true, false },
	["new"]      = { true, false },
	["client"]   = { true, false },
	["server"]   = { true, false },
	-- ["static"]   = { true, false },
	-- ["input"]    = { true, false },
	-- ["output"]   = { true, false },
	-- ["event"]    = { true, false },
	-- ["method"]   = { true, false },
}

-- fallback for nonexistant entries:
setmetatable( keywords, { __index = function( tbl, index ) return { } end } )

/*============================================================================================================================================
Default Color Configeration
============================================================================================================================================*/
/*
	"wire_expression2_editor_color_comment"			"128_128_128"
	"wire_expression2_editor_color_constant"		"140_200_50"
	"wire_expression2_editor_color_directive"		"100_200_255"
	"wire_expression2_editor_color_function"		"80_160_240"
	"wire_expression2_editor_color_keyword"			"0_120_240"
	"wire_expression2_editor_color_notfound"		"240_160_0"
	"wire_expression2_editor_color_number"			"0_200_0"
	"wire_expression2_editor_color_operator"		"255_0_0"
	"wire_expression2_editor_color_ppcommand"		"255_255_255"
	"wire_expression2_editor_color_string"			"100_50_200"
	"wire_expression2_editor_color_typename"		"80_160_240"
	"wire_expression2_editor_color_userfunction"	"102_122_102"
	"wire_expression2_editor_color_variable"		"0_180_80"


	wire_expression2_editor_color_comment 128_128_128;wire_expression2_editor_color_constant 140_200_50;wire_expression2_editor_color_directive 100_200_255;wire_expression2_editor_color_function 80_160_240;wire_expression2_editor_color_keyword 0_120_240;
	wire_expression2_editor_color_notfound 240_160_0;wire_expression2_editor_color_number 0_200_0;wire_expression2_editor_color_operator 255_0_0;wire_expression2_editor_color_ppcommand 255_255_255;wire_expression2_editor_color_string 100_50_200;
	wire_expression2_editor_color_typename 80_160_240;wire_expression2_editor_color_userfunction 102_122_102;wire_expression2_editor_color_variable 0_180_80
*/

/*============================================================================================================================================
Syntaxer Colors
============================================================================================================================================*/
local colors = { 
	/* TODO: 
		Make propper color scheme 
		Add syntax color options 
	*/
	
	["comment"]      = Color( 128, 128, 128 ), 
	-- ["event"]        = Color(  80, 160, 240 ), // TODO: Other color? 
	-- ["exception"]    = Color(  80, 160, 240 ), // TODO: Other color? 
	["function"]     = Color(  80, 160, 240 ), 
	["keyword"]      = Color(   0, 120, 240 ), 
	["notfound"]     = Color( 240, 160,   0 ), 
	["number"]       = Color(   0, 200,   0 ), 
	["operator"]     = Color( 240,   0,   0 ), 
	["string"]       = Color( 188, 188, 188 ), 
	["typename"]     = Color( 140, 200,  50 ), 
	["userfunction"] = Color( 102, 122, 102 ), 
	["variable"]     = Color(   0, 180,  80 ), 
	["directive"]    = Color(  89, 135, 126 ),  
	["prediction"]   = Color( 0xe3, 0xb5, 0x2d ), 
	["metamethod"]   = Color( 0x00, 0xc8, 0xff ),
}

-- fallback for nonexistant entries: 
setmetatable( colors, { __index = function( tbl, index ) return Color( 255, 255, 255 ) end } ) 

/*============================================================================================================================================
Syntaxer Colors options.
============================================================================================================================================*/
local colors_defaults = { }
local colors_convars = { }

function Syntaxer:UpdateSyntaxColors( bNoUpdate )
	for k,v in pairs( colors_convars ) do
		local r, g, b = string_match( v:GetString( ), "(%d+)_(%d+)_(%d+)" )
		local def = colors_defaults[k]
		colors[k] = Color( tonumber( r ) or def.r, tonumber( g ) or def.g, tonumber( b ) or def.b )
	end 
	
	if not bNoUpdate and Syntaxer.Editor then 
		Syntaxer.Editor:UpdateSyntaxColors( ) 
	end 
end 

function Syntaxer.UpdateSyntaxColor( sCVar, sOld, sNew ) 
	local cvar = string_match( sCVar, ".+_(.+)$" ) 
	local r, g, b = string_match( sNew, "(%d+)_(%d+)_(%d+)" )
	local def = colors_defaults[cvar]
	colors[cvar] = Color( tonumber( r ) or def.r, tonumber( g ) or def.g, tonumber( b ) or def.b )
	
	if Syntaxer.Editor then 
		Syntaxer.Editor:UpdateSyntaxColors( ) 
	end 
end 

local norun = false 
function Syntaxer.ResetSyntaxColor( sCVar, sOld, sNew ) 
	if not norun and sNew ~= "0" then 
		norun = true
		RunConsoleCommand( "golem_editor_resetcolors", "0" ) 
		norun = false
		
		if colors_defaults[sNew] then 
			RunConsoleCommand( "golem_editor_color_" .. sNew, colors_defaults[sNew].r .. "_" .. colors_defaults[sNew].g .. "_" .. colors_defaults[sNew].b )
		else 
			for k, v in pairs( colors_defaults ) do
				RunConsoleCommand( "golem_editor_color_" .. k, v.r .. "_" .. v.g .. "_" .. v.b )
			end 
		end 
		
		Syntaxer.UpdateSyntaxColors( ) 
	end 
end 

if Syntaxer.First then 
	table.Empty( cvars.GetConVarCallbacks( "golem_editor_resetcolors", true ) ) 
	
	CreateClientConVar( "golem_editor_resetcolors", "0", true, false ) 
	cvars.AddChangeCallback( "golem_editor_resetcolors", function(...) Syntaxer.ResetSyntaxColor(...) end ) 
end 

for k,v in pairs( colors ) do 
	colors_defaults[k] = Color( v.r, v.g, v.b ) -- Copy to save defaults
	colors_convars[k] = CreateClientConVar( "golem_editor_color_" .. k, v.r .. "_" .. v.g .. "_" .. v.b, true, false ) 
	
	if Syntaxer.First then 
		table.Empty( cvars.GetConVarCallbacks( "golem_editor_color_" .. k, true ) ) 
		
		cvars.AddChangeCallback( "golem_editor_color_" .. k, function(...) Syntaxer.UpdateSyntaxColor(...) end ) 
	end 
end 

Syntaxer.First = nil 

Syntaxer:UpdateSyntaxColors( true )
Syntaxer.ColorConvars = colors_convars

/*============================================================================================================================================
Syntaxer Highlighting.
============================================================================================================================================*/
local tOutput, tLastColor = { } 

function Syntaxer:AddToken( sTokenName, sTokenData )
	local color = colors[sTokenName]
	if not sTokenData then 
		sTokenData = self.sTokenData 
		self.sTokenData = ""
	end 
		
	if tLastColor and color == tLastColor[2] then
		tLastColor[1] = tLastColor[1] .. sTokenData
	else
		tOutput[#tOutput + 1] = { sTokenData, color }
		tLastColor = tOutput[#tOutput]
	end
	
	-- print( "ADDTOKEN", sTokenName, string.format( "%q", sTokenData ) )
end

function Syntaxer:InfProtect( nRow )
	self.nLoops = self.nLoops + 1
	if SysTime( ) > self.nExpire then 
		ErrorNoHalt( "Code on line " .. nRow .. " took to long to parse (" .. self.nLoops .. ")\n" )
		return false 
	end
	return true 
end

function Syntaxer:AddUserFunction( nRow, sName ) 
	if self.Functions[sName] then return end  
	self.UserFunctions[sName] = nRow
end 

-- function Syntaxer:CreateMethodFunction( nRow, sVarName, sFunctionName ) 
-- 	self.MetaMethods[sVarName] = self.MetaMethods[sVarName] or {} 
-- 	self.MetaMethods[sVarName][sFunctionName] = true 
-- end 

-- function Syntaxer:AddUserDirective( nRow, sName ) 
-- 	self.UserDirective[sName] = nRow 
-- end 

function Syntaxer:Parse( nRow )
	tOutput, tLastColor = { }, nil 
	
	self.nLoops = 0 
	self.nExpire = SysTime( ) + 0.1 
	
	self:ResetTokenizer( nRow )
	self:NextCharacter( )
	
	if self.bBlockComment then
		if self:NextPattern( ".-%*/" ) then
			self.bBlockComment = nil
		else
			self:NextPattern( ".*" )
		end
		
		self:AddToken( "comment" )
	elseif self.bMultilineString then
		while self.sChar do -- Find the ending '
			if self.sChar == "'" then
				self.bMultilineString = nil
				self:NextCharacter( )
				break
			end
			if self.sChar == "\\" then self:NextCharacter( ) end
			self:NextCharacter( )
		end
		
		self:AddToken( "string" )
	end
	
	while self.sChar and self:InfProtect( nRow ) do
		local spaces = self:NextPattern( " *", true ) 
		if spaces and spaces ~= "" then self:AddToken( "operator", spaces ) end 
		if not self.sChar then break end 
		
		if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then 
			local word = self.sTokenData 
			local keyword = ( self.sChar or "" ) != "(" 
			
			if word == "function" then 
				self:NextPattern( " *" ) 
				
				if self.sChar == "]" then 
					self:AddToken( "typename" ) 
					continue 
				elseif self.sChar == "(" then 
					self:AddToken( "keyword" ) 
					continue 
				end 
				
				if string_match( self.sLine, "^[a-zA-Z][a-zA-Z0-9_]* *=", self.nPosition ) then 
					self:AddToken( "typename" ) 
					self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) 
					self:AddUserFunction( nRow, self.sTokenData ) 
					self:AddToken( "userfunction" )
					continue 
				end 
				
				self:AddToken( "keyword" ) 
				
				if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]* *" ) then 
					self:AddToken( "typename" ) 
				end 
				
				if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then 
					self:AddUserFunction( nRow, self.sTokenData )
					self:AddToken( "userfunction" ) 
				end 
				
				self:NextPattern( " *%( *" ) 
				self:AddToken( "operator" )
				
				while self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) do 
					if istype( self.sTokenData ) then 
						self:AddToken( "typename" )
					else 
						self:AddToken( "notfound" )
					end 
					
					self:NextPattern( " *" )
					self:AddToken( "operator" )
					
					self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" )
					self.Variables[self.sTokenData] = nRow 
					self:AddToken( "variable" ) 
					
					if not self:NextPattern( " *, *" ) then break end 
					self:AddToken( "operator" ) 
				end 
				
				continue 
			end 
			
			if istype( word ) and keyword then 
				self:AddToken( "typename" )
				self:NextPattern( " *" ) 
				self:AddToken( "operator" )
				
				while self:NextPattern( "([a-zA-Z][a-zA-Z0-9_]*)" ) do 
					self.Variables[self.sTokenData] = nRow 
					self:AddToken( "variable" ) 
					
					if not self:NextPattern( " *, *" ) then break end 
					self:AddToken( "operator" ) 
				end
				
				continue 
			end 
			
			-- if word == "event" then 
			-- 	self:NextPattern( " *" ) 
			-- 	self:AddToken( "keyword" )
				
			-- 	self:NextPattern( "^[a-z][a-zA-Z0-9_]*" ) 
			-- 	if self.Events[self.sTokenData] then 
			-- 		self:AddToken( "event" )
			-- 	else 
			-- 		self:AddToken( "notfound" )
			-- 	end 
				
			-- 	self:NextPattern( " *%( *" ) 
			-- 	self:AddToken( "operator" )
				
			-- 	while self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) do 
			-- 		if istype( self.sTokenData ) then 
			-- 			self:AddToken( "typename" )
			-- 		else 
			-- 			self:AddToken( "notfound" ) 
			-- 		end 
					
			-- 		self:NextPattern( " *" )
			-- 		self:AddToken( "operator" )
					
			-- 		self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" )
			-- 		self.Variables[self.sTokenData] = nRow 
			-- 		self:AddToken( "variable" )
					
			-- 		if not self:NextPattern( " *, *" ) then break end 
			-- 		self:AddToken( "operator" )
			-- 	end 
				
			-- 	continue 
			-- end 
			
			-- if word == "catch" then 
			-- 	self:NextPattern( " *" ) 
			-- 	self:AddToken( "keyword" )
				
			-- 	if self:NextPattern( "%(" ) then 
			-- 		self:NextPattern( " *" ) 
			-- 		self:AddToken( "operator" )
					
			-- 		if self:NextPattern( "[a-z0-9]+" ) then 
			-- 			local exception = self.sTokenData 
			-- 			self:NextPattern( " *" ) 
						
			-- 			if EXPADV.Exceptions[ exception ] then 
			-- 				self:AddToken( "exception" )
			-- 			else 
			-- 				self:AddToken( "notfound" )
			-- 			end 
						
			-- 			self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) 
			-- 			self.Variables[self.sTokenData] = nRow 
			-- 			self:AddToken( "variable" ) 
			-- 		end 
			-- 	end 
				
			-- 	continue 
			-- end 
			
			-- if word == "method" then 
			-- 	self:NextPattern( " *" ) 
			-- 	self:AddToken( "keyword" )
				
			-- 	if self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) then 
			-- 		if isvar( self.sTokenData ) then 
			-- 			local MethodVar = self.sTokenData 
			-- 			self:AddToken( "variable" )
			-- 			self:NextPattern( " *: *" ) 
			-- 			self:AddToken( "operator" )
						
			-- 			if self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) then 
			-- 				if MetaMethods[string_match( self.sTokenData, "operator_(.*)" )] then 
			-- 					self:AddToken( "metamethod" )
			-- 				else 
			-- 					self:AddToken( "userfunction" )
			-- 					self:CreateMethodFunction( nRow, MethodVar, self.sTokenData )
			-- 				end 
			-- 			end 
			-- 		else 
			-- 			self:AddToken( "notfound" )
			-- 		end 
			-- 	end 
				
			-- 	continue
			-- end 
			
			if keywords[word][1] then 
				if keywords[word][2] then 
					self:AddToken( "keyword" ) 
					continue 
				elseif keyword then 
					self:AddToken( "keyword" ) 
					continue 
				end 
			end 
			
			if self.Functions[self.sTokenData] then 
				self:AddToken( "function" )
				continue 
			end 
			
			if self.UserFunctions[self.sTokenData] and self.UserFunctions[self.sTokenData] <= nRow then 
				self:AddToken( "userfunction" ) 
				continue 
			end 
			
			-- if self.UserDirective[self.sTokenData] and self.UserDirective[self.sTokenData] <= nRow then 
			-- 	self:AddToken( "directive" ) 
			-- 	continue 
			-- end 
			
			if isvar( word ) then 
				self:AddToken( "variable" )
				
				if self:NextPattern( " *%. *" ) then 
					self:AddToken( "operator" )
					
					if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then 
						self:AddToken( "function" )
					end 
				elseif self:NextPattern( " *: *" ) then 
					self:AddToken( "operator" )
					
					if string_match( self.sLine, "^[a-zA-Z][a-zA-Z0-9_]*", self.nPosition ) then 
						local func = string_match( self.sLine, "^[a-zA-Z][a-zA-Z0-9_]*", self.nPosition )
						if self.MetaMethods[word] and self.MetaMethods[word][func] then 
							self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" )
							self:AddToken( "userfunction" )
						end 
					end 
				end
				continue 
			end 
			
			self:AddToken( "notfound" )
			continue 
		-- elseif self:NextPattern( "^@[a-zA-Z][a-zA-Z0-9_]*" ) then 
		-- 	if EXPADV.Directives[string_sub( self.sTokenData, 2 )] then 
		-- 		self:AddToken( "directive" )
				
		-- 		if self:NextPattern( " *: *" ) then 
		-- 			self:AddToken( "operator" ) 
		-- 			if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then 
		-- 				self:AddUserDirective( nRow, self.sTokenData )
		-- 				self:AddToken( "variable" ) 
		-- 			end 
		-- 		end 
				
		-- 		continue 
		-- 	end 
		-- 	self:AddToken( "notfound" )
		elseif self:NextPattern( "^0[xb][%x]+" ) then 
			self:AddToken( "number" )
		elseif self:NextPattern( "^[%d][%d%.e]*" ) then 
			self:AddToken( "number" )
		elseif self.sChar == "'" then
			self:NextCharacter( )
			self.bMultilineString = true 
			
			while self.sChar do 
				if self.sChar == "'" then
					self.bMultilineString = false 
					break
				end
				if self.sChar == "\\" then self:NextCharacter( ) end
				self:NextCharacter( )
			end
			
			self:AddToken( "string" ) 
		elseif self.sChar == '"' then 
			self:NextCharacter( )
			
			while self.sChar do 
				if self.sChar == '"' then break end
				if self.sChar == "\\" then self:NextCharacter( ) end
				self:NextCharacter( )
			end
			
			self:NextCharacter( ) 
			self:AddToken( "string" ) 
		elseif self.sChar == "/" then 
			self:NextCharacter( ) 
			
			if self.sChar == "*" then // Multiline comment 
				self.bBlockComment = true
				while self.sChar do 
					if self.sChar == "*" then 
						self:NextCharacter( ) 
						if self.sChar == "/" then 
							self:NextCharacter( ) 
							self:AddToken( "comment" ) 
							self.bBlockComment = false
							break 
						end 
					end 
					
					self:NextCharacter( ) 
				end 	
				self:AddToken( "comment" ) 
			elseif self.sChar == "/" then // Singleline comment
				self:NextPattern( ".*" )
				self:AddToken( "comment" )
			else 
				self:AddToken( "operator" )
			end
		else 
			local b = false
			for i = 1, #self.Tokens do 
				if self:NextPattern( self.Tokens[i] ) then 
					-- print( "TOKENLIST", self.Tokens[i] )
					self:AddToken( "operator" ) 
					b = true
					break
				end 
			end 
			if b then continue end 
			
			self:NextCharacter( )
			self:AddToken( "notfound" ) 
		end 
	end 
	
	return tOutput 
end

function Syntaxer.Highlight( Editor, nRow )
	-- if not EXPADV.IsLoaded then return false end 
	-- if nRow < 15 or nRow > 16 then return {{Editor.Rows[nRow], Color(255,255,255)}} end 
	-- print( "\n\n\nRow: " .. nRow )
	Syntaxer.Editor = Editor 
	return Syntaxer:Parse( nRow )
end
