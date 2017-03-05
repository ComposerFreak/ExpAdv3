/*============================================================================================================================================
	Name: GOLEM_Wiki
	Author: DaDamRival 
============================================================================================================================================*/
local PANEL = {}

function PANEL:Init()
	local allExpanded = false
	local searchNumber = 1
	local oldSearch = ""
	local searchResults = {}
	local searchResultsParents = {}
	
	local derma = {}
	
	self:DockPadding(5, 5, 5, 5)
	
	local Tree = self:Add("DTree")
	Tree:DockMargin(0, 50, 0, 0)
	Tree:Dock(FILL)
	Tree:MoveToBack()
	
	--------Expand all--------
	local ExpandAll = self:Add("DCheckBoxLabel")
	ExpandAll:SetPos(5, 50)
	ExpandAll:SetValue(allExpanded)
	ExpandAll:SetText("Expand All")
	function ExpandAll:OnChange(val)
		allExpanded = val
		
		for k, data in pairs(derma) do
			if table.Count(data.parents) < 2 then
				data.panel:SetExpanded(allExpanded)
			end
		end
	end
	
	--------Search--------
	local TextEntry = self:Add("DTextEntry")
	TextEntry:SetPos(0, 0)
	TextEntry:Dock(TOP)
	TextEntry:SetText("")
	TextEntry.OnEnter = function(self)
		local txt = self:GetValue()
		
		if txt != oldSearch then
			oldSearch = txt
			searchResults = {}
			searchNumber = 1
		elseif txt != "" then
			searchNumber = searchNumber + 1
		end
		
		if txt == "" then
			searchNumber = 1
			
			Tree:SetSelectedItem()
		end
		
		if txt != "" then
			searchResults = {}
			searchResultsParents = {}
			
			for k, data in pairs(derma) do
				local panel = data.panel
				local name = data.name or ""
				
				if name:lower():find(txt:lower()) then
					table.insert(searchResults, panel)
					table.insert(searchResultsParents, data.parents)
				end
			end
			
			if searchNumber > table.Count(searchResults) then
				searchNumber = 1
			end
			
			if table.Count(searchResults) > 0 then
				local panel = searchResults[searchNumber]
				
				Tree:SetSelectedItem(panel)
				
				for k, parent in pairs(searchResultsParents[searchNumber]) do
					parent:SetExpanded(true)
				end
			end
		end
	end
	
	local MoveSelect = self:Add("DPanel")
	MoveSelect:SetPos(5, 30)
	MoveSelect:SetSize(90, 15)
	MoveSelect.Paint = function(self, w, h)
		local ind = math.Clamp(searchNumber, 0, table.Count(searchResults))
		
		draw.RoundedBox(0, 0, 0, 90, 15, Color(50, 50, 50, 255))
		draw.DrawText(ind.."/"..table.Count(searchResults), "DermaDefault", 45, 1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
	end
	
	local MoveSelectLeft = vgui.Create("DButton", MoveSelect)
	MoveSelectLeft:SetPos(0, 0)
	MoveSelectLeft:SetSize(15, 15)
	MoveSelectLeft:SetText("<")
	MoveSelectLeft.DoClick = function()
		searchNumber = searchNumber - 1
		
		if searchNumber < 1 then
			searchNumber = table.Count(searchResults)
		end
		
		if table.Count(searchResults) > 0 then
			local panel = searchResults[searchNumber]
			
			Tree:SetSelectedItem(panel)
			
			for k, parent in pairs(searchResultsParents[searchNumber]) do
				parent:SetExpanded(true)
			end
		end
	end
	
	local MoveSelectRight = vgui.Create("DButton", MoveSelect)
	MoveSelectRight:SetPos(75, 0)
	MoveSelectRight:SetSize(15, 15)
	MoveSelectRight:SetText(">")
	MoveSelectRight.DoClick = function()
		searchNumber = searchNumber + 1
		
		if searchNumber > table.Count(searchResults) then
			searchNumber = 1
		end
		
		if table.Count(searchResults) > 0 then
			local panel = searchResults[searchNumber]
			
			Tree:SetSelectedItem(panel)
			
			for k, parent in pairs(searchResultsParents[searchNumber]) do
				parent:SetExpanded(true)
			end
		end
	end
	
	--------Examples--------
	local NodeExam = Tree:AddNode("Examples")
	NodeExam.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	table.insert(derma, {name = "Examples", panel = NodeExam, parents = {}})
	
	for name, file in pairs(EXPR_WIKI.EXAMPLES) do
		local NodeFile = NodeExam:AddNode(name)
		NodeFile.Icon:SetImage("fugue/script.png")
		NodeFile.DoClick = function()
			Golem.GetInstance():NewTab("editor", file, "Example - "..name, "Example - "..name)
		end
		
		table.insert(derma, {name = name, panel = NodeFile, parents = {NodeExam}})
	end
	
	--------Constructors--------
	local NodeCons = Tree:AddNode("Constructors")
	NodeCons.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	table.insert(derma, {name = "Constructors", panel = NodeCons, parents = {}})
	
	for lib, data in pairs(EXPR_WIKI.CONSTRUCTORS) do
		local NodeLib = NodeCons:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeCons}})
		
		for func, html in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/script-text.png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeCons, NodeLib}})
		end
	end
	
	--------Methods--------
	local NodeMeths = Tree:AddNode("Methods")
	NodeMeths.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	table.insert(derma, {name = "Methods", panel = NodeMeths, parents = {}})
	
	for lib, data in pairs(EXPR_WIKI.METHODS) do
		local NodeLib = NodeMeths:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeMeths}})
		
		for func, html in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/script-text.png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeMeths, NodeLib}})
		end
	end
	
	--------Functions--------
	local NodeFuncs = Tree:AddNode("Functions")
	NodeFuncs.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	table.insert(derma, {name = "Functions", panel = NodeFuncs, parents = {}})
	
	for lib, data in pairs(EXPR_WIKI.FUNCTIONS) do
		local NodeLib = NodeFuncs:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeFuncs}})
		
		for func, html in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/script-text.png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeFuncs, NodeLib}})
		end
	end
	
	--------Events--------
	local NodeEvents = Tree:AddNode("Events")
	NodeEvents.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	table.insert(derma, {name = "Events", panel = NodeEvents, parents = {}})
	
	for lib, data in pairs(EXPR_WIKI.EVENTS) do
		local NodeLib = NodeEvents:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeEvents}})
		
		for func, html in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/script-text.png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeEvents, NodeLib}})
		end
	end
	
	--------Operators--------
	local NodeOpers = Tree:AddNode("Operators")
	NodeOpers.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	table.insert(derma, {name = "Operators", panel = NodeOpers, parents = {}})
	
	for lib, data in pairs(EXPR_WIKI.OPERATORS) do
		local NodeLib = NodeOpers:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeOpers}})
		
		for func, html in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/script-text.png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeOpers, NodeLib}})
		end
	end
end

function PANEL:Paint(w, h) 
	surface.SetDrawColor(30, 30, 30, 255)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("GOLEM_Wiki", PANEL, "EditablePanel")
