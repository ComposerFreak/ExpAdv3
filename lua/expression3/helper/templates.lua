if SERVER then return; end

/*********************************************************************************
	Make our signatures look pretty
*********************************************************************************/

local function name(id)
	if (id == nil) then return nil; end
	local obj = EXPR_LIB.GetClass(id);
	if (!obj) then obj = EXPR_LIB.GetClass(id:lower()); end
	if (obj and obj.name) then return obj.name; end
	if (id == "o") then return "object"; end
	return id;
end

function EXPR_DOCS.PrettyPerams(perams)
	if (!perams or perams == "") then return ""; end
	
	local r = {};

	for k, v in pairs(string.Explode(",", perams)) do
		r[k] = name(v);
	end

	return table.concat(r,", ");
end

local prettyPerams = EXPR_DOCS.PrettyPerams;

local prettyReturns = function(op)
	local rt = op["result type"] or "";

	local rc = tonumber(op["result count"]) or 0;
	if rc == 0 or rt == "" or rt == "NIL" then return "void" end

	rt = name(rt);
	if rc == 1 then return rt end

	for i = 2, rc do
		rt = rt .. ", " .. rt;
	end

	return rt;
end

function EXPR_DOCS.PrettyEvent(op)
	return string.format("%s(%s)", op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyFunction(op)
	return string.format("%s.%s(%s)", op.library, op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyConstructor(op)
	return string.format("new %s(%s)", op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyMethod(op)
	--local id = op.id:upper();

	--if id[1] == "_" then id = id:sub(2); end

	return string.format("%s.%s(%s)", name(op.id), op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyReturn(op)
	local t = op["result type"];
	local c = tonumber(op["result count"]) or 0;
	
	if (not t) or (t == "") or (t == "_nil") or (c == 0) then return ""; end

	if t[1] == "_" then t = t:sub(2); end

	if c == 1 then return t:upper(); end

	return string.format("(%s x %d)", t:upper(), c);
end

/*********************************************************************************
	HTML Template Sheet
*********************************************************************************/
local pre_html = [[
	<html>
		<body>

			<style>
				body {background-color: #000; color: #FFF}
				table {width: 100%}
			</style>

			<table>		
]];

local post_html = [[
			</table>
		<body>
	</html>
]];

EXPR_DOCS.parseBB = function(html)
	html = html:gsub("%[b%](.-)%[/b%]", "<strong>%1</strong>");
	html = html:gsub("%[i%](.-)%[/i%]", "<em>%1</em>");
	html = html:gsub("%[u%](.-)%[/u%]", "<u>%1</u>");
	html = html:gsub("%[color=(.-)%](.-)%[/color%]", "<span style='color:%1;'>%2</span>");
	html = html:gsub("%[h1%](.-)%[/h1%]", "<h1>%1</h1>");
	html = html:gsub("%[h2%](.-)%[/h2%]", "<h2>%1</h2>");
	html = html:gsub("%[h3%](.-)%[/h3%]", "<h3>%1</h3>");
	html = html:gsub("%[img%s?size=(%d+)x(%d+)%](.-)%[/img%]", "<img src='%3' width='%1' height='%2' />");
	html = html:gsub("%[img%](.-)%[/img%]", "<img src='%1' />");
	html = html:gsub("%[box color=(.-)%](.-)%[/box%]", "<div style='border-radius: 10px; padding: 10px; background-color:%1; display: inline-block;'>%2</div>");
	return html;
end

EXPR_DOCS.toHTML = function(tbl)
	local lines = {pre_html};

	for k, v in pairs(tbl) do
		
		if istable(v) then
			local str = string.format("<td>%s</td>\n<td>%s</td>", tostring(v[1] or ""), tostring(v[2] or ""));
			str = string.format("<tr>%s</tr>", str);
			str = EXPR_DOCS.parseBB(str);
			lines[#lines + 1] = str;
		else
			local str = string.format("<td colspan=\"2\">%s</td>", tostring(v or ""));
			str = string.format("<tr>%s</tr>", str);
			str = EXPR_DOCS.parseBB(str);
			lines[#lines + 1] = str;
		end

	end

	lines[#lines + 1] = post_html;

	return table.concat(lines, "\n"), #tbl;

end

/*********************************************************************************
	Add export state icons to nodes
*********************************************************************************/

local function addSaveStateIcon(pnl, node, docs, i, keyvalues)
	if docs then
		local btn = pnl:EmbedButton(node, "GOLEM_StateBox", 24, 0);

		--btn:AddState("v", nil, nil);
		btn:AddState("n", false, "fugue/minus-small-circle.png");
		btn:AddState("y", true, "fugue/tick-small-circle.png");

		if i then
			btn:PollFromCallback(function()
				return docs.clk[i];
			end);
	
			btn.ChangedValue = function(value)
				docs.clk[i] = value;
			end;
		end
	end

end

/*********************************************************************************
	state and description helpers
*********************************************************************************/

local function describe(str)
	--if str and str ~= "" then return str; end
	return str or "No helper data avalible.";
end

local function state(n)
	n = tonumber(n);
	if n == EXPR_SERVER then return {"[img]asset://garrysmod/materials/fugue/state-server.png[/img]", "Must be part of a server side statment."}; end
	if n == EXPR_CLIENT then return {"[img]asset://garrysmod/materials/fugue/state-client.png[/img]", "Must be part of a client side statment."}; end
	if n == EXPR_SHARED then return {"[img]asset://garrysmod/materials/fugue/state-shared.png[/img]", "Can appear anywhere, both server side and clientside."}; end
	return "[ERROR]";
end

local function stateIcon(node, n)
	n = tonumber(n);
	if n == EXPR_SERVER then node:SetIcon("fugue/state-server.png"); end
	if n == EXPR_CLIENT then node:SetIcon("fugue/state-client.png"); end
	if n == EXPR_SHARED then node:SetIcon("fugue/state-shared.png"); end
end

/*********************************************************************************
	Add event nodes to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.EventHelpers", function(pnl)
	local event_docs = EXPR_DOCS.GetEventDocs();

	event_docs:ForEach( function(i, keyvalues)
		local signature = EXPR_DOCS.PrettyEvent(keyvalues);

		local node = pnl:AddNode("Events", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function()
			local keyvalues = event_docs:ToKV(event_docs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Event:", string.format("%s(%s)", keyvalues.name, EXPR_DOCS.PrettyPerams(keyvalues.parameter))},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, type_docs;
		end);

		addSaveStateIcon(pnl, node, type_docs, i, keyvalues);

	end );
end);

/*********************************************************************************
	Add library nodes to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.LibraryHelpers", function(pnl)
	
	local libdocs = EXPR_DOCS.GetLibraryDocs();

	libdocs:ForEach( function(i, keyvalues)

		local node = pnl:AddNode("Libraries", keyvalues.name);

		pnl:AddHTMLCallback(node, function()
			local keyvalues = libdocs:ToKV(libdocs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Library", keyvalues.name},
				keyvalues.example,
				describe(keyvalues.desc),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, libdocs;
		end);

		addSaveStateIcon(pnl, node, libdocs, i, keyvalues);

	end );


	local fundocs = EXPR_DOCS.GetFunctionDocs();

	fundocs:ForEach( function(i, keyvalues)
		local signature = EXPR_DOCS.PrettyFunction(keyvalues);
		local result = EXPR_DOCS.PrettyReturn(keyvalues);

		local node = pnl:AddNode("Libraries", keyvalues.library, "Functions", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			local keyvalues = fundocs:ToKV(fundocs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Function:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, fundocs;
		end);

		addSaveStateIcon(pnl, node, fundocs, i, keyvalues);

	end );


	local constdocs = EXPR_DOCS.GetConstantDocs();

	constdocs:ForEach( function(i, keyvalues)
		local node = pnl:AddNode("Libraries", keyvalues.library, "Constants", keyvalues.signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			local keyvalues = constdocs:ToKV(constdocs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Constant:", keyvalues.signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, constdocs;
		end);

		addSaveStateIcon(pnl, node, constdocs, i, keyvalues);

	end );

end);

/*********************************************************************************
	Add class nodes to the helper
*********************************************************************************/
hook.Add("Expression3.LoadHelperNodes", "Expression3.ClassHelpers", function(pnl)
	local lk = {};

	local type_docs = EXPR_DOCS.GetTypeDocs();

	type_docs:ForEach( function(i, keyvalues)

		if not lk[keyvalues.id] then
			
			lk[keyvalues.id] = keyvalues.name;

			local node = pnl:AddNode("Classes", keyvalues.name);
			
			stateIcon(node, keyvalues.state);

			pnl:AddHTMLCallback(node, function()
				local keyvalues = type_docs:ToKV(type_docs.data[i]);
				
				return EXPR_DOCS.toHTML({
					{"Class:", string.format("%s (%s)", keyvalues.name, EXPR_DOCS.PrettyPerams(keyvalues.id))},
					{"Extends:", string.format("%s", name(keyvalues.extends))},
					keyvalues.example,
					describe(keyvalues.desc),
					state(keyvalues.state),
				});
			end);

			pnl:AddOptionsMenu(node, function()
				return keyvalues, type_docs;
			end);

			addSaveStateIcon(pnl, node, type_docs, i, keyvalues);

		end

	end );

	local const_docs = EXPR_DOCS.GetConstructorDocs();

	const_docs:ForEach( function(i, keyvalues)

		local signature = EXPR_DOCS.PrettyConstructor(keyvalues);

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Constructors", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function()
			local keyvalues = const_docs:ToKV(const_docs.data[i]);

			keyvalues["result type"] = keyvalues.id;
			keyvalues["result count"] = 1;

			return EXPR_DOCS.toHTML({
				{"Constructor:", string.format("new %s(%s)", keyvalues.name, prettyPerams(keyvalues.parameter))},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, const_docs;
		end);

		addSaveStateIcon(pnl, node, const_docs, i, keyvalues);

	end );

	local attr_docs = EXPR_DOCS.GetAttributeDocs();

	attr_docs:ForEach( function(i, keyvalues)

		local class = lk[keyvalues.id] or "";

		local node = pnl:AddNode("Classes", class, "Attributes", string.format("%s.%s", class, keyvalues.name));

		pnl:AddHTMLCallback(node, function()
			local keyvalues = attr_docs:ToKV(attr_docs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Attribute:", string.format("%s.%s", class, keyvalues.name)},
				{"Type:", lk[keyvalues.type]},
				keyvalues.example,
				describe(keyvalues.desc),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, attr_docs;
		end);

		addSaveStateIcon(pnl, node, attr_docs, i, keyvalues);

	end );

	local method_docs = EXPR_DOCS.GetMethodDocs();

	method_docs:ForEach( function(i, keyvalues)

		local signature = EXPR_DOCS.PrettyMethod(keyvalues, true);

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Methods", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			local keyvalues = method_docs:ToKV(method_docs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Method:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, method_docs;
		end);

		addSaveStateIcon(pnl, node, method_docs, i, keyvalues);
	end );

end);

/*********************************************************************************
	Operators are a lot of work
*********************************************************************************/

local function prettyOp(op)
	local signature = op.signature;

	signature = signature:upper():Replace("_", "");

	local match1, match2 = string.match(signature, "^([A-Za-z]+)%(([A-Za-z0-9_,]+)%)$");

	if match1 then
		local args = string.Explode(",", match2);

		local c = #args;

		local token;
		local named;

		    if match1 == "EQ"  then token, named = "==", "Equal to ( == )";
		elseif match1 == "NEQ" then token, named = "!=", "Not equal to ( != )";
		elseif match1 == "LEG" then token, named = "<=", "Less or equal to ( <= )";
		elseif match1 == "GEQ" then token, named = ">=", "Greather or equal to ( >= )";
		elseif match1 == "LTH" then token, named = "<", "Less then ( < )";
		elseif match1 == "GTH" then token, named = ">", "Greater than ( > )";
		elseif match1 == "DIV" then token, named = "/", "Divide ( / )";
		elseif match1 == "MUL" then token, named = "*", "Multiply ( * )"; 
		elseif match1 == "SUB" then token, named = "-", "Subtract ( - )";
		elseif match1 == "ADD" then token, named = "+", "Add ( + )";
		elseif match1 == "EXP" then token, named = "^", "Exponent ( ^ )";
		elseif match1 == "MOD" then token, named = "%", "Modulo ( % )";
		elseif match1 == "AND" then token, named = "&&", "Logical and ( && )";
		elseif match1 == "OR" then token, named = "||", "Logical or ( || )";
		elseif match1 == "BAND" then token, named = "&", "Bitwise and ( & )";
		elseif match1 == "BOR" then token, named = "|", "Bitwise or ( | )";
		elseif match1 == "BXOR" then token, named = "^^", "^^";
		elseif match1 == "BSHL" then token, named = "<<", "Bitwise shift l ( << )";
		elseif match1 == "BSHR" then token, named = ">>", "Bitwise shift r ( >> )";
		end

		if token then
			if c == 2 then return string.format("%s %s %s", name(args[1]), token, name(args[2])), token, named; end
		end

		if match1 == "SET" then
			local cls = name(args[3]) or "CLS";
			if cls and cls == "CLS" then cls = "type"; end

			if c >= 3 then return string.format("%s[%s,%s] = %s", name(args[1]), name(args[2]), cls, name(args[4]) or cls), "[]=", "Set ( []= )"; end
		end

		if match1 == "GET" then
			local cls = name(args[3]) or "CLS";
			if cls and cls == "CLS" then cls = "type"; end

			if c >= 2 then return string.format("%s[%s,%s]", name(args[1]), name(args[2]), cls), "[]", "Get ( [] )"; end
		end

		//if match1 == "IS" then token = ""; //else
			if match1 == "NOT" then token, named = "!", "Not ( ! )";
		elseif match1 == "LEN" then token, named = "#", "Length ( # )";
		elseif match1 == "NEG" then token, named = "-", "Negative ( - )";
		end

		if token then
			if c == 1 then return string.format("%s%s", token, name(args[2])), token, named; end
		end

		if match1 == "TEN" then
			if c == 3 then return string.format("%s ? %s : %s", name(args[1]), name(args[2]), name(args[3])), "?:", "Tenary ( ?: )"; end
		end

		if match1 == "ITOR" then
			if c == 1 then return string.format("foreach(type k; type v in %s) {}", name(args[1])), "foreach", "Foreach loop"; end
		end
	end

	match1, match2 = string.match(op.signature, "^%(([A-Za-z0-9_]+)%)([A-Za-z0-9_]+)$");

	if match1 and match2 then
		return string.format("(%s) %s", name(match1), name(match2)), "casting", "casting";
	end

	return signature, "misc", "unsorted";
end

/*********************************************************************************
	Add class nodes to the helper
*********************************************************************************/
hook.Add("Expression3.LoadHelperNodes", "Expression3.OperatorHelpers", function(pnl)
	local op_docs = EXPR_DOCS.GetOperatorDocs();

	op_docs:ForEach( function(i, keyvalues)

		local signature, token, named = prettyOp(keyvalues);

		local node = pnl:AddNode("Operators", named, signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			local keyvalues = op_docs:ToKV(op_docs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Operator:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, op_docs;
		end);

		addSaveStateIcon(pnl, node, op_docs, i, keyvalues);

	end);
end);

/*********************************************************************************
	Add example nodes to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.Examples", function(pnl)

	local path = "lua/expression3/helper/examples/";

	local editor = Golem.GetInstance( );

	local files = file.Find(path .. "*.lua", "GAME");

	for i, filename in pairs( files ) do
		local node = pnl:AddNode("Examples", filename);
		
		node.DoClick = function()
			local sCode = file.Read(path .. filename, "GAME");
			return editor:NewTab("editor", sCode, path .. filename, filename);
		end;

		node:SetIcon("fugue/script-text.png");
	end

end);

/*********************************************************************************
	Add url nodes to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.Links", function(pnl)

	local function addLink(sName, sUrl, sIcon)
		local node = pnl:AddNode("Links", sName);

		node:SetIcon(sIcon or sIcon);

		node.DoClick = function()
			gui.OpenURL(sUrl);
		end;
	end

	addLink("Git Hub", "https://github.com/ComposerFreak/ExpAdv3", "e3_github.png");
	addLink("Video Tutorials", "https://www.youtube.com/playlist?list=PLOxsj9mdwMARIj7m9MkFkV1mno6nc1TpN", "e3_youtube.png");
	//addLink("Offical Discord", "https://discord.gg/ktZFksbru7", "e3_discord.png");
	
	hook.Run("Expression3.LoadHelperLinks", addLink);

end);


/*********************************************************************************
	Youtube Videos
*********************************************************************************/
hook.Add("Expression3.LoadHelperNodes", "Expression3.Youtube", function(pnl)

	function AddYoutube(video, name)
		local node = pnl:AddNode("Tutorials", name);
		
		if (BRANCH == "x86-64") then
			local HTML = [[<iframe width="560" height="315" src="https://www.youtube.com/embed/]] .. video .. [[" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>]];
			
			pnl:AddHTMLCallback(node, function()
				return HTML, 14, 600;
			end);

		else
			node.DoClick = function() gui.OpenURL("https://youtube.com/watch?v=" .. video); end
		end
	
		node:SetIcon("e3_youtube.png");
	end
	
	AddYoutube("BkWZpEEb13o", "Editor Overview");
	AddYoutube("n636qx5A_o4", "Hellow World");
	AddYoutube("GUozLFU9YBM", "Directives and Wire IO");
	AddYoutube("VTfu3gu5uyE", "Variables and Constructors");
	AddYoutube("lNBLRmNXnpg", "User Functions and Delegates");
	AddYoutube("5jdTEPrpuPw", "Callbacks, Events and Timers");
	AddYoutube("YrfpKMaOW3g", "User Classes");

	hook.Run("Expression3.LoadTutorials", pnl, AddYoutube);
end);

/*********************************************************************************
	Add exported data files to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.SavedHelpers", function(pnl)

	local path = "e3docs/saved/";

	local editor = Golem.GetInstance( );

	local files = file.Find(path .. "*.txt", "DATA");

	for i, filename in pairs( files ) do

		local node = pnl:AddNode("Custom Helpers", filename)

		node:SetIcon("fugue/xfn.png");

		node.DoClick = function()
			local ok, err = EXPR_DOCS.LoadCustomDocFile(path .. filename, "DATA");

			if ok then
				pnl.CurrentHelperPath = path .. filename;
				pnl:WriteLine(Color(255, 255, 255), "Loaded Custom Helpers ", Color(0, 255, 0), filename);
			else
				pnl:WriteLine(Color(255, 255, 255), "Error Loading Custom Helpers ", Color(0, 255, 0), filename);
				pnl:WriteLine(Color(255, 255, 255), "Error ", Color(0, 255, 0), err);
			end
		end;
	end

end);

/*********************************************************************************
	Add menu to golem
*********************************************************************************/
hook.Add( "Expression3.AddGolemTabTypes", "HelperTab", function(editor)
	editor:AddCustomTab(false, "helper", function( self )
		if self.Helper then
			self.pnlSideTabHolder:SetActiveTab( self.Helper.Tab )
			self.Helper.Panel:RequestFocus( )
			return self.Helper
		end

		local Panel = vgui.Create( "GOLEM_E3Helper" )
		local Sheet = self.pnlSideTabHolder:AddSheet( "", Panel, "fugue/question.png", function(pnl) self:CloseMenuTab( pnl:GetParent( ), true ) end )
		self.pnlSideTabHolder:SetActiveTab( Sheet.Tab )
		self.Helper = Sheet
		Sheet.Panel:RequestFocus( )

		return Sheet
	end, function( self )
		self.Helper = nil
	end );

	editor.tbRight:SetupButton( "Helper", "fugue/question.png", TOP, function( ) editor:NewMenuTab( "helper" ); end )

	if (editor.btnHideSidebar.Expanded) then
		local tab = editor.pnlSideTabHolder:GetActiveTab()
		
		if (!IsValid( tab ) or !ispanel( tab )) then
			timer.Simple(1, function() editor:NewMenuTab( "helper" ); end)
		end
	end
end );