/*============================================================================================================================================
	Name: GOLEM_Wiki
	Author: DaDamRival 
============================================================================================================================================*/
local PANEL = {}

function PANEL:Init()
	local allExpanded = false
	local oldSearch = ""
	local searchResults = {}
	local searchResultsParents = {}
	
	local derma = {}
	local folders = {}
	
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
		
		for k, folder in pairs(folders) do
			folder:SetExpanded(allExpanded)
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
			
			for k, data in pairs(derma) do
				data.panel:Show()
			end
			
			for k, folder in pairs(folders) do
				folder:Show()
				folder:SetExpanded(false)
			end
			
			if txt != "" then
				searchResults = {}
				searchResultsParents = {}
				
				for k, data in pairs(derma) do
					local name = data.name or ""
					
					if name:lower():find(txt:lower()) then
						searchResults[data.panel] = data.panel
						
						for k2, parent in pairs(data.parents) do
							if not searchResultsParents[parent] then
								searchResultsParents[parent] = parent
							end
						end
					else
						data.panel:Hide()
					end
				end
				
				for k, folder in pairs(folders) do
					if not table.HasValue(searchResultsParents, folder) then
						folder:Hide()
					else
						folder:SetExpanded(true)
					end
				end
			end
		end
	end
	--[[TextEntry.OnEnter = function(self)
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
	end]]
	
	local NodeWeb = Tree:AddNode("Syntaxes")
	NodeWeb.Icon:SetImage("fugue/globe-network.png")
	NodeWeb.DoClick = function()
		Golem.GetInstance():NewTab("html", "url:https://github.com/Rusketh/ExpAdv3/wiki", "E3 Web Wiki", 100, 100)
	end
	
	table.insert(derma, {name = name, panel = NodeWeb, parents = {}})
	
	--------Examples--------
	local NodeExam = Tree:AddNode("Examples")
	NodeExam.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	--table.insert(derma, {name = "Examples", panel = NodeExam, parents = {}})
	table.insert(folders, NodeExam)
	
	for name, data2 in pairs(EXPR_WIKI.EXAMPLES) do
		local NodeFile = NodeExam:AddNode(name)
		NodeFile.Icon:SetImage("fugue/script-text.png")
		NodeFile.DoClick = function()
			Golem.GetInstance():NewTab("editor", file, "Example - "..name, "Example - "..name)
		end
		
		table.insert(derma, {name = name, panel = NodeFile, parents = {NodeExam}})
	end
	
	--------Constructors--------
	local NodeCons = Tree:AddNode("Constructors")
	NodeCons.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	--table.insert(derma, {name = "Constructors", panel = NodeCons, parents = {}})
	table.insert(folders, NodeCons)
	
	for lib, data in pairs(EXPR_WIKI.CONSTRUCTORS) do
		local NodeLib = NodeCons:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		--table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeCons}})
		table.insert(folders, NodeLib)
		
		for func, data2 in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/state-" .. data2.state .. ".png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", data2.html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeCons, NodeLib}})
		end
	end
	
	--------Methods--------
	local NodeMeths = Tree:AddNode("Methods")
	NodeMeths.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	--table.insert(derma, {name = "Methods", panel = NodeMeths, parents = {}})
	table.insert(folders, NodeMeths)
	
	for lib, data in pairs(EXPR_WIKI.METHODS) do
		local NodeLib = NodeMeths:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		--table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeMeths}})
		table.insert(folders, NodeLib)
		
		for func, data2 in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/state-" .. data2.state .. ".png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", data2.html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeMeths, NodeLib}})
		end
	end
	
	--------Functions--------
	local NodeFuncs = Tree:AddNode("Functions")
	NodeFuncs.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	--table.insert(derma, {name = "Functions", panel = NodeFuncs, parents = {}})
	table.insert(folders, NodeFuncs)
	
	for lib, data in pairs(EXPR_WIKI.FUNCTIONS) do
		local NodeLib = NodeFuncs:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		--table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeFuncs}})
		table.insert(folders, NodeLib)
		
		for func, data2 in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/state-" .. data2.state .. ".png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", data2.html, "E3 Wiki - "..func, 100, 100)
			end
			
			table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeFuncs, NodeLib}})
		end
	end
	
	--------Events--------
	local NodeEvents = Tree:AddNode("Events")
	NodeEvents.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	--table.insert(derma, {name = "Events", panel = NodeEvents, parents = {}})
	table.insert(folders, NodeEvents)
	
	for func, data2 in pairs(EXPR_WIKI.EVENTS) do
		local NodeFunc = NodeEvents:AddNode(func)
		NodeFunc.Icon:SetImage("fugue/state-" .. data2.state .. ".png")
		NodeFunc.DoClick = function()
			Golem.GetInstance():NewTab("html", data2.html, "E3 Wiki - "..func, 100, 100)
		end
		
		table.insert(derma, {name = func, panel = NodeFunc, parents = {NodeEvents}})
	end
	
	--------Operators--------
	local NodeOpers = Tree:AddNode("Operators")
	NodeOpers.Icon:SetImage("fugue/blue-folder-horizontal.png")
	
	--table.insert(derma, {name = "Operators", panel = NodeOpers, parents = {}})
	table.insert(folders, NodeOpers)
	
	for lib, data in pairs(EXPR_WIKI.OPERATORS) do
		local NodeLib = NodeOpers:AddNode(lib)
		NodeLib.Icon:SetImage("fugue/blue-folder-horizontal.png")
		
		--table.insert(derma, {name = lib, panel = NodeLib, parents = {NodeOpers}})
		table.insert(folders, NodeLib)
		
		for func, data2 in pairs(data) do
			local NodeFunc = NodeLib:AddNode(func)
			NodeFunc.Icon:SetImage("fugue/state-" .. data2.state .. ".png")
			NodeFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", data2.html, "E3 Wiki - "..func, 100, 100)
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
