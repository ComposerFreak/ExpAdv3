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
	-- This will probably become a separate stage (post compiler?).

	local buffer = {};
	local alltasks = this.__tasks;
	for k, v in pairs(this.__tokens) do

		if (v.newLine) then
			buffer[#buffer + 1] = "\n";
		end

		local tasks = alltasks[v.pos];

		if (tasks) then
			
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
		for i = this.__scopeID, 0, -1 do
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

	return class, scope, var;
end

function COMPILER.GetVariable(this, name, scope, nonDeep)
	if (not scope) then
		scope = this.__scopeID;
	end

	local v = this.__scopeData[scope].memory[name];

	if (v) then
		return v.class, v.scope, v;
	end

	if (not nonDeep) then
		for i = scope, 0, -1 do
			local v = this.__scopeData[i].memory[name];

			if (v) then
				return v.class, v.scope, v;
			end
		end
	end
end

function COMPILER.AssignVariable(this, token, declaired, name, class, scope)
	if (not scope) then
		scope = this.__scopeID;
	end

	local c, s, var = this:GetVariable(name, scope, declaired);

	if (declaired) then
		if (c) then
			this:Throw(token, "Unable to assign declare variable %s, Variable already exists.", name);
		else
			return this:SetVariable(name, class, scope);
		end
	else
		if (not c) then
			this:Throw(token, "Unable to assign variable %s, Variable doesn't exist", name);
		elseif (c ~= class) then
			this:Throw(token, "Unable to assign variable %s, %s expected got %s.", name, c, class);
		end
	end

	return c, s, var;
end

--[[
]]

function COMPILER.GetOperator(this, operation, fst, ...)
	if (not fst) then
		return EXPR_OPERATORS[operation .. "()"];
	end

	local signature = string.format("%s(%s)", operation, table.concat({fst, ...},","));

	local Op = EXPR_OPERATORS[signature];

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

		tasks.prefix[#tasks.prefix + 1] = op;
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

	if (not inst.compiled) then
		local instruction = string.upper(inst.type);
		local fun = this["Compile_" .. instruction];

		--print("Compiler->" .. instruction .. "->#" .. #inst.instructions)

		if (not fun) then
			this:Throw(inst.token, "Failed to compile unknown instruction %s", instruction);
		end

		local type, count = fun(this, inst, inst.token, inst.instructions);

		if (type) then
			inst.result = type;
			inst.rCount = count or 1;
		end

		inst.compiled = true;
	end

	return inst.result, inst.rCount;
end

--[[
]]


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
		local isBool = this:Expression_IS(inst.condition);

		if (not isBool) then
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
		local isBool = this:Expression_IS(inst.condition);

		if (not isBool) then
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

	local tVars = #inst.variables;
	local tExprs = #expressions;

	local pos = 1;
	while pos <= tVars && pos <= tExprs do
		local t = inst.variables[pos];
		local expr = expressions[pos];

		if (not t) then
			this:Throw(expr.token, "Unable to assign here, value #%i has no matching variable.", pos);
		elseif (not expr) then
			this:Throw(t, "Unable to assign variable %s, no matching value.")
		end

		local res, cnt = this:Compile(expr);

		for i = 1, cnt do
			local snd = i < cnt or cnt == 1;
			local tkn = inst.variables[pos];
			local var = tkn.data;
			
			local class, scope, info = this:AssignVariable(tkn, true, var, res, 0);
			
			if (info and info.prefix) then
				print(">>>>>>>", pos, tkn.data)
				this:QueueInjectionBefore(inst, tkn, info.prefix .. ".");
			end

			pos = pos + 1;

			if (snd) then
				break;
			end
		end
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
			local t, expr = this:CastExpression(inst.class, expr);

			if (not t) then
				this:Throw(token, "Unable to assign variable %s, %s expected got %s.", variable, inst.class, r);
			end
		end

		this:AssignVariable(token, true, variable, r);
	end

	return "", 0;
end

function COMPILER.Compile_ASS(this, inst, token, expressions)
	local tVars = #inst.variables;
	local tExprs = #expressions;

	local pos = 1;
	while pos <= tVars and pos <= tExprs do
		local t = inst.variables[pos];
		local expr = expressions[pos];

		if (not t) then
			this:Throw(expr.token, "Unable to assign here, value #%i has no matching variable.", pos);
		elseif (not expr) then
			this:Throw(t, "Unable to assign variable %s, no matching value.")
		end

		local res, cnt = this:Compile(expr);

		for i = 1, cnt do
			local snd = i < cnt or cnt == 1;
			local tkn = inst.variables[pos];
			local var = tkn.data;
			local class, scope, info = this:GetVariable(var, nil, false);

			if (not class) then
				this:Throw(var, "Unable to assign variable %s, Variable does not exist.", var);
			elseif (snd and (class ~= res)) then
				local noErr = this:CastExpression(class, expr);

				if (not noErr) then
					this:Throw(token, "Unable to assign variable %s, %s expected got %s.", var, class, res);
				end
			elseif (class ~= res) then
				this:Throw(token, "Unable to assign variable %s, %s expected got %s.", var, class, res);
			end

			local class, scope, info = this:AssignVariable(tkn, false, var, res);
			
			if (info and info.prefix) then
				this:QueueInjectionBefore(inst, tkn, info.prefix .. ".");
			end

			pos = pos + 1;

			if (snd) then
				break;
			end
		end
	end
end

--[[
]]

function COMPILER.Compile_AADD(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, inst.variables do
		local token = inst.variables[k];
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		local class, scope, info = this:GetVariable(token.data, nil, false);

		if (info and info.prefix) then
			this:QueueInjectionBefore(inst, token, info.prefix .. ".");
		end

		local char = "+";

		local op = this:GetOperator("add", class, r);

		if (not op and r ~= class) then
			if (this:CastExpression(class, expr)) then
				op = this:GetOperator("add", class, class);
			end
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (+=) does not support '%s += %s'", class, r);
		end

		if (not op.operation) then
			if (r == "s" or class == "s") then
				char = "..";
			end

			this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data, char);
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, variable, r);
	end
end

function COMPILER.Compile_ASUB(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, inst.variables do
		local token = inst.variables[k];
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		local class, scope, info = this:GetVariable(token.data, nil, false);

		if (info and info.prefix) then
			this:QueueInjectionBefore(inst, token, info.prefix .. ".");
		end

		local op = this:GetOperator("sub", class, r);

		if (not op and r ~= class) then
			if (this:CastExpression(class, expr)) then
				op = this:GetOperator("sub", class, class);
			end
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (-=) does not support '%s -= %s'", class, r);
		end

		if (not op.operation) then

			this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data, "-");
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, variable, r);
	end
end



function COMPILER.Compile_ADIV(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, inst.variables do
		local token = inst.variables[k];
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		local class, scope, info = this:GetVariable(token.data, nil, false);

		if (info and info.prefix) then
			this:QueueInjectionBefore(inst, token, info.prefix .. ".");
		end

		local op = this:GetOperator("div", class, r);

		if (not op and r ~= class) then
			if (this:CastExpression(class, expr)) then
				op = this:GetOperator("div", class, class);
			end
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (/=) does not support '%s /= %s'", class, r);
		end

		if (not op.operation) then

			this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data,"/");
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, variable, r);
	end
