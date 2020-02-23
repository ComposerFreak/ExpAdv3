--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Rendering Features::
	``````````````````````
]]

local max_id = 10;
local max_burst = 10;
local burst_counter = {};

local extension = EXPR_LIB.RegisterExtension("render_targets");

extension:RegisterPermission("RenderCanvas", "fugue/palette-paint-brush.png", "This gate is allowed to create and render to\ncanvases (render targets).");

extension:SetClientState();

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

if (CLIENT) then

	hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Render.RT", function(entity, ctx, env)
		ctx.data.RTS = {};
		ctx.data.rt_burst = 0;
	end);

	hook.Add("Expression3.Entity.PreDrawScreen", "Expression3.Render.RT", function(ctx, entity) 
		ctx.data.rt_deph = 0;
	end);

	hook.Add("Expression3.Entity.PostDrawScreen", "Expression3.Render.RT", function(ctx, entity) 
		for i = 1, ctx.data.rt_deph do
			render.PopRenderTarget();
		end
	end);
end

--[[
	*****************************************************************************************************************************************************
		RT Materials
	*****************************************************************************************************************************************************
]]--

local materials = {};

local function updateMaterials()
	if CLIENT then
		local info = {
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1,
			["$ignorez"] = 1,
			["$nolod"] = 1
		};

		for i = 1, max_id do
			materials[i] = materials[i] or CreateMaterial( "e3_rt_mat_" .. 0, "UnlitGeneric", info);
		end
	end
end

updateMaterials();

--[[
	*****************************************************************************************************************************************************
		CVARS
	*****************************************************************************************************************************************************
]]--

if CLIENT then
	local cvar_max = CreateConVar("e3_canvas_max", max_id, FCVAR_ARCHIVE, "The max amount of canvases per e3.");
	local cvar_burst = CreateConVar("e3_canvas_burst", max_burst, FCVAR_ARCHIVE, "The rate at witch an e3 can create canvases per second.");

	timer.Create("Expression3.Render.RT", 1, 0, function()
		max_id = cvar_max:GetInt();
		max_burst = cvar_burst:GetInt();

		updateMaterials();

		burst_counter = {};
	end);
end

--[[
	*****************************************************************************************************************************************************
		Size Options
	*****************************************************************************************************************************************************
]]--

local sizes = {
	[32] = true;
	[64] = true;
	[128] = true;
	[256] = true;
	[512] = true;
	[1024] = true;
};

--[[
	*****************************************************************************************************************************************************
		Create RT Object
	*****************************************************************************************************************************************************
]]--

local function GetRT(ctx, id, width, height)

	id = math.floor(id);

	if id < 1 or id > max_id then
		ctx:Throw("Attempt to create Render Target with invalid id #%i", id);
	end

	if not sizes[width] then
		ctx:Throw("Attempt to create Render Target #%i with invalid width %i", id, width);
	end

	if not sizes[height] then
		ctx:Throw("Attempt to create Render Target #%i with invalid height %i", id, height);
	end

	local RT = ctx.data.RTS[id];

	if not RT then 
		local burst = burst_counter[ctx] or 0;

		if burst > max_burst then
			ctx:Throw("Render Targets where created too fast.");
		end

		local name = string.format("E3RT_%i_%i_%i", ctx.entity:EntIndex(), width, height, id);

		RT = {
			id = id,
			name = name,
			width = width,
			height = height,
			mt = materials[id],
			rt = GetRenderTarget(name, width, height),
		};

		ctx.data.RTS[id] = RT;
		burst_counter[ctx] = burst;
	end

	return RT;
end

--[[
	*****************************************************************************************************************************************************
		Define RT as an object
	*****************************************************************************************************************************************************
]]--

extension:RegisterClass("cv", {"canvas"}, istable, EXPR_LIB.NOTNIL);

extension:RegisterConstructor("cv", "n,n,n", GetRT);

extension:RegisterOperator("eq", "cv,cv", "b", 1);
extension:RegisterOperator("neq", "cv,cv", "b", 1);

extension:RegisterMethod("cv", "id", "", "n", 1, function(rt) return rt and rt.id or 0; end, true);
extension:RegisterMethod("cv", "width", "", "n", 1, function(rt) return rt and rt.width or 0; end, true);
extension:RegisterMethod("cv", "height", "", "n", 1, function(rt) return rt and rt.height or 0; end, true);

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

local function preDraw(ctx)
	if (not EXPR3_DRAWSCREEN) then
		ctx:Throw("Attempted to render outside of a rendering event.");
	end
end

extension:RegisterFunction("render", "setTexture", "cv", "", 1, function(ctx, cv)
	preDraw(ctx);

	if cv and cv.mt then
		cv.mt:SetTexture("$basetexture", cv.rt);
		render.SetMaterial(cv.mt)
		surface.SetMaterial(cv.mt)
	end

end, false);

extension:RegisterFunction("render", "pushCanvas", "cv", "", 1, function(ctx, cv)
	preDraw(ctx);

	if cv then
		if self:ppPlayer(LocalPlayer(), "RenderCanvas") then
			render.PushRenderTarget(cv.rt);
			ctx.data.rt_deph = ctx.data.rt_deph + 1;
		end
	end
end, false);

extension:RegisterFunction("render", "popCanvas", "", "", 1, function(ctx, cv)
	preDraw(ctx);

	if ctx.data.rt_deph > 0 then
		render.PopRenderTarget();
		ctx.data.rt_deph = ctx.data.rt_deph - 1;
	end
end, false);

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();