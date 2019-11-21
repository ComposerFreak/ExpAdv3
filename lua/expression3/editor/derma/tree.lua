/*============================================================================================================================================
	Name: GOLEM_NodeBrowser
	Author: Rusketh
============================================================================================================================================*/

local PANEL = {};

/*********************************************************************************
	Initalize
*********************************************************************************/

function PANEL:Init()
	self:DockPadding(5, 5, 5, 5);

	self:BuildControls();
	self:SetDefaultIcon("fugue/block.png");
	self:SetExpandedIcon("fugue/toggle-small.png");
	self:SetUnexpandedIcon("fugue/toggle-small-expand.png");

	self:DoReload();
end

/*********************************************************************************
	Add or the panels
*********************************************************************************/

function PANEL:BuildControls()
	self.srch_pnl = self:Add("GOLEM_Toolbar");
	self.srch_pnl:SetTall(22);
	self.srch_pnl:DockMargin(5, 5, 5, 5);
	self.srch_pnl:Dock(TOP);

	self.root_tree = self:Add("DTree");
	self.root_tree:SetBackgroundColor(Color(0, 0, 0));
	self.root_tree:SetWide(200);
	self.root_tree:DockMargin(5, 5, 5, 5);
	self.root_tree:Dock(FILL);

	self.ctrl_pnl = self:Add("GOLEM_Toolbar");
	self.ctrl_pnl:SetTall(22);
	self.ctrl_pnl:DockMargin(5, 5, 5, 5);
	self.ctrl_pnl:Dock(BOTTOM);

	self.srch_txt = self.srch_pnl:SetupTextBox( "Search", "fugue/binocular.png", FILL, function(_, str)
		self:SearchAll(str, true);
	end, nil);

	self.srch_txt:SetPlaceholderText("Search...");
	self.srch_txt:DockIcon(RIGHT);

	self.srch_txt.OnEnter = function(_, str)
		self:SearchAll(str, true);
	end;

	self.ctrl_pnl:SetupButton("Close All", "fugue/arrow-090.png", LEFT, function()
		self:ExpandAll(false);
	end);

	self.ctrl_pnl:SetupButton("Expand All", "fugue/arrow-270.png", LEFT, function()
		self:ExpandAll(true);
	end);

	self.rld_brn = self.ctrl_pnl:SetupButton("Reload", "fugue/arrow-circle.png", LEFT, function()
		self:DoReload();
	end);
end

/*********************************************************************************
	Reload Button
*********************************************************************************/

function PANEL:SetShowReloadButton(b)
	self.rld_brn:SetVisible(b);
	self:InvalidateLayout();
end

function PANEL:GetShowReloadButton()
	return self.rld_brn:GetVisible();
end

function PANEL:Reload() end

function PANEL:DoReload(noRemove)
	local node = self.root_tree;
	
	if node.subnodes and not noRemove then
		for k, v in pairs(node.subnodes) do
			v:Remove();
		end

		node.subnodes = {};
	end

	self:Reload(noRemove);
end

/*********************************************************************************
	DTree
*********************************************************************************/

function PANEL:GetTree()
	return self.root_tree;
end

/*********************************************************************************
	Search Panel
*********************************************************************************/

function PANEL:SetShowSearch(b)
	self.srch_pnl:SetVisible(b);
	self:InvalidateLayout();
end

function PANEL:GetShowSearch()
	return self.srch_pnl:GetVisible();
end

function PANEL:GetSearchPanel()
	return self.srch_pnl;
end

/*********************************************************************************
	Customize Search Panel
*********************************************************************************/

function PANEL:CustomSearchPanel(icon, text, tooltip, cb, value)
	if value then self.srch_txt:SetValue(value); end
	self.srch_txt:SetMaterial(icon);
	self.srch_txt:SetToolTip(text);
	self.srch_txt:SetPlaceholderText(tooltip);
	self.srch_txt.OnEnter = cb;
	self.srch_txt.DoClick = cb;
end

/*********************************************************************************
	Reset Search Panel
*********************************************************************************/
do
	local binocular = Material("fugue/binocular.png");
	
	local cb = function(_, str)
		self:SearchAll(str, true);
	end;

	function PANEL:ResetSearchPanel()
		self:CustomSearchPanel(binocular, "Search", "Search...", cb, "");
	end
end

/*********************************************************************************
	Control Panel
*********************************************************************************/

