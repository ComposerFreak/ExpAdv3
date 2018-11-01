/*============================================================================================================================================
	Name: GOLEM_Search
	Author: Rusketh (The whole point of this, is to make Oskar hate it so he replaces it!)
	Based on Sublime Text 3, because its the best Text Editor (Disagree? Your wrong!).
============================================================================================================================================*/

--[[
	Check Box
]]

local CHECK = {};

local tick = Material("fugue\\tick.png");
local cross = Material("fugue\\cross-button.png");

function CHECK:Init()
	self.bChecked = false;
	self:SetTick(tick);
	self:SetCross(cross);
	self:SetMaterial( self.cross );
end

function CHECK:SetTick(tick)
	self.tick = tick;
	if (bChecked) then self:SetMaterial(tick); end
end

function CHECK:SetCross(cross)
	self.cross = cross;
	if (not bChecked) then self:SetMaterial(cross); end
end


function CHECK:DoClick()
	self.bChecked = not self.bChecked;
	self:SetMaterial( self.bChecked and self.tick or self.cross );
	self:ChangedValue(self.bChecked);
end

function CHECK:getValue()
	return self.bChecked;
end

function CHECK:ChangedValue(bChecked)

end

vgui.Register("GOLEM_CheckBox", CHECK, "GOLEM_ImageButton");

--[[
	Check Box but with a label.
]]

local CHECKLABEL = {};

function CHECKLABEL:Init()
	self.button = self:Add("GOLEM_CheckBox");
	self.button:SetSize(22, 22);
	self.button:Dock(LEFT);

	self.label = self:Add("DLabel");
	self.label:SetHeight(22);
	self.label:Dock(FILL);

	function self.button.ChangedValue(this, bChecked)
		self:ChangedValue(bChecked);
	end
	
end

function CHECKLABEL:SetText(text)
	self.label:SetText(text);
	self.label:SizeToContentsX();
	self:PerformLayout();
end

function CHECKLABEL:SetTick(tick)
	self.button:SetTick(tick);
end

function CHECKLABEL:SetCross(cross)
	self.button:SetCross(cross);
end

function CHECKLABEL:Paint()
	
end

function CHECKLABEL:GetValue()
	return self.button:GetValue();
end

function CHECKLABEL:ChangedValue(bChecked)

end

vgui.Register("GOLEM_CheckBoxLabel", CHECKLABEL, "DPanel");

--[[
	Search Box
]]

local SEARCH = {};

function SEARCH:Init()
	self.bWholeWord = false;
	self.bMatchCase = false;
	self.bAllowRegex = false;
	self.bWrapAround = false;

	self:SetSize(300, 50);

	self.query_text = self:Add("DTextEntry");
	self.query_text:SetDrawBackground(false);

	self.replace_text = self:Add("DTextEntry");
	self.replace_text:SetDrawBackground(false);
	self.find_prev = self:Add("GOLEM_ImageButton");
	self.find_prev:SetMaterial( Material("fugue\\arrow-090.png") );

	self.find_next = self:Add("GOLEM_ImageButton");
	self.find_next:SetMaterial( Material("fugue\\arrow-270.png") );

	self.find_all = self:Add("GOLEM_ImageButton");
	self.find_all:SetMaterial( Material("fugue\\arrow-retweet.png") );

	self.replace_check = self:Add("GOLEM_CheckBox");
	self.replace_check:SetCross(Material("fugue\\quill.png"));
	self.replace_check:SetTick(Material("fugue\\binocular.png"));

	function self.replace_check.ChangedValue(this, bChecked)
		if (bChecked) then self:ShowReplace(); else self:HideReplace(); end
	end

	self:HideReplace();
end

function SEARCH:PerformLayout( )
	local w, h = self:GetSize();

	self.find_prev:SetPos(w - 44, 1);
	self.find_prev:SetSize(22, 22);

	self.find_next:SetPos(w - 22, 1);
	self.find_next:SetSize(22, 22);

	self.find_all:SetPos(w - 44, 24);
	self.find_all:SetSize(22, 22);

	self.query_text:SetPos(1, 1);
	self.query_text:SetSize(w - 48, 24);

	self.replace_text:SetPos(1, 25);
	self.replace_text:SetSize(w - 48, 24);

	self.replace_check:SetPos(w - 22, 24);
	self.replace_check:SetSize(22, 22);

	if (self.bOpen) then self:Open(true); else self:Close(true); end
end

