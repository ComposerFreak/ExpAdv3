--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Debugger::
]]

local COLORS = {}

COLORS.Generic = Color(200, 200, 200);
COLORS.Removed = Color(255, 0, 0);
COLORS.Replaced = Color(150, 150, 0);
COLORS.Before = Color(0, 150, 100);
COLORS.After = Color(0, 100, 150);

local function ProcessLines(tokens, alltasks)
	local off = "";
	local row = {};
	local rows = {};

	for k = 1, #tokens do
		local token = tokens[k];
		local data = token.data;

		if (token.orig) then
			data = token.orig;
		end

		if (token.newLine) then
			rows[#rows + 1] = row;
			row = {{off, COLORS.Generic}};
		end

		if (token.depth and token.depth > 0) then
			-- off = string.rep("    ", token.depth)
			-- row[#row + 1] = {off, COLORS.Generic}
		end

		local tasks = alltasks[token.pos];

		if (not tasks) then
			row[#row + 1] = {data .. " ", COLORS.Generic};
		else
			if (tasks.prefix) then
				for _, task in pairs(tasks.prefix) do
					if (task.newLine) then
						rows[#rows + 1] = row;
						row = {{off, COLORS.Generic}};
					end

					row[#row + 1] = {task.str .. " ", COLORS.Before}
				end
			end

			if (not tasks.remove) then
				if (tasks.replace) then
					row[#row + 1] = {tasks.replace.str .. " ", COLORS.Replaced}
				else
					row[#row + 1] = {data .. " ", COLORS.Generic}
				end
			else
				row[#row + 1] = {data .. " ", COLORS.Removed}
			end

			if (tasks.postfix) then
				for _, task in pairs(tasks.postfix) do
					if (task.newLine) then
						rows[#rows + 1] = row;
						row = {{off, COLORS.Generic}};
					end

					row[#row + 1] = {task.str .. " ", COLORS.After}
				end
			end
		end
	end

	rows[#rows + 1] = row;


	local allTokens = {};

	for k, row in pairs(rows) do
		for j, token in pairs(row) do
			allTokens[#allTokens + 1] = token[1];
		end

		allTokens[#allTokens + 1] = "\n";
	end

	return rows, table.concat(allTokens, "");
end

EXPR_LIB.ShowDebug = function(tokens, tasks)
	if (Golem) then
		local inst = Golem:GetInstance();
		
		local rows, text = ProcessLines(tokens, tasks);
		
		local sheet = inst:NewTab("editor", text, nil, "Debug");
		
		sheet.Panel._OnKeyCodeTyped = function() end;
		sheet.Panel._OnTextChanged = function() end;
		
		sheet.Panel.SyntaxColorLine = function(self, row)
			-- print( "SCL" )
			-- print( rows[row] )
			
			if rows[row] then 
				-- PrintTableGrep( rows[row] ) 
				return rows[row];
			end 
			return {{self.Rows[row], Color(255,255,255)}}
		end;
	end
end

EXPR_LIB.ValidateAndDebug = function(editor, goto, code)
	local t = EXPR_TOKENIZER.New();
	
	t:Initalize("EXPADV", code);
	
	local ts, tr = t:Run();

	if (not ts) then
		if (tr.state == "internal") then
			editor.btnValidate:SetText("Internal error from tokenizer " .. tr.msg);
			editor.btnValidate:SetColor(Color(255, 0, 0));
		else
			editor.btnValidate:SetText("Tokenizer error " .. tr.msg);
			editor.btnValidate:SetColor(Color(255, 0, 0));

			if (goto) then
				editor.pnlTabHolder:GetActiveTab():GetPanel():SetCaret(Vector2(tr.line, tr.char));
			end
		end

		return false;
	end

	local p = EXPR_PARSER.New();

	p:Initalize(tr);

	local ps, pr = p:Run();

	if (not ps) then
		if (pr.state == "internal") then
			editor.btnValidate:SetText("Internal error from parser " .. pr.msg);
			editor.btnValidate:SetColor(Color(255, 0, 0));
		else
			editor.btnValidate:SetText("Parser error " .. pr.msg);
			editor.btnValidate:SetColor(Color(255, 0, 0));

			if (goto) then
				editor.pnlTabHolder:GetActiveTab():GetPanel():SetCaret(Vector2(pr.line, pr.char));
			end
		end

		return false;
	end

	local c = EXPR_COMPILER.New();

	c:Initalize(pr);

	local cs, cr = c:Run();

	if (not cs) then
		if (cr.state == "internal") then
			editor.btnValidate:SetText("Internal error from compiler " .. cr.msg);
			editor.btnValidate:SetColor(Color(255, 0, 0));
		else
			editor.btnValidate:SetText("Compiler error " .. cr.msg);
			editor.btnValidate:SetColor(Color(255, 0, 0));

			if (goto) then
				editor.pnlTabHolder:GetActiveTab():GetPanel():SetCaret(Vector2(cr.line, cr.char));
			end
		end

		return false;
	end

	editor.btnValidate:SetText("Validation sucessful");
	editor.btnValidate:SetColor(Color(0, 255, 255));

	EXPR_LIB.ShowDebug(tr.tokens, pr.tasks);

	return true;
end;