end

function COMPILER.Compile_AMUL(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, inst.variables do
		local token = inst.variables[k];
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		local class, scope, info = this:GetVariable(token.data, nil, false);

		if (info and info.prefix) then
			this:QueueInjectionBefore(inst, token, info.prefix .. ".");
		end

		local op = this:GetOperator("mul", class, r);

		if (not op and r ~= class) then
			if (this:CastExpression(class, expr)) then
				op = this:GetOperator("mul", class, class);
			end
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (*=) does not support '%s *= %s'", class, r);
		end

		if (not op.operation) then

			this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data, "*");
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, variable, r);
	end
end
--[[
]]

function COMPILER.Compile_TEN(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local expr3 = expressions[3];
	local r3, c3 = this:Compile(expr1);

	local op = this:GetOperator("ten", r1, r2, r3);

	if (not op) then
		this:Throw(expr.token, "Te nary operator (A ? b : C) does not support '%s ? %s : %s'", r1, r2, r3);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__and, "and");
		this:QueueReplace(inst, inst.__or, "or");
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__and, ",");
		this:QueueReplace(inst, inst.__or, ",");
		
		this:QueueInjectionAfter(inst, expr3.final, ")" );

		this.__operators[op.signature] = op.operator;
	end	

	return op.type, op.count;
end


