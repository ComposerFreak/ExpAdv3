--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	The crazy attempt at breaking the mold.

  I will probably regret attempting this.

  I almost did until Tanknut came along, THANK YOU!
]]

AddCSLuaFile()

ENT.Type = "anim";
ENT.Base = "base_anim";
ENT.IsHologram = true;
ENT.Animated = true;
ENT.AutomaticFrameAdvance  = true;
ENT.RenderGroup = RENDERGROUP_BOTH;

--[[
  Editor Open / Close
]]

if CLIENT then

  hook.Add("Expression3.OpenGolem", "Expression3.GolemAnim", function()
    RunConsoleCommand("e3_show_golem_anim");
  end);

  hook.Add("Expression3.CloseGolem", "Expression3.GolemAnim", function()
    RunConsoleCommand("e3_hide_golem_anim");
  end);

end

if SERVER then

  concommand.Add("e3_show_golem_anim", function(player)
    if not IsValid(player) then return; end
    if IsValid(player.__e3_ring__) then return; end

    local ent = ents.Create("e3_ring");

    if ent then
      ent:SetParent(player);
      ent:Spawn();

      player.__e3_ring__ = ent;
    end
  end);

  concommand.Add("e3_hide_golem_anim", function(player)
    if not IsValid(player) then return; end
    if not IsValid(player.__e3_ring__) then return; end

    player.__e3_ring__:Remove();
    player.__e3_ring__ = nil;
  end);

end

--[[
  Material / RT
]]

if CLIENT then
  local createRingMat = function()
    local data = {
      ["$basetexture"] = "e3_ring_rt",
      ["$translucent"] = 1,
      --["$basetexturetransform"] = "center .5 .5 scale 1 1 rotate 0 translate 0 0",
    };

    EXPR_LIB.RING_RT = EXPR_LIB.RING_RT or GetRenderTarget( "e3_ring_rt", 512, 512);
    EXPR_LIB.RING_MAT = EXPR_LIB.RING_MAT or CreateMaterial("sprites/e3_ring_mat", "UnlitGeneric", data);
  end

  createRingMat();

end

--[[
  Ent init:D
]]

function ENT:Initialize()
  self:SetModel("models/tanknut/cylinder.mdl");
  self:SetSolid(SOLID_NONE);
  self:SetMoveType(MOVETYPE_NONE);
  self:DrawShadow(false);
end

--[[
  Rotation & Movment
]]

function ENT:Think()
  local player = self:GetParent();
  self:SetAngles( Angle(0, RealTime() * -10, 0) );

  if (IsValid(player)) then
    local height = (player:OBBMaxs() - player:OBBMins()).z;
    local off = 20 + math.abs( math.sin(CurTime() * 0.5) * (height - 20));
    self:SetPos(player:GetPos() + Vector(0, 0, off) );
  end

end

--[[
  Developemnt code.
]]

if (SERVER) then
  --[[hook.Add("InitPostEntity", "Epression3.RingTest", function()
    local ent = ents.Create("e3_ring");

    if ent then
      ent:SetPos( Vector(147, 210, -11942) );
      ent:Spawn();
    end
  end);]]

end

--[[
  Render the entity
]]

if CLIENT then

  local borderColor = Color(150, 34, 34, 255);

  surface.CreateFont( "E3_Ring_Font", {
  	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
  	extended = false,
  	size = 30,
  	weight = 300,
  	blursize = 0,
  	scanlines = 0,
  	antialias = true,
  	underline = false,
  	italic = false,
  	strikeout = false,
  	symbol = false,
  	rotary = false,
  	shadow = false,
  	additive = true,
  	outline = false,
  } );

  surface.CreateFont( "E3_Ring_Font_Smaller", {
  	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
  	extended = false,
  	size = 16,
  	weight = 300,
  	blursize = 0,
  	scanlines = 1,
  	antialias = true,
  	underline = false,
  	italic = false,
  	strikeout = false,
  	symbol = false,
  	rotary = false,
  	shadow = false,
  	additive = true,
  	outline = false,
  } );


  local y = 256;
  local h = 50;
  local b = 5;

  function ENT:GetPlayerName()
    local ply = self:GetParent();

    if not IsValid(ply) or not ply:IsPlayer() then
      return "This player";
    end

    return ply:GetName();
  end

  function ENT:DrawBackGround()
    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 150);
    surface.DrawRect(0, y - ((h * 0.5) + b), 512, b);

    surface.SetDrawColor(100, 0, 0, 100);
    surface.DrawRect(0, y - (h * 0.5), 512, h);

    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 150);
    surface.DrawRect(0, y + ((h * 0.5) - b), 512, b);
  end

  function ENT:DrawOutsideMaterial()
    local w, h = ScrW(), ScrH();

    render.PushRenderTarget(EXPR_LIB.RING_RT);
      render.Clear(0, 0, 0, 0);
      render.SetViewPort(0, 0, 512, 512);
        cam.Start2D();

          self:DrawBackGround();

          draw.DrawText( self:GetPlayerName() .. " is currently edditing", "E3_Ring_Font_Smaller", 256, y - 26, Color(255, 100, 100, 100), TEXT_ALIGN_CENTER );
          draw.DrawText( "Expression Advanced Three", "E3_Ring_Font", 256, y - 10, borderColor, TEXT_ALIGN_CENTER );

          cam.End2D()
        render.SetViewPort(0, 0, w, h);
      render.SetRenderTarget();

      EXPR_LIB.RING_MAT:SetTexture("$basetexture", EXPR_LIB.RING_RT);
  end

  function ENT:DrawInsideMaterial()
    local w, h = ScrW(), ScrH();

    render.PushRenderTarget(EXPR_LIB.RING_RT);
      render.Clear(0, 0, 0, 0);
      render.SetViewPort(0, 0, 512, 512);
        cam.Start2D();

          self:DrawBackGround();

          cam.End2D()
        render.SetViewPort(0, 0, w, h);
      render.SetRenderTarget();

      if EXPR_LIB.RING_MAT and EXPR_LIB.RING_RT then
        EXPR_LIB.RING_MAT:SetTexture("$basetexture", EXPR_LIB.RING_RT);
      end
  end

  function ENT:Draw()

    render.MaterialOverride(EXPR_LIB.RING_MAT);

    self:DrawInsideMaterial();
    self:SetModelScale(-1);
    self:DrawModel();

    self:DrawOutsideMaterial();
    self:SetModelScale(1);
    self:DrawModel();

    render.MaterialOverride();
  end
end
