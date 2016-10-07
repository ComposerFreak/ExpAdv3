--[[
	TODO: This
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
	return Pcall(T._Run, this);
end

function T._Run(this)
	while (this.__char ~= nil) do

	end
end

function T.Throw(...)
	-- Todo: This
end

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
	
end

