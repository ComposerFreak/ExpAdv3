--[[============================================================================================================================================
	Some major hacks for syntaxing using the tokenizer
	Author: Oskar
============================================================================================================================================]]

local Syntax = {
	sName = "e3_tokenizer",
	tOutput = { },
	tTokens = { }
}

Syntax.__index = Syntax

function Syntax:Init( dEditor )
	self.dEditor = dEditor
	dEditor:SetSyntax( self )
	dEditor:SetCodeFolding( false )
	dEditor:SetParamMatching( false )
	
	
end

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

function Syntax:GetSyntax( nRow )
	if self.tOutput and self.tOutput[nRow] then return self.tOutput[nRow] end 
	
	return { { self.dEditor.tRows[nRow], Color( 255, 255, 255 ) } }
end


function Syntax:Parse( )
	local tmp = self.dEditor:ExpandAll( )
	self.tRows = table.Copy( self.dEditor.tRows )
	self.dEditor:FoldAll( tmp )
	
	local code = string.gsub( table.concat( self.tRows, "\n" ), "\r", "" )
	
	local Tokenizer = EXPR_TOKENIZER.New()
	self.Tokenizer = Tokenizer
	
	Tokenizer:Initialize( "EXPADV", code, true );
	
	local bOK, tData = Tokenizer:Run( );
	
	if bOK ~= true then print( "Syntax Error", tData ) end 
	self.tTokens = tData 
	
	self.tOutput = { }
	self.nRow = 1
	self.nChar = 0
	self.nPos = 1
	self.nToken = 1
	
	for i, tToken in ipairs(tData.tokens) do
		if tToken.newLine then 
			self.nRow = tToken.line 
			self.nChar = 0
		end 
		
		local text = tostring( tToken.orig or tToken.data )
		
		-- if tToken.start >= self.nPos then 
		-- 	self.tOutput[self.nRow] = self.tOutput[self.nRow] or { }
		-- 	self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { (" "):rep(tToken.start - self.nPos), Color( 255, 255, 255 ) }
		-- 	self.nPos = tToken.start
		-- end 
		
		if tToken.char - self.nChar > #text then
			local diff = (tToken.char - self.nChar) - #text
			self.tOutput[self.nRow] = self.tOutput[self.nRow] or { }
			self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { (" "):rep(diff), Color( 255, 255, 255 ) }
		end
		self.nChar = tToken.char
		
		-- if tToken.line > self.nRow then 
		-- 	local code = string.Explode( "\n", tToken.data )
			
		-- 	for i,v in ipairs( code ) do
		-- 		self.tOutput[self.nRow] = self.tOutput[self.nRow] or { }
		-- 		self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { v, colors[tToken.name] }
		-- 		self.nRow = self.nRow + 1
		-- 	end
		-- else
			self.tOutput[self.nRow] = self.tOutput[self.nRow] or { }
			self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { tostring(tToken.orig or tToken.data), colors[tToken.name] }
		-- end
		
		
		
		-- self.nPos = tToken.stop
	end
	
	/*local runs = 0
	while self.nRow < #self.tRows or runs > 10000 do 
		self.tOutput[self.nRow] = { }
		local token = self.tTokens.tokens[self.nToken]
		
		if token then 
			if token.start > self.nPos then 
				self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { (" "):rep(token.start - self.nPos), Color( 255, 255, 255 ) }
				self.nPos = token.start
			end 
			
			if token.line > self.nRow then 
				local code = string.Explode( "\n", token.data )
				
				for i,v in ipairs( code ) do
					self.tOutput[self.nRow] = self.tOutput[self.nRow] or { }
					self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { v, colors[token.name] }
					self.nRow = self.nRow + 1
				end
			else
				self.tOutput[self.nRow][#self.tOutput[self.nRow] + 1] = { token.data , colors[token.name] }
			end
			
			self.nPos = token.stop
			self.nToken = self.nToken + 1
		else 
			break 
		end 
		
		
		-- self.nRow = self.nRow + 1
		runs = runs + 1
	end */
	
	
end

Golem.Syntax:Add( Syntax.sName, Syntax )