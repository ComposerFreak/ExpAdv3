/*============================================================================================================================================
	Name: GOLEM_CheckBox and GOLEM_CheckBoxLabel
	Author: Rusketh (The whole point of this, is to make Oskar hate it so he replaces it!)
	Based on Sublime Text 3, because its the best Text Editor (Disagree? Your wrong!).
============================================================================================================================================*/

--[[
	Check Box
]]

local CHECK = {};

local tick = Material("fugue\\tick.png");
local cross = Material("fugue\\cross-button.png");

function CHECK:Init()
	self.bChecked = false;
	self:SetTick(tick, self:GetColor());
	self:SetCross(cross, self:GetColor());
	self:SetMaterial( self.cross );
end

function CHECK:SetStatic(image)
	self:SetTick(image, Color(0, 255, 0));
	self:SetCross(image, Color(255, 0, 0));
end

function CHECK:SetTick(tick, col)
	self.tick = tick or self.tick;
	self.ctick = col or self.ctick;

	if (self.bChecked) then
		self:SetMaterial(self.tick);
		self:SetColor(self.ctick);
	end
end

function CHECK:SetCross(cross, col)
	self.cross = cross or self.cross;
	self.ccross = col or self.ccross;

	if (not self.bChecked) then
		self:SetMaterial(self.cross);
		self:SetColor(self.ccross);
	end
end


function CHECK:DoClick()
	self.bChecked = not self.bChecked;
	self:SetMaterial( self.bChecked and self.tick or self.cross );
	self:SetColor( self.bChecked and self.ctick or self.ccross );
	self:ChangedValue(self.bChecked);
end

function CHECK:GetValue()
	return self.bChecked;
end

function CHECK:SetValue(b, noChanged)
	self.bChecked = b;
	self:SetMaterial( self.bChecked and self.tick or self.cross );
	self:SetColor( self.bChecked and self.ctick or self.ccross );
	if (not noChanged) then
		self:ChangedValue(self.bChecked);
	end
end

function CHECK:ChangedValue(bChecked)

end

vgui.Register("GOLEM_CheckBox", CHECK, "GOLEM_ImageButton");

--[[
	Check Box but with a label.
]]

local CHECKLABEL = {};

function CHECKLABEL:Init()
	self.button = self:Add("GOLEM_CheckBox");
	self.button:SetSize(22, 22);
	self.button:Dock(LEFT);

	self.label = self:Add("DLabel");
	self.label:SetHeight(22);
	self.label:Dock(FILL);

	function self.button.ChangedValue(this, bChecked)
		self:ChangedValue(bChecked);
	end

end

function CHECKLABEL:SetText(text)
	self.label:SetText(text);
	self.label:SizeToContentsX();
	self:PerformLayout();
end

function CHECKLABEL:SetTick(tick)
	self.button:SetTick(tick);
end

function CHECKLABEL:SetCross(cross)
	self.button:SetCross(cross);
end

function CHECKLABEL:Paint()

end

function CHECKLABEL:GetValue()
	return self.button:GetValue();
end

function CHECKLABEL:ChangedValue(bChecked)

end

vgui.Register("GOLEM_CheckBoxLabel", CHECKLABEL, "DPanel");
