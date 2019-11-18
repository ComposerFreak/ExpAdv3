/*============================================================================================================================================
	Name: GOLEM_StateBox
	Author: Rusketh
============================================================================================================================================*/
local STATE = {}

function STATE:Init()
	self.lk = {};
	self.states = {};
	self.m_nState = 0;
end

function STATE:GetValue()
	return self.m_oValue;
end

function STATE:SetValue(v, noOnChnaged)
	for i = 1, #self.states do
		local state = self.states[i];

		if state.v == v then 
			self.m_oValue = v;
			return self:SetState(i, noOnChnaged);
		end
	end
end

function STATE:SetState(sName, noOnChnaged)
	local i = self.lk[sName];
	
	if isnumber(sName) then i = sName; end

	if i then
		self.m_nState = i;

		local state = self.states[i];

		if state then
			
			if state.i then self:SetMaterial(state.i); end
			if state.c then self:SetColor(state.c); end
			if state.t then self:SetText(state.t); end
			
			if self.m_oValue ~= state.v then

				self.m_oValue = state.v;

				if not noOnChnaged then
					self:ChangedValue(state.v, state);
				end
			end
		end
	end
end

function STATE:AddState(sName, sValue, sIcon, sText, cCol)
	local id = #self.states + 1;

	if sIcon and isstring(sIcon) then sIcon = Material(sIcon); end

	self.states[id] = {id = id, n = sName, v = sValue, i = sIcon, c = cCol, t = sText};

	self.lk[sName] = id;

	return id;
end

function STATE:UpdateState(sName, sValue, sIcon, sText, cCol)
	local i = self.lk[sName];
	
	if i then
		local state = self.states[i];

		if state then
			if sIcon and isstring(sIcon) then sIcon = Material(sIcon); end

			state.n = sName or state.n;
			state.v = sValue or state.v;
			state.i = sIcon or state.i;
			state.c = cCol or state.c;
			state.t = sText or state.t;
		end
	end
end

function STATE:RemoveState(sName)
	local i = self.lk[sName];

	if i then
		table.remove(self.states, i);

		self:UpdateLK();
	end
end

function STATE:UpdateLK()
	self.lk = {};

	for i = 1, #self.states do
		local state = self.states[i];

		state.id = i;

		self.lk[state.n] = i;
	end
end

function STATE:ToggleForwards()
	local c = #self.states;
	local i = self.m_nState + 1;

	if i > c then i = 1; end

	self:SetState(i);
end

function STATE:ToggleBackwards()
	local c = #self.states;
	local i = self.m_nState - 1;

	if i <= 0 then i = c; end
	
	self:SetState(i);
end

function STATE:DoClick()
	self:ToggleForwards();
end

function STATE:DoRightClick()
	self:ToggleBackwards();
end

function STATE:ChangedValue(value)
end

function STATE:PollFromCallback(f)
	self.m_fPollFunc = f;
end

function STATE:Think()
	if self.m_fPollFunc then
		local tme = CurTime();
		if not self.m_nNxtPol or self.m_nNxtPol <= tme then
			self:SetValue(self:m_fPollFunc());
			self.m_nNxtPol = tme + 1;
		end
	end
end

vgui.Register("GOLEM_StateBox", STATE, "GOLEM_ImageButton");

/*============================================================================================================================================
	Name: GOLEM_CheckBox and GOLEM_CheckBoxLabel
	Author: Rusketh (The whole point of this, is to make Oskar hate it so he replaces it!)
	Based on Sublime Text 3, because its the best Text Editor (Disagree? Your wrong!).
============================================================================================================================================*/

--[[
	Check Box
]]

local CHECK = {};

function CHECK:Init()
	self:AddState("tick", true, "fugue/tick.png", nil, Color(100, 100, 100));
	self:AddState("cross", true, "fugue/cross-button.png", nil, Color(100, 100, 100));
	self:SetValue(false, true);
end

function CHECK:SetTick(icon, col, val, text)
	self:UpdateState("tick", val, icon, text, col);
end

function CHECK:SetCross(cross, col, val, text)
	self:UpdateState("cross", val, icon, text, col);
end

function CHECK:SetStatic(image)
	self:SetTick(image, Color(0, 255, 0));
	self:SetCross(image, Color(255, 0, 0));
end

vgui.Register("GOLEM_CheckBox", CHECK, "GOLEM_StateBox");

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
