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
		local class = EXPR_LIB.GetClass(arr[i]);
		table.insert(buf, class and class.name or arr[i]);
	end

	return "(" .. table.concat(buf,", ") .. ")";
end

function PANEL:Init()
	self.selection = 1;
	self.max = 5;
end

function PANEL:UpdateWord()
	self.left = self.editor:wordStart(self.editor.Caret);
	self.right = self.editor:wordEnd(self.editor.Caret);
	self.word = self.editor:GetArea({ self.left, self.right });

	self.preword = "";

	self.char = self.editor:GetArea({ self.left - Vector2(0, 1), self.left });

	if self.left.y > 1 and  self.char ~= "" then
		local left2 = self.editor:wordStart(self.left - Vector2(0, 2));
		local right2 = self.editor:wordEnd(self.left - Vector2(0, 2));
		self.preword = self.editor:GetArea({ left2, right2 });
	end
end

function PANEL:DoAutoComplete()
	local sugestion = self.sugestions[self.selection];
	if not sugestion or not sugestion.value then return; end

	self.editor:SetArea({ self.left, self.right }, sugestion.value);
	self.editor:SetCaret( self.left + Vector2(0, #sugestion.value) )
end

function PANEL:PositionAtCarrot(w, h)
	local x = self.editor.LinePadding + (self.editor.FontWidth * self.editor.Caret.y);
	local y = self.editor.FontHeight * self.editor.Caret.x;
	self:SetPos(x, y);
end

function PANEL:UpdateSugestions()
	self.sugestions = { };

	if self.char == "@" then
		self:AppendDirectives(self.word);
	elseif self.char == "." then
		self:AppendFunctions(self.preword, self.word);
		self:AppendConstants(self.preword, self.word);
		self:AppendAtributes(self.preword, self.word);
		self:AppendMethods(self.preword, self.word);
	elseif self.char == " " and self.preword == "new" then
		self:AppendConstructors(self.word);
	else
		self:AppendClasses(self.word);
		self:AppendVariables(self.word);
		self:AppendLibraries(self.word);
		self:AppendUserFunctions(self.word);
		self:AppendConstructors(self.word);
	end

	local count = #self.sugestions;

	if count == 0 then
		self.bEngaged = false;
		self.selection = 1;
	elseif self.selection > count then
		self.selection = count;
	end
end

function PANEL:GetVariables()
	return self.editor.tSyntax.tVariables;
end

function PANEL:GetClasses()
	return self.editor.tSyntax.tClasses;
end

function PANEL:AppendUserFunctions(word)
	for name, y in pairs(self.editor.tSyntax.tUserFunctions) do
		if name == word or string.StartWith(name, word) then
			table.insert(self.sugestions, {type = "Function", value = name, parameter = "(...)"});
		end
	end
end

function PANEL:AppendConstructors(word)
	local lk = { };
	for name, info in pairs( EXPR_CLASSES ) do
		lk[name] = true;
		if not lk[name] or not lk[info.id] then
			lk[info.id] = true;
			if name == word or string.StartWith(name, word) then
				for sig, op in pairs(info.constructors) do
					table.insert(self.sugestions, {type = "Constructor", value = name, parameter = names(op.parameter)});
				end
			end
		end
	end

	for name, info in pairs(self:GetClasses()) do
		if not lk[name] then
			if name == word or string.StartWith(name, word) then
				table.insert(self.sugestions, {type = "Constructor", value = name, parameter = "(...)"});
			end
		end
	end
end

function PANEL:AppendDirectives(word)
	if "name" == word or string.StartWith("name", word) then
		table.insert(self.sugestions, {type = "Directive", value = "name", parameter = "\"string\""});
	end

	if "model" == word or string.StartWith("model", word) then
		table.insert(self.sugestions, {type = "Directive", value = "model", parameter = "\"string\""});
	end

	if "include" == word or string.StartWith("include", word) then
		table.insert(self.sugestions, {type = "Directive", value = "include", parameter = "\"string\""});
	end

	if "input" == word or string.StartWith("input", word) then
		table.insert(self.sugestions, {type = "Directive", value = "input", parameter = "\"string\""});
	end

	if "output" == word or string.StartWith("output", word) then
		table.insert(self.sugestions, {type = "Directive", value = "output", parameter = "\"string\""});
	end
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

function PANEL:AppendConstants(preword, word)
	--if word == "" then return; end

	local libary = EXPR_LIBRARIES[preword];
	if not libary then return; end

	for sig, op in pairs(libary._constants) do
		if op.name == word or string.StartWith(op.name, word) then
			table.insert(self.sugestions, {type = "Constant", value = op.name});
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

	for name, info in pairs( self:GetClasses() ) do
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
	
	if class then
		for sig, op in pairs(EXPR_METHODS) do
			if op.class == class.id then
				if op.name == word or string.StartWith(op.name, word) then
					table.insert(self.sugestions, {type = "Method", class = class.name, value = op.name, parameter = names(op.parameter)});
				end
			end
		end
	else
		local methods = self.editor.tSyntax.tMethods[varData[2]];
		
		if methods then

			for name, y in pairs(methods) do
				if name == word or string.StartWith(name, word) then
					table.insert(self.sugestions, {type = "Method", class = varData[2], value = name, parameter = "(...)"});
				end
			end
		end
	end
end

function PANEL:AppendAtributes(preword, word)
	--if word == "" then return; end

	local varData = self:GetVariables()[preword];
	if not varData or not varData[2] then return; end

	local class = EXPR_LIB.GetClass(varData[2]);
	
	if class then

		for name, op in pairs(class.attributes) do
			if name == word or string.StartWith(name, word) then
				table.insert(self.sugestions, {type = "Atribute", class = class.name, value = name});
			end
		end

	else
		local attributes = self.editor.tSyntax.tAttributes[varData[2]];
		
		if attributes then

			for name, y in pairs(attributes) do
				if name == word or string.StartWith(name, word) then
					table.insert(self.sugestions, {type = "Atribute", class = varData[2], value = name});
				end
			end
		end

	end
end

function PANEL:Think()
	self.editor = self:GetParent();
	
	if not self.editor.bShowAutoComplete then
		self.bEngaged = false;
		return;
	end

	self:UpdateWord();
	self:UpdateSugestions();
	self:PositionAtCarrot(w, h);
end

function PANEL:OnKeyCodeTyped( code )

	if not self.editor.bShowAutoComplete then return false; end
	local control = input.IsKeyDown( KEY_LCONTROL ) or input.IsKeyDown( KEY_RCONTROL );

	if self.bEngaged and (code == KEY_LCONTROL or code == KEY_RCONTROL) then
		self.bEngaged = false;
		return true;
	end

	if not self.bEngaged then
		if control and code == KEY_Q then
			self.bEngaged = true;
			return true;
		else
			return false;
		end
	end

	if code == KEY_UP then
		self.selection = math.Clamp(self.selection - 1, 1, #self.sugestions);
		return true;
	elseif code == KEY_DOWN then
		self.selection = math.Clamp(self.selection + 1, 1, #self.sugestions);
		return true;
	elseif code == KEY_TAB then
		self:DoAutoComplete();
		self.bEngaged = false;
		return true;
	end

	return false;
end

function PANEL:RenderRows(x, y)

	surface.SetFont("Trebuchet20");

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

	local x1 = 5;
	local x2 = x1 + tw + 5;
	local x3 = x2 + cw + 5;
	local x4 = x3 + vw + 5;
	local x5 = x4 + pw + 5;

 	for i = start, stop do
		local row = self.sugestions[i];

		if row and i == self.selection then
			surface.SetDrawColor( 0, 255, 255, 50 );
			surface.DrawRect(2, y, x5 - 4, rh);
		elseif row and i % 2 ~= 0 then
			surface.SetDrawColor( 200, 200, 200, 50 );
			surface.DrawRect(2, y, x5 - 4, rh);
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

	if self.bEngaged then
		surface.SetDrawColor( 255, 255, 255, 50 );
		surface.DrawRect(0, 0, w, h);
	else
		surface.SetDrawColor( 200, 200, 200, 50 );
		surface.DrawRect(0, 0, w, h);
	end

	local nw, nh = self:RenderRows(5, 5);

	local txt = "interact: ctrl + q";
	if self.bEngaged then txt = "exit: ctrl | execute: tab"; end

	surface.SetFont("Trebuchet18");
	local fw, fh = surface.GetTextSize(txt);
	if nw < fw + 10 then nw = fw + 10; end

	surface.SetTextColor(0, 0, 0, 255);
	surface.SetTextPos(nw - fw -5, nh);
	surface.DrawText(txt);

	self:SetSize(nw, nh + 20);
end

vgui.Register( "GOLEM_AutoComplete", PANEL, "EditablePanel" )