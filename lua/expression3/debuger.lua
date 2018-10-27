--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Debugger::
]]

local COLORS = {};
COLORS.KEYWORD = Color(0, 0, 255);
COLORS.OPERATOR = Color(255, 255, 255);
COLORS.GENERIC = Color(200, 200, 200);
COLORS.NATIVE = Color(150, 150, 0);
COLORS.FUNCTION = Color(100, 100, 0);
COLORS.STRING = Color(100, 100, 0);

local KEYWORDS = {};
KEYWORDS['for'] = true;
KEYWORDS['in'] = true;
KEYWORDS['do'] = true;
KEYWORDS['if'] = true;
KEYWORDS['not'] = true;
KEYWORDS['and'] = true;
KEYWORDS['or'] = true;
KEYWORDS['elseif'] = true;
KEYWORDS['else'] = true;
KEYWORDS['end'] = true;
KEYWORDS['break'] = true;
KEYWORDS['continue'] = true;
KEYWORDS['function'] = true;
KEYWORDS['return'] = true;
KEYWORDS['local'] = true;

local OPERATOR = {};
OPERATOR['{'] = true;
OPERATOR['}'] = true;
OPERATOR['('] = true;
OPERATOR[')'] = true;
OPERATOR['['] = true;
OPERATOR[']'] = true;
OPERATOR['#'] = true;
OPERATOR['+'] = true;
OPERATOR['-'] = true;
OPERATOR['/'] = true;
OPERATOR['*'] = true;
OPERATOR['^'] = true;
OPERATOR['%'] = true;
OPERATOR['.'] = true;
OPERATOR['='] = true;
OPERATOR['=='] = true;
OPERATOR['~='] = true;
OPERATOR['>='] = true;
OPERATOR['>'] = true;
OPERATOR['<='] = true;
OPERATOR['<'] = true;


local function buildRows(native)
	local rows = {};

	for row, line in pairs(string.Explode("\n", native)) do
		local inString;
		local tokens = {};
		
		for _, token in pairs(string.Explode(" ", line)) do 
			if token == "'" or token == '"' then
				if inString and inString == token then
					inString = nil;
				else
					inString = token;
				end

				tokens[#tokens + 1] = {token, COLORS.STRING};
			elseif inString then
				tokens[#tokens + 1] = {token, COLORS.STRING};
			elseif KEYWORDS[token] then
				tokens[#tokens + 1] = {token, COLORS.KEYWORD};
			elseif OPERATOR[token] then
				tokens[#tokens + 1] = {token, COLORS.OPERATOR};
			elseif _G[token] then
				local tbl = _G[token];
				local t = type(tbl);

				if t == "function" then
					tokens[#tokens + 1] = {token, COLORS.FUNCTION};
				elseif tbl then
					tokens[#tokens + 1] = {token, COLORS.NATIVE};
				else
					tokens[#tokens + 1] = {token, COLORS.GENERIC};
				end
			else
				tokens[#tokens + 1] = {token, COLORS.GENERIC};
			end

			tokens[#tokens + 1] = {" ", COLORS.GENERIC};
		end

		rows[row] = tokens;
	end

	return rows, native;
end

EXPR_LIB.ShowDebug = function(native, name)
	if (Golem) then
		local inst = Golem:GetInstance();
		
		local rows, text = buildRows(native);
		
		name = name or "generic";
		local sheet = inst:NewTab("editor", text);
		
		sheet.Panel._OnKeyCodeTyped = function() end;
		sheet.Panel._OnTextChanged = function() end;
		
		sheet.Panel.SyntaxColorLine = function(self, row)
			
			if rows[row] then 
				return rows[row];
			end 

			return {{self.Rows[row], Color(255,255,255)}}
		end;

		local nFun = CompileString(text, "Expression 3 - Debugger", false);

		if type(nFun)  ~= "string" then
			inst.btnValidate:SetColor( Color( 50, 255, 50 ) );
			inst.btnValidate:SetText( "Native Output, Validated Sucessfuly" );
		elseif (nFun) then
			inst:OnValidateError( false, nFun);
			Golem.Print(Color(255, 255, 255), nFun);
		end
	end
end