function PANEL:SetShowControl(b)
	self.ctrl_pnl:SetVisible(b);
	self:InvalidateLayout();
end

function PANEL:GetShowControl()
	return self.ctrl_pnl:GetVisible();
end

function PANEL:GetControlPanel()
	return self.ctrl_pnl;
end

/*********************************************************************************
	Custom Skin
*********************************************************************************/

function PANEL:SetDefaultIcon(s)
	self.m_sDefIcon = s;
end

function PANEL:GetDefaultIcon()
	return self.m_sDefIcon;
end

function PANEL:SetExpandedIcon(s)
	self.m_sExpandedIcon = s;
end

function PANEL:GetExpandedIcon()
	return self.m_sExpandedIcon;
end

function PANEL:SetUnexpandedIcon(s)
	self.m_sUnexpandedIcon = s;
end

function PANEL:GetUnexpandedIcon()
	return self.m_sUnexpandedIcon;
end

/*********************************************************************************
	Apply Custom Skin
*********************************************************************************/

function PANEL:ApplyCustomSkin(node)
	node:SetIcon(self.m_sDefIcon);
	node.Label:SetTextColor(Color( 230, 230, 230 ) )

	local icon_open = Material(self.m_sExpandedIcon);
	local icon_small = Material(self.m_sUnexpandedIcon);

	if node.Expander then
		function node.Expander.Paint(self, w, h)
			local mat = self.m_bExpanded and icon_open or icon_small;

			surface.SetDrawColor(255, 255, 255);
			surface.SetMaterial(mat);
			surface.DrawTexturedRect(0, 0, w, h);
		end
	end
end

/*********************************************************************************
	Create Nodes
*********************************************************************************/

local addNode;

addNode = function(self, pnl, frs, scnd, ...)
	if not pnl.subnodes then pnl.subnodes = { }; end

	local node = pnl.subnodes[frs];

	if not node then
		node = pnl:AddNode(frs);

		self:ApplyCustomSkin(node);

		pnl.subnodes[frs] = node;
	end

	if not scnd then return node; end

	return addNode(self, node, scnd, ...);
end;

function PANEL:AddNode(frs, scnd, ...)
	if ispanel(frs) then return addNode(self, frs, scnd, ...); end

	return addNode(self, self.root_tree, frs, scnd, ...);
end

/*********************************************************************************
	Expand all nodes
*********************************************************************************/

local expandAll;

expandAll = function(node, expand, anim)
	node:SetExpanded(expand, anim);

	if node.subnodes then
		for k, v in pairs(node.subnodes) do
			expandAll(v, expand, anim);
		end
	end
end;

function PANEL:ExpandAll(expand, anim)
	return expandAll(self.root_tree, expand, anim);
end

/*********************************************************************************
	Search Function
*********************************************************************************/

local searchNodes;

searchNodes = function(node, query)
	local c = 0;

	if node.subnodes then
		for k, v in pairs(node.subnodes) do
			c = c + searchNodes(v, query);
		end
	end

	local val = node:GetText():upper();
	local found = string.find(val, query:upper(), 1, true);
	
	local visible = true;

	if c == 0 and (not found) then
		visible = false;
	end

	if query == "" then
		visible = true;
	end

	node:SetVisible(visible);

	if visible then
		c = c + 1;
	end

	return c;
end;

function PANEL:SearchAll(query)
	local c = searchNodes(self.root_tree, query);

	self:ExpandAll(query ~= "");

	return c;
end

/*********************************************************************************
	Scroll To
*********************************************************************************/
local getY;

getY = function(root, node, x, y)
	local parent = node:GetParent();

	if parent == root then return x, y; end

	local _x, _y = node:GetPos();

	x = x + _x;
	y = y + _y;

	return getY(root, parent, x, y);
end

function PANEL:ScrollTo(node)
	timer.Simple(0.01, function()
		self.root_tree:ScrollToChild(node);
	end);
end

/*********************************************************************************
	Embed Button
*********************************************************************************/

function PANEL:EmbedButton(node, pnl, x, y)

	if isstring(pnl) then pnl = vgui.Create(pnl); end

	if not pnl then return; end

	pnl:SetParent(node);
	pnl:SetDragParent(node);

	local PerformLayout = node.PerformLayout;
	node.PerformLayout = function(s, w, h)
		pnl:SetPos(w - x, y);
		return PerformLayout(s, w, h);
	end;

	return pnl;
end

vgui.Register("GOLEM_Tree", PANEL, "EditablePanel");