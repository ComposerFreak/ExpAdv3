local LEXER = {};
LEXER.__index = LEXER;

function LEXER.__call(tokens, files, compiler) 
	return setmetatable({tokens = tokens, files = files}, LEXER).Init();
end

--[[
	INIT
]]

function LEXER:Init()
	self.buffer = {};
end

--[[
	PUSH SCOPE / POP SCOPE
]]

--[[
	GET STAT / SET STATE
]]

--[[
	GET MEMORY / SET MEMORY
]]

--[[
	START CLASS / END CLASS
]]

--[[
	ERROR / REQUIRE
]]

--[[
	NEXT TOKEN / SKIP TOKEN
]]

--[[
	CHECK SEQUENCE / ACCEPT TOKEN
]]

--[[
	START INSTRUCTION / END INSTRUCTION
]]

--[[
	INSERT CODE
]]

--[[

]]

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
	STMTS0: (STMT18 ? (STMT0+)*;                                                                        #Regular Statments (STMT0 - SMST17)
	STMTS1: (STMT19+)*;                                                                                 #Class Statments (STMT19+)

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
	 EXPR7: (EXPR8 IOF TYP) ? EXPR8;                                                                    #Instaceof
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

	PRMS0: LPA (TYP (COM TYP)+ -COM)* RPA;                                                              #Delegate Peramaters
	PRMS1: LPA (TYP VAR (COM TYP VAR)+ -COM)* RPA;                                                      #Function Peramaters
	ARGS: LPA (EXPR0 ((COM EXPR0)+ -COM)*)* RPA;                                                        #Function Arguments
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

function LEXER:BLOCK0(prefix, postfix)
	local seq;

	self:StartInstruction("STMT");

	self:PushScope();

	if prefix then
		self:InsertCode(prefix);
	end

	if self:AcceptToken("LPA") then
		seq = self:STMTS0("RPA")
	else
		seq = self:STMT0();
	end

	if prefix then
		self:InsertCode(postfix);
	end

	self:PopScope();

	return self:EndInstruction();
end

--[[
	STMTS0
]]

function LEXER:STMTS0(rpa)
	local stmt;

	self:StartInstruction("SEQUENCE");

	while true do
		if rpa and self:CheckToken("RPA") then
			break;
		end

		local s = self:STMT1();

		if not s then
			break;
		end

		if stmt then
			if stmt.line == s.line and not (self:AcceptToken("SEP") or stmt.seperated) then
				self:Error("Sepperator (;) expected, betwen statments.");
			end

			if stmt.type == "RETURN" then
				self:Error("Unreachable code after, return statment.");
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
	
	if self:AcceptToken("TRY") then
		self:StartInstruction();

		--Inject code :D
		self:InsertCode("local ok, status = pcall(function()");

		self:BLOCK0(nil, "end)");

		
		return self:EndInstruction();
	end

	if not self:STMT1() then
		self:Error("Furth input expected at end of code."):
	end
end

--[[
	STMT1
]]

function LEXER:STMT1()
end

--[[
	STMT2
]]

function LEXER:STMT2()
end

--[[
	STMT3
]]

function LEXER:STMT3()
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
	DIR4
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
