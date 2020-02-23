/****************************************************************************************************************************
	This is Teks origonal EA2 Android Permissions Concept
****************************************************************************************************************************/

if SERVER then return; end

local matArrow = Material("tek/arrow.png")
local matInfo = Material("tek/iconexclamation.png")
local matTopLeft = Material("tek/topcornerleft.png")
local matTopRight = Material("tek/topcornerright.png")
local matBottomLeft = Material("tek/bottomcornerleft.png")
local matBottomRight = Material("tek/bottomcorneright.png")

local colBackground = Color(207, 207, 207)
local colWhite = Color(255, 255, 255)
local colTitle = Color(195, 195, 195)
local colText = Color(85, 85, 85)

/****************************************************************************************************************************
	PANEL
****************************************************************************************************************************/

local PANEL = { }

function PANEL:Init()
	self:SetWide(500)
	self:SetTall(83)

	self.btnAccept = self:Add("DButton")
	self.btnAccept:SetText("Accept")
	self.btnAccept:SetDrawBackground(false)

	self.btnBlock = self:Add("DButton")
	self.btnBlock:SetText("Block All")
	self.btnBlock:SetDrawBackground(false)

	self.btnClose = self:Add("DButton")
	self.btnClose:SetText("Close")
	self.btnClose:SetDrawBackground(false)

	function self.btnAccept.DoClick()
		if IsValid( self.entity ) then
			for perm, _ in pairs(self.features) do
				EXPR_PERMS.Set(self.entity, LocalPlayer(), perm, EXPR_ALLOW);
			end
		end
		self:Remove()
	end

	function self.btnBlock.DoClick()
		if IsValid( self.entity ) then
			for perm, _ in pairs(self.features) do
				EXPR_PERMS.Set(self.entity, LocalPlayer(), perm, EXPR_DENY);
			end
		end
		self:Remove()
	end

	function self.btnClose.DoClick()
		self:Remove()
	end
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matTopLeft)
	surface.DrawTexturedRect(0, 0, 12, 12)
	surface.SetMaterial(matTopRight)
	surface.DrawTexturedRect(w - 12, 0, 12, 12)

	--Title:
	surface.SetDrawColor(colTitle)
	surface.DrawRect(12, 0, w - 24, 12)
	draw.SimpleText("- Expression 3 -", "default", w * 0.5, 6, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	--Name and Owner
	surface.SetDrawColor(colTitle)
	surface.DrawRect(0, 12, w, 43)

	surface.SetDrawColor(colBackground)
	surface.DrawRect(5, 12, w - 10, 43)

	draw.SimpleText("Name: " .. self:GetTitle(), "default", 10, 13, colText, TEXT_ALIGN_LEFT)
	draw.SimpleText("Owner: " .. self:GetOwnersName(), "default", 10, 33, colText, TEXT_ALIGN_LEFT)

	--Features Title
	surface.SetDrawColor(colBackground)
	surface.DrawRect(0, 55, w, 40)

	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matInfo)
	surface.DrawTexturedRect(9, 55, 32, 32)

	draw.SimpleText("This gate requires access to the", "default", 43, 56, colText, TEXT_ALIGN_LEFT)
	draw.SimpleText("features listed below.", "default", 43, 70, colText, TEXT_ALIGN_LEFT)

	local y = 95

	for _,perm in pairs(self.features) do
		local permission = EXPR_LIB.PERMS[perm];

		if (permission) then
			surface.SetDrawColor(colBackground)
			surface.DrawRect(0, y, w, 42)

			surface.SetDrawColor(colWhite)
			surface.SetMaterial(Material(permission[2]))
			surface.DrawTexturedRect(24, y + 4, 32, 32)

			draw.SimpleText(perm, "default", 65, y + 5, colText, TEXT_ALIGN_LEFT)
			draw.SimpleText(permission[3], "default", 65, y + 20, colText, TEXT_ALIGN_LEFT)

			y = y + 42;
		end
	end

	surface.SetDrawColor(colBackground)
	surface.DrawRect(16, h - 16, w - 32, 16)
	surface.DrawRect(0, y, w, h - y - 16)

	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matBottomLeft)
	surface.DrawTexturedRect(0, h - 16, 16, 16)

	surface.SetDrawColor(colWhite)
	surface.SetMaterial(matBottomRight)
	surface.DrawTexturedRect(w - 16, h - 16, 16, 16)
end

function PANEL:SetUp(Gate, features)
	self.entity = Gate;
	self.features = features;
	self:SetTall(120 + (table.Count(self.features) * 42));
end

function PANEL:GetTitle()
	if !IsValid(self.entity) then
		return ""
	elseif self.entity.GetScriptName then
		return self.entity:GetScriptName()
	end

	return "generic"
end

function PANEL:GetOwnersName()
	if !IsValid(self.entity) or !IsValid(self.entity.player) then
		return "unkown"
	end

	return self.entity.player:Name()
end

function PANEL:PerformLayout()
	self.btnAccept:SetPos(0, self:GetTall() - 20)
	self.btnBlock:SetPos(100,self:GetTall() - 20)
	self.btnClose:SetPos(200,self:GetTall() - 20)
end

vgui.Register( "E3_TekMenu", PANEL, "DPanel" );

