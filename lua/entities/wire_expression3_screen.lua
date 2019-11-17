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

AddCSLuaFile();

ENT.Type 			= "anim";
ENT.Base 			= "wire_expression3_base";

ENT.PrintName       = "Expression 3 Screen";
ENT.Author          = "Rusketh";
ENT.Contact         = "";

ENT.Expression3 	= true;
ENT.Expression3_Screen 	= true;

EXPR3_DRAWSCREEN = false;

if (SERVER) then
	function ENT:Initialize()
		self.BaseClass.BaseClass.Initialize(self);
		self.Inputs = WireLib.CreateInputs( self, { } )
		self.Outputs = WireLib.CreateOutputs( self, { } )
		self:SetUseType(SIMPLE_USE)
	end
end

if (CLIENT) then
	function ENT:Initialize()
		self.bDrawSplash = true;
		self.GPU = GPULib.WireGPU(self)--, WIRE_GPU_HD);
	end

	function ENT:DrawEntityOutline() end

	function ENT:Draw()
		self:DrawModel()

		Wire_Render(self)

		self.GPU:RenderToGPU( self:RenderFromEvent() );

		self.GPU:Render()
	end

	function ENT:RenderFromEvent()
		return function()
			if not self.NoScreenRefresh then render.Clear( 0, 0, 0, 255 ); end
			
			EXPR3_DRAWSCREEN = true;

			local res = self.GPU.Resolution or 512;

			local status = self:CallEvent("", 0, "RenderScreen", {"n", res}, {"n", res}, {"e", self});
			
			EXPR3_DRAWSCREEN = false;

			if status == nil then self:RenderSplashScreen(res); end

			hook.Call("Expression3.Entity.PostDrawScreen", self.context, self);
		end;
	end

	local background = surface.GetTextureID("omicron/bulb");

	function ENT:RenderSplashScreen(res, force)
		force = force or not self:IsRunning();
		if self.bDrawSplash or force then
			surface.SetTexture(background);
			surface.SetDrawColor(Color(255, 255, 255, 255));
			surface.DrawTexturedRect(0, 0, res, res);
			self.bDrawSplash = false;
		end
	end

end

function ENT:OnRemove()
	if (CLIENT) then self.GPU:Finalize() end
	self:ShutDown();
end

function ENT:GetCursor(ply)
	-- LITTERALY RIPPED OUT OF EGP!
	-- CURTOSY OF DIVRAN!

	if (not ply or not ply:IsValid() or not ply:IsPlayer()) then
		return -1, -1;
	end

	local Normal, Pos, monitor, Ang
	
	-- Get monitor screen pos & size
	monitor = WireGPU_Monitors[ self:GetModel() ]

	-- Monitor does not have a valid screen point
	if (not monitor) then
		return -1,-1
	end

	Ang = self:LocalToWorldAngles( monitor.rot )
	Pos = self:LocalToWorld( monitor.offset )

	Normal = Ang:Up()

	local Start = ply:GetShootPos()
	local Dir = ply:GetAimVector()

	local A = Normal:Dot(Dir)

	-- If ray is parallel or behind the screen
	if (A == 0 or A > 0) then
		return -1, -1
	end

	local B = Normal:Dot(Pos-Start) / A

	if (B >= 0) then
		local HitPos = WorldToLocal( Start + Dir * B, Angle(), Pos, Ang )
		local x = (0.5+HitPos.x/(monitor.RS*512/monitor.RatioX)) * 512
		local y = (0.5-HitPos.y/(monitor.RS*512)) * 512
		if (x < 0 or x > 512 or y < 0 or y > 512) then
			return -1,-1
		end -- Aiming off the screen
		return x,y
	end

	return -1,-1
end

if (SERVER) then
	util.AddNetworkString("Expression3.Screen.Use");

	function ENT:Use(ply)
		local x, y = self:GetCursor(ply);
		self:CallEvent("", 0, "UseScreen", {"n", x}, {"n", y}, {"p", ply}, {self, "e"});

		net.Start("Expression3.Screen.Use");
			net.WriteEntity(self);
			net.WriteEntity(ply);
			net.WriteInt(x, 16);
			net.WriteInt(y, 16);
		net.Broadcast();
	end
end

if (CLIENT) then
	net.Receive("Expression3.Screen.Use", function()
		local ent = net.ReadEntity();
		local ply = net.ReadEntity();
		local x = net.ReadInt(16);
		local y = net.ReadInt(16);

		if (IsValid(ent) and ent.Expression3_Screen) then
			ent:CallEvent("", 0, "UseScreen", {"n", x}, {"n", y}, {"p", ply}, {ent, "e"});
		end
	end);
end