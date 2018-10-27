/*============================================================================================================================================
	Name: GOLEM_Search
	Author: Rusketh (The whole point of this, is to make Oskar hate it so he replaces it!)
	Based on Sublime Text 3, because its the best Text Editor (Disagree? Your wrong!).
============================================================================================================================================*/

local PANEL = {};

function PANEL:Init()

	self:DockPadding(5, 5, 5, 5)

	self.msg = self:Add("DLabel");
	self.msg:SetText("This is an ugly place holder and does NOTHING!");

	self.search_label = self:Add("DLabel");
	self.search_label:SetText("Find:");
	--self.search_label:Dock(TOP);

	self.search_box = self:Add("DTextEntry");
	--self.search_box:Dock(TOP);

	self.replace_label = self:Add("DLabel");
	self.replace_label:SetText("Replace:");
	--self.replace_label:Dock(TOP);

	self.replace_box = self:Add("DTextEntry");
	--self.replace_box:Dock(TOP);

	self.controls = self:Add("DGrid");
	self.controls:SetCols(2);
	self.controls:SetColWide(100);
	--self.controls:SetSize(200, 50);
	--self.controls:Dock(TOP);

	self.find_next = self.controls:Add("DButton");
	self.find_next:SetText("Find Next");
	self.find_next:SizeToContents();
	self.controls:AddItem(self.find_next);

	self.find_prev = self.controls:Add("DButton");
	self.find_prev:SetText("Find Prev");
	self.find_prev:SizeToContents();
	self.controls:AddItem(self.find_prev);

	self.replace_next = self.controls:Add("DButton");
	self.replace_next:SetText("Replace Next");
	self.replace_next:SizeToContents();
	self.controls:AddItem(self.replace_next);

	--Don't think we need this?
	--self.replace_prev = self.controls:Add("DButton");
	--self.replace_prev:SetText("Replace Prev");
	--self.controls:AddItem(self.replace_prev);

	self.replace_all = self.controls:Add("DButton");
	self.replace_all:SetText("Replace All");
	self.replace_all:SizeToContents();
	self.controls:AddItem(self.replace_all);


	self.option_matchcase = self:Add("DCheckBoxLabel");
	self.option_matchcase:SetText("Match case");
	--self.option_matchcase:Dock(TOP);

	self.option_regex = self:Add("DCheckBoxLabel");
	self.option_regex:SetText("Regular Expressions");
	--self.option_regex:Dock(TOP);

	self.option_wholeword = self:Add("DCheckBoxLabel");
	self.option_wholeword:SetText("Match whole word");
	--self.option_wholeword:Dock(TOP);

	self.option_inselection = self:Add("DCheckBoxLabel");
	self.option_inselection:SetText("Search selection");
	--self.option_inselection:Dock(TOP);

	self.results_pane = self:Add("DListView");
	self.results_pane:AddColumn("Line");
	self.results_pane:AddColumn("Char");
	self.results_pane:AddColumn("Match");
	--self.results_pane:Dock(FILL);
end

vgui.Register("GOLEM_FindReplace", PANEL, "DListLayout"); --"EditablePanel");