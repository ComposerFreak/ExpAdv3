/*============================================================================================================================================
	Name: GOLEM_Autocomplete
	Author: Oskar
============================================================================================================================================*/

local PANEL = { }

function PANEL:Init( )
	self.Text = ""
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(255, 255, 255, 50)
	surface.DrawRect(0, 0, w, h)
	
	surface.SetTextColor(40, 40, 40, 255)
	surface.SetTextPos(10, 10)
	surface.SetFont("Trebuchet20")
	surface.DrawText(self.Text)
end

function PANEL:GetWord()
	local sOut = ""
	local sText = self.Editor.tRows[self.Editor.Caret.x]
	
	for i = 1, math.min(#sText,self.Editor.Caret.y) do 
		local sChar = sText[i]
		
		if string.match( sChar, "[%w%.]" ) then 
			sOut = self.sOut .. sChar
		else
			sOut = ""
		end
	end 
	
	return sOut
end 

function PANEL:Update() 
	self.Text = self:GetWord()
end 

vgui.Register( "GOLEM_Autocomplete", PANEL, "EditablePanel" )
