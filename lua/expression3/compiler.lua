--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Compiler::
]]

local COMPILER = {};
COMPILER.__index = COMPILER;

function COMPILER.New()
	return setmetatable({}, COMPILER);
end

function COMPILER.Initalize(this, instance)
	this.__tokens = instance.tokens;
	this.__tasks = instance.tasks;
	this.__root = instance.instruction;
	this.__script = instance.script;

	this.__scope = {};
	this.__scopeID = 0;
	this.__scopeData = {};
	this.__scopeData[0] = this.__scope;

	this.__scope.memory = {};
	this.__scope.server = true;
	this.__scope.client = true;

	this.__operators = {};
	this.__functions = {};
	this.__methods = {};
	this.__enviroment = {};
end

function COMPILER.Run(this)
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

function COMPILER._Run(this)
	this:Compile(this.__root);

	local script = this:BuildScript();

	local result = {}
	result.script = this.__script;
	result.compiled = script;
	result.operators = this.__operators;
	result.functions = this.__functions;
	result.methods = this.__methods;
	result.enviroment = this.__enviroment;

	return result;
end

function COMPILER.BuildScript(this)
	-- This wil probably become a seperate stage (post compiler?).

	local buffer = {};
	local alltasks = this.__tasks;

	for k, v in pairs(this.__tokens) do
		
		if (v.newLine) then
			buffer[#buffer + 1] = "\n";
		end

		local tasks = alltasks[v.pos];

		if (tasks) then
			print("tasks", k, v, v.data);

			local prefixs = tasks.prefix;

			if (prefixs) then
				for _, prefix in pairs(prefixs) do
					buffer[#buffer + 1] = prefix.str;
				end
			end

			if (not tasks.remove) then
				if (tasks.replace) then
					buffer[#buffer + 1] = tasks.replace.str;
				else
					buffer[#buffer + 1] = v.data;
				end
			end

			local postfixs = tasks.postfix;

			if (postfixs) then
				for _, postfix in pairs(postfixs) do
					buffer[#buffer + 1] = postfix.str;
				end
			end
		else
			buffer[#buffer + 1] = v.data;
		end
	end

	return table.concat(buffer, " ");
end

function COMPILER.Throw(this, token, msg, fst, ...)
	local err = {};

	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	err.state = "compiler";
	err.char = token.char;
	err.line = token.line;
	err.msg = msg;

	error(err,0);
end

--[[
]]

function COMPILER.PushScope(this)
	this.__scope = {};
	this.__scope.memory = {};
	this.__scopeID = this.__scopeID + 1;
	this.__scopeData[this.__scopeID] = this.__scope;
end

function COMPILER.PopScope(this)
	this.__scopeData[this.__scopeID] = nil;
	this.__scopeID = this.__scopeID - 1;
	this.__scope = this.__scopeData[this.__scopeID];
end

function COMPILER.SetOption(this, option, value)
	this.__scope[option] = value;
end

function COMPILER.GetOption(this, option, nonDeep)
	if (this.__scope[option]) then
		return this.__scope[option];
	end

	if (not nonDeep) then
		for i = this.__scopeID, 1, -1 do
			local v = this.__scopeData[i][option];

			if (v) then
				return v;
			end
		end
	end
end

function COMPILER.SetVariable(this, name, class, scope)
	if (not scope) then
		scope = this.__scopeID;
	end

	local var = {};
	var.name = name;
	var.class = class;
	var.scope = scope;
	this.__scopeData[scope].memory[name] = var;
end

function COMPILER.GetVariable(this, name, scope, nonDeep)
	if (not scope) then
		scope = this.__scopeID;
	end

	local v = this.__scopeData[scope].memory[name];

	if (v) then
		return v.class, v.scope;
	end

	if (not nonDeep) then
		for i = scope, 1, -1 do
			local v = this.__scopeData[i].memory[name];

			if (v) then
				return v.class, v.scope;
			end
		end
	end
end

function COMPILER.AssignVariable(this, token, declaired, name, class, scope)
	if (not scope) then
		scope = this.__scopeID;
	end

	local c, s = this:GetVariable(name, scope, true);

	if (declaired) then
		if (c) then
			this:Throw(token, "Unable to assign declaire variable %s, Variable already exists.", name);
		else
			this:SetVariable(name, class, scope);
		end
	else
		if (not c) then
			this:Throw(token, "Unable to assign variable %s, Variable doesn't exist.", name);
		elseif (c ~= class) then
			this:Throw(token, "Unable to assign variable %s, %s expected got %s.", name, c, class);
		end
	end
end

--[[
]]

function COMPILER.GetOperator(this, operation, fst, ...)
	if (not fst) then
		return EXPR_EXPR_OPERATORS[operation .. "()"];
	end

	local signature = string.format("%s(%s)", operation, table.concat({fst, ...},","));

	local Op = EXPR_EXPR_OPERATORS[signature];

	if (Op) then
		return Op;
	end

	-- TODO: Inheritance.
end

--[[
]]

function COMPILER.QueueReplace(this, inst, token, str)
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

function COMPILER.QueueRemove(this, inst, token)
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

function COMPILER.QueueInjectionBefore(this, inst, token, str, ...)
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

function COMPILER.QueueInjectionAfter(this, inst, token, str, ...)
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

--[[
]]

function COMPILER.Compile(this, inst)
	if (not inst) then
		debug.Trace();
		error("Compiler was asked to compile a nil instruction.")
	end

	local instruction = string.upper(inst.type);
	local fun = this["Compile_" .. instruction];

	print("Compiler->" .. instruction .. "->#" .. #inst.instructions)

	if (not fun) then
		this:Throw(inst.token, "Failed to compile unkown instruction %s", instruction);
	end

	local type, count = fun(this, inst, inst.token, inst.instructions);

	if (type) then
		inst.type = type;
		inst.rCount = count or 1;
	end

	return type, count;
end

--[[
]]

function COMPILER.Compile_SEQ(this, inst, token, stmts)
	for k, v in pairs(stmts) do
		this:Compile(v);
	end

	return "", 0;
end

function COMPILER.Compile_IF(this, inst, token)
	local r, c = this:Compile(inst.condition);
	
	if (class ~= "b") then
		local op = this:GetOperator("is", r);

		if (op) then
			if (op.operation) then
				this.__EXPR_OPERATORS[op.signature] = op.operator;
				this:QueueInjectionBefore(inst, inst.condition.token, "OPERATORS", "[", "\"", op.signature, "\"", "]", "(", "CONTEXT", ",");
				this:QueueInjectionAfter(inst, inst.condition.final, ")" );
			end
		end

		if (not op) then
			local t = this:CastExpression("b", inst.condition);

			if (not t) then
				this:Throw(token, "Type of %s can not be used as a condition.", r);
			end
		end
	end

	this:PushScope();

	this:Compile(inst.block);
	
	this:PopScope();

	if (inst._else) then
		this:Compile(inst._else);
	end

	return "", 0;
end

function COMPILER.Compile_ELSEIF(this, inst, token)
	local class, count = this:Compile(inst.condition);
	
	if (class ~= "b") then
		-- TODO: Cast this to a boolean.
	end

	this:PushScope();

	this:Compile(inst.block);
	
	this:PopScope();

	if (inst._else) then
		this:Compile(inst._else);
	end

	return "", 0;
end

function COMPILER.Compile_ELSE(this, inst, token)
	this:PushScope();

	this:Compile(inst.block);
	
	this:PopScope();

	return "", 0;
end

--[[
]]

function COMPILER.Compile_SERVER(this, inst, token)
	if (not this:GetOption("server")) then
		this:Throw(token, "Server block must not appear inside a Client block.")
	end

	this:PushScope();
	this:SetOption("client", false);
	this:Compile(inst.block);
	
	this:PopScope();

	return "", 0;
end

function COMPILER.Compile_CLIENT(this, inst, token)
	if (not this:GetOption("client")) then
		this:Throw(token, "Client block must not appear inside a Server block.")
	end

	this:PushScope();
	this:SetOption("client", false);
	this:Compile(inst.block);
	
	this:PopScope();

	return "", 0;
end

--[[
]]

function COMPILER.Compile_GLOBAL(this, inst, token, expressions)

	for i, variable in pairs(inst.variables) do
		local expr = expressions[i];
		local r, c = this:Compile(expr);

		if (not r) then
			break;
		end

		if (r ~= inst.class) then
			local t, expr = this:CastExpression(inst.class, r);

			if (not t) then
				this:Throw(token, "Unable to assign variable %s, %s expected got %s.", variable, inst.class, r);
			end
		end

		this:AssignVariable(token, true, variable, r, 0);
	end

	return "", 0;
end

function COMPILER.Compile_LOCAL(this, inst, token, expressions)
	
	for i, variable in pairs(inst.variables) do

		local r, c = this:Compile(expressions[i]);

		if (not r) then
			break;
		end

		if (r ~= inst.class) then
			local t, expr = this:CastExpression(inst.class, r);

			if (not t) then
				this:Throw(token, "Unable to assign variable %s, %s expected got %s.", variable, inst.class, r);
			end
		end

		this:AssignVariable(token, true, variable, r);
	end

	return "", 0;
end

function COMPILER.Compile_ASS(this, inst, token, expressions)
	local count = 0;
	local total = #expressions;

	for i = 1, total do
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		if (r ~= inst.class) then
			if (c == 1) then
				local t, expr = this:CastExpression(inst.class, r);

				if (not t) then
					this:Throw(token, "Unable to assign variable %s, %s expected got %s.", variable, inst.class, r);
				end
			else
				this:Throw(token, "Unable to assign variable %s, %s expected got %s.", variable, inst.class, r);
			end
		end

		if (i == total) then
			for j = 1, c do
				count = count + 1;
				local variable = inst.variables[count];
				this:AssignVariable(token, false, variable, r);
			end
		else
			count = count + 1;
			local variable = inst.variables[count];
			this:AssignVariable(token, false, variable, r);
		end
	end

	return "", 0;
end

--[[
]]

function COMPILER.Compile_ASS_ADD(this, inst, token, expressions)
	for i = 1, #expressions do
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		count = count + 1;
		local variable = inst.variables[count];
		local class, scope = this:GetVariable(variable, nil, false);

		local op = this:GetOperator("add", class, r);

		if (not op) then
			this:Throw(expr.token, "Arithmatic assignment operator (+=) does not support '%s += %s'", class, r);
		elseif (not op.operation) then
			-- Use Native
			if (class == "s" or r == "s") then
				this:QueueInjectionBefore(inst, expr.token, variable, "..");
			else
				this:QueueInjectionBefore(inst, expr.token, variable, "+");
			end
		else
			-- Impliment Operator
			this.__EXPR_OPERATORS[op.signature] = op.operator;
			this:QueueInjectionBefore(inst, expr.token, "OPERATORS", "[", "\"", op.signature, "\"", "]", "(", "CONTEXT", ",");
			this:QueueInjectionAfter(inst, expr.final, ")" );

		end	

		this:AssignVariable(token, false, variable, r);
	end

	return "", 0;
end

function COMPILER.Compile_ASS_SUB(this, inst, token, expressions)
	for i = 1, #expressions do
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		count = count + 1;
		local variable = inst.variables[count];
		local class, scope = this:GetVariable(variable, nil, false);

		local op = this:GetOperator("sub", class, r);

		if (not op) then
			this:Throw(expr.token, "Arithmatic assignment operator (-=) does not support '%s -= %s'", class, r);
		elseif (not op.operation) then
			-- Use Native
			this:QueueInjectionBefore(inst, expr.token, variable, "-");
		else
			-- Impliment Operator
			this.__EXPR_OPERATORS[op.signature] = op.operator;
			this:QueueInjectionBefore(inst, expr.token, "OPERATORS", "[", "\"", op.signature, "\"", "]", "(", "CONTEXT", ",");
			this:QueueInjectionAfter(inst, expr.final, ")" );

		end	

		this:AssignVariable(token, false, variable, r);
	end

	return "", 0;
end

function COMPILER.Compile_ASS_MUL(this, inst, token, expressions)
	for i = 1, #expressions do
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		count = count + 1;
		local variable = inst.variables[count];
		local class, scope = this:GetVariable(variable, nil, false);

		local op = this:GetOperator("mul", class, r);

		if (not op) then
			this:Throw(expr.token, "Arithmatic assignment operator (*=) does not support '%s *= %s'", class, r);
		elseif (not op.operation) then
			-- Use Native
			this:QueueInjectionBefore(inst, expr.token, variable, "-");
		else
			-- Impliment Operator
			this.__EXPR_OPERATORS[op.signature] = op.operator;
			this:QueueInjectionBefore(inst, expr.token, "OPERATORS", "[", "\"", op.signature, "\"", "]", "(", "CONTEXT", ",");
			this:QueueInjectionAfter(inst, expr.final, ")" );

		end	

		this:AssignVariable(token, false, variable, r);
	end

	return "", 0;
end

function COMPILER.Compile_ASS_DIV(this, inst, token, expressions)
	for i = 1, #expressions do
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		count = count + 1;
		local variable = inst.variables[count];
		local class, scope = this:GetVariable(variable, nil, false);

		local op = this:GetOperator("div", class, r);

		if (not op) then
			this:Throw(expr.token, "Arithmatic assignment operator (/=) does not support '%s /= %s'", class, r);
		elseif (not op.operation) then
			-- Use Native
			this:QueueInjectionBefore(inst, expr.token, variable, "-");
		else
			-- Impliment Operator
			this.__EXPR_OPERATORS[op.signature] = op.operator;
			this:QueueInjectionBefore(inst, expr.token, "OPERATORS", "[", "\"", op.signature, "\"", "]", "(", "CONTEXT", ",");
			this:QueueInjectionAfter(inst, expr.final, ")" );

		end	

		this:AssignVariable(token, false, variable, r);
	end

	return "", 0;
end

--[[
]]

function COMPILER.Compile_TEN(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local expr3 = expressions[3];
	local r3, c3 = this:Compile(expr1);

	local op = this:GetOperator("ten", r1, r2, r3);

	if (not op) then
		this:Throw(expr.token, "Tenary operator (A ? b : C) does not support '%s ? %s : %s'", r1, r2, r3);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__and, "and");
		this:QueueReplace(inst, inst.__or, "or");
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__and, ",");
		this:QueueReplace(inst, inst.__or, ",");
		
		this:QueueInjectionAfter(inst, expr3.final, ")" );
	end	

	return op.type, op.count;
end


function COMPILER.Compile_OR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("or", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Logical or operator (||) does not support '%s || %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "or");
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_AND(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("and", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Logical or operator (&&) does not support '%s && %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "and");
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_BXOR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("bxor", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Binary xor operator (^^) does not support '%s ^^ %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.bxor(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_BOR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("bor", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Binary or operator (|) does not support '%s | %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.bor(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_BAND(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("band", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Binary or operator (&) does not support '%s & %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.band(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

--[[function COMPILER.Compile_EQ_MUL(inst, token, expressions)
end]]

function COMPILER.Compile_EQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("eq", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Comparison operator (==) does not support '%s == %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

--[[function COMPILER.Compile_NEQ_MUL(inst, token, expressions)
end]]

function COMPILER.Compile_NEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("neq", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Comparison operator (!=) does not support '%s != %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "~=");
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_LTH(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("lth", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Comparison operator (<) does not support '%s < %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_LEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("leg", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Comparison operator (<=) does not support '%s <= %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_GTH(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("gth", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Comparison operator (>) does not support '%s > %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_GEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("geq", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Comparison operator (>=) does not support '%s >= %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_BSHL(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("bshl", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Binary shift operator (<<) does not support '%s << %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.lshift(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_BSHR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("bshr", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Binary shift operator (>>) does not support '%s >> %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.rshift(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

--[[
]]

function COMPILER.Compile_ADD(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("add", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Addition operator (+) does not support '%s + %s'", r1, r2);
	elseif (not op.operation) then
		if (r1 == "s" or r2 == "s") then
			this:QueueReplace(inst, inst.__operator, ".."); -- Replace + with .. for string addition;
		end
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_SUB(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("sub", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Subtraction operator (-) does not support '%s - %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_DIV(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("div", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Division operator (/) does not support '%s / %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_MUL(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("mul", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Multiplication operator (*) does not support '%s * %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_EXP(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr1);

	local op = this:GetOperator("exp", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Exponent operator (^) does not support '%s ^ %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_NEG(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("neg", r1);

	if (not op) then
		this:Throw(expr.token, "Negation operator (-A) does not support '-%s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");
		
		this:QueueInjectionAfter(inst, expr1.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_NOT(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("not", r1);

	if (not op) then
		this:Throw(expr.token, "Not operator (!A) does not support '!%s'", r1, r2);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "not");
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");
		
		this:QueueInjectionAfter(inst, expr1.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.Compile_LEN(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("len", r1);

	if (not op) then
		this:Throw(expr.token, "Lengh operator (#A) does not support '#%s'", r1, r2);
	elseif (not op.operation) then
		-- Once again we change nothing.
	else
		this:QueueInjectionBefore(inst, expr1.token, "EXPR_EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");
		
		this:QueueInjectionAfter(inst, expr1.final, ")" );
	end

	return op.type, op.count;
end

function COMPILER.CastExpression(this, type, expr)
	local signature = string.format("(%s)%s", type, exrp.result);
	
	local op = EXPR_CAST_EXPR_OPERATORS[signature];

	if (not op) then
		return false, expr;
	end

	this:QueueInjectionBefore(inst, expr1.token, "EXPR_CAST_EXPR_OPERATORS[\"", op.signature, "\"](CONTEXT,");
		
	this:QueueInjectionAfter(inst, expr1.final, ")" );

	expr.result = op.type;
	expr.rCount = 0;

	return true, expr;
end

function COMPILER.Compile_CAST(this, inst, token, expressions)
	local expr = this:Compile(expressions[1]);
	local t = this:CastExpression(inst.class, expr);

	if (not t) then
		this:Throw(token, "Type of %s can not be cast to type of %s.", expr.result, inst.class)
	end

	return expr.result, expr.rCount;
end

function COMPILER.Compile_VAR(this, inst, token, expressions)
	local c, s = this:GetVariable(int.variable)

	if (s == 0) then
		this:QueueInjectionBefore(inst, token, "GLOBAL.");
	end

	if (not c) then
		this:Throw(token, "Variable %s does not exist.", inst.variable);
	end

	return c, 1;
end

function COMPILER.Compile_BOOL(this, inst, token, expressions)
	return "b", 1
end

function COMPILER.Compile_VOID(this, inst, token, expressions)
	return "", 1
end

function COMPILER.Compile_NUM(this, inst, token, expressions)
	return "n", 1
end

function COMPILER.Compile_STR(this, inst, token, expressions)
	return "s", 1
end

function COMPILER.Compile_NEW(this, inst, token, expressions)
	local Pp;
	local ids = {};
	local total = #expressions;

	if (total == 0) then
		Op = EXPR_CONSTRUCTORS[inst.class .. "()"];

		if (not Op) then
			op = EXPR_CONSTRUCTORS[inst.class .. "(...)"];
		end
	else
		for k, v in pairs(expressions) do
			local expr = expression[i];
			local r, c = this:Compile(expr);

			ids[#ids + 1] = r;

			if (k == total) then
				if (c > 1) then
					for i = 2; c do
						ids[#ids + 1] = r;
					end
				end
			end
		end

		for i = #r; 1; -1 do
			local args = table.concat({fst, ...},",", 1, i);

			if (i >= total) then
				local signature = string.format("%s(%s)", inst.class, args);

				Op = EXPR_CONSTRUCTORS[signature];
			end

			if (not Op) then
				local signature = string.format("%s(%s,...)", inst.class, args);

				Op = EXPR_CONSTRUCTORS[signature];
			end

			if (op) then
				break;
			end
		end

	if (not Op) then
		local signature = string.format("%s(%s)", inst.class, args);

		this:Throw(token, "No sutch constructor, %s", signature);
	end

	this:QueueInjectionBefore(inst, token, "EXPR_CONSTRUCTORS[\"", op.signature, "\"](CONTEXT");
	
	if (total > 0) then
		this:QueueInjectionBefore(inst, token, ",");
	end

	this:QueueInjectionAfter(inst, inst.final, ")" );

	expr.result = op.type;
	expr.rCount = 0;

	return true, expr;
end







--[[
]]

EXPR_COMPILER = COMPILER;