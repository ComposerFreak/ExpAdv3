/*============================================================================================================================================
	Name: GOLEM_Search
	Author: Rusketh (The whole point of this, is to make Oskar hate it so he replaces it!)
	Based on Sublime Text 3, because its the best Text Editor (Disagree? Your wrong!).
============================================================================================================================================*/

--[[
	Search Box
]]

local SEARCH = {};

function SEARCH:Init()

	self.bWholeWord = false;
	self.bMatchCase = false;
	self.bAllowRegex = false;
	self.bWrapAround = false;

	self:SetZPos(999);
	self:SetSize(300, 50);

	self.query_text = self:Add("DTextEntry");
	self.query_text:SetPaintBackground(false);

	self.replace_text = self:Add("DTextEntry");
	self.replace_text:SetPaintBackground(false);

	self.find_prev = self:Add("GOLEM_ImageButton");
	self.find_prev:SetMaterial( Material("fugue\\arrow-090.png") );
	self.find_prev:SetTooltip("Find previous.");

	self.find_next = self:Add("GOLEM_ImageButton");
	self.find_next:SetMaterial( Material("fugue\\arrow-270.png") );
	self.find_next:SetTooltip("Find next.");

	self.find_all = self:Add("GOLEM_ImageButton");
	self.find_all:SetMaterial( Material("fugue\\arrow-retweet.png") );
	self.find_all:SetTooltip("Replace all.");

	self.replace_check = self:Add("GOLEM_CheckBox");
	self.replace_check:SetCross(Material("fugue\\binocular.png"));
	self.replace_check:SetTick(Material("fugue\\quill.png"));
	self.replace_check:SetTooltip("Toggle Find and Replace");

	function self.replace_check.ChangedValue(this, bChecked)
		if (bChecked) then self:ShowReplace(); else self:HideReplace(); end
	end

	function self.find_next.DoClick(this)
		self:FindNext();
	end

	function self.find_prev.DoClick(this)
		self:FindPrev();
	end

	function self.query_text.OnEnter(this)
		self:FindNext();
	end

	function self.find_all.DoClick(this)
		self:FindAll();
	end

	self:HideReplace();
end

function SEARCH:SetEditor(ide)
	self.pEditor = ide;
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

	if (self.btnOptions) then
		for i = 1, 5 do
			local btn = self.btnOptions[i];
			btn:SetEnabled(true);
			btn:SetVisible(true);
		end
	end

	self.pEditor.tbRight:InvalidateLayout(false);

	self.query_text:RequestFocus();

	self.bOpen = true;
end

function SEARCH:Close(noanim)
	local pw, ph = self:GetParent():GetSize();
	local w, h = self:GetSize();
	local x = pw - w - 20;
	local y = -h - 10;

	if (noanim) then self:SetPos(x, y);
	else self:MoveTo(x, y, 0.2, 0.2); end

	if (self.btnOptions) then
		for i = 1, 5 do
			local btn = self.btnOptions[i];
			btn:SetEnabled(false);
			btn:SetVisible(false);
		end
	end

	self.pEditor.tbRight:InvalidateLayout(false);

	self.bOpen = false;
end

function SEARCH:Toggle()
	if ( self.bOpen ) then self:Close(); else self:Open(); end
end

function SEARCH:SetOptions(options)
	self.btnOptions = options;
end

function SEARCH:ShowReplace()
	self.replace_text:SetEnabled(true);
	self.replace_text:SetVisible(true);

	self.find_all:SetEnabled(true);
	self.find_all:SetVisible(true);

	self.replace_check:SetValue(true, true);

	self.bReplace = true;
end

function SEARCH:HideReplace()
	self.replace_text:SetEnabled(false);
	self.replace_text:SetVisible(false);

	self.find_all:SetEnabled(false);
	self.find_all:SetVisible(false);

	self.replace_check:SetValue(false, true);

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

function SEARCH:GetIDE( )
	local pTab = self.pEditor.pnlTabHolder:GetActiveTab( )

	if not pTab then return end

	if not IsValid( pTab ) or not ispanel( pTab ) then return end

	if pTab.__type ~= "editor" then return end

	return pTab:GetPanel( );
end

function SEARCH:GetCode()
	local ide = self:GetIDE()

	if (not ide) then return; end

	local code = ide:GetCode();

	local bMatchCase = self.pEditor.searchOpCase:GetValue();

	if (bMatchCase) then
		code = string.lower(code);
	end

	return code;
end

function SEARCH:GetQuery()
	local query = self.query_text:GetValue();
	local bMatchCase = self.pEditor.searchOpCase:GetValue();
	local bAllowRegex = self.pEditor.searchOptRegex:GetValue();

	if (bMatchCase) then
		query = string.lower(query);
	end

	if (not bAllowRegex) then
		query = string.gsub(query, "[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1");
	end

	return query;
end

function SEARCH:SetQuery(text)
	self.query_text:SetValue(text or "");
end

function SEARCH:GetReplacement()
	return self.replace_text:GetValue();
end

