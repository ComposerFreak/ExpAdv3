/*============================================================================================================================================
	Console hack
	Author: Oskar
============================================================================================================================================*/

local Syntax = { sName = "console" }
Syntax.__index = Syntax

function Syntax:Init( dEditor )
	self.dEditor = dEditor
	dEditor:SetSyntax( self ) 
	dEditor:SetCodeFolding( false ) 
	dEditor:SetParamMatching( false )
end

--[[self.tbConsoleEditor.SyntaxColorLine = function(_, row)
		if self.tbConsoleRows[row] then 
			return self.tbConsoleRows[row]
		end 
		
		return {self.tbConsoleRows[row], Color(255,255,255)}
	end*/]]--

function Syntax:GetSyntax( nRow )
	if self.dEditor.tFormat[nRow] then 
		return self.dEditor.tFormat[nRow]
	end 
	
	return { { self.dEditor.tRows[nRow], Color(255,255,255) } }
end

function Syntax:Parse( )
end


Golem.Syntax:Add( Syntax.sName, Syntax ) 