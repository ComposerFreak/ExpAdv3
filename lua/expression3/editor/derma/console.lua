local PANEL = {};

function PANEL:Init( )
	self.BaseClass.Init(self)
	self.pTextEntry.OnKeyCodeTyped = function( _, code ) end

	Golem.Syntax:Create( "console", self );
	self.tbConsoleRows = { };
end

function PANEL:WriteLine(...)

end	

--[[
function PANEL:PrintLine(...)
	local r = {};
	local l = "";
	local c = Color(255, 255, 255);
	
	for k, v in pairs({...}) do
		
		if (istable(v)) then
			c = v;
			continue;
		end
		
		l = l .. v;
		
		r[#r + 1] = {v, c};
	end
	
	self.tRows[#self.tRows + 1] = r
	
	self:SetCaret(Vector2( #self.tRows, 1 ));
	
	self:SetSelection(l .. "\n");
end

function PANEL:AddPrintOut(...)
	local r = {};
	local c = Color(255, 255, 255);
	
	for k, v in pairs({...}) do
		if (istable(v)) then
			c = v;
			r[#r + 1] = v;
			continue;
		end
		
		if (not isstring(v)) then
			v = tostring(v);
		end
		
		local lines = string.Explode("\n", v);
		
		if (#lines == 1) then
			r[#r + 1] = v;
			continue;
		end
		
		r[#r + 1] = lines[1];
		
		self:PrintLine(unpack(r));
		
		if (#lines > 2) then
			for i = 2, #lines - 1 do
				self:PrintLine(c, lines[i]);
			end
		end
		
		r = {c, lines[#lines]}
	end
	
	self:PrintLine(unpack(r));
end]]

vgui.Register( "GOLEM_Console", PANEL, "GOLEM_Editor" );