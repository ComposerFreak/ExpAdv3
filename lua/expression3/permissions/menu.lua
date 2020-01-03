if SERVER then return; end

/*********************************************************************************
	Tabbed Menu Panel
*********************************************************************************/
do
	local PANEL = {};

	function PANEL:Init()
		self:AddTab("Permissions", "fugue/xfn.png", "GOLEM_E3PermissionTree");
		self:AddTab("HTTP", "fugue/globe-network.png", "GOLEM_E3URLTree");

		self:SetActiveTab("Permissions");
	end;
		
	function PANEL:Paint( w, h ) 
		surface.SetDrawColor(30, 30, 30, 255)
		surface.DrawRect(0, 0, w, h)
	end

	vgui.Register("GOLEM_E3Permissions", PANEL, "GOLEM_SimpleTabs");
end

/*********************************************************************************
	Add our permissions menu.
*********************************************************************************/

hook.Add( "Expression3.AddGolemTabTypes", "PermssionsTab", function(editor)
	editor:AddCustomTab(false, "permissions", function( self )
		if self.Permissions then
			self.pnlSideTabHolder:SetActiveTab( self.Permissions.Tab )
			self.Permissions.Panel:RequestFocus( )
			return self.Permissions
		end

		local Panel = vgui.Create( "GOLEM_E3Permissions" )
		local Sheet = self.pnlSideTabHolder:AddSheet( "", Panel, "fugue/controller-d-pad.png", function(pnl) self:CloseMenuTab( pnl:GetParent( ), true ) end )
		self.pnlSideTabHolder:SetActiveTab( Sheet.Tab )
		self.Permissions = Sheet
		Sheet.Panel:RequestFocus( )

		return Sheet
	end, function( self )
		self.Permissions = nil
	end );

	editor.tbRight:SetupButton( "Permssions", "fugue/controller-d-pad.png", TOP, function( ) editor:NewMenuTab( "permissions" ); end )
end);