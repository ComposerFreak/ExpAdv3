/*********************************************************************************
	Tabbed Panel
*********************************************************************************/

local TABPANEL = {};

function TABPANEL:Init()
	self:DockPadding(5, 5, 5, 5);

	self.pnl_tbr = self:Add("GOLEM_Toolbar");
	self.pnl_tbr:DockMargin(5, 5, 5, 5);
	self.pnl_tbr:Dock(TOP);

	self.pnl_cnvs = self:Add("EditablePanel");
	self.pnl_cnvs:DockMargin(5, 5, 5, 5);
	self.pnl_cnvs:Dock(FILL);

	self.sheets = {};
	self.tabs = {};
end

function TABPANEL:AddTab(sName, sIcon, pSheet)
	
	if isstring(pSheet) then
		pSheet = vgui.Create(pSheet);
	end

	local tab = self.pnl_tbr:SetupButton(sName, sIcon, LEFT, function()
		self:SetActiveTab(sName);
	end)

	self.tabs[sName] = tab;
	self.sheets[sName] = pSheet;

	if pSheet then
		pSheet:SetParent(self.pnl_cnvs);
		pSheet:SetVisible(false);
		pSheet:Dock(FILL);
	end

	return pSheet, tab;
end

function TABPANEL:HideActiveTab()
	if self.m_sActive then

		local sheet = self.sheets[self.m_sActive];

		if sheet then
			self.m_sActive = nil;
			sheet:SetVisible(false);
		end
	end
end

function TABPANEL:SetActiveTab(sName)
	local sheet = self.sheets[sName];

	if sheet then
		self:HideActiveTab();
		self.m_sActive = sName;
		sheet:SetVisible(true);
	end
end

vgui.Register("GOLEM_SimpleTabs", TABPANEL, "EditablePanel");