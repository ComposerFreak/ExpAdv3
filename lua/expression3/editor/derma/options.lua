/*============================================================================================================================================
	Name: GOLEM_Options
	Author: DaDamRival (and Oskar)
============================================================================================================================================*/
local PANEL = {}

function PANEL:Init()
	local saveLocation = "e3-syntaxthemes.txt"
	
	local currentIndex = "variable"
	local themeSelected
	local themes = {}
	local saveName = "Enter Name"
	
	local defaultThemes = {
		["Expression 2"] = {
			["userfunction"] = Color(102, 122, 102),
			["variable"] = Color(160, 240, 160),
			["librarie"] = Color(160, 160, 240),
			["notfound"] = Color(240, 96, 96),
			["keyword"] = Color(160, 240, 240),
			["function"] = Color(160, 160, 240),
			["number"] = Color(240, 160, 160),
			["comment"] = Color(128, 128, 128),
			["directive"] = Color(240, 240, 160),
			["string"] = Color(128, 128, 128),
			["typename"] = Color(240, 160, 96),
			["operator"] = Color(224, 224, 224),
			["metamethod"] = Color(255, 0, 255), --Color(0, 200, 255),
			["prediction"] = Color(255, 0, 255) --Color(227, 181, 45)
		}
	}
	
	self:DockPadding(5,5,5,5)
	
	local mixer
	--------themes--------
	local themeMenu = self:Add("DComboBox")
	themeMenu:SetTall(20)
	themeMenu:Dock(TOP)
	themeMenu:DockMargin(0, 0, 0, 5)
	themeMenu:MoveToBack()
	function themeMenu:OnSelect(index, value, data)
		for type, color in pairs(themes[value]) do
			themeSelected = value
			
			RunConsoleCommand("golem_editor_color_" .. type, color.r .. "_" .. color.g .. "_" .. color.b)
			Golem.Syntaxer:UpdateSyntaxColors()
			
			if type == currentIndex then
				mixer:SetColor(color)
			end
		end
	end
	
	if file.Exists(saveLocation, "DATA") then
		themes = util.JSONToTable(file.Read(saveLocation))
		themes = util.JSONToTable(file.Read(saveLocation))
		
		for name, data in pairs(themes) do
			themeMenu:AddChoice(name, name)
		end
	else
		local tbl = {}
		
		for k, v in pairs(Golem.Syntaxer.ColorConvars) do
			local r, g, b = string.match(v:GetString(), "(%d+)_(%d+)_(%d+)")
			
			tbl[k] = Color(r, g, b)
		end
		
		themes["Expression 3"] = tbl
		
		for k, v in pairs(defaultThemes) do
			themes[k] = v
		end
		
		for name, data in pairs(themes) do
			themeMenu:AddChoice(name, name)
		end
		
		file.Write(saveLocation, util.TableToJSON(themes, true))
	end
	
	--------Color stuff--------
	local syntaxColor = self:Add("DComboBox")
	syntaxColor:SetTall(20)
	syntaxColor:Dock(TOP)
	syntaxColor:DockMargin(0, 0, 0, 5)
	for k, v in pairs(Golem.Syntaxer.ColorConvars) do
		syntaxColor:AddChoice(k, v, k == "variable")
	end
	function syntaxColor:OnSelect(index, value, data)
		local r, g, b = string.match(data:GetString(), "(%d+)_(%d+)_(%d+)")
		currentIndex = value
		mixer:SetColor(Color(r, g, b))
	end
	
	mixer = self:Add("DColorMixer")
	mixer:Dock(TOP)
	mixer:SetTall(150)
	mixer:SetPalette(false)
	mixer:SetAlphaBar(false)
	function mixer:ValueChanged(color)
		if themeSelected then
			themes[themeSelected][currentIndex] = color
		end
		
		RunConsoleCommand("golem_editor_color_" .. currentIndex, color.r .. "_" .. color.g .. "_" .. color.b)
		Golem.Syntaxer:UpdateSyntaxColors()
	end
	
	local reset = vgui.Create("DButton")
	reset:SetText("Reset color")
	function reset:DoClick()
		local found = false
		
		for k, v in pairs(defaultThemes) do
			if k == themeSelected then
				found = true
				
				break
			end
		end
		
		if not found then
			RunConsoleCommand("golem_editor_resetcolors", currentIndex)
			
			timer.Simple(0, function()
				local r, g, b = string.match(Golem.Syntaxer.ColorConvars[currentIndex]:GetString(), "(%d+)_(%d+)_(%d+)")
				mixer:SetColor(Color(r, g, b))
				
				themes[themeSelected][currentIndex] = Color(r, g, b)
			end)
		else
			local color = defaultThemes[themeSelected][currentIndex]
			
			RunConsoleCommand("golem_editor_color_" .. currentIndex, color.r .. "_" .. color.g .. "_" .. color.b)
			Golem.Syntaxer:UpdateSyntaxColors()
			
			mixer:SetColor(color)
			
			themes[themeSelected][currentIndex] = color
		end
	end
	
	local resetall = vgui.Create("DButton")
	resetall:SetText("Reset all colors")
	function resetall:DoClick()
		local found = false
		
		for k, v in pairs(defaultThemes) do
			if k == themeSelected then
				found = true
				print(k .. "sdsad")
				break
			end
		end
		
		if not found then
			RunConsoleCommand("golem_editor_resetcolors", "1")
			
			timer.Simple(0, function()
				local r, g, b = string.match(Golem.Syntaxer.ColorConvars[currentIndex]:GetString(), "(%d+)_(%d+)_(%d+)")
				mixer:SetColor(Color(r, g, b)) 
				
				for type, color in pairs(defaultThemes[table.GetKeys(defaultThemes)[1]]) do
					local r, g, b = string.match(Golem.Syntaxer.ColorConvars[type]:GetString(), "(%d+)_(%d+)_(%d+)")
					
					themes[themeSelected][type] = Color(r, g, b)
				end
			end)
		else
			themes[themeSelected] = defaultThemes[themeSelected]
			
			for type, color in pairs(defaultThemes[themeSelected]) do
				RunConsoleCommand("golem_editor_color_" .. type, color.r .. "_" .. color.g .. "_" .. color.b)
				Golem.Syntaxer:UpdateSyntaxColors()
				
				if type == currentIndex then
					mixer:SetColor(color)
				end
			end
		end
	end
	
	local resetDivider = self:Add("DHorizontalDivider")
	self.ResetDivider = resetDivider
	resetDivider:Dock(TOP)
	resetDivider:DockMargin(0, 5, 0, 0)
	resetDivider:SetLeft(reset)
	resetDivider:SetRight(resetall)
	resetDivider:SetLeftWidth(120)
	resetDivider.StartGrab = function() end
	resetDivider.m_DragBar:SetCursor("")
	
	local saveButton = vgui.Create("DButton")
	saveButton:SetText("Save Current")
	function saveButton:DoClick()
		file.Write(saveLocation, util.TableToJSON(themes, true))
	end
	
	local deleteButton = self:Add("DButton")
	deleteButton:SetText("Delete Current")
	function deleteButton:DoClick()
		local defPref = false
		
		for k, v in pairs(defaultThemes) do
			if k == themeSelected then
				defPref = true
				
				break
			end
		end
		
		if themeSelected and (not defPref or themeSelected == "Expression 3") then
			themes[themeSelected] = nil
			themeMenu:Clear()
			
			for k, v in pairs(themes) do
				themeMenu:AddChoice(k, k)
			end
			
			file.Write(saveLocation, util.TableToJSON(themes, true))
			
			for type, color in pairs(themes["Expression 3"]) do
				RunConsoleCommand("golem_editor_color_" .. type, color.r .. "_" .. color.g .. "_" .. color.b)
				Golem.Syntaxer:UpdateSyntaxColors()
				
				if type == "variable" then
					mixer:SetColor(color)
				end
			end
		end
	end
	
	local saveDivider = self:Add("DHorizontalDivider")
	self.SaveDivider = saveDivider
	saveDivider:Dock(TOP)
	saveDivider:DockMargin(0, 5, 0, 0)
	saveDivider:SetLeft(saveButton)
	saveDivider:SetRight(deleteButton)
	saveDivider:SetLeftWidth(120)
	saveDivider.StartGrab = function() end
	saveDivider.m_DragBar:SetCursor("")
	
	-----------------
	local newText = self:Add("DTextEntry")
	newText:SetText("Enter name")
	
	local newButton = vgui.Create("DButton")
	newButton:SetText("Add new theme")
	function newButton:DoClick()
		if not themes[newText:GetValue()] then
			local tbl = {}
			
			for k, v in pairs(Golem.Syntaxer.ColorConvars) do
				local r, g, b = string.match(v:GetString(), "(%d+)_(%d+)_(%d+)")
				
				tbl[k] = Color(r, g, b)
			end
			
			themes[newText:GetValue()] = tbl
			
			themeMenu:AddChoice(newText:GetValue(), newText:GetValue(), true)
			
			file.Write(saveLocation, util.TableToJSON(themes, true))
		end
	end
	
	local newDivider = self:Add("DHorizontalDivider")
	self.NewDivider = newDivider
	newDivider:Dock(TOP)
	newDivider:DockMargin(0, 5, 0, 30)
	newDivider:SetLeft(newText)
	newDivider:SetRight(newButton)
	newDivider:SetLeftWidth(160)
	newDivider.StartGrab = function() end
	newDivider.m_DragBar:SetCursor("")
	
	--------Font stuff--------
	local editorFont = self:Add("DComboBox")
	editorFont:SetValue(GetConVarString("golem_font_name"))
	editorFont:AddChoice("Consolas")
	editorFont:AddChoice("Courier New")
	editorFont:AddChoice("DejaVu Sans Mono")
	editorFont:AddChoice("Lucida Console")
	if system.IsOSX() then
		editorFont:AddChoice("Monaco", "", false)
	end
	function editorFont:OnSelect(index, value, data)
		Golem.Font:SetFont(value)
	end
	
	--------
	local editorFontSize = self:Add("DComboBox")
	editorFontSize:SetValue( GetConVarNumber("golem_font_size"))
	for i = 10, 30 do
		editorFontSize:AddChoice(i)
	end
	function editorFontSize:OnSelect(index, value, data)
		-- Golem.Font:SetFont( value ) 
		Golem.Font:ChangeFontSize(value, true)
	end
	
	--------
	local fontDivider = self:Add("DHorizontalDivider")
	self.FontDivider = fontDivider
	fontDivider:Dock(TOP)
	fontDivider:DockMargin(0, 5, 0, 0)
	fontDivider:SetLeft(editorFont)
	fontDivider:SetRight(editorFontSize)
	fontDivider:SetLeftWidth(200)
	fontDivider.StartGrab = function() end
	fontDivider.m_DragBar:SetCursor("")
	
	--------
	local resetfont = self:Add("DButton")
	resetfont:SetText("Reset font to default")
	resetfont:Dock(TOP)
	resetfont:DockMargin(0, 5, 0, 0)
	function resetfont:DoClick()
		Golem.Font:SetFont("Courier New", 16)
		editorFont:SetValue("Courier New")
		editorFontSize:SetValue(16)
	end
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(30, 30, 30, 255)
	surface.DrawRect(0, 0, w, h) 
end 

function PANEL:PerformLayout()
	self.ResetDivider:SetLeftWidth(120)
	self.FontDivider:SetLeftWidth(200)
	self.SaveDivider:SetLeftWidth(120)
	self.NewDivider:SetLeftWidth(160)
end

vgui.Register("GOLEM_Options", PANEL, "EditablePanel")
