
/****************************************************************************************************************************
	
****************************************************************************************************************************/
if CLIENT then 
	local b = 5;
	local cw, ch = 200, 32;
	local dw, dh = 200, 32;
	local wh = 75;
	local background = Material("e3Skin/PermissionsPanelBG.png");

/****************************************************************************************************************************
	Create a window used to display the controls for each gate.
****************************************************************************************************************************/
	local PERM_PANEL = {};

	function PERM_PANEL:Init()
		self:SetTall(ch);
		self:SetWide(cw);
		self:AddControls();
	end

	function PERM_PANEL:AddControls()
		self.controls = {};
		for key, data in pairs(EXPR_LIB.PERMS) do
			self:AddControl(key, data[2], data[3]);
		end
	end

	function PERM_PANEL:AddControl(name, image, desc)
		local control = self:Add("GOLEM_CheckBox");

		control.ChangedValue = function(this, value)
			self:ChangedValue(name, value);
		end;

		control:SetToolTip(name .. "\n" .. desc);
		control:Dock(RIGHT);

		self.controls[name] = control;
	end

	function PERM_PANEL:Update(entity)
		self.entity = entity;
		for perm, control in pairs(self.controls) do			
			control:SetValue( entity.context:getPerm(LocalPlayer(), perm), true);
		end
	end

	function PERM_PANEL:ChangedValue(perm, value)
		if IsValid(self.entity) then
			EXPR_LIB.SetPermission(self.entity, perm, value);
		end
	end

	vgui.Register("GOLEM_E3GatePerms", PERM_PANEL, "EditablePanel");

/****************************************************************************************************************************
	Create a window used to display the controls for each gate.
****************************************************************************************************************************/
	local ICON_PANEL = {};

	function ICON_PANEL:Init()
		self:SetTall(ch);
		self:SetWide(cw);
		self:AddControls();
	end

	function ICON_PANEL:AddControls()
		for key, data in pairs(EXPR_LIB.PERMS) do
			self:AddControl(key, data[2], data[3]);
		end
	end

	function ICON_PANEL:AddControl(name, image, desc)
		local control = self:Add("GOLEM_ImageButton");
		control:SetToolTip(name .. "\n" .. desc);
		control:SetMaterial(Material(image));
		control:Dock(RIGHT);
	end

	vgui.Register("GOLEM_E3GateIcons", ICON_PANEL, "EditablePanel");

/****************************************************************************************************************************
	We will list all our gates, so we need to create a display for that.
****************************************************************************************************************************/
	
	local GATE_PANEL = {};

	function GATE_PANEL:Init()
		self:SetHeight(b * 2 + ch);
		self.controls = self:Add("GOLEM_E3GatePerms");
		self.controls:Dock(RIGHT);
	end

	function GATE_PANEL:SetEntity(entity)
		self.entity = entity;
		self.controls:Update(entity);
	end

	function GATE_PANEL:Paint(w, h)
	    surface.SetDrawColor(90, 90, 90, 255);
	    surface.DrawRect(0, 0, w, h);

	    surface.SetMaterial(background);
	    surface.SetDrawColor(255, 255, 255, 255);

	    for x = 0, w, 100 do
	    	surface.DrawTexturedRect(x, 0, 100, 100);
	    end

	    if (IsValid(self.entity)) then
	    	local server_status = table.concat({
	    		"Server: ", self.entity:GetServerAverageCPU(), " / ", self.entity:GetServerTotalCPU(), " (", tostring(self.entity:GetServerWarning()), ")",
	    	});

	    	local client_status = table.concat({
	    		"Client: ", self.entity:GetClientAverageCPU(), " / ", self.entity:GetClientTotalCPU(), " (", tostring(self.entity:GetClientWarning()), ")"
	    	});

	   		draw.DrawText("Name: " .. self.entity:GetScriptName(), "DermaDefault", b, b, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT );
	   		draw.DrawText("Owner: " .. self.entity:GetPlayerName(), "DermaDefault", b, b + 20, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT );

	   		draw.DrawText(server_status, "DermaDefault", b + 400, b, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT );
	   		draw.DrawText(client_status, "DermaDefault", b + 400, b + 20, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT );
	   		//draw.DrawText(tostring(self.entity), "DermaDefault", b + 400, b + 20, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT );
	   	end
	end

	vgui.Register("GOLEM_E3GateEntry", GATE_PANEL, "EditablePanel");

/****************************************************************************************************************************
	We will need to house all this inside an editor tab, this is that panel.
****************************************************************************************************************************/
		
	local MENU_PANEL = {};

	function MENU_PANEL:Init()
		self.items = {};

		self.controls = self:Add( "EditablePanel");
		self.controls:SetTall(32);
		self.controls:DockPadding(5, 5, 5, 5);
		self.controls:Dock(TOP);

		self.refresh = self.controls:Add("GOLEM_ImageButton");
		self.refresh:SetMaterial(Material("fugue/arrow-circle.png"));
		self.refresh:Dock(LEFT);

		function self.refresh.DoClick(this)
			self:Update();
		end

		self.icons = self.controls:Add("GOLEM_E3GateIcons");
		self.icons:Dock(RIGHT);

		self.layout = self:Add( "DListLayout");
		self.layout:DockPadding(5, 5, 5, 5);
		self.layout:Dock(FILL);

		self:Update();
		self:SetSize(300, 100);
		
		timer.Create("GOLEM_Permissions", 5, 0, function() self:Update(); end);
	end

	function MENU_PANEL:addEntity(entity)
		if (IsValid(entity) and !self.items[entity]) then
			local pnl = vgui.Create("GOLEM_E3GateEntry");

			pnl:SetEntity(entity);

			self.layout:Add(pnl);

			self.items[entity] = pnl;
		end
	end

	function MENU_PANEL:removeEntity(entity)
		local pnl = self.items[entity];

		if (pnl) then
			self.items[entity] = nil;
			pnl:Remove();
		end
	end

	function MENU_PANEL:Update()
		for e, pnl in pairs(self.items) do
			pnl:Remove();
		end

		self.items = { };

		for _, ctx in pairs(EXPR_LIB.GetAll()) do
			self:addEntity(ctx.entity);
		end
	end

	function MENU_PANEL:Paint(w, h)
	    surface.SetDrawColor(30, 30, 30, 255)
	    surface.DrawRect(0, 0, w, h)
	end

	vgui.Register("GOLEM_E3GateMenu", MENU_PANEL, "EditablePanel");

