/*============================================================================================================================================
	Component for EA3 syntax highlighting for Golem
	Author: Oskar
============================================================================================================================================*/

local string_match = string.match 
local string_rep = string.rep 
local string_sub = string.sub 
local string_gsub = string.gsub 
local string_find = string.find

local type = type 
local pairs = pairs 

local Syntax = { sName = "E3" }
Syntax.__index = Syntax

function Syntax:Init( dEditor )
	self.dEditor = dEditor
	
	self.dEditor:SetSyntax( self ) 
	self.dEditor:SetCodeFolding( true ) 
	self.dEditor:SetParamMatching( true )
	
	self:BuildTokensTable( )
	self:BuildKeywordsTable( )
	self:BuildClassTable( )
	self:BuildLibraryMethods( ) 
end

/*---------------------------------------------------------------------------
Formating and folding
---------------------------------------------------------------------------*/
function Syntax:FindValidLines( )
	local ValidLines = { } 
	local bMultilineComment = false 
	local bMultilineString = false 
	local Row, Char = 1, 0 
	local LinesToFold = self.dEditor:ExpandAll( )
	
	while Row <= #self.dEditor.tRows do 
		local sStringType = false 
		local Line = self.dEditor.tRows[Row]
		
		while Char < #Line do 
			Char = Char + 1
			local Text = Line[Char]
			
			if bMultilineComment then 
				if Text == "/" and Line[Char-1] == "*" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineComment = false 
				end 
				continue 
			end 
			
			if bMultilineString then 
				if Text == "'" and Line[Char-1] ~= "\\" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineString = nil 
				end 
				continue 
			end 
			
			if sStringType then 
				if Text == sStringType and Line[Char-1] ~= "\\" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					sStringType = nil 
				end 
				continue 
			end 
			
			if Text == "/" then 
				if Line[Char+1] == "/" then // SingleLine comment
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
					break 
				elseif Line[Char+1] == "*" then // MultiLine Comment
					bMultilineComment = true 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
					continue 
				end 
			end 
			
			if Text == "'" then 
				if Line[Char-1] ~= "\\" then 
					bMultilineString = true 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
				end 
				continue 
			end 
			
			if Text == '"' then 
				if Line[Char-1] ~= "\\" then 
					sStringType = Text 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
				end 
			end 
		end 
		
		Char = 0 
		Row = Row + 1 
	end 
	
	self.dEditor:FoldAll( LinesToFold )
	
	return function( nLine, nStart ) 
		for i = 1, #ValidLines do
			local tStart, tEnd = ValidLines[i][1], ValidLines[i][2]
			
			if tStart[1] < nLine and tEnd[1] > nLine then 
				return false 
			end 
			
			if tStart[1] == tEnd[1] then
				if tStart[1] == nLine then 
			 		if tStart[2] <= nStart and tEnd[2] >= nStart then 
			 			return false 
			 		end 
			 	end 
			else 
			 	if tStart[1] == nLine then 
			 		if tStart[2] <= nStart then 
			 			return false 
			 		end 
			 	elseif tEnd[1] == nLine then 
			 		if tEnd[2] >= nStart then 
			 			return false 
			 		end 
			 	end 
			end 
		end
		
		return true 
	end 
end 

