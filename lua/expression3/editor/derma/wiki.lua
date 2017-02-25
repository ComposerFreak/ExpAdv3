/*============================================================================================================================================
	Name: GOLEM_Wiki
	Author: DaDamRival 
============================================================================================================================================*/
local PANEL = {}

function PANEL:Init()
	local offset = 50
	
	local searchNumber = 1
	local oldSearch = ""
	local searchResults = {}
	
	local folding = {funcsFold = false}
	local derma = {}
	
	self:DockPadding(5, 5, 5, 5)
	
	local Scrollbar = self:Add("DScrollPanel")
	Scrollbar:Dock(FILL)
	Scrollbar:MoveToBack()
	
	local Highlight = vgui.Create("DPanel", Scrollbar)
	Highlight.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, 0, 0, Color(255, 0, 0, 0))
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
			
			Highlight.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, 0, 0, Color(255, 0, 0, 0))
			end
		end
		
		if txt != "" then
			searchResults = {}
			
			for k, data in pairs(derma) do
				local panel = data.panel
				local name = data.name or ""
				
				if name:lower():find(txt:lower()) then
					table.insert(searchResults, panel)
				end
			end
			
			if searchNumber > table.Count(searchResults) then
				searchNumber = 1
			end
			
			if table.Count(searchResults) > 0 then
				local panel = searchResults[searchNumber]
				
				Highlight:SetPos(panel:GetPos())
				Highlight:SetSize(panel:GetSize())
				Highlight.Paint = function(self, w, h)
					local w, h = panel:GetSize()
					draw.RoundedBox(0, 0, 0, w, h, Color(255, 0, 0, 100))
				end
				
				Scrollbar:ScrollToChild(panel)
			end
		end
	end
	
	local MoveSelect = self:Add("DPanel")
	MoveSelect:SetPos(5, 30)
	MoveSelect:SetSize(60, 15)
	MoveSelect.Paint = function(self, w, h)
		local ind = math.Clamp(searchNumber, 0, table.Count(searchResults))
		
		draw.RoundedBox(0, 0, 0, 60, 15, Color(50, 50, 50, 255))
		draw.DrawText(ind.."/"..table.Count(searchResults), "DermaDefault", 30, 1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
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
			
			Highlight:SetPos(panel:GetPos())
			Highlight:SetSize(panel:GetSize())
			Highlight.Paint = function(self, w, h)
				local w, h = panel:GetSize()
				draw.RoundedBox(0, 0, 0, w, h, Color(255, 0, 0, 100))
			end
			
			Scrollbar:ScrollToChild(panel)
		end
	end
	
	local MoveSelectRight = vgui.Create("DButton", MoveSelect)
	MoveSelectRight:SetPos(45, 0)
	MoveSelectRight:SetSize(15, 15)
	MoveSelectRight:SetText(">")
	MoveSelectRight.DoClick = function()
		searchNumber = searchNumber + 1
		
		if searchNumber > table.Count(searchResults) then
			searchNumber = 1
		end
		
		if table.Count(searchResults) > 0 then
			local panel = searchResults[searchNumber]
			
			Highlight:SetPos(panel:GetPos())
			Highlight:SetSize(panel:GetSize())
			Highlight.Paint = function(self, w, h)
				local w, h = panel:GetSize()
				draw.RoundedBox(0, 0, 0, w, h, Color(255, 0, 0, 100))
			end
			
			Scrollbar:ScrollToChild(panel)
		end
	end
	
	--------Constructors--------
	local ButtonCons = vgui.Create("DButton", Scrollbar)
	ButtonCons:SetPos(0, offset)
	ButtonCons:SetSize(500, 18)
	ButtonCons:SetText("")
	ButtonCons.Paint = function(self, w, h)
		draw.DrawText("Constructors", "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end
	
	table.insert(derma, {name = "Constructors", panel = ButtonCons}) 
	
	for lib, data in pairs(EXPR_WIKI.CONSTRUCTORS) do
		
		offset = offset + 20
		
		local ButtonLib = vgui.Create("DButton", Scrollbar)
		ButtonLib:SetPos(20, offset)
		ButtonLib:SetSize(500, 18)
		ButtonLib:SetText("")
		ButtonLib.Paint = function(self, w, h)
			draw.DrawText(lib, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
		end
		
		table.insert(derma, {name = lib, panel = ButtonLib}) 
		
		for func, html in pairs(data) do
			offset = offset + 20
			
			local ButtonFunc = vgui.Create("DButton", Scrollbar)
			ButtonFunc:SetPos(40, offset)
			ButtonFunc:SetSize(500, 18)
			ButtonFunc:SetText("")
			ButtonFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			ButtonFunc.Paint = function(self, w, h)
				draw.DrawText(func, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
			end
			
			table.insert(derma, {name = func, panel = ButtonFunc}) 
		end
	end
	
	offset = offset + 30
	
	--------Methods--------
	local ButtonMeths = vgui.Create("DButton", Scrollbar)
	ButtonMeths:SetPos(0, offset)
	ButtonMeths:SetSize(500, 18)
	ButtonMeths:SetText("")
	ButtonMeths.Paint = function(self, w, h)
		draw.DrawText("Methods", "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end
	
	table.insert(derma, {name = "Methods", panel = ButtonMeths}) 
	
	for lib, data in pairs(EXPR_WIKI.METHODS) do
		
		offset = offset + 20
		
		local ButtonLib = vgui.Create("DButton", Scrollbar)
		ButtonLib:SetPos(20, offset)
		ButtonLib:SetSize(500, 18)
		ButtonLib:SetText("")
		ButtonLib.Paint = function(self, w, h)
			draw.DrawText(lib, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
		end
		
		table.insert(derma, {name = lib, panel = ButtonLib}) 
		
		for func, html in pairs(data) do
			offset = offset + 20
			
			local ButtonFunc = vgui.Create("DButton", Scrollbar)
			ButtonFunc:SetPos(40, offset)
			ButtonFunc:SetSize(500, 18)
			ButtonFunc:SetText("")
			ButtonFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			ButtonFunc.Paint = function(self, w, h)
				draw.DrawText(func, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
			end
			
			table.insert(derma, {name = func, panel = ButtonFunc}) 
		end
	end
	
	offset = offset + 30
	
	--------Functions--------
	local ButtonFuncs = vgui.Create("DButton", Scrollbar)
	ButtonFuncs:SetPos(0, offset)
	ButtonFuncs:SetSize(500, 18)
	ButtonFuncs:SetText("")
	ButtonFuncs.Paint = function(self, w, h)
		draw.DrawText("Functions", "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end
	
	table.insert(derma, {name = "Functions", panel = ButtonFuncs}) 
	
	for lib, data in pairs(EXPR_WIKI.FUNCTIONS) do
		offset = offset + 20
		
		local ButtonLib = vgui.Create("DButton", Scrollbar)
		ButtonLib:SetPos(20, offset)
		ButtonLib:SetSize(500, 18)
		ButtonLib:SetText("")
		ButtonLib.Paint = function(self, w, h)
			draw.DrawText(lib, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
		end
		
		table.insert(derma, {name = lib, panel = ButtonLib}) 
		
		for func, html in pairs(data) do
			offset = offset + 20
			
			local ButtonFunc = vgui.Create("DButton", Scrollbar)
			ButtonFunc:SetPos(40, offset)
			ButtonFunc:SetSize(500, 18)
			ButtonFunc:SetText("")
			ButtonFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			ButtonFunc.Paint = function(self, w, h)
				draw.DrawText(func, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
			end
			
			table.insert(derma, {name = func, panel = ButtonFunc}) 
		end
	end
	
	offset = offset + 30
	
	--------Events--------
	local ButtonEvents = vgui.Create("DButton", Scrollbar)
	ButtonEvents:SetPos(0, offset)
	ButtonEvents:SetSize(500, 18)
	ButtonEvents:SetText("")
	ButtonEvents.Paint = function(self, w, h)
		draw.DrawText("Events", "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end
	
	table.insert(derma, {name = "Events", panel = ButtonEvents}) 
	
	for lib, data in pairs(EXPR_WIKI.EVENTS) do
		offset = offset + 20
		
		local ButtonLib = vgui.Create("DButton", Scrollbar)
		ButtonLib:SetPos(20, offset)
		ButtonLib:SetSize(500, 18)
		ButtonLib:SetText("")
		ButtonLib.Paint = function(self, w, h)
			draw.DrawText(lib, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
		end
		
		table.insert(derma, {name = lib, panel = ButtonLib}) 
		
		for func, html in pairs(data) do
			offset = offset + 20
			
			local ButtonFunc = vgui.Create("DButton", Scrollbar)
			ButtonFunc:SetPos(40, offset)
			ButtonFunc:SetSize(500, 18)
			ButtonFunc:SetText("")
			ButtonFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			ButtonFunc.Paint = function(self, w, h)
				draw.DrawText(func, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
			end
			
			table.insert(derma, {name = func, panel = ButtonFunc}) 
		end
	end
	
	offset = offset + 30
	
	--------Operators--------
	local ButtonOpers = vgui.Create("DButton", Scrollbar)
	ButtonOpers:SetPos(0, offset)
	ButtonOpers:SetSize(500, 18)
	ButtonOpers:SetText("")
	ButtonOpers.Paint = function(self, w, h)
		draw.DrawText("Operators", "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end
	
	table.insert(derma, {name = "Operators", panel = ButtonOpers}) 
	
	for lib, data in pairs(EXPR_WIKI.OPERATORS) do
		offset = offset + 20
		
		local ButtonLib = vgui.Create("DButton", Scrollbar)
		ButtonLib:SetPos(20, offset)
		ButtonLib:SetSize(500, 18)
		ButtonLib:SetText("")
		ButtonLib.Paint = function(self, w, h)
			draw.DrawText(lib, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
		end
		
		table.insert(derma, {name = lib, panel = ButtonLib}) 
		
		for func, html in pairs(data) do
			offset = offset + 20
			
			local ButtonFunc = vgui.Create("DButton", Scrollbar)
			ButtonFunc:SetPos(40, offset)
			ButtonFunc:SetSize(500, 18)
			ButtonFunc:SetText("")
			ButtonFunc.DoClick = function()
				Golem.GetInstance():NewTab("html", html, "E3 Wiki - "..func, 100, 100)
			end
			ButtonFunc.Paint = function(self, w, h)
				draw.DrawText(func, "DermaDefault", 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
			end
			
			table.insert(derma, {name = func, panel = ButtonFunc}) 
		end
	end
end

function PANEL:Paint(w, h) 
	surface.SetDrawColor(30, 30, 30, 255)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("GOLEM_Wiki", PANEL, "EditablePanel")
