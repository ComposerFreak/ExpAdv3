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

	if string.sub(html, 1, 4) != "url:" then
		self.Html:SetHTML(html)
	else
		self.Html:OpenURL(string.sub(html, 5))
	end
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("GOLEM_DHTML", PANEL, "EditablePanel")
