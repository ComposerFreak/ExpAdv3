--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Hologram Extension::
]]

local Models;
local RateCounter, PlayerCounter;
local max, rate, clips, size, any;

local def = function() end;
local LowerCount, SetModel, Create = def, def, def;
-- Clientside wont need the actual functions.

--[[
	Server side limits
]]

if (SERVER) then
	RateCounter = {};
	PlayerCounter = {};

	local a = CreateConVar("wire_expression3_hologram_max", 250);
	local b = CreateConVar("wire_expression3_hologram_rate", 50);
	local c = CreateConVar("wire_expression3_hologram_clips", 5);
	local d = CreateConVar("wire_expression3_hologram_size", 50);
	local e = CreateConVar("wire_expression3_hologram_model_any", 1);

	timer.Create("Expression3.Hologram.Refresh", 1, 0, function()
		max = a:GetInt();
		rate = b:GetInt();
		clips = c:GetInt();
		size = d:GetInt();
		any = e:GetBool();

		RateCounter = { }
	end);

	--[[
		Hooks
	]]

	hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Holograms", function(entity, ctx, env)
		ctx.data.holograms = {};
		ctx.data.hologramIDs = {};

		local ply = entity.player;
		if (not RateCounter[ply]) then RateCounter[ply] = 0 end
		if (not PlayerCounter[ply]) then PlayerCounter[ply] = 0 end
	end);

	hook.Add("Expression3.Entity.Stop", "Expression3.Holograms",function(entity, ctx)
		for _, holo in pairs( ctx.data.holograms or {}) do
			if IsValid(holo) then
				holo:Remove();
			end
		end

		ctx.data.holograms = nil
	end);

	hook.Add("PlayerDisconnected", "Expression3.Holograms", function( ply )
		for _, ctx in pairs(EXPR_LIB.GetAll()) do
			if (ctx.player == ply) then
				for _, holo in pairs( ctx.data.holograms ) do
					if IsValid(holo) then
						holo:Remove();
					end
				end

				ctx.data.holograms = nil
			end
		end
	end )

	--[[
		Out util functions, more then util more like super important.
	]]

	LowerCount = function( self )
		if IsValid( self.player ) then
			PlayerCounter[self.player] = PlayerCounter[self.player] - 1
		end
	end;

	SetModel = function(ctx, holo, model )
		local ValidModel = Models[ model or "sphere" ];

		if ValidModel then
			if holo.IsHologram and holo.player == ctx.player then
				holo:SetModel( "models/holograms/" .. ValidModel .. ".mdl" );
			end
		elseif not any then
			ctx:Throw( "hologram", "Invalid model set " .. model );
		elseif holo.IsHologram and holo.player == ctx.player then
			holo:SetModel( ValidModel or model );
		end
	end;

	function Create( ctx, model, pos, ang )
		local ent, ply = ctx.entity, ctx.player;
		local nrate, ncount = RateCounter[ply] or 0, PlayerCounter[ply] or 0

		if nrate >= rate then
			ctx:Throw("Hologram cooldown reached.");
		elseif ncount >= max then
			ctx:Throw("Hologram max reached.");
		end

		local holo = ents.Create("wire_expression3_hologram");

		if not IsValid(holo) then
			ctx:Throw("Failed to create hologram.");
		end

		RateCounter[ply] = nrate + 1;
		PlayerCounter[ply] = ncount + 1;

		holo.player = ply;
		holo:Spawn( );
		holo:Activate( );
		holo.LowerCount = LowerCount;

		ctx.data.holograms[#ctx.data.holograms + 1] = holo;
		ctx.data.hologramIDs[#ctx.data.hologramIDs + 1] = holo;

		if CPPI then holo:CPPISetOwner( ply ) end

		SetModel( ctx, holo, model or "sphere" );

		if not pos then
			holo:SetPos( ent:GetPos( ) );
		else
			holo:SetPos( pos );
		end

		if not ang then
			holo:SetAngles( ent:GetAngles( ) );
		else
			holo:SetAngles( ang );
		end

		return holo;
	end;

	--[[
		Model  List
	]]

	Models = {
		["cone"]              = "cone",
		["cube"]              = "cube",
		["cylinder"]          = "cylinder",
		["hq_cone"]           = "hq_cone",
		["hq_cylinder"]       = "hq_cylinder",
		["hq_dome"]           = "hq_dome",
		["hq_hdome"]          = "hq_hdome",
		["hq_hdome_thick"]    = "hq_hdome_thick",
		["hq_hdome_thin"]     = "hq_hdome_thin",
		["hq_icosphere"]      = "hq_icosphere",
		["hq_sphere"]         = "hq_sphere",
		["hq_torus"]          = "hq_torus",
		["hq_torus_thick"]    = "hq_torus_thick",
		["hq_torus_thin"]     = "hq_torus_thin",
		["hq_torus_oldsize"]  = "hq_torus_oldsize",
		["hq_tube"]           = "hq_tube",
		["hq_tube_thick"]     = "hq_tube_thick",
		["hq_tube_thin"]      = "hq_tube_thin",
		["hq_stube"]          = "hq_stube",
		["hq_stube_thick"]    = "hq_stube_thick",
		["hq_stube_thin"]     = "hq_stube_thin",
		["icosphere"]         = "icosphere",
		["icosphere2"]        = "icosphere2",
		["icosphere3"]        = "icosphere3",
		["plane"]             = "plane",
		["prism"]             = "prism",
		["pyramid"]           = "pyramid",
		["sphere"]            = "sphere",
		["sphere2"]           = "sphere2",
		["sphere3"]           = "sphere3",
		["tetra"]             = "tetra",
		["torus"]             = "torus",
		["torus2"]            = "torus2",
		["torus3"]            = "torus3",

		["hq_rcube"]          = "hq_rcube",
		["hq_rcube_thick"]    = "hq_rcube_thick",
		["hq_rcube_thin"]     = "hq_rcube_thin",
		["hq_rcylinder"]      = "hq_rcylinder",
		["hq_rcylinder_thick"]= "hq_rcylinder_thick",
		["hq_rcylinder_thin"] = "hq_rcylinder_thin",
		["hq_cubinder"]       = "hq_cubinder",
		["hexagon"]           = "hexagon",
		["octagon"]           = "octagon",
		["right_prism"]       = "right_prism",

		// Removed models with their replacements

		["dome"]             = "hq_dome",
		["dome2"]            = "hq_hdome",
		["hqcone"]           = "hq_cone",
		["hqcylinder"]       = "hq_cylinder",
		["hqcylinder2"]      = "hq_cylinder",
		["hqicosphere"]      = "hq_icosphere",
		["hqicosphere2"]     = "hq_icosphere",
		["hqsphere"]         = "hq_sphere",
		["hqsphere2"]        = "hq_sphere",
		["hqtorus"]          = "hq_torus_oldsize",
		["hqtorus2"]         = "hq_torus_oldsize",

		// HQ models with their short names

		["hqhdome"]          = "hq_hdome",
		["hqhdome2"]         = "hq_hdome_thin",
		["hqhdome3"]         = "hq_hdome_thick",
		["hqtorus3"]         = "hq_torus_thick",
		["hqtube"]           = "hq_tube",
		["hqtube2"]          = "hq_tube_thin",
		["hqtube3"]          = "hq_tube_thick",
		["hqstube"]          = "hq_stube",
		["hqstube2"]         = "hq_stube_thin",
		["hqstube3"]         = "hq_stube_thick",
		["hqrcube"]          = "hq_rcube",
		["hqrcube2"]         = "hq_rcube_thick",
		["hqrcube3"]         = "hq_rcube_thin",
		["hqrcylinder"]      = "hq_rcylinder",
		["hqrcylinder2"]     = "hq_rcylinder_thin",
		["hqrcylinder3"]     = "hq_rcylinder_thick",
		["hqcubinder"]       = "hq_cubinder"
	}

	hook.Call("Expression3.Holograms.AllModels", Models);
end

--[[
	Register Extension and the library.
]]

local extension = EXPR_LIB.RegisterExtension("holograms");

extension:SetServerState();

extension:RegisterLibrary("hololib");

extension:RegisterFunction("hololib", "limit", "", "n", 1, function()
	return max;
end, false);

extension:RegisterFunction("hololib", "spawnRate", "", "n", 1, function()
	return rate;
end, false);

extension:RegisterFunction("hololib", "clipLimit", "", "n", 1, function()
	return clips;
end, false);

extension:RegisterFunction("hololib", "maxScale", "", "n", 1, function()
	return size;
end, false);

extension:RegisterFunction("hololib", "anyModel", "", "b", 1, function()
	return any;
end, false);

extension:RegisterFunction("hololib", "modelName", "s", "s", 1, function(m)
	return Models[m] or "";
end, false);


--[[
	Register Class
]]

extension:RegisterExtendedClass("h", {"hologram"}, "e", function(entity)
	return IsValid(entity) and entity:GetClass() == "wire_expression3_hologram";
end, IsValid);

--[[
	Casting to entity
]]

-- Hologram -> Entity
extension:RegisterCastingOperator("e", "h", function(ctx, obj)
	return obj;
end, false);

-- Entity <- Hologram
extension:RegisterCastingOperator("h", "e", function(ctx, obj)
	if (not IsValid(obj) and obj:GetClass() == "wire_expression3_hologram") then
		return obj;
	end

	ctx:Throw("Attempted to cast none hologram entity to hologram.");
end, false);

--[[
	Create the holograms
]]

extension:RegisterFunction("hololib", "create", "", "h", 1, Create);
extension:RegisterFunction("hololib", "create", "s", "h", 1, Create);
extension:RegisterFunction("hololib", "create", "s,v", "h", 1, Create);
extension:RegisterFunction("hololib", "create", "s,v,a", "h", 1, Create);

extension:RegisterFunction("hololib", "canCreate", "", "b", 1, function(ctx)
	local ply = xtx.player;
	return not ((RateCounter[ply] or 0) >= rate or (PlayerCounter[ply] or 0) >= max);
end, false);

extension:RegisterMethod("h", "remove", "", "", 0, function(ctx, holo)
	if (IsValid(holo) and holo.player == ctx.player) then
		holo:Remove();
	end
end, false);

--[[
	IDS, for e2 style.
]]

extension:RegisterFunction("hololib", "getByID", "n", "e", 1, function(ctx, id)
	return ctx.data.hologramIDs[id] or Entity(0);
end, false);

extension:RegisterMethod("h", "setID", "n", "", 0, function(ctx, holo, id)
	if id > 0 and IsValid(holo) and holo.IsHologram then
		local known = ctx.data.hologramIDs[id];
		if IsValid(known) then known.ID = -1 end
		if holo.ID then ctx.data.hologramIDs[ holo.ID ] = nil end
		ctx.data.hologramIDs[id] = holo;
		holo.ID = id;
	end
end, false)

extension:RegisterMethod("h", "getID", "", "n", 1, function(ctx, holo)
	if (IsValid(holo) and holo.IsHologram) then
		return holo.ID or -1;
	end; return -1;
end, false)

--[[
	Methods
]]

extension:RegisterMethod("h", "getModel", "", "s", 1, "GetModel", false);

extension:RegisterMethod("h", "setModel", "s", "", 0, SetModel, false);

extension:RegisterMethod("h", "setPos", "v", "", 0, function(ctx, holo, v)
	if (IsValid(holo) and holo.player == ctx.player) then
		if not (v.x ~= v.x or v.y ~= v.y or v.z ~= v.z) then
			holo:SetPos(v);
		end
	end
end, false);

extension:RegisterMethod("h", "moveTo", "v,n", "", 0, function(ctx, holo, v, n)
	if (IsValid(holo) and holo.player == ctx.player) then
		if not (v.x ~= v.x or v.y ~= v.y or v.z ~= v.z) then
			holo:MoveTo(v, n);
		end
	end
end, false);

extension:RegisterMethod("h", "startMove", "v", "", 0, function(ctx, holo, v)
	if (IsValid(holo) and holo.player == ctx.player) then
		if not (v.x ~= v.x or v.y ~= v.y or v.z ~= v.z) then
			holo:StartMove(v);
		end
	end
end, false);

extension:RegisterMethod("h", "stopMove", "", "", 0, function(ctx, holo)
	if (IsValid(holo) and holo.player == ctx.player) then
		holo:StopMove( )
	end
end, false);

----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "setAng", "a", "", 0, function(ctx, holo, a)
	if (IsValid(holo) and holo.player == ctx.player) then
		if not (a.p ~= a.p or a.y ~= a.y or a.r ~= a.r) then
			holo:SetAngles(a);
		end
	end
end, false);

extension:RegisterMethod("h", "rotateTo", "a,n", "", 0, function(ctx, holo, a, n)
	if (IsValid(holo) and holo.player == ctx.player) then
		if not (a.p ~= a.p or a.y ~= a.y or a.r ~= a.r) then
			holo:RotateTo(a, n);
		end
	end
end, false);

extension:RegisterMethod("h", "startRotate", "a", "", 0, function(ctx, holo, a)
	if (IsValid(holo) and holo.player == ctx.player) then
		holo:StartRotate(a);
	end
end, false);

extension:RegisterMethod("h", "stopRotate", "", "", 0, function(ctx, holo)
	if (IsValid(holo) and holo.player == ctx.player) then
		holo:StopRotate();
	end
end, false);

----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "setScale", "v", "", 0, function(ctx, holo, v)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetScale( v );
	end
end, false);

