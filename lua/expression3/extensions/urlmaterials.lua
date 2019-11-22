--[[
	Szymekk made this extention for EA2, I have just ported it over.
]]

local max_count, max_size;

if CLIENT then
	max_count = CreateConVar("expression3_maxurlmaterials", 15);
	max_size = CreateConVar("expression3_maxurlmatsize", 512);
end

--[[

]]

hook.Add("Expression3.Entity.BuildSandbox", "Expression3.URLMaterials", function(entity, ctx, env)
	ctx.data.materials  = {};
end);

--[[

]]

local TextureSize = 512;
local HTML = HTML
local URLQueue = { }
local CanLoad = true

if CLIENT then TextureSize = max_size:GetInt(); end

--[[

]]

local function Download(context, Name, url, Width, Height)
	if not context:canGetURL(url, "URL-Materials") then return; end

	if IsValid(HTML) then HTML:Remove() end

	local htmlpanel = vgui.Create("HTML")
	htmlpanel:SetVisible(true)
	htmlpanel:SetSize(Width, Height)
	htmlpanel:SetPos(ScrW()-1, ScrH()-1)
	htmlpanel:SetHTML(
		[[
			<style type="text/css">
				html
				{
					margin: 0px 0px;
					overflow:hidden;
				}
			</style>
			<body>
				<img src="]] .. url .. '"width="' .. Width .. '" height="' .. Height .. [[" />
			</body>
		]]
	)
	HTML = htmlpanel

	local uid = "e3_urlmaterial_" .. Name .. context.entity:EntIndex()

	local spawn, nextUpdate = RealTime(), RealTime() + 0.5
	hook.Add("Think", uid, function()
		if !IsValid(context.entity) || !IsValid(htmlpanel) || RealTime() - spawn > 5 then
			htmlpanel:Remove()
			CanLoad = true
			hook.Remove("Think", uid)
			return
		end

		if RealTime() < nextUpdate then return end

		nextUpdate = RealTime() + 0.1

		if htmlpanel:IsLoading() then
			return
		end

		local mat = htmlpanel:GetHTMLMaterial()

		if !mat then return end

		local vertex_mat = CreateMaterial("ea2urlmat_" .. Name, "UnlitGeneric", { ["$vertexcolor"] = 1, ["$vertexalpha"] = 1, ["$ignorez"] = 1, ["$nolod"] = 1 } )
		local tex = mat:GetTexture("$basetexture")
		tex:Download()
		vertex_mat:SetTexture("$basetexture", tex)
		context.data.materials[Name] = vertex_mat

		htmlpanel:Remove()
		CanLoad = true
		hook.Remove("Think", uid)
	end)
end

--[[

]]

hook.Add("Think", "Expression3.UrlTexture", function()
	if #URLQueue > 1 && CanLoad then
		CanLoad = false
		Download(unpack(URLQueue[#URLQueue]))
		table.remove(URLQueue, #URLQueue)
	end
	if #URLQueue == 0 then CanLoad = true end
end)

--[[

]]

local download_material = function(context, Trace, Name, URL, Width, Height)
	if (context.data.materials[Name] || #context.data.materials < Component:ReadSetting("maxurlmaterials", 15)) && #URLQueue < 10 then
		context.data.materials[Name] = context.data.materials[Name] or Material("debug/debugempty")
		table.insert(URLQueue, { context, Name, URL, math.Clamp(Width or TextureSize, 1, TextureSize), math.Clamp(Height or TextureSize, 1, TextureSize) })
	end
end

--[[

]]

local extension = EXPR_LIB.RegisterExtension("url-materials");

extension:SetClientState();

extension:RegisterPermission("URL-Materials", "fugue/drive-upload.png", "This gate is allowed to download images\nthe filter setting will still be applied.");

extension:RegisterFunction("render", "downloadURLMaterial", "s,s,n,n", "", 0, download_material, false);

extension:RegisterFunction("render", "downloadURLMaterial", "s,s", "", 0, download_material, false);

extension:RegisterFunction("render", "setURLMaterial", "s", "", 0, function(context, name)
	if context.data.materials then
		local mat = context.data.materials[name];
		
		if mat then
			render.SetMaterial(mat);
			surface.SetMaterial(mat);
		end
	end
end, false);

extension:EnableExtension();
