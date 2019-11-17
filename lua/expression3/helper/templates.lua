if SERVER then return; end

/*********************************************************************************
	Make our signatures look pretty
*********************************************************************************/

function EXPR_DOCS.PrettyPerams(perams)
	local r = {};

	for k, v in pairs(string.Explode(",", perams)) do
		if v[1] == "_" then v = v:sub(2); end
		r[k] = v:upper();
	end

	return table.concat(r,",");
end

local prettyPerams = EXPR_DOCS.PrettyPerams;

local prettyReturns = function(op)
	local rt = op["result type"] or "";

	--if rt then rt = prettyPerams(rt); end

	local rc = tonumber(op["result count"]) or 0;

	if rc == 0 or rt == "" or rt == "NIL" then return "" end

	local typ = EXPR_LIB.GetClass(rt);

	if typ then rt = typ.name; end

	if rc == 1 then return rt end

	return string.format("%s *%i", rt, rc);
end

function EXPR_DOCS.PrettyFunction(op)
	return string.format("%s.%s(%s)", op.library, op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyConstructor(op)
	return string.format("new %s(%s)", op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyMethod(op)
	local id = op.id:upper();

	if id[1] == "_" then id = id:sub(2); end

	return string.format("%s.%s(%s)", id, op.name, prettyPerams(op.parameter));
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
				tr:nth-child(odd) {background: #333}
			</style>

			<table>		
]];

local post_html = [[
			</table>
		<body>
	</html>
]];

local toHTML = function(tbl)

	local lines = {pre_html};

	for k, v in pairs(tbl) do
		
		if istable(v) then
			local str = string.format("<td>%s</td>\n<td>%s</td>", tostring(v[1] or ""), tostring(v[2] or ""));
			lines[#lines + 1] = string.format("<tr>%s</tr>", str);
		else
			local str = string.format("<td colspan=\"2\">%s</td>", tostring(v or ""));
			lines[#lines + 1] = string.format("<tr>%s</tr>", str);
		end

	end

	lines[#lines + 1] = post_html;

	return table.concat(lines, "\n"), #tbl;

end

/*********************************************************************************
	Golem menu panel
*********************************************************************************/
local EDITOR_PANEL = {};

local tick = Material("fugue/tick.png");
local cross = Material("fugue/exclamation-red.png");

function EDITOR_PANEL:Init()
	self.items = {};
end

function EDITOR_PANEL:AddValue(name, value, callback)
	local h = 22;
	local w = self:GetWide();

	local pnl = self:Add("DHorizontalDivider");
	pnl:SetSize(w, h);

	pnl.lbl = pnl:Add("DLabel");
	pnl.lbl:SetText(name);
	pnl:SetLeftWidth(w * 0.25);
	pnl:SetLeft(pnl.lbl);

	pnl.txt = pnl:Add("GOLEM_TextEntry");
	pnl.txt:SetMaterial(tick);
	pnl.txt:SetPlaceholderText(name);
	pnl.txt:SetValue(value);
	pnl:SetRight(pnl.txt);

	local function updateIcon(v)
		pnl.txt:SetMaterial(value == v and tick or cross);
	end

	pnl.txt.OnChange = function(_, v)
		updateIcon(v);
	end;

	pnl.txt.DoClick = function(_, v)
		value = v;
		callback(v);
		updateIcon(v);
	end;

	pnl.txt.OnEnter = function(_, v)
		value = v;
		callback(v);
		updateIcon(v);
	end;

	self.items[name] = pnl;

	return pnl;
end

function EDITOR_PANEL:Clear()
	for k, v in pairs(self.items) do
		v:Remove();
	end

	self.items = {};

	self:InvalidateLayout();
end

function EDITOR_PANEL:SetValues(tbl)
	
	self:Clear();
	
	for k, v in pairs(tbl) do
		self:AddValue(k, v, function(value)
			tbl[k] = value;
		end);
	end
end

vgui.Register("GOLEM_E3HelperEditor", EDITOR_PANEL, "DListLayout");


/*********************************************************************************
	Golem menu panel
*********************************************************************************/

local HELPER_PANEL = {};

local icon_open = Material("fugue/toggle-small.png");
local icon_small = Material("fugue/toggle-small-expand.png");

function HELPER_PANEL:Init()

	self:DockPadding(5, 5, 5, 5);

	self.edtr_pnl = self:Add("GOLEM_E3HelperEditor");
	self.edtr_pnl:SetTall(0);
	self.edtr_pnl:DockMargin(5, 5, 5, 5);
	self.edtr_pnl:Dock(TOP);

	self.html_pnl = self:Add("DHTML");
	self.html_pnl:SetTall(0);
	self.html_pnl:DockMargin(5, 5, 5, 5);
	self.html_pnl:Dock(TOP);

	self.srch_pnl = self:Add("GOLEM_Toolbar");
	self.srch_pnl:SetTall(22);
	self.srch_pnl:DockMargin(5, 5, 5, 5);
	self.srch_pnl:Dock(TOP);

	self.root_tree = self:Add("DTree");
	self.root_tree:SetBackgroundColor(Color(0, 0, 0));
	self.root_tree:SetWide(200);
	self.root_tree:DockMargin(5, 5, 5, 5);
	self.root_tree:Dock(FILL);

	self.ctrl_pnl = self:Add("GOLEM_Toolbar");
	self.ctrl_pnl:SetTall(22);
	self.ctrl_pnl:DockMargin(5, 5, 5, 5);
	self.ctrl_pnl:Dock(BOTTOM);

	self.cls_btn = self.srch_pnl:SetupButton("Expand List", "fugue/arrow-090-small.png", RIGHT, function()
		self.cls_btn:SetVisible(false);
		self:CloseHTML();
		self:CloseEditor();
	end);

	self.cls_btn:SetVisible(false);

	self.srch_txt = self.srch_pnl:SetupTextBox( "Search", "fugue/binocular-small.png", FILL, function(_, str)
		self:SearchAll(str, true);
	end, nil);

	self.srch_txt:SetPlaceholderText("Search Helper");
	self.srch_txt:DockIcon(RIGHT);

	self.srch_txt.OnEnter = function(_, str)
		self:SearchAll(str, true);
	end;

	self.ctrl_pnl:SetupButton("Reload Helper", "fugue/arrow-circle.png", RIGHT, function()
		self:Reload();
	end);

	self.ctrl_pnl:SetupButton("Save Helper Data", "fugue/disk-black.png", RIGHT, function()
		EXPR_DOCS.SaveLocalDocs();
	end);

	self.ctrl_pnl:SetupButton("Close All", "fugue/arrow-090-small.png", LEFT, function()
		self:ExpandAll(false);
	end);

	self.ctrl_pnl:SetupButton("Expand All", "fugue/arrow-270-small.png", LEFT, function()
		self:ExpandAll(true);
	end);

	self:Reload();--hook.Run("Expression3.LoadHelperNodes", self);
end

function HELPER_PANEL:OpenEditor(kv)
	self.cls_btn:SetVisible(true);
	self.edtr_pnl:SetVisible(true);
	if kv then self.edtr_pnl:SetValues(kv); end
	self:CloseHTML();
end

function HELPER_PANEL:CloseEditor()
	self.edtr_pnl:SetVisible(false);
	self.edtr_pnl:SetTall(0);
	self:InvalidateLayout();
end

function HELPER_PANEL:OpenHTML(h)
	self.cls_btn:SetVisible(true);
	self.html_pnl:SetVisible(true);
	self.html_pnl:SetTall(h);
	self:CloseEditor();
end

function HELPER_PANEL:CloseHTML()
	self.html_pnl:SetVisible(false);
	self.html_pnl:SetTall(0);
	self:InvalidateLayout();
end

/*********************************************************************************
	Reload button
*********************************************************************************/

local bookmark_icon = "fugue/book-bookmark.png";

function HELPER_PANEL:Reload()
	local subnodes = self.root_tree.subnodes;

	if subnodes then

		for _, node in pairs(subnodes) do
			node:Remove();
		end

		self.root_tree.subnodes = {};
	end

	self:AddNode("Links"):SetIcon("fugue/globe-network.png");
	self:AddNode("Examples"):SetIcon("fugue/blue-folder--plus.png");
	self:AddNode("Book Marks"):SetIcon(bookmark_icon);

	self:AddNode("Libraries");
	self:AddNode("Classes");
	self:AddNode("Operators");

	hook.Run("Expression3.LoadHelperNodes", self);
end

/*********************************************************************************
	Set up and apply custom theme to nodes
*********************************************************************************/

local function applyCustomSkin(node)

	node:SetIcon("fugue/block.png");

	if node.Expander then
		function node.Expander.Paint(self, w, h)
			local mat = self.m_bExpanded and icon_open or icon_small;

			surface.SetDrawColor(255, 255, 255);
			surface.SetMaterial(mat);
			surface.DrawTexturedRect(0, 0, w, h);
		end
	end
end

/*********************************************************************************
	Add new nodes to the helper
*********************************************************************************/

local addNode;

addNode = function(self, frs, scnd, ...)
	if not self.subnodes then self.subnodes = { }; end

	local node = self.subnodes[frs];

	if not node then
		node = self:AddNode(frs);

		applyCustomSkin(node);

		self.subnodes[frs] = node;
	end

	if not scnd then return node; end

	return addNode(node, scnd, ...);
end;


function HELPER_PANEL:AddNode(frs, scnd, ...)
	return addNode(self.root_tree, frs, scnd, ...);
end

/*********************************************************************************
	Expand all nodes
*********************************************************************************/

local expandAll;

expandAll = function(node, expand, anim)
	node:SetExpanded(expand, anim);

	if node.subnodes then
		for k, v in pairs(node.subnodes) do
			expandAll(v, expand, anim);
		end
	end
end;

function HELPER_PANEL:ExpandAll(expand, anim)
	return expandAll(self.root_tree, expand, anim);
end

/*********************************************************************************
	Search panels
*********************************************************************************/

local searchNodes;

searchNodes = function(node, query)
	local c = 0;

	if node.subnodes then
		for k, v in pairs(node.subnodes) do
			c = c + searchNodes(v, query);
		end
	end

	local val = node:GetText():upper();
	local found = string.find(val, query:upper(), 1, true);
	
	local visible = true;

	if c == 0 and (not found) then
		visible = false;
	end

	if query == "" then
		visible = true;
	end

	node:SetVisible(visible);

	if visible then
		c = c + 1;
	end

	return c;
end;

function HELPER_PANEL:SearchAll(query)
	local c = searchNodes(self.root_tree, query);

	self:ExpandAll(query ~= "");

	return c;
end

/*********************************************************************************
	Scroll To
*********************************************************************************/
local getY;

getY = function(root, node, x, y)
	local parent = node:GetParent();

	if parent == root then return x, y; end

	local _x, _y = node:GetPos();

	x = x + _x;
	y = y + _y;

	return getY(root, parent, x, y);
end

function HELPER_PANEL:ScrollTo(node)
	timer.Simple(0.01, function()
		self.root_tree:ScrollToChild(node);
	end);
end

/*********************************************************************************
	Show html
*********************************************************************************/

function HELPER_PANEL:AddHTMLCallback(node, callback)
	node.DoClick = function(this)
		local str, num = callback();
		local tall = num and ((num * 25) + 10) or 100;
		self.html_pnl:SetHTML(str);
		self:OpenHTML(tall);
	end;
end

/*********************************************************************************
	Show Menu Options
*********************************************************************************/

local edit_icon = "fugue/pencil.png";
local open_book_icon = "fugue/book-open-bookmark.png";
local closed_book_icon = "fugue/book.png";
local goto_icon = "fugue/eye--arrow.png";

function HELPER_PANEL:AddOptionsMenu(node, callback)
	
	node.DoRightClick = function()

		local menu = DermaMenu();

		if callback then
			menu:AddOption( "Edit", function()
				local kv = callback();

				self:OpenEditor(kv);

			end):SetIcon(edit_icon);
		end

		if not node.isBookMarked then

			menu:AddOption( "Book Mark", function()
				
				node.isBookMarked = true;
				node.bookMark = self:AddNode("Book Marks", node:GetText());
				node.bookMark.BookMarkOff = node;
				node.bookMark.isBookMarked = true;
				node.bookMark:SetIcon(node:GetIcon());
				node.bookMark.DoClick = function()
					node:DoClick();
				end;

				self:AddOptionsMenu(node.bookMark);

			end):SetIcon(open_book_icon);

		end

		if node.isBookMarked then

			menu:AddOption( "Remove Book Mark", function()
				if node.bookMark then
					node.bookMark:Remove();
				else
					node:Remove();
				end

				node.bookMark = nil;
				node.isBookMarked = false;
			end):SetIcon(closed_book_icon);

			if node.BookMarkOff then
				menu:AddOption( "Goto", function()
					self.root_tree:SetSelectedItem(node.BookMarkOff);
					node.BookMarkOff:ExpandTo(true);
					self:ScrollTo(node);
				end):SetIcon(goto_icon);
			end

		end

		menu:Open();
	end;

end

/*********************************************************************************
	Add book mark
*********************************************************************************/

vgui.Register("GOLEM_E3Helper", HELPER_PANEL, "EditablePanel");

/*********************************************************************************
	Add library nodes to the helper
*********************************************************************************/
local function describe(str)
	if str and str ~= "" then return str; end
	return "No helper data avalible.";
end

local function state(n)
	if n == EXPR_SERVER then return "[SERVER]"; end
	if n == EXPR_CLIENT then return "[CLIENT]"; end
	return "[SERVER] [CLIENT]";
end

local function stateIcon(node, n)
	if n == EXPR_SERVER then node:SetIcon("fugue/state-server.png") end
	if n == EXPR_CLIENT then node:SetIcon("fugue/state-client.png") end
	return node:SetIcon("fugue/state-shared.png");
end

hook.Add("Expression3.LoadHelperNodes", "Expression3.LibraryHelpers", function(pnl)
	
	local libdocs = EXPR_DOCS.GetLibraryDocs();

	libdocs:ForEach( function(i, keyvalues)

		local node = pnl:AddNode("Libraries", keyvalues.name);

		pnl:AddHTMLCallback(node, function()
			return toHTML({
				{"Library", keyvalues.name},
				keyvalues.example,
				describe(keyvalues.desc),
			});
		end);

		pnl:AddHTMLCallback(node, function() 
			return toHTML({
				{"Library:", keyvalues.name},
				keyvalues.example,
				describe(keyvalues.desc),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues;
		end);

	end );


	local fundocs = EXPR_DOCS.GetFunctionDocs();

	fundocs:ForEach( function(i, keyvalues)
		local signature = EXPR_DOCS.PrettyFunction(keyvalues);
		local result = EXPR_DOCS.PrettyReturn(keyvalues);
		
		local node = pnl:AddNode("Libraries", keyvalues.library, signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			return toHTML({
				{"Function:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues;
		end);

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

			pnl:AddHTMLCallback(node, function()
				return toHTML({
					{"Class:", string.format("%s (%s)", keyvalues.name, EXPR_DOCS.PrettyPerams(keyvalues.id))},
					{"Extends:", string.format("%s", lk[keyvalues.extends] or "")},
					keyvalues.example,
					describe(keyvalues.desc),
				});
			end);

			pnl:AddOptionsMenu(node, function()
				return keyvalues;
			end);

		end

	end );

	local const_docs = EXPR_DOCS.GetConstructorDocs();

	const_docs:ForEach( function(i, keyvalues)

		local signature = EXPR_DOCS.PrettyConstructor(keyvalues);

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Constructors", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function()
			keyvalues["result type"] = keyvalues.id;
			keyvalues["result count"] = 1;

			return toHTML({
				{"Constructor:", string.format("new %s(%s)", keyvalues.name, prettyPerams(keyvalues.parameter))},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues;
		end);

	end );

	local attr_docs = EXPR_DOCS.GetAttributeDocs();

	attr_docs:ForEach( function(i, keyvalues)

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Attributes", keyvalues.name);

		pnl:AddHTMLCallback(node, function() 
			return toHTML({
				{"Atribute:", string.format("%s.%s", lk[keyvalues.id], keyvalues.name)},
				{"Type:", lk[keyvalues.type]},
				keyvalues.example,
				describe(keyvalues.desc),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues;
		end);

	end );

	local method_docs = EXPR_DOCS.GetMethodDocs();

	method_docs:ForEach( function(i, keyvalues)

		local signature = EXPR_DOCS.PrettyMethod(keyvalues);

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Methods", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			return toHTML({
				{"Method:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues;
		end);
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

		    if match1 == "EQ"  then token = "==";
		elseif match1 == "NEQ" then token = "!=";
		elseif match1 == "LEG" then token = "<=";
		elseif match1 == "GEQ" then token = ">=";
		elseif match1 == "LTH" then token = "<";
		elseif match1 == "GTH" then token = ">";
		elseif match1 == "DIV" then token = "/";
		elseif match1 == "MUL" then token = "*"; 
		elseif match1 == "SUB" then token = "-"; 
		elseif match1 == "ADD" then token = "+"; 
		elseif match1 == "EXP" then token = "^";
		elseif match1 == "MOD" then token = "%";
		elseif match1 == "AND" then token = "&&";
		elseif match1 == "OR" then token = "||";
		elseif match1 == "BAND" then token = "&";
		elseif match1 == "BOR" then token = "|";
		elseif match1 == "BXOR" then token = "^^";
		elseif match1 == "BSHL" then token = "<<";
		elseif match1 == "BSHR" then token = ">>";
		end

		if token then
			if c == 2 then return string.format("%s %s %s", args[1], token, args[2]), token; end
		end



		if match1 == "SET" then
			local cls = args[3] or "CLS";
			if cls and cls == "CLS" then cls = "type"; end

			if c >= 3 then return string.format("%s[%s,%s] = %s", args[1], args[2], cls, args[4] or cls), "[]="; end
		end

		if match1 == "GET" then
			local cls = args[3] or "CLS";
			if cls and cls == "CLS" then cls = "type"; end

			if c >= 2 then return string.format("%s[%s,%s]", args[1], args[2], cls), "[]"; end
		end



		    if match1 == "IS" then token = "";
		elseif match1 == "NOT" then token = "!";
		elseif match1 == "LEN" then token = "#";
		elseif match1 == "NEG" then token = "-";
		end

		if token then
			if c == 1 then return string.format("%s%s", token, args[2]), token; end
		end



		if match1 == "TEN" then
			if c == 3 then return string.format("%s ? %s : %s", args[1], args[2], args[3]), "?"; end
		end



		if match1 == "ITOR" then
			if c == 1 then return string.format("foreach(type k; type v in %s) {}", args[1]), "foreach"; end
		end

	end



	match1, match2 = string.match(op.signature, "^%(([A-Za-z0-9_]+)%)([A-Za-z0-9_]+)$");

	if match1 and match2 then
		match2 = match2:upper():Replace("_", "");

		local class = EXPR_LIB.GetClass(match1);
		if class then match1 = class.name; end;

		return string.format("(%s) %s", match1, match2), "casting";
	end

	return signature, "misc";
end

/*********************************************************************************
	Add class nodes to the helper
*********************************************************************************/
hook.Add("Expression3.LoadHelperNodes", "Expression3.OperatorHelpers", function(pnl)
	local op_docs = EXPR_DOCS.GetOperatorDocs();

	op_docs:ForEach( function(i, keyvalues)

		local signature, class = prettyOp(keyvalues);

		local node = pnl:AddNode("Operators", class, signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			return toHTML({
				{"Operator:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues;
		end);

	end);
end);

/*********************************************************************************
	Add example nodes to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.Examples", function(pnl)

	local path = "lua/expression3/helper/examples/";

	local editor = Golem.GetInstance( );

	local files = file.Find(path .. "*.txt", "GAME");

	for i, filename in pairs( files ) do
		local node = pnl:AddNode("Examples", filename);
		
		node.DoClick = function()
			local sCode = file.Read(path .. filename, "GAME");
			return editor:NewTab("editor", sCode, path, filename);
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

	addLink("Git Hub", "https://github.com/Rusketh/ExpAdv3", "e3_github.png");

	hook.Run("Expression3.LoadHelperLinks", addLink);

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
end );