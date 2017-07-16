--[[
	SCRIPT PARSER
]]

E3_SCRIPTPARSER = {};
E3_SCRIPTPARSER.__index = E3_SCRIPTPARSER;

--[[
	NEW
]]

function E3_SCRIPTPARSER.New(tokens, keywords, patterns, funcs, ast)
	local new = setmetatable({}, E3_SCRIPTPARSER);

	new.tokens = tokens;
	new.keywords = keywords;
	new.patterns = patterns;
	new.funcs = funcs;
	new.ast = ast;

	return new;
end

--[[
	INIT
]]

function E3_SCRIPTPARSER:Init(script)
	self.pos = 0;
	self.offset = 0;
	self.depth = 0;

	self.char = "";
	self.data = "";
	self.dataStart = 1;
	self.dataEnd = 1;

	self.tokenPos = 0;
	self.tokenLine = 0;
	self.tokenChar = 0;

	self.readChar = 1;
	self.readLine = 1;

	self.script = script;
	self.buffer = script;
	self.lengh = string.len(script);

	self.instructions = { };
	self.instructionPos = 0;

	if self.funcs.INIT then  self.funcs.INIT(self); end

	self:NextChar( );
end

function E3_SCRIPTPARSER:Run()
	local ok, status, res = pcall(self.ASTSequence, self, "ROOT", false);
	--print("RUN->",ok, status, res)
	return ok, status, res;
end

--[[
	STATE
]]

function E3_SCRIPTPARSER:GetState()
	local state = {};
	state.pos = self.pos;
	state.offset = self.offset;
	state.char = self.char;
	state.data = self.data;
	state.dataStart = self.dataStart;
	state.dataEnd = self.dataEnd;
	state.tokenPos = self.tokenPos;
	state.tokenLine = self.tokenLine;
	state.tokenChar = self.tokenChar;
	state.readChar = self.readChar;
	state.readLine = self.readLine;
	state.instruction = self.instruction;
	state.instructionPos = self.instructionPos;

	if self.funcs.GETSTATE then  self.funcs.GETSTATE(self, state); end

	return state;
end

function E3_SCRIPTPARSER:SetState(state)
	if not state then debug.Trace(); end
	self.pos = state.pos;
	self.offset = state.offset;
	self.char = state.char;
	self.data = state.data;
	self.dataStart = state.dataStart;
	self.dataEnd = state.dataEnd;
	self.tokenPos = state.tokenPos;
	self.tokenLine = state.tokenLine;
	self.tokenChar = state.tokenChar;
	self.readChar = state.readChar;
	self.readLine = state.readLine;
	self.instruction = state.instruction;
	self.instructionPos = state.instructionPos;
	if self.funcs.SETSTATE then  self.funcs.SETSTATE(self, state); end

end

--[[
	THROW ERROR
]]

function E3_SCRIPTPARSER:Throw(msg, fst, ...)
	local err = {};

	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	err.state = "parser";
	err.char = self.readChar;
	err.line = self.readLine;
	err.msg = msg;

	error( err, 0 );
end


--[[
	CHAR FUNCS
]]

function E3_SCRIPTPARSER:NextChar( )
	self.dataEnd = self.dataEnd + 1;
	self.data = self.data .. self.char;
	self:SkipChar( );
end

