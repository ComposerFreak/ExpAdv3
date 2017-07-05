--[[
	ERROR MESSAGES
]]

local ERROR_VAR_EXISTS = "Unable to define %s %s, %s already exists here.";
local ERROR_IO_MISSMATCH = "Unable to declair %s here, %s exists as %s.";
local ERROR_INVALID_COND = "Invalid condition for %s statment."
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
	PUSH SCOPE / POP SCOPE
]]

function LEXER:NewScope()
	local new = {};
	new.level = -1;
	new.levels = { };
	new.outports = { };
	new.inports = { };
	new.loopDeph = 0;
	new.classDeph = 0;
	new.functionDeph = 0;

	local old = self.scopeTable;
	self.scopeTable = new;

	self:pushScope();
	return old;
end

function LEXER:PushScope()
	local data = self.scopeTable;
	local level = data.level + 1;
	local prev = data[level - 1];

	local new = { };

	new.locals = { };
	new.outports = { };
	new.inports = { };
	new.classes = { };

	new.inClass = prev.inClass;
	new.canBreak = prev.canBreak or false;
	new.canCont = prev.canCont or false;
	new.canRet = prev.canRet or false;

	new.retType = prev.retType;
	new.retcount = prev.retCount;

	data.current = new;
	data.level = level;
	data.levels[level] = new;

	return new;
end

function LEXER:popScope()
	local data = self.scopeTable;
	local level = data.level - 1;

	data.level = level;
	data.current = data.levels[level];
end

--[[
	GET STATE DATA
]]

function LEXER:canBreak()
	return self.scopeTable.current.canBreak or false;
end

function LEXER:canContinue()
	return self.scopeTable.current.canContinue or false;
end

function LEXER:canReturn()
	return self.scopeTable.current.canReturn or false;
end

function LEXER:returnValues()
	return self.scopeTable.current.retType or "void", self.scopeTable.current.retcount or 0;
end

function LEXER:currentClass()
	local class = self.scopeTable.current.inClass;
	return class, self:getUDC(class); -- Todo this function.
end

--[[
	STATE INFORMATION
]]

function LEXER:startLoop()
	self.scopeTable.loopDeph = self.scopeTable.loopDeph + 1;
	local data = self:pushScope();
	data.canBreak = true;
	data.canCont = true;
end

function LEXER:endLoop()
	self.scopeTable.loopDeph = self.scopeTable.loopDeph - 1;
	self:popScope();
end

function LEXER:startFunction(res, count)
	self.scopeTable.functionDeph = self.scopeTable.functionDeph + 1;
	local data = self:pushScope();
	data.canBreak = false;
	data.canCont = false;
	data.canRet = (res ~= nil);
	data.retType = res;
	data.retcount = count;
end

function LEXER:endFunction()
	self.scopeTable.functionDeph = self.scopeTable.functionDeph - 1;
	self:popScope();
end

function LEXER:startClass(name, tbl)
	self.scopeTable.classDeph = self.scopeTable.classDeph + 1;

	local data = self:pushScope();
	data.classes[name] = tbl;
	data.inClass = name;

	data.canBreak = false;
	data.canCont = false;
	data.canRet = false;
	data.retType = nil;
	data.retcount = nil;
end

function LEXER:endClass()
	self.scopeTable.classDeph = self.scopeTable.classDeph - 1;
	self:popScope();
end

function LEXER:getUDC(name)
	local levels = self.scopeTable.levels;

	for level = self.scopeTable.level, 0, -1 do
		local data = levels[level];

		if data.classes[name] then
			return data.classes[name], level, "class";
		end
	end
end

--[[
	GET MEMORY / SET MEMORY
]]

function LEXER:getVariable(name, scope, noLoop)
	local levels = self.scopeTable.levels;

	for level = scope or self.scopeTable.level, 0, -1 do
		local data = levels[level];

		if data.locals[name] then
			return data.locals[name], level, "variable";
		elseif data.outports[name] then
			return data.outports[name], level, "outport";
		elseif data.inports[name] then
			return data.inports[name], level, "inport";
		elseif noLoop then
			return;
		end
	end
