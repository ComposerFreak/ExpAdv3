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

		:::Statements:::
			Stmt1 ← ("try" Block "(" Var ")" Block)? Stmt2
			Stmt2 ← ("if" Cond Block Stmt3)? Stmt5
			Stmt3 ← ("elseif" Cond Block Stmt3)? Stmt4
			Stmt4 ← ("else" Block)
			Stmt5 ← (("for" "(" Type "=" Expr1 ")" Block) / ("while" Cond Block))? Stmt6
			Stmt6 ← (("server" / "client") Block)? Stmt7
			Stmt7 ← "global"? (type (Var("," Var)* "="? (Expr1? ("," Expr1)*)))? Stmt8
			Stmt8 ← (type (Var("," Var)* ("=" / "+=" / "-=" / "/=" / "*=")? (Expr1? ("," Expr1)*)))? Stmt9
			Stmt9 ← ("delegate" "(" (Type ((",")?)*)?) ")" ("{")? "return" Num ("}")?)? Stmt10
			Stmt10 ← (("return" (Expr1 ((","")?)*)?) / "continue", "break")?
			
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
			Expr17 ← (Epxr18 "instanceof" Type)? Expr18
			Expr18 ← ("+" Expr24)? Exp19
			Expr19 ← ("-" Expr24)? Exp20
			Expr2 ← ("!" Expr24)? Expr21
			Expr21 ← ("#" Expr24)? Expr22
			Expr22 ← (("$" / "~") Var)? Expr23
			Expr23 ← ("("type")" Expr1)? Expr24
			Expr24 ← ("(" Expr1 ")" (Trailing)?)? Expr25
			Expr25 ← (Library "." Function  "(" (Expr1 ((",")?)*)?) ")")? Expr26
			Expr26 ← (Var (Trailing)?)? Expr27
			Expr27 ← ("new" Type "(" (Expr1 ((","")?)*)?) ")")? Expr28
			Expr28 ← ("Function" Params Block1)? Expr29
			Expr29 ← Expr30? Error
			Expr30 ← (String / Number / "true" / "false", "void")?

		:::Syntax:::
			Cond 		← "(" Expr1 ")"
			Block 		← "{" (Stmt1 ((";" / " ") Stmt1)*)? "}"
			Values 		← "[" Expr1 ("," Expr1)* "]"
			Raw 		← (Str / Num / Bool)
			Trailing 	← (Method / Get /Call)?
			Method 		← (("." Method "(" (Expr1 ((","")?)*)?) ")")
			Get 		← ("[" Expr1 ("," Type)? "]")
			Call 		← ("(" (Expr1 ((","")?)*)?) ")")?
			Params 		← ("(" (Type Var (("," Type Var)*)?)? ")")

]]

local function name(id)
	local obj = EXPR_LIB.GetClass(id);
	return obj and obj.name or id;
end

--[[
]]

local PARSER = {};
PARSER.__index = PARSER;

function PARSER.New()
	return setmetatable({}, PARSER);
end

function PARSER.Initialize(this, instance, files)
	this.__pos = 0;
	this.__depth = 0;
	this.__scopeID = 0;
	this.__scope = {[0] = {classes = {}}};
	this.__scopeData = this.__scope;

	this.__instructions = {};
	this.stmt_deph = 0;
	this.__token = instance.tokens[0];
	this.__next = instance.tokens[1];
	this.__total = #instance.tokens;
	this.__tokens = instance.tokens;
	this.__script = instance.script;

	--this.__tasks = {};

	this.__directives = {};
	this.__directives.inport = {};
	this.__directives.outport = {};
	this.__directives.includes = {};

	this.__files = files;
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
	--result.tasks = this.__tasks
	result.tokens = this.__tokens;
	result.directives = this.__directives;

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


function PARSER.PushScope(this)
	this.__scope = {};
	this.__scope.classes = {};
	this.__scopeID = this.__scopeID + 1;
	this.__scopeData[this.__scopeID] = this.__scope;
end

function PARSER.PopScope(this)
	this.__scopeData[this.__scopeID] = nil;
	this.__scopeID = this.__scopeID - 1;
	this.__scope = this.__scopeData[this.__scopeID];
end

function PARSER.SetOption(this, option, value, deep)
	if (not deep) then
		this.__scope[option] = value;
	else
		for i = this.__scopeID, 0, -1 do
			local v = this.__scopeData[i][option];

			if (v) then
				this.__scopeData[i][option] = value;
				break;
			end
		end
	end
end

--[[
]]

function PARSER.GetOption(this, option, nonDeep)
	if (this.__scope[option]) then
		return this.__scope[option];
	end

	if (not nonDeep) then
		for i = this.__scopeID, 0, -1 do
			local v = this.__scopeData[i][option];

			if (v) then
				return v;
			end
		end
	end
end

function PARSER.SetUserObject(this, name, scope)
	if (not scope) then
		scope = this.__scopeID;
	end

	if (not name) then debug.Trace() end

	local class = {};
	class.name = name;
	class.scope = scope;
	this.__scopeData[scope].classes[name] = class;

	return scope, class;
end

function PARSER.GetUserObject(this, name, scope, nonDeep)
	if (not scope) then
		scope = this.__scopeID;
	end

	local v = this.__scopeData[scope].classes[name];

	if (v) then
		return v.scope, v;
	end

	if (not nonDeep) then
		for i = scope, 0, -1 do
			local v = this.__scopeData[i].classes[name];

			if (v) then
				return v.scope, v;
			end
		end
	end
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
			local tokenType = tkn.type;

			if (tokenType == "var" and this:GetUserObject(tkn.data)) then
				tokenType = "typ";
			end

			if (tokenType == t) then
				return true;
			end
		end
	end

	return false;
end


function PARSER.Accept(this, type, ...)
	if (this:CheckToken(type, ...)) then
		--print("Accept(" .. type .. ", " .. this.__next.data .. ") -> ", this.cur_instruction and this.cur_instruction.type or "?")
		this:Next();
		return true;
	end

	return false;
end

function PARSER.AcceptWithData(this, type, data)
	if (this:CheckToken(type) and this.__next.data == data) then
		--print("AcceptWithData(" .. type .. ", " .. data .. ") -> ", this.cur_instruction and this.cur_instruction.type or "?")
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

function PARSER.OffsetToken(this, token, offset)
	local pos = token.index + offset;

	local token = this.__tokens[pos];

	return token;
end

function PARSER.StepBackward(this, steps)

	if (not steps) then
		steps = 1;
	end

	local pos = this.__pos - (steps + 1);

	if (pos > this.__total) then
		pos = this.__total;
	end

	this.__pos = pos;

	this:Next();
end

function PARSER.GotoToken(this, token, offset)

	if (not offset) then
		offset = 0;
	end

	local pos = token.index - (offset + 1);

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

function PARSER.CheckForSequence(this, type, ...)
	local tkn = this.__token;

	if (not tkn) then
		return false;
	end

	if (not this:Accept(type)) then
		return false;
	end

	local res = true;
	local types = {...};

	for i = 1, #types do
		res = this:Accept(types[i]);

		if (not res) then
			break;
		end
	end

	this:GotoToken(tkn);

	return res;
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

function PARSER.LastInStatment(this, token, type, endType)
	local last;
	local i = token.index;

	while (i <= this.__total) do
		local tkn = this.__tokens[i];

		if (not tkn) then
			break;
		end

		if (tkn.type == "sep" or tkn.line ~= token.line) then
			break;
		end

		if (tkn.type == type) then
			last = tkn;
		elseif (endType and tkn.type == endType) then
			break;
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
	end; return this.__token;
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

function PARSER.StartInstruction(this, _type, token, perfhandler)

	if (not istable(token)) then
		debug.Trace();
		error("PARSER:StartInstruction got bad token type " .. tostring(token));
	elseif (not type(_type) == "string") then
		debug.Trace();
		error("PARSER:StartInstruction got bad instruction type " .. tostring(_type));
	elseif (not type(token) == "table") then
		debug.Trace();
		error("PARSER:StartInstruction got bad instruction token " .. tostring(token));
	end

	local inst = {};
	inst.type = _type;
	inst.perfhandler = perfhandler;

	inst.rCount = 0;
	inst.result = "void";

	inst.token = token;
	inst.start = token;
	inst.char = token.char;
	inst.line = token.line;

	--inst.tokens = {all = {}};
	--inst.instructions = {all = {}};
	inst.parent = this.cur_instruction;

	inst.depth = this.__depth;
	inst.scope = this.__scope;

	this.cur_instruction = inst;
	this.__depth = this.__depth + 1;
	this.stmt_deph = this.stmt_deph + 1;

	return inst;
end

function PARSER.SetEndResults(this, inst, type, count)
	inst.result = type;
	inst.rCount = count or 1;
end

function PARSER.EndInstruction(this, inst, data)

	inst.data = data or {};
	inst.final = this.__token;
	this.cur_instruction = inst.parent;

	this.__depth = this.__depth - 1;
	this.stmt_deph = this.stmt_deph + 1;

	return inst;
end

--[[
]]

function PARSER.Root(this)
	local seq = this:StartInstruction("root", this.__tokens[1], true);

	local stmts = this:Statements(false);

	return this:EndInstruction(seq, {stmts = stmts});
end

function PARSER.Block_1(this, _end, lcb, returnable)
	this:ExcludeWhiteSpace( "Further input required at end of code, incomplete statement" )

	if (this:Accept("lcb")) then
		local stmts;
		local seq = this:StartInstruction("seq", this.__token, true);

		if (not this:CheckToken("rcb")) then
			this:PushScope();

			stmts = this:Statements(true);

			this:PopScope();
		end

		if (not this:Accept("rcb")) then
			this:Throw(this.__token, "Right curly bracket (}) missing, to close block got " .. this.__token.type);
		end

		return this:EndInstruction(seq, {stmts = stmts});
	end

	do
		local seq = this:StartInstruction("seq", this.__next);

		this:PushScope()

		local stmt = this:Statment_1();

		this:Accept("sep");
		
		this:PopScope()

		return this:EndInstruction(seq, {stmts = {stmt}});
	end
end

function PARSER.Block_2(this)
	this:ExcludeWhiteSpace( "Further input required at end of code, incomplete statement" )

	this:Require("lcb", "Left curly bracket ({) missing for constructor");

	local stmts;
	local seq = this:StartInstruction("seq", this.__token, true);

	if (not this:CheckToken("rcb")) then
		this:PushScope();

		stmts = this:Statements(true, this.ConstructorStatment);

		this:PopScope();
	end

	if (not this:Accept("rcb")) then
		this:Throw(this.__token, "Right curly bracket (}) missing, to close constructor got " .. this.__token.type);
	end

	return this:EndInstruction(seq, {stmts = stmts});
end

function PARSER.ConstructorStatment(this, stmtc)
	
	if (this:Accept("sup")) then
		
		if (stmtc > 0) then
			this:Throw(this.__token, "Super constructor can not appear here.");
		end

		local seq = this:StartInstruction("supconst", this.__token, true);

		this:Require("lpa", "Left parenthesis (( ) expected to open super constructor parameters.")

		local expressions = {};

		if (not this:CheckToken("rpa")) then
			expressions[1] = this:Expression_1();

			while(this:Accept("com")) do
				this:Exclude("rpa", "Expression or value expected after comma (,).");

				expressions[#expressions + 1] = this:Expression_1();
			end

		end

		this:Require("rpa", "Right parenthesis ( )) expected to close super constructor parameters.");

		return this:EndInstruction(seq, {expressions = expressions});
	end

	return this:Statment_0();
end

--[[

]]

function PARSER.Directive_NAME(this, token, directive)
	this:Require("str", "String expected to follow directive @name");

	if (this.FirstStatment) then
		this:Throw(token, "Directive @name must appear towards the top of your code");
	elseif (this.__directives.name) then
		this:Throw(token, "Directive @name must not appear twice.");
	end

	this.__directives.name = this.__token.data;
end

function PARSER.Directive_MODEL(this, token, directive)
	this:Require("str", "String expected to follow directive @model");

	if (this.FirstStatment) then
		this:Throw(token, "Directive @model must appear towards the top of your code");
	elseif (this.__directives.model) then
		this:Throw(token, "Directive @model must not appear twice.");
	end

	this.__directives.model = this.__token.data;
end

function PARSER.Directive_INCLUDE(this, token, directive)
	this:Require("str", "String expected to follow directive @include");

	local inst = this:StartInstruction("include", token);

	if (this.FirstStatment) then
		this:Throw(token, "Directive @include must appear towards the top of your code");
	end

	local includes = this.__directives.includes or {};


	local file_path = string.sub(this.__token.data, 2, -2);

	local exists;

	if (CLIENT) then
		exists = file.Exists("golem/" .. file_path .. ".txt", "DATA");
	elseif (SERVER) then
		exists = this.__files[file_path] ~= nil;
	end

	if (not exists) then
		this:Throw(token, "No sutch file %s", file_path);
	end

	if (includes[file_path]) then
		this:Throw(token, "File %s, allready included.", file_path);
	end

	includes[file_path] = file_path;

	return this:EndInstruction(inst, {file = file_path});
end

function PARSER.Directive_INPUT(this, token, directive)
	this:Require("typ", "Class expected for inport type, after @input");

	local inst = this:StartInstruction("inport", token);

	local port_type = this.__token.data;

	local class_obj = EXPR_LIB.GetClass(port_type);

if (not class_obj.wire_in_class) then
		this:Throw(token, "Invalid wire port, class %s can not be used for wired input.", class_obj.name);
	end

	local variables = {};

	this:Require("var", "Variable('s) expected after class for inport name.");

	variables[1] = this.__token;

	while (this:Accept("com")) do
		this:Require("var", "Variable expected after comma (,).");

		variables[#variables + 1] = this.__token;
	end

	return this:EndInstruction(inst, {class = class_obj.id, variables = variables, wire_type = class_obj.wire_in_class, wire_func = class_obj.wire_in_func});
end

function PARSER.Directive_OUTPUT(this, token, directive)
	this:Require("typ", "Class expected for outport type, after @output");

	local inst = this:StartInstruction("outport", token);

	local port_class = this.__token.data;

	local class_obj = EXPR_LIB.GetClass(port_class);

	if (not class_obj.wire_out_class) then
		this:Throw(token, "Invalid wire port, class %s can not be used for wired output.", class_obj.name);
	end

	local variables = {};

	this:Require("var", "Variable('s) expected after class for output name.");

	variables[1] = this.__token;

	while (this:Accept("com")) do
		this:Require("var", "Variable expected after comma (,).");

		variables[#variables + 1] = this.__token;
	end

	return this:EndInstruction(inst, {class = class_obj.id, variables = variables, wire_type = class_obj.wire_out_class, wire_func = class_obj.wire_out_func, wire_func2 = class_obj.wire_out_func});
end

--[[
]]

function PARSER.Statements(this, block, call)
	local sep = false;
	local stmts = {};

	call = call or this.Statment_0;

		while true do

			local stmt = call(this, #stmts);

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

function PARSER.Statment_0(this)
	local sep;
	local dirLine;

	while this:Accept("dir") do
		local token = this.__token;
		dirLine = this.__token.line;

		if (not this:Accept("var")) then
			this:Throw(token, "Directive name exspected after @");
		end

		local directive = this.__token.data;

		local func = this["Directive_" .. string.upper(directive)]

		if (not func) then
			this:Throw(token, "No such directive @%s", directive);
		end

		local instr = func(this, token, directive);

		sep = this:Accept("sep");

		if (instr) then
			return instr
		end

		if (!this:HasTokens()) then
			return;
		end
	end

	if (this:CheckToken("cls")) then
		return this:ClassStatment_0();
	end

	if (this:CheckToken("itf")) then
		return this:InterfaceStatment_0();
	end

	local stmt = this:Statment_1();

	if (dirLine and (not sep or direLine == stmt.line)) then
		this:Throw(stmt.token, "Statements must be separated by semicolon (;) or newline")
	end

	return stmt;
end;


function PARSER.Statment_1(this)
	if (this:Accept("try")) then
		local inst = this:StartInstruction("try", this.__token);

		local block1 = this:Block_1(true, "function()");

		this:Require("cth", "Catch expected after try statment, for try catch");

		this:Require("lpa", "Left parenthesis (( ) expected after catch.");

		local var = this:Require("var", "Variable expected for error object, catch(variable)");

		this:Require("rpa", "Right parenthesis ( )) expected to end catch.");

		local block2 = this:Block_1(false, "then");

		return this:EndInstruction(inst, {block1 = block1; var = var; block2 = block2});
	end

	return this:Statment_2();
end

function PARSER.Statment_2(this)
	if (this:Accept("if")) then
		local inst = this:StartInstruction("if", this.__token);

		local condition = this:GetCondition();

		local block = this:Block_1(false, "then");

		local eif = { this:Statment_3() };

		if (#eif > 0) then
			while true do
				local stmt = this:Statment_3();

				if not stmt then
					break;
				end

				eif[#eif + 1] = stmt;
			end
		end

		eif[#eif + 1] = this:Statment_4();

		return this:EndInstruction(inst, {condition = condition; block = block; eif = eif});
	end

	return this:Statment_5();
end

function PARSER.Statment_3(this)
	if (this:Accept("eif")) then
		local inst = this:StartInstruction("elseif", this.__token);

		local condition = this:GetCondition();

		local block = this:Block_1(false, "then");

		return this:EndInstruction(inst, {condition = condition; block = block;});
	end

	return this:Statment_4();
end

function PARSER.Statment_4(this)
	if (this:Accept("els")) then
		local inst = this:StartInstruction("else", this.__token);

		local block = this:Block_1(false, "");

		return this:EndInstruction(inst, {block = block});
	end
end



--[[
]]


function PARSER.Statment_5(this)
	if (this:Accept("for")) then
		local inst = this:StartInstruction("for", this.__token);

		this:Require("lpa", "Left parenthesis (( ) expected after for.");

		local iClass = this:Require("typ", "Class expected for loop itorator");

		local iVar = this:Require("var", "Assigment expected for loop definition.");

		this:Require("ass", "Assigment expected for loop definition.");

		local expressions = {};

		expressions[1] = this:Expression_1();

		this:Require("sep", "Seperator expected after loop decleration.");

		expressions[2] = this:Expression_1();

		if (this:Accept("sep")) then
			expressions[3] = this:Expression_1();
		end

		this:Require("rpa", "Right parenthesis ( )) expected to close cloop defintion.");

		local block = this:Block_1(true);

		return this:EndInstruction(inst, {iClass = iClass; iVar = iVar; expressions = expressions, block = block});
	end

	if (this:Accept("whl")) then
		local inst = this:StartInstruction("while", this.__token);

		local condition = this:GetCondition();

		local block = this:Block_1(true);

		return this:EndInstruction(inst, {condition = condition; block = block});
	end

	if (this:Accept("each")) then
		local inst = this:StartInstruction("each", this.__token);

		this:Require("lpa", "Left parenthesis (() ) expected to close cloop defintion.");

		this:Require("typ", "Class expected after lpa, for foreach loop")

		local a = this.__token.data

		this:Require("var", "Variable expected after class, for foreach loop")

		local b = this.__token.data

		local kType, kValue;

		if (this:Accept("as")) then
			kType, kValue = a, b;

			this:Require("typ", "Class expected after as, for foreach loop")
			a = this.__token.data

			this:Require("var", "Variable expected after class, for foreach loop")
			b = this.__token.data
		end

		vType, vValue = a, b;

		this:Require("in", "In expected after variable, for foreach loop");

		local expr = this:Expression_1();

		this:Require("rpa", "Right parenthesis ( )) expected to close loop defintion.");

		local block = this:Block_1(true, "do");

		return this:EndInstruction(inst, {expr = expr; vType = vType; vValue = vValue; kType = kType, kValue = kValue, block = block});
	end

	return this:Statment_6();
end

function PARSER.Statment_6(this)
	if (this:Accept("sv")) then
		local inst = this:StartInstruction("server", this.__token);

		local block = this:Block_1(true, "then");

		return this:EndInstruction(inst, {block = block});
	end

	if (this:Accept("cl")) then
		local inst = this:StartInstruction("client", this.__token);

		local block = this:Block_1(true, "then");

		return this:EndInstruction(inst, {block = block});
	end

	return this:Statment_7();
end

--[[
]]

function PARSER.Statment_7(this)
	if (this:Accept("glo")) then
		local inst = this:StartInstruction("global", this.__token);

		this:Require("typ", "Class expected after global.");

		local var_type = this.__token.data;

		local variables = {};

		this:Require("var", "Variable('s) expected after class for global variable.");
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

		return this:EndInstruction(inst, {var_type = var_type; variables = variables; expressions = expressions});
	end

	if (this:Accept("typ")) then
		local inst = this:StartInstruction("local", this.__token);

		local var_type = this.__token.data;

		if ((var_type == "f" and this:CheckToken("typ")) or this:CheckToken("lpa")) then
			this:StepBackward(1);
			return this:Statment_8()
		end

		local variables = {};

		variables[1] = this:Require("var", "Variable('s) expected after class for variable.");

		while (this:Accept("com")) do
			variables[#variables + 1] = this:Require("var", "Variable expected after comma (,).");
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

		return this:EndInstruction(inst, {class = var_type; variables = variables; expressions = expressions});
	end

	return this:Statment_8()
end

function PARSER.Statment_8(this)
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

			local expressions = {};

			if (this:Accept("ass")) then
				this:ExcludeWhiteSpace( "Assignment operator (=), must not be preceded by whitespace." );

				expressions[1] = this:Expression_1();

				while (this:Accept("com")) do
					this:ExcludeWhiteSpace( "comma (,) must not be preceeded by whitespace." );
					expressions[#expressions + 1] = this:Expression_1();
				end

				return this:EndInstruction(inst, {expressions = expressions; variables = variables});
			end

			if (this:Accept("aadd", "asub", "amul", "adiv")) then
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

				return this:EndInstruction(inst, {expressions = expressions; variables = variables});
			end

			this:Throw(inst.token, "Variable can not be preceded by whitespace.");
		end
	end
	
	return this:Statment_9();
end

function PARSER.GetTypeInputs(this)
	
	if ( this:Accept("cst") ) then
		return {this.__token.data};
	end

	this:Require("lpa", "Left parenthesis (( ) expected to open delegate parameters.");

	local parameters = {};

	if (not this:CheckToken("rpa")) then

		while (true) do
			this:Require("typ", "Parameter type expected for parameter.");

			parameters[#parameters + 1] = this.__token.data;

			if (not this:Accept("com")) then
				break;
			end
		end
	end

	this:Require("rpa", "Right parenthesis ( )) expected to close delegate parameters.");

	return parameters;
end

function PARSER.Statment_9(this)
	if (this:Accept("del")) then
		local inst = this:StartInstruction("delegate", this.__token);

		this:Require("typ", "Return class expected after delegate.");

		local result_class = this.__token.data;

		this:Require("var", "Delegate name expected after delegate return class.")

		local variable = this.__token.data;

		local parameters = this:GetTypeInputs();

		local lcb = this:Accept("lcb");

		this:Require("ret", "Delegate body must be return followed by return count");

		this:Require("num", "Delegate body must be return followed by return count as number.");

		local result_count = this.__token.data;

		this:Accept("sep")

		if (lcb) then
			this:Require("rcb", "Right curly bracket ( }) expected to close delegate.");
		end

		return this:EndInstruction(inst, {result_class= result_class;  variable = variable;  parameters = parameters;  result_count = result_count });
	end

	return this:Statment_10();
end

function PARSER.Statment_10(this)
	if (this:AcceptWithData("typ", "f")) then

		local inst = this:StartInstruction("funct", this.__token);

		this:Require("typ", "Return class expected after user function.");

		local resultClass = this.__token.data;

		this:Require("var", "Function name expected after user function return class.")

		local variable = this.__token.data;

		local params, signature = this:InputParameters(inst);

		local block = this:Block_1(true, " ");

		return this:EndInstruction(inst, {resultClass = resultClass; variable = variable; params = params; signature = signature; block = block});
	end

	return this:Statment_11();
end

function PARSER.Statment_11(this)
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

		this:Accept("sep");

		return this:EndInstruction(inst, {expressions = expressions});
	end

	if (this:Accept("cnt")) then
		local inst = this:StartInstruction("continue", this.__token);
		this:Accept("sep");
		return this:EndInstruction(inst, expressions);
	end

	if (this:Accept("brk")) then
		local inst = this:StartInstruction("break", this.__token);
		this:Accept("sep");
		return this:EndInstruction(inst, expressions);
	end

	local expr = this:Expression_1();

	if (expr and this:CheckToken("lsb")) then
		expr = this:Statment_12(expr);
	elseif (expr and this:CheckToken("prd")) then
		expr = this:Statment_13(expr);
	end

	return expr;
end

function PARSER.Statment_12(this, expr)
	if (this:Accept("lsb")) then
		local inst = this:StartInstruction("set", expr.token);

		local class;
		local expressions = {};

		expressions[1] = expr;

		expressions[2] = this:Expression_1();

		if (this:Accept("com")) then
			this:Require("typ", "Class expected for index operator, after coma (,).");

			class = E3Class(this.__token.data);

			if (class) then class = class.id; end
		end

		this:Require("rsb", "Right square bracket (]) expected to close index operator.");

		this:Require("ass", "Assigment operator (=) expected after index operator.");

		expressions[3] = this:Expression_1();

		return this:EndInstruction(inst, {class = class, expressions = expressions});
	end
end

function PARSER.Statment_13(this, expr)
	if (this:Accept("prd")) then
		local inst = this:StartInstruction("set_field", expr.token);
		local var = this:Require("var", "Attribute expected after (.)");
		this:Require("ass", "Assigment operator (=) expected after index operator.");
		return this:EndInstruction(inst, {var = var; expressions = {expr, this:Expression_1()}});
	end
end

--[[
]]

function PARSER.Expression_1(this)
	local expr = this:Expression_2();

	while this:Accept("qsm") do
		local inst = this:StartInstruction("ten", expr.token);

		local expr2 = this:Expression_2();

		this:Require("col", "colon (:) expected for ternary operator.");

		local expr3 = this:Expression_2();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2; expr3 = expr3});
	end

	return this:Expression_Trailing(expr);
end

function PARSER.Expression_2(this)
	local expr = this:Expression_3();

	while this:Accept("or") do
		local inst = this:StartInstruction("or", expr.token);

		local expr2 = this:Expression_3();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_3(this)
	local expr = this:Expression_4();

	while this:Accept("and") do
		local inst = this:StartInstruction("and", expr.token);

		local expr2 = this:Expression_4();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_4(this)
	local expr = this:Expression_5();

	while this:Accept("bxor") do
		local inst = this:StartInstruction("bxor", expr.token);

		local expr2 = this:Expression_5();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_5(this)
	local expr = this:Expression_6();

	while this:Accept("bor") do
		local inst = this:StartInstruction("bor", expr.token);

		local expr2 = this:Expression_6();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_6(this)
	local expr = this:Expression_7();

	while this:Accept("band") do
		local inst = this:StartInstruction("band", expr.token);

		local expr2 = this:Expression_7();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_7(this)
	local expr = this:Expression_8();

	while this:CheckToken("eq", "neq") do
		if (this:Accept("eq")) then

			if (this:Accept("lsb")) then
				local inst = this:StartInstruction("eq_mul", expr.token);

				local expressions = {};

				expressions[1] = expr;

				expressions[2] = this:Expression_1();

				while this:Accept("com") do
					expressions[#expressions + 1] = this:Expression_1();
				end

				expr = this:EndInstruction(inst, {expressions = expressions});

				this:Require("rsb", "Right suare bracket required to close mutliple comparason list");
			else
				local inst = this:StartInstruction("eq", expr.token);

				inst.__operator = this.__token;

				local expr2 = this:Expression_8();

				expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
			end
		elseif (this:Accept("neq")) then

			if (this:Accept("lsb")) then
				local inst = this:StartInstruction("neq_mul", expr.token);

				local expressions = {};

				expressions[1] = expr;

				expressions[2] = this:Expression_1();

				while this:Accept("com") do
					expressions[#expressions + 1] = this:Expression_1();
				end

				expr = this:EndInstruction(inst, {expressions = expressions});

				this:Require("rsb", "Right suare bracket required to close mutliple comparason list");
			else
				local inst = this:StartInstruction("neq", expr.token);

				local expr2 = this:Expression_8();

				expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
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

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
		elseif (this:Accept("leq")) then
			local inst = this:StartInstruction("leq", expr.token);

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
		elseif (this:Accept("gth")) then
			local inst = this:StartInstruction("gth", expr.token);

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
		elseif (this:Accept("geq")) then
			local inst = this:StartInstruction("geq", expr.token);

			local expr2 = this:Expression_1();

			expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
		end
	end

	return expr;
end

function PARSER.Expression_9(this)
	local expr = this:Expression_Trailing( this:Expression_10() );

	while this:Accept("bshl") do
		local inst = this:StartInstruction("bshl", expr.token);

		local expr2 = this:Expression_10();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_10(this)
	local expr = this:Expression_Trailing( this:Expression_11() );

	while this:Accept("bshr") do
		local inst = this:StartInstruction("bshr", expr.token);

		local expr2 = this:Expression_11();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_11(this)
	local expr = this:Expression_Trailing( this:Expression_12() );

	while this:Accept("add") do
		local inst = this:StartInstruction("add", expr.token);

		local expr2 = this:Expression_12();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_12(this)
	local expr = this:Expression_Trailing( this:Expression_13() );

	while this:Accept("sub") do
		local inst = this:StartInstruction("sub", expr.token);

		local expr2 = this:Expression_13();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_13(this)
	local expr = this:Expression_Trailing( this:Expression_14() );

	while this:Accept("div") do
		local inst = this:StartInstruction("div", expr.token);

		local expr2 = this:Expression_14();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_14(this)

	local expr = this:Expression_Trailing( this:Expression_15() );

	while this:Accept("mul") do
		local inst = this:StartInstruction("mul", expr.token);

		local expr2 = this:Expression_15();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_15(this)
	local expr = this:Expression_Trailing( this:Expression_16() );

	while this:Accept("exp") do
		local inst = this:StartInstruction("exp", expr.token);

		local expr2 = this:Expression_16();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_16(this)
	local expr = this:Expression_Trailing( this:Expression_17() );

	while this:Accept("mod") do
		local inst = this:StartInstruction("mod", expr.token);

		local expr2 = this:Expression_17();

		expr = this:EndInstruction(inst, {expr = expr; expr2 = expr2});
	end

	return expr;
end

function PARSER.Expression_17(this)
	local expr = this:Expression_Trailing( this:Expression_18() );

	if this:Accept("iof") then
		local inst = this:StartInstruction("iof", expr.token);

		this:Require("typ", "class expected after instanceof");

		return this:EndInstruction(inst, {expr = expr, class = this.__token.data});
	end

	return expr;
end

function PARSER.Expression_18(this)
	if (this:Accept("add")) then
		this:ExcludeWhiteSpace("Identity operator (+) must not be succeeded by whitespace");

		return this:Expression_19();
	end

	return this:Expression_19();
end

function PARSER.Expression_19(this)
	if (this:Accept("sub")) then
		local inst = this:StartInstruction("neg", this.__token);

		this:ExcludeWhiteSpace("Negation operator (-) must not be succeeded by whitespace");

		local expr = this:Expression_1();

		return this:EndInstruction(inst, {expr = expr});
	end

	return this:Expression_20();
end

function PARSER.Expression_20(this)
	if (this:Accept("not")) then
		local inst = this:StartInstruction("not", this.__token);

		this:ExcludeWhiteSpace("Not operator (!) must not be succeeded by whitespace");

		local expr = this:Expression_1();

		return this:EndInstruction(inst, {expr = expr});
	end

	return this:Expression_21();
end

function PARSER.Expression_21(this)
	if (this:Accept("len")) then
		local inst = this:StartInstruction("len", this.__token);

		this:ExcludeWhiteSpace("Length operator (#) must not be succeeded by whitespace");

		local expr = this:Expression_24();

		return this:EndInstruction(inst, {expr = expr});
	end

	return this:Expression_22();
end

function PARSER.Expression_22(this)
	if (this:Accept("dlt")) then
		local inst = this:StartInstruction("delta", this.__token);

		this:ExcludeWhiteSpace("Delta operator (#) must not be succeeded by whitespace");

		this:Require("var", "Gobal variable expected after delta operator ($)")

		return this:EndInstruction(inst, {var = this.__token.data});
	end

	if (this:Accept("cng")) then
		local inst = this:StartInstruction("changed", this.__token);

		this:ExcludeWhiteSpace("Changed operator (~) must not be succeeded by whitespace");

		this:Require("var", "Gobal variable expected after changed operator (~)")

		return this:EndInstruction(inst, {var = this.__token.data});
	end

	return this:Expression_23();
end

function PARSER.Expression_23(this)
	if (this:Accept("cst")) then
		local inst = this:StartInstruction("cast", this.__token);

		local class = this.__token.data;

		this:ExcludeWhiteSpace("Cast operator ( (%s) ) must not be succeeded by whitespace", name(class));

		local expr = this:Expression_1();

		return this:EndInstruction(inst, {class = class, expr = expr});
	end

	local previous = this.__token;

	if (this:Accept("lpa")) then
		local lpa = this.__token;

		if (this:Accept("typ")) then
			local token = this.__token;

			local class = token.data;

			if (this:Accept("rpa")) then
				local inst = this:StartInstruction("cast", token);

				this:ExcludeWhiteSpace("Cast operator ( (%s) ) must not be succeeded by whitespace", name(class));

				local expr = this:Expression_1();

				return this:EndInstruction(inst, {class = class, expr = expr});
			end
		end

		this:GotoToken(previous);

	end

	return this:Expression_24();
end

function PARSER.Expression_24(this)
	if (this:Accept("lpa")) then
		local inst = this:StartInstruction("group", this.__token);

		local expr = this:Expression_1();

		this:Require("rpa", "Right parenthesis ( )) missing, to close grouped equation.");

		return this:EndInstruction(inst, {expr = expr});
	end

	return this:Expression_25();
end

function PARSER.Expression_25(this)
	if (this:CheckToken("var")) then
		local token = this.__next;
		local library = this.__next.data;
		local lib = EXPR_LIBRARIES[library];

		if (lib) then
			this:Next();

			local library = this.__token;

			if (not this:Accept("prd")) then
				this:StepBackward(1);
				return this:Expression_26();
			end

			local name = this:Require("var", "function name expected after library name");

			if not this:Accept("lpa") then
				local inst = this:StartInstruction("const", token);
				return this:EndInstruction(inst, {library = library; name = name.data});
			end

			local inst = this:StartInstruction("func", token);

			local expressions = {};

			if (not this:CheckToken("rpa")) then
				expressions[1] = this:Expression_1();

				while(this:Accept("com")) do
					this:Exclude("rpa", "Expression or value expected after comma (,).");

					expressions[#expressions + 1] = this:Expression_1();
				end

			end

			this:Require("rpa", "Right parenthesis ( )) expected to close function parameters.")

			return this:EndInstruction(inst, {library = library; name = name.data; expressions = expressions});
		end
	end

	return this:Expression_26();
end

function PARSER.Expression_26(this)
	if (this:Accept("var")) then
		local inst = this:StartInstruction("var", this.__token);

		this:EndInstruction(inst, {variable = this.__token.data});

		return this:Expression_Trailing(inst);
	end

	return this:Expression_27()
end

function PARSER.Expression_27(this)

	local new = this:Accept("new");

	if (this:CheckForSequence("typ", "lpa") && this.__next.data ~= "f") then
		new = true;
	end

	if ( new ) then

		local inst = this:StartInstruction("new", this.__token);

		local class = this:Require("typ", "Type expected after new for constructor.");

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

		return this:EndInstruction(inst, {class = class.data; expressions = expressions});
	end

	return this:Expression_28();
end

function PARSER.Expression_28(this)
	if (this:AcceptWithData("typ", "f")) then
		local inst = this:StartInstruction("lambda", this.__token);

		local params, signature = this:InputParameters(inst);

		local block = this:Block_1(true, " ");

		return this:EndInstruction(inst, {params = params; signature = signature; block = block});
	end

	return this:Expression_29();
end

function PARSER.InputParameters(this, inst)
	this:Require("lpa", "Left parenthesis (( ) expected to open function parameters.");

	inst.__lpa = this.__token;

	local signature = {};

	local params = {};


	if (this:Accept("typ")) then

		local class = this.__token.data;

		signature[1] = class;

		this:Require("var", "Parameter expected after %s.", class);

		params[1] = {class, this.__token.data}

		while(this:Accept("com")) do
			this:Require("typ", "Class expected for new parameter.");

			local class = this.__token.data;

			signature[#signature + 1] = class;

			this:Require("var", "Parameter expected after %s.", class);

			params[#params + 1] = {class, this.__token.data}

		end
	end

	this:Require("rpa", "Right parenthesis ( )) expected to close function parameters. %s", this.__next.data);

	return params, table.concat(signature, ",");
end

function PARSER.Expression_29(this)
	expr = this:Expression_30();

	if (expr) then
		return expr;
	end

	this:ExpressionErr();
end

function PARSER.Expression_30(this)
	if (this:Accept("tre")) then
		local inst = this:StartInstruction("bool", this.__token);
		return this:EndInstruction(inst, {value = true});
	elseif (this:Accept("fls")) then
		local inst = this:StartInstruction("bool", this.__token);
		return this:EndInstruction(inst, {value = false});
	elseif (this:Accept("num")) then
		local inst = this:StartInstruction("num", this.__token);
		return this:EndInstruction(inst, {value = this.__token.data});
	elseif (this:Accept("str")) then
		local inst = this:StartInstruction("str", this.__token);
		return this:EndInstruction(inst, {value = this.__token.data});
	elseif (this:Accept("ptr")) then
		local inst = this:StartInstruction("ptrn", this.__token);
		return this:EndInstruction(inst, {value = this.__token.data});
	elseif this:Accept("typ") then
		local inst = this:StartInstruction("cls", this.__token);
		return this:EndInstruction(inst, {value = this.__token.data});
	elseif this:Accept("void") then
		local inst = this:StartInstruction("void", this.__token);
		return this:EndInstruction(inst, {});
	end
end

function PARSER.Expression_Trailing(this, expr)

	while this:CheckToken("prd", "lsb", "lpa") do

		-- Methods
		if (this:Accept("prd")) then
			this.__prd = this.__token;

			local inst = this:StartInstruction("meth", expr.token);

			local method = this:Require("var", "method name expected after method operator (.)");

			local varToken = this.__token;

			if (this:Accept("lpa")) then
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

				this:Require("rpa", "Right parenthesis ( )) expected to close method parameters.");

				expr = this:EndInstruction(inst, {method = method.data; expressions = expressions});
			else
				-- Check for an ass instruction and locate it,
				-- If we are at our set attribute then we break.

				if (this:StatmentContains(varToken, "ass")) then
					local excluded = this:LastInStatment(this:OffsetToken(this.__prd, -1), "prd", "ass");

					if (excluded and excluded.index == this.__prd.index) then
						this:StepBackward(2);
						break;
					end
				end

				inst.type = "field";

				expr = this:EndInstruction(inst, {expr = expr; var = varToken});
			end
		elseif (this:Accept("lsb")) then
			local class;
			local lsb = this.__token;

			local inst = this:StartInstruction("get", expr.token);

			local expressions = {};

			expressions[1] = expr;

			expressions[2] = this:Expression_1();

			if (this:Accept("com")) then

				this:Require("typ", "Class expected for index operator, after coma (,).");

				class = E3Class(this.__token.data);

				if (class) then class = class.id; end
			end

			this:Require("rsb", "Right square bracket (]) expected to close index operator.");

			if (this:CheckToken("ass")) then
				this:GotoToken(expr.final);
				break;
			end

			expr = this:EndInstruction(inst, {expressions = expressions, class = class});
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

			expr = this:EndInstruction(inst, {expressions = expressions});
		end
	end

	return expr;
end

function PARSER.GetCondition(this)
	this:Require("lpa", "Left parenthesis ( () required, to open condition.");

	local inst = this:StartInstruction("cond", this.__token);

	local expr = this:Expression_1();

	this:Require("rpa", "Right parenthesis ( )) missing, to close condition.");

	return this:EndInstruction(inst, {expr = expr});
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
	this:Exclude("dir", "directive operator (@) must not appear inside an equation");

	this:Throw(this.__token, "Unexpected symbol found (%s)", this.__token.type);
end

--[[
]]

function PARSER.ClassStatment_0(this)
	if (this:Accept("cls")) then
		local inst = this:StartInstruction("class", this.__token);

		this:Require("var", "Class name expected after class");

		local extends, implements;
		local classname = this.__token.data;

		this:SetUserObject(classname);

		if (this:Accept("ext")) then
			inst.__ext = this.__token;
			extends = this:Require("typ", "Class name expected after extends");
			inst.__exttype = this.__token;
		end

		if (this:Accept("imp")) then
			this:Require("typ", "Class name expected after implements");

			implements = {this.__token};

			while(this:Accept("com")) do
				this:Require("typ", "Class name expected after implements");

				implements[#implements + 1] = this.__token;
			end
		end

		this:Require("lcb", "Left curly bracket ({) expected, to open class");

		local stmts = {};

		if (not this:CheckToken("rcb")) then
			this:PushScope()

			this:SetOption("curclass", classname);

			stmts = this:Statements(true, this.ClassStatment_1);

			this:PopScope()
		end

		this:Require("rcb", "Right curly bracket (}) missing, to close class");

		return this:EndInstruction(inst, {block = stmts; extends = extends; implements = implements; classname = classname});
	end

	return this:ClassStatment_1();
end

function PARSER.ClassStatment_1(this)
	if (this:Accept("typ")) then
		if (this.__token.data == this:GetOption("curclass") and this:CheckToken("lpa")) then
			this:StepBackward(1);
			return this:ClassStatment_2();
		end

		local inst = this:StartInstruction("def_field", this.__token);

		local type = this.__token.data;

		if (type == "f" and this:CheckToken("typ")) then
			this:StepBackward(1);
			return this:Statment_8();
		end

		local variables = {};

		variables[1] = this:Require("var", "Variable('s) expected after class for variable.");

		while (this:Accept("com")) do
			variables[#variables + 1] = this:Require("var", "Variable expected after comma (,).");
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

		return this:EndInstruction(inst, {type = type; expressions = expressions; variables = variables});
	end

	return this:ClassStatment_2();
end

function PARSER.ClassStatment_2(this)
	local class = this:GetOption("curclass");

	if (this:AcceptWithData("typ", class)) then

		local inst = this:StartInstruction("constclass", this.__token);

		local args, signature = this:InputParameters(inst);

		local block = this:Block_2(true, " ");

		return this:EndInstruction(inst, {args = args; signature = signature; block = block});
	end

	return this:ClassStatment_3();
end

function PARSER.ClassStatment_3(this)
	if (this:Accept("meth")) then
		local inst = this:StartInstruction("def_method", this.__token);

		local typ = this:Require("typ", "Return type expected for method, after method.");

		local var = this:Require("var", "Name expected for method, after %s", name(typ.data));

		local params, signature = this:InputParameters(inst);

		local block = this:Block_1(true, " ");

		return this:EndInstruction(inst, {var = var; type = typ; args = params; signature = signature; block = block});
	end

	return this:ClassStatment_4()
end

function PARSER.ClassStatment_4(this)
	if (this:AcceptWithData("var", "tostring")) then
		local inst = this:StartInstruction("tostr", this.__token);
		inst.__var = this.__token;

		local params, signature = this:InputParameters(inst);

		if (#params > 0) then
			this:Throw(inst.__var, "The tostring operation does not take any parameters.");
		end

		local block = this:Block_1(true, " ");

		return this:EndInstruction(inst, {params = params; signature = signature, block = block});
	end

	this:Throw(this.__token, "Right curly bracket (}) expected, to close class.");
end

--[[
]]

function PARSER.InterfaceStatment_0(this)
	if (this:Accept("itf")) then
		local inst = this:StartInstruction("interface", this.__token);

		local interface = this:Require("var", "Interface name expected after class");

		this:SetUserObject(interface.data);

		this:Require("lcb", "Left curly bracket ({) expected, to open interface");

		local stmts = {};

		if (not this:CheckToken("rcb")) then
			this:PushScope()

			this:SetOption("interface", interface.data);
			stmts = this:Statements(true, this.InterfaceStatment_1);

			this:PopScope()
		end

		this:Require("rcb", "Right curly bracket (}) missing, to close interface");

		return this:EndInstruction(inst, {interface = interface.data; stmts = stmts});
	end

	this:Throw(this.__token, "Right curly bracket (}) expected, to close interface.");
end

--[[
]]

function PARSER.InterfaceStatment_1(this)
	if (this:Accept("meth")) then
		local inst = this:StartInstruction("interface_method", this.__token);

		local result = this:Require("typ", "Return type expected for method, after method.");

		local name = this:Require("var", "Name expected for method, after %s", name(result.data));

		this:Require("lpa", "Left parenthesis ( () expected to close method parameters.");

		local params = {};

		if (not this:CheckToken("rpa")) then

			while (true) do
				this:Require("typ", "Parameter type expected for parameter.");

				params[#params + 1] = this.__token.data;

				if (not this:Accept("com")) then
					break;
				end

			end

		end

		this:Require("rpa", "Right parenthesis ( )) expected to close method parameters.");

		local lcb = this:Accept("lcb");

		this:Require("ret", "Method body must be return followed by return count");

		local count = this:Require("num", "Method body must be return followed by return count as number.");

		this:Accept("sep");

		if (lcb) then
			this:Require("rcb", "Right curly bracket ( }) expected to close method.");
		end

		return this:EndInstruction(inst, {params = params, result = result, name = name, count = count});
	end
end

EXPR_PARSER = PARSER;
