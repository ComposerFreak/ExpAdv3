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

COLORS.Generic = Color(2555, 255, 255);
COLORS.Removed = Color(255, 0, 0);
COLORS.Replaced = Color(150, 150, 0);
COLORS.Before = Color(100, 200, 200);
COLORS.After = Color(100, 200, 250);

local function ProcessLines(tokens, alltasks)
	local rows = {};

	local expr, lua = {}, {};

	for k, v in pairs(tokens) do
		
		if (v.newLine) then
			rows[#rows + 1] = expr;
			rows[#rows + 1] = lua;

			expr, lua = {}, {};
		end

		local taks = alltasks[v.pos];

		if (not tasks) then
			expr[#expr + 1] = {v.data .. " ", COLORS.Generic}
			lua[#lua + 1] = {v.data .. " ", COLORS.Generic}
		else

			local prefixs = tasks.prefix;

			if (prefixs) then
				for _, prefix in pairs(prefixs) do
					lua[#lua + 1] = {v.data .. " ", COLORS.Before}
				end
			end

			if (not tasks.remove) then
				if (tasks.replace) then
					expr[#expr + 1] = {v.data .. " ", COLORS.Replaced}
					lua[#lua + 1] = {tasks.replace.str .. " ", COLORS.Replaced}
				else
					expr[#expr + 1] = {v.data .. " ", COLORS.Generic}
					lua[#lua + 1] = {v.data .. " ", COLORS.Generic}
				end
			else
				expr[#expr + 1] = {v.data .. " ", COLORS.Removed}
			end

			local postfixs = tasks.postfix;

			if (postfixs) then
				for _, postfix in pairs(postfixs) do
					lua[#lua + 1] = {v.data .. " ", COLORS.After}
				end
			end
		end
	end

	rows[#rows + 1] = expr;
	rows[#rows + 1] = lua;

	local allTokens = {};

	for k, row in pairs(Rows) do
		for j, token in pairs(row) do
			allTokens[#AllTokens + 1] = token[1];
		end

		allTokens[#allTokens + 1] = "\n";
	end

	return rows, table.concat(AllTokens, " ");
end

EXPR_LIB.ShowDebug = function(tokens, tasks)
	if (Golem) then
		local inst = Golem:GetInstance();

		local rows, text = ProcessLines(tokens, alltasks);

		local editor, tab, sheet = inst:NewTab("editor", text, nil, "Debug");

		editor._OnKeyCodeTyped = function() end;
		editor._OnTextChanged = function() end;

		sheet.Panel.SyntaxColorLine = function(self, row)
			return rows[row];
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

		return;
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

		return;
	end

	local c = EXPR_COMPILER.New();

	c:Initalize();

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

		return;
	end

	editor.btnValidate:SetText("Validation sucessful");
	editor.btnValidate:SetColor(Color(0, 255, 255));

	EXPR_LIB.ShowDebug(ts.__tokens, pr.__tasks);
end;