extension:RegisterMethod("h", "setScaleUnits", "v", "", 0, function(ctx, holo, v)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetScaleUnits( v );
	end
end, false);

extension:RegisterMethod("h", "scaleTo", "v,n", "", 0, function(ctx, holo, v, n)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:ScaleTo( v, n );
	end
end, false);

extension:RegisterMethod("h", "scaleToUnits", "v,n", "", 0, function(ctx, holo, v, n)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:ScaleToUnits( v, n );
	end
end, false);

extension:RegisterMethod("h", "stopScale", "", "", 0, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:StopScale( );
	end
end, false);

extension:RegisterMethod("h", "getScale", "", "v", 1, function(ctx, holo)
	if IsValid( holo ) and holo.GetScale then
		return holo:GetScale( );
	end; return Vector(0, 0, 0);
end, false);

extension:RegisterMethod("h", "getScaleUnits", "", "v", 1, function(ctx, holo)
	if IsValid( holo ) and holo.GetScale then
		return holo:GetScaleUnits( );
	end; return Vector(0, 0, 0);
end, false);

----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "setShading", "b", "", 0, function(ctx, holo, b)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetShading(b);
	end
end, false);

extension:RegisterMethod("h", "setShadow", "b", "", 0, function(ctx, holo, b)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:DrawShadow(b);
	end
end, false);

