
--[[
	KEYWORDS
]]

E3_RegisterKeyWord("if", "IF", "if");
E3_RegisterKeyWord("elseif", "EIF", "elseif");
E3_RegisterKeyWord("else", "ELS", "else");
E3_RegisterKeyWord("while", "WHL", "while");
E3_RegisterKeyWord("for", "FOR", "for");
E3_RegisterKeyWord("foreach", "EACH", "foreach");
E3_RegisterKeyWord("delegate", "DEL", "delegate");
E3_RegisterKeyWord("true", "TRU", "true");
E3_RegisterKeyWord("false", "FLS", "false");
E3_RegisterKeyWord("void", "VOID", "void");
E3_RegisterKeyWord("nil", "NUL", "nil");
E3_RegisterKeyWord("break", "BRK", "break");
E3_RegisterKeyWord("continue", "CNT", "continue");
E3_RegisterKeyWord("return", "RET", "return");
E3_RegisterKeyWord("global", "GLO", "global");
E3_RegisterKeyWord("server", "SV", "server");
E3_RegisterKeyWord("client", "CL", "client");
E3_RegisterKeyWord("new", "NEW", "constructor");
E3_RegisterKeyWord("try", "TRY", "try");
E3_RegisterKeyWord("catch", "CTH", "catch");
E3_RegisterKeyWord("class", "CLS", "class");
E3_RegisterKeyWord("method", "METH", "method");

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

E3_RegisterTokenFunction("SPACE", E3_PATTERN_SPACE, "Space");
E3_RegisterTokenFunction("CMT", E3_PATTERN_CMT, "Comment");
E3_RegisterTokenFunction("NUM", E3_PATTERN_NUM, "Number");
E3_RegisterTokenFunction("STR", E3_PATTERN_STR, "String");
E3_RegisterTokenFunction("TYP", E3_PATTERN_TYP, "Type");
E3_RegisterTokenFunction("CST", E3_PATTERN_CST, "Cast");
E3_RegisterTokenFunction("VAR", "^[a-zA-Z][a-zA-Z0-9_]*", "variable");

--[[
	PARSE FUNCTIONS
]]

E3_RegisterSyntaxFunction("INIT", E3_PARSE_INIT);
E3_RegisterSyntaxFunction("GETSTATE", E3_PARSE_GETSTATE);
E3_RegisterSyntaxFunction("SETSTATE", E3_PARSE_SETSTATE);
E3_RegisterSyntaxFunction("PUSH", E3_PARSE_PUSH);
E3_RegisterSyntaxFunction("POP", E3_PARSE_POP);
E3_RegisterSyntaxFunction("ADD_TYP", E3_PARSE_ADD_TYP);

--[[
	AST DATA
]]

