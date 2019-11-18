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

		Golem.QueryString(add_icon, function(url)

			self:ListedNode("Black List", "Black list", url, EXPR_PERMS.BlackListURL, EXPR_PERMS.UnblackListURL);

		end, "", "Black list url");

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
	local edit = self:EmbedButton(node, "GOLEM_ImageButton", 25, 0);
	local del = self:EmbedButton(node, "GOLEM_ImageButton", 50, 0);

	edit:SetMaterial(edit_icon);
	del:SetMaterial(del_icon);
	
	edit.DoClick = function()
		
		Golem.QueryString(edit_icon, function(_url)
			
			add(_url);
			remove(url);
			node:SetText(_url);

		end, "", name);

	end;
	
	del.DoClick = function()
		remove(url)
		node:Remove();
	end;

	return node;
end

vgui.Register("GOLEM_E3URLTree", PANEL, "GOLEM_Tree");