extension:RegisterMethod("h", "setVisible", "b", "", 0, function(ctx, holo, b)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetVisible(b);
	end
end, false);

extension:RegisterMethod("h", "isVisible", "", "b", 1, function(ctx, holo)
	if IsValid( holo ) and holo.INFO then
		return holo.INFO.VISIBLE or false;
	end; return false;
end, false);

extension:RegisterMethod("h", "hasShading", "", "b", 1, function(ctx, holo)
	if IsValid( holo ) and holo.INFO then
		return holo.INFO.SHADING or false;
	end; return false;
end, false);

----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "pushClip", "n,v,v,b", "", 0, function(ctx, holo, n, v, v, b)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:PushClip(n, v, v, b);
	end
end, false);

extension:RegisterMethod("h", "removeClip", "n", "", 0, function(ctx, holo, n)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:RemoveClip(n);
	end
end, false);

extension:RegisterMethod("h", "enableClip", "n,b", "", 0, function(ctx, holo, n, b)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetClipEnabled(n, b);
	end
end, false);

extension:RegisterMethod("h", "setClipOrigin", "n,v", "", 0, function(ctx, holo, n, v)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetClipOrigin(n, v);
	end
end, false);

extension:RegisterMethod("h", "setClipNormal", "n,v", "", 0, function(ctx, holo, n, v)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetClipNormal(n, v);
	end
end, false);