end

function LEXER:createGlobal(type, name)
	local var, level, mem = self:getVariable(name, 0, true);
	if var then self:error(ERROR_VAR_EXISTS, "variable", name, mem); end

	var = {};
	var.name = name;
	var.type = type;
	var.level = 0;

	self.scopeTable.levels[0].locals[name] = var;
end

function LEXER:createVariable(type, name)
	local var, level, mem = self:getVariable(name, true);

	if var then self:error(ERROR_VAR_EXISTS, "variable", name, mem); end

	var = {};
	var.name = name;
	var.type = type;
	var.level = 0;

	self.scopeTable.current.locals[name] = var;
end

function LEXER:createInport(type, name)
	local port = self.scopeTable.inports[name];
	if port and port.type ~= type then self:error(ERROR_IO_MISSMATCH, "inport", name, Name(port.type)); end
	
	local var, level, mem = self:getVariable(name, true);
	if var then self:error(ERROR_VAR_EXISTS, "inport", name, mem); end

	var = {};
	var.name = name;
	var.type = type;
	var.level = 0;

	self.scopeTable.inports[name] = var;
	self.scopeTable.current.inports[name] = var;
end

function LEXER:createOutport(type, name)
	local port = self.scopeTable.outports[name];
	if port and port.type ~= type then self:error(ERROR_IO_MISSMATCH, "outport", name, Name(port.type)); end

	local var, level, mem = self:getVariable(name, true);
	if var then self:error(ERROR_VAR_EXISTS, "outport", name, mem); end

	var = {};
	var.name = name;
	var.type = type;
	var.level = 0;

	self.scopeTable.outports[name] = var;
	self.scopeTable.current.outports[name] = var;
end

--[[
	ERROR / REQUIRE
]]

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

function LEXER:acceptToken(typ)
	if self:checkToken(typ, 0) then
		self:nextToken();
		return true;
	end

	return false;
end

--[[
	FIND/LAST IN STATMENT
]]

function LEXER:findInStatment(typ, off)
	off = off or 0;
	local first = self:getToken(off);
	
	while true do
		local token = self:getToken(off);

		if not token then return false; end

		if token.type == "sep" then return false; end

		if first.line ~= token.line then return false; end

		if self:checkToken(typ, off) then return true, token; end

		off = off + 1;
	end

	return false;
end

function Parser:lastInStatment(typ, off)
	off = off or 0;

	local last;
	local first = self:getToken(off);

	while true do
		local token = self:getToken(off);

		if not token then return last; end

		if token.type == "sep" then return last; end

		if first.line ~= token.line then return last; end

		if self:checkToken(typ, off) then last = token end

		off = off + 1;
	end

	return last;
end

--[[
	START INSTRUCTION / END INSTRUCTION
]]

function LEXER:StartInstruction(type)
	local position = #instructions;
	local instructions = self.instructions;

	local instruction = { };
	instruction.info = {};
	instruction.buffer = {};
	instruction.type = type;
	instruction.result = {"", 0};
	instruction.sChar = self.token.char;
	instruction.sLine = self.token.line;
	instruction.parent = instructions[position];

	instructions[position + 1] = instruction;
	self.instruction = instruction;

	return instruction;
end

function LEXER:insertCode(code, a, ...)
	if self.instruction then
		if a then code = string.format(code, a, ...); end
		local buffer = self.instruction.buffer;
		local info = self.instruction.info;
		buffer[#buffer + 1] = code;
	end
end

function LEXER:insertLine(line, a, ...)
	if a then line = string.format(line, a, ...); end
	self:insertCode("\n" .. line .. "\n");
end

function LEXER:injectCode(inst, pos, code, a, ...)
	if a then code = string.format(code, a, ...); end
	table.insert(inst, pos, code);
end

function LEXER:EndInstruction(class, count)
	local position = #instructions;
	local instructions = self.instructions;
	local instruction = instructions[position];

	local inject = string.concat(instruction.buffer, " ");
	if inject ~= "" then self:insertCode(inject); end

	if class then instruction.result = {class, count or 0}; end

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
	Casted Expression
]]