/****************************************************************************************************************************
	set every thing up in the editor using the api.
****************************************************************************************************************************/
	hook.Add( "Expression3.AddGolemTabTypes", "PermissionsTab", function(editor) 
		editor:AddCustomTab( true, "expression 3", function( self )
			if self.Permissions then
				self.pnlSideTabHolder:SetActiveTab( self.Permissions.Tab )
				self.Permissions.Panel:RequestFocus( )
				return self.Permissions
			end

			local Panel = vgui.Create( "GOLEM_E3GateMenu" )
			local Sheet = self.pnlTabHolder:AddSheet( "", Panel, "fugue/question.png", function(pnl) self:CloseMenuTab( pnl:GetParent( ), true ) end )
			self.pnlTabHolder:SetActiveTab( Sheet.Tab )
			self.Permissions = Sheet
			Sheet.Panel:RequestFocus( )

			return Sheet
		end, function( self )
			self.Permissions = nil
		end );

		editor.tbRight:SetupButton( "Permissions", "fugue/question.png", TOP, function( ) editor:NewTab( "expression 3" ); end )
	end );
end

/****************************************************************************************************************************
	Inject the permissions system in e3 gates
****************************************************************************************************************************/

	local Owner = function(entity)
		local owner;

		if not IsValid(entity) then
			return;
		end
			
		if entity.CPPIGetOwner then
			owner = entity:CPPIGetOwner();
		end

		if not IsValid(owner) and entity.GetPlayer then
			owner = entity:GetPlayer();
		end

		if not IsValid(owner) and IsValid(entity.player) then
			owner = entity.player;
		end

		return owner;
	end

	local Set = function(entity, target, perm, value)
		--print(SERVER, "SET -> ", entity, target, perm, value);

		if not IsValid(entity) then return false; end
		if not IsValid(target) then return false; end

		local tid = target:UserID();
		local perms = entity.permissions[tid];

		if not perms then
			perms = { };
			entity.permissions[tid] = perms;
		end

		perms[perm] = value;

		return true;
	end

	local Get = function(entity, target, perm)
		--print(SERVER, "GET -> ", entity, target, perm);

		if not IsValid(entity) then return false; end
		if not IsValid(target) then return false; end
		
		local owner = Owner(entity);
		if IsValid(owner) and owner == target then return true; end

		local tid = target:UserID();
		local perms = entity.permissions[tid];
		if not perms then return false; end

		return perms[perm] or flase;
	end

	local PPCheck = function(entity, object, perm)
		local owner = Owner(object);
		if not IsValid(owner) then return false; end
		return Get(entity, owner, perm or "Prop-Control");
	end

	hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Permissions", function(entity, context, env)
		entity.permissions = entity.permissions or {};
		entity.getPerm = Get;
		entity.setPerm = Set;
		entity.getOwner = Owner;
		entity.ppCheck = PPCheck;

		context.permissions = entity.permissions;
		context.getPerm = function(context, target, perm) return Get(context.entity, target, perm); end;
		context.setPerm = function(context, target, perm, value) return Set(context.entity, target, perm, value); end;
		context.getOwner = function(context, target) return Owner(context.entity, target); end;
		context.ppCheck = function(context, target, perm) return PPCheck(context.entity, target, perm); end;
	end);

/****************************************************************************************************************************
	Server side handles.
****************************************************************************************************************************/

if SERVER then
	util.AddNetworkString( "e3_permission" )

	EXPR_LIB.SetPermission = function(entity, target, perm, value)
		Set(entity, target, perm, value);

		net.Start( "e3_permission" );
			net.WriteEntity(entity);
			net.WriteEntity(target);
			net.WriteString(perm);
			net.WriteBool(value);
		net.Broadcast();
	end;

	local cmd = function(target, cmd, args, line)
		if not args[3] then return; end
		if not IsValid(target) then return; end

		local entity = Entity(args[1]);
		if not IsValid(entity) then return; end

		Set(entity, target, args[2], tonumber(args[3]) > 0);
	end;

	concommand.Add("e3_permission", cmd);

end

/****************************************************************************************************************************
	Client side handles.
****************************************************************************************************************************/

if CLIENT then

	EXPR_LIB.SetPermission = function(entity, perm, value)
		if not IsValid(entity) then return; end
		Set(entity, LocalPlayer(), perm, value);
		RunConsoleCommand("e3_permission", entity:EntIndex(), perm, value and 1 or 0);
	end;

	net.Receive( "e3_permission", function(len)
		local entity = net.ReadEntity();
		local target = net.ReadEntity();
		local perm = net.ReadString();
		local value = net.ReadBool();

		if not IsValid(entity) then return; end
		if not IsValid(target) then return; end

		Set(entity, target, perm, value);
	end);

end

/****************************************************************************************************************************
	Create a permissons extention
****************************************************************************************************************************/

local extension = EXPR_LIB.RegisterExtension("permissons");

extension:RegisterPermission("Prop-Control", "fugue/controller-d-pad.png", "This gate is allowed to alter your props.");

extension:EnableExtension();
