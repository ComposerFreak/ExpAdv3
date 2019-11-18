/*============================================================================================================================================
	Expression 3 Syntax Highlighting
	Author: Oskar
	Credits: The authors of the E2 syntax highlighter
============================================================================================================================================*/

Golem.Syntaxer = Golem.Syntaxer or { First = true }
local Syntaxer = Golem.Syntaxer
Syntaxer.First = true

/********************************************************************************************************************************************/

local tonumber, pairs, Color = tonumber, pairs, Color

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
	local Libraries = { }

	for sName, tData in pairs( EXPR_LIBRARIES ) do
		Libraries[sName] = { }
		if tData._functions then
			for _, tFunc in pairs( tData._functions ) do
				Functions[tFunc.name] = true
				Libraries[sName][tFunc.name] = true
			end
		end
	end

	self.Libraries = Libraries
	self.Functions = Functions
end

function Syntaxer:BuildTokensTable( )
	local Tokens = { }

	for k,v in pairs( EXPR_TOKENS.EXPADV ) do
		Tokens[#Tokens+1] = string_gsub( v[1], "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
	end

	self.Tokens = Tokens
end

function Syntaxer:BuildMethodsTable( )
	local Methods = { }

	for _, tData in pairs( EXPR_METHODS ) do
		Methods[tData.name] = tData.class
	end

	self.Methods = Methods
end

function Syntaxer.Rebuild( )
	Syntaxer:BuildFunctionTable( )
	Syntaxer:BuildMethodsTable( )
	Syntaxer:BuildTokensTable( )
	Syntaxer.Variables = { }
	Syntaxer.VariableTypes = { }
	Syntaxer.UserClasses = { }
	Syntaxer.UserFunctions = { }
	Syntaxer.UserClassMethods = { }
end

Syntaxer.Rebuild( ) -- For the editor reload command
hook.Add( "Expression3.LoadGolem", "Expression3", Syntaxer.Rebuild )

/*============================================================================================================================================
Syntaxer Functions
============================================================================================================================================*/
local function istype( word, row )
	local base = EXPR_LIB.GetClass( word )
	if base and base.id ~= word then
		return base and true or false
	end
	if not base then
		return (Syntaxer.UserClasses[word] and (row and Syntaxer.UserClasses[word] <= row or true)) or false
	end
	return false
end

local function isvar( word, row )
	return (Syntaxer.Variables[word] and (row and Syntaxer.Variables[word] <= row or true)) or false
end

local function fixtype( word )
	local base = EXPR_LIB.GetClass( word or "" )
	return base and base.name or word
end

function Syntaxer:ResetTokenizer( Row )
	self.nPosition = 0
	self.sChar = ""
	self.sTokenData = ""
	self.bBlockComment = nil
	self.bMultilineString = nil

	self.Variables = { }
	self.VariableTypes = { }
	self.UserClasses = { }
	self.UserFunctions = { }
	self.UserClassMethods = { }

	local tmp = self.Editor:ExpandAll( )
	local tRows = self.Editor.Rows
	self.sLine = self.Editor.Rows[Row]
	self.Editor:FoldAll( tmp )

	local bComment = nil
	local bString = nil

	for i, sLine in ipairs( tRows ) do
		if i >= Row then break end

		local tLine = string.Split( sLine, "" )
		local skip = { }

		for n = 1, #tLine do
			if not bComment and not bString then
				if tLine[n] == "/" then
					if tLine[n+1] == "/" then -- Single line comment
						sLine = string_sub( sLine, 0, n-1 )
						break
					elseif tLine[n+1] == "*" then -- Multi line comment
						bComment = true
						skip[#skip+1] = {n, #tLine}
					end
				elseif tLine[n] == "\"" and tLine[n-1] ~= "\\" then -- Single line string
					bString = "\""
					skip[#skip+1] = {n, #tLine}
				elseif tLine[n] == "'" and tLine[n-1] ~= "\\" then -- Multi line string
					bString = "'"
					skip[#skip+1] = {n, #tLine}
				end
			elseif bComment and tLine[n] == "/" and tLine[n-1] == "*" then -- End multi line comment
				if skip[#skip] then
					skip[#skip][2] = n
				else
					skip[#skip+1] = {1, n}
				end
				bComment = nil
			elseif bString and tLine[n] == bString and tLine[n-1] ~= "\\" then -- End string
				if bString == "\"" then
					if skip[#skip] then
						skip[#skip][2] = n
					else
						skip[#skip+1] = {1, n}
					end
				else -- Multi line string
					if skip[#skip] then
						skip[#skip][2] = n
					else
						skip[#skip+1] = {1, n}
					end
				end
				bString = nil
			end
		end

		if bComment or bString then continue end

		for i2 = #skip, 1, -1 do
			sLine = string_sub( sLine, 1, skip[i2][1]-1 ) .. string_sub( sLine, skip[i2][2]+1 )
		end

		for sClass in string_gmatch( sLine, "class +([a-zA-Z][a-zA-Z0-9_]*)" ) do
			self.UserClasses[sClass] = i
		end

		for sType, sName in string_gmatch( sLine, "function +([a-zA-Z][a-zA-Z0-9_]*) +([a-zA-Z][a-zA-Z0-9_]*)" ) do
			self:AddUserFunction( i, sName )
		end

		for sType, sVar in string_gmatch( sLine, "([a-zA-Z][a-zA-Z0-9_]*) +([a-zA-Z][a-zA-Z0-9_]*)" ) do
			if istype( sType, i ) then
				self.Variables[sVar] = i
				self.VariableTypes[sVar] = fixtype( sType )
			end
		end

		/* TODO:
			custom class methods
		*/
	end

	self.bBlockComment = bComment
	self.bMultilineString = bString == "'"
end

function Syntaxer:NextCharacter( )
	if not self.sChar then return end

	self.sTokenData = self.sTokenData .. self.sChar
	self.nPosition = self.nPosition + 1

	if self.nPosition <= #self.sLine then
		self.sChar = self.sLine[self.nPosition]
	else
		self.sChar = nil
	end
end

function Syntaxer:NextPattern( sPattern, bSkip )
	if not self.sChar then return false end
	local startpos, endpos, text = string_find( self.sLine, sPattern, self.nPosition  )

	if startpos ~= self.nPosition then return false end
	text = text or string_sub( self.sLine, startpos, endpos )

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
local keywords = {
	-- keywords that can be followed by a "(":
	["if"] 				= { true, true },
	["elseif"] 			= { true, true },
	["while"] 			= { true, true },
	["for"] 			= { true, true },
	["foreach"] 		= { true, true },
	["catch"] 			= { true, true },

	-- keywords that cannot be followed by a "(":
	["else"] 			= { true, false },
	["delegate"] 		= { true, false },
	["break"] 			= { true, false },
	["continue"] 		= { true, false },
	["return"] 			= { true, false },
	["global"] 			= { true, false },
	["true"] 			= { true, false },
	["false"] 			= { true, false },
	["void"] 			= { true, false },
	["new"] 			= { true, false },
	["client"] 			= { true, false },
	["server"] 			= { true, false },
	["try"] 			= { true, false },
	["final"] 			= { true, false },
	["class"] 			= { true, false },
	["constructor"] 	= { true, false },
	["operator"] 		= { true, false },
	["method"] 			= { true, false },
	["instanceof"] 		= { true, false },
}

local Directives = {
	["name"] 			= true,
	["model"] 			= true,
	["input"] 			= true,
	["output"] 			= true,
	["include"] 		= true,
}

-- fallback for nonexistant entries:
setmetatable( keywords, { __index = function( tbl, index ) return { } end } )

/*============================================================================================================================================
Syntaxer Colors
============================================================================================================================================*/
local colors = {
	/* TODO:
		Make propper color scheme
		Add syntax color options
	*/

	["comment"]      = Color( 128, 128, 128 ),
	-- ["exception"]    = Color(  80, 160, 240 ), -- TODO: Other color?
	["function"]     = Color(  80, 160, 240 ),
	["librarie"]     = Color(  80, 160, 240 ),
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
end

function Syntaxer:SkipSpaces( )
	self:NextPattern( " *" )
	self:AddToken( "operator" )
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
			local keyword = ( self.sChar or "" ) ~= "("

			-- Special keywords that needs extra work
			if word == "function" or word == "delegate" then
				if word == "function" then
					if self.sChar == "]" then
						self:AddToken( "typename" )
						continue
					elseif self.sChar == "(" then
						self:AddToken( "keyword" )
						continue
					end
				end

				self:AddToken( "keyword" )
				self:SkipSpaces( )

				if string_match( self.sLine, "^[a-zA-Z][a-zA-Z0-9_]* *=", self.nPosition ) then
					self:AddToken( "typename" )
					self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" )
					self:AddUserFunction( nRow, self.sTokenData )
					self:AddToken( "userfunction" )
					continue
				end

				if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
					if istype( self.sTokenData ) then
						self:AddToken( "typename" )
					else
						self:AddToken( "notfound" )
					end
				end

				self:SkipSpaces( )

				if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
					self:AddUserFunction( nRow, self.sTokenData )
					self:AddToken( "userfunction" )
				end

				self:NextPattern( " *%( *" )
				self:AddToken( "operator" )

				while self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) do
					local sType = ""
					if istype( self.sTokenData ) then
						sType = fixtype( self.sTokenData )
						self:AddToken( "typename" )
					else
						self:AddToken( "notfound" )
					end

					self:SkipSpaces( )

					if word == "function" then
						self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" )
						self.Variables[self.sTokenData] = nRow
						self.VariableTypes[self.sTokenData] = sType
						self:AddToken( "variable" )
					end

					if not self:NextPattern( " *, *" ) then break end
					self:AddToken( "operator" )
				end

				continue
			end

			if word == "method" then
				self:AddToken( "keyword" )
				self:SkipSpaces( )

				if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
					if istype( self.sTokenData ) then
						self:AddToken( "typename" )
					else
						self:AddToken( "notfound" )
					end
				end

				self:SkipSpaces( )

				self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" )
				self:AddUserFunction( nRow, self.sTokenData )
				self:AddToken( "userfunction" )

				self:NextPattern( " *%( *" )
				self:AddToken( "operator" )

				while self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) do
					local sType = ""
					if istype( self.sTokenData ) then
						sType = fixtype( self.sTokenData )
						self:AddToken( "typename" )
					else
						self:AddToken( "notfound" )
					end

					self:SkipSpaces( )
					self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" )
					self.Variables[self.sTokenData] = nRow
					self.VariableTypes[self.sTokenData] = sType
					self:AddToken( "variable" )

					if not self:NextPattern( " *, *" ) then break end
					self:AddToken( "operator" )
				end

				continue
			end

			if word == "class" then
				self:AddToken( "keyword" )
				self:SkipSpaces( )

				if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
					self.UserClasses[self.sTokenData] = nRow
					self:AddToken( "typename" )
				end

				self:SkipSpaces( )

				if self:NextPattern( "extends" ) then
					self:AddToken( "keyword" )
					self:SkipSpaces( )

					if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
						if istype( self.sTokenData, nRow ) then
							self:AddToken( "typename" )
						else
							self:AddToken( "notfound" )
						end
					end
				end

				continue
			end

			if word == "catch" then
				self:AddToken( "keyword" )
				self:SkipSpaces( )

				if self:NextPattern( "%(" ) then
					self:SkipSpaces( )

					if self:NextPattern( "[a-zA-Z][a-zA-Z0-9_]*" ) then
						self.Variables[self.sTokenData] = nRow
						self.VariableTypes[self.sTokenData] = "error"
						self:AddToken( "variable" )
					end
				end

				continue
			end

			if word == "new" then
				self:AddToken( "keyword" )
				self:SkipSpaces( )

				if self:NextPattern( "^[a-zA-Z][a-zA-Z0-9_]*" ) then
					if istype( self.sTokenData ) then
						self:AddToken( "typename" )
					else
						self:AddToken( "notfound" )
					end
				end
				continue
			end

			if word == "this" then
				self:AddToken( "keyword" )
				continue
			end

			-- All other keywords
			if keywords[word][1] then
				if keywords[word][2] then
					self:AddToken( "keyword" )
					continue
				elseif keyword then
					self:AddToken( "keyword" )
					continue
				end
			end

			if istype( word, nRow ) then
				self:AddToken( "typename" )
				self:SkipSpaces( )

				if self:NextPattern( "%(" ) then
					self:AddToken( "operator" )
					self:SkipSpaces( )
					while self:NextPattern( "([a-zA-Z][a-zA-Z0-9_]*)" ) do
						self:AddToken( "typename" )
						self:SkipSpaces( )

						if not self:NextPattern( "([a-zA-Z][a-zA-Z0-9_]*)" ) then break end

						self.Variables[self.sTokenData] = nRow
						self.VariableTypes[self.sTokenData] = fixtype( word )
						self:AddToken( "variable" )

						self:SkipSpaces( )

						if not self:NextPattern( "," ) then break end

						self:AddToken( "operator" )
						self:SkipSpaces( )
					end
				else
					while self:NextPattern( "([a-zA-Z][a-zA-Z0-9_]*)" ) do
						self.Variables[self.sTokenData] = nRow
						self.VariableTypes[self.sTokenData] = fixtype( word )
						self:AddToken( "variable" )

						if not self:NextPattern( " *, *" ) then break end
						self:AddToken( "operator" )
					end
				end

				continue
			end

			if self.Libraries[self.sTokenData] then
				local lib = self.Libraries[self.sTokenData]
				self:AddToken( "librarie" )
				self:SkipSpaces( )
				self:NextPattern( "^%." )
				self:AddToken( "operator" )
				self:SkipSpaces( )

				if self:NextPattern( "^[a-z][a-zA-Z0-9]*" ) then
					if lib[self.sTokenData] then
						self:AddToken( "function" )
					else
						self:AddToken( "notfound" )
					end
				end

				continue
			end

			if isvar( word, nRow ) then
				self:AddToken( "variable" )
				self:SkipSpaces( )

				if self:NextPattern( "^%." ) then
					self:AddToken( "operator" )
					self:SkipSpaces( )

					if self:NextPattern( "^[a-z][a-zA-Z0-9]*" ) then
						local s = self.sTokenData
						if fixtype( self.Methods[s] ) == fixtype(self.VariableTypes[word]) then
							self:AddToken( "function" )
						elseif self.UserClassMethods[s] then
							self:AddToken( "function" )
						end
					end
				end

				self:AddToken( "notfound" )
				continue
			end

			if self.UserFunctions[self.sTokenData] and self.UserFunctions[self.sTokenData] <= nRow then
				self:AddToken( "userfunction" )
				continue
			end

			self:AddToken( "notfound" )
		elseif self:NextPattern( "^@[a-zA-Z][a-zA-Z0-9_]*" ) then
			local dir = string_sub( self.sTokenData, 2 )
			if Directives[dir] then
				self:AddToken( "directive" )
				self:SkipSpaces( )
				continue
			end
			self:AddToken( "notfound" )
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

			if self.sChar == "*" then -- Multiline comment
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
			elseif self.sChar == "/" then -- Singleline comment
				self:NextPattern( ".*" )
				self:AddToken( "comment" )
			else
				self:AddToken( "operator" )
			end
		else
			local b = false
			for i = 1, #self.Tokens do
				if self:NextPattern( self.Tokens[i] ) then
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
	Syntaxer.Editor = Editor
	return Syntaxer:Parse( nRow )
end