function COMPILER.Compile_OR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("or", r1, r2);

	if (not op) then
		local is1 = this:Expression_IS(expr1);
		local is2 = this:Expression_IS(expr2);

		if (is1 and is2) then
			op = this:GetOperator("and", "b", "b");
		end

		if (not op) then
			this:Throw(token, "Logical or operator (||) does not support '%s || %s'", r1, r2);
		end
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "or");
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_AND(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("and", r1, r2);

	if (not op) then
		local is1 = this:Expression_IS(expr1);
		local is2 = this:Expression_IS(expr2);

		if (is1 and is2) then
			op = this:GetOperator("and", "b", "b");
		end

		if (not op) then
			this:Throw(token, "Logical and operator (&&) does not support '%s && %s'", r1, r2);
		end
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "and");
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_BXOR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bxor", r1, r2);

	if (not op) then
		this:Throw(token, "Binary xor operator (^^) does not support '%s ^^ %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.bxor(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_BOR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bor", r1, r2);

	if (not op) then
		this:Throw(token, "Binary or operator (|) does not support '%s | %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.bor(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_BAND(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("band", r1, r2);

	if (not op) then
		this:Throw(token, "Binary or operator (&) does not support '%s & %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.band(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

--[[function COMPILER.Compile_EQ_MUL(inst, token, expressions)
end]]

function COMPILER.Compile_EQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("eq", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (==) does not support '%s == %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

--[[function COMPILER.Compile_NEQ_MUL(inst, token, expressions)
end]]

function COMPILER.Compile_NEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("neq", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (!=) does not support '%s != %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "~=");
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_LTH(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("lth", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (<) does not support '%s < %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_LEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("leg", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (<=) does not support '%s <= %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_GTH(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("gth", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (>) does not support '%s > %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_GEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("geq", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (>=) does not support '%s >= %s'", r1, r2);
	elseif (not op.operation) then
		-- Leave the code alone.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_BSHL(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bshl", r1, r2);

	if (not op) then
		this:Throw(token, "Binary shift operator (<<) does not support '%s << %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.lshift(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end
		
		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_BSHR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bshr", r1, r2);

	if (not op) then
		this:Throw(token, "Binary shift operator (>>) does not support '%s >> %s'", r1, r2);
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.rshift(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__enviroment.bit = bit;
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

--[[
]]

function COMPILER.Compile_ADD(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("add", r1, r2);

	if (not op) then
		this:Throw(token, "Addition operator (+) does not support '%s + %s'", r1, r2);
	elseif (not op.operation) then
		if (r1 == "s" or r2 == "s") then
			this:QueueReplace(inst, inst.__operator, ".."); -- Replace + with .. for string addition;
		end
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_SUB(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("sub", r1, r2);

	if (not op) then
		this:Throw(token, "Subtraction operator (-) does not support '%s - %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_DIV(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("div", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Division operator (/) does not support '%s / %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_MUL(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("mul", r1, r2);

	if (not op) then
		this:Throw(token, "Multiplication operator (*) does not support '%s * %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_EXP(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("exp", r1, r2);

	if (not op) then
		this:Throw(token, "Exponent operator (^) does not support '%s ^ %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_MOD(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("mod", r1, r2);

	if (not op) then
		this:Throw(token, "Modulus operator (%) does not support '%s % %s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_NEG(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("neg", r1);

	if (not op) then
		this:Throw(token, "Negation operator (-A) does not support '-%s'", r1, r2);
	elseif (not op.operation) then
		-- Do not change the code.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end
		
		this:QueueInjectionAfter(inst, expr1.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_NOT(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("not", r1);

	if (not op) then
		this:Throw(token, "Not operator (!A) does not support '!%s'", r1, r2);
	elseif (not op.operation) then
		this:QueueReplace(inst, inst.__operator, "not");
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end
		
		this:QueueInjectionAfter(inst, expr1.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_LEN(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("len", r1);

	if (not op) then
		this:Throw(token, "Length operator (#A) does not support '#%s'", r1, r2);
	elseif (not op.operation) then
		-- Once again we change nothing.
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end
		
		this:QueueInjectionAfter(inst, expr1.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Expression_IS(this, expr)
	local op = this:GetOperator("is", expr.result);

	if (op) then
		if (not op.operation) then
			expr.result = op.type;
			expr.rCount = op.count;

			return true, expr;
		else
			this:QueueInjectionBefore(inst, expr.token, "_OPS[\"" .. op.signature .. "\"](");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token, "CONTEXT", ",");
			end
			
			this:QueueInjectionAfter(inst, expr.final, ")" );

			this.__operators[op.signature] = op.operator;

			expr.result = op.type;
			expr.rCount = op.count;

			return true, expr;
		end
	elseif (expr.result == "b") then
		return true, expr;
	end

	return false, expr;
end

function COMPILER.CastExpression(this, type, expr)

	local signature = string.format("(%s)%s", type, expr.result);
	
	local op = EXPR_CAST_OPERATORS[signature];

	if (not op) then
		return false, expr;
	end

	this:QueueInjectionBefore(inst, expr.token, "_OPS[\"" .. op.signature .. "\"](");

	if (op.context) then
	    this:QueueInjectionBefore(inst, expr.token, "CONTEXT", ",");
	end
		
	this:QueueInjectionAfter(inst, expr.final, ")" );

	this.__operators[op.signature] = op.operator;

	expr.result = op.type;
	expr.rCount = op.count;

	return true, expr;
end

function COMPILER.Compile_CAST(this, inst, token, expressions)
	local expr = expressions[1];

	this:Compile(expr);

	local t = this:CastExpression(inst.class, expr);

	if (not t) then
		this:Throw(token, "Type of %s can not be cast to type of %s.", expr.result, inst.class)
	end

	return expr.result, expr.rCount;
end

function COMPILER.Compile_VAR(this, inst, token, expressions)
	local c, s, var = this:GetVariable(inst.variable)

	if (var and var.prefix) then
		this:QueueInjectionBefore(inst, token, var.prefix .. ".");
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

function COMPILER.Compile_COND(this, inst, token, expressions)
	local expr = expressions[1];
	local r, c = this:Compile(expr);

	if (r == "b") then
		return r, c;
	end

	local op = this:GetOperator("is", r);

	if (not op and this:CastExpression("b", expr)) then
		return r, "b";
	end

	if (not op) then
		this:Throw(token, "No such condition (%s).", r);
	elseif (not op.operation) then
		-- Once again we change nothing.
	else
		this:QueueInjectionBefore(inst, expr.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr.token, "CONTEXT", ",");
		end
		
		this:QueueInjectionAfter(inst, expr.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	return op.type, op.count;
end

function COMPILER.Compile_NEW(this, inst, token, expressions)
	local op;
	local ids = {};
	local total = #expressions;

	if (total == 0) then
		op = EXPR_CONSTRUCTORS[inst.class .. "()"];

		if (not op) then
			op = EXPR_CONSTRUCTORS[inst.class .. "(...)"];
		end
	else
		for k, v in pairs(expressions) do
			local expr = expression[i];
			local r, c = this:Compile(expr);

			ids[#ids + 1] = r;

			if (k == total) then
				if (c > 1) then
					for i = 2, c do
						ids[#ids + 1] = r;
					end
				end
			end
		end

		for i = #r, 1, -1 do
			local args = table.concat({fst, "..."},",", 1, i);

			if (i >= total) then
				local signature = string.format("%s(%s)", inst.class, args);

				op = EXPR_CONSTRUCTORS[signature];
			end

			if (not Op) then
				local signature = string.format("%s(%s,...)", inst.class, args);

				op = EXPR_CONSTRUCTORS[signature];
			end

			if (op) then
				break;
			end
		end
	end

	if (not Op) then
		local signature = string.format("%s(%s)", inst.class, table.concat(ids, ","));

		this:Throw(token, "No such constructor, %s", signature);
	end

	this:QueueInjectionBefore(inst, token, "_CONST[\"" .. op.signature .. "\"](");
	
	if (op.context) then
	    this:QueueInjectionBefore(inst, token "CONTEXT");

	    if (total > 0) then
			this:QueueInjectionBefore(inst, token, ",");
		end
	end

	this:QueueInjectionAfter(inst, inst.final, ")" );

	this.__constructors[op.signature] = op.operator;

	expr.result = op.type;
	expr.rCount = 0;

	return true, expr;
end

function COMPILER.Compile_METH(this, inst, token, expressions)
	local mClass, mCount = this:Compile(expressions[1]);

	local op;
	local ids = {};
	local total = #expressions;

	if (total == 1) then
		op = EXPR_METHODS[string.format("%s:%s()", mClass, this.method)];

		if (not op) then
			op = EXPR_METHODS[string.format("%s:%s(...)", mClass, this.method)];
		end
	else
		for k, v in pairs(expressions) do
			local expr = expression[i];
			local r, c = this:Compile(expr);

			ids[#ids + 1] = r;

			if (k == total) then
				if (c > 1) then
					for i = 2, c do
						ids[#ids + 1] = r;
					end
				end
			end
		end

		for i = #r, 2, -1 do
			local args = table.concat({fst, "..."},",", 1, i);

			if (i >= total) then
				local signature = string.format("%s:%s(%s)", mClass, inst.class, args);

				op = EXPR_METHODS[signature];
			end

			if (not Op) then
				local signature = string.format("%s:%s(%s,...)", mClass, inst.class, args);

				op = EXPR_METHODS[signature];
			end

			if (op) then
				break;
			end
		end
	end

	if (not op) then
		this:Throw(token, "No such method %s.%s(%s).", mClass, inst.method, table.concat(ids, ","));
	end

	if (type(op.operator) == "table") then
		this:QueueRemove(inst, inst.__operator);
		this:QueueRemove(inst, inst.__method);

		if (total == 1) then
			this:QueueRemove(inst, inst.__lpa);
		else
			this:QueueReplace(inst, inst.__lpa, ",");
		end

		this:QueueInjectionBefore(inst, inst.__func, "_METH[", expressions[1].token, "](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, inst.__func, "CONTEXT,");

		    --if (total > 0) then
			--	this:QueueInjectionBefore(inst, inst.__func, ",");
			--end
		end

		this.__methods[op.signature] = op.operator;
	elseif (type(op.operator) == "string") then
		this:QueueReplace(inst, inst.__operator, ":");
		this:QueueReplace(inst, this.__method, op.operator);
	else
		local signature = string.format("%s.", inst.library, op.signature);
		error("Attempot to inject " .. signature .. " but operator was incorrect.")
	end

	return op.result, op.rCount;
end


function COMPILER.Compile_FUNC(this, inst, token, expressions)
	local lib = EXPADV_LIBRARIES[inst.library];

	if (not lib) then
		-- Please note this should be impossible.
		this:Throw(token, "Library %s does not exist.", inst.library);
	end

	local op;
	local ids = {};
	local total = #expressions;

	if (total == 0) then
		op = lib._functions[inst.name .. "()"];

		if (not op) then
			op = lib._functions[inst.name .. "(...)"];
		end
	else
		for k, v in pairs(expressions) do
			local expr = expression[i];
			local r, c = this:Compile(expr);

			ids[#ids + 1] = r;

			if (k == total) then
				if (c > 1) then
					for i = 2, c do
						ids[#ids + 1] = r;
					end
				end
			end
		end

		for i = #r, 1, -1 do
			local args = table.concat({fst, "..."},",", 1, i);

			if (i >= total) then
				local signature = string.format("%s(%s)", inst.name, args);

				op = lib._functions[signature];
			end

			if (not Op) then
				local signature = string.format("%s(%s,...)", inst.name, args);

				op = lib._functions[signature];
			end

			if (op) then
				break;
			end
		end
	end

	if (not op) then
		this:Throw(token, "No such function %s.%s(%s).", inst.library, inst.name, table.concat(ids, ","));
	end

	if (type(op.operator) == "table") then
		local signature = string.format("%s.", inst.library, op.signature);

		this:QueueRemove(inst, token);
		this:QueueRemove(inst, inst.__operator);
		this:QueueRemove(inst, inst.__func);

		this:QueueInjectionAfter(inst, inst.__func, "_FUN[", signature, "]");

		if (op.context) then
		    this:QueueInjectionBefore(inst, inst.__lpa, "CONTEXT");

		    if (total > 0) then
				this:QueueInjectionBefore(inst, inst.__lpa, ",");
			end
		end

		this.__functions[signature] = op.operator;
	elseif (type(op.operator) == "string") then
		this:QueueRemove(inst, token);
		this:QueueRemove(inst, inst.__operator);
		this:QueueReplace(inst, op.operator);
	else
		local signature = string.format("%s.", inst.library, op.signature);
		error("Attempot to inject " .. signature .. " but operator was incorrect.")
	end

	return op.result, op.rCount;
end





--[[
]]

EXPR_COMPILER = COMPILER;