----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "setColor", "c", "", 0, function(ctx, holo, c)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetColor(c);
		holo:SetRenderMode(c.a == 255 and 0 or 4 );
	end
end, false);

extension:RegisterMethod("h", "getColor", "", "c", 1, function(ctx, holo)
	if IsValid( holo ) then
		return holo:GetColor( );
	end; return Color(0, 0, 0 );
end, false);


----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "setMaterial", "s", "", 0, function(ctx, holo, s)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetMaterial(s);
	end
end, false);

extension:RegisterMethod("h", "getMaterial", "", "s", 1, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetMaterial();
	end; return "";
end, false);

extension:RegisterMethod("h", "getSkin", "", "n", 1, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetSkin();
	end; return 0;
end, false);

extension:RegisterMethod("h", "getSkinCount", "", "n", 1, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:SkinCount();
	end; return 0;
end, false);

extension:RegisterMethod("h", "setSkin", "n", "", 0, function(ctx, holo, n)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetSkin(n);
	end
end, false);

extension:RegisterMethod("h", "setBodygroup", "n,n", "", 0, function(ctx, holo, n1, n2)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetBodygroup(n1, n2);
	end
end, false);

----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "parent", "e", "", 0, function(ctx, holo, e)
	if IsValid( holo ) and holo.player == ctx.player and IsValid(e) then
		holo:SetParent(e);
	end