function SEARCH:CaretToPos(ide, caret)
	local tRows = ide.tRows;

	local pos = 0;

	for l = 1, caret.x - 1 do
		pos = pos + #tRows[l] + 1;
	end

	local len = #tRows[caret.x];

	if caret.y >= len then
		pos = pos + caret.y;
	else
		pos = pos + len;
	end

	return pos;
end

function SEARCH:PosToCaret(ide, pos)
	local tRows = ide.tRows;

	local cur = 0;

	for l = 1, #tRows do
		local len = #tRows[l];

		if (cur + len < pos) then
			cur = cur + len + 1;
		else
			return Vector2(l, pos - cur);
		end
	end

	return Vector2(0, 0);
end

function SEARCH:FindResults(maxResults)
	local ide = self:GetIDE();

	if (not ide) then
		return;
	end

	local code = self:GetCode();
	local query = self:GetQuery();

	local bInSelection = self.pEditor.searchOptSelection:GetValue();
	local bAllowRegex = self.pEditor.searchOptRegex:GetValue();
	local bMatchWhole = self.pEditor.searchOptWhole:GetValue();
	local bWrapAround = self.pEditor.searchOptWrap:GetValue();

	local startPos = ide.Start;
	local endPos = Vector2(#ide.tRows, #ide.tRows[#ide.tRows]);

	if (bInSelection) then
		endPos = ide.Caret;
	end

	local caretPos = self:CaretToPos(ide, startPos);
	local offset = caretPos;
	local maxoffset = self:CaretToPos(ide, endPos);

	local tempStart, tempStop = string.find(code, query, 1, not bAllowRegex);

	if (not tempStart or not tempStop) then
		return;
	end

	local results = {};

	for i = 1, 500 do --TODO: Maybe make this while true?
		if (offset >= maxoffset) then
			break;
		end

		local start, stop = string.find(code, query, offset, not bAllowRegex);

		if (not start or not stop) then
			if (bWrapAround and not bInSelection) then
				bWrapAround = false;
				maxoffset = caretPos;
				offset = 0;
				continue;
			else
				break;
			end
		end

		stop = stop + 1;

		local newStart = self:PosToCaret(ide, start);
		local newStop = self:PosToCaret(ide, stop);

		if (bMatchWhole) then

			local wordStart = ide:wordStart(newStart);
			local wordStop = ide:wordEnd(newStop);

			if (wordStart == newStart and wordStop == newStop) then
				results[#results + 1] = { newStart, newStop, string.sub(code, start, stop) };
			end

			offset = start + 1;
		else
			results[#results + 1] = { newStart, newStop, string.sub(code, start, stop - 1) };
			offset = start + 1;
		end

		if (maxResults and #results >= maxResults) then
			break;
		end
	end

	if (#results > 0) then
		return results;
	end
end

function SEARCH:FindNext()
	local results = self:FindResults(10);

	if (not results) then
		Golem.Print({image = "fugue\\binocular.png", size = 16}, Color(100, 100, 100), "Search returned no results!");
	else
		self:DoFindReplace(results[1]);
	end
end

function SEARCH:FindPrev()
	local results = self:FindResults();

	if (not results) then
		Golem.Print({image = "fugue\\binocular.png", size = 16}, Color(100, 100, 100), "Search returned no results!");
	else
		self:DoFindReplace(results[#results]);
	end
end

function SEARCH:DoFindReplace(result, noPrint)
	local ide = self:GetIDE();

	if (self.bReplace) then
		local with = self:GetReplacement();

		ide:SetArea( { ide:MakeSelection({ result[1], result[2] }) }, with);

		if (not noPrint) then
			Golem.Print({image = "fugue\\binocular.png", size = 16}, Color(100, 100, 100), "Replaced ", Color(50, 100, 50), result[3], Color(100, 100, 100), " at line ", result[1].x, " char ", result[1].y, ".");
		end
	else
		if (not noPrint) then
			Golem.Print({image = "fugue\\quill.png", size = 16}, Color(100, 100, 100), "Found ", Color(50, 100, 50), result[3], Color(100, 100, 100), " at line ", result[1].x, " char ", result[1].y, ".");
		end
	end

	ide:SetCaret(result[1]);
	ide:ScrollCaret();
	ide:RequestFocus();
end

function SEARCH:FindAll()
	local results = self:FindResults();

	if (not results) then
		Golem.Print({image = "fugue\\binocular.png", size = 16}, Color(100, 100, 100), "Search returned no results!");
	else
		Golem.Print({image = "fugue\\binocular.png", size = 16}, Color(100, 100, 100), "Search returned ", #results, " results!");

		for i = 1, #results do
			self:DoFindReplace(results[i], true);
		end

		if (self.bReplace) then
			Golem.Print({image = "fugue\\quill.png", size = 16}, Color(100, 100, 100), "Replaced ", Color(50, 100, 50), #results, Color(100, 100, 100), " results.");
		else
			--This wont happen as the button only exists when replacing D:
			Golem.Print({image = "fugue\\binocular.png", size = 16}, Color(100, 100, 100), "Found ", Color(50, 100, 50), #results, Color(100, 100, 100), " results.");
		end
	end

	--TODO: Oskar make this function do more then just print in to the console.
end



vgui.Register("GOLEM_SearchBox", SEARCH, "DPanel");
