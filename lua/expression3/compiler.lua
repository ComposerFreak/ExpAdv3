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

local function name(id)
	return EXPR_LIB.GetClass(id).name
end

local function names(ids)
	if (isstring(ids)) then
		ids = string.Explode(",", ids);
	end

	local names = {};

	for i, id in pairs(ids) do
		names[i] = EXPR_LIB.GetClass(id).name;
	end

	return table.concat(names,", ")
end

--[[
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
	this.__directives = instance.directives;

	this.__scope = {};
	this.__scopeID = 0;
	this.__scopeData = {};
	this.__scopeData[0] = this.__scope;

	this.__scope.memory = {};
	this.__scope.classes = {};
	this.__scope.server = true;
	this.__scope.client = true;

	this.__defined = {};

	this.__constructors = {};
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
	this:SetOption("state", EXPR_SHARED);

	this:Compile(this.__root);

	local script, traceTbl = this:BuildScript();

	local result = {}
	result.script = this.__script;
	result.compiled = script;
	result.constructors = this.__constructors;
	result.operators = this.__operators;
	result.functions = this.__functions;
	result.methods = this.__methods;
	result.enviroment = this.__enviroment;
	result.directives = this.__directives;
	result.traceTbl = traceTbl;
	
	return result;
end

function COMPILER.BuildScript(this)
	-- This will probably become a separate stage (post compiler?).

	local buffer = {};
	local alltasks = this.__tasks;

	local char = 0;
	local line = 3;
	local traceTable = {};

	for k, v in pairs(this.__tokens) do
		local data = tostring(v.data);

		if (v.newLine) then
			char = 1;
			line = line + 1;
			buffer[#buffer + 1] = "\n";
		end

		local tasks = alltasks[v.pos];

		if (tasks) then
			
			local prefixs = tasks.prefix;

			if (prefixs) then
				--for _ = #prefixs, 1, -1 do
				--	local prefix = prefixs[_];
				for _, prefix in pairs(prefixs) do
					if (prefix.newLine) then
						char = 1;
						line = line + 1;
						buffer[#buffer + 1] = "\n";
					end

					buffer[#buffer + 1] = prefix.str;
					char = char + #prefix.str + 1;
				end
			end

			if (not tasks.remove) then
				if (tasks.replace) then
					buffer[#buffer + 1] = tasks.replace.str;
					char = char + #tasks.replace;
				else
					buffer[#buffer + 1] = data;
					char = char + #data + 1;
				end

				traceTable[#traceTable + 1] = {e3_line = v.line, e3_char = v.char, native_line = line, native_char = char};
			end

			local postfixs = tasks.postfix;

			if (postfixs) then
				--for _ = #postfixs, 1, -1 do
				--	local postfix = postfixs[_];
				for _, postfix in pairs(postfixs) do
					if (postfix.newLine) then
						char = 1;
						line = line + 1;
						buffer[#buffer + 1] = "\n";
					end
					char = char + #postfix.str + 1;
					buffer[#buffer + 1] = postfix.str;
				end
			end

			if (tasks.instruction) then
				
			end
		else
			traceTable[#traceTable + 1] = {e3_line = v.line, e3_char = v.char, native_line = line, native_char = char};
			buffer[#buffer + 1] = data;
			char = char + #data + 1;
		end
	end

	return table.concat(buffer, " "), traceTable;
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

function COMPILER.OffsetToken(this, token, offset)
	local pos = token.index + offset;

	local token = this.__tokens[pos];

	return token;
end

--[[
]]

function COMPILER.Import(this, path)
	local g = _G;
	local e = this.__enviroment;
	local a = string.Explode(".", path);
	
	if (#a > 1) then
		for i = 1, #a - 1 do
			local k = a[i];
			local v = g[k];
			
			if (istable(v)) then
				if (not istable(e[k])) then
					e[k] = {};
				end
				
				g = v;
				e = e[k];
			end
		end
	end
	
	local k = a[#a];
	local v = g[k];
	
	if(isfunction(v)) then
		e[k] = v;
	end
end

--[[
]]

function COMPILER.PushScope(this)
	this.__scope = {};
	this.__scope.memory = {};
	this.__scope.classes = {};
	this.__scopeID = this.__scopeID + 1;
	this.__scopeData[this.__scopeID] = this.__scope;
end

function COMPILER.PopScope(this)
	this.__scopeData[this.__scopeID] = nil;
	this.__scopeID = this.__scopeID - 1;
	this.__scope = this.__scopeData[this.__scopeID];
end

function COMPILER.SetOption(this, option, value, deep)
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

local bannedVars = {
	["GLOBAL"] = true,
	["SERVER"] = true,
	["CLIENT"] = true,
	["CONTEXT"] = true,
	["_OPS"] = true,
	["_CONST"] = true,
	["_METH"] = true,
	["_FUN"] = true,
	["invoke"] = true,
};

function COMPILER.AssignVariable(this, token, declaired, varName, class, scope)
	if (bannedVars[varName]) then
		this:Throw(token, "Unable to declare variable %s, name is reserved internally.", varName);
	end

	if (not scope) then
		scope = this.__scopeID;
	end

	local c, s, var = this:GetVariable(varName, scope, declaired);

	if (declaired) then
		if (c and c == class) then
			this:Throw(token, "Unable to declare variable %s, Variable already exists.", varName);
		elseif (c) then
			this:Throw(token, "Unable to initalize variable %s, %s expected got %s.", varName, name(c), name(class));
		else
			return this:SetVariable(varName, class, scope);
		end
	else
		if (not c) then
			this:Throw(token, "Unable to assign variable %s, Variable doesn't exist.", varName);
		elseif (c ~= class) then
			this:Throw(token, "Unable to assign variable %s, %s expected got %s.", varName, name(c), name(class));
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

local injectNewLine = false;

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

		if (i == 1) then
			op.newLine = injectNewLine;
		end

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
		
		if (i == 1) then
			op.newLine = injectNewLine;
		end

		r[#r + 1] = op;
		tasks.postfix[#tasks.postfix + 1] = op;
	end

	return r;
end

--[[
]]

function COMPILER.QueueInstruction(this, inst, inst, token, inst, type)
	local op = {};
	op.token = token;
	op.inst = inst;
	op.type = type;

	local tasks = this.__tasks[token.pos];

	if (not tasks) then
		tasks = {};
		this.__tasks[token.pos] = tasks;
	end

	if (not tasks.instruction) then
		tasks.instruction = op;
	end

	return op;
end

function COMPILER.Compile(this, inst)
	if (not inst) then
		debug.Trace();
		error("Compiler was asked to compile a nil instruction.")
	end

	if (not istable(inst.token)) then
		debug.Trace();
		print("token is ", type(inst.token), inst.token);
	end

	if (not inst.compiled) then
		local instruction = string.upper(inst.type);
		local fun = this["Compile_" .. instruction];

		-- print("Compiler->" .. instruction .. "->#" .. #inst.instructions)

		if (not fun) then
			this:Throw(inst.token, "Failed to compile unknown instruction %s", instruction);
		end

		--this:QueueInstruction(inst, inst.token, inst.type);

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
	for i = 1, #stmts do
		this:Compile(stmts[i]);
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
				this:Throw(token, "Type of %s can not be used as a condition.", name(r));
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
				this:Throw(token, "Type of %s can not be used as a condition.", name(r));
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

function COMPILER.CheckState(this, state, token, msg, frst, ...)
	local s = this:GetOption("state");
	
	if (state == EXPR_SHARED or s == state) then
		return true;
	end

	if (token and msg) then
		if (frst) then
			msg = string.format(msg, frst, ...);
		end

		if (state == EXPR_SERVER) then
			this:Throw(token, "%s is server-side only.", msg);
		elseif (state == EXPR_SERVER) then
			this:Throw(token, "%s is client-side only.", msg);
		end 
	end

	return false;
end

function COMPILER.Compile_SERVER(this, inst, token)
	if (not this:GetOption("server")) then
		this:Throw(token, "Server block must not appear inside a Client block.")
	end

	this:PushScope();
	this:SetOption("state", EXPR_SERVER);
	this:Compile(inst.block);
	
	this:PopScope();

	return "", 0;
end

function COMPILER.Compile_CLIENT(this, inst, token)
	if (not this:GetOption("client")) then
		this:Throw(token, "Client block must not appear inside a Server block.")
	end

	this:PushScope();
	this:SetOption("state", EXPR_CLIENT);
	this:Compile(inst.block);
	
	this:PopScope();

	return "", 0;
end

--[[
]]

function COMPILER.Compile_GLOBAL(this, inst, token, expressions)
	local tArgs = #expressions;

	local results = {};

	for i = 1, tArgs do
		local arg = expressions[i];
		local r, c = this:Compile(arg);

		if (not inst.variables[i]) then
			this:Throw(arg.token, "Unable to assign here, value #%i has no matching variable.", i);
		elseif (i < tArgs) then
			results[#results + 1] = {r, arg, true};
		else
			for j = 1, c do
				results[#results + 1] = {r, arg, j == 1};
			end
		end
	end

	for i = 1, #inst.variables do
		local result = results[i];
		local token = inst.variables[i];
		local var = token.data;

		if (not result) then
			this:Throw(token, "Unable to assign variable %s, no matching value.", var);
		end

		local class, scope, info = this:AssignVariable(token, true, var, inst.class, 0);

		if (info) then
			info.prefix = "GLOBAL";
			this:QueueReplace(inst, token, info.prefix .. "." .. var);
		end

		this.__defined[var] = true;

		if (result[1] ~= inst.class) then
			local casted = false;
			local arg = result[2];

			if (result[3]) then
				-- TODO: CAST
			end

			if (not casted) then
				this:AssignVariable(arg.token, true, var, result[1], 0);
			end
		end
	end

	this.__defined = {};

	return "", 0;
end

function COMPILER.Compile_LOCAL(this, inst, token, expressions)
	local tArgs = #expressions;

	local results = {};

	for i = 1, tArgs do
		local arg = expressions[i];
		local r, c = this:Compile(arg);

		if (not inst.variables[i]) then
			this:Throw(arg.token, "Unable to assign here, value #%i has no matching variable.", i);
		elseif (i < tArgs) then
			results[#results + 1] = {r, arg, true};
		else
			for j = 1, c do
				results[#results + 1] = {r, arg, j == 1};
			end
		end
	end

	for i = 1, #inst.variables do
		local result = results[i];
		local token = inst.variables[i];
		local var = token.data;

		if (not result) then
			this:Throw(token, "Unable to assign variable %s, no matching value.", var);
		end

		local class, scope, info = this:AssignVariable(token, true, var, inst.class);

		this.__defined[var] = true;

		if (result[1] ~= inst.class) then
			local casted = false;
			local arg = result[2];

			if (result[3]) then
				-- TODO: CAST
			end

			if (not casted) then
				this:AssignVariable(arg.token, true, var, result[1]);
			end
		end
	end

	this.__defined = {};

	return "", 0;
end

function COMPILER.Compile_ASS(this, inst, token, expressions)
	local tArgs = #expressions;

	local results = {};

	for i = 1, tArgs do
		local arg = expressions[i];
		local r, c = this:Compile(arg);

		if (not inst.variables[i]) then
			this:Throw(arg.token, "Unable to assign here, value #%i has no matching variable.", i);
		elseif (i < tArgs) then
			results[#results + 1] = {r, arg, true};
		else
			for j = 1, c do
				results[#results + 1] = {r, arg, j == 1};
			end
		end
	end

	for i = 1, #inst.variables do
		local result = results[i];

		local token = inst.variables[i];
		local var = token.data;

		if (not result) then
			this:Throw(token, "Unable to assign variable %s, no matching value.", var);
		end

		this.__defined[var] = true;

		local type = result[1];
		local class, scope, info = this:GetVariable(var);

		if (type ~= class) then
			local arg = result[2];

			if (result[3]) then
				-- TODO: CAST
				-- Once done rember: type = class;
			end
		end

		local class, scope, info = this:AssignVariable(token, false, var, class);

		if (info and info.prefix) then
			var = info.prefix .. "." .. var;

			this:QueueReplace(inst, token, var);
		end

		if (inst.class == "f") then
			injectNewLine = true;
			
			if (info.signature) then
				local msg = string.format("Failed to assign function to delegate %s(%s), permater missmatch.", var, info.signature);
				this:QueueInjectionAfter(inst, inst.final, string.format("if (%s and %s.signature ~= %q) then CONTEXT:Throw(%q); %s = nil; end", var, var, info.signature, msg, var));
			end
			
			if (info.resultClass) then
				local msg = string.format("Failed to assign function to delegate %s(%s), result type missmatch.", var, name(info.resultClass));
				this:QueueInjectionAfter(inst, inst.final, string.format("if (%s and %s.result ~= %q) then CONTEXT:Throw(%q); %s = nil; end", var, var, name(info.resultClass), msg, var));
			end
			
			if (info.resultCount) then
				local msg = string.format("Failed to assign function to delegate %s(%s), result count missmatch.", var, info.resultCount);
				this:QueueInjectionAfter(inst, inst.final, string.format("if (%s and %s.count ~= %i) then CONTEXT:Throw(%q); %s = nil; end", var, var, info.resultCount, msg, var));
			end

			injectNewLine = false;
		end
	end

	this.__defined = {};

	return "", 0;
end

--[[
]]

function COMPILER.Compile_AADD(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, #inst.variables do
		local token = inst.variables[k];
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		local class, scope, info = this:GetVariable(token.data, nil, false);

		if (info and info.prefix) then
			this:QueueReplace(inst, token, info.prefix .. "." .. token.data);
		end

		local char = "+";

		local op = this:GetOperator("add", class, r);

		if (not op and r ~= class) then
			if (this:CastExpression(class, expr)) then
				op = this:GetOperator("add", class, class);
			end
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (+=) does not support '%s += %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (+=)");

		if (not op.operation) then
			if (r == "s" or class == "s") then
				char = "..";
			end

			if (info and info.prefix) then
				this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data, char);
			else
				this:QueueInjectionBefore(inst, expr.token, token.data, char);
			end
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, token.data, op.result);
	end
end

function COMPILER.Compile_ASUB(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, #inst.variables do
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
			this:Throw(expr.token, "Assignment operator (-=) does not support '%s -= %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (-=)");

		if (not op.operation) then

			if (info and info.prefix) then
				this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data, "-");
			else
				this:QueueInjectionBefore(inst, expr.token, token.data, char);
			end
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, token.data, op.result);
	end
end



function COMPILER.Compile_ADIV(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, #inst.variables do
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
			this:Throw(expr.token, "Assignment operator (/=) does not support '%s /= %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (/=)");

		if (not op.operation) then

			if (info and info.prefix) then
				this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data, "/");
			else
				this:QueueInjectionBefore(inst, expr.token, token.data, char);
			end
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, token.data, op.result);
	end
end

function COMPILER.Compile_AMUL(this, inst, token, expressions)
	this:QueueReplace(inst, inst.__operator, "=");

	for k = 1, #inst.variables do
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
			this:Throw(expr.token, "Assignment operator (*=) does not support '%s *= %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (*=)");

		if (not op.operation) then

			if (info and info.prefix) then
				this:QueueInjectionBefore(inst, expr.token, info.prefix .. "." .. token.data, "*");
			else
				this:QueueInjectionBefore(inst, expr.token, token.data, char);
			end
		else
			-- Implement Operator
			this.__operators[op.signature] = op.operator;

			this:QueueInjectionBefore(inst, expr.token, "_OPS", "[", "\"" .. op.signature .. "\"", "]", "(");

			if (op.context) then
			    this:QueueInjectionBefore(inst, expr.token "CONTEXT", ",");
			end

			this:QueueInjectionAfter(inst, expr.final, ")" );
		end	

		this:AssignVariable(token, false, token.data, op.result);
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
		this:Throw(expr.token, "Tenary operator (A ? b : C) does not support '%s ? %s : %s'", name(r1), name(r2), name(r3));
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

	this:CheckState(op.state, token, "Tenary operator (A ? b : C)");

	return op.result, op.rCount;
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
			this:Throw(token, "Logical or operator (||) does not support '%s || %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Logical or operator (||) '%s || %s'", name(r1), name(r2));

	return op.result, op.rCount;
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
			this:Throw(token, "Logical and operator (&&) does not support '%s && %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Logical and operator (&&) '%s && %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_BXOR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bxor", r1, r2);

	if (not op) then
		this:Throw(token, "Binary xor operator (^^) does not support '%s ^^ %s'", name(r1), name(r2));
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.bxor(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	this:CheckState(op.state, token, "Binary xor operator (^^) '%s ^^ %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_BOR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bor", r1, r2);

	if (not op) then
		this:Throw(token, "Binary or operator (|) does not support '%s | %s'", name(r1), name(r2));
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.bor(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	this:CheckState(op.state, token, "Binary xor operator (|) '%s | %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_BAND(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("band", r1, r2);

	if (not op) then
		this:Throw(token, "Binary or operator (&) does not support '%s & %s'", name(r1), name(r2));
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.band(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	this:CheckState(op.state, token, "Binary xor operator (&) '%s & %s'", name(r1), name(r2));

	return op.result, op.rCount;
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
		this:Throw(token, "Comparison operator (==) does not support '%s == %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Comparison operator (==) '%s == %s'", name(r1), name(r2));

	return op.result, op.rCount;
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
		this:Throw(token, "Comparison operator (!=) does not support '%s != %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Comparison operator (!=) '%s != %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_LTH(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("lth", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (<) does not support '%s < %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Comparison operator (<) '%s < %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_LEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("leg", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (<=) does not support '%s <= %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Comparison operator (<=) '%s <= %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_GTH(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("gth", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (>) does not support '%s > %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Comparison operator (>) '%s > %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_GEQ(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("geq", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (>=) does not support '%s >= %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Comparison operator (>=) '%s >= %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_BSHL(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bshl", r1, r2);

	if (not op) then
		this:Throw(token, "Binary shift operator (<<) does not support '%s << %s'", name(r1), name(r2));
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.lshift(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end
		
		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	this:CheckState(op.state, token, "Binary shift operator (<<) '%s << %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_BSHR(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("bshr", r1, r2);

	if (not op) then
		this:Throw(token, "Binary shift operator (>>) does not support '%s >> %s'", name(r1), name(r2));
	elseif (not op.operation) then
		this:QueueInjectionBefore(inst, expr1.token, "bit.rshift(");

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		
	else
		this:QueueInjectionBefore(inst, expr1.token, "_OPS[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr1.token, "CONTEXT", ",");
		end

		this:QueueReplace(inst, inst.__operator, ",");
		
		this:QueueInjectionAfter(inst, expr2.final, ")" );

		this.__operators[op.signature] = op.operator;
	end

	this:CheckState(op.state, token, "Binary shift operator (>>) '%s >> %s'", name(r1), name(r2));

	return op.result, op.rCount;
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
		this:Throw(token, "Addition operator (+) does not support '%s + %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Addition operator (+) '%s + %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_SUB(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("sub", r1, r2);

	if (not op) then
		this:Throw(token, "Subtraction operator (-) does not support '%s - %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Subtraction operator (-) '%s - %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_DIV(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("div", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Division operator (/) does not support '%s / %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Division operator (/) '%s / %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_MUL(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("mul", r1, r2);

	if (not op) then
		this:Throw(token, "Multiplication operator (*) does not support '%s * %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Multiplication operator (*) '%s * %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_EXP(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("exp", r1, r2);

	if (not op) then
		this:Throw(token, "Exponent operator (^) does not support '%s ^ %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Exponent operator (^) '%s ^ %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_MOD(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local expr2 = expressions[2];
	local r2, c2 = this:Compile(expr2);

	local op = this:GetOperator("mod", r1, r2);

	if (not op) then
		this:Throw(token, "Modulus operator (%) does not support '%s % %s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Modulus operator (%) '%s % %s'", name(r1), name(r2));

	return op.result, op.rCount;
end

function COMPILER.Compile_NEG(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("neg", r1);

	if (not op) then
		this:Throw(token, "Negation operator (-A) does not support '-%s'", name(r1));
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

	this:CheckState(op.state, token, "Negation operator (-A) '-%s'", name(r1));

	return op.result, op.rCount;
end

function COMPILER.Compile_NOT(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("not", r1);

	if (not op) then
		this:Throw(token, "Not operator (!A) does not support '!%s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Not operator (!A) '!%s'", name(r1));

	return op.result, op.rCount;
end

function COMPILER.Compile_LEN(this, inst, token, expressions)
	local expr1 = expressions[1];
	local r1, c1 = this:Compile(expr1);

	local op = this:GetOperator("len", r1);

	if (not op) then
		this:Throw(token, "Length operator (#A) does not support '#%s'", name(r1), name(r2));
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

	this:CheckState(op.state, token, "Length operator (#A) '#%s'", name(r1));

	return op.result, op.rCount;
end

function COMPILER.Expression_IS(this, expr)
	local op = this:GetOperator("is", expr.result);

	if (op) then
		if (not this:CheckState(op.state)) then
			return false, expr;
		elseif (not op.operation) then
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

	local signature = string.format("(%s)%s", name(type), name(expr.result));
	
	local op = EXPR_CAST_OPERATORS[signature];

	if (not op) then
		return false, expr;
	end

	if (not this:CheckState(op.state)) then
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
		this:Throw(token, "Type of %s can not be cast to type of %s.", name(expr.result), name(inst.class))
	end

	return expr.result, expr.rCount;
end

function COMPILER.Compile_VAR(this, inst, token, expressions)
	if (this.__defined[inst.variable]) then
		this:Throw(token, "Variable %s is defined here and can not be used as part of an expression.", inst.variable);
	end

	local c, s, var = this:GetVariable(inst.variable)

	if (var and var.prefix) then
		this:QueueReplace(inst, token, var.prefix .. "." .. token.data);
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

function COMPILER.Compile_PTRN(this, inst, token, expressions)
	return "_ptr", 1
end

function COMPILER.Compile_CLS(this, inst, token, expressions)
	this:QueueReplace(inst, token, "\"" .. token.data .. "\"");
	return "_cls", 1
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
		this:Throw(token, "No such condition (%s).", name(r));
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

	return op.result, op.rCount;
end

function COMPILER.Compile_NEW(this, inst, token, expressions)
	local op;
	local ids = {};
	local total = #expressions;

	local cls = EXPR_LIB.GetClass(inst.class);
	local constructors = cls.constructors;

	if (total == 0) then
		op = constructors[inst.class .. "()"];
	else
		for k, expr in pairs(expressions) do
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

		for i = #ids, 1, -1 do
			local args = table.concat(ids,",", 1, i);

			if (i >= total) then
				local signature = string.format("%s(%s)", inst.class, args);

				op = constructors[signature];
			end

			if (not op) then
				local signature = string.format("%s(%s,...)", inst.class, args);

				op = constructors[signature];
			end

			if (op) then
				break;
			end
		end

		if (not op) then
			op = constructors[inst.class .. "(...)"];
			
			if (op) then
				vargs = 1;
			end
		end
	end

	local signature = string.format("%s(%s)", name(inst.class), names(ids));

	if (not op) then
		this:Throw(token, "No such constructor, new %s", signature);
	end

	this:CheckState(op.state, token, "Constructor 'new %s", signature);

	if (type(op.operator) == "function") then

		this:QueueRemove(inst, inst.__new);
		this:QueueRemove(inst, inst.__const);
		this:QueueRemove(inst, inst.__lpa);

		this:QueueInjectionBefore(inst, inst.__const, "_CONST[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, inst.__const, "CONTEXT");

		    if (total > 0) then
				this:QueueInjectionBefore(inst, inst.__const, ",");
			end
		end

		this.__constructors[op.signature] = op.operator;
	elseif (type(op.operator) == "string") then
		this:QueueRemove(inst, inst.__new);
		this:QueueRemove(inst, inst.__const);
		this:QueueReplace(inst, inst.__const, op.operator);
	else
		local signature = string.format("%s.", inst.library, op.signature);
		error("Attempt to inject " .. op.signature .. " but operator was incorrect " .. type(op.operator) .. ".");
	end

	if (vargs) then
		if (#expressions >= 1) then
			for i = vargs, #expressions do
				local arg = expressions[i];

				if (arg.result ~= "_vr") then
					this:QueueInjectionBefore(inst, this:OffsetToken(arg.token, -1), "{", "\"" .. arg.result .. "\"", ",");

					this:QueueInjectionAfter(inst, arg.final, "}");
				end
			end
		end
	end

	return op.result, op.rCount;
end

function COMPILER.Compile_METH(this, inst, token, expressions)
	local expr = expressions[1];
	local mClass, mCount = this:Compile(expr);

	local op;
	local vargs;
	local ids = {};
	local total = #expressions;

	if (total == 1) then
		op = EXPR_METHODS[string.format("%s.%s()", mClass, inst.method)];
		--print("method->", string.format("%s.%s()", mClass, inst.method), op)
	else
		for k, expr in pairs(expressions) do
			if (k > 1) then
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
		end

		for i = #ids, 1, -1 do
			local args = table.concat(ids,",", 1, i);

			if (i <= total) then
				local signature = string.format("%s.%s(%s)", mClass, inst.method, args);

				op = EXPR_METHODS[signature];
				--print("method->", signature, op)
			end

			if (not op) then
				local signature = string.format("%s.%s(%s,...)", mClass, inst.method, args);

				op = EXPR_METHODS[signature];
				--print("method->", signature, op)

				if (op) then
					vargs = i;
				end
			end

			if (op) then
				break;
			end
		end

		if (not op) then
			op = EXPR_METHODS[string.format("%s.%s(...)", mClass, inst.method)];
				--print("method->", string.format("%s.%s(...)", mClass, inst.method), op)

			if (op) then
				vargs = 1;
			end
		end
	end

	if (not op) then
		this:Throw(token, "No such method %s.%s(%s).", name(mClass), inst.method, names(ids));
	end

	this:CheckState(op.state, token, "Method %s.%s(%s)", name(mClass), inst.method, names(ids));


	if (type(op.operator) == "function") then
		this:QueueRemove(inst, inst.__operator);
		this:QueueRemove(inst, inst.__method);

		if (total == 1) then
			this:QueueRemove(inst, inst.__lpa);
		else
			this:QueueReplace(inst, inst.__lpa, ",");
		end

		this:QueueInjectionBefore(inst, expr.token, "_METH[\"" .. op.signature .. "\"](");

		if (op.context) then
		    this:QueueInjectionBefore(inst, expr.token , "CONTEXT,");
		end

		this.__methods[op.signature] = op.operator;
	elseif (type(op.operator) == "string") then
		this:QueueReplace(inst, inst.__operator, ":");
		this:QueueReplace(inst, inst.__method, op.operator);
	else
		local signature = string.format("%s.%s", name(inst.class), op.signature);
		error("Attempt to inject " .. op.signature .. " but operator was incorrect, got " .. type(op.operator));
	end

	if (vargs) then
		if (#expressions > 1) then
			for i = vargs, #expressions do
				local arg = expressions[i];

				if (arg.result ~= "_vr") then
					this:QueueInjectionBefore(inst, this:OffsetToken(arg.token, -1), "{", "\"" .. arg.result .. "\"", ",");

					this:QueueInjectionAfter(inst, arg.final, "}");
				end
			end
		end
	end

	return op.result, op.rCount;
end

function COMPILER.Compile_FUNC(this, inst, token, expressions)
	local lib = EXPR_LIBRARIES[inst.library.data];

	if (not lib) then
		-- Please note this should be impossible.
		this:Throw(token, "Library %s does not exist.", inst.library.data);
	end

	local op;
	local vargs;
	local ids = {};
	local total = #expressions;

	if (total == 0) then
		op = lib._functions[inst.name .. "()"];
	else
		for k, expr in pairs(expressions) do
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

		for i = #ids, 1, -1 do
			local args = table.concat(ids,",", 1, i);

			if (i >= total) then
				local signature = string.format("%s(%s)", inst.name, args);

				op = lib._functions[signature];
			end

			if (not op) then
				local signature = string.format("%s(%s,...)", inst.name, args);

				op = lib._functions[signature];

				if (op) then
					vargs = i;
				end
			end

			if (op) then
				break;
			end
		end

		if (not op) then
			op = lib._functions[inst.name .. "(...)"];
			
			if (op) then
				vargs = 1;
			end
		end
	end

	if (not op) then
		this:Throw(token, "No such function %s.%s(%s).", inst.library.data, inst.name, names(ids, ","));
	end

	this:CheckState(op.state, token, "Function %s.%s(%s).", inst.library.data, inst.name, names(ids, ","));

	if (type(op.operator) == "function") then
		local signature = string.format("%s.%s", inst.library.data, op.signature);

		this:QueueRemove(inst, token);
		this:QueueRemove(inst, inst.library);
		this:QueueRemove(inst, inst.__operator);
		this:QueueRemove(inst, inst.__func);

		this:QueueInjectionAfter(inst, inst.__func, "_FUN[\"" .. signature .. "\"]");

		if (op.context) then
			this:QueueInjectionAfter(inst, inst.__lpa, "CONTEXT");

		    if (total > 0) then
				this:QueueInjectionAfter(inst, inst.__lpa, ",");
			end
		end

		this.__functions[signature] = op.operator;
	elseif (type(op.operator) == "string") then
		this:QueueRemove(inst, token);
		this:QueueRemove(inst, inst.library);
		this:QueueRemove(inst, inst.__operator);
		this:QueueReplace(inst, inst.__func, op.operator); -- This is error.
		this:Import(op.operator);
	else
		local signature = string.format("%s.", inst.library, op.signature);
		error("Attempt to inject " .. signature .. " but operator was incorrect " .. type(op.operator) .. ".");
	end


	if (vargs) then
		if (#expressions >= 1) then
			for i = vargs, #expressions do
				local arg = expressions[i];

				if (arg.result ~= "_vr") then
					this:QueueInjectionAfter(inst, this:OffsetToken(arg.token, -1), "{", "\"" .. arg.result .. "\"", ",");

					this:QueueInjectionAfter(inst, arg.final, "}");
				end
			end
		end
	end

	if (inst.library == "system") then
		local res, count = hook.Run("Expression3.PostCompile.System." .. inst.name, this, inst, token, expressions);
		
		if (res and count) then
			return res, count;
		end
	end

	return op.result, op.rCount;
end

--[[
]]

function COMPILER.Compile_LAMBDA(this, inst, token, expressions)
	this:PushScope();

	for _, peram in pairs(inst.perams) do
		local var = peram[2];
		local class = peram[1];

		this:AssignVariable(token, true, var, class);

		if (class ~= "_vr") then
			injectNewLine = true;
			this:QueueInjectionBefore(inst, inst.stmts.token, string.format("if (%s == nil or %s[1] == nil) then CONTEXT:Throw(\"%s expected for %s, got void\"); end", var, var, name(class), var));
			this:QueueInjectionBefore(inst, inst.stmts.token, string.format("if (%s[1] ~= %q) then CONTEXT:Throw(\"%s expected for %s, got \" .. %s[1]); end", var, class, name(class), var, var));
			this:QueueInjectionBefore(inst, inst.stmts.token, string.format("%s = %s[2];", var, var));
			injectNewLine = false;
		end
	end

	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);

	this:SetOption("retunClass", "?"); -- Indicate we do not know this yet.
	this:SetOption("retunCount", -1); -- Indicate we do not know this yet.

	this:Compile(inst.stmts);

	local result = this:GetOption("retunClass");
	local count = this:GetOption("retunCount");

	this:PopScope();

	if (result == "?" or count == -1) then
		result = "";
		count = 0;
	end

	this:QueueInjectionAfter(inst, inst.__end, ", result = \"" .. result .. "\"");
	this:QueueInjectionAfter(inst, inst.__end, ", count = " .. count);
	this:QueueInjectionAfter(inst, inst.__end, "}");

	return "f", 1;
end

--[[
]]

function COMPILER.Compile_RETURN(this, inst, token, expressions)
	local result = this:GetOption("retunClass");
	local count = this:GetOption("retunCount");

	local results = {};

	for _, expr in pairs(expressions) do
		local r, c = this:Compile(expr);
		results[#results + 1] = {r, c};
	end

	local outClass;

	if (result == "?") then
		for i = 1, #results do
			local t = results[i][1];

			if (not outClass) then
				outClass = t;
			elseif (outClass ~= t) then
				outClass = "_vr";
				break;
			end
		end

		this:SetOption("retunClass", outClass or "", true);
	else
		outClass = result;
	end

	local outCount = 0;

	for i = 1, #results do
		local expr = expressions[i];
		local res = results[i][1];
		local cnt = results[i][2];

		if (res ~= outClass) then
			local ok = this:CastExpression(outClass, expr);

			if (not ok) then
				this:Throw(expr.token, "Can not return %s here, %s expected.", name(res), name(outClass));
			end
		end

		if (i < #results) then
			outCount = outCount + 1;
		else
			outCount = outCount + cnt;
		end
	end

	if (count == -1) then
		count = outCount;
		this:SetOption("retunCount", outCount, true);
	end

	if (count ~= outCount) then
		this:Throw(expr.token, "Can not return %i %s('s) here, %i %s('s) expected.", name(outCount), name(outClass), count, name(outClass));
	end
end

--[[
]]

function COMPILER.Compile_DELEGATE(this, inst, token, expressions)
	local class, scope, info = this:AssignVariable(token, true, inst.variable, "f");

	if (info) then
		info.signature = table.concat(inst.peramaters, ",");
		info.peramaters = inst.peramaters;
		info.resultClass = inst.resultClass;
		info.resultCount = inst.resultCount;
	end
end

function COMPILER.Compile_FUNCT(this, inst, token, expressions)
	this:PushScope();

	for _, peram in pairs(inst.perams) do
		local var = peram[2];
		local class = peram[1];

		this:AssignVariable(token, true, var, class);

		if (class ~= "_vr") then
			injectNewLine = true;
			this:QueueInjectionBefore(inst, inst.stmts.token, string.format("if (%s == nil or %s[1] == nil) then CONTEXT:Throw(\"%s expected for %s, got void\"); end", var, var, class, var));
			this:QueueInjectionBefore(inst, inst.stmts.token, string.format("if (%s[1] ~= %q) then CONTEXT:Throw(\"%s expected for %s, got \" .. %s[1]); end", var, class, class, var, var));
			this:QueueInjectionBefore(inst, inst.stmts.token, string.format("%s = %s[2];", var, var));
			injectNewLine = false;
		end
	end

	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);

	this:SetOption("retunClass", inst.resultClass);
	this:SetOption("retunCount", -1); -- Indicate we do not know this yet.

	this:Compile(inst.stmts);

	local count = this:GetOption("retunCount");

	this:PopScope();

	local variable = inst.variable;

	local class, scope, info = this:AssignVariable(token, true, variable, "f");

	if (info) then
		info.signature = inst.signature;
		info.peramaters = inst.perams;
		info.resultClass = inst.resultClass;
		info.resultCount = count;

		if (info.prefix) then
			variable = info.prefix .. "." .. variable;
		else
			this:QueueInjectionBefore(inst, token, "local");
		end
	end

	this:QueueInjectionBefore(inst, token, variable, " = { op = ");
	this:QueueInjectionAfter(inst, inst.__end, ", signature = \"" .. inst.signature .. "\"");
	this:QueueInjectionAfter(inst, inst.__end, ", result = \"" .. info.resultClass .. "\"");
	this:QueueInjectionAfter(inst, inst.__end, ", count = " .. count);
	this:QueueInjectionAfter(inst, inst.__end, "}");
end

--[[
]]

function COMPILER.Compile_CALL(this, inst, token, expressions)
	local expr = expressions[1];
	local res, count = this:Compile(expr);

	local prms = {};

	if (#expressions > 1) then
		for i = 2, #expressions do
			local arg = expressions[i];
			local r, c = this:Compile(arg);

			prms[#prms + 1] = r;

			if (i == #expressions and c > 1) then
				for j = 2, c do
					prms[#prms + 1] = r;
				end
			end
		end
	end

	local signature = table.concat(prms, ",");

	if (res == "f" and expr.type == "var") then
		local c, s, info = this:GetVariable(expr.variable);
		-- The var instruction will have already validated this variable.
		
		if (info.signature) then
			if (info.signature ~= signature) then
				this:Throw(token, "Invalid arguments to user function got %s(%s), %s(%s) expected.", expr.variable, names(signature), expr.variable, names(info.signature));
			end

			if (#expressions > 1) then
				for i = 2, #expressions do
					local arg = expressions[i];

					if (arg.result ~= "_vr") then
						this:QueueInjectionBefore(inst, arg.token, "{", "\"" .. arg.result .. "\"", ",");

						this:QueueInjectionAfter(inst, arg.final, "}");
					end
				end
			end

			this:QueueReplace(inst, expr.token, "invoke");

			this:QueueInjectionAfter(inst, token, "(", "CONTEXT", ",\"" .. info.resultClass .. "\",", tostring(info.resultCount), ",");

			if (info.prefix) then
				this:QueueInjectionAfter(inst, token, info.prefix .. "." .. expr.variable);
			else
				this:QueueInjectionAfter(inst, token, expr.variable);
			end

			if (#prms >= 1) then
				this:QueueInjectionAfter(inst, token, ",");
			end

			return info.resultClass, info.resultCount;
		end
	end

	local op;

	if (#prms == 0) then
		op = this:GetOperator("call", res, "");

		if (not op) then
			op = this:GetOperator("call", res, "...");
		end
	else
		for i = #prms, 1, -1 do
			local args = table.concat(prms,",", 1, i);

			if (i >= #prms) then
				op = this:GetOperator("call", res, args);
			end

			if (not op) then
				op = this:GetOperator("call", args, res, "...");
			end

			if (op) then
				break;
			end
		end
	end

	if (not op) then
		this:Throw(token, "No such call operation %s(%s)", name(res), names(prms));
	end

	this:CheckState(op.state, token, "call operation %s(%s).", name(res), names(prms));

	this:QueueRemove(inst, token); -- Removes (

	this:QueueInjectionBefore(inst, expr.token, "_OPS[\"" .. op.signature .. "\"]", "(");

	if (op.context) then
		this:QueueInjectionBefore(inst, expr.token, "CONTEXT", ",");
	end

	if (#prms >= 1) then
		this:QueueInjectionBefore(inst, token, ",");
	end

	this.__operators[op.signature] = op.operator;

	return op.result, op.rCount;
end

--[[
]]

function COMPILER.Compile_GET(this, inst, token, expressions)
	local value = expressions[1];
	local vType = this:Compile(value);
	local index = expressions[2];
	local iType = this:Compile(index);

	local op;
	local keepid = false;
	local cls = inst.class;

	if (not cls) then
		op = this:GetOperator("get", vType, iType);

		if (not op) then
			this:Throw(token, "No such get operation %s[%s]", name(vType), name(iType));
		end
	else
		op = this:GetOperator("get", vType, iType, cls.data);
		
		if (not op) then
			keepid = true;

			this:QueueReplace(inst, cls, "\'" .. cls.data .. "\'");

			op = this:GetOperator("get", vType, iType, "_cls");

			if (op) then
				if (op.result == "") then
					op.result = cls.data;
					op.rCount = 1;
				end
			end
		end

		if (not op) then
			this:Throw(token, "No such get operation %s[%s,%s]", name(vType), name(iType), name(cls.data));
		end
	end

	this:CheckState(op.state);

	if (not op.operator) then
		return op.result, op.rCount;
	end

	this:QueueInjectionBefore(inst, value.token, "_OPS[\"" .. op.signature .. "\"](");

	if (op.context) then
	   this:QueueInjectionBefore(inst, value.token, "CONTEXT", ",");
	end

	if (not keepid) then
		this:QueueRemove(inst, cls);
	else
		this:QueueReplace(inst, cls, "'" .. cls.data .. "'");
	end

	this:QueueReplace(inst, inst.__rsb, ")" );

	this:QueueReplace(inst, inst.__lsb, "," );

	this.__operators[op.signature] = op.operator;

	return op.result, op.rCount;
end

function COMPILER.Compile_SET(this, inst, token, expressions)
	local value = expressions[1];
	local vType = this:Compile(value);
	local index = expressions[2];
	local iType = this:Compile(index);
	local expr = expressions[3];
	local vExpr = this:Compile(expr);

	local op;
	local keepclass = false;
	local cls = inst.class;

	if (cls and vExpr ~= cls.data) then
		-- TODO: Cast
	end

	if (not cls) then
		op = this:GetOperator("set", vType, iType, vExpr);
	else
		op = this:GetOperator("set", vType, iType, cls.data);

		if (not op) then
			keepclass = true;
			op = this:GetOperator("set", vType, iType, "_cls", vExpr)
		end
	end

	if (not op) then
		if (not cls) then
			this:Throw(token, "No such set operation %s[%s] = ", name(vType), name(iType), name(vExpr));
		else
			this:Throw(token, "No such set operation %s[%s, %s] = ", name(vType), name(iType), name(cls.data), name(vExpr));
		end
	end

	this:CheckState(op.state);

	if (not op.operator) then
		return op.result, op.rCount;
	end

	this:QueueReplace(inst, token, "," );

	this:QueueInjectionBefore(inst, value.token, "_OPS[\"" .. op.signature .. "\"](");

	if (op.context) then
	   this:QueueInjectionBefore(inst, value.token, "CONTEXT", ",");
	end
	
	if (not keepclass) then
		this:QueueRemove(isnt, cls);
	else
		this:QueueReplace(isnt, cls, ", '" .. cls.data .. "'");
	end

	this:QueueRemove(inst, inst.__ass, ",");

	this:QueueReplace(inst, inst.__rsb, "," );
	  
	this:QueueInjectionAfter(inst, expr.final, ")");

	this.__operators[op.signature] = op.operator;

	return op.result, op.rCount;
end

--[[
]]

function COMPILER.Compile_FOR(this, inst, token, expressions)

	local start = expressions[1];
	local tStart = this:Compile(start);
	local _end = expressions[2];
	local tEnd = this:Compile(_end);
	local step = expressions[3];
	
	if (not step and (inst.class ~= "n" or tStart  ~= "n" or tEnd ~= "n")) then
		this:Throw(token, "No such loop 'for(%s i = %s; %s)'.", name(inst.class), name(tStart), name(tEnd));
	elseif (step) then
		local tStep = this:Compile(step);
		if (inst.class ~= "n" or tStart  ~= "n" or tEnd ~= "n" or tEnd ~= "n" or tStep ~= "n") then
			this:Throw(token, "No such loop 'for(%s i = %s; %s; %s)'.", name(inst.class), name(tStart), name(tEnd), name(tStep));
		end
	end

	this:PushScope();

	this:AssignVariable(token, true, inst.variable.data, inst.class, nil);

	this:Compile(inst.stmts);

	this:PopScope();
end

--[[

]]

function COMPILER.Compile_TRY(this, inst, token, expressions)
	this:QueueReplace(inst, token, "local");

	this:QueueInjectionAfter(inst, token, "ok", ",", inst.__var.data, "=", "pcall(");

	this:PushScope();

	this:Compile(inst.protected);

	this:PopScope();

	this:QueueInjectionAfter(inst, inst.protected.final, ");", "if", "(", "not", "ok", "and", inst.__var.data, ".", "state", "==", "'runtime'", ")");

	this:QueueRemove(inst, inst.__catch);
	this:QueueRemove(inst, inst.__lpa);
	this:QueueRemove(inst, inst.__var);
	this:QueueRemove(inst, inst.__rpa);

	this:PushScope();

	this:AssignVariable(token, true, inst.__var.data, "_er", nil);

	this:Compile(inst.catch);

	this:PopScope();

	this:QueueInjectionAfter(inst, inst.catch.final, "elseif (not ok) then error(", inst.__var.data, ", 0) end");
end

--[[
]]

function COMPILER.Compile_INPORT(this, inst, token)
	if (this:GetOption("state") ~= EXPR_SERVER) then
		this:Throw(token, "Wired input('s) must be defined server side.");
	end

	for _, token in pairs(inst.variables) do
		local var = token.data;

		if (var[1] ~= string.upper(var[1])) then
			this:Throw(token, "Invalid name for wired input %s, name must be cammel cased");
		end

		local class, scope, info = this:AssignVariable(token, true, var, inst.class, 0);

		if (info) then
			info.prefix = "INPUT";
		end

		this.__directives.inport[var] = {class = inst.class, wire = inst.wire_type, func = inst.wire_func};
	end
end

function COMPILER.Compile_OUTPORT(this, inst, token)
	if (this:GetOption("state") ~= EXPR_SERVER) then
		this:Throw(token, "Wired output('s) must be defined server side.");
	end

	for _, token in pairs(inst.variables) do
		local var = token.data;

		if (var[1] ~= string.upper(var[1])) then
			this:Throw(token, "Invalid name for wired output %s, name must be cammel cased");
		end

		local class, scope, info = this:AssignVariable(token, true, var, inst.class, 0);

		if (info) then
			info.prefix = "OUTPUT";
		end

		this.__directives.outport[var] = {class = inst.class, wire = inst.wire_type, func = inst.wire_func, func_in = inst.wire_func2};
	end
end


--[[
]]

function COMPILER.StartClass(this, name, scope)
	if (not scope) then
		scope = this.__scopeID;
	end

	local classes = this.__scopeData[scope].classes;

	local newclass = {name = name; memory = {}};

	classes[name] = newclass;

	return newclass;
end

function COMPILER.GetUserClass(this, name, scope, nonDeep)
	if (not scope) then
		scope = this.__scopeID;
	end

	local v = this.__scopeData[scope].classes[name];

	if (v) then
		return v.class, v.scope, v;
	end

	if (not nonDeep) then
		for i = scope, 0, -1 do
			local v = this.__scopeData[i].classes[name];

			if (v) then
				return v.class, v.scope, v;
			end
		end
	end
end

function COMPILER.AssToClass(token, declaired, varName, class, scope)
	local class, scope, info = this:AssignVariable(token, declaired, varName, class, scope);
	if (declaired) then
		local userclass = this:GetOption("userclass");
		userclass.memory[varName] = info;
		inf.prefix = "this.vars";
	end
end



function COMPILER.Compile_CLASS(this, inst, token, stmts)
	this:PushScope();
		local class = this:StartClass(inst.__classname.data);
		
		this:SetOption("userclass", class);

		for i = 1, #stmts do
			this:Compile(stmts[i]);
		end

	this:PopScope();

	-- inst.__classname
	this:QueueReplace(inst, token, "local");
	this:QueueRemove(inst, inst.__lcb);
	this:QueueInjectionAfter(inst, inst.__lcb, " =",  "{", "vars", "=", "{", "}", "}");
	this:QueueRemove(inst, inst.__rcb);

	return "", 0;
end

function COMPILER.Compile_FEILD(this, inst, token, expressions)
	local expr = expressions[1];
	local type = this:Compile(expr);
	local userclass = this:GetUserClass(type);

	if (not userclass) then
		this:Throw(token, "Unable to refrence feild %s.%s here", name(type), inst.__feild.data);
	end

	local info = userclass.vars[inst.__feild.data];

	if (not info) then
		this:Throw(token, "No sutch feild %s.%s", type, inst.__feild.data);
	end

	return info.result, 1;
end

function COMPILER.Compile_DEF_FEILD(this, inst, token, expressions)
	local tArgs = #expressions;
	local userclass = this:GetOption("userclass");

	local tArgs = #expressions;

	local results = {};

	for i = 1, tArgs do
		local arg = expressions[i];
		local r, c = this:Compile(arg);

		if (not inst.variables[i]) then
			this:Throw(arg.token, "Unable to assign here, value #%i has no matching variable.", i);
		elseif (i < tArgs) then
			results[#results + 1] = {r, arg, true};
		else
			for j = 1, c do
				results[#results + 1] = {r, arg, j == 1};
			end
		end
	end

	for i = 1, #inst.variables do
		local result = results[i];
		local token = inst.variables[i];
		local var = token.data;

		if (not result) then
			this:Throw(token, "Unable to assign variable %s, no matching value.", var);
		end

		local class, scope, info = this:AssignVariable(token, true, var, inst.class, 0);

		if (info) then
			this:QueueReplace(inst, token, userclass.name .. ".vars." .. var);
		end

		this.__defined[var] = true;

		if (result[1] ~= inst.class) then
			local casted = false;
			local arg = result[2];

			if (result[3]) then
				-- TODO: CAST
			end

			if (not casted) then
				this:AssignVariable(arg.token, true, var, result[1], 0);
			end
		end
	end

	this.__defined = {};

	return "", 0;
end

EXPR_COMPILER = COMPILER;