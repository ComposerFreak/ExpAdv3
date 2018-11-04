local PANEL = {};

function PANEL:Init( )
	self.BaseClass.Init(self);

	self.nLine = 1;
	self.row = {};
	self.format = {};
	self.funcs = {};

	self.tFormat = {};
	self.tFuncs = {};

	--self:NewLine();
	self:SetEditable(false);
	self:SetDefaultTextColor(Color(255, 255, 255));

	-- Golem.Syntax:Create( "console", self );
	
end

function PANEL:ClickText( cursor )
	local format = self.tFormat[cursor.x];
	local funcs = self.tFuncs[cursor.x];
	if not funcs then return false; end

	local fun;
	local pos = 0;

	for k = 1, #format do
		local len = #format[k][1];

		if (cursor.y >= pos) and (cursor.y <= (pos + len)) then
			fun = funcs[k];
			break;
		else
			pos = pos + len;
		end
	end

	if not fun then return false; end

	fun();

	return true;
end

function PANEL:NewLine()
	self.tRows[ self.nLine ] = table.concat(self.row, "");
	self.tFormat[ self.nLine ] = table.Copy(self.format);
	self.tFuncs[ self.nLine ] = self.funcs;
	PrintTable(self.tFuncs)
	
	self.row = {};
	self.format = {};
	self.funcs = {};
	self.nLine = self.nLine + 1;
end

function PANEL:Write(str)
	self.row[#self.row + 1] = str;
	self.format[#self.row] = {str, self.cTextColor};
	if self.fClick then self.funcs[#self.row] = self.fClick;  end
end

function PANEL:SetColor(col)
	self.cTextColor = col;
end

function PANEL:WriteImage(image, size)
	local str = string.rep(" ",math.ceil(size/self.FontWidth));
	self.row[#self.row + 1] = str;
	self.format[#self.row] = { str, self.cTextColor, true, Material(image) };
	if self.fClick then self.funcs[#self.row] = self.fClick; end
end

function PANEL:WriteTable(values)
	local tValues = #values;
	local oc = self.cTextColor;
	local of = self.fClick;

	for i = 1, tValues do
		local value = values[i];
		
		if isfunction(value) then
			self.fClick = value;
			continue;
		end

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

		if not isstring(value) then
			value = tostring(value)
		end

		local lines = string.Explode("\n", value);
		local tLines = #lines;

		for j = 1, tLines do
			self:Write(lines[j]);

			if tLines > 1 and j < tLines then
				self:NewLine();
			end
		end
	end

	self.fClick = of;
	self.cTextColor = oc;
end

function PANEL:WriteLine(...)
	self.cTextColor = self.cDefTextColor;
	self:WriteTable( { ... } );
	self:NewLine();
end

function PANEL:Warn(level, ...)
	local left = {};
	local right = {...};

	level = level or 2;
	
	if level == 1 then 
		left[1] = {image = "fugue/question.png", size = 16}
	elseif level == 2 then
		left[1] = {image = "fugue/exclamation-circle.png", size = 16}
	elseif level == 3 then 
		left[1] = {image = "fugue/exclamation-red.png", size = 16}
	end
	
	--if level == 3 then
	--	self:SetBackGroundColorL(200, 50, 50);
	--	self:SetBackGroundColorR(200, 50, 50);
	--end
	
	left[#left + 1] = Color(255, 255, 255);
	left[#left + 1] = "Warning ";

	self:WriteLine(left, right)
end

function PANEL:GetDefaultTextColor()
	return self.cDefTextColor;
end

function PANEL:SetDefaultTextColor(c)
	self.cDefTextColor = c;
end

vgui.Register( "GOLEM_Console", PANEL, "GOLEM_Editor" );