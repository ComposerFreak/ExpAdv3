
--[[
	THE LEXER
]]

local LEXER = {};
LEXER.__index = LEXER;

function LEXER.__call(tokens, files, compiler)
	return setmetatable({tokens = tokens, files = files, pos = 0}, LEXER).Init();
end

--[[
	INIT
]]

function LEXER:Init()
	self.buffer = {};
	self:NewScope();
	self:firstToken();
	return self;
end

--[[
	NEXT TOKEN
]]

function LEXER:firstToken()
	self.tokenPosition = 1;
	self:nextToken();
end

function LEXER:nextToken()
	local pos = self.tokenPosition;

	if pos > 0 and pos < #self.tokens then
		self.token = self.tokens[self.tokenPosition];
		self.tokenPosition = self.tokenPosition + 1;
	else
		self.token = nil;
	end
end

--[[
	CHECK SEQUENCE / ACCEPT TOKEN
]]

function LEXER:getToken(off)
	return self.tokens[self.tokenPosition + off];
end

function LEXER:checkToken(typ, off)
	local token = self:getToken(off);

	if token and istable(typ) then
		for i = 1, #typ do
			if token.type == type[i] then return true; end
		end
	elseif token and token.type == typ then
		return true;
	end

	return false;
end

function LEXER:acceptToken(typ)
	if self:checkToken(typ, 0) then
		self:nextToken();
		return true;
	end

	return false;
end

--[[
	START INSTRUCTION / END INSTRUCTION
]]

function LEXER:StartInstruction(type)
	local position = #instructions;
	local instructions = self.instructions;

	local instruction = { };
	instruction.info = {};
	instruction.tokens = {};
	instruction.instructions = {};
	instruction.type = type;
	instruction.result = {"", 0};
	instruction.sChar = self.token.char;
	instruction.sLine = self.token.line;
	instruction.parent = instructions[position];

	instructions[position + 1] = instruction;
	self.instruction = instruction;

	return instruction;
end

function LEXER:insertToken(type, token)
	if self.instruction then
		local tokens = self.instruction.tokens[type];
		if not tokens then tokens = { }; self.instruction.tokens[type] = tokens; end
		tokens[#tokens + 1] = token;
	end
end

function LEXER:insertInstruction(instruction)
	if self.instruction then
		local type = instruction.type
		local instructions = self.instruction.instructions[type];
		if not instructions then instructions = { }; self.instruction.instructions[type] = instructions; end
		instructions[#instructions + 1] = instruction;
	end
end

function LEXER:EndInstruction(class, count)
	local position = #instructions;
	local instructions = self.instructions;
	local instruction = instructions[position];

	instruction.eChar = self.token.char;
	instruction.eLine = self.token.char;

	self.instruction = instructions[position - 1];
	instructions[position] = nil;

	return instruction;
end

function LEXER:TerminateInstruction()
	local position = #instructions;
	local instructions = self.instructions;

	self.instruction = instructions[position - 1];
	instructions[position] = nil;
end

--[[
	TODO: Make this do what its supposed to do.
]]

function LEXER:checkSeqence(...)
	local p =self.tokenPosition - 1;
	local seq = { ... };

	local exprs = {};
	local valid = true;

	for i = 1, #seq do
		local v = seq[i];
		local f = self[v];

		if not self:checkToken(v, i - 1) then
			if not f then
				valid = false;
				break;
			end

			local r = f(self);

			if not r and not opt then
				valid = false;
				break;
			end

			exprs[#exprs + 1] = r;
		end
	end

	if not valid then
		self.tokenPosition = p;
		self:nextToken();
		return false;
	end

	if #exprs == 0 then return true; end

	return true, unpack(exprs);
end