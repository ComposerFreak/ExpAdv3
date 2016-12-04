/*=============================================================================
	Golem HTML tab
	Author: DaDamRival
=============================================================================*/
local PANEL = {}

function PANEL:Init()
	self.Html = self:Add("DHTML")
end

function PANEL:Setup(html)
	self.Html:Dock(FILL)
	self.Html:SetHTML(html)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("GOLEM_DHTML", PANEL, "EditablePanel")