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
      ent:SetPos(player:GetPos());
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
  local data = {
    ["$basetexture"] = "e3_ring_rt",
    ["$translucent"] = 1,
    ["$basetexturetransform"] = "center .5 .5 scale -1 1 rotate 0 translate 0 0",
  };

  EXPR_LIB.RING_RT = EXPR_LIB.RING_RT or GetRenderTarget( "e3_ring_rt", 512, 512);
  EXPR_LIB.RING_MAT = EXPR_LIB.RING_MAT or CreateMaterial("sprites/e3_ring_mat", "UnlitGeneric", data);
end

--[[
  Ent init:D
]]

function ENT:Initialize()
  self:SetModel("models/props_phx/construct/glass/glass_curve360x1.mdl");
  self:SetModelScale( -1 );
  self:SetSolid(SOLID_NONE);
  self:SetMoveType(MOVETYPE_NONE);
  self:DrawShadow(false);
end

--[[
  Rotation
]]

function ENT:Think()
  self:SetAngles( Angle(180, RealTime() * -10, 0) );
end

--[[
  Render the entity
]]

if CLIENT then

  local CogColor = Color(150, 34, 34, 255);
	local CogTexture = surface.GetTextureID("expression 2/cog");

  local fone = surface.CreateFont( "E3_Ring_Font", {
  	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
  	extended = false,
  	size = 50,
  	weight = 500,
  	blursize = 0,
  	scanlines = 0,
  	antialias = true,
  	underline = false,
  	italic = false,
  	strikeout = false,
  	symbol = false,
  	rotary = false,
  	shadow = true,
  	additive = false,
  	outline = false,
  } );

  function ENT:DrawMaterial()
      surface.SetDrawColor(0, 0, 0, 0);
      surface.DrawRect(0, 100, 512, 100);

      surface.SetTexture(CogTexture);
			surface.SetDrawColor(CogColor.r, CogColor.g, CogColor.b, 255);
			surface.DrawTexturedRectRotated(50, 150, 80, 80, RealTime() * 10);

      draw.DrawText( "Expression Three", "E3_Ring_Font", 290, 130, CogColor, TEXT_ALIGN_CENTER );
  end

  function ENT:Draw()
    local w, h = ScrW(), ScrH();

    render.PushRenderTarget(EXPR_LIB.RING_RT);
      render.Clear(0, 0, 0, 0);
      render.SetViewPort(0, 0, 512, 512);
        cam.Start2D();

          self:DrawMaterial();

        cam.End2D()
      render.SetViewPort(0, 0, w, h);
    render.SetRenderTarget();

    EXPR_LIB.RING_MAT:SetTexture("$basetexture", EXPR_LIB.RING_RT);

    render.MaterialOverride(EXPR_LIB.RING_MAT);

    self:DrawModel();

    render.MaterialOverride();
  end
end
