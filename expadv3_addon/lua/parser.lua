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
	this.__offsets = 0;
	this.__depth = 0;
	this.__instructions = {};
	this.__token = instance.tokens[1];
	this.__next = instance.tokens[2];
	this.__total = #instance.tokens;
	this.__tokens = instance.tokens;
	this.__script = instance.script;
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
	result.script = this.__buffer;

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

function PASRSER.ExludeWhiteSpace(this, msg, ...)
	if (this:HasTokens()) then 
		this:Throw( this.__token, msg, ... )
	end
end

--[[
]]

--[[
]]

function PARSER.StartInstruction(this, type, token);
	local inst = {};
	inst.type = type;
	inst.result = "void";
	inst.rCount = 0;
	inst.token = token;
	inst.char = token.char;
	inst.line = token.lin;
	inst.offset = this.__offset;
	inst.operations = {};
	return inst;
end

function PARSER.QueueReplace(this, inst, token, str)
	local op = {};
	op.type = "rep";
	op.token = token;
	op.str = str;
	inst.operations[#inst.operations + 1] = op;
end

function PARSER.QueueRemove(this, inst, token)
	local op = {};
	op.type = "rem";
	op.token = token;
	inst.operations[#inst.operations + 1] = op;
end

function PARSER.QueueInjectionBefore(this, inst, token, str)
	local op = {};
	op.type = "bef";
	op.token = token;
	op.str = str;
	inst.operations[#inst.operations + 1] = op;
end

function PARSER.QueueInjectionAfter(this, inst, token, str)
	local op = {};
	op.type = "aft";
	op.token = token;
	op.str = str;
	inst.operations[#inst.operations + 1] = op;
end

function PARSER.SetEndResults(this, inst, type, count)
	inst.type = type;
	inst.rCount = count or 1;
end

function PARSER.EndInstruction(this, inst, instructions)
	inst.instructions = instructions;
	inst.final = this.__token;
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
		this.__depth = this.__deph + 1;

		local seq = this:StartInstruction("seq", this.__token);

		this:QueueReplace(seq, this.__token, lcb;

		local stmts = this:Statments(true);

		this.__depth = this.__deph - 1;

		this:Require("rcb", "Right curly bracket (}) missing, to close block");

		if (_end) then
			this:QueueReplace(seq, this.__token, "end");
		end

		return this:EndInstruction(this, seq, stmts);
	end

	this.__depth = this.__deph + 1;

	local seq = this:StartInstruction("seq", this.__token);

	this:QueueInjectionAfter(seq, this.__token, lcb);

	local stmt = this:Statment_1();

	this.__depth = this.__deph - 1;

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
		this:QueueInjectBefore(inst, this.__token, "GLOBAL");
		this:QueueInjectBefore(inst, this.__token, ".");

		while (this:Accpet("com")) then
			this:Require("var", "Variable expected after comma (,).");
			variables[#variables + 1] = this.__token.data;
			this:QueueInjectBefore(inst, this.__token, "GLOBAL");
			this:QueueInjectBefore(inst, this.__token, ".");
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
					this:QueueInjectBefore(instVar, this.__token, v);
					this:QueueInjectBefore(instVar, this.__token, "+");
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
					this:QueueInjectBefore(instVar, this.__token, v);
					this:QueueInjectBefore(instVar, this.__token, "-");
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
					this:QueueInjectBefore(instVar, this.__token, v);
					this:QueueInjectBefore(instVar, this.__token, "/");
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
					this:QueueInjectBefore(instVar, this.__token, v);
					this:QueueInjectBefore(instVar, this.__token, "-");
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

		inst.injectFunction = this:QueueInjectBefore(expr.token, "bit.bxor");

		this:QueueInjectBefore(expr.token, "(");

		local expr2 = this:Expression_5();

		this:QueueInjectAfter(expr2.token, ")");

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_5(this)
	local expr = this:Expression_6();

	while this:Accept("bor") then
		local inst = this:StartInstruction(expr.token, "bor");

		inst.injectFunction = this:QueueInjectBefore(expr.token, "bit.bor");

		this:QueueInjectBefore(expr.token, "(");

		local expr2 = this:Expression_6();

		this:QueueInjectAfter(expr2.token, ")");

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_6(this)
	local expr = this:Expression_7();

	while this:Accept("band") then
		local inst = this:StartInstruction(expr.token, "band");

		inst.injectFunction = this:QueueInjectBefore(expr.token, "bit.band");

		this:QueueInjectBefore(expr.token, "(");

		local expr2 = this:Expression_7();

		this:QueueInjectAfter(expr2.token, ")");

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

				this:QueueInjectBefore(inst, eqTkn, "eqMult");
				this:QueueInjectBefore(inst, eqTkn, "(");
				this:QueueInjectBefore(inst, eqTkn, ",");
				inst.injectNil = this:QueueInjectBefore(inst, eqTkn, "nil");
				this:QueueReplace(inst, this.__token, ","); -- This is ([)

				local expressions = {};
				expressions[1] = this:Expression_1();

				while this:AcceptToken("com") do
					expressions[#expressions + 1] = this:Expression_1()
				end

				this:QueueInjectAfter(inst, this.__token, ")");

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

				this:QueueInjectBefore(inst, eqTkn, "neqMult");
				this:QueueInjectBefore(inst, eqTkn, "(");
				this:QueueInjectBefore(inst, eqTkn, ",");
				inst.injectNil = this:QueueInjectBefore(inst, eqTkn, "nil");
				this:QueueReplace(inst, this.__token, ","); -- This is ([)

				local expressions = {};
				expressions[1] = this:Expression_1();

				while this:AcceptToken("com") do
					expressions[#expressions + 1] = this:Expression_1()
				end

				this:QueueInjectAfter(inst, this.__token, ")");

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

		inst.injectFunction = this:QueueInjectBefore(expr.token, "bit.lshift");

		this:QueueInjectBefore(expr.token, "(");

		local expr2 = this:Expression_10();

		this:QueueInjectAfter(expr2.token, ")");

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end

function PARSER.Expression_10(this)
	local expr = this:Expression_11();

	while this:Accept("bshr") then
		local inst = this:StartInstruction(expr.token, "bshr");

		inst.injectFunction = this:QueueInjectBefore(expr.token, "bit.rshift");

		this:QueueInjectBefore(expr.token, "(");

		local expr2 = this:Expression_11();

		this:QueueInjectAfter(expr2.token, ")");

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

function PARSER.Expression_14(this)
	local expr = this:Expression_15();

	while this:Accept("exp") then
		local inst = this:StartInstruction(inst, expr.token, "exp");

		local expr2 = this:Expression_15();

		expr = this:EndInstruction(inst, {expr, expr2});
	end

	return expr;
end
