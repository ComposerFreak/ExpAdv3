--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Expression 3 Base::
]]

include("shared.lua");

/****************************************************************************************************************************
	Client Side Validation
****************************************************************************************************************************/

local ValidateError;

function ValidateError(Thrown )
	local Error;

	if (istable(Thrown)) then
		if (string.sub(Thrown.msg, -1) == ".") then
			Thrown.msg = string.sub(Thrown.msg, 1, -2);
		end

		Error = string.format("%s, at line %i char %i.", Thrown.msg, Thrown.line, Thrown.char);

		if (Thrown.file) then
			Error = string.format("%s in %s.txt", string.sub(Error, 1, -2), Thrown.file);
		end
	else
		Error = Thrown
		Thrown = nil
	end

	chat.AddText(Color(255, 255, 255), "Upload failed see editor console.");
	Golem.Print(Error);
end

/****************************************************************************************************************************
	Server To Client Transfer
****************************************************************************************************************************/

function ENT:ReceiveFromServer(ply, script, files)
	timer.Simple(1, function()
		if (IsValid(self)) then
			self.player = ply;
			self:SetCode(script, files, true);
		end
	end);
end

function ENT:PostInitScript()
	net.Start("Expression3.InitializedClient");
		net.WriteEntity(self);
	net.SendToServer();
end

/****************************************************************************************************************************
	Client Side Overlay
****************************************************************************************************************************/

function ENT:GetOverlayData()
	return {txt = table.concat({
		"::Expression 3::",
		self:GetPlayerName(),
		self:GetScriptName() or "generic",
		"----------------------",
		"SEVER: " .. self:GetServerDisplayData(),
		"CLIENT: " .. self:GetClientDisplayData(),
	}, "\n")};
end

local function percent(part, whole)
	part, whole = part or 0, whole or 0;
	
	if part <= 0 or whole <= 0 then return 0; end
	
	local p = math.ceil((part / whole) * 100);
	
	if p < 0 then p = 0; end
	
	return p;
end

function ENT:GetDisplayLine(online, soft, average, warning)
	if not online then return "Offline"; end
	return math.ceil(average * 100) .. "% (" .. math.ceil(soft * 1000000) .. "us" .. (warning and "!" or "") .. ")";
end

function ENT:GetClientDisplayData()
	return self:GetDisplayLine(self:GetClientOnline(), self:GetClientSoftCPU(), self:GetClientAverageCPU(), self:GetClientWarning());
end

function ENT:GetServerDisplayData()
	return self:GetDisplayLine(self:GetServerOnline(), self:GetServerSoftCPU(), self:GetServerAverageCPU(), self:GetServerWarning());
end

/****************************************************************************************************************************
	Permissions Menu
****************************************************************************************************************************/

function ENT:OpenPermissionsMenu()

	if IsValid(self.FeaturesPanel) then
		self.FeaturesPanel:Remove();
	end

	local status, results = self:CallEvent("t", 0, "GatherPermissions");

	if status and results then
		local result = results[1];

		if result and result.size > 0 then

			local perms = {};

			for _, v in pairs(result.tbl) do
				if v[1] == "s" then
					local perm = v[2];
					
					if EXPR_LIB.PERMS[perm] then
						perms[#perms + 1] = perm;
					end
				end
			end

			if #perms > 0 then

				local pnl = vgui.Create("E3_TekMenu");
				pnl:SetUp(self, perms);
				pnl:Center();
				pnl:MakePopup( );

				self.FeaturesPanel = pnl

				return true;
			end
		end
	end

	return false;
end

/****************************************************************************************************************************
	Context Menu
****************************************************************************************************************************/

local function Filter( self, Entity, Player )
	if not (IsValid( Entity) and Entity.Expression3) then
		return false;
	end

	return true
end

local function MenuOpen( ContextMenu, Option, Entity, Trace )
	local SubMenu = Option:AddSubMenu( )

	SubMenu:AddOption("Show Permissions", function()
		Entity:OpenPermissionsMenu();
	end);
end

properties.Add( "expadv", {
	MenuLabel = "Expression Advanced",
	MenuIcon  = "fugue/gear.png",
	Order = 999,
	Filter = Filter,
	MenuOpen = MenuOpen,
	Action = function( ) end,
} ); -- We wont use recieve here, Send it yourself :D

/****************************************************************************************************************************
	Add a pulsing effect over the entity.
****************************************************************************************************************************/

function ENT:DrawPulse(red, green, blue)
	if self == halo.RenderedEntity() then return; end

    local radius, width = (self.radius or 1) + 0.1, Lerp(self.radius or 0, 5, 15)
    
    if radius > 150 then radius = 0 end
    
    self.radius = radius

    local pos = self:LocalToWorld(self:OBBCenter());

    if self:GetModel( ) == "models/lemongate/lemongate.mdl" then
        pos = self:GetAttachment(self:LookupAttachment("fan_attch")).Pos;
    end

    local p, a, r = pos, self:GetAngles(), 0.1;

    render.SetStencilEnable( true );
    render.SetStencilWriteMask( 3 );
    render.SetStencilTestMask( 3 );
    render.ClearStencil( );

    render.SetStencilReferenceValue(1);
    render.SetStencilPassOperation( STENCIL_REPLACE );
    render.SetStencilFailOperation( STENCIL_REPLACE );
    render.SetStencilZFailOperation( STENCIL_REPLACE );

    render.SetStencilCompareFunction(STENCIL_NEVER);

    cam.Start3D2D(p, a, r);
        for i = 0, 4 do
            surface.SetDrawColor(Color(0, 0, 255, 255));
            surface.DrawTexturedRectRotated(0, 0, (radius) * 2, (radius) * 2, i * 45);
        end
    cam.End3D2D();

    render.SetStencilReferenceValue(1);
    render.SetStencilPassOperation( STENCIL_ZERO );
    render.SetStencilFailOperation( STENCIL_ZERO );
    render.SetStencilZFailOperation( STENCIL_ZERO );

    render.SetStencilCompareFunction(STENCIL_NEVER);

    cam.Start3D2D(p, a, r);
        for i = 0, 4 do
            surface.SetDrawColor(Color(0, 0, 255, 255));
            surface.DrawTexturedRectRotated(0, 0, (radius - width) * 2, (radius - width) * 2, i * 45);
        end
    cam.End3D2D();

    render.SetStencilCompareFunction(STENCIL_EQUAL);

    render.SetColorModulation(red, green, blue);

    self:DrawModel();

    render.SetColorModulation(1,1,1);
    render.SetStencilEnable( false );
end

/****************************************************************************************************************************
	Custom Draw Function
****************************************************************************************************************************/

function ENT:Draw()
	self:DoNormalDraw(true);
	
	if not self:GetServerOnline() then
		self:DrawPulse(1, 0, 0);
	end
	
	Wire_Render(self);
end