function LEXER:getOperator(op_table, operator, ...)
	if not op_table then return; end

	local types = { };
	local expressons = { ... };

	for k = 1, #expressons do
		local v = expressons[k];

		if isstring(v) then
			types[k] = v;
		elseif istable(v) and v.result then
			types[k] = v.result[1];
		else
			error("LEXER:getOperator() was given invalid type " .. tostring(v), 0);
		end
	end

	local name = string.format(operator, unpack(types));
	local op = op_table[name];

	return op, name;
end

--[[
	Casted Expression
]]

function LEXER:compareClass(inst, class)
	if not inst.result then return false; end

	if inst.result[1] ~= class then return false; end

	if inst.result[2] > 0 and class ~= "" then return false; end

	return true;
end

function LEXER:useCallableOperator(op, inst)
	self:injectCode(inst, 1, "_OPS[%q] (", op.signature);

	if op.context then self:injectCode(inst, 2, "CONTEXT"); end

	if inst.buffer[3] then self:injectCode(inst, 3, ","); end

	self:injectCode(inst, nil, ")");

	inst.result = {op.result, op.rCount};
end

function LEXER:getCastedValue(func, class, ...)
	local inst = self:StartInstruction("CAST");

	local expr = func(self, ...);

	if not expr then return false; end

	if not self:compareClass(expr, class) then
		-- TODO: Check for user type casting.

		local op = self:getOperator(EXPR_CAST_OPERATORS, "(%s)%s", class, expr);

		if op.operation then self:useCallableOperator(op, inst); end

		return true, self:endInstruction(op.result, op.rCount);
	end

	return false;
end

function LEXER:getAsBoolean(func, ...)
	return self:getCastedValue(func, "b", ...);
end

function LEXER:getAsString(func, ...)
	return self:getCastedValue(func, "s", ...);
end

function LEXER:getAsVariant(func, ...)
	return self:getCastedValue(func, "_vr", ...);
end