function SEARCH:Open(noanim)
	local pw, ph = self:GetParent():GetSize();
	local w, h = self:GetSize();
	local x = pw - w - 20;
	local y = 10;
	if (noanim) then self:SetPos(x, y);
	else self:MoveTo(x, y, 0.2, 0.2); end
	self.options:MoveTo(pw - self.options:GetWide() - 30, ph - h - 20, 0.2, 0.2);
	self.bOpen = true;
end

function SEARCH:Close(noanim)
	local pw, ph = self:GetParent():GetSize();
	local w, h = self:GetSize();
	local x = pw - w - 20;
	local y = -h - 10;
	if (noanim) then self:SetPos(x, y);
	else self:MoveTo(x, y, 0.2, 0.2); end
	self.options:MoveTo(pw - self.options:GetWide() - 30, ph + 10, 0.2, 0.2);
	self.bOpen = false;
end

function SEARCH:Toggle()
	if ( self.bOpen ) then self:Close(); else self:Open(); end
end

function SEARCH:GetOptions(parent)
	self.options = vgui.Create("GOLEM_SearchOptions", parent);
	return self.options;
end

function SEARCH:ShowReplace()
	self.replace_text:SetEnabled(true);
	self.replace_text:SetVisible(true);

	self.find_all:SetEnabled(true);
	self.find_all:SetVisible(true);

	self.bReplace = true;
end

function SEARCH:HideReplace()
	self.replace_text:SetEnabled(false);
	self.replace_text:SetVisible(false);

	self.find_all:SetEnabled(false);
	self.find_all:SetVisible(false);

	self.bReplace = false;
end

function SEARCH:Paint()
	local w, h = self:GetSize();

	draw.RoundedBox( 6, 0, 0, w, 24, Color( 100, 100, 100, 255 ) );
	draw.RoundedBox( 6, w - 24, 0, 24, h, Color( 100, 100, 100, 255 ) );

	draw.RoundedBox( 6, 2, 4, w - 46, 18, Color( 100, 150, 150, 255 ) );

	if (self.bReplace) then
		draw.RoundedBox( 6, 2, 26, w - 46, 18, Color( 100, 150, 150, 255 ) );
	end
end

vgui.Register("GOLEM_SearchBox", SEARCH, "DPanel");

--[[
	Options Menu
]]


local OPTIONS = {};

function OPTIONS:Init()
	self:DockPadding(5, 5, 5, 5);

	self.allowRegex = self:Add("GOLEM_CheckBox");
	self.allowRegex:SetCross(Material("fugue\\regular-expression-search-match.png"));
	self.allowRegex:SetTick(Material("fugue\\regular-expression.png"));
	self.allowRegex:Dock(LEFT);

	self.matchCase = self:Add("GOLEM_CheckBox");
	self.matchCase:SetCross(Material("fugue\\edit-superscript.png"));
	self.matchCase:SetTick(Material("fugue\\edit-lowercase.png"));
	self.matchCase:Dock(LEFT);
--
	self.wholeWord = self:Add("GOLEM_CheckBox");
	self.wholeWord:SetCross(Material("fugue\\selection-select-input.png"));
	self.wholeWord:SetTick(Material("fugue\\selection-select.png"));
	self.wholeWord:Dock(LEFT);

	self.inSelection = self:Add("GOLEM_CheckBox");
	self.inSelection:SetCross(Material("fugue\\selection-input.png"));
	self.inSelection:SetTick(Material("fugue\\selection.png"));
	self.inSelection:Dock(LEFT);
--
	self.wrapWround = self:Add("GOLEM_CheckBox");
	self.wrapWround:SetCross(Material("fugue\\arrow-circle.png"));
	self.wrapWround:SetTick(Material("fugue\\arrow-return-000-left.png"))
	self.wrapWround:Dock(LEFT);
end

function OPTIONS:getQuery( )
	return self.search_box:GetValue();
end

function OPTIONS:getReplace( )
	return self.replace_box:GetValue();
end

function OPTIONS:PerformLayout(w, h)
	local pw, ph = self:GetParent():GetSize();
	self:SetPos(pw - w - 30, ph - h - 40);
end

function OPTIONS:Paint()
	local w, h = self:GetSize();

	draw.RoundedBox( 6, 0, 0, w, h, Color( 100, 100, 100, 255 ) );
end


vgui.Register("GOLEM_SearchOptions", OPTIONS, "EditablePanel");

