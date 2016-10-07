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
	A reveamp of my expression advanced 2 tokenizer,
	Using code by Divran, Oskar94, and maybe a few others.
]]


local T = {};

function T.new()
	return setmetatable({}, T);
end

function T.Initalize(this, script)
	this.__pos = 0;
	this.__offset = 0;

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

	this:NextChar();
end

function T.Run(this)
	--TODO: PcallX for stack traces on internal errors?
	local status, result = Pcall(T._Run, this);

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

function T._Run(this)
	while (this.__char ~= nil) do
		this:Loop();
	end

	local result = {};
	result.tokens = this.tokens;
	result.script = this.__buffer;
	
	return result;
end

function T.Throw(this, offset, msg, fst, ...)
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

local KEYWORDS = {
	["if"] = {"if", "if"},
	["elseif"] = {"eif", "elseif"},
	["else"] = {"els", "else"},
	["while"] = {"whl", "while"},
	["for"] = {"for", "for"},
	["foreach"] = {"each", "foreach"},
	["function"] = {"func", "function"},
	["default"] = {"dft", "default"},
	["event"] = {"evt", "event"},
	["try"] = {"try", "try"},
	["catch"] = {"cth", "catch"},
	["final"] = {"fnl", "final"},
	["true"] = {"tre", "true"},
	["false"] = {"fls", "false"}
	["void"] = {"void", "void"}
	["break"] = {"brk", "break"},
	["continue"] = {"cnt", "continue"},
	["return"] = {"ret", "return"},
	["global"] = {"glo", "global"},
	["input"] = {"in", "input"},
	["output"] = {"out", "output"},
	["static"] = {"stc", "static"},
	["synced"] = {"syn", "synced"},
	["server"] = {"sv", "server"},
	["client"] = {"cl", "client"},
}

local TOKENS = {
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
	{ "~", "cng", "changed" },
	{ "->", "wc", "connect" },
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

--[[
]]

function T.NextChar(this)
	this.__dataEnd = this.__dataEnd + 1;
	this.__data = this.__data .. this.__char;
	this:SkipChar();
end

function T.SkipChar(this)
	if (this.__lengh < this.__pos) then
		this.__char = nil;
	else if (this.__char == "\n") then
		this:PushLine();
	else
		this:PushChar();
	end
end

function T.PushLine(this)
	this.__readLine = this.__readLine + 1;
	this.__readChar = 1;

	this.__pos = this.__pos + 1;
	this.__char = string.sub(this.__script, this.__pos, this.__pos);
end

function T.PushChar(this)
	this.__readChar = this.__readChar + 1;

	this.__pos = this.__pos + 1;
	this.__char = string.sub(this.__script, this.__pos, this.__pos);
end

function T.Clear(this)
	this.__data = "";
	this.__match = "";
	this.__dataStart = this.__pos;
	this.__dataEnd = this.__pos;
end

--[[
]]

function T.NextPattern(this, pattern, exact)
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

function T.MatchPattern(this, pattern, exact)
	local s, e, r = string.find(this.__script, pattern, this.__pos, exact);

	if (s ~= this.__pos) then
		return false;
	end

	return true, string.sub(this.__script. this.__pos, this.__pos);
end

function T.NextPatterns(this, exact, pattern, pattern2, ...)
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

function T.CreateToken(this, type, name, data);
	if (not data) then
		data = this.__data;
	end

	local tkn = {};
	tkn.data = data;
	tkn.start = this.__dataStart + this.__offset;
	tkn.stop = this.__dataEnd + this.__offset;
	tkn.pos = this.__pos;
	tkn.char = this.__readChar;
	tkn.line = this.__readLine;

	this.__tokens[#this.__tokens + 1] = tkn;
end

--[[
]]

function T.SkipSpaces(this)
	this:NextPattern("^[%s\n]*");

	local r = this.__match;

	this:Clear();

	return r;
end

function T.SkipComments(this)
	if (this:NextPattern("^/%*.-%*/") or this:NextPattern("^//.-\n")) then
		this.__data = "";
		this.__skip = true;
		return true;
	else if (this:NextPattern("/*", true)) then
		this:Error(0, "Un-terminated multi line comment (/*)", 0);
	else
		return false;
	end
end

function T.Replace(this, start, _end, str)
	local len = _end - start;
	local pre = string.sub(this.__buffer, 1, this.__offet + start);
	local post = string.sub(this.__buffer, this.__offset + _end);
	
	this.__buffer = pre + str + post;

	if (len > 0) then
		this.__offset = this.__offset + len)
	end
end

--[[
]]

function T.Loop(this)
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
		this:Replace(this.__dataStart, this.__dataend, cmnt);
	elseif (this:NextPattern("/*", true)) then
		this:Throw(0, "Un-terminated multi line comment (/*)", 0);
	elseif (this:NextPattern("^//.-\n")) then
		skip = true;
		local cmnt = "--" .. string.sub(this.__data, 3);
		this:Replace(this.__dataStart, this.__dataend, cmnt);
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
			elseif (c = "\\") then
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
				local str = "[[" .. string.sub(this.__data, 2, string.len(this.__data) - 1) .. "]]";
				this:Replace(this.__dataStart, this.__dataend, str);
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

	-- Keywords.

	if (this:NextPattern("^[a-zA-Z][a-zA-Z0-9_]*")) then
		local w = this.__data;
		local tkn = KEYWORDS[w];

		if (tkn) then
			this:CreateToken(tkn[1], tkn[2]);
		else
			this:CreateToken("var", "variable");
		end
		
		return true;
	end

	-- TODO: Class names and casting :D

	-- Ops

	for k = 1, #TOKENS, 1 do
		local v = [k];

		if (this:NextPattern(v[1], true)) then
			this:CreateToken(v[2], v[3]);
			return true;
		end
	end

	if (not this.__char or this.__char == "") then
		this.__char = nil;
	else
		this:Throw(0, "Unknown syntax found (%s)", tostring(this.__char));
	end
end

