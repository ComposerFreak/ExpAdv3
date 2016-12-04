--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Base Parser::
	```````````````
	A parser is the logical structure used to turn tokens into instructions that.
	
	:::Syntax Grammar:::
	```````````````````
		I have based this off the one from E2.

		:::Key:::
		* ε is the end-of-file
		* E? matches zero or one occurrences of T (and will always match one if possible)
		* E* matches zero or more occurrences of T (and will always match as many as possible)
		* E F matches E (and then whitespace) and then F
		* E / F tries matching E, if it fails it matches F (from the start location)
		* &E matches E, but does not consume any input.
		* !E matches everything except E, and does not consume any input.
		
		:::Root:::
			Root ← Stmt1((";" / " ") Stmt1)* ε

		:::Statments:::
			Stmt1 ← ("if" Cond Block Stmt2)? Stmt4
			Stmt2 ← ("elseif" Cond Block Stmt2)? Stmt3
			Stmt3 ← ("else" Block)
			Stmt4 ← ("for" "(" Type "=" Expr1 ")" Block)? Stmt5
			Stmt5 ← (("server" / "client") Block)? Stmt6
			Stmt6 ← "global"? (type (Var("," Var)* "="? (Expr1? ("," Expr1)*)))? Stmt7
			Stmt7 ← (type (Var("," Var)* ("=" / "+=" / "-=" / "/=" / "*=")? (Expr1? ("," Expr1)*)))? Stmt8
			Stmt8 ← ("delegate" "(" (Type ((",")?)*)?) ")" ("{")? "return" Num ("}")?)? Stmt9
			Stmt9 ← ("return" (Expr1 ((","")?)*)?)?)?

		:::Expressions:::
			Expr1 ← (Expr1 "?" Expr1 ":" Expr1)? Expr2
			Expr2 ← (Expr3 "||" Expr3)? Expr3
			Expr3 ← (Expr4 "&&" Expr4)? Expr4
			Expr4 ← (Expr5 "^^" Expr5)? Expr5
			Expr5 ← (Expr6 "|" Expr6)? Expr6
			Expr6 ← (Expr7 "&" Expr7)? Expr7
			Expr7 ← (Expr8 ("==" / "!=") (Values / Expr1))? Expr8
			Expr8 ← (Epxr9 (">" / "<" / " >=" / "<=") Expr1)? Expr9
			Expr9 ← (Epxr10 "<<" Expr10)? Expr10
			Expr10 ← (Epxr11 ">>" Expr11)? Expr11
			Expr11 ← (Epxr12 "+" Expr12)? Expr12
			Expr12 ← (Epxr13 "-" Expr13)? Expr13
			Expr13 ← (Epxr14 "/" Expr14)? Expr14
			Expr14 ← (Epxr15 "*" Expr15)? Expr15
			Expr15 ← (Epxr16 "^" Expr16)? Expr16
			Expr16 ← (Epxr17 "%" Expr17)? Expr17
			Expr17 ← ("+" Expr22)? Exp18
			Expr18 ← ("-" Expr22)? Exp19
			Expr19 ← ("!" Expr22)? Expr20
			Expr20 ← ("#" Expr22)? Expr21
			Expr21 ← ("("type")" Expr1)? Expr22
			Expr22 ← ("(" Expr1 ")" (Trailing)?)? Expr23
			Expr23 ← (Library "." Function  "(" (Expr1 ((",")?)*)?) ")")? Expr24
			Expr24 ← (Var (Trailing)?)? Expr25
			Expr25 ← ("new" Type "(" (Expr1 ((","")?)*)?) ")")? Expr25
			Expr26 ← ("Function" Perams Block1)? Expr27
			Expr27 ← Expr28? Error
			Expr28 ← (String / Number / "true" / "false", "void")?

		:::Syntax:::
			Cond 		← "(" Expr1 ")"
			Block 		← "{" (Stmt1 ((";" / " ") Stmt1)*)? "}"
			Values 		← "[" Expr1 ("," Expr1)* "]"
			Raw 		← (Str / Num / Bool)
			Trailing 	← (Method / Get /Call)?
			Method 		← (("." Method "(" (Expr1 ((","")?)*)?) ")")
			Get 		← ("[" Expr1 ("," Type)? "]")
			Call 		← ("(" (Expr1 ((","")?)*)?) ")")?
			Perams 		← ("(" (Type Var (("," Type Var)*)?)? ")")

]]

local PARSER = {};
PARSER.__index = PARSER;

function PARSER.New()
	return setmetatable({}, PARSER);
end

function PARSER.Initalize(this, instance)
	this.__pos = 0;
	this.__depth = 0;
	this.__scope = 0;
	this.__instructions = {};

	this.__token = instance.tokens[0];
	this.__next = instance.tokens[1];
	this.__total = #instance.tokens;
	this.__tokens = instance.tokens;
	this.__script = instance.script;

	this.__tasks = {};
end


function PARSER.Run(this)
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

function PARSER._Run(this)
	local result = {};
	result.instruction = this:Root();
	result.script = this.__script;
	result.tasks = this.__tasks
	result.tokens = this.__tokens;
	return result;
end

function PARSER.Throw(this, token, msg, fst, ...)
	local err = {};

	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	err.state = "parser";
	err.char = token.char;
	err.line = token.line;
	err.msg = msg;

	error(err,0);
end

--[[
]]

function PARSER.Next(this)
	this.__pos = this.__pos + 1;
	
	this.__token = this.__tokens[this.__pos];
	this.__next = this.__tokens[this.__pos + 1];

	if (this.__pos > this.__total) then
		return false;
	end

	return true;
end

function PARSER.HasTokens(this)
	return this.__next ~= nil;
end

function PARSER.CheckToken(this, type, ...)
	if (this.__pos < this.__total) then
		local tkn = this.__next;

		for _, t in pairs({type, ...}) do
			if (t == tkn.type) then
				return true;
			end
		end
	end

	return false;
end

function PARSER.Accept(this, type, ...)
	if (this:CheckToken(type, ...)) then
		this:Next();
		return true;
	end

	return false;
end

function PARSER.AcceptWithData(this, type, data)
	if (this:CheckToken(type) and this.__next.data == data) then
		this:Next();
		return true;
	end

	return false;
end

function PARSER.GetTokenData(this)
	return this.__token.data
end

function PARSER.GetToken(this, pos)
	if (pos >= this.__total) then
		return this.__tokens[pos];
	end
end

function PARSER.StepBackward(this, steps)
	
	if (not steps) then
		steps = 1;
	end

	local pos = this.__pos - (steps + 1);

	if (pos == 0) then
		this.__pos = 0;
		this.__token = this.__tokens[0];
		this.__next = this.__tokens[1];
		return;
	end

	if (pos > this.__total) then
		pos = this.__total;
	end

	this.__pos = pos;

	this:Next();
end

function PARSER.GetFirstTokenOnLine(this)
	for i = this.__pos, 1, -1 do
		local tkn = this.__tokens[i];

		if (tkn.newLine) then
			return tkn;
		end
	end

	return this.__tokens[1];
end

function PARSER.StatmentContains(this, token, type)
	local i = this.__pos;

	while (i < this.__total) do
		local tkn = this.__tokens[i];

		if (not tkn) then
			return;
		end

		if (tkn.type == "sep" or tkn.line ~= token.line) then
			return;
		end

		if (tkn.type == type) then
			return tkn;
		end

		i = i + 1;
	end
end

function PARSER.LastInStatment(this, token, type)
	local last;
	local i = token.index;

	while (i <= this.__total) do
		local tkn = this.__tokens[i];

		if (not tkn) then
			break;
		end

		if (tkn.type == "sep" or tkn.newLine) then
			break;
		end

		if (tkn.type == type) then
			last = tkn;
		end

		i = i + 1;
	end

	return last;
end

--[[
]]

function PARSER.Require( this, type, msg, ... )
	if (not this:Accept(type)) then
		this:Throw( this.__token, msg, ... )
	end
end

function PARSER.Exclude( this, tpye, msg, ... )
	if (this:Accept(type)) then
		this:Throw( this.__token, msg, ... )
	end
end

function PARSER.ExcludeWhiteSpace(this, msg, ...)
	if (not this:HasTokens()) then 
		this:Throw( this.__token, msg, ... )
	end
end

--[[
]]

function PARSER.StartInstruction(this, _type, token)
	if (not type(_type) == "string") then
		debug.Trace();
		error("PARSER:StartInstruction got bad instruction type.", _type);
	elseif (not type(token) == "table") then
		debug.Trace();
		error("PARSER:StartInstruction got bad instruction token.", token);
	end

	local inst = {};
	inst.type = _type;
	inst.result = "void";
	inst.rCount = 0;
	inst.token = token;
	inst.char = token.char;
	inst.line = token.line;
	inst.depth = this.__depth;
	inst.scope = this.__scope;
	this.__depth = this.__depth + 1;

	return inst;
end

function PARSER.QueueReplace(this, inst, token, str)
	local op = {};

	op.token = token;
	op.str = str;
	op.inst = inst;

	local tasks = this.__tasks[token.pos];

	if (not tasks) then
		tasks = {};
		this.__tasks[token.pos] = tasks;
	end

	tasks.replace = op;

	return op;
end

function PARSER.QueueRemove(this, inst, token)
	local op = {};

	op.token = token;
	op.inst = inst;

	local tasks = this.__tasks[token.pos];

	if (not tasks) then
		tasks = {};
		this.__tasks[token.pos] = tasks;
	end

	tasks.remove = op;

	return op;
end

function PARSER.QueueInjectionBefore(this, inst, token, str, ...)
	local tasks = this.__tasks[token.pos];

	if (not tasks) then
		tasks = {};
		this.__tasks[token.pos] = tasks;
	end

	if (not tasks.prefix) then
		tasks.prefix = {};
	end

	local t = {str, ...};

	for i = 1, #t do
		local op = {};
	
		op.token = token;
		op.str = t[i];
		op.inst = inst;

		tasks.prefix[#tasks.prefix + 1] = op;
	end

	return r;
end

function PARSER.QueueInjectionAfter(this, inst, token, str, ...)
	local op = {};
	
	op.token = token;
	op.str = str;
	op.inst = inst;

	local tasks = this.__tasks[token.pos];

	if (not tasks) then
		tasks = {};
		this.__tasks[token.pos] = tasks;
	end

	if (not tasks.postfix) then
		tasks.postfix = {};
	end

	local r = {};
	local t = {str, ...};

	for i = 1, #t do
		local op = {};
	
		op.token = token;
		op.str = t[i];
		op.inst = inst;

		r[#r + 1] = op;
		tasks.postfix[#tasks.postfix + 1] = op;
	end

	return r;
end

function PARSER.SetEndResults(this, inst, type, count)
	inst.type = type;
	inst.rCount = count or 1;
end

function PARSER.EndInstruction(this, inst, instructions)
	inst.instructions = instructions;

	inst.final = this.__token;

	this.__depth = this.__depth - 1;

	--print("PARSER->" .. inst.type .. "->#" .. #inst.instructions)

	return inst;
end

--[[
]]

function PARSER.Root(this)
	local seq = this:StartInstruction("seq", this.__tokens[1]);

	local stmts = this:Statments(false);

	return this:EndInstruction(seq, stmts);
end

function PARSER.Block_1(this, _end, lcb)
	this:ExcludeWhiteSpace( "Further input required at end of code, incomplete statement" )
	
	if (this:Accept("lcb")) then
		
		local seq = this:StartInstruction("seq", this.__token);

		if (lcb) then
			this:QueueReplace(seq, this.__token, lcb);
		end

		this.__scope = this.__scope + 1;

		local stmts = this:Statments(true);

		this.__scope = this.__scope - 1;

		if (not this:Accept("rcb")) then
			this:Throw(this.__token, "Right curly bracket (}) missing, to close block");
		end
		
		this:QueueReplace(seq, this.__token, _end and "end" or "");

		return this:EndInstruction(seq, stmts);
	end

	do
		local seq = this:StartInstruction("seq", this.__next);

		if (lcb) then
			this:QueueInjectionAfter(seq, this.__token, lcb);
		end

		this.__scope = this.__scope + 1;

		local stmt = this:Statment_1();

		this.__scope = this.__scope - 1;

		if (_end) then
			this:QueueInjectionAfter(seq, stmt.final, "end");
		end

		return this:EndInstruction(seq, { stmt });
	end
end

function PARSER.Statments(this, block)
	local sep = false;
	local stmts = {};

		while true do

			local stmt = this:Statment_1();

			stmts[#stmts + 1] = stmt;

			local seperated = this:Accept("sep");

			if (not stmt) then
				break;
			end

			if (block and this:CheckToken("rcb")) then
				break;
			end

			if (not this:HasTokens()) then
				break;
			end

			local pre = stmts[#stmts - 1];

			if (pre) then
				if (pre.line == stmt.line and not sep) then
					this:Throw(stmt.token, "Statements must be separated by semicolon (;) or newline")
				end
			end

			if (stmt.type == "return") then
				this:Throw(stmt.final, "Statement can not appear after return.")
			elseif (stmt.type == "continue") then
				this:Throw(stmt.final, "Statement can not appear after continue.")
			elseif (stmt.type == "break") then
				this:Throw(stmt.final, "Statement can not appear after break.")
			end

			sep = seperated;
		end

 	return stmts;
end

--[[
]]

function PARSER.Statment_1(this)
	if (this:Accept("if")) then
		local inst = this:StartInstruction("if", this.__token);

		inst.condition = this:GetCondition();
		
		inst.block = this:Block_1(false, "then");

		inst._else = this:Statment_2();

		this:QueueInjectionAfter(inst, this.__token, "end");

		return this:EndInstruction(inst, {});
	end

	return this:Statment_4();
end

function PARSER.Statment_2(this)
	if (this:Accept("eif")) then
		local inst = this:StartInstruction("elseif", this.__token);

		inst.condition = this:GetCondition();

		inst.block = this:Block_1(false, "then");

		inst._else = this:Statment_2();

		return this:EndInstruction(inst, {});
	end

	return this:Statment_3();
end

function PARSER.Statment_3(this)
	if (this:Accept("els")) then
		local inst = this:StartInstruction("else", this.__token);

		inst.block = this:Block_1(false, "");

		return this:EndInstruction(inst, {});
	end
end

--[[
]]


function PARSER.Statment_4(this)
	if (this:Accept("for")) then
		local inst = this:StartInstruction("for", this.__token);

		this:Require("lpa", "Left parenthesis (( ) expected after for.");

		this:QueueRemove(inst, this.__token);

		this:Require("typ", "Class expected for loop itorator");

		inst.class = this.__token.data;

		this:QueueRemove(inst, this.__token);

		this:Require("var", "Assigment expected for loop definition.");

		inst.variable = this.__token;

		this:Require("ass", "Assigment expected for loop definition.");

		inst.__ass = this.__token;

		local expressions = {};

		expressions[1] = this:Expression_1();

		this:Require("sep", "Seperator expected after loop decleration.");

		this:QueueReplace(inst, this.__token, (","));

		inst.__sep1 = this.__token;

		expressions[2] = this:Expression_1();

		if (this:Accept("sep")) then
			this:QueueReplace(inst, this.__token, (","));
			
			inst.__sep2 = this.__token;

			expressions[3] = this:Expression_1();
		end

		this:Require("rpa", "Right parenthesis ( )) expected to close cloop defintion.");

		this:QueueRemove(inst, this.__token);

		inst.stmts = this:Block_1(true, "do");

		return this:EndInstruction(inst, expressions);
	end

	return this:Statment_5();
end

function PARSER.Statment_5(this)
	if (this:Accept("sv")) then
		local inst = this:StartInstruction("server", this.__token);

		this:QueueInjectionBefore(inst, this.__token, "if");

		this:QueueReplace(inst, this.__token, "(SERVER)");

		inst.block = this:Block_1(true, "then");

		return this:EndInstruction(inst, {});
	end

	if (this:Accept("cl")) then
		local inst = this:StartInstruction("client", this.__token);

		this:QueueInjectionBefore(inst, this.__token, "if");

		this:QueueReplace(inst, this.__token, "(CLIENT)");

		inst.block = this:Block_1(true, "then");

		return this:EndInstruction(inst, {});
	end

	return this:Statment_6();
end

--[[
]]

function PARSER.Statment_6(this)
	if (this:Accept("glo")) then
		local inst = this:StartInstruction("global", this.__token);

		this:QueueRemove(inst, this.__token);

		this:Require("typ", "Class expected after global.");
		
		local type = this.__token.data;

		inst.class = type;

		this:QueueRemove(inst, this.__token);

		local variables = {};

		this:Require("var", "Variable('s) expected after class for global variable.");
		variables[1] = this.__token;
		--this:QueueInjectionBefore(inst, this.__token, "GLOBAL", ".");

		while (this:Accept("com")) do
			this:Require("var", "Variable expected after comma (,).");
			variables[#variables + 1] = this.__token;
			--this:QueueInjectionBefore(inst, this.__token, "GLOBAL", ".");
		end

		local expressions = {};

		if (this:Accept("ass")) then
			this:ExcludeWhiteSpace( "Assignment operator (=), must not be preceded by whitespace." );
			
			expressions[1] = this:Expression_1();

			while (this:Accept("com")) do
				this:ExcludeWhiteSpace( "comma (,) must not be preceded by whitespace." );
				expressions[#expressions + 1] = this:Expression_1();
			end
		end

		inst.variables = variables;

		return this:EndInstruction(inst, expressions);
	end

	if (this:Accept("typ")) then
		local inst = this:StartInstruction("local", this.__token);
		
		local type = this.__token.data;

		if (type == "f" and this:CheckToken("typ")) then
			this:StepBackward(1);
			return this:Statment_7()
		end

		this:QueueReplace(inst, this.__token, "local");

		inst.class = type;
		
		local variables = {};

		this:Require("var", "Variable('s) expected after class for variable.");
		variables[1] = this.__token;

		while (this:Accept("com")) do
			this:Require("var", "Variable expected after comma (,).");
			variables[#variables + 1] = this.__token;
		end
		
		local expressions = {};

		if (this:Accept("ass")) then
			this:ExcludeWhiteSpace( "Assignment operator (=), must not be preceded by whitespace." );
			
			expressions[1] = this:Expression_1();

			while (this:Accept("com")) do
				this:ExcludeWhiteSpace( "comma (,) must not be preceded by whitespace." );
				expressions[#expressions + 1] = this:Expression_1();
			end
		end

		inst.variables = variables;

		return this:EndInstruction(inst, expressions);
	end

	return this:Statment_7()
end

function PARSER.Statment_7(this)
	if (this:Accept("var")) then
		
		if (not this:CheckToken("com", "ass", "aadd", "asub", "adiv", "amul")) then
			this:StepBackward(1);
		else
			local inst = this:StartInstruction("ass", this.__token);
			
			local variables = {};
		
			variables[1] = this.__token;

			while (this:Accept("com")) do
				this:Require("var", "Variable expected after comma (,).");
				variables[#variables + 1] = this.__token;
			end
			
			inst.variables = variables;

			local expressions = {};

			if (this:Accept("ass")) then
				this:ExcludeWhiteSpace( "Assignment operator (=), must not be preceded by whitespace." );
				
				expressions[1] = this:Expression_1();

				while (this:Accept("com")) do
					this:ExcludeWhiteSpace( "comma (,) must not be preceeded by whitespace." );
					expressions[#expressions + 1] = this:Expression_1();
				end

				return this:EndInstruction(inst, expressions);
			end

			if (this:Accept("aadd", "asub", "amul", "advi")) then
				inst.__operator = this.__token;

				inst.type = this.__token.type;

				this:ExcludeWhiteSpace("Assignment operator (%s), must not be preceded by whitespace.", this.__token.data);
				
				expressions[1] = this:Expression_1();

				while (this:Accept("com")) do
					this:ExcludeWhiteSpace( "comma (,) must not be preceeded by whitespace." );
					expressions[#expressions + 1] = this:Expression_1();
				end

				if (#expressions ~= #variables) then
					-- TODO: Better error message.
					this:ExcludeWhiteSpace("Invalid arithmetic assignment, not all variables are given values.");
				end

				return this:EndInstruction(inst, expressions);
			end

			this:Throw(inst.token "Variable can not be preceded by whitespace.");
		end
	end

	return this:Statment_8();
end

function PARSER.Statment_8(this)
	if (this:Accept("del")) then
		local inst = this:StartInstruction("delegate", this.__token);

		this:QueueRemove(inst, this.__token);
		
		this:Require("typ", "Return class expected after delegate.");

		inst.resultClass = this.__token.data;

		this:QueueRemove(inst, this.__token);

		this:Require("var", "Delegate name expected after delegate return class.")

		inst.variable = this.__token.data;

		this:QueueRemove(inst, this.__token);

		this:Require("lpa", "Left parenthesis (( ) expected to open delegate peramaters.");

		this:QueueRemove(inst, this.__token);

		local classes = {};

		if (not this:CheckToken("rpa")) then

			while (true) do
				this:Require("typ", "Peramater type expected for peramater.");

				this:QueueRemove(inst, this.__token);

				classes[#classes + 1] = this.__token.data;

				if (not this:Accept("com")) then
					break;
				end

				this:QueueRemove(inst, this.__token);
			end

		end
		
		inst.peramaters = classes;

		this:Require("rpa", "Right parenthesis ( ) expected to close delegate peramaters.");

		this:QueueRemove(inst, this.__token);

		local lcb = this:Accept("lcb");

		if (lcb) then
			this:QueueRemove(inst, this.__token);
		end

		this:Require("ret", "Delegate body must be return followed by return count");
		
		this:QueueRemove(inst, this.__token);

		this:Require("num", "Delegate body must be return followed by return count as number.");

		this:QueueRemove(inst, this.__token);

		inst.resultCount = this.__token.data;

		if (this:Accept("sep")) then
			this:QueueRemove(inst, this.__token);
		end

		if (lcb) then
			this:Require("rcb", "Right curly bracket ( }) expected to close delegate.");

			this:QueueRemove(inst, this.__token);
		end

		return this:EndInstruction(inst, {});
	end

	return this:Statment_9();
end

function PARSER.Statment_9(this)
	if (this:AcceptWithData("typ", "f")) then

		local inst = this:StartInstruction("funct", this.__token);

		this:QueueReplace(inst, this.__token, "function");
		
		this:Require("typ", "Return class expected after user function.");

		inst.resultClass = this.__token.data;

		this:QueueRemove(inst, this.__token);

		this:Require("var", "Function name expected after user function return class.")

		inst.variable = this.__token.data;

		this:QueueRemove(inst, this.__token);

		local perams, signature = this:InputPeramaters(inst);
		
		inst.perams = perams;
		
		inst.signature = signature;

		inst.stmts = this:Block_1(true, " ");

		inst.__end = this.__token;

		return this:EndInstruction(inst, {});
	end

	return this:Statment_10();
end

function PARSER.Statment_10(this)
	if (this:Accept("ret")) then
		local expressions = {};
		local inst = this:StartInstruction("return", this.__token);

		if (not this:CheckToken("sep", "rcb")) then
			while (true) do
				expressions[#expressions + 1] = this:Expression_1();

				if (not this:HasTokens()) then
					break;
				end

				if (not this:Accept("com")) then --"sep", "rcb")) then
					break;
				end

				-- this:Require("com", "Comma (,) expected to seperate return values.");
			end
		end

		return this:EndInstruction(inst, expressions);
	end

	local expr = this:Expression_1();

	if (expr and this:CheckToken("lsb")) then
		expr = this:Statment_11(expr);
	end

	return expr;
end

function PARSER.Statment_11(this, expr)
	if (this:Accept("lsb")) then
		local inst = this:StartInstruction("set", this.__token);

		local expressions = {};

		expressions[1] = expr;

		expressions[2] = this:Expression_1();

		if (this:Accept("com")) then
			this:QueueRemove(inst, this.__token);

			this:Require("typ", "Class expected for index operator, after coma (,).");

			inst.class = this.__token.data;

			this:QueueRemove(inst, this.__token);
		end

		this:Require("rsb", "Right square bracket (]) expected to close index operator.");

		inst.__rsb = this.__token;

		this:Require("ass", "Assigment operator (=) expected after index operator.");

		inst.__ass = this.__token;

		expressions[3] = this:Expression_1();

		return this:EndInstruction(inst, expressions);
	end
end

--[[
]]

function PARSER.Expression_1(this)
	local expr = this:Expression_2();

	while this:Accept("qsm") do
		local inst = this:StartInstruction("ten", this.__token);

		inst.__and = this.__token;

		local expr2 = this:Expression_2();

		this:Require("col", "colon (:) expected for ternary operator.");

		inst.__or = this.__token;

		local expr3 = this:Expression_2();

		expr = this:EndInstruction(inst, {expr, expr2, expr3});
	end

	return this:Expression_Trailing(expr);
end

function PARSER.Expression_2(this)
	local expr = this:Expression_3();

	while this:Accept("or") do
		local inst = this:StartInstruction("or", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_3();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_3(this)
	local expr = this:Expression_4();

	while this:Accept("and") do
		local inst = this:StartInstruction("and", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_4();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_4(this)
	local expr = this:Expression_5();

	while this:Accept("bxor") do
		local inst = this:StartInstruction("bxor", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_5();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_5(this)
	local expr = this:Expression_6();

	while this:Accept("bor") do
		local inst = this:StartInstruction("bor", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_6();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_6(this)
	local expr = this:Expression_7();

	while this:Accept("band") do
		local inst = this:StartInstruction("band", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_7();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_7(this)
	local expr = this:Expression_8();

	while this:CheckToken("eq", "neq") do
		if (this:Accept("eq")) then
			local eqTkn = this.__token;

			if (this:Accept("lsb")) then
				local inst = this:StartInstruction("eq_mul", expr.token);
				
				inst.__operator = eqTkn;

				inst.__listStart = this.__token;

				local expressions = {};

				expressions[1] = expr;

				expressions[2] = this:Expression_1();

				while this:Accept("com") do
					expressions[#expressions + 1] = this:Expression_1()
				end

				expr = this:EndInstruction(ist, expressions);
			else
				local inst = this:StartInstruction("eq", this.__token);

				inst.__operator = this.__token;

				local expr2 = this:Expression_8();

				expr = this:EndInstruction(inst, {expr, expr2});
			end
		elseif (this:Accept("neq")) then
			local eqTkn = this.__token;

			if (this:Accept("lsb")) then
				local inst = this:StartInstruction("neq_mul", expr.token);
				
				inst.__operator = eqTkn;

				inst.__listStart = this.__token;

				local expressions = {};

				expressions[1] = expr;

				expressions[2] = this:Expression_1();

				while this:Accept("com") do
					expressions[#expressions + 1] = this:Expression_1()
				end

				expr = this:EndInstruction(inst, expressions);
			else
				local inst = this:StartInstruction("neq", this.__token);

				inst.__operator = this.__token;

				local expr2 = this:Expression_8();

				expr = this:EndInstruction(ist, {expr, expr2});
			end
		end
	end

	return expr;
end

function PARSER.Expression_8(this)
	local expr = this:Expression_9();

	while this:CheckToken("lth", "leq", "gth", "geq") do
		if (this:Accept("lth")) then
			local inst = this:StartInstruction("lth", expr.token);

			inst.__operator = this.__token;

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		elseif (this:Accept("leq")) then
			local inst = this:StartInstruction("leq", expr.token);

			inst.__operator = this.__token;

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		elseif (this:Accept("gth")) then
			local inst = this:StartInstruction("gth", expr.token);

			inst.__operator = this.__token;

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		elseif (this:Accept("geq")) then
			local inst = this:StartInstruction("geq", expr.token);

			inst.__operator = this.__token;

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		end
	end

	return expr;
end

function PARSER.Expression_9(this)
	local expr = this:Expression_10();

	while this:Accept("bshl") do
		local inst = this:StartInstruction("bshl", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_10();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_10(this)
	local expr = this:Expression_11();

	while this:Accept("bshr") do
		local inst = this:StartInstruction("bshr", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_11();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_11(this)
	local expr = this:Expression_12();

	while this:Accept("add") do
		local inst = this:StartInstruction("add", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_12();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_12(this)
	local expr = this:Expression_13();

	while this:Accept("sub") do
		local inst = this:StartInstruction("sub", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_13();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_13(this)
	local expr = this:Expression_14();

	while this:Accept("div") do
		local inst = this:StartInstruction("div", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_14();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_14(this)
	local tkn = this.__token;

	local expr = this:Expression_15();

	while this:Accept("mul") do
		local inst = this:StartInstruction("mul", tkn);

		inst.__operator = this.__token;

		local expr2 = this:Expression_15();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_15(this)
	local expr = this:Expression_16();

	while this:Accept("exp") do
		local inst = this:StartInstruction("exp", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_16();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_16(this)
	local expr = this:Expression_17();

	while this:Accept("mod") do
		local inst = this:StartInstruction("mod", expr.token);

		inst.__operator = this.__token;

		local expr2 = this:Expression_17();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_17(this)
	if (this:Accept("add")) then
		local tkn = this.__token;

		this:ExcludeWhiteSpace("Identity operator (+) must not be succeeded by whitespace");

		local expr = this:Expression_18();

		this:QueueRemove(expr, tkn);

		return expr;
	end

	return this:Expression_18();
end

function PARSER.Expression_18(this)
	if (this:Accept("neg")) then
		local inst = this:StartInstruction("neg", expr.token);

		inst.__operator = this.__token;

		this:ExcludeWhiteSpace("Negation operator (-) must not be succeeded by whitespace");

		local expr = this:Expression_23();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_19();
end

function PARSER.Expression_19(this)
	if (this:Accept("neg")) then
		local inst = this:StartInstruction("not", expr.token);

		inst.__operator = this.__token;

		this:ExcludeWhiteSpace("Not operator (!) must not be succeeded by whitespace");

		local expr = this:Expression_23();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_20();
end

function PARSER.Expression_20(this)
	if (this:Accept("len")) then
		local inst = this:StartInstruction("len", expr.token);

		inst.__operator = this.__token;

		this:ExcludeWhiteSpace("Length operator (#) must not be succeeded by whitespace");

		local expr = this:Expression_23();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_21();
end

function PARSER.Expression_21(this)
	if (this:Accept("cst")) then
		local inst = this:StartInstruction("cast", expr.token);
		
		inst.class = this.__token.data;

		this:ExcludeWhiteSpace("Cast operator ( (%s) ) must not be succeeded by whitespace", inst.type);

		local expr = this:Expression_1();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_22();
end

function PARSER.Expression_22(this)
	if (this:Accept("lpa")) then
		local expr = this:Expression_1();

		this:Require("rpa", "Right parenthesis ( )) missing, to close grouped equation.");

		return expr;
	end

	return this:Expression_23();
end

function PARSER.Expression_23(this)
	if (this:CheckToken("var")) then
		local library = this.__next.data;
		local lib = EXPR_LIBRARIES[library];

		if (lib) then
			this:Next();

			local inst = this:StartInstruction("func", this.__token);

			inst.library = this.__token.data;

			if (not this:Accept("prd")) then
				this:StepBackward(1);
				return this:Expression_24();
			end

			inst.__operator = this.__token;

			this:Require("var", "function expected after library name");
			
			inst.__func = this.__token;

			inst.name = this.__token.data;

			this:Require("lpa", "Left parenthesis (( ) expected to open function parameters.")

			inst.__lpa = this.__token;
			
			local expressions = {};

			if (not this:CheckToken("rpa")) then
				expressions[1] = this:Expression_1();

				while(this:Accept("com")) do
					this:Exclude("rpa", "Expression or value expected after comma (,).");

					expressions[#expressions + 1] = this:Expression_1();
				end

			end  
			
			this:Require("rpa", "Right parenthesis ( )) expected to close function parameters.")

			return this:EndInstruction(inst, expressions);
		end
	end

	return this:Expression_24();
end

function PARSER.Expression_24(this)
	if (this:Accept("var")) then
		local inst = this:StartInstruction("var", this.__token);

		inst.variable = this.__token.data;

		this:EndInstruction(inst, {});

		return this:Expression_Trailing(inst);
	end

	return this:Expression_25()
end

function PARSER.Expression_25(this)

	if (this:Accept("new")) then
		local inst = this:StartInstruction("new", this.__token);

		inst.__new = this.__token; -- this:QueueRemove(inst, this.__token);

		this:Require("typ", "Type expected after new for constructor.");

		inst.class = this.__token.data;

		inst.__const = this.__token; -- this:QueueRemove(inst, this.__token);
		
		this:Require("lpa", "Left parenthesis (( ) expected to open constructor parameters.")

		local expressions = {};

		if (not this:CheckToken("rpa")) then
			expressions[1] = this:Expression_1();

			while(this:Accept("com")) do
				this:Exclude("rpa", "Expression or value expected after comma (,).");

				expressions[#expressions + 1] = this:Expression_1();
			end

		end

		this:Require("rpa", "Right parenthesis ( )) expected to close constructor parameters.");

		return this:EndInstruction(inst, expressions);
	end

	return this:Expression_26();
end

function PARSER.Expression_26(this)
	if (this:AcceptWithData("typ", "f")) then
		local inst = this:StartInstruction("lambda", this.__token);

		this:QueueInjectionBefore(inst, this.__token, "{op = ");

		this:QueueReplace(inst, this.__token, "function");

		local perams, signature = this:InputPeramaters(inst);

		inst.perams = perams;
		
		inst.signature = signature;

		inst.stmts = this:Block_1(true, " ");

		this:QueueInjectionAfter(inst, this.__token, ", signature = \"" .. signature .. "\"");
		
		inst.__end = this.__token;
		-- We inject the } in the compiler.
		-- this:QueueInjectionAfter(inst, this.__token, "}");

		return this:EndInstruction(inst, {});
	end

	return this:Expression_27();
end

function PARSER.InputPeramaters(this, inst)
	this:Require("lpa", "Left parenthesis (() ) expected to open function parameters.");

	local signature = {};

	local perams = {};

	if (not this:CheckToken("rpa")) then
		while (true) do
			this:Require("typ", "Class expected for new peramater.");

			this:QueueRemove(inst, this.__token);

			local class = this.__token.data;

			this:Require("var", "Peramater expected after class.");

			signature[#signature + 1] = class;

			perams[#perams + 1] = {class, this.__token.data}

			if (this:CheckToken("rpa")) then
				break;
			end

			if (not this:HasTokens()) then
				break;
			end

			this:Require("com", "Right parenthesis ( )) expected to close function parameters.");
			-- May not look logical, but it is :D
		end
	end

	this:Require("rpa", "Right parenthesis ( )) expected to close function parameters.");

	return perams, table.concat(signature, ",");
end

function PARSER.Expression_27(this)
	expr = this:Expression_28();

	if (expr) then
		return expr;
	end

	this:ExpressionErr();
end

function PARSER.Expression_28(this)
	if (this:Accept("tre", "fls")) then
		local inst = this:StartInstruction("bool", this.__token);
		inst.value = this.__token.data;
		return this:EndInstruction(inst, {});
	elseif (this:Accept("void")) then
		local inst = this:StartInstruction("void", this.__token);
		
		this:QueueReplace(this.__token, "nil");
		
		return this:EndInstruction(inst, {});
	elseif (this:Accept("num")) then
		local inst = this:StartInstruction("num", this.__token);
		inst.value = this.__token.data;
		return this:EndInstruction(inst, {});
	elseif (this:Accept("str")) then
		local inst = this:StartInstruction("str", this.__token);
		inst.value = this.__token.data;
		return this:EndInstruction(inst, {});
	elseif this:Accept("typ") then
		local inst = this:StartInstruction("cls", this.__token);
		inst.value = this.__token.data;
		return this:EndInstruction(inst, {});
	end
end

function PARSER.Expression_Trailing(this, expr)

	while this:CheckToken("prd", "lsb", "lpa") do
		
		local excluded;

		if (this:StatmentContains(this.__token, "ass")) then
			excluded = this:LastInStatment(this.__token, "lsb");
		end

		-- Methods
		if (this:Accept("prd")) then
			local inst = this:StartInstruction("meth", expr.token);

			inst.__operator = this.__token;

			this:Require("var", "method name expected after method operator (.)");

			inst.__method = this.__token;

			inst.method = this.__token.data;

			this:Require("lpa", "Left parenthesis (( ) expected to open method parameters.")

			inst.__lpa = this.__token;

			local expressions = {};
 
			expressions[1] = expr;

			if (not this:CheckToken("rpa")) then
				expressions[2] = this:Expression_1();

				while(this:Accept("com")) do
					this:Exclude("rpa", "Expression or value expected after comma (,).");

					expressions[#expressions + 1] = this:Expression_1();
				end

			end  

			this:Require("rpa", "Right parenthesis ( )) expected to close method parameters.")

			inst.__rpa = this.__token;

			expr = this:EndInstruction(inst, expressions);
		elseif (this:Accept("lsb")) then
			
			-- Check for a set instruction and locate it,
			-- If we are at our set indexer then we break.

			if (this:StatmentContains(this.__token, "ass")) then
				local excluded = this:LastInStatment(this.__token, "lsb");
				
				if (excluded and excluded.index == this.__token.index) then
					this:StepBackward(1);
					break;
				end
			end

			local inst = this:StartInstruction("get", expr.token);

			local expressions = {};
 
			expressions[1] = expr;

			expressions[2] = this:Expression_1();

			if (this:Accept("com")) then
				this:QueueRemove(inst, this.__token);

				this:Require("typ", "Class expected for index operator, after coma (,).");

				inst.class = this.__token.data;

				this:QueueRemove(inst, this.__token);
			end

			this:Require("rsb", "Right square bracket (]) expected to close index operator.");

			inst.__rsb = this.__token;

			expr = this:EndInstruction(inst, expressions);
		elseif (this:Accept("lpa")) then
			local inst = this:StartInstruction("call", expr.token);

			local expressions = {};
 
			expressions[1] = expr;

			if (not this:CheckToken("rpa")) then
				expressions[2] = this:Expression_1();

				while (this:Accept("com")) do
					this:Exclude("rpa", "Expression or value expected after comma (,).");

					expressions[#expressions + 1] = this:Expression_1();
				end

			end  

			this:Require("rpa", "Right parenthesis ( )) expected to close call parameters.")

			expr = this:EndInstruction(inst, expressions);
		end
	end
	
	return expr;
end

function PARSER.GetCondition(this)
	this:Require("lpa", "Left parenthesis ( () required, to open condition.");
	
	local inst = this:StartInstruction("cond", this.__token);
	
	local expr = this:Expression_1();

	this:Require("rpa", "Right parenthesis ( )) missing, to close condition.");
	
	return this:EndInstruction(inst, {expr});
end

function PARSER.ExpressionErr(this)
	if (not this.__token) then
		this:Throw(this.__tokens[#this.__tokens], "Further input required at end of code, incomplete expression");
	end

	this:ExcludeWhiteSpace("Further input required at end of code, incomplete expression");
	this:Exclude("void", "void must not appear inside an equation");
	this:Exclude("add", "Arithmetic operator (+) must be preceded by equation or value");
	this:Exclude("sub", "Arithmetic operator (-) must be preceded by equation or value");
	this:Exclude("mul", "Arithmetic operator (*) must be preceded by equation or value");
	this:Exclude("div", "Arithmetic operator (/) must be preceded by equation or value");
	this:Exclude("mod", "Arithmetic operator (%) must be preceded by equation or value");
	this:Exclude("exp", "Arithmetic operator (^) must be preceded by equation or value");
	this:Exclude("ass", "Assignment operator (=) must be preceded by variable");
	this:Exclude("aadd", "Assignment operator (+=) must be preceded by variable");
	this:Exclude("asub", "Assignment operator (-=) must be preceded by variable");
	this:Exclude("amul", "Assignment operator (*=) must be preceded by variable");
	this:Exclude("adiv", "Assignment operator (/=) must be preceded by variable");
	this:Exclude("and", "Logical operator (&&) must be preceded by equation or value");
	this:Exclude("or", "Logical operator (||) must be preceded by equation or value");
	this:Exclude("eq", "Comparison operator (==) must be preceded by equation or value");
	this:Exclude("neq", "Comparison operator (!=) must be preceded by equation or value");
	this:Exclude("gth", "Comparison operator (>=) must be preceded by equation or value");
	this:Exclude("lth", "Comparison operator (<=) must be preceded by equation or value");
	this:Exclude("geq", "Comparison operator (>) must be preceded by equation or value");
	this:Exclude("leq", "Comparison operator (<) must be preceded by equation or value");
	-- this:Exclude("inc", "Increment operator (++) must be preceded by variable");
	-- this:Exclude("dec", "Decrement operator (--) must be preceded by variable");
	this:Exclude("rpa", "Right parenthesis ( )) without matching left parenthesis");
	this:Exclude("lcb", "Left curly bracket ({) must be part of an table/if/while/for-statement block");
	this:Exclude("rcb", "Right curly bracket (}) without matching left curly bracket");
	this:Exclude("lsb", "Left square bracket ([) must be preceded by variable");
	this:Exclude("rsb", "Right square bracket (]) without matching left square bracket");
	this:Exclude("com", "Comma (,) not expected here, missing an argument?");
	this:Exclude("prd", "Method operator (.) must not be preceded by white space");
	this:Exclude("col", "Ternary operator (:) must be part of conditional expression (A ? B : C).");
	this:Exclude("if", "If keyword (if) must not appear inside an equation");
	this:Exclude("eif", "Else-if keyword (elseif) must be part of an if-statement");
	this:Exclude("els", "Else keyword (else) must be part of an if-statement");
	--this:Exclude("try", "Try keyword (try) must be part of a try-statement");
	--this:Exclude("cth", "Catch keyword (catch) must be part of an try-statement");
	--this:Exclude("fnl", "Final keyword (final) must be part of an try-statement");
	--this:Exclude("dir", "directive operator (@) must not appear inside an equation");

	this:Throw(this.__token, "Unexpected symbol found (%s)", this.__token.type);
end
--[[
]]

--[[
]]

EXPR_PARSER = PARSER;