--[[
function OPTIONS:Search( query, replace, all )
	local editor = Golem.GetInstance();

	local start = editor.Start;
	local finish = Vector2( #editor.Rows, #editor.Rows[ #editor.Rows ] );

	if ( bInSelection ) then
		finish = editor.Carret;
	end

	local origonal = editor:GetCode();

	if ( !bCaseSensative ) then
		query = string.lower(query);
		origonal = string.lower(origonal);
	end

	local results = { };

	local s, f = string.find(origonal, query, 1, !bAllowRegex);

	if ( (not s) or (not f) ) then
		return false, results;
	end

	local offset = 2;

	while s and f do
		s, f = string.find(origonal, query, offset, !bAllowRegex );

		if (bWholeWord) then

		end
	end
	
	return results;
end

--[[
--COPIED from my previous EA2 work
local Offset = 2
		for Loop = 1, 100 do
			local Start, Stop = Text:find( Query, Offset, !self.AllowRegex:GetBool( ) )
			
			if Start and Stop then
				
				if self.WholeWordOnly:GetBool( ) then

					local NewStart = Editor:MovePosition( Editor.Start, Start )
					NewStart = Vector2( NewStart.x, NewStart.y - 1 )
								
					local NewStop = Editor:MovePosition( Editor.Start, Stop )
					NewStop = Vector2( NewStop.x, NewStop.y - 1 )
					
					local WordStart = Editor:wordStart( Vector2( NewStart.x, NewStart.y + 1 ) )
					local WordEnd = Editor:wordEnd( Vector2( NewStart.x, NewStart.y + 1 ) )
							
					if NewStart == WordStart and WordEnd == ( NewStop + Vector2( 0, 1 ) ) then
						Editor:HighlightFoundWord( nil, NewStart, NewStop )
						return true
					else
						Offset = Start + 1
					end
				else
					Editor:HighlightFoundWord( nil, Start - 1, Stop - 1 )
					return true
				end
			
			else
				break
			end
		end
		
		if self.Wrap:GetBool( ) and !self.CaseSensative:GetBool( ) then
			Editor:SetCaret( Vector2( 1, 1 ) )
			return self:DoFind( Query, Up, Looped + 1 )
		end
				
	else
		--Up:
		
		if !self.InSelection:GetBool( ) then
			End = Start
			Start = Vector2( 1, 1 )
		end
		
		
		local Text = self:GetArea( Start, End )
		
		if !self.CaseSensative:GetBool( ) then
			Text = Text:lower( )
		end
		
		local Found
		
		local Offset = 2
		for Loop = 1, 100 do
			local Start, Stop = Text:find( Query, Offset, !self.AllowRegex:GetBool( ) )
			
			if Start and Stop then
				
				if self.WholeWordOnly then
					local NewStart = Editor:MovePosition( Vector2( 1, 1 ), Start )
					NewStart = Vector2( NewStart.x, NewStart.y - 1 )
								
					local NewStop = Editor:MovePosition( Vector2( 1, 1 ), Stop )
					NewStop = Vector2( NewStop.x, NewStop.y - 1 )
					
					local WordStart = Editor:wordStart( Vector2( NewStart.x, NewStart.y + 1 ) )
					local WordEnd = Editor:wordEnd( Vector2( NewStart.x, NewStart.y + 1 ) )
							
					if NewStart == WordStart and WordEnd == ( NewStop + Vector2( 0, 1 ) ) then
						Found = { NewStart, NewStop }
						
						if NewStop.x == Editor.Start.x and NewStop.y >= Editor.Start.y then
							break
						elseif NewStop.x > Editor.Start.x then
							break
						end
					else
						Offset = Start + 1
					end
				else
					Found = { Start - 1, Stop - 1 }
					
					local NewStop = Editor:MovePosition( Vector2( 1, 1 ), Stop )
					
					if NewStop.x == Editor.Start.x and NewStop.y >= Editor.Start.y then
						break
					elseif NewStop.x > Editor.Start.x then
						break
					end
				end
				
				Offset = Start + 1
				
			else
				break
			end
		end
		
		if Found then
			Editor:HighlightFoundWord( Vector2( 1, 1 ), Found[1], Found[2] )
			return true
		end
		
		if self.Wrap:GetBool( ) and !self.CaseSensative:GetBool( ) then
			Editor:SetCaret( CaretMax )
			return self:DoFind( Query, Up, Looped + 1 )
		end
		
	end
	
]]