end, false);

extension:RegisterMethod("h", "parent", "h", "", 0, function(ctx, holo, h)
	if IsValid( holo ) and holo.player == ctx.player and IsValid(h) then
		holo:SetParent(h);
	end
end, false);

extension:RegisterMethod("h", "parent", "p", "", 0, function(ctx, holo, p)
	if IsValid( holo ) and holo.player == ctx.player and IsValid(p) then
		holo:SetParent(p);
	end
end, false);

extension:RegisterMethod("h", "parentAttachment", "e,s", "", 0, function(ctx, holo, e, s)
	if IsValid( holo ) and holo.player == ctx.player and IsValid(e) then
		holo:SetParent(e);
		holo:Fire("SetParentAttachmentMaintainOffset", s, 0);
	end
end, false);

extension:RegisterMethod("h", "parentAttachment", "h,s", "", 0, function(ctx, holo, h, s)
	if IsValid( holo ) and holo.player == ctx.player and IsValid(h) then
		holo:SetParent(h);
		holo:Fire("SetParentAttachmentMaintainOffset", s, 0);
	end
end, false);

extension:RegisterMethod("h", "parentAttachment", "p,s", "", 0, function(ctx, holo, p, s)
	if IsValid( holo ) and holo.player == ctx.player and IsValid(p) then
		holo:SetParent(p);
		holo:Fire("SetParentAttachmentMaintainOffset", s, 0);
	end
end, false);

extension:RegisterMethod("h", "unparent", "", "", 0, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetParent();
	end
end, false);

extension:RegisterMethod("h", "getParentEntity", "", "", 0, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		local parent = holo:GetParent();
		if (IsValid(parent)) then return parent end
	end; return Entity(0);
end, false);

extension:RegisterMethod("h", "getParentHologram", "", "", 0, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		local parent = holo:GetParent();
		if (IsValid(parent) and parent.IsHologram) then return parent end
	end; return Entity(0);
end, false);

