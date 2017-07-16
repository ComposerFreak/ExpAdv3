--[[
	AST Syntax Parser
]]

local  E3_ASTPARSER = {};
E3_ASTPARSER.__index =  E3_ASTPARSER;

function E3_ASTSYNTAX(ast, name)
	local p = E3_ASTPARSER.New();

	p:Initialize(ast, name);

	local ok, res = p:Run();

	return ok, res, p;
end

function E3_ASTPARSER.New()
	return setmetatable({},  E3_ASTPARSER);
end

function E3_ASTPARSER:Initialize(ast, name)
	self.pos = 0;

	self.char = "";
	self.data = "";
	self.dataStart = 1;
	self.dataEnd = 1;

	self.buffer = ast;
	self.lengh = string.len(ast);

	self.ast = ast;
	self.name = name;

	self:NextChar();
end

function E3_ASTPARSER:Run()
	local status, result = pcall(self.NextSequence, self, 0);

	if (status) then
		return true, result;
	end

	return false, result;
end

--[[
]]

function E3_ASTPARSER:PushChar()
	self.pos = self.pos + 1;
	self.char = string.sub(self.buffer, self.pos, self.pos);
end


function E3_ASTPARSER:NextChar()
	self.dataEnd = self.dataEnd + 1;
	self.data = self.data .. self.char;
	self:SkipChar();
end

function E3_ASTPARSER:SkipChar()
	if (self.lengh < self.pos) then
		self.char = nil;
	else
		self:PushChar();
	end
end

function E3_ASTPARSER:NextPattern(pattern, exact)
	if (self.char == nil) then
		return false;
	end

	local s, e, r = string.find(self.buffer, pattern, self.pos, exact);

	if (s ~= self.pos) then
		return false;
	end

	if (not r) then
		r = string.sub(self.buffer, s, e);
	end

	self.pos = e + 1;
	self.dataStart = s;
	self.dataEnd = e;
	self.data = self.data .. r;

	self.match = r;

	if (self.pos > self.lengh) then
		self.char = nil;
	else
		self.char = string.sub(self.buffer, self.pos, self.pos);
	end

	return true;
end

function E3_ASTPARSER:MatchPattern(pattern, exact)
	local s, e, r = string.find(self.buffer, pattern, self.pos, exact);

	if (s ~= self.pos) then
		return false;
	end

	return true, string.sub(self.buffer. self.pos, self.pos);
end

function E3_ASTPARSER:NextPatterns(this, exact, pattern, pattern2, ...)
	if (self:NextPattern(pattern, exact)) then
		return true;
	end

	if (pattern2) then
		return self:NextPatterns(pattern2, ...);
	end

	return false;
end

function E3_ASTPARSER:SkipSpaces()
	self:NextPattern("^[%s\n]*");

	local r = self.match;

	self:Clear();

	return r;
end

function E3_ASTPARSER:NextSequence(name)
	local seq = {};

	while self.char and self.char ~= ")" do
		local token1 = self:NextSyntax(name);

		if not token1 then
			error("incomplete ast sequence " .. self.char);
		end

		seq[#seq + 1] = token1;
	end


	if #seq == 1 then return seq[1]; end

	return {type = "GROUP", seq = seq};
end

function E3_ASTPARSER:NextSyntax(name)

	self:SkipSpaces();

	if self.char == ")" then
		return;
	elseif self.char == "-" then
		self:SkipChar();
		return {type = "EXCL", seq = self:NextSyntax(), name = self.name};
	end

	local token = {};

	token.name = self.name;
	
	if self.char == "(" then
		-- (GROUP EXPR)
		self:SkipChar();

		local token2 = self:NextSequence();

		token2.name = token2.name or token.name;

		token = token2;

		if (not self.char) or self.char ~= ")" then
			error("Incomplete ast sequence, ) expected.");
		end

		self:SkipChar();

	elseif self:NextPattern("^([A-Z0-9_]+)") then
		token.type = "TOKEN";
		token.data = self.data
		self.data = ""
	else
		error("Invalid token in sequence '" .. self.char .. "'");
	end

	if self.char == "{" then
		-- {FUNC}
		self:SkipChar();

		if token.type ~= "TOKEN" then
			error("Parser functions must preceed token.")
		end

		while self.char and self.char ~= "}" do
			if self:NextPattern("^%!=([a-zA-Z0-9_]+)") then
				token.func = "neg"
				token.filter = self.data; self.data = "";
			elseif self:NextPattern("^=([a-zA-Z0-9_]+)") then
				token.func = "eg"
				token.filter = self.data; self.data = "";
			elseif self:NextPattern("^([A-Z0-9_]+)") then
				token.func = self.data; self.data = "";
			else
				error("Invalid ast function.");
			end
		end

		if not self.char or self.char ~= "}" then
			error("Incomplete ast sequence, ~ expected.");
		end

		self:SkipChar();
	end

	if self.char and self.char == "+" then
		-- * one or more
		token.looped = true;
		self:SkipChar();
	end

	if self.char and self.char == "*" then
		-- + optional
		token.optional = true;
		self:SkipChar();
	end

	self:SkipSpaces();

	if self.char and self.char == "?" then
		self:SkipChar();
		return {type = "LOR", left = token, right = self:NextSequence()}
	end

	return token;
end

function E3_ASTPARSER:Clear()
	self.data = "";
	self.match = "";
	self.dataStart = self.pos;
	self.dataEnd = self.pos;
end