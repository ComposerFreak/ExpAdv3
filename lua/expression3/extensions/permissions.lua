if CLIENT then 

/****************************************************************************************************************************
	Display panel
****************************************************************************************************************************/
	do
		local PANEL = {}

		function PANEL:Init()
			self.expanded = false;
		end

		function PANEL:SetEntity(entity)
			self.entity = entity;
			self:SetHeight(50);
		end

		function PANEL:Paint(w, h)
		    surface.SetDrawColor(90, 90, 90, 255);
		    surface.DrawRect(0, 0, w, h);

		    if (IsValid(self.entity)) then
		   		draw.DrawText(self.entity:GetScriptName(), "DermaDefault", 5, 5, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT );
		   		draw.DrawText(self.entity:GetPlayerName(), "DermaDefault", 5, 25, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT );
		   	end
		end

		vgui.Register("GOLEM_PermissionsPanel", PANEL, "EditablePanel");
	end

/****************************************************************************************************************************
	Menu panel
****************************************************************************************************************************/

	do
		local PANEL = {}

		function PANEL:Init()
			self.items = {};
			self.layout = vgui.Create( "DListLayout", self );
			self.layout:DockPadding(5, 5, 5, 5);
			self.layout:Dock(FILL);

			self:Update();
			self:SetSize(300, 100);
			timer.Create("GOLEM_Permissions", 5, 0, function() self:Update(); end);
		end

		function PANEL:addEntity(entity)
			if (IsValid(entity) and !self.items[entity]) then
				local pnl = vgui.Create("GOLEM_PermissionsPanel");

				pnl:SetEntity(entity);

				self.layout:Add(pnl);

				self.items[entity] = pnl;
			end
		end

		function PANEL:removeEntity(entity)
			local pnl = self.items[entity];

			if (pnl) then
				self.items[entity] = nil;
				pnl:Remove();
			end
		end

		function PANEL:Update()
			for e, pnl in pairs(self.items) do
				pnl:Remove();
			end

			self.items = { };

			for _, ctx in pairs(EXPR_LIB.GetAll()) do
				self:addEntity(ctx.entity);
			end
		end

		function PANEL:Paint(w, h)
		    surface.SetDrawColor(30, 30, 30, 255)
		    surface.DrawRect(0, 0, w, h)
		end

		vgui.Register("GOLEM_Permissions", PANEL, "EditablePanel");
	end

/****************************************************************************************************************************
	Register tab
****************************************************************************************************************************/

	hook.Add( "Expression3.AddGolemTabTypes", "PermissionsTab", function(editor) 
		editor:AddCustomTab( true, "expression 3", function( self )
			if self.Permissions then
				self.pnlSideTabHolder:SetActiveTab( self.Permissions.Tab )
				self.Permissions.Panel:RequestFocus( )
				return self.Permissions
			end

			local Panel = vgui.Create( "GOLEM_Permissions" )
			local Sheet = self.pnlTabHolder:AddSheet( "", Panel, "fugue/question.png", function(pnl) self:CloseMenuTab( pnl:GetParent( ), true ) end )
			self.pnlTabHolder:SetActiveTab( Sheet.Tab )
			self.Permissions = Sheet
			Sheet.Panel:RequestFocus( )

			return Sheet
		end, function( self )
			self.Permissions = nil
		end );

		editor.tbRight:SetupButton( "Permissions", "fugue/disks-black.png", TOP, function( ) editor:NewTab( "expression 3" ); end )
	end );
end














