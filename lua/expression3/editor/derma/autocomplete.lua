--[[============================================================================================================================================
	Name: GOLEM_Autocomplete
	Author: Oskar
============================================================================================================================================]]
local PANEL = { }
local font = "Trebuchet20";

local function names(ids)
	local buf = { };
	local arr = string.Explode(",", ids);

	for i = 1, #arr do
		table.insert(buf, EXPR_LIB.GetClass(arr[i]).name );
	end

	return "(" .. table.concat(buf,", ") .. ")";
end

function PANEL:Init()
	self.selection = 1;
	self.max = 5;
end

function PANEL:UpdateWord()
	local editor = self:GetParent();
	self.left = editor:wordStart(editor.Caret);
	self.right = editor:wordEnd(editor.Caret);
	self.word = editor:GetArea({ self.left, self.right });

	self.preword = "";

	self.char = editor:GetArea({ self.left - Vector2(0, 1), self.left });

	if self.left.y > 1 and  self.char ~= "" then
		local left2 = editor:wordStart(self.left - Vector2(0, 2));
		local right2 = editor:wordEnd(self.left - Vector2(0, 2));
		self.preword = editor:GetArea({ left2, right2 });
	end
end

function PANEL:PositionAtCarrot(w, h)
	local editor = self:GetParent();
	local x = editor.LinePadding + (editor.FontWidth * editor.Caret.y);
	local y = editor.FontHeight * editor.Caret.x;
	self:SetPos(x, y);
end

function PANEL:UpdateSugestions()
	self.sugestions = { };

	if self.char == "." then
		self:AppendFunctions(self.preword, self.word);
		self:AppendAtributes(self.preword, self.word);
		self:AppendMethods(self.preword, self.word);
	else
		self:AppendClasses(self.word);
		self:AppendVariables(self.word);
		self:AppendLibraries(self.word);
	end
end

function PANEL:GetVariables()
	local editor = self:GetParent();
	return editor.tSyntax.tVariables;
end

function PANEL:AppendFunctions(preword, word)
	--if word == "" then return; end

	local libary = EXPR_LIBRARIES[preword];
	if not libary then return; end

	for sig, op in pairs(libary._functions) do
		if op.name == word or string.StartWith(op.name, word) then
			table.insert(self.sugestions, {type = "Function", value = op.name, parameter = names(op.parameter)});
		end 
	end
end

function PANEL:AppendLibraries(word)
	if word == "" then return; end

	for name, library in pairs(EXPR_LIBRARIES) do
		if name == word or string.StartWith(name, word) then
			table.insert(self.sugestions, {type = "Library", value = name});
		end
	end
end

function PANEL:AppendVariables(word)
	if word == "" then return; end

	for name, info in pairs( self:GetVariables() ) do
		if name == word or string.StartWith(name, word) then
			table.insert(self.sugestions, {type = "Variable", class = info[2], value = name});
		end
	end
end

function PANEL:AppendClasses(word)
	if word == "" then return; end

	for name, info in pairs( EXPR_CLASSES ) do
		if name == word or string.StartWith(name, word) then
			table.insert(self.sugestions, {type = "Class", value = name});
		end
	end
end

function PANEL:AppendMethods(preword, word)
	--if word == "" then return; end

	local varData = self:GetVariables()[preword];
	if not varData or not varData[2] then return; end

	local class = EXPR_LIB.GetClass(varData[2]);
	if not class or not varData[2] then return; end

	for sig, op in pairs(EXPR_METHODS) do
		if op.class == class.id then
			if op.name == word or string.StartWith(op.name, word) then
				table.insert(self.sugestions, {type = "Method", class = class.name, value = op.name, parameter = names(op.parameter)});
			end
		end
	end
end

function PANEL:AppendAtributes(preword, word)
	--if word == "" then return; end

	local varData = self:GetVariables()[preword];
	if not varData or not varData[2] then return; end

	local class = EXPR_LIB.GetClass(varData[2]);
	if not class or not varData[2] then return; end

	for name, op in pairs(class.attributes) do
		if name == word or string.StartWith(name, word) then
			table.insert(self.sugestions, {type = "Atribute", class = class.name, value = name});
		end
	end
end

function PANEL:Think()
	self:UpdateWord();
	self:UpdateSugestions();
	self:PositionAtCarrot(w, h);
end

function PANEL:RenderRows(x, y)
	local total = #self.sugestions;

	local start = self.selection;
	if start > (total - self.max) then start = total - self.max; end
	if start < 1 then start = 1; end

	local stop = start + self.max;
	if stop > total then stop = total; end

	local tw, cw, vw, pw, rh = 0, 0, 0, 0, 0;

	for i = start, stop do
		local row = self.sugestions[i];

		if row and row.type then
			local fw, fh = surface.GetTextSize(row.type);
			if tw < fw then tw = fw; end
			if rh < fh then rh = fh; end
		end

		if row and row.class then
			local fw, fh = surface.GetTextSize(row.class);
			if cw < fw then cw = fw; end
			if rh < fh then rh = fh; end
		end

		if row and row.value then
			local fw, fh = surface.GetTextSize(row.value);
			if vw < fw then vw = fw; end
			if rh < fh then rh = fh; end
		end

		if row and row.parameter then
			local fw, fh = surface.GetTextSize(row.parameter);
			if pw < fw then pw = fw; end
			if rh < fh then rh = fh; end
		end
	end

	local y = 5;
	local x1 = 5;
	local x2 = x1 + tw + 5;
	local x3 = x2 + cw + 5;
	local x4 = x3 + vw + 5;
	local x5 = x4 + pw + 5;

 	for i = start, stop do
		local row = self.sugestions[i];

		if row and i % 2 ~= 0 then
			surface.SetDrawColor( 200, 200, 200, 50 );
			surface.DrawRect(0, y - 5, x5, rh + 10);
		end

		if row and row.type then
			surface.SetTextColor(0, 0, 0, 255);
			surface.SetTextPos(x1, y);
			surface.DrawText(row.type);
		end

		if row and row.class then
			surface.SetTextColor(0, 0, 0, 255);
			surface.SetTextPos(x2, y);
			surface.DrawText(row.class);
		end

		if row and row.value then
			surface.SetTextColor(0, 0, 0, 255);
			surface.SetTextPos(x3, y);
			surface.DrawText(row.value);
		end

		if row and row.parameter then
			surface.SetTextColor(0, 0, 0, 255);
			surface.SetTextPos(x4, y);
			surface.DrawText(row.parameter);
		end

		y = y + rh;
	end

	return x5, y;
end

function PANEL:Paint( w, h )

	if not self.sugestions or #self.sugestions == 0 then return; end

	surface.SetDrawColor( 255, 255, 255, 50 );
	surface.DrawRect(0, 0, w, h);
	surface.SetFont("Trebuchet20");

	local nw, nh = self:RenderRows(5, 5);

	self:SetSize(nw, nh);
end

vgui.Register( "GOLEM_AutoComplete", PANEL, "EditablePanel" )