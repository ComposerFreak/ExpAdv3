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
	
	:::Syntax Gramar:::
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
			Stmt4 ← (("server" / "client") Block)? Stmt5
			Stmt6 ← "global"? (type (Var("," Var)* "="? (Expr1? ("," Expr1)*)))
			Stmt7 ← (type (Var("," Var)* ("=" / "+=" / "-=" / "/=" / "*=")? (Expr1? ("," Expr1)*)))
		
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
			Expr16 ← ("+" Expr21)? Exp17
			Expr17 ← ("-" Expr21)? Exp18
			Expr18 ← ("!" Expr21)? Expr19
			Expr19 ← ("#" Expr21)? Expr20
			Expr20 ← ("("type")" Expr1)? Expr21
			Expr21 ← ("(" Expr1 ")")? Expr22
			Expr22 ← (Var)? Expr23

		:::Syntax:::
			Cond ← "(" Expr1 ")"
			Block ← "{" (Stmt1 ((";" / " ") Stmt1)*)? "}"
			Values ← "[" Expr1 ("," Expr1)* "]"

]]

local PARSER = {};
PARSER.__index = PARSER;

function PARSER.New()
	return setmetatable({}, PARSER);
end

function PARSER.Initalize(this, instance)
	this.__pos = 1;
	this.__depth = 0;
	this.__scope = 0;
	this.__instructions = {};

	this.__token = instance.tokens[1];
	this.__next = instance.tokens[2];
	this.__total = #instance.tokens;
	this.__tokens = instance.tokens;
	this.__script = instance.script;

	this.__tasks = {};
end


function PARSER.Run(this)
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
	if (this.__pos >= this.__total) then
		return false;
	end

	this.__pos = this.__pos + 1;
	this.__token = instance.tokens[this.__pos];
	this.__next = instance.tokens[this.__pos + 1];

	return true;
end

function PARSER.HasTokens(this)
	return this.__pos >= this.__total;
end

function PARSER.CheckToken(this, type, ...)
	if (this.__pos >= this.__total) then
		local tkn = this.__next;

		for _, t in pairs({type, ...}) do
			if (t == tkn.type) then
				return true;
			end
		end
	end

	return false;
end

function PARSER.Accept(this, type, ..)
	if (this:CheckToken(type, ...)) then
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

function PARSER.StepBackward(steps)
	if (not steps) then
		steps = 1;
	end

	local pos = this.__pos - steps

	if (pos < 0) then
		pos = 0;
	end

	if (pos > this.__total) then
		pos = this.__total;
	end

	this.__pos = pos;

	this:Next();
end

function PASRSER.GetFirstTokenOnLine(this)
	for i = this.__pos, 1, -1 do
		local tkn = this.__tokens[i];

		if (tkn.newLine) then
			return tkn;
		end
	end

	return this.__tokens[1];
end

--[[
]]

function PASRSER.Require( this, type, msg, ... )
	if (not this:AcceptToken(type)) then
		this:Throw( this.__token, msg, ... )
	end
end

function PASRSER.Exclude( this, tpye, msg, ... )
	if (this:AcceptToken(type)) then
		this:Throw( this.__token, msg, ... )
	end
end

function PASRSER.ExcludeWhiteSpace(this, msg, ...)
	if (this:HasTokens()) then 
		this:Throw( this.__token, msg, ... )
	end
end

--[[
]]

