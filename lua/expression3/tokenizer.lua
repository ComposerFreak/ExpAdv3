--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Tokenizer::
	`````````````
	A revamp of my expression advanced 2 tokenizer,
	Using code by Divran, Oskar94, and maybe a few others.
]]

local KEYWORDS = {
	EXPADV = {
		["if"] = {"if", "if"},
		["elseif"] = {"eif", "elseif"},
		["else"] = {"els", "else"},
		["while"] = {"whl", "while"},
		["for"] = {"for", "for"},
		["foreach"] = {"each", "foreach"},
		["function"] = {"func", "function"},
		["event"] = {"evt", "event"},
		["true"] = {"tre", "true"},
		["false"] = {"fls", "false"},
		["void"] = {"void", "void"},
		["break"] = {"brk", "break"},
		["continue"] = {"cnt", "continue"},
		["return"] = {"ret", "return"},
		["global"] = {"glo", "global"},
		["server"] = {"sv", "server"},
		["client"] = {"cl", "client"},
		["new"] = {"new", "constructor"},
	}
}

local TOKENS = {
	EXPADV = {
		{ "+", "add", "addition" },
		{ "-", "sub", "subtract" },
		{ "*", "mul", "multiplier" },
		{ "/", "div", "division" },
		{ "%", "mod", "modulus" },
		{ "^", "exp", "power" },
		{ "=", "ass", "assign" },
		{ "+=", "aadd", "increase" },
		{ "-=", "asub", "decrease" },
		{ "*=", "amul", "multiplier" },
		{ "/=", "adiv", "division" },
		{ "++", "inc", "increment" },
		{ "--", "dec", "decrement" },
		{ "==", "eq", "equal" },
		{ "!=", "neq", "unequal" },
		{ "<", "lth", "less" },
		{ "<=", "leq", "less or equal" },
		{ ">", "gth", "greater" },
		{ ">=", "geq", "greater or equal" },
		{ "&", "band", "and" },
		{ "|", "bor", "or" },
		{ "^^", "bxor", "or" },
		{ ">>", "bshr", ">>" },
		{ "<<", "bshl", "<<" },
		{ "!", "not", "not" },
		{ "&&", "and", "and" },
		{ "||", "or", "or" },
		{ "?", "qsm", "?" },
		{ ":", "col", "colon" },
		{ ";", "sep", "semicolon" },
		{ ",", "com", "comma" },
		{ "$", "dlt", "delta" },
		{ "#", "len", "length" },
		--{ "~", "cng", "changed" },
		--{ "->", "wc", "connect" },
		{ ".", "prd", "period" },
		{ "(", "lpa", "left parenthesis" },
		{ ")", "rpa", "right parenthesis" },
		{ "{", "lcb", "left curly bracket" },
		{ "}", "rcb", "right curly bracket" },
		{ "[", "lsb", "left square bracket" },
		{ "]", "rsb", "right square bracket" },
		{ '@', "dir", "directive operator" },
		{ "...", "varg", "varargs" },
	}
}


table.sort( TOKENS.EXPADV, function( token, token2 )
	return #token[1] > #token2[1];
end )

--[[
	Notes: 	I plan on possibly making this compiler multi language capable.
]]

local TOKENIZER = {};
TOKENIZER.__index = TOKENIZER;

function TOKENIZER.New(lang)
	return setmetatable({}, TOKENIZER);
end

function TOKENIZER.Initalize(this, lang, script)
	if (KEYWORDS[lang] and TOKENS[lang]) then
		this.__pos = 0;
		this.__offset = 0;
		this.__depth = 0;

		this.__char = "";
		this.__data = "";
		this.__dataStart = 1;
		this.__dataEnd = 1;

		this.__tokenPos = 0;
		this.__tokenLine = 0;
		this.__tokenChar = 0;

		this.__readChar = 1;
		this.__readLine = 1;

		this.__tokens = {};
		this.__script = script;
		this.__buffer = script;
		this.__lengh = string.len(script);

		this.language = lang;
		this.tokens = TOKENS[lang];
		this.keywords = KEYWORDS[lang];

		this:NextChar();
	else
		return nil, "No such language.";
	end
end

function TOKENIZER.Run(this)
	--TODO: PcallX for stack traces on internal errors?
	local status, result = pcall(this._Run, this);

	if (status) then
		return true, result;
	end

	if (type(result) == "table") then
		return false, result;
	end

	local err = {};
	err.state = "internal";
	err.msg = result;

	return false, err;
end

function TOKENIZER._Run(this)
	while (this.__char ~= nil) do
		this:Loop();
	end

	local result = {};
	result.tokens = this.__tokens;
	result.script = this.__buffer;

	return result;
end

function TOKENIZER.Throw(this, offset, msg, fst, ...)
	local err = {};

	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	err.state = "tokenizer";
	err.char = this.__readChar + offset;
	err.line = this.__readLine;
	err.msg = msg;

	error(err,0);
end

--[[
]]

function TOKENIZER.NextChar(this)
	this.__dataEnd = this.__dataEnd + 1;
	this.__data = this.__data .. this.__char;
	this:SkipChar();
end

function TOKENIZER.SkipChar(this)
	if (this.__lengh < this.__pos) then
		this.__char = nil;
	elseif (this.__char == "\n") then
		this:PushLine();
	else
		this:PushChar();
	end
end

function TOKENIZER.PushLine(this)
	this.__readLine = this.__readLine + 1;
	this.__readChar = 1;

	this.__pos = this.__pos + 1;
	this.__char = string.sub(this.__script, this.__pos, this.__pos);
end

function TOKENIZER.PushChar(this)
	this.__readChar = this.__readChar + 1;

	this.__pos = this.__pos + 1;
	this.__char = string.sub(this.__script, this.__pos, this.__pos);
end

function TOKENIZER.Clear(this)
	this.__data = "";
	this.__match = "";
	this.__dataStart = this.__pos;
	this.__dataEnd = this.__pos;
end

--[[
]]

function TOKENIZER.NextPattern(this, pattern, exact)
	if (this.__char == nil) then
		return false;
	end

	local s, e, r = string.find(this.__script, pattern, this.__pos, exact);

	if (s ~= this.__pos) then
		return false;
	end

	if (not r) then
		r = string.sub(this.__script, s, e);
	end

	this.__pos = e + 1;
	this.__dataStart = s;
	this.__dataEnd = e;
	this.__data = this.__data .. r;

	this.__match = r;

	if (this.__pos > this.__lengh) then
		this.__char = nil;
	else
		this.__char = string.sub(this.__script, this.__pos, this.__pos);
	end

	local ls = string.Explode("\n", r);

	if (#ls > 1) then
		this.__readLine = this.__readLine + #ls - 1;
		this.__readChar = string.len(ls[#ls]) + 1;
	else
		this.__readChar = this.__readChar + string.len(ls[#ls]);
	end

	return true;
end

function TOKENIZER.MatchPattern(this, pattern, exact)
	local s, e, r = string.find(this.__script, pattern, this.__pos, exact);

	if (s ~= this.__pos) then
		return false;
	end

	return true, string.sub(this.__script. this.__pos, this.__pos);
end

function TOKENIZER.NextPatterns(this, exact, pattern, pattern2, ...)
	if (this:NextPattern(pattern, exact)) then
		return true;
	end

	if (pattern2) then
		return this:NextPatterns(exact, pattern2, ...);
	end

	return false;
end

--[[
]]

function TOKENIZER.CreateToken(this, type, name, data, origonal)

	if (not data) then
		data = this.__data;
	end

	local tkn = {};
	tkn.type = type;
	tkn.name = name;
	tkn.data = data;

	tkn.start = this.__dataStart + this.__offset;
	tkn.stop = this.__dataEnd + this.__offset;
	tkn.pos = this.__pos;
	tkn.char = this.__readChar;
	tkn.line = this.__readLine;
	tkn.depth = this.__depth;
	tkn.orig = origonal;
	
	local prev = this.__tokens[#this.__tokens];

	if (prev and prev.line < tkn.line) then
		tkn.newLine = true;
	end

	this.__tokens[#this.__tokens + 1] = tkn;
end

--[[
]]

function TOKENIZER.SkipSpaces(this)
	this:NextPattern("^[%s\n]*");

	local r = this.__match;

	this:Clear();

	return r;
end

function TOKENIZER.SkipComments(this)
	if (this:NextPattern("^/%*.-%*/") or this:NextPattern("^//.-\n")) then
		this.__data = "";
		this.__skip = true;
		return true;
	elseif (this:NextPattern("/*", true)) then
		this:Error(0, "Un-terminated multi line comment (/*)", 0);
	else
		return false;
	end
end

function TOKENIZER.Replace(this, str)
	local len = string.len(this.__data) - string.len(str);
	
	this.__data = str;

	this.__offset = this.__offset + len
end

--[[
]]

function TOKENIZER.Loop(this)
	if (this.__char == nil) then
		return false;
	end

	this:SkipSpaces();

	-- Comments need to be (--[[]] && --) not (/**/ & //)
	-- Comments also need to be ignored.

	local skip = false;

	if (this:NextPattern("^/%*.-%*/")) then
		skip = true;
		local cmnt = "--[[" .. string.sub(this.__data, 3, string.len(this.__data) - 2) .. "]]";
		this:Replace(cmnt);
	elseif (this:NextPattern("/*", true)) then
		this:Throw(0, "Un-terminated multi line comment (/*)", 0);
	elseif (this:NextPattern("^//.-\n")) then
		skip = true;
		local cmnt = "--" .. string.sub(this.__data, 3);
		this:Replace(cmnt);
	end

	if (skip) then
		this:Clear();
		return true;
	end

	-- Numbers

	if (this:NextPattern("^0x[%x]+")) then
		local n = tonumber(this.__data);

		if (not n) then
			this:Throw(0, "Invalid number format (%s)", 0, this.__data);
		end

		this:CreateToken("num", "hex", n);

		return true;
	end

	if (this:NextPattern("^0b[01]+")) then
		local n = tonumber(string.sub(this.__data, 3), 2);

		if (not n) then
			this:Throw(0, "Invalid number format (%s)", 0, this.__data);
		end

		this:CreateToken("num", "bin", n);

		return true;
	end

	if (this:NextPattern("^%d+%.?%d*")) then
		local n = tonumber(this.__data);

		if (not n) then
			this:Throw(0, "Invalid number format (%s)", 0, this.__data);
		end

		this:CreateToken("num", "real", n);

		return true;
	end

	-- Strings
	
	if (this.__char == '"' or this.__char == "'") then
		local strChar = this.__char;

		local escp = false;

		this:SkipChar();

		while this.__char do
			local c = this.__char;

			if (c == "\n") then
				if (strChar == "'") then
					this:NextChar();
				else
					break;
				end
			elseif (not escp) then
				if (c == strChar) then
					break;
				elseif (c == "\\") then
					escp = true;
					this:SkipChar();
					-- Escape sequence.
				else
					this:NextChar();
				end
			elseif (c == "\\") then
				escp = false;
				this:NextChar();
			elseif (c == strChar) then
				escp = false;
				this.__char = "\n";
				this:NextChar();
			elseif (c == "t") then
				escp = false;
				this.__char = "\t";
				this:NextChar();
			elseif (c == "r") then
				escp = false;
				this.__char = "\r";
				this:NextChar();
			elseif (this:NextPattern("^([0-9]+)")) then
				local n = tonumber(this.__match);

				if (not n or n < 0 or n > 255) then
					this:Throw(0, "Invalid char (%s)", n);
				end

				escp = false;
				this.__pos = this.__pos - 1;
				this.__data = this.__data .. string.char(n);
				this:SkipChar();
			else
				this:Throw(0, "Unfinished escape sequence (\\%s)", this.__char);
			end
		end

		if (this.__char and this.__char == strChar) then
			this:SkipChar();

			-- Multi line strings need to be converted to lua syntax.
			if (strChar == "'") then
				local str = "[[" .. string.sub(this.__data, 1, string.len(this.__data) - 1) .. "]]";
				this:Replace(str);
			end

			this:CreateToken("str", "string");
			return true;
		end

		local str = this.__data;

		if (string.len(str) > 10) then
			str = string.sub(str, 0, 10) .. "...";
		end

		this:Throw(0, "Unterminated string (\"%s)", str);
	end

	-- Classes
	
	for k, v in pairs(EXPR_CLASSES) do
		if (this:NextPattern("%( *" .. k .. " *%)")) then
			this:CreateToken("cst", "cast", v.id, k);
			return true;
		end

		if (this:NextPattern(k, true)) then
			this:CreateToken("typ", "type", v.id, k);
			return true;
		end
	end

	-- Keywords.

	if (this:NextPattern("^[a-zA-Z][a-zA-Z0-9_]*")) then
		local w = this.__data;
		local tkn = this.keywords[w];

		if (tkn) then
			this:CreateToken(tkn[1], tkn[2]);
		else
			this:CreateToken("var", "variable");
		end
		
		return true;
	end

	-- Ops

	for k = 1, #this.tokens, 1 do
		local v = this.tokens[k];
		local op = v[1];

		if (this:NextPattern(op, true)) then
			if (op == "}") then
				this.__depth = this.__depth - 1;
			end

			this:CreateToken(v[2], v[3]);

			if (op == "{") then
				this.__depth = this.__depth + 1;
			end

			return true;
		end
	end

	if (not this.__char or this.__char == "") then
		this.__char = nil;
	else
		this:Throw(0, "Unknown syntax found (%s)", tostring(this.__char));
	end
end


--[[
]]

EXPR_TOKENS = TOKENS;
EXPR_KEYWORDS = KEYWORDS;
EXPR_TOKENIZER = TOKENIZER;
