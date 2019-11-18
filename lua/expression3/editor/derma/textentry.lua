/*============================================================================================================================================
	Name: GOLEM_TextEntry
	Author: Rusketh
============================================================================================================================================*/

local PANEL = { };

AccessorFunc(PANEL, "m_bBackground", "DrawBackground");
AccessorFunc(PANEL, "m_colBackground", "BackgroundColor");

AccessorFunc(PANEL, "m_bBorder", "DrawBorder");
AccessorFunc(PANEL, "m_colBorder", "BorderColor");
AccessorFunc(PANEL, "m_nBorderRadius", "BorderRadius");
AccessorFunc(PANEL, "m_nBorderMargin", "BorderMargin");

function PANEL:Init()

	self.pnl_txt = vgui.Create("DTextEntry", self);
	self.pnl_txt:SetPaintBackground(false);
	self.pnl_txt:SetDrawBorder(false);

	self.pnl_txt.OnChange = function(_,v) return self:OnChange(v); end
	self.pnl_txt.OnEnter = function() return self:OnEnter(self:GetValue()); end

	self.pnl_btn = self:Add("GOLEM_ImageButton");
	self.pnl_btn:DrawButton(false);

	self.pnl_btn.DoClick = function(_, ...) return self:DoClick(self:GetValue(), ...); end
	self.pnl_btn.OnGetFocus = function(_, ...) return self:OnGetFocus(self:GetValue(), ...); end
	self.pnl_btn.OnKeyCode = function(_, ...) return self:OnKeyCode(self:GetValue(), ...); end
	self.pnl_btn.OnLoseFocus = function(_, ...) return self:OnLoseFocus(self:GetValue(), ...); end

	self:DockIcon(LEFT);

	self:SetPaintBackground(true);
	self:SetBackgroundColor(Color(255, 255, 255));

	self:SetDrawBorder(true);
	self:SetBorderRadius(0);
	self:SetBorderMargin(2);
	self:SetBorderColor(Color(0, 0, 0));
end

function PANEL:DoClick() end

function PANEL:OnChange() end

function PANEL:OnEnter() end

/*============================================================================================================================================
	Paint
============================================================================================================================================*/

function PANEL:Paint(w, h)

	local r = self.m_nBorderRadius;
	local m = self.m_nBorderMargin;

	local w = w - (m * 2);
	local h = h - (m * 2);

	local x, y = m, m;

	if self.m_bBackground then
		draw.RoundedBox(r, x, y, w, h, self.m_colBackground);
	end

	if self.m_bBorder then
		surface.SetDrawColor(self.m_colBorder);
		surface.DrawOutlinedRect(x, y, w, h);
	end

end

/*============================================================================================================================================
	Layout
============================================================================================================================================*/

function PANEL:ShowIcon(b)
	self.pnl_btn:SetVisible(b);

	self:InvalidateLayout(false);
end

function PANEL:DockIcon(dock)
	if dock ~= LEFT and dock ~= RIGHT then dock = LEFT; end

	self.nIconDock = dock;

	self:InvalidateLayout(false);
end

function PANEL:PerformLayout( w, h )
	local m = self.m_nBorderMargin;

	local bx = m;
	local tx = h + (m * 2);
	local tw = w - h - (m * 3);

	if not self.pnl_btn:IsVisible() then
		tx = m;
		tw = w - (m * 2);
	elseif self.nIconDock == RIGHT then
		bx = w - h - m;
		tx = m;
	end

	h = h - (m * 2);

	self.pnl_btn:SetPos(bx, m);
	self.pnl_btn:SetSize(h, h);

	self.pnl_txt:SetPos(tx, m);
	self.pnl_txt:SetSize(tw, h);
end

/*============================================================================================================================================
	Make this act as a DTextEntry
============================================================================================================================================*/
local function importTextFunction(name)
	PANEL[name] = function(self, ...)
		return self.pnl_txt[name](self.pnl_txt, ...);
	end;
end

importTextFunction("AddHistory");
importTextFunction("GetAutoComplete");
importTextFunction("GetDisabled");
importTextFunction("GetDrawBackground");
importTextFunction("GetDrawBorder");
importTextFunction("GetEnterAllowed");
importTextFunction("GetFloat");
importTextFunction("GetFont");
importTextFunction("GetHighlightColor");
importTextFunction("GetHistoryEnabled");
importTextFunction("GetInt");
importTextFunction("GetTabbingDisabled");
importTextFunction("GetUpdateOnType");
importTextFunction("IsEditing");
importTextFunction("OpenAutoComplete");
importTextFunction("SetCursorColor");
importTextFunction("SetEditable");
importTextFunction("SetEnterAllowed");
importTextFunction("SetFont");
importTextFunction("SetHighlightColor");
importTextFunction("SetHistoryEnabled");
importTextFunction("SetTabbingDisabled");
importTextFunction("SetTextColor");
importTextFunction("SetUpdateOnType");
importTextFunction("SetPlaceholderText");
importTextFunction("SetValue");
importTextFunction("GetValue");
importTextFunction("UpdateConvarValue");
importTextFunction("UpdateFromHistory");
importTextFunction("UpdateFromMenu");

/*============================================================================================================================================
	Make this act as a Image Button
============================================================================================================================================*/
local function importButtonFunction(name)
	PANEL[name] = function(self, ...)
		return self.pnl_btn[name](self.pnl_btn, ...);
	end;
end

importButtonFunction("DrawButton");
importButtonFunction("SetTextColor");
importButtonFunction("SetTextShadow");
importButtonFunction("SetOutlined");
importButtonFunction("SetTextCentered");
importButtonFunction("SetFading");
importButtonFunction("SetFlat");
importButtonFunction("SetIconFading");
importButtonFunction("SetIconCentered");
importButtonFunction("SetTooltip");
importButtonFunction("SetMaterial");
importButtonFunction("GetColor");
importButtonFunction("GetTextColor");
importButtonFunction("GetTextShadow");
importButtonFunction("GetOutlined");
importButtonFunction("GetTextCentered");
importButtonFunction("GetFading");
importButtonFunction("GetFlat");
importButtonFunction("GetIconFading");
importButtonFunction("GetIconCentered");
importButtonFunction("GetTooltip");
importButtonFunction("GetMaterial");

vgui.Register( "GOLEM_TextEntry", PANEL, "EditablePanel" );