function PARSER.StartInstruction(this, type, token);
	local inst = {};
	inst.type = type;
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

	local r = {};
	local t = {str, ...};

	for i = 1, #t do
		local op = {};
	
		op.token = token;
		op.str = t[i];
		op.inst = inst;

		r[#r + 1] = op;
	end

	for i = #r, 1, -1 do
		-- place these in reverse order so they come out in the corect order.
		tasks.prefix[#tasks.prefix + 1] = r[i];
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
		tasks.prefix[#tasks.prefix + 1] = op;
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

	return inst;
end

--[[
]]

function PARSER.Root(this)
	local seq = this:StartInstruction("seq", this.__token);

	local stmts = this:Statments(this, false);

	return this:EndInstruction(this, seq, stmts);
end

function PARSER.Block_1(this, _end, lcb)
	this:ExcludeWhiteSpace( "Further input required at end of code, incomplete statment" )
	
	if (this:Accept("lcb")) then

		local seq = this:StartInstruction("seq", this.__token);

		this:QueueReplace(seq, this.__token, lcb;

		this.__scope = this.__scope + 1;

		local stmts = this:Statments(true);

		this.__scope = this.__scope - 1;

		this:Require("rcb", "Right curly bracket (}) missing, to close block");

		if (_end) then
			this:QueueReplace(seq, this.__token, "end");
		end

		return this:EndInstruction(this, seq, stmts);
	end

	local seq = this:StartInstruction("seq", this.__token);

	this:QueueInjectionAfter(seq, this.__token, lcb);

	this.__scope = this.__scope + 1;

	local stmt = this:Statment_1();

	this.__scope = this.__scope - 1;

	if (_end) then
		this:QueueInjectionBefore(seq, this.__token, "end");
	else
		this:QueueRemove(seq, this.__token);
	end

	return this:EndInstruction(this, seq, {stmt})
end

function PARSER.Statments(this, block)
	local pre;
	local sep = false;
	local stmts = {};

	while true do

		if (pre and this:Accept("sep") then
			sep = true;
		end

		local stmt = this:Statment_1();

		if (block and this:Check("rcb")) then
			break;
		end

		if (not this:HasTokens()) then
			break;
		end

		if (pre) then
			if (pre.line == stmt.line and not sep) then
				this:Throw(stmt.token, "Statements must be separated by semicolon (;) or newline")
			end

			if (pre.type == "return") then
				this:Throw(stmt.token, "Statment can not appear after return.")
			elseif (pre.type == "continue") then
				this:Throw(stmt.token, "Statment can not appear after continue.")
			elseif (pre.type == "break") then
				this:Throw(stmt.token, "Statment can not appear after break.")
			end
		end

		pre = stmt;

		stmts[#stmts + 1] = stmt;
	end

	return stmts;
end

--[[
]]

function PARSER.Statment_1(this)
	if (this:Accept("if")) then
		local inst = this:StartInstruction(this, "if", this.__token);

		inst.condition = this:Condition();

		inst.block = this:block_1(false, "then");

		inst._else = this:Statment_2();

		this:QueueInjectionAfter(inst, this.__token, "end");

		return this:EndInstruction(inst, {});
	end

	return this:Statment_4();
end

function PARSER.Statment_2(this)
	if (this:Accept("eif")) then
		local inst = this:StartInstruction(this, "elseif", this.__token);

		inst.condition = this:Condition();

		inst.block = this:block_1(false, "then");

		inst._else = this:Statment_2();

		return this:EndInstruction(inst, {});
	end

	return this:Statment_3();
end

function PARSER.Statment_3(this)
	if (this:Accept("els")) then
		local inst = this:StartInstruction(this, "else", this.__token);

		inst.block = this:block_1(false, "");

		return this:EndInstruction(inst, {});
	end
end

--[[
]]

function PARSER.Statment_4(this)
	if (this:Accept("sv")) then
		local inst = this:StartInstruction(this, "server", this.__token);

		this:QueueInjectionBefore(inst, this.__token, "if");

		this:QueueReplace(inst, this.__token, "(SERVER)");

		inst.block = this:block_1(true, "then");

		return this:EndInstruction(inst, {});
	end

	if (this:Accept("cl")) then
		local inst = this:StartInstruction(this, "client", this.__token);

		this:QueueInjectionBefore(inst, this.__token, "if");

		this:QueueReplace(inst, this.__token, "(CLIENT)");

		inst.block = this:block_1(true, "then");

		return this:EndInstruction(inst, {});
	end

	return this:Statment_5();
end

--[[
]]

function PARSER.Statment_5(this)
	if (this:Accept("glo")) then
		local inst = this:StartInstruction(this, "global", this.__token);

		this:Require("typ", "Class expected after global.");
		
		local type = this.token.data;
		this:QueueRemove(inst, this.__token);

		local variables = {};

		this:Require("var", "Variable('s) expected after class for global variable.");
		variables[1] = this.__token.data;
		this:QueueInjectionBefore(inst, this.__token, "GLOBAL", ".");

		while (this:Accpet("com")) then
			this:Require("var", "Variable expected after comma (,).");
			variables[#variables + 1] = this.__token.data;
			this:QueueInjectionBefore(inst, this.__token, "GLOBAL", ".");
		end

		local expressions = {};

		if (this:Accept("ass")) then
			this:ExcludeWhiteSpace( "Assigment operator (=), must not be preceeded by whitespace." );
			
			expressions[1] = this:expression_1();

			while (this:Accpet("com")) then
				this:ExcludeWhiteSpace( "comma (,) must not be preceeded by whitespace." );
				expressions[#expressions + 1] = this:expression_1();
			end
		end

		return this:EndInstruction(inst, variables, expressions);
	end

	if (this:Accept("typ")) then
		local inst = this:StartInstruction(this, "local", this.__token);
		
		local type = this.token.data;
		this:QueueReplace(inst, this.__token, "local");

		local variables = {};

		this:Require("var", "Variable('s) expected after class for global variable.");
		variables[1] = this.__token.data;

		while (this:Accpet("com")) then
			this:Require("var", "Variable expected after comma (,).");
			variables[#variables + 1] = this.__token.data;
		end
		
		local expressions = {};

		if (this:Accept("ass")) then
			this:ExcludeWhiteSpace( "Assigment operator (=), must not be preceeded by whitespace." );
			
			expressions[1] = this:expression_1();

			while (this:Accpet("com")) then
				this:ExcludeWhiteSpace( "comma (,) must not be preceeded by whitespace." );
				expressions[#expressions + 1] = this:expression_1();
			end
		end

		return this:EndInstruction(inst, variables, expressions);
	end

	return this:Statment_6()
end;

function PARSER.Statment_6(this)
	if (this:Accept("var")) then
		if (not this:CheckToken("com", "ass", "aadd", "asub", "adiv", "amul")) then
			this:StepBackward(1);
		else
			local inst = this:StartInstruction(this, "ass", this.__token);
			
			local variables = {};
		
			this:Require("var", "Variable('s) expected after class for global variable.");
			variables[1] = this.__token.data;

			while (this:Accpet("com")) then
				this:Require("var", "Variable expected after comma (,).");
				variables[#variables + 1] = this.__token.data;
			end
			
			local expressions = {};

			if (this:Accept("ass")) then
				this:ExcludeWhiteSpace( "Assigment operator (=), must not be preceeded by whitespace." );
				
				expressions[1] = this:expression_1();

				while (this:Accpet("com")) then
					this:ExcludeWhiteSpace( "comma (,) must not be preceeded by whitespace." );
					expressions[#expressions + 1] = this:expression_1();
				end
			elseif this:AcceptToken( "aadd" ) then
				this:ExcludeWhiteSpace( "Assigment operator (+=), must not be preceeded by whitespace." );

				for k, v in pairs(variables) do
					local inst = this:StartInstruction(this.__token, "ass_add");
					instVar.variable = v;
					this:QueueInjectionBefore(instVar, this.__token, v, "+");
					expressions[#expressions + 1] = this:EndInstruction(instVar, {this:Expression_1()});

					if (k < #variables) then
						this:ExcludeWhiteSpace("Invalid arithmatic assigment operation, #%i value or equation expected for %s", k, v);
						
						if ( not this:Accept("com")) then
							this:Throw(inst.token, "Expression missing to complete arithmatic assigment operator (+=).");
						end

					end
				end

				return this:EndInstruction(inst, variables, expressions);
			elseif this:AcceptToken( "asub" ) then
				this:ExcludeWhiteSpace( "Assigment operator (-=), must not be preceeded by whitespace." );

				for k, v in pairs(variables) do
					local inst = this:StartInstruction(this.__token, "ass_sub");
					instVar.variable = v;
					this:QueueInjectionBefore(instVar, this.__token, v, "-");
					expressions[#expressions + 1] = this:EndInstruction(instVar, {this:Expression_1()});

					if (k < #variables) then
						this:ExcludeWhiteSpace("Invalid arithmatic assigment operation, #%i value or equation expected for %s", k, v);
						
						if ( not this:Accept("com")) then
							this:Throw(inst.token, "Expression missing to complete arithmatic assigment operator (-=).");
						end

					end
				end

				return this:EndInstruction(inst, variables, expressions);
			elseif this:AcceptToken( "adiv" ) then
				this:ExcludeWhiteSpace( "Assigment operator (/=), must not be preceeded by whitespace." );

				for k, v in pairs(variables) do
					local inst = this:StartInstruction(this.__token, "ass_div");
					instVar.variable = v;
					this:QueueInjectionBefore(instVar, this.__token, v, "/");
					expressions[#expressions + 1] = this:EndInstruction(instVar, {this:Expression_1()});

					if (k < #variables) then
						this:ExcludeWhiteSpace("Invalid arithmatic assigment operation, #%i value or equation expected for %s", k, v);
						
						if ( not this:Accept("com")) then
							this:Throw(inst.token, "Expression missing to complete arithmatic assigment operator (/=).");
						end

					end
				end

				return this:EndInstruction(inst, variables, expressions);
			elseif this:AcceptToken( "amul" ) then
				this:ExcludeWhiteSpace( "Assigment operator (*=), must not be preceeded by whitespace." );

				for k, v in pairs(variables) do
					local inst = this:StartInstruction(this.__token, "ass_mul");
					instVar.variable = v;
					this:QueueInjectionBefore(instVar, this.__token, v, "-");
					expressions[#expressions + 1] = this:EndInstruction(instVar, {this:Expression_1()});

					if (k < #variables) then
						this:ExcludeWhiteSpace("Invalid arithmatic assigment operation, #%i value or equation expected for %s", k, v);
						
						if ( not this:Accept("com")) then
							this:Throw(inst.token, "Expression missing to complete arithmatic assigment operator (*=).");
						end

					end
				end

				return this:EndInstruction(inst, variables, expressions);
			end

			this:Throw(inst.token "Variable can not be preceeded by whitespace.");
		end
	end

	return this:Statment_7();
end

--[[
]]

function PARSER.Expression_1(this)
	local expr = this:Expression_2();

	while this:Accept("qsm") then
		local inst = this:StartInstruction(this.__token, "ten");

		this:QueueReplace(inst, this.__token, "and");

		local expr2 = this:Expression_2();

		this:Require("col", "colon (:) expected for ternary operator.");

		this:QueueReplace(this, this.__token, "or");

		local expr2 = this:Expression_3();

		expr = this:EndInstruction(inst, expr, {expr2, expr3});
	end

	return expr;
end

function PARSER.Expression_2(this)
	local expr = this:Expression_3();

	while this:Accept("or") then
		local inst = this:StartInstruction(inst, expr.token, "or");

		this:QueueReplace(this.__token, "or");

		local expr2 = this:Expression_3();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_3(this)
	local expr = this:Expression_4();

	while this:Accept("and") then
		local inst = this:StartInstruction(expr.token, "and");

		this:QueueReplace(inst, this.__token, "and");

		local expr2 = this:Expression_4();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_4(this)
	local expr = this:Expression_5();

	while this:Accept("bxor") then
		local inst = this:StartInstruction(expr.token, "bxor");

		local r = this:QueueInjectionBefore(expr.token, "bit.bxor", "(");

		inst.injectFunction = r[1];

		local expr2 = this:Expression_5();

		this:QueueInjectionAfter(expr2.token, ")");

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_5(this)
	local expr = this:Expression_6();

	while this:Accept("bor") then
		local inst = this:StartInstruction(expr.token, "bor");

		local r = this:QueueInjectionBefore(expr.token, "bit.bor", "(");

		inst.injectFunction = r[1];

		local expr2 = this:Expression_6();

		this:QueueInjectionAfter(expr2.token, ")");

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_6(this)
	local expr = this:Expression_7();

	while this:Accept("band") then
		local inst = this:StartInstruction(expr.token, "band");

		local r = this:QueueInjectionBefore(expr.token, "bit.band", "(");

		inst.injectFunction =  r[1];

		local expr2 = this:Expression_7();

		this:QueueInjectionAfter(expr2.token, ")");

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
				local inst = this:StartInstruction(expr.token, "eq_mul");

				this:QueueInjectionBefore(inst, eqTkn, "eqMult",  "(",  "nil", "," );

				inst.injectNil = r[3]

				this:QueueReplace(inst, this.__token, ","); -- This is ([)

				local expressions = {};
				expressions[1] = this:Expression_1();

				while this:AcceptToken("com") do
					expressions[#expressions + 1] = this:Expression_1()
				end

				this:QueueInjectionAfter(inst, this.__token, ")");

				expr = this:EndInstruction(ist, expressions);

				-- TODO: When using a function operator to do comparisons this will inject the function as peram 1.
			else
				local inst = this:StartInstruction(this.__token, "eq");
				expr = this:EndInstruction(ist, {expr, expr2});
			end
		elseif (this:Accept("neq")) then
			local eqTkn = this.__token;

			if (this:Accept("lsb")) then
				local inst = this:StartInstruction(expr.token, "neq_mul");

				this:QueueInjectionBefore(inst, eqTkn, "neqMult",  "(",  "nil", "," );

				inst.injectNil = r[3]
				this:QueueReplace(inst, this.__token, ","); -- This is ([)

				local expressions = {};
				expressions[1] = this:Expression_1();

				while this:AcceptToken("com") do
					expressions[#expressions + 1] = this:Expression_1()
				end

				this:QueueInjectionAfter(inst, this.__token, ")");

				expr = this:EndInstruction(ist, expressions);

				-- TODO: When using a function operator to do comparisons this will inject the function as peram 1.
			else
				local inst = this:StartInstruction(this.__token, "neq");
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
			local inst = this:StartInstruction(expr.token, "lth");

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		elseif (this:Accept("leq")) then
			local inst = this:StartInstruction(expr.token, "leq");

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		elseif (this:Accept("gth")) then
			local inst = this:StartInstruction(expr.token, "gth");

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		elseif (this:Accept("geq")) then
			local inst = this:StartInstruction(expr.token, "geq");

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr, expr2});
		end
	end

	return expr;
end

function PARSER.Expression_9(this)
	local expr = this:Expression_10();

	while this:Accept("bshl") then
		local inst = this:StartInstruction(expr.token, "bshl");

		local r = this:QueueInjectionBefore(expr.token, "bit.lshift", "(");

		inst.injectFunction = r[1];

		local expr2 = this:Expression_10();

		this:QueueInjectionAfter(expr2.token, ")");

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_10(this)
	local expr = this:Expression_11();

	while this:Accept("bshr") then
		local inst = this:StartInstruction(expr.token, "bshr");

		local r = this:QueueInjectionBefore(expr.token, "bit.rshift", "(");

		inst.injectFunction = r[1];

		local expr2 = this:Expression_11();

		this:QueueInjectionAfter(expr2.token, ")");

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_11(this)
	local expr = this:Expression_12();

	while this:Accept("add") then
		local inst = this:StartInstruction(inst, expr.token, "add");

		local expr2 = this:Expression_12();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_12(this)
	local expr = this:Expression_13();

	while this:Accept("sub") then
		local inst = this:StartInstruction(inst, expr.token, "sub");

		local expr2 = this:Expression_13();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_13(this)
	local expr = this:Expression_14();

	while this:Accept("div") then
		local inst = this:StartInstruction(inst, expr.token, "div");

		local expr2 = this:Expression_14();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_14(this)
	local expr = this:Expression_15();

	while this:Accept("mul") then
		local inst = this:StartInstruction(inst, expr.token, "mul");

		local expr2 = this:Expression_15();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_15(this)
	local expr = this:Expression_16();

	while this:Accept("exp") then
		local inst = this:StartInstruction(inst, expr.token, "exp");

		local expr2 = this:Expression_16();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_16(this)
	if (this:Accept("add")) then
		local tkn = this.__token;

		this:ExcludeWhiteSpace("Identity operator (+) must not be succeeded by whitespace");

		local expr = this:Expression_17();

		this:QueueRemove(expr, tkn);

		return expr;
	end

	return this:Expression_17();
end

function PARSER.Expression_17(this)
	if (this:Accept("neg")) then
		local inst = this:StartInstruction(inst, expr.token, "neg");

		this:ExcludeWhiteSpace("Negation operator (-) must not be succeeded by whitespace");

		local expr = this:Expression_22();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_18();
end

function PARSER.Expression_18(this)
	if (this:Accept("neg")) then
		local inst = this:StartInstruction(inst, expr.token, "not");

		this:ExcludeWhiteSpace("Not operator (!) must not be succeeded by whitespace");

		local expr = this:Expression_22();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_18();
end

function PARSER.Expression_19(this)
	if (this:Accept("len")) then
		local inst = this:StartInstruction(inst, expr.token, "len");

		this:ExcludeWhiteSpace("Lengh operator (#) must not be succeeded by whitespace");

		local expr = this:Expression_22();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_20();
end

function PARSER.Expression_20(this)
	if (this:Accept("cst")) then
		local inst = this:StartInstruction(inst, expr.token, "cast");
		
		inst.type = this.__token.data;

		this:ExcludeWhiteSpace("Cast operator ( (%s) ) must not be succeeded by whitespace", inst.type);

		local expr = this:Expression_1();

		return this:EndInstruction(inst, {expr});
	end

	return this:Expression_20();
end

function PARSER.Expression_21(this)
	if (this:Accept("lpa")) then
		local expr = this:Expression_1();

		this:Require("rpa", "Right parenthesis ( )) missing, to close grouped equation.");

		return this:Expression_Trailing(expr);
	end

	return this:Expression_22();
end

function PARSER.Expression_22(this)
	if (this:Accept("var")) then
		local inst = this:StartInstruction(this.__token, "var");

		inst.variable = this.__token.data;

		this:EndInstruction(inst, {});

		return this:Expression_Trailing(inst);
	end

	return this:Expression_23()
end

function PARSER.Expression_23(this)
	local expr = this:Expression_RawVaue();

	if (not expr) then
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
		this:Exclude("eq", "Comparason operator (==) must be preceded by equation or value");
		this:Exclude("neq", "Comparason operator (!=) must be preceded by equation or value");
		this:Exclude("gth", "Comparason operator (>=) must be preceded by equation or value");
		this:Exclude("lth", "Comparason operator (<=) must be preceded by equation or value");
		this:Exclude("geq", "Comparason operator (>) must be preceded by equation or value");
		this:Exclude("leq", "Comparason operator (<) must be preceded by equation or value");
		-- this:Exclude("inc", "Increment operator (++) must be preceded by variable");
		-- this:Exclude("dec", "Decrement operator (--) must be preceded by variable");
		this:Exclude("rpa", "Right parenthesis ( )) without matching left parenthesis");
		this:Exclude("lcb", "Left curly bracket ({) must be part of an table/if/while/for-statement block");
		this:Exclude("rcb", "Right curly bracket (}) without matching left curly bracket");
		this:Exclude("lsb", "Left square bracket ([) must be preceded by variable");
		this:Exclude("rsb", "Right square bracket (]) without matching left square bracket");
		this:Exclude("com", "Comma (,) not expected here, missing an argument?");
		this:Exclude("prd", "Method operator (.) must not be preceded by white space");
		this:Exclude("col", "Tenarry operator (:) must be part of conditional expression (A ? B : C).");
		this:Exclude("if", "If keyword (if) must not appear inside an equation");
		this:Exclude("eif", "Else-if keyword (elseif) must be part of an if-statement");
		this:Exclude("els", "Else keyword (else) must be part of an if-statement");
		--this:Exclude("try", "Try keyword (try) must be part of a try-statement");
		--this:Exclude("cth", "Catch keyword (catch) must be part of an try-statement");
		--this:Exclude("fnl", "Final keyword (final) must be part of an try-statement");
		--this:Exclude("dir", "directive operator (@) must not appear inside an equation");
		this:Error(this.__token, "Unexpected symbol found (%s)", self.__token.name);
	end
end

function PARSER.Expression_RawVaue(this)
	if (this:Accept("tre", "fls")) then
		local inst = this:StartInstruction(this.__token, "bool");
		inst.value = this.__token.data;
		return this:EndInstruction(inst, {});
	elseif (this:Accept("void")) then
		local inst = this:StartInstruction(this.__token, "void");
		
		this:QueueReplace(this.__token, "nil");
		
		return this:EndInstruction(inst, {});
	elseif (this:Accept("num")) then
		local inst = this:StartInstruction(this.__token, "num");
		inst.value = this.__token.data;
		return this:EndInstruction(inst, {});
	elseif (this:Accept("str")) then
		local inst = this:StartInstruction(this.__token, "str");
		inst.value = this.__token.data;
		return this:EndInstruction(inst, {});
	end

	-- TODO: Functions :D
end

function PARSER.Expression_Trailing(this, inst)
	while this:CheckToken("prd", "lsb", "lpa") do
		-- Methods

		-- Getters
	end

	return expr;
end
