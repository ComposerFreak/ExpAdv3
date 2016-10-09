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
	
	:::Syntax Data:::
	`````````````````
		-- Todo?
		
		:::Block(blck):::
			1 - {stmt*} or stmt
		:::Statments(stmt):::
			1 - if (expr1) blck1 [stmt2 or stmt3] or stmt4
			2 - elseif (expr1) blck1 [stmt2]
			3 - else blck1
			4 - state blck1
			5 - [global] type var[, var*][= exp1][, expr*] or stmt7
			6 - var[, var*][+-/*= exp1][, expr*]

		:::Expressions(expr):::
			1 - (exp1) or exp2
			2 - exp3 op exp2
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

--[[function PARSER.Replace(this, token, str)
	local offset = string.len(str) - string.len(token.data);
	local pre = string.gsub(this.__buffer, 0, this.__offet + token.start);
	local post = string.gsub(this.__buffer, this.__offet + token.stop);
	this.__buffer = pre .. str .. post;
	this.__offset = this.__offset + offset;
end

function PARSER.Remove(this, token)
	this:Replace(this, token, "");
end

function PARSER.InjectBefore(this, token, str)
	local pre = string.gsub(this.__buffer, 0, this.__offet + token.start - 1);
	local post = string.gsub(this.__buffer, this.__offet + token.start);
	this.__buffer = pre .. str .. post;
	this.__offset = this.__offset + string.len(str);
end

function PARSER.InjectAfter(this, token, str)
	local pre = string.gsub(this.__buffer, 0, this.__offet + token.stop);
	local post = string.gsub(this.__buffer, this.__offet + token.stop + 1);
	this.__buffer = pre .. str .. post;
	this.__offset = this.__offset + string.len(str);
end]]

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

function PARSER.Statment_7(this)
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

	return this:Statment_7()
end;