--[[
	#Sorry guys, it looks like crap but makes sense to me :D


	#KEY:
	#[*]Optional
	#[()] Group
	#[+] Repeate
	#[?] OR
	#[-] Exclude

	#PARSER DATA

	ROOT: (DIRS1+)* STMTS0;                                                                             #Root of code
	BLOCK0: {PUSH}((LCB STMTS0 RCB) ? STMT0){POP};                                                      #Code Block
	STMTS0: (STMT18 ? (STMT0+)*;                                                                        #Regular Statements (STMT0 - SMST17)
	STMTS1: (STMT19+)*;                                                                                 #Class Statements (STMT19+)

	STMT0: DIR4 ? (TRY BLOCK0 CTC LPA VAR RPA BLOCK0) ? STMT1;                                          #Try Catch
	STMT1: (IF LPA CND RPA BLCOK0 (STMT2+)* STMT3*) ? STMT4;                                            #If Statement
	STMT2: (EIF LPA CND RPA BLOCK0);                                                                    #Esleif Statement
	STMT3: (ELSE BLOCK0)*;                                                                              #Else Statement

	 STMT4: (FOR LPA TYPE ASS EXPR0 SEP EXPR0 (SEP EXPR0)* RPA BLOCK0) ? STMT5;                         #For Loop
	 STMT5: (WHILE CND BLOCK0) ? STMT6;                                                                 #While Loop
	 STMT6: ((SERVER ? CLIENT) BLOCK0) ? STMT7;                                                         #Client and Server Block
	 STMT7: (GLB* TYP VAR{ADDVAR} ((COM TYP VAR)+ -COM) (ASS EXPR0 ((COM EXPR0)+ -COM)* ? STMT8;        #Variable Defintion
	 STMT8: (VAR ((COM VAR)+ - COM) (ASS) EXPR0 ((COM EXPR0)+ -COM)) ? STMT9;                           #Assign Variable
	 STMT9: (VAR ((COM VAR)+ - COM) (AADD ? ADIV ? AMUL ? ADIV) EXPR0 ((COM EXPR0)+ -COM)) ? STMT9;     #Arithmatic Assignments
	STMT10: (DLG TYP VAR PRMS0 LCB RET NUM SEP* RCB) ? STMT11;                                          #Define Delegate
	STMT11: (FUN TYP VAR PRMS1 BLOCK0) ? STMT12;                                                        #Define USer Function
	STMT12: (RET EXPR0)+ ? STMT13;                                                                      #Return
	STMT13: CONT ? STMT14;                                                                              #Continue
	STMT14: BRK ? STMT15;                                                                               #Break
	STMT15: (EXPR0 ? EXPR_ERROR) STMT16;                                                                #Expression or Error
	SMMT16: (PRD VAR ASS EXPR0) ? STMT17;                                                               #Trailing - Set Atribute;
	SMMT17: (LSB (COM TYP)* RSB) ? STMT_ERROR;                                                          #Trailing - Set Feild;

	STMT18: CLS TYP{ADDCLASS} (EXT TYP)* CB STMTS1 RCB;                                                 #Define User Class
	STMT19: (TYP[!=string] PRMS1 BLOCK0) ? STMT20;                                                      #User class constructor
	STMT20: (METH TYP VAR PRMS1 BLOCK) ? STMT21;                                                        #User class constructor
	STMT21: (TYP[=string] PRMS1 BLOCK0);                                                                #define user class to string

	 DIR1: (DIR VAR[=name] STR) ? DIR2;                                                                 #Name Directive
	 DIR2: (DIR VAR[=model] STR) ? DIR3;                                                                #Model Directive
	 DIR3: (DIR VAR[=include] STR);                                                                     #Include Directive
	 DIR4: (DIR VAR[=input] TYP VAR ((COM VAR)+ -COM)* ? DIR5;                                          #Input Directive
	 DIR4: (DIR VAR[=output] TYP VAR ((COM VAR)+ -COM)* ? DIR5;                                         #Output Directive

	 EXPR0: (LPA EXPR1 RPA) ? EXPR1;                                                                    #Group Equation
	 EXPR1: (CST EXPR1) ? EXPR2;                                                                        #Casting
	 EXPR2: (EXPR3 QSM EXPR0 TEN EXPR0) ? EXPR3;                                                        #Tinary
	 EXPR3: (EXPR4 (OR ? AND) EXPR0) ? EXPR4;                                                           #Logic
	 EXPR4: (EXPR5 (EQ ? NEQ ? GTH ? LTH ? GTHEQ ? LTHEQ) EXPR0) ? EXPR5;                               #Comparison
	 EXPR5: (EXPR6 (ADD ? SUB ? DIV ? MUL ? EXP ? MOD) EXPR0) ? EXPR6;                                  #Arithmatic
	 EXPR6: (EXPR7 (BAND ? BOR ? BXOR ? BSL ? BSR) EXPR0) ? EXPR7;                                      #Binary
	 EXPR7: (EXPR8 IOF TYP) ? EXPR8;                                                                    #Instanceof
	 EXPR8: ((ADD ? NEG) EXPR9) ? EXPR9;                                                                #Identity and Negate
	 EXPR9: ((NOT ? LEN ? DLT) EXPR10) ? EXPR10;                                                        #Not, Lengh, Delta
	EXPR10: (LIB PRD VAR ARGS) ? EXPR11; #Library Function
	EXPR11: (EXPR12 (PRD VAR ARGS)+) ? EXPR12;                                                          #Method
	EXPR12: (EXPR13 (PRD VAR -ASS)+) ? EXPR13;                                                          #Get Atribute;
	EXPR13: (EXPR14 (LSB EXPR0 (COM TYP)* RSB - ASS)+) ? EXPR14;                                        #Get Feild
	EXPR14: (EXPR15 ARGS+) ? EXPR15;                                                                    #Call
	EXPR15: (NEW TYP ARGS) ? EXPR16;                                                                    #New Object
	EXPR16: (FUNC PRMS1 BLOCK0) ? EXPR17;                                                               #Inline Function
	EXPR17: (NUM ? STR ? TRU ? FLS ? NUL);                                                              #Raw Value

	PRMS0: LPA (TYP (COM TYP)+ -COM)* RPA;                                                              #Delegate Parameters
	PRMS1: LPA (TYP VAR (COM TYP VAR)+ -COM)* RPA;                                                      #Function Parameters
	ARGS: LPA (EXPR0 ((COM EXPR0)+ -COM)*)* RPA;
	CND: EXPR0                                                       #Function Arguments
]]

--[[
	ROOT
]]

function LEXER:ROOT()
	self:DIRS();
	self:STMTS0();
end

--[[
	BLOCK0
]]

function LEXER:BLOCK0()
	local seq;

	self:StartInstruction("STMT");

	if prefix then
		self:insertCode(prefix);
	end

	if self:acceptToken("LPA") then
		seq = self:STMTS0(true);
	else
		seq = self:STMT0();
	end

	if prefix then
		self:insertCode(postfix);
	end

	return self:EndInstruction();
end

--[[
	STMTS0
]]

function LEXER:STMTS0(rpa)
	local stmt;

	self:StartInstruction("SEQUENCE");

	while true do
		if rpa and self:checkToken("RPA") then
			break;
		end

		local s = self:STMT1();

		if not s then
			break;
		end

		if stmt then
			if stmt.line == s.line and not (self:acceptToken("SEP") or stmt.seperated) then
				self:Error("Sepperator (;) expected, betwen statements.");
			end

			if stmt.type == "RETURN" then
				self:Error("Unreachable code after, return statement.");
			elseif stmt.type == "BREAK" then
				self:Error("Unreachable code after, break.");
			elseif stmt.type == "CONTINUE" then
				self:Error("Unreachable code after, continue.");
			end
		end

		stmt = s;
	end

	return self:EndInstruction();
end

--[[
	STMTS1
]]

function LEXER:STMTS1()

end

--[[
	STMT0
]]

function LEXER:STMT0()
	while self:DIR4() do
		-- Nothing :D
	end

	if self:acceptToken("TRY") then
		self:StartInstruction();

		--Inject code :D
		self:insertCode("local ok, result = pcall(function()");

		self:PushScope();

		self:BLOCK0(nil, "end)");

		self:PopScope();

		self:insertLine("if not ok then");

		local catch = 0;

		while self:acceptToken("CTH") do
			self:RequireToken("LPA", "(() ) expected after catch");

			local class = self:RequireType("Class expected after (( )");

			local var = self:RequireToken("VAR", "Variable expected after %s.", Name(class));

			self:insertLine("elseif result and result.type ~= %s then");

			self:insertLine("local %s = result", var);

			self:PushScope();

			self:AssignMemory(var, class);

			self:BLOCK0(false, false);

			self:PushScope();
		end

		self:insertLine("end");

		return self:EndInstruction();
	end

	if not self:STMT1() then
		self:Error("Further input expected at end of code."):
	end
end

--[[
	STMT1
]]

function LEXER:STMT1()
	--(IF LPA CND RPA BLCOK0 (STMT2+)* STMT3*) ? STMT4;

	self:StartInstruction("IF");

	local accepted, cnd, block = self:checkSequence("IF", "LPA", "CND", "RPA", "BLOCK0");

	if not accepted then
		self:TerminateInstruction();
		return self:STMT4();
	end

	self:STMT2();

	return self:endInstruction();
end

--[[
	STMT2
]]

function LEXER:STMT2()
	self:StartInstruction("EIF");

	local accepted, cnd, block = self:checkSequence("EIF", "LPA", "CND", "RPA", "BLOCK0");

	if not accepted then return self:TerminateInstruction(); end

	local eif = self:STMT2();

	if not eif then eif = self:STMT3(); end

	return self:endInstruction();
end

--[[
	STMT3
]]

function LEXER:STMT3()
	self:StartInstruction("ELS");

	local accepted, block = self:checkSequence("EIF", "LPA", "CND", "RPA", "BLOCK0");

	if not accepted then return self:TerminateInstruction(); end

	return self:endInstruction();
end

--[[
	STMT4
]]

function LEXER:STMT4()
end

--[[
	STMT5
]]

function LEXER:STMT5()
end

--[[
	STMT6
]]

function LEXER:STMT6()
end

--[[
	STMT7
]]

function LEXER:STMT7()
end

--[[
	STMT8
]]

function LEXER:STMT8()
end

--[[
	STMT9
]]

function LEXER:STMT9()
end

--[[
	STMT10
]]

function LEXER:STMT10()
end

--[[
	STMT11
]]

function LEXER:STMT11()
end

--[[
	STMT12
]]

function LEXER:STMT12()
end

--[[
	STMT13
]]

function LEXER:STMT13()
end

--[[
	STMT14
]]

function LEXER:STMT14()
end

--[[
	STMT15
]]

function LEXER:STMT15()
end

--[[
	SMMT16
]]

function LEXER:SMMT16()
end

--[[
	SMMT17
]]

function LEXER:SMMT17()
end

--[[
	STMT18
]]

function LEXER:STMT18()
end

--[[
	STMT19
]]

function LEXER:STMT19()
end

--[[
	STMT20
]]

function LEXER:STMT20()
end

--[[
	STMT21
]]

function LEXER:STMT21()
end

--[[
	DIR1
]]

function LEXER:DIR1()
end

--[[
	DIR2
]]

function LEXER:DIR2()
end

--[[
	DIR3
]]

function LEXER:DIR3()
end

--[[
	DIR4: (DIR VAR[=input] TYP VAR ((COM VAR)+ -COM)* ? DIR5; 
]]

function LEXER:DIR4()
end

--[[
	DIR4
]]

function LEXER:DIR4()
end
--[[
	EXPR0
]]

function LEXER:EXPR0()
end

--[[
	EXPR1
]]

function LEXER:EXPR1()
end

--[[
	EXPR2
]]

function LEXER:EXPR2()
end

--[[
	EXPR3
]]

function LEXER:EXPR3()
end

--[[
	EXPR4
]]

function LEXER:EXPR4()
end

--[[
	EXPR5
]]

function LEXER:EXPR5()
end

--[[
	EXPR6
]]

function LEXER:EXPR6()
end

--[[
	EXPR7
]]

function LEXER:EXPR7()
end

--[[
	EXPR8
]]

function LEXER:EXPR8()
end

--[[
	EXPR9
]]

function LEXER:EXPR9()
end

--[[
	EXPR10
]]

function LEXER:EXPR10()
end

--[[
	EXPR11
]]

function LEXER:EXPR11()
end

--[[
	EXPR12
]]

function LEXER:EXPR12()
end

--[[
	EXPR13
]]

function LEXER:EXPR13()
end

--[[
	EXPR14
]]

function LEXER:EXPR14()
end

--[[
	EXPR15
]]

function LEXER:EXPR15()
end

--[[
	EXPR16
]]

function LEXER:EXPR16()
end

--[[
	EXPR17
]]

function LEXER:EXPR17()
end

--[[
	PRMS0
]]

function LEXER:PRMS0()
end

--[[
	PRMS1
]]

function LEXER:PRMS1()
end

--[[
	ARGS
]]

function LEXER:ARGS()
end

--[[
	CND
]]

function LEXER:CND()
	return self:getAsBoolean(self.EXPR0);
end

--[[
	UTIL
]]