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

/*self.tbConsoleEditor.SyntaxColorLine = function(_, row)
		if self.tbConsoleRows[row] then 
			return self.tbConsoleRows[row]
		end 
		
		return {self.tbConsoleRows[row], Color(255,255,255)}
	end*/

function Syntax:GetSyntax( nRow )
	if self.dEditor.tbConsoleRows[nRow] then 
		return self.dEditor.tbConsoleRows[nRow]
	end 
	return { { self.dEditor.tbConsoleRows[nRow], Color(255,255,255) } }
end

function Syntax:Parse( )
end


Golem.Syntax:Add( Syntax.sName, Syntax ) 