extension:RegisterMethod("h", "getParentPlayer", "", "", 0, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		local parent = holo:GetParent();
		if (IsValid(parent) and parent:IsPlayer()) then return parent end
	end; return Entity(0);
end, false);

----------------------------------------------------------------------------------------------

extension:RegisterMethod("h", "setBonePos", "n,v", "", 0, function(ctx, holo, n, v)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetBonePos(n, v);
	end
end, false);


extension:RegisterMethod("h", "setBoneAngle", "n,a", "", 0, function(ctx, holo, n, a)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetBoneAngle(n, a);
	end
end, false);


extension:RegisterMethod("h", "setBoneScale", "n,v", "", 0, function(ctx, holo, n, v)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetBoneScale(n, v);
	end
end, false);

extension:RegisterMethod("h", "jiggleBone", "n,b", "", 0, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetBoneJiggle(n,b);
	end
end, false);

extension:RegisterMethod("h", "getBonePos", "n", "v", 1, function(ctx, holo, n)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetBonePos(n);
	end; return Vector(0, 0, 0);
end, false);

extension:RegisterMethod("h", "getBoneAng", "n", "a", 1, function(ctx, holo, n)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetBoneAngle(n);
	end; return Angle(0, 0, 0);
end, false);

extension:RegisterMethod("h", "getBoneScale", "n", "v", 1, function(ctx, holo, n)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetBoneScale(n);
	end; return Vector(0, 0, 0);
end, false);

extension:RegisterMethod("h", "boneCount", "", "n", 0, function(ctx, holo)
	if IsValid( holo ) then
		return holo:GetBoneCount();
	end; return 0;
end, false);

extension:RegisterMethod("h", "boneParent", "n", "n", 0, function(ctx, holo, n)
	if IsValid( holo ) then
		return holo:GetBoneParent(n - 1 ) + 1;
	end; return 0;
end, false);


----------------------------------------------------------------------------------------------

local SetAnimation1 = function(ctx, holo, a, b, c)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetHoloAnimation(a, b, c);
	end
end

extension:RegisterMethod("h", "setAnimation", "n", "", 0, SetAnimation1, false);
extension:RegisterMethod("h", "setAnimation", "n,n", "", 0, SetAnimation1, false);
extension:RegisterMethod("h", "setAnimation", "n,n,n", "", 0, SetAnimation1, false);

local SetAnimation2 = function(ctx, holo, a, b, c)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetHoloAnimation(holo:LookupSequence(a), b, c);
	end
end

extension:RegisterMethod("h", "setAnimation", "s,n,n", "", 0, SetAnimation2, false);
extension:RegisterMethod("h", "setAnimation", "s,n", "", 0, SetAnimation2, false);
extension:RegisterMethod("h", "setAnimation", "s", "", 0, SetAnimation2, false);

extension:RegisterMethod("h", "animationLength", "", "n", 1, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:SequenceDuration() or 0;
	end; return 0;
end, false);

extension:RegisterMethod("h", "setPose", "s,n", "", 0, function(ctx, holo, s, n)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetPoseParameter(s, n);
	end
end, false);

extension:RegisterMethod("h", "getPose", "", "n", 1, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetPoseParameter() or 0;
	end; return 0;
end, false);

extension:RegisterMethod("h", "getAnimation", "", "n", 1, function(ctx, holo)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetSequence() or 0;
	end; return 0;
end, false);

extension:RegisterMethod("h", "getAnimationName", "n", "s", 1, function(ctx, holo, n)
	if IsValid( holo ) and holo.player == ctx.player then
		return holo:GetSequenceName(n) or "";
	end; return "";
end, false);

extension:RegisterMethod("h", "setAnimationRate", "n", "", 0, function(ctx, holo, n)
	if IsValid( holo ) and holo.player == ctx.player then
		holo:SetPlaybackRate(n);
	end
end, false);

-----------------------------------------------------------------------------------------------

extension:EnableExtension();
