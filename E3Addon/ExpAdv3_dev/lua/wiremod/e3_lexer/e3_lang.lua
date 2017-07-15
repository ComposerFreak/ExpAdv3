
--[[
	KEYWORDS
]]

E3_RegisterKeyWord("IF", "if", "if");
E3_RegisterKeyWord("ELSEIF", "eif", "elseif");
E3_RegisterKeyWord("ELSE", "els", "else");
E3_RegisterKeyWord("WHILE", "whl", "while");
E3_RegisterKeyWord("FOR", "for", "for");
E3_RegisterKeyWord("FOREACH", "each", "foreach");
E3_RegisterKeyWord("DELEGATE", "del", "delegate");
E3_RegisterKeyWord("TRUE", "tre", "true");
E3_RegisterKeyWord("FALSE", "fls", "false");
E3_RegisterKeyWord("VOID", "void", "void");
E3_RegisterKeyWord("BREAK", "brk", "break");
E3_RegisterKeyWord("CONTINUE", "cnt", "continue");
E3_RegisterKeyWord("RETURN", "ret", "return");
E3_RegisterKeyWord("GLOBAL", "glo", "global");
E3_RegisterKeyWord("SERVER", "sv", "server");
E3_RegisterKeyWord("CLIENT", "cl", "client");
E3_RegisterKeyWord("NEW", "new", "constructor");
E3_RegisterKeyWord("TRY", "try", "try");
E3_RegisterKeyWord("CATCH", "cth", "catch");
E3_RegisterKeyWord("CLASS", "cls", "class");
E3_RegisterKeyWord("METHOD", "meth", "method");

--[[
	TOKENS
]]

E3_RegisterToken("+",   "ADD", "addition");
E3_RegisterToken("-",   "SUB", "subtract");
E3_RegisterToken("*",   "MUL", "multiplier");
E3_RegisterToken("/",   "DIV", "division");
E3_RegisterToken("%",   "MOD", "modulus");
E3_RegisterToken("^",   "EXP", "power");
E3_RegisterToken("=",   "ASS", "assign");
E3_RegisterToken("+=",  "AADD", "increase");
E3_RegisterToken("-=",  "ASUB", "decrease");
E3_RegisterToken("*=",  "AMUL", "multiplier");
E3_RegisterToken("/=",  "ADIV", "division");
E3_RegisterToken("++",  "INC", "increment");
E3_RegisterToken("--",  "DEC", "decrement");
E3_RegisterToken("==",  "EQ", "equal");
E3_RegisterToken("!=",  "NEQ", "unequal");
E3_RegisterToken("<",   "LTH", "less");
E3_RegisterToken("<=",  "LEQ", "less or equal");
E3_RegisterToken(">",   "GTH", "greater");
E3_RegisterToken(">=",  "GEQ", "greater or equal");
E3_RegisterToken("&",   "BAND", "and");
E3_RegisterToken("|",   "BOR", "or");
E3_RegisterToken("^^",  "BXOR", "or");
E3_RegisterToken(">>",  "BSHR", ">>");
E3_RegisterToken("<<",  "BSHL", "<<");
E3_RegisterToken("!",   "NOT", "not");
E3_RegisterToken("&&",  "AND", "and");
E3_RegisterToken("||",  "OR", "or");
E3_RegisterToken("?",   "QSM", "?");
E3_RegisterToken(":",   "COL", "colon");
E3_RegisterToken(";",   "SEP", "semicolon");
E3_RegisterToken(",",   "COM", "comma");
E3_RegisterToken("$",   "DLT", "delta");
E3_RegisterToken("#",   "LEN", "length");
E3_RegisterToken("~",   "CNG", "changed");
E3_RegisterToken(".",   "PRD", "period");
E3_RegisterToken("(",   "LPA", "left parenthesis");
E3_RegisterToken(")",   "RPA", "right parenthesis");
E3_RegisterToken("{",   "LCB", "left curly bracket");
E3_RegisterToken("}",   "RCB", "right curly bracket");
E3_RegisterToken("[",   "LSB", "left square bracket");
E3_RegisterToken("]",   "RSB", "right square bracket");
E3_RegisterToken('@',   "DIR", "directive operator");
E3_RegisterToken("...", "VARG", "varargs");

--[[
	PATERNS
]]

E3_PATTERNS = {};

function E3_RegisterPattern(name, paterns, func, desc)
	E3_PATTERNS[name] = {paterns, func};
end

E3_RegisterPattern("CMT", E3_PATTERN_CMT, nil, "Comment");
E3_RegisterPattern("NUM", E3_PATTERN_NUM, nil, "Number");
E3_RegisterPattern("STR", E3_PATTERN_STR, nil, "String");
E3_RegisterPattern("TYP", E3_PATTERN_TYP, nil, "Type");

