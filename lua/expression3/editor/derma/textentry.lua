/*============================================================================================================================================
	Name: GOLEM_TextEntry
	Author: Rusketh
============================================================================================================================================*/

local PANEL = { };

AccessorFunc(PANEL, "m_bBackground", "DrawBackground");
AccessorFunc(PANEL, "m_colBackground", "BackgroundColor");

AccessorFunc(PANEL, "m_bBorder", "DrawBorder", FORCE_BOOL);
AccessorFunc(PANEL, "m_colBorder", "BorderColor");
AccessorFunc(PANEL, "m_nBorderRadius", "BorderRadius", FORCE_NUMBER );
AccessorFunc(PANEL, "m_nBorderMargin", "BorderMargin", FORCE_NUMBER );

function PANEL:Init()

	self.pnl_txt = self:Add("DTextEntry");
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

	-- self:SetDrawBorder(true);
	self:SetDrawBorder(false);
	self:SetBorderRadius(0);
	self:SetBorderMargin(2);
	self:SetBorderColor(Color(0, 0, 0));
end

function PANEL:DoClick() end

function PANEL:OnChange() end

function PANEL:OnEnter() end

/*============================================================================================================================================
	Value
============================================================================================================================================*/

function PANEL:SetValue(v)
	self.pnl_txt:SetValue(v);
end

function PANEL:GetValue()
	return self.pnl_txt:GetValue();
end

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
	
	self.pnl_btn:SizeToContentsX()

	local bx = m;
	local tx = self.pnl_btn:GetWide() + (m * 1);
	local tw = w - self.pnl_btn:GetWide() - (m * 3);
	
	if not self.pnl_btn:IsVisible() then
		tx = m;
		tw = w - (m * 2);
	elseif self.nIconDock == RIGHT then
		bx = w - self.pnl_btn:GetWide() - m;
		tx = m;
	end

	h = h - (m * 2);
	
	self.pnl_btn:SetPos(bx, m);
	self.pnl_btn:SetTall(h);

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
importTextFunction("GetPaintBackground");
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
importTextFunction("SetPaintBackground");
importTextFunction("SetPlaceholderText");
importTextFunction("UpdateConvarValue");
importTextFunction("UpdateFromHistory");
importTextFunction("UpdateFromMenu");
importTextFunction("RequestFocus");

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

/*============================================================================================================================================
	Make this a pop up
============================================================================================================================================*/

function Golem.QueryString(icon, cb, txt, place, w)
	local pnl = vgui.Create("GOLEM_TextEntry");

	if isstring(icon) then icon = Material(icon); end
	if place then pnl:SetPlaceholderText(place); end
	if not icon then pnl:ShowIcon(false); end
	if icon then pnl:SetMaterial(icon); end
	if txt then pnl:SetValue(txt); end

	if cb then
		pnl.DoClick = function(_, v) cb(v); pnl:Remove(); end;
		pnl.OnEnter = function(_, v) cb(v); pnl:Remove(); end;
	end

	local x, y = input.GetCursorPos();

	pnl.OnCursorExited = function() pnl:Remove(); end;
	pnl:SetPos(x - 40, y - 10);
	pnl:SetSize(w or 150, 22);
	pnl:MakePopup();
	pnl:RequestFocus();

	return pnl;
end