function E3_SCRIPTPARSER:PrevChar( )
	self.dataEnd = self.dataEnd - 2;
	self.pos = self.pos - 2;
	self.data = string.sub( self.data, 0, #self.data - 2 );
	self:SkipChar();
end

function E3_SCRIPTPARSER:SkipChar( )
	if self.lengh < self.pos then
		self.char = nil;
	elseif self.char == "\n" then
		self:PushLine( );
	else
		self:PushChar( );
	end
end

--[[
	LINE & CHAR
]]

function E3_SCRIPTPARSER:PushLine( )
	self.readLine = self.readLine + 1;
	self.readChar = 1;

	self.pos = self.pos + 1;
	self.char = string.sub( self.script, self.pos, self.pos );
end

function E3_SCRIPTPARSER:PushChar( )
	self.readChar = self.readChar + 1;

	self.pos = self.pos + 1;
	self.char = string.sub( self.script, self.pos, self.pos );
end

--[[
	PATERNS AND DATA
]]
function E3_SCRIPTPARSER:Clear( )
	self.data = "";
	self.match = "";
	self.dataStart = self.pos;
	self.dataEnd = self.pos;
end

function E3_SCRIPTPARSER:NextPattern( pattern, exact )
	--print("NextPatern", pattern, exact)
	if self.char == nil then
		return false;
	end

	local s, e, r = string.find( self.script, pattern, self.pos, exact );

	if s ~= self.pos then
		return false;
	end

	if not r then
		r = string.sub( self.script, s, e );
	end

	self.pos = e + 1;
	self.dataStart = s;
	self.dataEnd = e;
	self.data = self.data .. r;

	self.match = r;

	if self.pos > self.lengh then
		self.char = nil;
	else
		self.char = string.sub( self.script, self.pos, self.pos );
	end

	local ls = string.Explode( "\n", r );

	if #ls > 1 then
		self.readLine = self.readLine + #ls - 1;
		self.readChar = string.len( ls[#ls] ) + 1;
	else
		self.readChar = self.readChar + string.len(ls[#ls]);
	end

	--print(pattern, true, self.data)
	return true;
end

function E3_SCRIPTPARSER:MatchPattern( pattern, exact )
	local s, e, r = string.find( self.script, pattern, self.pos, exact );

	if s ~= self.pos then
		return false;
	end

	return true, string.sub( self.script. self.pos, self.pos );
end

function E3_SCRIPTPARSER:NextPatterns( exact, pattern, pattern2, ... )
	if (self:NextPattern(pattern, exact)) then
		return true;
	end

	if (pattern2) then
		return self:NextPatterns(exact, pattern2, ...);
	end

	return false;
end

function E3_SCRIPTPARSER:Replace( str )
	local len = string.len( self.data ) - string.len(str);

	self.data = str;

	self.offset = self.offset + len;
end

--[[
	TOKENS
]]

function E3_SCRIPTPARSER:CreateToken(type, name, data)
	local token = { };
	token.type = type;
	token.name = name;

	token.raw = self.data;
	token.data = data or self.data;
	token.start = self.dataStart + self.offset;
	token.stop = self.dataEnd + self.offset;
	token.pos = self.pos;
	token.char = self.readChar;
	token.line = self.readLine;
	token.depth = self.depth;
	token.orig = origonal;

	self.data = "";

	return token;
end

--[[
	INSTRUCTIONS
]]

function E3_SCRIPTPARSER:StartInstruction(type)
	local instruction = {};

	instruction.type = type;
	instruction.tokens = {};
	instruction.tokenData = {};
	instruction.instructions = {};
	instruction.parent = self.instruction;
	instruction.readChar = self.readChar
	instruction.readLine = self.readLine

	local pos = self.instructionPos + 1;
	self.instructions[pos] = instruction;
	self.instruction = instruction;
	self.instructionPos = pos;

	return instruction;
end

function E3_SCRIPTPARSER:EndInstruction()
	local instruction = self.instruction;

	local pos = self.instructionPos;
	self.instructionPos = pos - 1;
	self.instructions[pos] = nil;
	self.instruction = self.instructions[pos - 1];

	return instruction;
end

function E3_SCRIPTPARSER:addToken(instruction, token)
	local data = instruction.tokenData[token.type];

	if not data then data = {}; instruction.tokenData[token.type] = data; end

	instruction.tokens[#instruction.tokens + 1] = token;

	data[#data] = token;
end

function E3_SCRIPTPARSER:addInstruction(instruction1, instruction2)
	local data = instruction1.instructions[instruction2.type];

	if not data then data = {}; instruction1.instructions[instruction2.type] = data; end

	data[#data] = instruction2;
end

--[[
	PARSE AST
]]

function E3_SCRIPTPARSER:AST_EXCL(token, state, opt, instruction)
	--print("EXLUDE: ", token.name);
	local hasSeq = self:CheckAST(token.seq, true, instruction);
	if hasSeq then self:Thorw("1 %s must not appear here.", token.seq.name); end
	self:SetState(state);
	return true;
end

function E3_SCRIPTPARSER:AST_OR(token, state, opt, instruction)
	--print("LOR: ", token.right.name, token.left.name);
	local left = self:CheckAST(token.left, true, instruction);
	if left then return true; end

	local right = self:CheckAST(token.right, true, instruction);
	if right then return true; end

	if not opt then 
		if token.name then
			self:Throw("2 %s expected here.", token.name);
		else
			self:Throw("2 %s or %s expected here.", left.name, right.name);
		end
	end

	self:SetState(state);

	return false;
end

function E3_SCRIPTPARSER:AST_GRUOP(token, state, opt, instruction)
	--print("GROUP: ", token.name);
	
	for k, nextToken in pairs(token.seq) do

		if not self:CheckAST(nextToken, state, instruction) then
			if not opt then self:Throw("3 %s expected here.", nextToken.name); end

			return false;
		end
	end

	return true;
end

function E3_SCRIPTPARSER:AST_TOKEN(astToken, state, opt, instruction)
	
	if self.ast[astToken.data] then
		print("AST->", astToken.data);
		local data = self.ast[astToken.data];
		local ok, instruction2 = self:ASTSequence(data[1], opt, instruction);

		if ok then return true, instruction2; end

		if opt then return false; end

		self:Throw("%s expected.", data[3] or astToken.name);
	end

	local ok;
	local data;
	local token;

	if self.tokens[astToken.data] then
		print("TOKEN->", astToken.data);
		data = self.tokens[astToken.data];
		ok = self:NextPattern(data[1], true);
		if ok then token = self:CreateToken(astToken.data, data[2]); end
	elseif self.keywords[astToken.data] then
		print("KEYWORD->", astToken.data);
		data = self.keywords[astToken.data];
		ok = self:NextPattern(data[1], true);
		if ok then token = self:CreateToken(astToken.data, data[2]); end
	elseif self.patterns[astToken.data] then
		print("PATTERN->", astToken.data);
		data = self.patterns[astToken.data];
		if not data[3] then
			ok, token = data[1](self);
		else
			ok = self:NextPattern(data[1], true);
			if ok then token = self:CreateToken(astToken.data, data[2]); end
		end
	else
		error("Unkown token type: " .. astToken.data);
	end

	if astToken.func then
		self:RunAstFunc(astToken, token);
	end

	if ok and instruction then self:addToken(instruction, token); end

	if ok then return true, token; end

	if opt then return false; end

	self:Throw("%s expected.", data[2] or astToken.name);
end

local function eg(self, astToken, token)
	if token.data ~= astToken.filter then
		self:Throw("%s must not appear here", token.filter or token.name);
	end
end

local function neg(self, astToken, token)
	if token.data == astToken.filter then
		self:Throw("%s must not appear here", token.filter or token.name);
	end
end

function E3_SCRIPTPARSER:RunAstFunc(astToken, token)
	local name = astToken.func;
	if name == "neg" then
		eg(self, astToken, token);
	elseif name == "eg" then
		eg(self, astToken, token);
	elseif self.funcs[name] then
		self.funcs[name](self, token);
	else
		error("Uknown ast function, " .. name);
	end
end

function E3_SCRIPTPARSER:SkipSpaces()
	if not self.ast["SPACE"] then return false; end
	return E3_SCRIPTPARSER:ASTSequence("SPACE", true);
end

function E3_SCRIPTPARSER:SkipComments()
	if not self.ast["CMT"] then return false; end
	return E3_SCRIPTPARSER:ASTSequence("CMT", true);
end

local function ast(self, token, state, opt, instruction)
	if token.type == "EXCL" then return self:AST_EXCL(token, state, opt, instruction)
	elseif token.type == "LOR" then return self:AST_OR(token, state, opt, instruction)
	elseif token.type == "GROUP" then return self:AST_GRUOP(token, state, opt, instruction)
	elseif token.type == "TOKEN" then return self:AST_TOKEN(token, state, opt, instruction)
	else error("Uknown AST token type " .. token.type); end
end

function E3_SCRIPTPARSER:CheckAST(token, opt, instruction)
	self:SkipSpaces();
	self:SkipComments();

	local state = self:GetState();

	if not opt then opt = token.optional; end

	local ok, result = ast(self, token, state, opt, instruction);

	if not token.looped then return ok, result; end

	local results = {result};

	while ok do 
		local ok, result = ast(self, token, state, true, instruction)
		if ok then results[#results + 1] = result; end
	end

	return true, unpack(results);
end

function E3_SCRIPTPARSER:ASTSequence(type, opt, instruction1)
	--print("SEQENCE:", type)
	local req = self.ast[type];

	if not req then
		error("5 Unkown ast sequence " .. type);
	end

	local state = self:GetState();

	local instruction2 = self:StartInstruction(type);

	local ok = self:CheckAST(req[1], opt, instruction2);

	if ok then
		self:EndInstruction();

		if instruction1 then
			self:addInstruction(instruction1, instruction2);
		end

		return true, instruction2;
	end

	self:SetState(state);

	return false;
end