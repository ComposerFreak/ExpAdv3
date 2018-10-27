/*============================================================================================================================================
	Component for E3 syntax highlighting for Golem
	Author: Oskar
============================================================================================================================================*/

local string_match = string.match 
local string_rep = string.rep 
local string_sub = string.sub 
local string_gsub = string.gsub 

local type = type 
local pairs = pairs 

local Syntax = { sName = "E3" }
Syntax.__index = Syntax

function Syntax:Init( dEditor )
	self.dEditor = dEditor
	self.dEditor:SetSyntax( self ) 
	self.dEditor:SetCodeFolding( true ) 
	self.dEditor:SetParamMatching( true )
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
		
		if self.dEditor.tFoldData[nLine][1] ~= nLevel then 
			self.dEditor.tFoldData[nLine][1] = nLevel 
		end 
	end
	
	self.dEditor.tFoldData[#self.dEditor.tRows+1] = { 0, false, false }
	
	-- print( "Printing E3 fold data" )
	-- PrintTable( self.dEditor.tFoldData ) 
	
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


function Syntax:GetSyntax( nRow )
	-- if not self.Syntaxer.tOutput then self.Syntaxer:Parse() end 
	-- return self.Syntaxer.tOutput[nRow]
	return { { self.dEditor.tRows[nRow], Color(255,255,255) } }
end

function Syntax:Parse( )
	-- self.Syntaxer:Parse( ) 
end



Golem.Syntax:Add( Syntax.sName, Syntax ) 