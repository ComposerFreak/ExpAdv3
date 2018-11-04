local PANEL = {};

function PANEL:Init( )
	self.nLine = 0;
	self.tRows = { };
	self.BaseClass.Init(self)

	self:NewLine();
	self:SetDefaultTextColor(Color(255, 255, 255));

	Golem.Syntax:Create( "console", self );
	
	self.pTextEntry.OnKeyCodeTyped = function( _, code ) end
end

function PANEL:NewLine()
	self.row = { };
	self.nLine = self.nLine + 1;
	self.tRows[ self.nLine ] = self.row;
end

function PANEL:Write(str)
	self.row[#self.row + 1] = { str, self.cTextColor };
end

function PANEL:SetColor(col)
	self.cTextColor = col;
end

function PANEL:WriteImage(image, size)

end

function PANEL:WriteTable(values)
	local tValues = #values;

	for i = 1, tValues do
		local value = values[i];

		if IsColor(value) then
			self:SetColor(value);
			continue;
		end

		if istable(value) then
			if value.image then
				self:WriteImage(value.image, value.size);
			else
				self:WriteTable(value);
			end
			continue;
		end

		if not isstring(value) then value = tostring(value) end

		local lines = string.Explode("\n", value);
		local tLines = #lines;

		for j = 1, tLines do
			self:Write(lines[j]);

			if tLines > 1 and j < tLines then
				self:NewLine();
			end
		end
	end
end

function PANEL:WriteLine(...)
	self.cTextColor = self.cDefTextColor;
	self:WriteTable( { ... } );
	self:NewLine();
end


function PANEL:GetDefaultTextColor()
	return self.cDefTextColor;
end

function PANEL:SetDefaultTextColor(c)
	self.cDefTextColor = c;
end

vgui.Register( "GOLEM_Console", PANEL, "GOLEM_Editor" );