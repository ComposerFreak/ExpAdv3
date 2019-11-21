if SERVER then return; end

/*********************************************************************************
	Browser
*********************************************************************************/
local PANEL = {};

local add_icon = Material("fugue/plus-button.png");
local save_icon = Material("fugue/disk-black.png");
local edit_icon = Material("fugue/pencil.png");
local del_icon = Material("fugue/cross-button.png");

function PANEL:Init()
	self:Reload();
end

function PANEL:Reload(b)
	if not b then
		EXPR_PERMS.LoadWhiteList();
		EXPR_PERMS.LoadBlackList();
	end

	self:LoadWhiteList();
	self:LoadBlackList();
	self:LoadHistory();
end

/*********************************************************************************
	White List Node
*********************************************************************************/

function PANEL:LoadWhiteList()
	self.node_white = self:AddNode("White List");
	self.node_white:SetIcon("fugue/quill.png");

	self.btn_white = self:EmbedButton(self.node_white, "GOLEM_ImageButton", 25, 0);
	self.btn_white:SetMaterial(add_icon);
	
	self.btn_white.DoClick = function()
		
		Golem.QueryString(add_icon, function(url)
			
			self:ListedNode("White List", "White list", url, EXPR_PERMS.WhiteListURL, EXPR_PERMS.UnwhiteListURL);
			
		end, "", "White list url");

	end;

	self.sv_white = self:EmbedButton(self.node_white, "GOLEM_ImageButton", 50, 0);
	self.sv_white:SetMaterial(save_icon);

	self.sv_white.DoClick = function()
		EXPR_PERMS.SaveWhiteList();
	end;

	for url, filter in pairs(EXPR_PERMS.GetWhiteList()) do
		self:ListedNode("White List", "White list", url, EXPR_PERMS.WhiteListURL, EXPR_PERMS.UnwhiteListURL);
	end
end

/*********************************************************************************
	Black List Node
*********************************************************************************/

function PANEL:LoadBlackList()
	self.node_black = self:AddNode("Black List");
	self.node_black:SetIcon("fugue/exclamation-circle.png");

	self.btn_black = self:EmbedButton(self.node_black, "GOLEM_ImageButton", 25, 0);
	self.btn_black:SetMaterial(add_icon);
	
	self.btn_black.DoClick = function()

		self:CustomSearchPanel(add_icon, "Add to black list.", "url",
			function(_, url)
				EXPR_PERMS.BlackListURL(url);
				self:ResetSearchPanel();
				self:ListedNode("Black List", "Black list", url, EXPR_PERMS.BlackListURL, EXPR_PERMS.UnblackListURL);
			end,
		"", name);

	end;

	self.sv_black = self:EmbedButton(self.node_black, "GOLEM_ImageButton", 50, 0);
	self.sv_black:SetMaterial(save_icon);

	self.sv_black.DoClick = function()
		EXPR_PERMS.SaveBlackList();
	end;

	for url, filter in pairs(EXPR_PERMS.GetBlackList()) do
		self:ListedNode("Black List", "Black list", url, EXPR_PERMS.BlackListURL, EXPR_PERMS.UnblackListURL);
	end
end

/*********************************************************************************
	Add List node
*********************************************************************************/

function PANEL:ListedNode(node, name, url, add, remove)
	local node = self:AddNode(node, url);
	node:SetText(string.sub(url, 1, 25));
	node:SetTooltip(url);

	local edit = self:EmbedButton(node, "GOLEM_ImageButton", 25, 0);
	local del = self:EmbedButton(node, "GOLEM_ImageButton", 50, 0);

	edit:SetMaterial(edit_icon);
	del:SetMaterial(del_icon);
	
	edit.DoClick = function()
		
		self:CustomSearchPanel(edit_icon, "Apply changes.", url,
			function(_, _url)
				add(_url);
				remove(url);
				node:Remove();
				self:ListedNode(node, name, _url, add, remove)
				self:ResetSearchPanel();
			end,
		url);

	end;
	
	del.DoClick = function()
		remove(url)
		node:Remove();
	end;

	return node;
end


/*********************************************************************************
	History Node
*********************************************************************************/

function PANEL:LoadHistory()
	self.node_history = self:AddNode("History");

	local rfsh = self:EmbedButton(self.node_history, "GOLEM_ImageButton", 25, 0);
	rfsh:SetIcon("fugue/arrow-circle.png");
	rfsh:SetToolTip("Refresh history.");

	rfsh.DoClick = function()
		for url, ents in pairs(EXPR_PERMS.GetHistory()) do
			local node = self:AddNode("History", url);
			node:SetText(string.sub(url, 1, 25));
			node:SetTooltip(url);

			local wlst = self:EmbedButton(node, "GOLEM_ImageButton", 25, 0);
			wlst:SetIcon("fugue/quill.png");
			wlst:SetToolTip("Add to white list.");

			local blst = self:EmbedButton(node, "GOLEM_ImageButton", 50, 0);
			blst:SetIcon("fugue/exclamation-circle.png");
			blst:SetToolTip("Add to black list.");

			wlst.DoClick = function()
				self:ListedNode("White List", "White list", url, EXPR_PERMS.WhiteListURL, EXPR_PERMS.UnwhiteListURL);
			end;

			blst.DoClick = function()
				self:ListedNode("Black List", "Black list", url, EXPR_PERMS.BlackListURL, EXPR_PERMS.UnblackListURL);
			end;
		end
	end;

	rfsh.DoClick();

end

vgui.Register("GOLEM_E3URLTree", PANEL, "GOLEM_Tree");