// { FoldLevel, Folded, FoldOverride }
function Syntax:MakeFoldData( nExit )
	local LinesToFold = self.dEditor:ExpandAll( )
	local ValidLines = self:FindValidLines( ) 
	local nLevel = 0
	
	for nLine = 1, #self.dEditor.tRows do
		if nLine == nExit then break end 
		local text = self.dEditor.tRows[nLine]
		local last
		self.dEditor.tFoldData[nLine] = self.dEditor.tFoldData[nLine] or { nLevel, false, false }
		
		for nStart, sType, nEnd in string.gmatch( text, "()([{}])()") do 
			if not ValidLines( nLine, nStart ) then continue end 
			nLevel = nLevel + ( sType == "{" and 1 or -1 ) 
			last = sType
		end 
		
		if last == "{" and self.dEditor.tFoldData[nLine][1] == nLevel then
			self.dEditor.tFoldData[nLine][3] = true 
		else 
			self.dEditor.tFoldData[nLine][3] = false 
		end
		
		nLevel = nLevel < 0 and 0 or nLevel
		
		if self.dEditor.tFoldData[nLine][1] >= nLevel then 
			self.dEditor.tFoldData[nLine][1] = nLevel 
		end 
	end
	
	self.dEditor.tFoldData[#self.dEditor.tRows+1] = { 0, false, false }
	
	self.dEditor:FoldAll( LinesToFold )
end 

local ParamPairs = {
	["{"] = { "{", "}", true }, 
	["["] = { "[", "]", true }, 
	["("] = { "(", ")", true }, 
	
	["}"] = { "}", "{", false }, 
	["]"] = { "]", "[", false }, 
	[")"] = { ")", "(", false }, 
}

function Syntax:FindMatchingParam( nRow, nChar )
	if not self.dEditor.tRows[nRow] then return false end 
	local LinesToFold = self.dEditor:ExpandAll( )
	local Param, EnterParam, ExitParam = ParamPairs[self.dEditor.tRows[nRow][nChar]] 
	
	if ParamPairs[self.dEditor.tRows[nRow][nChar-1]] and not ParamPairs[self.dEditor.tRows[nRow][nChar-1]][3] then 
		nChar = nChar - 1
		Param = ParamPairs[self.dEditor.tRows[nRow][nChar]] 
	end 
	
	if not Param then 
		nChar = nChar - 1
		Param = ParamPairs[self.dEditor.tRows[nRow][nChar]] 
	end 
	
	if not Param then
		self.dEditor:FoldAll( LinesToFold ) 
		return false 
	end 
	
	EnterParam = Param[1]
	ExitParam = Param[2]
	
	local line, pos, level = nRow, nChar, 0 
	local ValidLines = self:FindValidLines( ) 
	
	if not ValidLines( line, pos ) then 
		self.dEditor:FoldAll( LinesToFold )
		return false 
	end 
	
	if Param[3] then -- Look forward 
		while line <= #self.dEditor.tRows do 
			local Line = self.dEditor.tRows[line]
			while pos < #Line do 
				pos = pos + 1
				local Text = Line[pos]
				
				if not ValidLines( line, pos ) then continue end 
				
				if Text == EnterParam then 
					level = level + 1 
				elseif Text == ExitParam then 
					if level > 0 then 
						level = level - 1 
					else 
						self.dEditor:FoldAll( LinesToFold )
						return { Vector2( nRow, nChar ), Vector2( line, pos ) }
					end 
				end 
			end 
			pos = 0 
			line = line + 1 
		end 
	else -- Look backwards 
		while line > 0 do 
			local Line = self.dEditor.tRows[line]
			while pos > 0 do 
				pos = pos - 1 
				
				local Text = Line[pos] 
				
				if not ValidLines( line, pos ) then continue end 
				
				if Text == EnterParam then 
					level = level + 1 
				elseif Text == ExitParam then 
					if level > 0 then 
						level = level - 1 
					else 
						self.dEditor:FoldAll( LinesToFold )
						return { Vector2( line, pos ), Vector2( nRow, nChar ) }
					end 
				end 
			end 
			line = line - 1 
			pos = #(self.dEditor.tRows[line] or "") + 1
		end 
	end 
	
	self.dEditor:FoldAll( LinesToFold )
	
	return false 
end 

/*---------------------------------------------------------------------------
Directives
---------------------------------------------------------------------------*/
local Directives = {
	["name"] 			= true,
	["model"] 			= true,
	["input"] 			= true,
	["output"] 			= true,
	["include"] 		= true,
}

/*---------------------------------------------------------------------------
Colors
---------------------------------------------------------------------------*/
local colors = { 
	["comment"]      = Color( 128, 128, 128 ), 
	["function"]     = Color(  80, 160, 240 ), 
	["library"]      = Color(  80, 160, 240 ), 
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

Golem.Syntax:RegisterColors( Syntax.sName, colors )

/*---------------------------------------------------------------------------
Build data
---------------------------------------------------------------------------*/
/*
all locations:
EXPR_LIB
EXPR_OPERATORS
EXPR_CAST_OPERATORS


Maybe: 
EXPR_METHODS
EXPR_CLASSES


100% usefull
EXPR_LIBRARIES 
EXPR_TOKENS 
EXPR_KEYWORDS 
*/

function Syntax:BuildTokensTable( )
	self.tTokens = { }
	
	for k, v in pairs( EXPR_TOKENS.EXPADV ) do
		self.tTokens[#self.tTokens+1] = string_gsub( v[1], "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
	end
end

function Syntax:BuildKeywordsTable( ) 
	self.tKeywords = { } 
	
	for k, v in pairs( EXPR_KEYWORDS.EXPADV ) do
		self.tKeywords[k] = true
	end
	
	self.tKeywords["function"] = true -- Special case
end 

function Syntax:BuildClassTable( )
	self.tClasses = { }
	
	for k, v in pairs( EXPR_CLASSES ) do
		self.tClasses[k] = true
	end
end

function Syntax:BuildLibraryMethods( ) 
	self.tLibrary = { } 
	
	for sLib, tData in pairs( EXPR_LIBRARIES ) do
		self.tLibrary[sLib] = { } 
		for k, v in pairs( tData._functions ) do
			self.tLibrary[sLib][v.name] = true 
		end
	end
end 

/*---------------------------------------------------------------------------
Syntaxer
---------------------------------------------------------------------------*/
function Syntax:NextCharacter( )
	if not self.sChar then return end

	self.sBuffer = self.sBuffer .. self.sChar
	self.nPosition = self.nPosition + 1

	if self.nPosition <= #self.sLine then
		self.sChar = self.sLine[self.nPosition]
	else
		self.sChar = nil
	end
end

function Syntax:NextPattern( sPattern, bSkip )
	if not self.sChar then return false end
	local startpos, endpos, text = string_find( self.sLine, sPattern, self.nPosition  )
	
	if startpos ~= self.nPosition then return false end 
	text = text or string_sub( self.sLine, startpos, endpos ) 
	
	if not bSkip then 
		self.sBuffer = self.sBuffer .. text
	end 
	
	self.nPosition = endpos + 1
	if self.nPosition <= #self.sLine then
		self.sChar = self.sLine[self.nPosition]
	else
		self.sChar = nil
	end
	
	return bSkip and text or true 
end

function Syntax:AddToken( sTokenName, sBuffer )
	local color = colors[sTokenName]
	if not sBuffer then 
		sBuffer = self.sBuffer 
		self.sBuffer = ""
	end 
	if not sBuffer or sBuffer == "" then return end 
		
	if self.tLastColor and color == self.tLastColor[2] then
		self.tLastColor[1] = self.tLastColor[1] .. sBuffer
	else
		self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { sBuffer, color }
		self.tLastColor = self.tOutput[self.nRow][#self.tOutput[self.nRow]]
	end
end

function Syntax:SkipSpaces( )
	if self.sBuffer and self.sBuffer ~= "" then 
		print( string.format( "Unflushed %q on line %d char %d", self.sBuffer, self.nRow, self.nPosition ) )
	end 
	
	while self.sChar and self.sChar == " " do
		self:NextCharacter( )
	end 
	self:AddToken( "operator" )
end


function Syntax:InfProtect( )
	self.nLoops = self.nLoops + 1
	if SysTime( ) > self.nExpire then 
		ErrorNoHalt( "Code took to long to parse (" .. self.nLoops .. ")\n" )
		return false 
	end
	return true 
end

function Syntax:Parse( )
	self.bBlockComment = nil
	self.bMultilineString = nil
	
	self.tOutput = { }
	self.tLastColor = nil 
	
	self.nLoops = 0 
	self.nExpire = SysTime( ) + 0.1 
	
	local tmp = self.dEditor:ExpandAll( )
	self.tRows = table.Copy( self.dEditor.tRows )
	self.dEditor:FoldAll( tmp )
	
	for i = 1, #self.tRows do
		self.nPosition = 0
		self.nRow = i 
		
		self.sChar = ""
		self.sBuffer = ""
		self.sLine = self.tRows[i]
		
		self.tLastColor = nil 
		self.tOutput[i] = { }
		
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
		
		while self.sChar and self:InfProtect( ) do 
			self:SkipSpaces( )
			
			if self:NextPattern( "^[a-zA-Z][_A-Za-z0-9]*" ) then 
				-- if keywords[self.sBuffer] then 
				if self.tKeywords[self.sBuffer] then 
					self:AddToken( "keyword" )
				elseif self.tClasses[self.sBuffer] then 
					self:AddToken( "typename" )
				elseif self.tLibrary[self.sBuffer] then 
					local lib = self.tLibrary[self.sBuffer]
					self:AddToken( "library" )
					self:SkipSpaces( )
					if not self:NextPattern( "^%." ) then continue end 
					self:AddToken( "operator" ) 
					self:SkipSpaces( )
					
					if self:NextPattern( "^[a-z][a-zA-Z0-9]*" ) then 
						if lib[self.sBuffer] then 
							self:AddToken( "function" )
						else 
							self:AddToken( "notfound" )
						end 
					end 
				else 
					self:AddToken( "variable" )
				end 
			elseif self:NextPattern( "^0x[%x]+" ) then -- Hexadecimal numbers
				self:AddToken( "number" )
			elseif self:NextPattern( "^[%d][%d%.e]*" ) then -- Normal numbers
				self:AddToken( "number" )
			elseif self:NextPattern( "^@[a-zA-Z][a-zA-Z0-9_]*" ) then 
				local dir = string_sub( self.sBuffer, 2 )
				if Directives[dir] then 
					self:AddToken( "directive" )
					self:SkipSpaces( ) 
					continue 
				end 
				self:AddToken( "notfound" )
			elseif self.sChar == '"' or self.sChar == "'" then -- Single line string
				local sType = self.sChar
				self.bMultilineString = sType == "'"
				self:NextCharacter( )
				
				while self.sChar do 
					if self.sChar == sType then 
						if sType == "'" then 
							self.bMultilineString = nil
						end 
						break 
					end
					if self.sChar == "\\" then self:NextCharacter( ) end
					self:NextCharacter( )
				end
				
				self:NextCharacter( ) 
				self:AddToken( "string" ) 
			elseif self.sChar == "/" then 
				self:NextCharacter( ) 
				
				if self.sChar == "*" then -- Multi line comment type /*
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
				elseif self.sChar == "/" then -- Single line comment type //
					self:NextPattern( ".*" )
					self:AddToken( "comment" )
				else 
					self:AddToken( "operator" )
				end
			else
				local exit = false
				for i = 1, #self.tTokens do 
					if self:NextPattern( self.tTokens[i] ) then 
						self:AddToken( "operator" ) 
						exit = true
						break
					end 
				end 
				if exit then continue end 
				
				self:NextCharacter( )
			end 
			
			self:AddToken( "notfound" ) 
		end 
	end
end










function Syntax:GetSyntax( nRow )
	if not self.tOutput then self:Parse() end 
	return self.tOutput[nRow]
	-- return { { self.dEditor.tRows[nRow], Color(255,255,255) } }
end



Golem.Syntax:Add( Syntax.sName, Syntax ) 