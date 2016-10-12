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
	this.__root = instance.instruction
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

function COMPILER._Run(this)
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

function Compiler.AssignVariable(this, token, declaired, name, class, scope)
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
		tasks.prefix[#tasks.prefix + 1] = op;
	end

	return r;
end

--[[
]]

function COMPILER.Compile(this, inst)
	local instruction = string.upper(inst.type);
	local fun = this["Compile_" .. instruction];

	if (not fun) then
		this:Throw(inst.token, "Failed to compile unkown instruction %s", instruction);
	end

	local type, count = fun(this, inst, token, inst.instructions);

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
		this:Compile(n);
	end

	return "", 0;
end

function COMPILER.Compile_IF(this, inst, token)
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
end

function COMPILER.Compile_ELSE(this, inst, token)
	this:PushScope();

	this:Compile(inst.block);
	
	this:PopScope();
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
end

function COMPILER.Compile_CLIENT(this, inst, token)
	if (not this:GetOption("client")) then
		this:Throw(token, "Client block must not appear inside a Server block.")
	end

	this:PushScope();
	this:SetOption("client", false);
	this:Compile(inst.block);
	
	this:PopScope();
end

--[[
]]

function COMPILER.Compile_GLOBAL(inst, token, expressions)
	for i, variable in pairs(inst.variables) do
		local r, c = this:Compile(expressions[i]);

		if (not r) then
			break;
		end

		if (r ~= inst.class) then
			this:Throw(token, "Unable to assign variable %s, %s expected got %s.", variable, inst.class, r);
		end

		this:AssignVariable(token, true, variable, r, 0);
	end
end

function COMPILER.Compile_LOCAL(inst, token, expressions)
	for i, variable in pairs(inst.variables) do
		local r, c = this:Compile(expressions[i]);

		if (not r) then
			break;
		end

		this:AssignVariable(token, true, variable, r);
	end
end

function COMPILER.Compile_ASS(inst, token, expressions)
	local count = 0;
	local total = #expressions;

	for i = 1, total do
		local expr = expressions[k];
		local r, c = this:Compile(expr);

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
end

function COMPILER.Compile_ASS_ADD(inst, token, expressions)
	for i = 1, #expressions do
		local expr = expressions[k];
		local r, c = this:Compile(expr);

		count = count + 1;
		local variable = inst.variables[count];
		local class, scope = this:GetVariable(variable, nil, false);

		local op = this:GetOperator("add", class, r);

		if (not op) then
			this:Throw(expr.token, "Arithmatic operator (add) does not support '%s + %s'", class, r);
		elseif (not op.operation) then
			-- Use Native
		else
			-- Impliment Operator
		end	

		this:AssignVariable(token, false, variable, r);
	end
end

