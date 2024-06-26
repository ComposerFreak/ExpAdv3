--[[============================================================================================================================================
	Component for EA3 syntax highlighting for Golem
	Author: Oskar
============================================================================================================================================]]

local string_match = string.match
local string_sub = string.sub
local string_gsub = string.gsub
local string_find = string.find
local pairs = pairs

local Syntax = {
	sName = "e3"
}

Syntax.__index = Syntax

function Syntax:Init( dEditor )
	self.dEditor = dEditor
	self.dEditor:SetSyntax( self )
	self.dEditor:SetCodeFolding( true )
	self.dEditor:SetParamMatching( true )
	
	self.tInterfaces = { }
	self.tVariables = { }
	self.tUserFunctions = { }
	self.tFunctions = { }
	self.tAttributes = { }
	self.tConstants = { }
	
	self:BuildTokensTable( )
	self:BuildKeywordsTable( )
	self:BuildClassTable( )
	self:BuildLibraryMethods( )
	self:BuildClassMethods( )
end

--[[---------------------------------------------------------------------------
Formating and folding
---------------------------------------------------------------------------]]
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
				if Text == "/" and Line[Char - 1] == "*" then
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineComment = false
				end

				continue
			end
			
			if bMultilineString then
				if Text == "'" and Line[Char - 1] ~= "\\" then
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineString = nil
				end

				continue
			end
			
			if sStringType then
				if Text == sStringType and Line[Char - 1] ~= "\\" then
					ValidLines[#ValidLines][2] = { Row, Char }
					sStringType = nil
				end

				continue
			end
			
			if Text == "/" then
				-- SingleLine comment
				if Line[Char + 1] == "/" then
					ValidLines[#ValidLines + 1] = { { Row, Char }, { Row, #Line + 1 } }
					break
				elseif Line[Char + 1] == "*" then
					-- MultiLine Comment
					bMultilineComment = true
					ValidLines[#ValidLines + 1] = { { Row, Char }, { Row, #Line + 1 } }
					continue
				end
			end
			
			if Text == "'" then
				if Line[Char - 1] ~= "\\" then
					bMultilineString = true
					ValidLines[#ValidLines + 1] = { { Row, Char }, { Row, #Line + 1 } }
				end

				continue
			end
			
			if Text == '"' and Line[Char - 1] ~= "\\" then
				sStringType = Text
				ValidLines[#ValidLines + 1] = { { Row, Char }, { Row, #Line + 1 } }
			end
		end
		
		Char = 0
		Row = Row + 1
	end
	
	self.dEditor:FoldAll( LinesToFold )
	
	return function( nLine, nStart )
		for i = 1, #ValidLines do
			local tStart, tEnd = ValidLines[i][1], ValidLines[i][2]
			if tStart[1] < nLine and tEnd[1] > nLine then return false end
			
			if tStart[1] == tEnd[1] then
				if tStart[1] == nLine and ( tStart[2] <= nStart and tEnd[2] >= nStart ) then return false end
			else
				if tStart[1] == nLine then
					if tStart[2] <= nStart then return false end
				elseif tEnd[1] == nLine then
					if tEnd[2] >= nStart then return false end
				end
			end
		end
		
		return true
	end
end

-- { FoldLevel, Folded, FoldOverride }
function Syntax:MakeFoldData( nExit )
	local LinesToFold = self.dEditor:ExpandAll( )
	local ValidLines = self:FindValidLines( )
	local nLevel = 0
	
	for nLine = 1, #self.dEditor.tRows do
		if nLine == nExit then break end
		local text = self.dEditor.tRows[nLine]
		local last
		self.dEditor.tFoldData[nLine] = self.dEditor.tFoldData[nLine] or { nLevel, false, false }
		
		for nStart, sType, nEnd in string.gmatch( text, "()([{}])()" ) do
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
	
	self.dEditor.tFoldData[#self.dEditor.tRows + 1] = { 0, false, false }
	self.dEditor:FoldAll( LinesToFold )
end

local ParamPairs = {
	["{"] = { "{", "}", true },
	["["] = { "[", "]", true },
	["("] = { "(", ")", true },
	["}"] = { "}", "{", false },
	["]"] = { "]", "[", false },
	[")"] = { ")", "(", false }
}

function Syntax:FindMatchingParam( nRow, nChar )
	if not self.dEditor.tRows[nRow] then return false end
	local LinesToFold = self.dEditor:ExpandAll( )
	local Param, EnterParam, ExitParam = ParamPairs[self.dEditor.tRows[nRow][nChar]]
	
	if ParamPairs[self.dEditor.tRows[nRow][nChar - 1]] and not ParamPairs[self.dEditor.tRows[nRow][nChar - 1]][3] then
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
	
	-- Look forward
	if Param[3] then
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
			pos = #( self.dEditor.tRows[line] or "" ) + 1
		end
	end
	
	self.dEditor:FoldAll( LinesToFold )
	
	return false
end

--[[---------------------------------------------------------------------------
Directives
---------------------------------------------------------------------------]]
local Directives = {
	["name"] = true,
	["model"] = true,
	["input"] = true,
	["output"] = true,
	["include"] = true,
	["server"] = true,
	["client"] = true,
	["synced"] = true
}

--[[---------------------------------------------------------------------------
Colors
---------------------------------------------------------------------------]]
local colors = {
	["comment"] = Color( 128, 128, 128 ),
	["function"] = Color( 80, 160, 240 ),
	["library"] = Color( 80, 160, 240 ),
	["constant"] = Color( 80, 160, 240 ),
	["keyword"] = Color( 0, 120, 240 ),
	["notfound"] = Color( 240, 160, 0 ),
	["number"] = Color( 0, 200, 0 ),
	["operator"] = Color( 240, 0, 0 ),
	["string"] = Color( 188, 188, 188 ),
	["class"] = Color( 140, 200, 50 ),
	["userfunction"] = Color( 102, 122, 102 ),
	["variable"] = Color( 0, 180, 80 ),
	["directive"] = Color( 89, 135, 126 ),
	["attribute"] = Color( 100, 100, 200 ),
}

-- ["prediction"]   = Color( 0xe3, 0xb5, 0x2d ),
-- ["metamethod"]   = Color( 0x00, 0xc8, 0xff ),
-- fallback for nonexistant entries:
setmetatable( colors, {
	__index = function( tbl, index ) return Color( 255, 255, 255 ) end
} )

Golem.Syntax:RegisterColors( Syntax.sName, colors )

--[[---------------------------------------------------------------------------
Build data
---------------------------------------------------------------------------]]
--[[
all locations:
EXPR_LIB
EXPR_OPERATORS
EXPR_CAST_OPERATORS


Maybe useful:
EXPR_METHODS


100% useful
EXPR_TOKENS
EXPR_KEYWORDS
EXPR_CLASSES
EXPR_LIBRARIES
]]
function Syntax:BuildTokensTable( )
	self.tTokens = { }
	
	for k, v in pairs( EXPR_TOKENS.EXPADV ) do
		self.tTokens[#self.tTokens + 1] = string_gsub( k, "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
	end
end

function Syntax:BuildKeywordsTable( )
	self.tKeywords = { }
	
	for k, v in pairs( EXPR_KEYWORDS.EXPADV ) do
		self.tKeywords[k] = true
	end
	
	-- Special cases
	-- self.tKeywords["function"] = true
	self.tKeywords["this"] = true
	self.tKeywords["input"] = true 
	self.tKeywords["intable"] = true 
end

function Syntax:BuildClassTable( )
	self.tClasses = { }
	self.tAttributes = { }
	
	for sClass, tData in pairs( EXPR_CLASSES ) do
		self.tClasses[sClass] = true
		self.tAttributes[sClass] = { }
		
		for sAttrName, tAttrData in pairs( tData.attributes ) do
			self.tAttributes[sClass][sAttrName] = true 
		end
	end
end

function Syntax:BuildLibraryMethods( )
	self.tLibrary = { }
	self.tConstants = { }
	
	for sLib, tData in pairs( EXPR_LIBRARIES ) do
		self.tLibrary[sLib] = { }
		self.tConstants[sLib] = { } 
		
		for k, v in pairs( tData._functions ) do
			self.tLibrary[sLib][v.name] = true
		end
		
		for k,v in pairs( tData._constants ) do
			self.tConstants[sLib][v.name] = true 
		end
	end
end

local function fixclass( word )
	local base = EXPR_LIB.GetClass( word or "" )
	
	return base and base.name or word
end

function Syntax:BuildClassMethods( )
	self.tMethods = { }
	
	for _, tData in pairs( EXPR_METHODS ) do
		local class = fixclass( tData.class )
		self.tMethods[class] = self.tMethods[class] or { }
		self.tMethods[class][tData.name] = true
		self.tFunctions[tData.name] = true
	end
	-- PrintTableGrep( self.tMethods )
end

--[[---------------------------------------------------------------------------
Syntaxer
---------------------------------------------------------------------------]]
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
	local startpos, endpos, text = string_find( self.sLine, sPattern, self.nPosition )
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
		print( string.format( "Unflushed %q on line %d char %d in tab %q", self.sBuffer, self.nRow, self.nPosition, self.dEditor.Tab:GetName( ) ) )
	end
	
	while self.sChar and self.sChar == " " do
		self:NextCharacter( )
	end
	
	self:AddToken( "notfound" )
end

function Syntax:AddUserFunction( nRow, sName )
	self.tUserFunctions[sName] = nRow
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
			-- Find the ending '
			while self.sChar do
				if self.sChar == "'" then
					self.bMultilineString = nil
					self:NextCharacter( )
					break
				end
				
				if self.sChar == "\\" then
					self:NextCharacter( )
				end
				
				self:NextCharacter( )
			end
			
			self:AddToken( "string" )
		end
		
		while self.sChar and self:InfProtect( ) do
			self:SkipSpaces( )
			
			if self:NextPattern( "^[a-zA-Z][_A-Za-z0-9]*" ) then
				local word = self.sBuffer
				
				-- Special keywords that needs extra work
				if word == "function" or word == "delegate" then
					local inline = false
					
					if word == "function" then
						-- Check to see if we are defining a inline function or accessing a function from a table.
						local match = self:NextPattern( " *[%]%(]", true )
						
						if match then
							if match:sub( -1 ) == "(" then
								self:AddToken( "keyword" )
								self:AddToken( "operator", match )
								self.sBuffer = ""
								inline = true
							elseif match:sub( -1 ) == "]" then
								self:AddToken( "class" )
								self:AddToken( "operator", match )
								continue
							end
						elseif string_match( self.sLine, "^ +[a-zA-Z][a-zA-Z0-9_]* *=", self.nPosition ) then
							-- Check if we are assigning a function to a variable
							self:AddToken( "class" )
							self:NextPattern( "^ +[a-zA-Z][a-zA-Z0-9_]*" )
							self:AddUserFunction( self.nRow, string.Trim( self.sBuffer ) )
							self:AddToken( "userfunction" )
							 
							if self:NextPattern( " *= * %( *" ) then
								self:AddToken( "operator" )
							else
								continue
							end
						end
					end
					
					if not inline then
						self:AddToken( "keyword" )
						self:SkipSpaces( )
						
						-- We are defining a new fundction, time to check for return type
						if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
							if self.tClasses[self.sBuffer] then
								self:AddToken( "class" )
							else
								self:AddToken( "notfound" )
							end
						end
						
						self:SkipSpaces( )
						
						-- Next up is the name of the function
						if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
							self:AddUserFunction( self.nRow, self.sBuffer )
							self:AddToken( "userfunction" )
						end
						
						self:NextPattern( " *%( *" )
						self:AddToken( "operator" )
					else
						self:SkipSpaces( )
					end
					
					local bTable = false
					if self:NextPattern( " *{ *" ) then
						self:AddToken( "operator" ) 
						bTable = true 
					end
					
					-- Time to catch all variables that the function can have
					while self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) do
						local sType = ""
						
						if self.tClasses[self.sBuffer] then
							sType = self.sBuffer
							self:AddToken( "class" )
						else
							self:AddToken( "notfound" )
						end
						
						self:SkipSpaces( )
						
						if word == "function" then
							self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" )
							self.tVariables[self.sBuffer] = { self.nRow, sType }
							self:AddToken( "variable" )
						end
						
						if not self:NextPattern( " *, *" ) then break end
						self:AddToken( "operator" )
					end
					
					if bTable then
						self:NextPattern( " *} *" )
						self:AddToken( "operator" )
					end
					
					continue
				end
				
				if word == "method" then
					self:AddToken( "keyword" )
					self:SkipSpaces( )
					
					if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
						if self.tClasses[self.sBuffer] then
							self:AddToken( "class" )
						else
							self:AddToken( "notfound" )
						end
					end
					
					self:SkipSpaces( )
					self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" )
					
					if self.sCurrentClassDefine then
						self.tMethods[self.sCurrentClassDefine][self.sBuffer] = true
						self:AddUserFunction( self.nRow, self.sBuffer )
						-- self.tFunctions[self.sBuffer] = true
					end
					
					self:AddToken( "userfunction" )
					self:NextPattern( " *%( *" )
					self:AddToken( "operator" )
					
					while self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) do
						local sType = ""
						
						if self.tClasses[self.sBuffer] then
							sType = self.sBuffer
							self:AddToken( "class" )
						else
							self:AddToken( "notfound" )
						end
						
						self:SkipSpaces( )
						self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" )
						self.tVariables[self.sBuffer] = { self.nRow, sType }
						self:AddToken( "variable" )
						
						if not self:NextPattern( " *, *" ) then break end
						self:AddToken( "operator" )
					end

					continue
				end
				
				if word == "class" then
					self:AddToken( "keyword" )
					self:SkipSpaces( )
					
					self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" )
					self.tClasses[self.sBuffer] = true
					self.tMethods[self.sBuffer] = { }
					self.sCurrentClassDefine = self.sBuffer
					self:AddToken( "class" )
					self:SkipSpaces( )
					
					if self:NextPattern( "extends" ) then
						self:AddToken( "keyword" )
						self:SkipSpaces( )
						
						if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
							if self.tClasses[self.sBuffer] then
								self:AddToken( "class" )
							else
								self:AddToken( "notfound" )
							end
						end
					end
					
					self:SkipSpaces( )
					
					if self:NextPattern( "implements" ) then
						self:AddToken( "keyword" )
						self:SkipSpaces( )
						self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" )
						
						if self.tInterfaces[self.sBuffer] then
							self:AddToken( "class" )
						else
							self:AddToken( "notfound" )
						end
					end
					
					continue
				end
				
				if word == "interface" then
					self:AddToken( "keyword" )
					self:SkipSpaces( )
					
					self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" )
					self.tInterfaces[self.sBuffer] = true
					self:AddToken( "class" )
					continue
				end
				
				if word == "catch" then
					self:AddToken( "keyword" )
					self:SkipSpaces( )
					
					if self:NextPattern( "%(" ) then
						self:AddToken( "operator" )
						self:SkipSpaces( )
						
						if self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) then
							self.tVariables[self.sBuffer] = { self.nRow, "error" }
							self:AddToken( "variable" )
						end
					end
					
					continue
				end

				if word == "new" then
					self:AddToken( "keyword" )
					self:SkipSpaces( )
					
					if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
						if self.tClasses[self.sBuffer] then
							self:AddToken( "class" )
						else
							self:AddToken( "notfound" )
						end
					end
					
					continue
				end
				
				if self.tKeywords[word] then
					self:AddToken( "keyword" )
					continue
				end
				
				if self.tClasses[word] or self.tInterfaces[word] then
					local match = self:NextPattern( " *[%]%(]", true )
					
					if match then
						if match:sub( -1 ) == "(" then
							self:AddToken( "function" )
							self:AddToken( "operator", match )
							continue
						elseif match:sub( -1 ) == "]" then
							self:AddToken( "class" )
							self:AddToken( "operator", match )
							continue
						end
					end
					
					self:AddToken( "class" )
					self:SkipSpaces( )
					
					if self:NextPattern( "%(" ) then
						self:AddToken( "operator" )
						self:SkipSpaces( )
						
						while self:NextPattern( "([a-zA-Z][a-zA-Z0-9_]*)" ) do
							self:AddToken( "typename" )
							self:SkipSpaces( )
							
							if not self:NextPattern( "([a-zA-Z][a-zA-Z0-9_]*)" ) then break end
							
							self.tVariables[self.sBuffer] = { self.nRow, word }
							self:AddToken( "variable" )
							self:SkipSpaces( )
							
							if not self:NextPattern( "," ) then break end
							self:AddToken( "operator" )
							self:SkipSpaces( )
						end
					else
						while self:NextPattern( "([a-zA-Z][a-zA-Z0-9_]*)" ) do
							self.tVariables[self.sBuffer] = { self.nRow, word }
							self:AddToken( "variable" )
							
							if not self:NextPattern( " *, *" ) then break end
							self:AddToken( "operator" )
						end
					end
					
					continue
				end
				
				if self.tLibrary[word] then
					self:AddToken( "library" )
					self:SkipSpaces( )
					
					if not self:NextPattern( "^%." ) then continue end
					
					self:AddToken( "operator" )
					self:SkipSpaces( )
					
					if self:NextPattern( "^[a-z][a-zA-Z0-9_]*" ) then
						if self.tLibrary[word] and self.tLibrary[word][self.sBuffer] then
							self:AddToken( "function" )
						elseif self.tConstants[word] and self.tConstants[word][self.sBuffer] then 
							self:AddToken( "constant" )
						else
							self:AddToken( "notfound" )
						end
					end
					
					continue
				end
				
				if self.tVariables[word] and self.nRow >= self.tVariables[word][1] then
					self:AddToken( "variable" )
					self:SkipSpaces( )
					
					if self:NextPattern( "^%." ) then
						self:AddToken( "operator" )
						self:SkipSpaces( )
						
						if self:NextPattern( "^[a-z][a-zA-Z0-9_]*" ) then
							local s = self.sBuffer
							
							if self.tMethods[self.tVariables[word][2]] and self.tMethods[self.tVariables[word][2]][s] then
								self:AddToken( "function" )
							elseif self.tAttributes[self.tVariables[word][2]] and self.tAttributes[self.tVariables[word][2]][s] then
								self:AddToken( "attribute" )
							end
						end
					end
					
					self:AddToken( "notfound" )
					continue
				end
				
				local match = self:NextPattern( " *= *", true ) 
				if match then
					self:AddToken( "variable" )
					self:AddToken( "operator", match )
					self.sBuffer = ""
					continue
				end
				
				if self.tUserFunctions[self.sBuffer] and self.tUserFunctions[self.sBuffer] <= self.nRow then
					self:AddToken( "userfunction" )
					continue
				end
				
				if self.tFunctions[word] then
					self:AddToken( "function" )
					continue
				end
			elseif self:NextPattern( "^0x[%x]+" ) then
				-- Hexadecimal numbers
				self:AddToken( "number" )
			elseif self:NextPattern( "^[%d][%d%.e]*" ) then
				-- Normal numbers
				self:AddToken( "number" )
			elseif self:NextPattern( "^@[a-zA-Z][a-zA-Z0-9_]*" ) then
				local dir = string_sub( self.sBuffer, 2 )
				
				if Directives[dir] then
					self:AddToken( "directive" )
					self:SkipSpaces( )
					continue
				end
				
				self:AddToken( "notfound" )
			elseif self.sChar == '"' or self.sChar == "'" then
				-- Single line string
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
					
					if self.sChar == "\\" then
						self:NextCharacter( )
					end
					
					self:NextCharacter( )
				end
				
				self:NextCharacter( )
				self:AddToken( "string" )
			elseif self.sChar == "/" then
				self:NextCharacter( )
				
				-- Multi line comment type /*
				if self.sChar == "*" then
					self.bBlockComment = true
					local sLastChar
					
					while self.sChar do
						self:NextCharacter( )
						
						if self.sChar == "/" and sLastChar == "*" then 
							self:NextCharacter( )
							self:AddToken( "comment" ) 
							self.bBlockComment = false 
							break 
						end 
						
						sLastChar = self.sChar
					end
					
					self:AddToken( "comment" )
				elseif self.sChar == "/" then
					-- Single line comment type //
					self:NextPattern( ".*" )
					self:AddToken( "comment" )
				else
					self:AddToken( "operator" )
				end
			else
				local exit = false
				
				for n = 1, #self.tTokens do
					if self:NextPattern( self.tTokens[n] ) then
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
	if not self.tOutput then
		self:Parse( )
	end
	-- return { { self.dEditor.tRows[nRow], Color(255,255,255) } }
	
	return self.tOutput[nRow]
end

Golem.Syntax:Add( Syntax.sName, Syntax )