--[[
	PARSE FUNCTIONS
]]

E3_RegisterSyntaxFunction("PUSH", E3_PARSE_PUSH);
E3_RegisterSyntaxFunction("POP", E3_PARSE_POP);
E3_RegisterSyntaxFunction("ADD_TYP", E3_PARSE_ADD_TYP);

--[[
	AST DATA
]]

E3_RegisterSyntax("ROOT", "DIRS1+* STMTS0", COMPILE_ROOT, "Root of code");
E3_RegisterSyntax("BLOCK0", "(LCB{PUSH} STMTS0 RCB{POP}) ? STMT0", COMPILE_BLOCK0, "Code Block");
E3_RegisterSyntax("STMTS0", "STMT18 ? (STMT0+)*", COMPILE_STMTS0, "RStatements");
E3_RegisterSyntax("STMTS1", "(STMT19+)*", COMPILE_STMTS1, "Class Statements");
E3_RegisterSyntax("STMT0", "DIR4 ? (TRY BLOCK0 CTC LPA VAR RPA BLOCK0) ? STMT1", COMPILE_STMT0, "Try Catch");
E3_RegisterSyntax("STMT1", "(IF LPA CND RPA BLCOK0 (STMT2+)* STMT3*) ? STMT4", COMPILE_STMT1, "If Statement");
E3_RegisterSyntax("STMT2", "(EIF LPA CND RPA BLOCK0)", COMPILE_STMT2, "Esleif Statement");
E3_RegisterSyntax("STMT3", "(ELSE BLOCK0)*", COMPILE_STMT3, "Else Statement");
E3_RegisterSyntax("STMT4", "(FOR LPA TYPE ASS EXPR0 SEP EXPR0 (SEP EXPR0)* RPA BLOCK0) ? STMT5", COMPILE_STMT4, "For Loop");
E3_RegisterSyntax("STMT5", "(WHILE CND BLOCK0) ? STMT6", COMPILE_STMT5, "While Loop");
E3_RegisterSyntax("STMT6", "((SERVER ? CLIENT) BLOCK0) ? STMT7", COMPILE_STMT6, "Client and Server Block");
E3_RegisterSyntax("STMT7", "GLB* TYP VAR ((COM TYP VAR)+ -COM) (ASS EXPR0 (COM EXPR0)+ -COM)* ? STMT8", COMPILE_STMT7, "Variable Defintion");
E3_RegisterSyntax("STMT8", "(VAR ((COM VAR)+ - COM) (ASS) EXPR0 ((COM EXPR0)+ -COM)) ? STMT9", COMPILE_STMT8, "Assign Variable");
E3_RegisterSyntax("STMT9", "(VAR ((COM VAR)+ - COM) (AADD ? ADIV ? AMUL ? ADIV) EXPR0 ((COM EXPR0)+ -COM)) ? STMT10", COMPILE_STMT9, "Arithmatic Assignments");
E3_RegisterSyntax("STMT10", "(DLG TYP VAR PRMS0 LCB RET NUM SEP* RCB) ? STMT11", COMPILE_STMT10, "Define Delegate");
E3_RegisterSyntax("STMT11", "(FUN TYP VAR PRMS1 BLOCK0) ? STMT12", COMPILE_STMT11, "Define User Function");
E3_RegisterSyntax("STMT12", "(RET EXPR0)+ ? STMT13", COMPILE_STMT12, "Return");
E3_RegisterSyntax("STMT13", "CONT ? STMT14", COMPILE_STMT13, "Continue");
E3_RegisterSyntax("STMT14", "BRK ? STMT15", COMPILE_STMT14, "Break");
E3_RegisterSyntax("STMT15", "(EXPR0 ? EXPR_ERROR) STMT16", COMPILE_STMT15, "Expression or Error");
E3_RegisterSyntax("SMMT16", "(PRD VAR ASS EXPR0) ? STMT17", COMPILE_STMT16, "Trailing - Set Atribute");
E3_RegisterSyntax("SMMT17", "(LSB (COM TYP)* RSB) ? STMT_ERROR", COMPILE_STMT17, "Trailing - Set Feild");
E3_RegisterSyntax("STMT18", "CLS VAR{ADD_TYP} (EXT TYP)* CB STMTS1 RCB", COMPILE_STMT18, "Define User Class");
E3_RegisterSyntax("STMT19", "(TYP{!=string} PRMS1 BLOCK0) ? STMT20", COMPILE_STMT19, "User class constructor");
E3_RegisterSyntax("STMT20", "(METH TYP VAR PRMS1 BLOCK) ? STMT21", COMPILE_STMT20, "User class constructor");
E3_RegisterSyntax("STMT21", "(TYP{=string} PRMS1 BLOCK0)", COMPILE_STMT21, "define user class to string");
E3_RegisterSyntax("DIR1", "(DIR VAR{=name} STR) ? DIR2", COMPILE_DIR1, "Name Directive");
E3_RegisterSyntax("DIR2", "(DIR VAR{=model} STR) ? DIR3", COMPILE_DIR2, "Model Directive");
E3_RegisterSyntax("DIR3", "(DIR VAR{=include} STR)", COMPILE_DIR3, "Include Directive");
E3_RegisterSyntax("DIR4", "(DIR VAR{=input} TYP VAR (COM VAR)+ -COM)* ? DIR5", COMPILE_DIR4, "Input Directive");
E3_RegisterSyntax("DIR4", "(DIR VAR{=output} TYP VAR (COM VAR)+ -COM)* ? DIR5", COMPILE_DIR5, "Output Directive");
E3_RegisterSyntax("EXPR0", "(LPA EXPR1 RPA) ? EXPR1", COMPILE_EXPR0, "Group Equation");
E3_RegisterSyntax("EXPR1", "(CST EXPR1) ? EXPR2", COMPILE_EXPR1, "Casting");
E3_RegisterSyntax("EXPR2", "(EXPR3 QSM EXPR0 TEN EXPR0) ? EXPR3", COMPILE_EXPR2, "Tinary");
E3_RegisterSyntax("EXPR3", "(EXPR4 (OR ? AND) EXPR0) ? EXPR4", COMPILE_EXPR3, "Logic");
E3_RegisterSyntax("EXPR4", "(EXPR5 (EQ ? NEQ ? GTH ? LTH ? GTHEQ ? LTHEQ) EXPR0) ? EXPR5", COMPILE_EXPR4, "Comparison");
E3_RegisterSyntax("EXPR5", "(EXPR6 (ADD ? SUB ? DIV ? MUL ? EXP ? MOD) EXPR0) ? EXPR6", COMPILE_EXPR5, "Arithmatic");
E3_RegisterSyntax("EXPR6", "(EXPR7 (BAND ? BOR ? BXOR ? BSL ? BSR) EXPR0) ? EXPR7", COMPILE_EXPR6, "Binary");
E3_RegisterSyntax("EXPR7", "(EXPR8 IOF TYP) ? EXPR8", COMPILE_EXPR7, "Instanceof");
E3_RegisterSyntax("EXPR8", "((ADD ? NEG) EXPR9) ? EXPR9", COMPILE_EXPR8, "Identity and Negate");
E3_RegisterSyntax("EXPR9", "((NOT ? LEN ? DLT) EXPR10) ? EXPR10", COMPILE_EXPR9, "Not, Lengh, Delta");
E3_RegisterSyntax("EXPR10", "(LIB PRD VAR ARGS) ? EXPR11", COMPILE_EXPR10, "Library Function");
E3_RegisterSyntax("EXPR11", "(EXPR12 (PRD VAR ARGS)+) ? EXPR12", COMPILE_EXPR11, "Method");
E3_RegisterSyntax("EXPR12", "(EXPR13 (PRD VAR -ASS)+) ? EXPR13", COMPILE_EXPR12, "Get Atribute");
E3_RegisterSyntax("EXPR13", "(EXPR14 (LSB EXPR0 (COM TYP)* RSB - ASS)+) ? EXPR14", COMPILE_EXPR13, "Get Feild");
E3_RegisterSyntax("EXPR14", "(EXPR15 ARGS+) ? EXPR15", COMPILE_EXPR14, "Call");
E3_RegisterSyntax("EXPR15", "(NEW TYP ARGS) ? EXPR16", COMPILE_EXPR15, "New Object");
E3_RegisterSyntax("EXPR16", "(FUNC PRMS1 BLOCK0) ? EXPR17", COMPILE_EXPR16, "Inline Function");
E3_RegisterSyntax("EXPR17", "(NUM ? STR ? TRU ? FLS ? NUL)", COMPILE_EXPR17, "Raw Value");
E3_RegisterSyntax("PRMS0", "LPA (TYP (COM TYP)+ -COM)* RPA", COMPILE_PRMS0, "Delegate Parameters");
E3_RegisterSyntax("PRMS1", "LPA (TYP VAR (COM TYP VAR)+ -COM)* RPA", COMPILE_PRMS1, "Function Parameters");
E3_RegisterSyntax("ARGS", "LPA (EXPR0 ((COM EXPR0)+ -COM)*)* RPA", COMPILE_ARGS, "Argument");
E3_RegisterSyntax("CND", "EXPR0", COMPILE_CND, "Codiniton");