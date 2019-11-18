if SERVER then return; end

/*********************************************************************************
	Browser
*********************************************************************************/
local PANEL = {};

function PANEL:Init()
	self.entities = {};
	
	self:Reload();
end

function PANEL:Reload(b)
	if not b then 
		self:AddGlobalNode();
		self.entities = {};
	end

	for _, ctx in pairs(EXPR_LIB.GetAll()) do
		self:AddEntity(ctx.entity);
	end
end

function PANEL:AddGlobalNode()
	local oNode = self:AddNode("Global");

	oNode:SetIcon("fugue/globe-network.png");

	self:AddGlobalURLNode(oNode);

	for perm, data in pairs(EXPR_LIB.PERMS) do
		
		local pNode = self:AddNode(oNode, perm);
		local btn = self:EmbedButton(pNode, "GOLEM_CheckBox", 24, 0);
		
		pNode:SetIcon(data[2]);

		btn:SetTick(nil, nil, EXPR_ALLOW);
		btn:SetCross(nil, nil, EXPR_DENY);
		btn:AddState("friends", EXPR_FRIEND, "fugue/hand-shake.png");

		btn:PollFromCallback(function()
			return EXPR_PERMS.GetGlobal(LocalPlayer(), perm), true;
		end);

		btn.ChangedValue = function(value)
			EXPR_PERMS.SetGlobalPermission(perm, value);
		end;

	end

end

function PANEL:AddGlobalURLNode(oNode)

	local pNode = self:AddNode(oNode, "URL Filter Mode");
	local btn = self:EmbedButton(pNode, "GOLEM_StateBox", 24, 0);
	
	pNode:SetIcon("fugue/monitor-network.png");

	btn:AddState("deny", EXPR_DENY, "fugue/cross-button.png");
	btn:AddState("whitelist", EXPR_WHITE_LIST, "fugue/quill.png");
	btn:AddState("blacklist", EXPR_BLACK_LIST, "fugue/exclamation-circle.png");
	btn:AddState("friends", EXPR_FRIENDS, "fugue/hand-shake.png");

	btn:PollFromCallback(function()
		return EXPR_PERMS.GetGlobal(LocalPlayer(), "URL"), true;
	end);

	btn.ChangedValue = function(value)
		EXPR_PERMS.SetGlobalPermission("URL", value);
	end;

end

function PANEL:AddEntity(entity)

	if entity and not self.entities[entity] then

		local oName = entity:GetPlayerName() or "Disconnected";
		local eName = entity:GetScriptName() or "generic";
		
		eName = string.Explode("\n", eName)[1];
		eName = string.format("(%i) - %s", entity:EntIndex(), eName);

		local oNode = self:AddNode(oName);
		local eNode = self:AddNode(oNode, eName);

		oNode:SetIcon("fugue/xfn.png");
		eNode:SetIcon("fugue/monitor-window-3d.png");

		self:AddEntityURLNode(eNode, entity);

		for perm, data in pairs(EXPR_LIB.PERMS) do
			
			local pNode = self:AddNode(eNode, perm);
			local btn = self:EmbedButton(pNode, "GOLEM_CheckBox", 24, 0);
			
			pNode:SetIcon(data[2]);

			btn:SetTick(nil, nil, EXPR_ALLOW);
			btn:SetCross(nil, nil, EXPR_DENY);
			btn:AddState("global", EXPR_FRIEND, "fugue/globe-network.png");

			btn:PollFromCallback(function()
				return EXPR_PERMS.Get(entity, LocalPlayer(), perm, true), true;
			end);

			btn.ChangedValue = function(value)
				EXPR_PERMS.Set(entity, LocalPlayer(), perm, value);
			end;
		end

		self.entities[entity] = eNode;

	end

end

function PANEL:AddEntityURLNode(eNode, entity)

	local pNode = self:AddNode(eNode, "URL Filter Mode");
	local btn = self:EmbedButton(pNode, "GOLEM_StateBox", 24, 0);
	
	pNode:SetIcon("fugue/monitor-network.png");

	btn:AddState("deny", EXPR_DENY, "fugue/cross-button.png");
	btn:AddState("whitelist", EXPR_WHITE_LIST, "fugue/quill.png");
	btn:AddState("blacklist", EXPR_BLACK_LIST, "fugue/exclamation-circle.png");
	btn:AddState("global", EXPR_GLOBAL, "fugue/globe-network.png");

	btn:PollFromCallback(function()
		return EXPR_PERMS.GetURLPerm(entity, true), true;
	end);

	btn.ChangedValue = function(value)
		EXPR_PERMS.Set(entity, LocalPlayer(), "URL", value);
	end;

end

function PANEL:RemoveEntity(entity)
	if entity then
		local node = self.entities[entity];
		if IsValid(node) then node:Remove(); end
		self.entities[entity] = nil;
	end
end

function PANEL:Think()
	local time = CurTime();

	if not self.m_nNextUpdate or self.m_nNextUpdate <= time then

		local entities = {};

		for entity, node in pairs(self.entities) do
			if not IsValid(entity) then
				if IsValid(node) then node:Remove(); end
			else
				entities[entity] = node;
			end
		end

		self.entities = entities;

		self:Reload(true);

		self.m_nNextUpdate = time;

	end

end

vgui.Register("GOLEM_E3PermissionTree", PANEL, "GOLEM_Tree");