E3_RegisterSyntax("ROOT", "DIRS1+* STMTS0", E3_COMPILE_ROOT, "Root of code");
E3_RegisterSyntax("BLOCK0", "(LCB{PUSH} STMTS0 RCB{POP}) ? STMT0", E3_COMPILE_BLOCK0, "Code Block");
E3_RegisterSyntax("STMTS0", "STMT18 ? STMT0+*", E3_COMPILE_STMTS0, "Statements");
E3_RegisterSyntax("STMTS1", "(STMT19+)*", E3_COMPILE_STMTS1, "Class Statements");
E3_RegisterSyntax("STMT0", "DIR4 ? (TRY BLOCK0 CTC LPA VAR RPA BLOCK0) ? STMT1", E3_COMPILE_STMT0, "Try Catch");
E3_RegisterSyntax("STMT1", "(IF LPA CND RPA BLOCK0 (STMT2+)* STMT3*) ? STMT4", E3_COMPILE_STMT1, "If Statement");
E3_RegisterSyntax("STMT2", "(EIF LPA CND RPA BLOCK0)", E3_COMPILE_STMT2, "Esleif Statement");
E3_RegisterSyntax("STMT3", "(ELSE BLOCK0)*", E3_COMPILE_STMT3, "Else Statement");
E3_RegisterSyntax("STMT4", "(FOR LPA TYPE ASS EXPR0 SEP EXPR0 (SEP EXPR0)* RPA BLOCK0) ? STMT5", E3_COMPILE_STMT4, "For Loop");
E3_RegisterSyntax("STMT5", "(WHILE CND BLOCK0) ? STMT6", E3_COMPILE_STMT5, "While Loop");
E3_RegisterSyntax("STMT6", "((SERVER ? CLIENT) BLOCK0) ? STMT7", E3_COMPILE_STMT6, "Client and Server Block");
E3_RegisterSyntax("STMT7", "GLB* TYP VAR ((COM TYP VAR)+ -COM) (ASS EXPR0 (COM EXPR0)+ -COM)* ? STMT8", E3_COMPILE_STMT7, "Variable Defintion");
E3_RegisterSyntax("STMT8", "(VAR ((COM VAR)+ - COM) (ASS) EXPR0 ((COM EXPR0)+ -COM)) ? STMT9", E3_COMPILE_STMT8, "Assign Variable");
E3_RegisterSyntax("STMT9", "(VAR ((COM VAR)+ - COM) (AADD ? ADIV ? AMUL ? ADIV) EXPR0 ((COM EXPR0)+ -COM)) ? STMT10", E3_COMPILE_STMT9, "Arithmatic Assignments");
E3_RegisterSyntax("STMT10", "(DLG TYP VAR PRMS0 LCB RET NUM SEP* RCB) ? STMT11", E3_COMPILE_STMT10, "Define Delegate");
E3_RegisterSyntax("STMT11", "(FUN TYP VAR PRMS1 BLOCK0) ? STMT12", E3_COMPILE_STMT11, "Define User Function");
E3_RegisterSyntax("STMT12", "(RET EXPR0)+ ? STMT13", E3_COMPILE_STMT12, "Return");
E3_RegisterSyntax("STMT13", "CONT ? STMT14", E3_COMPILE_STMT13, "Continue");
E3_RegisterSyntax("STMT14", "BRK ? STMT15", E3_COMPILE_STMT14, "Break");
E3_RegisterSyntax("STMT15", "(EXPR0 ? EXPR_ERROR) STMT16", E3_COMPILE_STMT15, "Expression or Error");
E3_RegisterSyntax("SMMT16", "(PRD VAR ASS EXPR0) ? STMT17", E3_COMPILE_STMT16, "Trailing - Set Atribute");
E3_RegisterSyntax("SMMT17", "(LSB (COM TYP)* RSB) ? STMT_ERROR", E3_COMPILE_STMT17, "Trailing - Set Feild");
E3_RegisterSyntax("STMT18", "CLS VAR{ADD_TYP} (EXT TYP)* CB STMTS1 RCB", E3_COMPILE_STMT18, "Define User Class");
E3_RegisterSyntax("STMT19", "(TYP{!=string} PRMS1 BLOCK0) ? STMT20", E3_COMPILE_STMT19, "User class constructor");
E3_RegisterSyntax("STMT20", "(METH TYP VAR PRMS1 BLOCK) ? STMT21", E3_COMPILE_STMT20, "User class constructor");
E3_RegisterSyntax("STMT21", "(TYP{=string} PRMS1 BLOCK0)", E3_COMPILE_STMT21, "define user class to string");
E3_RegisterSyntax("DIR1", "(DIR VAR{=name} STR) ? DIR2", E3_COMPILE_DIR1, "Name Directive");
E3_RegisterSyntax("DIR2", "(DIR VAR{=model} STR) ? DIR3", E3_COMPILE_DIR2, "Model Directive");
E3_RegisterSyntax("DIR3", "(DIR VAR{=include} STR)", E3_COMPILE_DIR3, "Include Directive");
E3_RegisterSyntax("DIR4", "(DIR VAR{=input} TYP VAR (COM VAR)+ -COM)* ? DIR5", E3_COMPILE_DIR4, "Input Directive");
E3_RegisterSyntax("DIR4", "(DIR VAR{=output} TYP VAR (COM VAR)+ -COM)* ? DIR5", E3_COMPILE_DIR5, "Output Directive");
E3_RegisterSyntax("EXPR0", "(LPA EXPR1 RPA) ? EXPR1", E3_COMPILE_EXPR0, "Group Equation");
E3_RegisterSyntax("EXPR1", "(CST EXPR1) ? EXPR2", E3_COMPILE_EXPR1, "Casting");
E3_RegisterSyntax("EXPR2", "(EXPR3 QSM EXPR0 TEN EXPR0) ? EXPR3", E3_COMPILE_EXPR2, "Tinary");
E3_RegisterSyntax("EXPR3", "(EXPR4 (OR ? AND) EXPR0) ? EXPR4", E3_COMPILE_EXPR3, "Logic");
E3_RegisterSyntax("EXPR4", "(EXPR5 (EQ ? NEQ ? GTH ? LTH ? GTHEQ ? LTHEQ) EXPR0) ? EXPR5", E3_COMPILE_EXPR4, "Comparison");
E3_RegisterSyntax("EXPR5", "(EXPR6 (ADD ? SUB ? DIV ? MUL ? EXP ? MOD) EXPR0) ? EXPR6", E3_COMPILE_EXPR5, "Arithmatic");
E3_RegisterSyntax("EXPR6", "(EXPR7 (BAND ? BOR ? BXOR ? BSL ? BSR) EXPR0) ? EXPR7", E3_COMPILE_EXPR6, "Binary");
E3_RegisterSyntax("EXPR7", "(EXPR8 IOF TYP) ? EXPR8", E3_COMPILE_EXPR7, "Instanceof");
E3_RegisterSyntax("EXPR8", "((ADD ? NEG) EXPR9) ? EXPR9", E3_COMPILE_EXPR8, "Identity and Negate");
E3_RegisterSyntax("EXPR9", "((NOT ? LEN ? DLT) EXPR10) ? EXPR10", E3_COMPILE_EXPR9, "Not, Lengh, Delta");
E3_RegisterSyntax("EXPR10", "(LIB PRD VAR ARGS) ? EXPR11", E3_COMPILE_EXPR10, "Library Function");
E3_RegisterSyntax("EXPR11", "(EXPR12 (PRD VAR ARGS)+) ? EXPR12", E3_COMPILE_EXPR11, "Method");
E3_RegisterSyntax("EXPR12", "(EXPR13 (PRD VAR -ASS)+) ? EXPR13", E3_COMPILE_EXPR12, "Get Atribute");
E3_RegisterSyntax("EXPR13", "(EXPR14 (LSB EXPR0 (COM TYP)* RSB - ASS)+) ? EXPR14", E3_COMPILE_EXPR13, "Get Feild");
E3_RegisterSyntax("EXPR14", "(EXPR15 ARGS+) ? EXPR15", E3_COMPILE_EXPR14, "Call");
E3_RegisterSyntax("EXPR15", "(NEW TYP ARGS) ? EXPR16", E3_COMPILE_EXPR15, "New Object");
E3_RegisterSyntax("EXPR16", "(FUNC PRMS1 BLOCK0) ? EXPR17", E3_COMPILE_EXPR16, "Inline Function");
E3_RegisterSyntax("EXPR17", "(NUM ? STR ? TRU ? FLS ? NUL)", E3_COMPILE_EXPR17, "Raw Value");
E3_RegisterSyntax("PRMS0", "LPA (TYP (COM TYP)+ -COM)* RPA", E3_COMPILE_PRMS0, "Delegate Parameters");
E3_RegisterSyntax("PRMS1", "LPA (TYP VAR (COM TYP VAR)+ -COM)* RPA", E3_COMPILE_PRMS1, "Function Parameters");
E3_RegisterSyntax("ARGS", "LPA (EXPR0 ((COM EXPR0)+ -COM)*)* RPA", E3_COMPILE_ARGS, "Argument");
E3_RegisterSyntax("CND", "EXPR0", E3_COMPILE_CND, "Codiniton");
