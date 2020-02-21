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

local string_Explode = string.Explode;
local string_upper = string.upper;
local string_format = string.format;
local table_concat = table.concat;

E3Class = EXPR_LIB.GetClass;

local function name(id)
	local obj = E3Class(id);
	return obj and obj.name or id;
end

local function names(ids)

	if (ids == null) then
		debug.Trace();
		print("Names got nil!")
	end

	if (isstring(ids)) then
		ids = string_Explode(",", ids);
	end

	local names = {};

	for i, id in pairs(ids) do
		local obj = E3Class(id);
		names[i] =  obj and obj.name or id;
	end

	return table_concat(names,", ")
end

--[[

]]

local function fakeInstruction(inst, lua, r, c)
	local new = table.Copy(inst);
	new.buffer = { lua };
	return new;
end

--[[
]]

local COMPILER = {};
COMPILER.__index = COMPILER;

function COMPILER.New()
	return setmetatable({}, COMPILER);
end

function COMPILER.Initialize(this, instance, files)
	this.__tokens = instance.tokens;
	this.__root = instance.instruction;
	this.__script = instance.script;
	this.__directives = instance.directives;

	this.__scope = {};
	this.__scopeID = 0;
	this.__scopeData = {};
	this.__scopeData[0] = this.__scope;

	this.__scope.memory = {};
	this.__scope.classes = {};
	this.__scope.interfaces = {};
	this.__scope.server = true;
	this.__scope.client = true;

	this.__defined = {};

	this.__constructors = {};
	this.__operators = {};
	this.__functions = {};
	this.__methods = {};
	this.__enviroment = {};
	this.__hashtable = {};

	this.__files = files;
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

	local result = {}
	result.script = this.__script;
	result.constructors = this.__constructors;
	result.operators = this.__operators;
	result.functions = this.__functions;
	result.methods = this.__methods;
	result.enviroment = this.__enviroment;
	result.directives = this.__directives;
	result.hashTable = this.__hashtable;
	result.rootInstruction = this.__root;

	result.build = function()
		local script, traceTbl = this:BuildScript(this.__root);
		result.compiled = script;
		result.traceTbl = traceTbl;
		return script, traceTbl;
	end

	return result;
end

local addNativeLua;

function addNativeLua(instruction, outBuffer, traceTable, char, line)
	--print("\nadding instruction to buffer: ", instruction.type);

	if (not instruction) then
		debug.Trace();
		error( "addNativeLua got invalid instruction " .. type(instruction) , 0);
	end

	local inBuffer = instruction.buffer;

	if (not inBuffer) then
		debug.Trace();
		error( "addNativeLua got invalid buffer " .. type(inBuffer) , 0);
	end

	local len = #inBuffer;

	for key = 1, len do
		local value = inBuffer[key];
		local _type = type(value);

		if _type == "table" then
			char, line = addNativeLua(value, outBuffer, traceTable, char, line);
		else
			if _type ~= "string" then value = tostring(value); end

			--print("\nadding token to buffer: ", value, _type);

			outBuffer[#outBuffer + 1] = value;

			if string.find(value, "\n") then
				local lines = string.Explode("\n", value);

				line = line + #lines;
				char = #lines[#lines] + 1;
			else
				char = char + (#value + 1); -- Include the space added by concat later.
			end

			traceTable[#traceTable + 1] = {
				e3_line = instruction.line - 1;
				e3_char = instruction.char;
				native_line = line;
				native_char = char
			};
		end
	end

	--print("\nfinished instruction: ", instruction.type);

	return char, line;
end

function COMPILER.BuildScript(this, instruction)
	-- This will probably become a separate stage (post compiler?).
	local outBuffer = {};
	local traceTable = {};

	addNativeLua(instruction, outBuffer, traceTable, 0, 1);

	return table_concat(outBuffer, " "), traceTable;
end

function COMPILER.Throw(this, token, msg, fst, ...)
	local err = {};

	if not token then
		debug.Trace();
	end

	if fst then
		msg = string_format(msg, fst, ...);
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
	local a = string_Explode(".", path);

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
function COMPILER.CRC(this, start, final)
	local i, tokens = 0, {};

	for j = start.index, final.index do
		i = i + 1;
		tokens[i] = this.__tokens[j].data;
	end

	return util.CRC(table_concat(tokens, " "));
end

--[[
]]

function COMPILER.PushScope(this)
	this.__scope = {};
	this.__scope.memory = {};
	this.__scope.classes = {};
	this.__scope.interfaces = {};
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
	if (this.__scope[option] ~= nil) then
		return this.__scope[option];
	end

	if (not nonDeep) then
		for i = this.__scopeID, 0, -1 do
			local v = this.__scopeData[i][option];

			if (v ~= nil) then
				return v;
			end
		end
	end
end

function COMPILER.SetVariable(this, name, class, scope, prefix, global)
	if (not scope) then
		scope = this.__scopeID;
	end

	local var = {};
	var.name = name;
	var.class = class;
	var.scope = scope;
	var.prefix = prefix;
	var.global = global;

	if not name then debug.Trace(); end

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
	["in"] = true,
	["if"] = true,
	["then"] = true,
	["end"] = true,
	["pairs"] = true,
};

function COMPILER.AssignVariable(this, token, declaired, varName, class, scope, prefix, global)
	if (not isstring(varName)) or varName == "" then
		--print("VARNAME is " .. varName);
		debug.Trace();
	end

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
		elseif (c and class ~= "") then
			this:Throw(token, "Unable to Initialize variable %s, %s expected got %s.", varName, name(c), name(class));
		else
			return this:SetVariable(varName, class, scope, prefix, global);
		end
	else
		if (not c) then
			this:Throw(token, "Unable to assign variable %s, Variable doesn't exist.", varName);
		elseif (c ~= class and class ~= "") then
			this:Throw(token, "Unable to assign variable %s, %s expected got %s.", varName, name(c), name(class));
		end
	end

	return c, s, var;
end

--[[
]]

function COMPILER.GetOperator(this, operation, fst, snd, ...)
	if (not fst) then
		return EXPR_OPERATORS[operation .. "()"];
	end

	local signature = string_format("%s(%s)", operation, table_concat({fst, snd, ...},","));

	local Op = EXPR_OPERATORS[signature];

	if (Op) then
		return Op;
	end

	-- First peram base class.

	if (fst) then
		local cls = E3Class(fst);

		if (cls and cls.base) then
			local Op = this:GetOperator(operation, cls.base, snd, ...);

			if (Op) then
				return Op;
			end
		end
	end

	-- Second peram base class.

	if (snd) then
		local cls = E3Class(snd);

		if (cls and cls.base) then
			local Op = this:GetOperator(operation, fst, cls.base, ...);

			if (Op) then
				return Op;
			end
		end
	end

end

--[[
]]

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
		inst.buffer = {};

		local instruction = string_upper(inst.type);
		local fun = this["Compile_" .. instruction];

		if (not fun) then
			this:Throw(inst.token, "Failed to compile unknown instruction %s", instruction);
		end

		local preInst = this.cur_instruction;

		this.cur_instruction = inst;

		local type, count, price = fun(this, inst, inst.token, inst.data);

		this.cur_instruction = preInst;

		if (type) then
			inst.result = type;
			inst.rCount = count or 1;
		end

		inst.price = price or EXPR_LOW;

		inst.compiled = true;
	end

	return inst.result, inst.rCount, inst.price;
end

--[[
]]

function COMPILER.writeToBuffer(this, inst, line, a, ...)
	if (isstring(inst)) then
		print("writeToBuffer", inst)
		debug.Trace();
	end

	if (a) then
		line = string.format(line, a, ...);
	end

	inst.buffer[#inst.buffer + 1] = line;
end

function COMPILER.addInstructionToBuffer(this, inst, inst2)
	inst.buffer[#inst.buffer + 1] = inst2;
end

function COMPILER.writeOperationCall(this, inst, op, expr1, ...)
	this.__operators[op.signature] = op.operator;

	this:writeToBuffer(inst, "_OPS[%q](", op.signature);

	if (op.context) then
	    this:writeToBuffer(inst, "CONTEXT");

	    if (expr1) then
	    	this:writeToBuffer(inst, ",");
	    end
	end

	if (expr1) then
		local args = {expr1, ...};
		local tArgs = #args;

		for i = 1, tArgs do
			if (type(args[i]) == "table") then
				this:addInstructionToBuffer(inst, args[i]);
			else
				this:writeToBuffer(inst, tostring(args[i]));
			end

			if (i < tArgs) then
				this:writeToBuffer(inst, ",");
			end
		end
	end

	this:writeToBuffer(inst, ")");
end

function COMPILER.writeArgsToBuffer(this, inst, vargs, ...)
	local args = {...};
	local tArgs = #args;

	for i = 1, tArgs do
		local arg = args[i];

		if istable(arg) then
			local vr = (vargs and i >= vargs) and arg.result ~= "_vr";

			if (vr) then
				this:writeToBuffer(inst, "{%q,", arg.result);
			end

			this:addInstructionToBuffer(inst, arg);

			if (vr) then
				this:writeToBuffer(inst, "}");
			end
		else
			this:writeToBuffer(inst, tostring(arg));
		end

		if (i < tArgs) then
			this:writeToBuffer(inst, ",");
		end
	end
end

function COMPILER.writeMethodCall(this, inst, op, expr1, ...)
	this.__methods[op.signature] = op.operator;

	this:writeToBuffer(inst, "_METH[%q](", op.signature);

	if (op.context) then
	    this:writeToBuffer(inst, "CONTEXT");

	    if (expr1) then
	    	this:writeToBuffer(inst, ",");
	    end
	end

	if (expr1) then
		this:writeArgsToBuffer(inst, nil, expr1, ...);
	end

	this:writeToBuffer(inst, ")");
end

function COMPILER.writeOperationCall2(this, tbl, inst, op, vargs, expr1, ...)
	local t = istable(op);
	local signature = t and op.signature or op;

	this:writeToBuffer(inst, "%s[%q](", tbl, signature);

	if (t and op.context) then
	    this:writeToBuffer(inst, "CONTEXT");

	    if (expr1) then
	    	this:writeToBuffer(inst, ",");
	    end
	end

	if (expr1) then
		this:writeArgsToBuffer(inst, vargs, expr1, ...);
	end

	this:writeToBuffer(inst, ")");
end

--[[
]]

--[[
]]

function COMPILER.Compile_ROOT(this, inst, token, data)
	this:writeToBuffer(inst, "\nreturn function(env)\n");
	this:writeToBuffer(inst, "\nsetfenv(1,env)\n");

	local stmts = data.stmts;

	if stmts then
		local price = 0;

		for i = 1, #stmts do
			local r, c, p = this:Compile(stmts[i]);
			price = price + p;
		end

		this:writeToBuffer(inst, "\n --PRICE: " .. price .. "\n");

		for i = 1, #stmts do
			this:addInstructionToBuffer(inst, stmts[i]);
		end
	end

	this:writeToBuffer(inst, "\nend\n");

	return "", 0, 0;
end

function COMPILER.Compile_SEQ(this, inst, token, data)
	local stmts = data.stmts;

	if stmts then
		local price = 0;

		for i = 1, #stmts do
			local r, c, p = this:Compile(stmts[i]);
			price = price + p;
		end

		this:writeToBuffer(inst, "\n --PRICE: " .. price .. "\n");

		for i = 1, #stmts do
			this:addInstructionToBuffer(inst, stmts[i]);
		end
	end

	return "", 0, 0;
end

function COMPILER.Compile_IF(this, inst, token, data)
	this:writeToBuffer(inst, "if (");

	local condition = data.condition;

	local r, c = this:Compile(condition);

	if (class ~= "b") then
		local isBool = this:Expression_IS(condition);

		if (not isBool) then
			local t = this:CastExpression("b", condition);

			if (not t) then
				this:Throw(token, "Type of %s can not be used as a condition.", name(r));
			end
		end
	end

	this:addInstructionToBuffer(inst, condition);

	this:writeToBuffer(inst, ") then\n");

	this:PushScope();

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

	this:PopScope();

	local eif = data.eif;

	if (eif and #eif > 0) then
		for i = 1, #eif do
			local stmt = eif[i];
			this:Compile(stmt);
			this:addInstructionToBuffer(inst, stmt);
		end
	end

	this:writeToBuffer(inst, "\nend\n");

	return "", 0;
end

function COMPILER.Compile_ELSEIF(this, inst, token, data)
	this:writeToBuffer(inst, "\nelseif (");

	local condition = data.condition;

	local class, count = this:Compile(condition);

	if (class ~= "b") then
		local isBool = this:Expression_IS(condition);

		if (not isBool) then
			local t = this:CastExpression("b", condition);

			if (not t) then
				this:Throw(token, "Type of %s can not be used as a condition.", name(r));
			end
		end
	end

	this:addInstructionToBuffer(inst, condition);

	this:writeToBuffer(inst, ") then\n");

	this:PushScope();

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

	this:PopScope();

	local eif = data.eif;

	if (eif) then
		local _, __, inst4 = this:Compile(eif);

		this:addInstructionToBuffer(inst, inst4);
	end

	return "", 0;
end

function COMPILER.Compile_ELSE(this, inst, token, data)
	this:writeToBuffer(inst, "\nelse\n");

	this:PushScope();

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

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
			msg = string_format(msg, frst, ...);
		end

		if (state == EXPR_SERVER) then
			this:Throw(token, "%s is server-side only.", msg);
		elseif (state == EXPR_SERVER) then
			this:Throw(token, "%s is client-side only.", msg);
		end
	end

	return false;
end

function COMPILER.Compile_SERVER(this, inst, token, data)
	this:writeToBuffer(inst, "if (SERVER) then\n");

	if (not this:GetOption("server")) then
		this:Throw(token, "Server block must not appear inside a Client block.")
	end

	this:PushScope();

	this:SetOption("state", EXPR_SERVER);

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

	this:PopScope();

	this:writeToBuffer(inst, "end\n");

	return "", 0, 1;
end

function COMPILER.Compile_CLIENT(this, inst, token, data)
	this:writeToBuffer(inst, "if (CLIENT) then\n");

	if (not this:GetOption("client")) then
		this:Throw(token, "Client block must not appear inside a Server block.")
	end

	this:PushScope();

	this:SetOption("state", EXPR_CLIENT);

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

	this:PopScope();

	this:writeToBuffer(inst, "end\n");

	return "", 0, 1;
end

--[[
]]

function COMPILER.Compile_GLOBAL(this, inst, token, data)
	local tVars = #data.variables;
	local tArgs = #data.expressions;

	local price = 1;
	local results = {};

	for i = 1, tArgs do
		local arg = data.expressions[i];
		arg.data.call_pred = (i == tArgs) and (tVars - i) + 1 or 1;
		local r, c, p = this:Compile(arg);

		prive = price + p;

		if (not data.variables[i]) then
			this:Throw(arg.token, "Invalid assignment, value #%i is not being assigned to a variable.", i);
		elseif (i < tArgs) then
			results[#results + 1] = {r, arg, true};
		else
			for j = 1, c do
				results[#results + 1] = {r, arg, j == 1};
			end
		end
	end

	for i = 1, #data.variables do
		local result = results[i];
		local token = data.variables[i];
		local var = token.data;

		if (not result) then
			this:Throw(token, "Invalid assignment, variable %s is not initalized.", var);
		end

		local class, scope, info = this:AssignVariable(token, true, var, data.class, 0, "GLOBAL", true);

		this:writeToBuffer(inst, "GLOBAL.");
		this:writeToBuffer(inst, var);

		if (i < #data.variables) then
			this:writeToBuffer(inst, ",");
		end

		this.__defined[var] = true;

		if (result[1] ~= data.class) then
			local casted = false;
			local arg = result[2];

			if (result[3]) then
				casted = this:CastExpression(data.class, data.expressions[i]);
			end

			if (not casted) then
				this:AssignVariable(arg.token, true, var, result[1], 0, "GLOBAL", true);
			end
		end
	end

	this:writeToBuffer(inst, "=");

	for i = 1, tArgs do
		this:addInstructionToBuffer(inst, data.expressions[i]);

		if (i < tArgs) then
			this:writeToBuffer(inst, ",");
		end
	end

	this.__defined = {};

	this:writeToBuffer(inst, ";\n");

	return "", 0, price;
end

function COMPILER.Compile_LOCAL(this, inst, token, data)
	local tVars = #data.variables;
	local tArgs = #data.expressions;

	local price = 1;
	local results = {};

	this:writeToBuffer(inst, "local");

	for i = 1, tArgs do
		local arg = data.expressions[i];
		arg.data.call_pred = (i == tArgs) and (tVars - i) + 1 or 1;
		local r, c, p = this:Compile(arg);

		price = price + p;

		if (not data.variables[i]) then
			this:Throw(arg.token, "Invalid assignment, value #%i is not being assigned to a variable.", i);
		elseif (i < tArgs) then
			results[#results + 1] = {r, arg, true};
		else
			for j = 1, c do
				results[#results + 1] = {r, arg, j == 1};
			end
		end
	end

	for i = 1, tVars do
		local result = results[i];
		local token = data.variables[i];
		local var = token.data;

		if (not result) then
			this:Throw(token, "Invalid assignment,  variable %s is not initalized.", var);
		end

		local class, scope, info = this:AssignVariable(token, true, var, data.class);

		this:writeToBuffer(inst, var);

		if (i < #data.variables) then
			this:writeToBuffer(inst, ",");
		end

		this.__defined[var] = true;

		if (result[1] ~= data.class and result[1] ~= "") then
			local casted = false;
			local arg = result[2];

			if (result[3]) then
				casted = this:CastExpression(data.class, data.expressions[i]);
			end

			if (not casted) then
				this:AssignVariable(arg.token, false, var, result[1]);
			end
		end
	end

	this:writeToBuffer(inst, "=");

	for i = 1, tArgs do
		this:addInstructionToBuffer(inst, data.expressions[i]);

		if (i < tArgs) then
			this:writeToBuffer(inst, ",");
		end
	end

	this.__defined = {};

	this:writeToBuffer(inst, "\n");

	return "", 0, price;
end

function COMPILER.Compile_ASS(this, inst, token, data)
	local price = 1;

	this:writeToBuffer(inst, "\n");

	local vars = data.variables;
	local tVars = #vars;

	for i = 1, tVars do
		local var = vars[i].data;
		local class, scope, info = this:GetVariable(var);

		if info then
				if (info.attribute) then
				this:writeToBuffer(inst, "this.");
			end

			if (info.prefix) then
				this:writeToBuffer(inst, info.prefix);
				this:writeToBuffer(inst, ".");
			end

		end
		this:writeToBuffer(inst, var);

		if i < tVars then
			this:writeToBuffer(inst, ",");
		end
	end

	this:writeToBuffer(inst, "=");

	local args = data.expressions;
	local tArgs = #args;

	for i = 1, tArgs do
		local var = vars[i];
		local arg = args[i];

		if not var then
			this:Throw(arg.token, "Invalid assignment, value #%i is not being assigned to a variable.", i);
		end

		arg.data.call_pred = (i == tArgs) and (tVars - i) + 1 or 1;
		local r, c, p = this:Compile(arg);

		price = price + p;

		local class, scope, info = this:AssignVariable(var, false, var.data, r);

		this:addInstructionToBuffer(inst, arg);

		if i < tVars then this:writeToBuffer(inst, ","); end

		if i == tArgs and c > 1 then
			for j = (i + 1), tVars do

				local var = vars[j];

				if (i + c >= j) then
					this:AssignVariable(var, false, var.data, r);
				else
					this:Throw(var, "Invalid assignment, variable %s is not initalized.", var.data);
				end
			end
		end
	end

	this:writeToBuffer(inst, ";\n");

	for i = 1, tVars do
		local var = vars[i].data;
		local class, scope, info = this:GetVariable(var);

		if (data.class == "f") then
			if (info.signature) then
				local msg = string_format("Failed to assign function to delegate %s(%s), permater missmatch.", var, info.signature);
				this:writeToBuffer(inst, "if (%s and %s.signature ~= %q) then CONTEXT:Throw(%q); %s = nil; end\n", var, var, info.signature, msg, var);
			end

			if (info.resultClass) then
				local msg = string_format("Failed to assign function to delegate %s(%s), result type missmatch.", var, name(info.resultClass));
				this:writeToBuffer(inst, "if (%s and %s.result ~= %q) then CONTEXT:Throw(%q); %s = nil; end\n", var, var, name(info.resultClass), msg, var);
			end

			if (info.resultCount) then
				local msg = string_format("Failed to assign function to delegate %s(%s), result count missmatch.", var, info.resultCount);
				this:writeToBuffer(inst, "if (%s and %s.count ~= %i) then CONTEXT:Throw(%q); %s = nil; end\n", var, var, info.resultCount, msg, var);
			end
		end
	end

	return "", 0, price;
end

--[[
]]

function COMPILER.Compile_AADD(this, inst, token, data)
	local r, c, p;
	local price = 1;
	local vt = #data.variables;
	local et = #data.expressions;

	for k = 1, #data.variables do
		local token = data.variables[k];
		local var = token.data;

		local valid = false;
		local expr = data.expressions[k];
		
		if expr then
			valid = true;
			expr.data.call_pred = (k == et) and (vt - k) + 1 or 1;
			r, c, p = this:Compile(expr);
			price = price + p;
		end

		if k == et then
			c = c - 1;
			this:writeToBuffer(inst, "\nlocal ");

			for i = k, vt do
				this:writeToBuffer(inst, "__" .. data.variables[i].data);
				if (i < vt) then this:writeToBuffer(inst, ","); end
			end

			this:writeToBuffer(inst, "=");

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");

			expr = fakeInstruction(inst, "__" .. var, r, 1);
		end

		if not valid then
			if c <= 1 then
				this:Throw(token, "Value expected, for Variable %s.", var);
			else
				expr = fakeInstruction(inst, "__" .. var, r, 1);
				c = c - 1;
			end
		end

		local class, scope, info = this:GetVariable(var, nil, false);

		if (not class) then
			this:Throw(token, "Variable %s does not exist.", var);
		end

		if (info and info.prefix) then
			var = info.prefix .. "." .. token.data;
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

		if (not op.operator) then
			if (r == "s" or class == "s") then
				char = "..";
			end

			this:writeToBuffer(inst, "%s = %s %s", var, var, char);

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");
		else
			this:writeToBuffer(inst, "%s = ", var);

			this:writeOperationCall(inst, op, "var", expr);

			this:writeToBuffer(inst, ";\n");
		end

		price = price + op.price;

		this:AssignVariable(token, false, token.data, op.result);
	end

	return nil, nil, price;
end

function COMPILER.Compile_ASUB(this, inst, token, data)
	local r, c, p;
	local price = 1;
	local vt = #data.variables;
	local et = #data.expressions;

	for k = 1, #data.variables do
		local token = data.variables[k];
		local var = token.data;

		local valid = false;
		local expr = data.expressions[k];
		
		if expr then
			valid = true;
			expr.data.call_pred = (k == et) and (vt - k) + 1 or 1;
			r, c, p = this:Compile(expr);
			price = price + p;
		end

		if k == et then
			c = c - 1;
			this:writeToBuffer(inst, "\nlocal ");

			for i = k, vt do
				this:writeToBuffer(inst, "__" .. data.variables[i].data);
				if (i < vt) then this:writeToBuffer(inst, ","); end
			end

			this:writeToBuffer(inst, "=");

			expr.data.call_pred = call_pred;

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");

			expr = fakeInstruction(inst, "__" .. var, r, 1);
		end

		if not valid then
			if c <= 1 then
				this:Throw(token, "Value expected, for Variable %s.", var);
			else
				expr = fakeInstruction(inst, "__" .. var, r, 1);
				c = c - 1;
			end
		end

		local class, scope, info = this:GetVariable(var, nil, false);

		if (not class) then
			this:Throw(token, "Variable %s does not exist.", var);
		end

		if (info and info.prefix) then
			var = info.prefix .. "." .. token.data;
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

		if (not op.operator) then
			this:writeToBuffer(inst, "%s = %s -", var, var);

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");
		else
			this:writeToBuffer(inst, "%s = ", var);

			this:writeOperationCall(inst, op, "var", expr);

			this:writeToBuffer(inst, ";\n");
		end

		price = price + op.price;

		this:AssignVariable(token, false, token.data, op.result);
	end

	return nil, nil, price;
end



function COMPILER.Compile_ADIV(this, inst, token, data)
	local r, c, p;
	local price = 1;
	local vt = #data.variables;
	local et = #data.expressions;

	for k = 1, #data.variables do
		local token = data.variables[k];
		local var = token.data;

		local valid = false;
		local expr = data.expressions[k];
		
		if expr then
			valid = true;
			expr.data.call_pred = (k == et) and (vt - k) + 1 or 1;
			r, c, p = this:Compile(expr);
			price = price + p;
		end

		if k == et then
			c = c - 1;
			this:writeToBuffer(inst, "\nlocal ");

			for i = k, vt do
				this:writeToBuffer(inst, "__" .. data.variables[i].data);
				if (i < vt) then this:writeToBuffer(inst, ","); end
			end

			this:writeToBuffer(inst, "=");

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");

			expr = fakeInstruction(inst, "__" .. var, r, 1);
		end

		if not valid then
			if c <= 1 then
				this:Throw(token, "Value expected, for Variable %s.", var);
			else
				expr = fakeInstruction(inst, "__" .. var, r, 1);
				c = c - 1;
			end
		end

		local class, scope, info = this:GetVariable(var, nil, false);

		if (not class) then
			this:Throw(token, "Variable %s does not exist.", var);
		end

		if (info and info.prefix) then
			var = info.prefix .. "." .. token.data;
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

		if (not op.operator) then
			this:writeToBuffer(inst, "%s = %s /", var, var);

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");
		else
			this:writeToBuffer(inst, "%s = ", var);

			this:writeOperationCall(inst, op, "var", expr);

			this:writeToBuffer(inst, ";\n");
		end

		price = price + op.price;

		this:AssignVariable(token, false, token.data, op.result);
	end

	return nil, nil, price;
end

function COMPILER.Compile_AMUL(this, inst, token, data)
	local r, c, p;
	local price = 1;
	local vt = #data.variables;
	local et = #data.expressions;

	for k = 1, #data.variables do
		local token = data.variables[k];
		local var = token.data;

		local valid = false;
		local expr = data.expressions[k];
		
		if expr then
			valid = true;
			expr.data.call_pred = (k == et) and (vt - k) + 1 or 1;
			r, c, p = this:Compile(expr);
			price = price + p;
		end

		if k == et then
			c = c - 1;
			this:writeToBuffer(inst, "\nlocal ");

			for i = k, vt do
				this:writeToBuffer(inst, "__" .. data.variables[i].data);
				if (i < vt) then this:writeToBuffer(inst, ","); end
			end

			this:writeToBuffer(inst, "=");

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");

			expr = fakeInstruction(inst, "__" .. var, r, 1);
		end

		if not valid then
			if c <= 1 then
				this:Throw(token, "Value expected, for Variable %s.", var);
			else
				expr = fakeInstruction(inst, "__" .. var, r, 1);
				c = c - 1;
			end
		end

		local class, scope, info = this:GetVariable(var, nil, false);

		if (not class) then
			this:Throw(token, "Variable %s does not exist.", var);
		end

		if (info and info.prefix) then
			var = info.prefix .. "." .. token.data;
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

		if (not op.operator) then
			this:writeToBuffer(inst, "%s = %s *", var, var);

			this:addInstructionToBuffer(inst, expr);

			this:writeToBuffer(inst, ";\n");
		else
			this:writeToBuffer(inst, "%s = ", var);

			this:writeOperationCall(inst, op, "var", expr);

			this:writeToBuffer(inst, ";\n");
		end

		price = price + op.price;

		this:AssignVariable(token, false, token.data, op.result);
	end

	return nil, nil, price;
end

--[[
]]

function COMPILER.Compile_GROUP(this, inst, token, data)

	this:writeToBuffer(inst, "(");

	local r, c, p = this:Compile(data.expr);

	this:addInstructionToBuffer(inst, data.expr);

	this:writeToBuffer(inst, ")");

	return r, c, p;
end

function COMPILER.Compile_TEN(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local expr3 = data.expr3;
	local r3, c3, p3 = this:Compile(expr3);

	local price = p1 + p2 + p3;
	local op = this:GetOperator("ten", r1, r2, r3);

	if not op and not (r1 == "b" and r2 == r3) then
		this:Throw(expr.token, "Tenary operator (A ? B : C) does not support '%s ? %s : %s'", name(r1), name(r2), name(r3));
	elseif (not op or not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "and");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, "or");

		this:addInstructionToBuffer(inst, expr3);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2, expr3);
	end

	if op then
		this:CheckState(op.state, token, "Tenary operator (A ? B : C)");

		return op.result, op.rCount, price + op.price;
	end

	return r2, 1, price + EXPR_MIN;
end


function COMPILER.Compile_OR(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("or", r1, r2);

	if (not op) then
		local is1 = this:Expression_IS(expr1);
		local is2 = this:Expression_IS(expr2);

		if (is1 and is2) then
			op = this:GetOperator("or", "b", "b");
		end

		if (not op) then
			this:Throw(token, "Logical or operator (||) does not support '%s || %s'", name(r1), name(r2));
		end
	end

	if (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "or");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Logical or operator (||) '%s || %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_AND(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

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
	end

	if (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "and");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Logical and operator (&&) '%s && %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_BXOR(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("bxor", r1, r2);

	if (not op) then
		this:Throw(token, "Binary xor operator (^^) does not support '%s ^^ %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "bit.bxor(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, ",");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Binary xor operator (^^) '%s ^^ %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_BOR(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("bor", r1, r2);

	if (not op) then
		this:Throw(token, "Binary or operator (|) does not support '%s | %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "bit.bor(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, ",");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Binary xor operator (|) '%s | %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_BAND(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("band", r1, r2);

	if (not op) then
		this:Throw(token, "Binary or operator (&) does not support '%s & %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "bit.band(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, ",");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Binary xor operator (&) '%s & %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_EQ_MUL(this, inst, token, data)
	--(function(value) return operations; end)(value)

	this:writeToBuffer(inst, "((function(eq_val) return ");

	local expr1 = data.expressions[1];
	local r1, c1, price = this:Compile(expr1);

	local total = #data.expressions;

	for i = 2, total do

		local expr2 = data.expressions[i];
		local r2, c2, p2 = this:Compile(expr2);

		local op = this:GetOperator("eq", r1, r2);

		if (not op) then
			this:Throw(token, "Comparison operator (==) does not support '%s == %s'", name(r1), name(r2));
		elseif (not op.operator) then
			this:writeToBuffer(inst, "(");

			this:writeToBuffer(inst, "eq_val");

			this:writeToBuffer(inst, "==");

			this:addInstructionToBuffer(inst, expr2);

			this:writeToBuffer(inst, ")");
		else
			this:writeOperationCall(inst, op, "eq_val", expr2);
		end

		price = price + p2 + op.price;

		this:CheckState(op.state, token, "Comparison operator (==) '%s == %s'", name(r1), name(r2));

		if (i < total) then
			this:writeToBuffer(inst, " or ");
		end
	end

	this:writeToBuffer(inst, "; end) (");

	this:addInstructionToBuffer(inst, expr1);

	this:writeToBuffer(inst, "))");

	return "b", 1, price;
end

function COMPILER.Compile_EQ(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("eq", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (==) does not support '%s == %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "==");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Comparison operator (==) '%s == %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_NEQ_MUL(this, inst, token, data)
	--(function(value) return operations; end)(value)

	this:writeToBuffer(inst, "((function(eq_val) return ");

	local expr1 = data.expressions[1];
	local r1, c1, price = this:Compile(expr1);

	local total = #data.expressions;

	for i = 2, total do

		local expr2 = data.expressions[i];
		local r2, c2, p2 = this:Compile(expr2);

		local op = this:GetOperator("neq", r1, r2);

		if (not op) then
			this:Throw(token, "Comparison operator (!=) does not support '%s != %s'", name(r1), name(r2));
		elseif (not op.operator) then
			this:writeToBuffer(inst, "(");

			this:writeToBuffer(inst, "eq_val");

			this:writeToBuffer(inst, "~=");

			this:addInstructionToBuffer(inst, expr2);

			this:writeToBuffer(inst, ")");
		else
			this:writeOperationCall(inst, op, "eq_val", expr2);
		end

		price = price + p2 + op.price;

		this:CheckState(op.state, token, "Comparison operator (!=) '%s != %s'", name(r1), name(r2));

		if (i < total) then
			this:writeToBuffer(inst, " and ");
		end
	end

	this:writeToBuffer(inst, "; end) (");

	this:addInstructionToBuffer(inst, expr1);

	this:writeToBuffer(inst, "))");

	return "b", 1, price;
end

function COMPILER.Compile_NEQ(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("neq", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (!=) does not support '%s != %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "~=");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Comparison operator (!=) '%s != %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_LTH(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("lth", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (<) does not support '%s < %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "<");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Comparison operator (<) '%s < %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_LEQ(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("leg", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (<=) does not support '%s <= %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "<=");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Comparison operator (<=) '%s <= %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_GTH(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("gth", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (>) does not support '%s > %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, ">");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Comparison operator (>) '%s > %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_GEQ(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("geq", r1, r2);

	if (not op) then
		this:Throw(token, "Comparison operator (>=) does not support '%s >= %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, ">=");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Comparison operator (>=) '%s >= %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_BSHL(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("bshl", r1, r2);

	if (not op) then
		this:Throw(token, "Binary shift operator (<<) does not support '%s << %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "bit.lshift(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, ",");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Binary shift operator (<<) '%s << %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_BSHR(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("bshr", r1, r2);

	if (not op) then
		this:Throw(token, "Binary shift operator (>>) does not support '%s >> %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "bit.rshift(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, ",");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Binary shift operator (>>) '%s >> %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

--[[
]]

function COMPILER.Compile_ADD(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("add", r1, r2);

	if (not op) then
		this:Throw(token, "Addition operator (+) does not support '%s + %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		if (r1 == "s" or r2 == "s") then
			this:writeToBuffer(inst, "..");
		else
			this:writeToBuffer(inst, "+");
		end

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Addition operator (+) '%s + %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_SUB(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("sub", r1, r2);

	if (not op) then
		this:Throw(token, "Subtraction operator (-) does not support '%s - %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "-");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Subtraction operator (-) '%s - %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_DIV(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("div", r1, r2);

	if (not op) then
		this:Throw(expr.token, "Division operator (/) does not support '%s / %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "/");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Division operator (/) '%s / %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_MUL(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("mul", r1, r2);

	if (not op) then
		this:Throw(token, "Multiplication operator (*) does not support '%s * %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "*");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Multiplication operator (*) '%s * %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_EXP(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("exp", r1, r2);

	if (not op) then
		this:Throw(token, "Exponent operator (^) does not support '%s ^ %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "^");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Exponent operator (^) '%s ^ %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_MOD(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local expr2 = data.expr2;
	local r2, c2, p2 = this:Compile(expr2);

	local op = this:GetOperator("mod", r1, r2);

	if (not op) then
		this:Throw(token, "Modulus operator (%) does not support '%s % %s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "(");

		this:addInstructionToBuffer(inst, expr1);

		this:writeToBuffer(inst, "%");

		this:addInstructionToBuffer(inst, expr2);

		this:writeToBuffer(inst, ")");
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Modulus operator (%) '%s % %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_NEG(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local op = this:GetOperator("neg", r1);

	if (not op) then
		this:Throw(token, "Negation operator (-A) does not support '-%s'", name(r1));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "-");

		this:addInstructionToBuffer(inst, expr1);
	else
		this:writeOperationCall(inst, op, expr1);
	end

	this:CheckState(op.state, token, "Negation operator (-A) '-%s'", name(r1));

	return op.result, op.rCount, (p1 + op.price);
end

function COMPILER.Compile_NOT(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local op = this:GetOperator("not", r1);

	if (not op) then
		this:Throw(token, "Not operator (!A) does not support '!%s'", name(r1));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "not");

		this:addInstructionToBuffer(inst, expr1);
	else
		this:writeOperationCall(inst, op, expr1);
	end

	this:CheckState(op.state, token, "Not operator (!A) '!%s'", name(r1));

	return op.result, op.rCount, (p1 + op.price);
end

function COMPILER.Compile_LEN(this, inst, token, data)
	local expr1 = data.expr;
	local r1, c1, p1 = this:Compile(expr1);

	local op = this:GetOperator("len", r1);

	if (not op) then
		this:Throw(token, "Length operator (#A) does not support '#%s'", name(r1), name(r2));
	elseif (not op.operator) then
		this:writeToBuffer(inst, "#");

		this:addInstructionToBuffer(inst, expr1);
	else
		this:writeOperationCall(inst, op, expr1);
	end

	this:CheckState(op.state, token, "Length operator (#A) '#%s'", name(r1));

	return op.result, op.rCount, (p1 + op.price);
end

function COMPILER.Compile_DELTA(this, inst, token, data)
	local var = data.var;

	if (this.__defined[var]) then
		this:Throw(token, "Variable %s is defined here and can not be used as part of an expression.", var);
	end

	local c, s, info = this:GetVariable(var);

	if (not c) then
		this:Throw(token, "Variable %s does not exist.", var);
	end

	if (not info.global) then
		this:Throw(token, "Delta operator ($) can not be used on none global variable %s.", var);
	end

	local op = this:GetOperator("dlt", c);

	if (not op) then
		this:Throw(token, "Delta operator ($) does not support '$%s'", name(c));
	end

	if (info and info.prefix) then
		this:writeOperationCall(inst, op, "DELTA." .. var, info.prefix .. "." .. var);
	else
		this:writeOperationCall(inst, op, "DELTA." .. var, var);
	end

	this:CheckState(op.state, token, "Delta operator ($) '$%s'", name(c));

	return op.result, op.rCount, op.price;
	
end

function COMPILER.Compile_CHANGED(this, inst, token, data)
	local var = data.var;

	if (this.__defined[var]) then
		this:Throw(token, "Variable %s is defined here and can not be used as part of an expression.", var);
	end

	local c, s, info = this:GetVariable(var);

	if (not c) then
		this:Throw(token, "Variable %s does not exist.", var);
	end

	if (not info.global) then
		this:Throw(token, "Changed operator (~) can not be used on none global variable %s.", var);
	end

	local op = this:GetOperator("neq", c, c);

	if (not op) then
		this:Throw(token, "Changed operator (~) does not support '~%s'", name(c));
	elseif (not op.operator) then
		
		if (info and info.prefix) then
			this:writeToBuffer(inst, "(DELTA.%s ~= %s.%s)", var, info.prefix, var);
		else
			this:writeToBuffer(inst, "(DELTA.%s ~= %s)", var, var);
		end

	else
		if (info and info.prefix) then
			this:writeOperationCall(inst, op, string_format("DELTA.%s", var), string_format("%s.%s", info.prefix, var));
		else
			this:writeOperationCall(inst, op, string_format("DELTA.%s", var), var);
		end
	end

	this:CheckState(op.state, token, "Changed operator (~) '~%s'", name(c));

	return op.result, op.rCount, op.price;
end

function COMPILER.Expression_IS(this, expr)
	local op = this:GetOperator("is", expr.result);

	if (op) then
		if (not this:CheckState(op.state)) then
			return false, expr;
		elseif (not op.operator) then
			expr.result = op.type;
			expr.rCount = op.count;
			expr.price = expr.price + op.price;

			return true, expr;
		else
			local temp = table.Copy(expr);

			expr.buffer = {};

			this:writeOperationCall(expr, op, temp);

			expr.result = op.type;
			expr.rCount = op.count;
			expr.price = expr.price + op.price;

			return true, expr;
		end
	elseif (expr.result == "b") then
		return true, expr;
	end

	return false, expr;
end

function COMPILER.Compile_IOF(this, inst, token, data)
	local r, c, p = this:Compile(data.expr);

	local userclass = this:GetClassOrInterface(data.class);

	if (not userclass or not this:GetClassOrInterface(r)) then
		this:Throw(token, "Instanceof currently only supports user classes, sorry about that :D");
	end

	this:writeToBuffer(inst, string_format("CheckHash(%q,", userclass.hash));

	this:addInstructionToBuffer(inst, data.expr);

	this:writeToBuffer(inst, ")");

	return "b", 1, EXPR_LOW;
end

function COMPILER.CastUserType(this, left, right)
	local to = this:GetClassOrInterface(left);
	local from = this:GetClassOrInterface(right);

	if (not to) or (not from) then return end;

	if (not this.__hashtable[to.hash][from.hash]) then
		if (this.__hashtable[from.hash][to.hash]) then
			return {
				signature = string_format("(%s)%s", to.hash, from.hash),
				context = true,
				result = left,
				rCount = 1,
				operator = function(ctx, obj)
					if (not ctx.env.CheckHash(to.hash, obj)) then
						ctx:Throw("Failed to cast %s to %s, #class missmatched.", name(right), name(left));
					end; return obj;
				end,
			};
		end

		return nil;
	end

	return {
		result = left,
		rCount = 1,
		price = EXPR_LOW;
	};
	-- hashtable[extends][class] = is isinstance of.
end

function COMPILER.CastExpression(this, type, expr)

	local op = this:CastUserType(type, expr.result);

	if op then
		local temp = table.Copy(expr);

		expr.buffer = {};

		this:addInstructionToBuffer(expr, temp);
	else
		local signature = string_format("(%s)%s", type, expr.result);

		op = EXPR_CAST_OPERATORS[signature];

		if (not op) then
			return false, expr;
		end

		if (not this:CheckState(op.state)) then
			return false, expr;
		end

		if (op.operator) then
			local temp = table.Copy(expr);

			expr.buffer = {};

			this:writeOperationCall(expr, op, temp);
		end
	end

	expr.result = op.result;
	expr.rCount = op.rCount;
	expr.price = expr.price + op.price;

	return true, expr;
end

function COMPILER.Compile_CAST(this, inst, token, data)
	local expr = data.expr;

	this:Compile(expr);

	local t = this:CastExpression(data.class, expr);

	if (not t) then
		this:Throw(token, "Type of %s can not be cast to type of %s.", name(expr.result), name(data.class))
	end

	this:addInstructionToBuffer(inst, expr);

	return expr.result, expr.rCount, expr.price;
end

function COMPILER.Compile_VAR(this, inst, token, data)
	if (this.__defined[inst.variable]) then
		this:Throw(token, "Variable %s is defined here and can not be used as part of an expression.", data.variable);
	end

	local c, s, var = this:GetVariable(data.variable);

	if (var) then
		if (var.attribute) then
			this:writeToBuffer(inst, "this.");
		end

		if (var.prefix) then
			this:writeToBuffer(inst, var.prefix);
			this:writeToBuffer(inst, ".");
		end
	end

	this:writeToBuffer(inst, data.variable);

	if (not c) then
		this:Throw(token, "Variable %s does not exist.", data.variable);
	end

	return c, 1, EXPR_LOW;
end

function COMPILER.Compile_BOOL(this, inst, token, data)
	if data.value then
		this:writeToBuffer(inst, "true");
	else
		this:writeToBuffer(inst, "false");
	end

	return "b", 1, EXPR_MIN;
end

function COMPILER.Compile_NUM(this, inst, token, data)
	this:writeToBuffer(inst, data.value);
	return "n", 1, EXPR_MIN;
end

function COMPILER.Compile_STR(this, inst, token, data)
	this:writeToBuffer(inst, data.value);
	return "s", 1, EXPR_MIN;
end

function COMPILER.Compile_PTRN(this, inst, token, data)
	this:writeToBuffer(inst, data.value);
	return "_ptr", 1, EXPR_MIN;
end

function COMPILER.Compile_CLS(this, inst, token, data)
	this:writeToBuffer(inst, "\"" .. data.value .. "\"");
	return "_cls", 1, EXPR_MIN;
end

function COMPILER.Compile_VOID(this, inst, token)
	this:writeToBuffer(inst, "void");
	return "", 1, EXPR_MIN;
end

function COMPILER.Compile_COND(this, inst, token, data)
	local expr = data.expr;
	local r, c, p = this:Compile(expr);

	if (r == "b") then
		this:addInstructionToBuffer(inst, expr);
		return r, c;
	end

	local op = this:GetOperator("is", r);

	if (not op and this:CastExpression("b", expr)) then
		this:addInstructionToBuffer(inst, expr);
		return r, "b", expr.price;
	end

	if (not op) then
		this:Throw(token, "No such condition (%s).", name(r));
	elseif (not op.operator) then
		this:addInstructionToBuffer(inst, expr);
	else
		this:writeOperationCall(inst, op, expr);
	end

	return op.result, op.rCount, (op.price + p);
end

function COMPILER.Compile_NEW(this, inst, token, data)
	local op;
	local ids = {};
	local total = #data.expressions;

	local price = 0;

	local classname = data.class
	local cls = E3Class(classname);
	local userclass = this:GetUserClass(classname);

	if (not cls and userclass) then
		cls = userclass;
		classname = "constructor";
	end

	if (total == 0) then
		op = cls.constructors[classname .. "()"];
	else
		local constructors = cls.constructors;

		for k, expr in pairs(data.expressions) do
			local r, c, p = this:Compile(expr);

			ids[#ids + 1] = r;
			price = price + p;

			if (k == total) then
				if (c > 1) then
					for i = 2, c do
						ids[#ids + 1] = r;
					end
				end
			end
		end

		for i = #ids, 1, -1 do
			local args = table_concat(ids,",", 1, i);

			if (i >= total) then
				local signature = string_format("%s(%s)", classname, args);

				op = constructors[signature];
			end

			if (not op) then
				local signature = string_format("%s(%s,...)", classname, args);
				op = constructors[signature];
				if (op) then vargs = i + 1; end
			end

			if (op) then
				break;
			end
		end

		if (not op) then
			op = constructors[classname .. "(...)"];
			if (op) then vargs = 1; end
		end
	end

	local signature = string_format("%s(%s)", name(data.class), names(ids));

	if (op and userclass) then
		this:writeToBuffer(inst, "%s[%q](", cls.name, op);

		for k, expr in pairs(data.expressions) do
			this:addInstructionToBuffer(inst, expr);

			if (k < #data.expressions) then
				this:writeToBuffer(inst, ",");
			end
		end

		this:writeToBuffer(inst, ")");

		return userclass.name, 1, price;
	end

	if (not op) then
		this:Throw(token, "No such constructor, new %s", signature);
	end

	this:CheckState(op.state, token, "Constructor 'new %s", signature);

	if (type(op.operator) == "function") then
		this.__constructors[op.signature] = op.operator;
		this:writeOperationCall2("_CONST", inst, op, vargs, unpack(data.expressions));
	elseif (type(op.operator) == "string") then
		this:writeToBuffer(inst, op.operator);
	else
		local signature = string_format("%s.", inst.library, op.signature);
		error("Attempt to inject " .. op.signature .. " but operator was incorrect " .. type(op.operator) .. ".");
	end

	return op.result, op.rCount, (price + op.price);
end

local function getMethod(mClass, userclass, method, ...)
	local prams = table_concat({...}, ",");

	if (userclass) then
		local sig = string_format("@%s(%s)", method, prams);
		return userclass.methods[sig];
	end

	local sig = string_format("%s.%s(%s)", mClass, method, prams);

	local op = EXPR_METHODS[sig];

	if op then return op; end

	local class = E3Class(mClass);

	if (class and class.base) then
		local op = getMethod(class.base, userclass, method, ...)
		if (op) then return op; end
	end
end

function COMPILER.Compile_METH(this, inst, token, data)
	local expressions = data.expressions;

	local expr = expressions[1];
	local mClass, mCount = this:Compile(expr);

	local op;
	local vargs;
	local ids = {};
	local total = #expressions;
	local method = data.method;
	local userclass = this:GetUserClass(mClass);

	local price = 0;

	if (total == 1) then
		op = getMethod(mClass, userclass, method);
	else
		for k, expr in pairs(expressions) do
			if (k > 1) then
				local r, c, p = this:Compile(expr);

				ids[#ids + 1] = r;

				price = price + p;

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
			local args = table_concat(ids,",", 1, i);

			if (i == total -  1) then
				op = getMethod(mClass, userclass, method, args);
			end

			if (not op) then
				op = getMethod(mClass, userclass, method, args, "...");

				if (op) then
					vargs = i;
				end
			end

			if (op) then
				break;
			end
		end

		if (not op) then
			op = getMethod(mClass, userclass, method, "...");

			if (op) then
				vargs = 1;
			end
		end
	end

	if (not op) then
		this:Throw(token, "No such method %s.%s(%s).", name(mClass), method, names(ids));
	end

	if (userclass) then
		this:writeOperationCall2(userclass.name, inst, op, vargs, unpack(expressions));
		return op.result, op.count, (op.price + price);
	end

	this:CheckState(op.state, token, "Method %s.%s(%s)", name(mClass), method, names(ids));

	if (type(op.operator) == "function") then
		this:writeMethodCall(inst, op, unpack(expressions));
	elseif (type(op.operator) == "string") then
		this:addInstructionToBuffer(inst, expr);

		this:addInstructionToBuffer(inst, ":");

		this:writeToBuffer(inst, op.operator .. "(");

		this:writeArgsToBuffer(inst, vargs, unpack(expressions, 2));

		this:addInstructionToBuffer(inst, ")");
	else
		local signature = string_format("%s.%s", name(inst.class), op.signature);
		error("Attempt to inject " .. op.signature .. " but operator was incorrect, got " .. type(op.operator));
	end

	return op.result, op.rCount, (op.price + price);
end

function COMPILER.Compile_CONST(this, inst, token, data)
	local library = data.library.data;
	local lib = EXPR_LIBRARIES[library];

	if (not lib) then
		this:Throw(token, "Library %s does not exist.", library);
	end

	local op = lib._constants[data.name];

	if (not lib) then
		this:Throw(token, "No such constant %.%s", library, data.name);
	end

	if not op.native then
		this:Throw(token, "Constant %.%s is beyound modern science :(", library, data.name);
	end

	this:writeToBuffer(inst, op.value);

	return op.result, 1, 0;
end

function COMPILER.Compile_FUNC(this, inst, token, data)
	local lib = EXPR_LIBRARIES[data.library.data];

	if (not lib) then
		-- Please note this should be impossible.
		this:Throw(token, "Library %s does not exist.", inst.library.data);
	end

	local op;
	local vargs;
	local ids = {};
	local total = #data.expressions;

	local price = 0;

	if (total == 0) then
		op = lib._functions[data.name .. "()"];
	else
		for k, expr in pairs(data.expressions) do
			local r, c, p = this:Compile(expr);

			ids[#ids + 1] = r;

			price = price + p;

			if (k == total) then
				if (c > 1) then
					for i = 2, c do
						ids[#ids + 1] = r;
					end
				end
			end
		end

		for i = #ids, 1, -1 do
			local args = table_concat(ids,",", 1, i);

			if (i >= total) then
				local signature = string_format("%s(%s)", data.name, args);

				op = lib._functions[signature];
			end

			if (not op) then
				local signature = string_format("%s(%s,...)", data.name, args);

				op = lib._functions[signature];

				if (op) then vargs = i + 1 end
			end

			if (op) then
				break;
			end
		end

		if (not op) then
			op = lib._functions[data.name .. "(...)"];

			if (op) then vargs = 1 end
		end
	end

	if (not op) then
		this:Throw(token, "No such function %s.%s(%s).", data.library.data, data.name, names(ids, ","));
	end

	this:CheckState(op.state, token, "Function %s.%s(%s).", data.library.data, data.name, names(ids, ","));

	local compile = function()
		if (type(op.operator) == "function") then
			local signature = string_format("%s.%s", data.library.data, op.signature);

			if op.context then
				if vargs then vargs = vargs + 1; end
				this:writeOperationCall2("_FUN", inst, signature, vargs, "CONTEXT", unpack(data.expressions));
			else
				this:writeOperationCall2("_FUN", inst, signature, vargs, unpack(data.expressions));
			end

			this.__functions[signature] = op.operator;
		elseif (type(op.operator) == "string") then
			this:writeToBuffer(inst, op.operator .. "(");
			this:writeArgsToBuffer(inst, false, unpack(data.expressions));
			this:writeToBuffer(inst, ")");
			this:Import(op.operator);
		else
			local signature = string_format("%s.", inst.library, op.signature);
			error("Attempt to inject " .. signature .. " but operator was incorrect " .. type(op.operator) .. ".");
		end

		return op.result, op.rCount, (op.price + price);
	end;

	if (data.library.data == "system") then
		local res, count, prc = hook.Run("Expression3.PostCompile.System." .. data.name, this, inst, token, data, compile);

		price = price + (prc or 0);

		if (res and count) then
			return res, count, price;
		end
	end

	return compile();
end

--[[
]]

function COMPILER.Compile_LAMBDA(this, inst, token, data)
	this:PushScope();

	this:writeToBuffer(inst, "{op = function(");

	local args = data.params;
	local tArgs = #args;

	for k = 1, tArgs do
		local param = args[k];
		local var = param[2];
		local class = param[1];

		this:writeToBuffer(inst, var);
		this:AssignVariable(token, true, var, class);

		if (k < tArgs) then
			this:writeToBuffer(inst, ",");
		end
	end

	this:writeToBuffer(inst, ")\n");

	for k = 1, tArgs do
		local param = args[k];
		local var = param[2];
		local class = param[1];

		if (class ~= "_vr") then
			this:writeToBuffer(inst, "if (%s == nil or %s[1] == nil) then CONTEXT:Throw(\"%s expected for %s, got void\"); end\n", var, var, name(class), var);
			this:writeToBuffer(inst, "if (%s[1] ~= %q) then CONTEXT:Throw(\"%s expected for %s, got \" .. %s[1]); end\n", var, class, name(class), var, var);
			this:writeToBuffer(inst, "%s = %s[2];\n", var, var);
			--this:writeToBuffer(inst, "print('called function')");
		end
	end

	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);

	this:SetOption("loop", false);
	this:SetOption("canReturn", true);
	this:SetOption("retunClass", "?"); -- Indicate we do not know this yet.
	this:SetOption("retunCount", -1); -- Indicate we do not know this yet.

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

	local result = this:GetOption("retunClass");
	local count = this:GetOption("retunCount");

	this:PopScope();

	if (result == "?" or count == -1) then
		result = "";
		count = 0;
	end

	this:writeToBuffer(inst, "\nend,\nresult = %q, count = %i, scr = CONTEXT}", result, count);

	return "f", 1, EXPR_LOW;
end

--[[
]]

function COMPILER.Compile_RETURN(this, inst, token, data)
	if (not this:GetOption("canReturn", false)) then
		this:Throw(token, "A return statment can not appear here.");
	end

	local result = this:GetOption("retunClass");
	local count = this:GetOption("retunCount");

	local price = 0;

	local results = {};

	for _, expr in pairs(data.expressions) do
		local r, c, p = this:Compile(expr);

		price = price + p;

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

	this:writeToBuffer(inst, "\nreturn ");

	local outCount = 0;

	for i = 1, #results do
		local expr = data.expressions[i];
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

		this:addInstructionToBuffer(inst, expr);

		if (i < #results) then
			this:writeToBuffer(inst, ",");
		end
	end

	this:writeToBuffer(inst, ";\n");

	if (count == -1) then
		count = outCount;
		this:SetOption("retunCount", outCount, true);
	end

	if (count ~= outCount) then
		this:Throw(expr.token, "Can not return %i %s('s) here, %i %s('s) expected.", outCount, name(outClass), count, name(outClass));
	end

	return nil, nil, price;
end

function COMPILER.Compile_BREAK(this, inst, token)
	if (not this:GetOption("loop", false)) then
		this:Throw(token, "Break must not appear outside of a loop");
	end

	this:writeToBuffer(inst, "\nbreak\n;");

	return nil, nil, EXPR_MIN;
end

function COMPILER.Compile_CONTINUE(this, inst, token)
	if (not this:GetOption("loop", false)) then
		this:Throw(token, "Continue must not appear outside of a loop");
	end

	this:writeToBuffer(inst, "\ncontinue\n;");

	return nil, nil, EXPR_MIN;
end

--[[
]]

function COMPILER.Compile_DELEGATE(this, inst, token, data)
	local class, scope, info = this:AssignVariable(token, true, data.variable, "f");

	if (info) then
		info.signature = table_concat(data.parameters, ",");
		info.parameters = data.parameters;
		info.resultClass = data.result_class;
		info.resultCount = data.result_count;
	end

	this:writeToBuffer(inst, "\nlocal %s;\n", data.variable);

	return nil, nil, EXPR_MIN;
end

function COMPILER.Compile_FUNCT(this, inst, token, data)
	local variable = data.variable;

	local class, scope, info = this:AssignVariable(token, true, variable, "f");

	if (info and info.prefix) then
		this:writeToBuffer(inst, "local %s.%s = {op = function(", info.prefix, variable);
	else
		this:writeToBuffer(inst, "local %s = {op = function(", variable);
	end

	this:PushScope();

	local args = data.params;
	local tArgs = #args;

	for k = 1, tArgs do
		local param = args[k];
		local var = param[2];
		local class = param[1];

		this:writeToBuffer(inst, var);
		this:AssignVariable(token, true, var, class);

		if (k < tArgs) then
			this:writeToBuffer(inst, ",");
		end
	end

	this:writeToBuffer(inst, ")\n");

	for k = 1, tArgs do
		local param = args[k];
		local var = param[2];
		local class = param[1];

		if (class ~= "_vr") then
			this:writeToBuffer(inst, "if (%s == nil or %s[1] == nil) then CONTEXT:Throw(\"%s expected for %s, got void\"); end\n", var, var, name(class), var);
			this:writeToBuffer(inst, "if (%s[1] ~= %q) then CONTEXT:Throw(\"%s expected for %s, got \" .. %s[1]); end\n", var, class, name(class), var, var);
			this:writeToBuffer(inst, "%s = %s[2];\n", var, var);
		end
	end

	this:SetOption("loop", false);
	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);
	this:SetOption("canReturn", true);
	this:SetOption("retunClass", data.resultClass or "");
	this:SetOption("retunCount", -1); -- Indicate we do not know this yet.

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

	local count = this:GetOption("retunCount");
	this:SetOption("retunClass", "?");
	this:SetOption("retunCount", -1); -- Indicate we do not know this yet.

	this:PopScope();

	if (info) then
		info.signature = data.signature;
		info.parameters = data.params;
		info.resultClass = data.resultClass;
		info.resultCount = count;
	end

	this:writeToBuffer(inst, "\nend,\nresult = %q, count = %i, scr = CONTEXT};\n", data.resultClass, count);

	return nil, nil, EXPR_MIN;
end

--[[
]]

function COMPILER.Compile_CALL(this, inst, token, data)
	local args = data.expressions;
	local tArgs = #args;

	local expr = args[1];
	local res, count, price = this:Compile(expr);
	--variables, class

	if (res == "_cls") then
		if (token.type == "typ") then
			this:Throw(token, "Invalid use of constructor, must be part of statment.");
		else
			this:Throw(token, "Invalid use of constructor, class name must be defined.");
		end
	end

	local prms = {};

	if (tArgs > 1) then
		for i = 2, tArgs do
			local arg = args[i];
			local r, c, p = this:Compile(arg);

			price = price + p;

			prms[#prms + 1] = r;

			if (i == targs and c > 1) then
				for j = 2, c do
					prms[#prms + 1] = r;
				end
			end
		end
	end

	local signature = table_concat(prms, ",");

	local parent = inst.parent;
	local resultClass, resultCount;

	if (parent and parent.data) then
		if (parent.data.variables) then 
			
			if (parent.data.class) then
				resultClass = parent.data.class;
				resultCount = data.call_pred or #parent.data.variables;
			else
				local var = parent.data.variables[1];

				if (var) then
					local c, s, info = this:GetVariable(var.data);
					
					if (c) then 
						resultClass = c;
						resultCount = data.call_pred or #parent.data.variables;
					end
				end
			end
		end
	end	

	if (res == "f") then

		local c, s, info;

		if (expr.type == "var") then
			c, s, info = this:GetVariable(expr.data.variable);
			-- The var instruction will have already validated this variable.

			if (info and info.signature) then
				resultClass = info.resultClass;
				resultCount = info.resultCount;
			end
		end

		if (resultClass and resultCount) then

			this:writeToBuffer(inst, "invoke(CONTEXT, %q, %i,", resultClass, resultCount);

			if (info) then
				if (info.signature and info.signature ~= signature) then
					this:Throw(token, "Invalid arguments to user function got %s(%s), %s(%s) expected.", expr.data.variable, names(signature), expr.data.variable, names(info.signature));
				end
			end

			this:addInstructionToBuffer(inst, expr);

			if (tArgs > 1) then

				this:writeToBuffer(inst, ",");

				for i = 2, tArgs do
					local arg = args[i];
					local vr = arg.result ~= "_vr";

					if (vr) then
						this:writeToBuffer(inst, "{%q,", arg.result);
					end

					this:addInstructionToBuffer(inst, arg);

					if (vr) then
						this:writeToBuffer(inst, "}");
					end

					if (i < tArgs) then
						this:writeToBuffer(inst, ",");
					end
				end
			end

			this:writeToBuffer(inst, ")");

			return resultClass, resultCount, (price + EXPR_MIN);
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
			local args = table_concat(prms,",", 1, i);

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

	--this:QueueRemove(inst, token); -- Removes (

	this:writeOperationCall(inst, op, unpack(args));

	return op.result, op.rCount, (op.price + price);
end

--[[
]]

function COMPILER.Compile_GET(this, inst, token, data)
	local expressions = data.expressions;
	local value = expressions[1];
	local vType, vCount, vPrice = this:Compile(value);
	local index = expressions[2];
	local iType, iCount, iPrice = this:Compile(index);

	local op;
	local keepid = false;
	local class = data.class;

	local op_result = "";
	local op_count = 0;

	if (not class) then
		op = this:GetOperator("get", vType, iType);

		if (not op) then
			this:Throw(token, "No such get operation %s[%s]", name(vType), name(iType));
		end

		op_result = op.result;
		op_count = op.rCount;

	else
		op = this:GetOperator("get", vType, iType, class);

		if (op) then
			op_result = op.result;
			op_count = op.rCount;
		else
			keepid = true;

			op = this:GetOperator("get", vType, iType, "_cls");

			if (op) then
				op_result = op.result;
				op_count = op.rCount;

				if (op_result == "" or op_result == "_nil") then
					op_result = cls;
					op_count = 1;
				end
			end
		end

		if (not op) then
			if cls then
				this:Throw(token, "No such get operation %s[%s,%s]", name(vType), name(iType), name(class));
			else
				this:Throw(token, "No such get operation %s[%s]", name(vType), name(iType));
			end
		end
	end

	this:CheckState(op.state);

	if (not op.operator) then
		this:addInstructionToBuffer(inst, value);

		this:writeToBuffer(inst, "[");

		this:addInstructionToBuffer(inst, index);

		this:writeToBuffer(inst, "]");

		return op_result, op_count, (op.price + vPrice + iPrice);
	end

	if (keepid) then
		this:writeOperationCall(inst, op, value, index, string_format("%q", class));
	else
		this:writeOperationCall(inst, op, value, index);
	end

	if (class) then
		return class, 1, (op.price + vPrice + iPrice);
	end

	return op_result, op_count, (op.price + vPrice + iPrice);
end

function COMPILER.Compile_SET(this, inst, token, data)
	local expressions = data.expressions;

	local value = expressions[1];
	local vType, vCount, p1 = this:Compile(value);

	local index = expressions[2];
	local iType, iCount, p2 = this:Compile(index);

	local expr = expressions[3];
	local vExpr, c, p3 = this:Compile(expr);

	local op;
	local keepclass = false;
	local cls = data.class;

	if (cls and vExpr ~= cls) then
		this:Throw(token, "Can not assign %s onto %s, %s expected.", name(vExpr), name(vType), name(cls.data));
	end

	if (not cls) then
		op = this:GetOperator("set", vType, iType, vExpr);
	else
		op = this:GetOperator("set", vType, iType, cls);

		if (not op) then
			keepclass = true;
			op = this:GetOperator("set", vType, iType, "_cls", vExpr)
		end
	end

	if (not op) then
		if (not cls) then
			this:Throw(token, "No such set operation %s[%s] = %s", name(vType), name(iType), name(vExpr));
		else
			this:Throw(token, "No such set operation %s[%s, %s] = %s", name(vType), name(iType), name(cls), name(vExpr));
		end
	end

	this:CheckState(op.state);

	if (not op.operator) then
		this:addInstructionToBuffer(inst, value);

		this:writeToBuffer(inst, "[");

		this:addInstructionToBuffer(inst, index);

		this:writeToBuffer(inst, "] = ");

		this:addInstructionToBuffer(inst, expr);

		this:writeToBuffer(inst, ";\n");

		return op.result, op.rCount, (op.price + p1 + p2 + p3);
	end

	if (keepclass) then
		this:writeOperationCall(inst, op, value, index, string_format("%q", cls), expr);
	else
		this:writeOperationCall(inst, op, value, index, expr);
	end

	return op.result, op.rCount, (op.price + p1 + p2 + p3);
end

--[[
]]

function COMPILER.Compile_FOR(this, inst, token, data)
	local class = data.iClass.data;
	local expressions = data.expressions;

	local var = data.iVar.data;
	this:writeToBuffer(inst, "\nfor %s = ", var);

	local start = expressions[1];
	local tStart, cStart, p1 = this:Compile(start);
	this:addInstructionToBuffer(inst, start);

	this:writeToBuffer(inst, ",");

	local _end = expressions[2];
	local tEnd, cEnd, p2 = this:Compile(_end);
	this:addInstructionToBuffer(inst, _end);

	local price = p1 + p2;
	local step = expressions[3];

	if (step) then
		local tStep, cStep, p3 = this:Compile(step);

		if (class ~= "n" or tStart  ~= "n" or tEnd ~= "n" or tEnd ~= "n" or tStep ~= "n") then
			this:Throw(token, "No such loop 'for(%s i = %s; %s; %s)'.", name(class), name(tStart), name(tEnd), name(tStep));
		end

		price = price + p3;

		this:writeToBuffer(inst, ",");

		this:addInstructionToBuffer(inst, step);
	elseif (class ~= "n" or tStart  ~= "n" or tEnd ~= "n") then
		this:Throw(token, "No such loop 'for(%s i = %s; %s)'.", name(class), name(tStart), name(tEnd));
	end

	this:writeToBuffer(inst, " do\n");

	this:PushScope();
		this:SetOption("loop", true);
		this:AssignVariable(token, true, var, class, nil);

		this:Compile(data.block);
		this:addInstructionToBuffer(inst, data.block);

	this:PopScope();

	this:writeToBuffer(inst, "\nend\n");

	return nil, nil, price;
end

function COMPILER.Compile_WHILE(this, inst, token, data)
	this:writeToBuffer(inst, "\nwhile ");

	local r, c, p = this:Compile(data.condition);
	this:addInstructionToBuffer(inst, data.condition);

	this:writeToBuffer(inst, " do\n");

	this:PushScope();
		this:SetOption("loop", true);
		this:Compile(data.block);
		this:addInstructionToBuffer(inst, data.block);
	this:PopScope();

	this:writeToBuffer(inst, "\nend\n");

	-- Add the price for the conditon to the price of the block,
	-- to ensure that its always accounted for, regardless of step count!
	data.block.price = data.block.price + 1;

	return nil, nil, p;
end

function COMPILER.Compile_EACH(this, inst, token, data)
	local r, c, p = this:Compile(data.expr);
	local op = this:GetOperator("itor", r);

	if not op then
		this:Throw(token, "%s can not be used inside a foreach loop", name(r));
	end

	this:PushScope();
	this:SetOption("loop", true);

	this:writeToBuffer(inst, "for _kt, _kv, _vt, _vv in ");

	this:writeOperationCall(inst, op, data.expr);

	this:writeToBuffer(inst, " do\n");

	this:AssignVariable(token, true, data.vValue, data.vType, nil);

	if data.kType then
		this:AssignVariable(token, true, data.kValue, data.kType,  nil);

		if (data.kType ~= "_vr") then
			this:writeToBuffer(inst, "if (_kt ~= %q) then continue end\n", data.kType);
			this:writeToBuffer(inst, "local %s = _kv\n", data.kValue);
		else
			this:writeToBuffer(inst, "local %s = {_kt, _kv}\n", data.kValue);
		end
	end

	if (data.vType) then
		if (data.vType ~= "_vr") then
			this:writeToBuffer(inst, "if (_vt ~= %q) then continue end\n", data.vType);
			this:writeToBuffer(inst, "local %s = _vv\n", data.vValue);
		else
			this:writeToBuffer(inst, "local %s = {_vt, _vv}\n", data.vValue);
		end
	end

	this:Compile(data.block);

	this:addInstructionToBuffer(inst, data.block);

	this:PopScope();

	this:writeToBuffer(inst, "\nend\n");

	return nil, nil, (op.price + p);
end

--[[

]]

function COMPILER.Compile_TRY(this, inst, token, data)
	this:writeToBuffer(inst, "\nlocal ok, %s = pcall(function()\n", data.var.data);

	this:PushScope();
		this:SetOption("canReturn", false);
		this:SetOption("loop", false);

		this:Compile(data.block1);
		this:addInstructionToBuffer(inst, data.block1);

	this:PopScope();

	this:writeToBuffer(inst, "\nend\n); if (not ok and %s.state == 'runtime') then\n", data.var.data);

	this:PushScope();
		this:SetOption("loop", false);

		this:AssignVariable(token, true, data.var.data, "_er", nil);

		this:Compile(data.block2);
		this:addInstructionToBuffer(inst, data.block2);

	this:PopScope();

	this:writeToBuffer(inst, "\nelseif (not ok) then\nerror(%q, 0);\nend\n", data.var.data);
end

--[[
]]

function COMPILER.Compile_INPORT(this, inst, token, data)
	if (this:GetOption("state") ~= EXPR_SERVER) then
		this:Throw(token, "Wired input('s) must be defined server side.");
	end

	for _, token in pairs(data.variables) do
		local var = token.data;

		if (var[1] ~= string_upper(var[1])) then
			this:Throw(token, "Invalid name for wired input %s, name must be cammel cased");
		end

		local class, scope, info = this:AssignVariable(token, true, var, data.class, 0, "INPUT");

		this.__directives.inport[var] = {class = data.class, wire = data.wire_type, func = data.wire_func};
	end
end

function COMPILER.Compile_OUTPORT(this, inst, token, data)
	if (this:GetOption("state") ~= EXPR_SERVER) then
		this:Throw(token, "Wired output('s) must be defined server side.");
	end

	for _, token in pairs(data.variables) do
		local var = token.data;

		if (var[1] ~= string_upper(var[1])) then
			this:Throw(token, "Invalid name for wired output %s, name must be cammel cased");
		end

		local class, scope, info = this:AssignVariable(token, true, var, data.class, 0, "OUTPUT");

		this.__directives.outport[var] = {class = data.class, wire = data.wire_type, func = data.wire_func, func_in = data.wire_func2};
	end
end

--[[
	Include support: Huge Work In Progress, I will not like this how ever it comes out.
]]

local function Inclucde_ROOT(this, inst, token, data)
	this:writeToBuffer(inst, "\ndo --START INCLUDE\n")

	local price = 0;

	local stmts = data.stmts;

	for i = 1, #stmts do
		local r, c, p = this:Compile(stmts[i]);

		price = price + p;

		this:addInstructionToBuffer(inst, stmts[i]);
	end

	this:writeToBuffer(inst, "\nend --END INCLUDE\n")
	return "", 0, price;
end

function COMPILER.Compile_INCLUDE(this, inst, token, file_path)
	local script;

	if (CLIENT) then
		script = file.Read("golem/" .. file_path .. ".txt", "DATA");
	elseif (SERVER) then
		script = this.__files[file_path];
	end

	local Toker = EXPR_TOKENIZER.New();

	Toker:Initialize("EXPADV", script);

	local ok, res = Toker:Run();

	if ok then
		local Parser = EXPR_PARSER.New();

		Parser:Initialize(res);

		Parser.__directives = this.__directives;

		ok, res = Parser:Run();

		if ok then
			local Compiler = EXPR_COMPILER.New();

			Compiler:Initialize(res);

			Compiler.Compile_ROOT = Inclucde_ROOT;
			Compiler.__directives = this.__directives;

			Compiler.__scope = this.__scope;
			Compiler.__scopeID = this.__scopeID ;
			Compiler.__scopeData = this.__scopeData;
			Compiler.__constructors = this.__constructors;
			Compiler.__operators = this.__operators;
			Compiler.__functions = this.__functions;
			Compiler.__methods = this.__methods;
			Compiler.__enviroment = this.__enviroment;

			ok, res = Compiler:Run();

			if (ok) then
				this:QueueInjectionAfter(inst, token, res.compiled);
			end
		end
	end

	if (not ok) then
		if (istable(res)) then
			res.file = file_path;
		end

		error(res, 0);
	end

end

--[[
]]

function COMPILER.StartClass(this, name)
	local classes = this.__scope.classes;

	local newclass = {name = name, constructors = {}, methods = {}, memory = {}, instances = {}};

	classes[name] = newclass;

	return newclass;
end

function COMPILER.GetUserClass(this, name, scope, nonDeep)
	if (not scope) then
		scope = this.__scopeID;
	end

	local v = this.__scopeData[scope].classes[name];

	if (v) then
		return v, v.scope;
	end

	if (not nonDeep) then
		for i = scope, 0, -1 do
			local v = this.__scopeData[i].classes[name];

			if (v) then
				return v, v.scope;
			end
		end
	end
end

function COMPILER.AssToClass(this, token, declaired, varName, class, scope)
	local class, scope, info = this:AssignVariable(token, declaired, varName, class, scope);
	if (declaired) then
		local userclass = this:GetOption("userclass");
		userclass.memory[varName] = info;
		info.attribute = true;
		info.prefix = "vars";
	end

	return class, scope, info;
end



function COMPILER.Compile_CLASS(this, inst, token, data)
	local extends;

	local classname = data.classname;
	local class = this:StartClass(classname);
	class.hash = this:CRC(inst.start, inst.final);
	this.__hashtable[class.hash] = {[class.hash] = true};

	this:writeToBuffer(inst, "\n--START CLASS (%s, %q)\n", classname, class.hash);

	this:writeToBuffer(inst, "\nlocal %s = {vars = {}; hash = %q};\n", classname, class.hash);

	this:PushScope();

		this:SetOption("userclass", class);

		if (data.extends) then
			extends = this:GetUserClass(data.extends.data);

			if (not extends) then
				this:Throw(token, "Can not extend user class from none user class %s.", data.extends.data);
			end

			class.extends = extends;

			for name, info in pairs(extends.memory) do
				this:AssToClass(token, true, name, info.class);
			end

			for name, info in pairs(extends.constructors) do
				class.constructors[name] = info;
			end

			for name, info in pairs(extends.methods) do
				class.methods[name] = info;
			end

			this.__hashtable[extends.hash][class.hash] = true;
		end

		for i = 1, #data.block do
			local stmt = data.block[i];

			this:Compile(stmt);
			this:addInstructionToBuffer(inst, stmt);
			this:writeToBuffer(inst, "\n");
		end

		if (data.implements) then
			for _, imp in pairs(data.implements) do
				local interface = this:GetInterface(imp.data);

				if (not interface) then
					this:Throw(imp, "No sutch interface %s", imp.data);
				end

				for mName, info in pairs(interface.methods) do
					local overrride = class.methods[mName];

					if (not overrride) then
						this:Throw(token, "Missing method %s(%s) on class %s, for interface %s", info.name, inst.params or "", data.classname, imp.data);
					end

					if (overrride and info.result ~= overrride.result) then
						this:Throw(overrride.token, "Interface method %s(%s) on %s must return %s", info.name, inst.params or "", imp.data, name(info.result));
					end

					if (overrride and info.count ~= overrride.count) then
						this:Throw(overrride.token, "Interface method %s(%s) on %s must return %i values", info.name, inst.params or "", imp.data, info.count);
					end
				end

				this.__hashtable[interface.hash][class.hash] = true;
			end
		end

		if (not extends and not class.valid) then
			this:Throw(token, "Class %s requires at least one constructor.", class.name);
		end

	this:PopScope();

	if (extends) then
		--this:writeToBuffer(inst, "\nsetmetatable(%s, %s);\n", class.name, extends.name);
		--this:writeToBuffer(inst, "\nsetmetatable(%s.vars, %s.vars);\n", class.name, extends.name);

		this:writeToBuffer(inst, "\nsetmetatable(%s, {__index = %s});\n", class.name, extends.name);
		this:writeToBuffer(inst, "\nsetmetatable(%s.vars, {__index = %s.vars});\n", class.name, extends.name);
	end

	this:writeToBuffer(inst, "\n%s.vars.__index = %s.vars;\n", class.name, class.name);

	this:writeToBuffer(inst, "\n--END CLASS (%s, %q)\n", classname, class.hash);

	return "", 0;
end

--[[Notes.
function downCast()
	if from-class is extended from to-class then return to-class
end

function upCast()
	if to-class is extended from from-class then

end
]]


function COMPILER.Compile_FIELD(this, inst, token, data)
	local expr = data.expr;
	local type, count, price = this:Compile(expr);
	local userclass = this:GetUserClass(type);

	local var = data.var.data;

	this:addInstructionToBuffer(inst, expr);

	this:writeToBuffer(inst, ".");

	if (not userclass) then
		-- this:Throw(token, "Unable to reference field %s.%s here", name(type), inst.__field.data);

		local cls = E3Class(type);
		local info = cls.attributes[var];

		if (not info) then
			this:Throw(token, "No sutch attribute %s.%s", name(type), var);
		end

		this:writeToBuffer(inst, info.field or var);

		return info.class, 1;
	end

	local info = userclass.memory[var];

	if (not info) then
		this:Throw(token, "No sutch attribute %s.%s", type, var);
	end

	if (info) then
		this:writeToBuffer(inst, info.prefix);
		this:writeToBuffer(inst, ".");
	end

	this:writeToBuffer(inst, var);

	return info.class, 1, (price + EXPR_MIN);
end

function COMPILER.Compile_DEF_FIELD(this, inst, token, data)
	local tArgs = #data.expressions;
	local userclass = this:GetOption("userclass");

	local price = 0;

	local results = {};

	for i = 1, tArgs do
		local arg = data.expressions[i];
		local r, c, p = this:Compile(arg);

		price = price + p;

		if (not data.variables[i]) then
			this:Throw(arg.token, "Unable to assign here, value #%i has no matching variable.", i);
		elseif (i < tArgs) then
			results[#results + 1] = {r, arg, true};
		else
			for j = 1, c do
				results[#results + 1] = {r, arg, j == 1};
			end
		end
	end

	for i = 1, #data.variables do
		local result = results[i];
		local token = data.variables[i];
		local var = token.data;

		local class, scope, info = this:AssToClass(token, true, var, data.class);

		if (not result) then
			this:Throw(token, "Variable %s is not initalized.", var);
		else
			if (info) then
				this:writeToBuffer(inst,string_format("\n%s.vars.%s", userclass.name, var));
			end

			this.__defined[var] = true;

			local arg = result[2];

			this:AssToClass(arg.token, true, var, result[1]);

			this:writeToBuffer(inst, " = ");

			this:addInstructionToBuffer(inst, arg);

			this:writeToBuffer(inst, ";\n");
		end
	end

	this.__defined = {};

	return "", 0, price;
end

function COMPILER.Compile_SET_FIELD(this, inst, token, data)

	local info;
	local attribute = data.var.data;
	local expressions = data.expressions;
	local r1, c1, p1 = this:Compile(expressions[1]);
	local r2, c2, p2 = this:Compile(expressions[2]);
	local cls = E3Class(r1);

	if (not cls) then
		local userclass = this:GetClassOrInterface(r1);
		info = userclass.memory[attribute];
	else
		info = cls.attributes[attribute];
	end

	if (not info) then
		this:Throw(token, "No sutch attribute %s.%s", name(r1), attribute);
	end

	if (info.class ~= r2) then
		this:Throw( token, "Can not assign attribute %s.%s of type %s with %s", name(r1), attribute, name(info.class), name(r2));
	end

	this:writeToBuffer(inst, "\n");

	this:addInstructionToBuffer(inst, expressions[1]);

	if (not cls) then
		this:writeToBuffer(inst, ".vars.%s = ", attribute);
	elseif (info.field) then
		this:writeToBuffer(inst, ".%s = ", info.field);
	end

	this:addInstructionToBuffer(inst, expressions[2]);

	this:writeToBuffer(inst, ";\n");

	return info.class, 1, (p1 + p2);
end

--[[
]]

function COMPILER.Compile_CONSTCLASS(this, inst, token, data)
	this:PushScope();
	this:SetOption("loop", false);

	local userclass = this:GetOption("userclass");

	this:AssignVariable(token, true, "this", userclass.name);

	local signature = string_format("constructor(%s)", data.signature);

	this:writeToBuffer(inst, "\n%s[%q] = function(", userclass.name, signature);

	local args = data.args;
	local tArgs = #args;

	for i = 1, tArgs do
		local arg = args[i];
		this:writeToBuffer(inst, arg[2]);
		this:AssignVariable(token, true, arg[2], arg[1]);
		if i < tArgs then this:writeToBuffer(inst, ","); end
	end

	this:writeToBuffer(inst, ")\n");

	userclass.valid = true;
	userclass.constructors[signature] = signature;

	this:writeToBuffer(inst, "\nlocal this = setmetatable({vars = setmetatable({}, {__index = %s.vars}), hash = %q}, %s)\n", userclass.name, userclass.hash, userclass.name);

	if data.block then
		this:Compile(data.block);
		this:addInstructionToBuffer(inst, data.block);
	end

	this:PopScope();

	this:writeToBuffer(inst, "\nreturn this;\nend\n");

	return nil, nil, EXPR_LOW;
end

function COMPILER.Compile_SUPCONST(this, inst, token, data)
	local class = this:GetOption("userclass");
	
	if (not class.extends) then
		this:Throw(inst, "class %s does not extend a class", class.name)
	end

	data.class = class.extends.name;

	this:writeToBuffer(inst, "this = ");

	local new = COMPILER.Compile_NEW(this, inst, token, data);

	this:writeToBuffer(inst, "\nthis.hash = %q;", class.hash);

	return new;
end

function COMPILER.Compile_DEF_METHOD(this, inst, token, data)
	this:PushScope();

	local userclass = this:GetOption("userclass");

	local signature = string_format("@%s(%s)", data.var.data, data.signature);

	this:writeToBuffer(inst, "\n%s[%q] = function(this", userclass.name, signature);


	this:AssignVariable(token, true, "this", userclass.name);

	local args = data.args;
	local tArgs = #args;

	if tArgs > 0 then this:writeToBuffer(inst, ","); end

	for i = 1, tArgs do
		local param = args[i];
		this:writeToBuffer(inst, param[2]);
		this:AssignVariable(token, true, param[2], param[1]);
		if i < tArgs then this:writeToBuffer(inst, ","); end
	end

	this:writeToBuffer(inst, ")\n");

	local overrride = userclass.methods[signature];

	local error = string_format("Attempt to call user method '%s.%s(%s)' using alien class of the same name.", userclass.name, data.var.data, data.signature);
	this:writeToBuffer(inst, "if(not CheckHash(%q, this)) then CONTEXT:Throw(%q); end", userclass.hash, error);


	local meth = {};
	meth.signature = signature;
	meth.name = data.var.data;
	meth.result = data.type.data;
	meth.token = token;
	meth.price = 0;
	userclass.methods[signature] = meth;

	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);
	this:SetOption("loop", false);
	this:SetOption("canReturn", true);
	this:SetOption("retunClass", meth.result);
	this:SetOption("retunCount", meth.result ~= "" and -1 or 0);

	local _, __, blockprice = this:Compile(data.block);
	
	meth.price = blockprice;

	this:addInstructionToBuffer(inst, data.block);

	local count = this:GetOption("retunCount");

	this:PopScope();

	if (count == -1) then
		count = 0;
	end

	meth.count = count;

	if (overrride and meth.result ~= overrride.result) then
		this:Throw(token, "Overriding method %s(%s) must return %s", inst.__name.data, inst.signature, name(overrride.result));
	end

	if (overrride and meth.count ~= overrride.count) then
		this:Throw(token, "Overriding method %s(%s) must return %i values", inst.__name.data, inst.signature, overrride.count);
	end

	this:writeToBuffer(inst, "\nend\n");

	return nil, nil, EXPR_LOW;
end

function COMPILER.Compile_TOSTR(this, inst, token, data)
	local userclass = this:GetOption("userclass");

	this:PushScope();
	this:SetOption("loop", false);

	this:AssignVariable(token, true, "this", userclass.name);

	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);
	this:SetOption("canReturn", true);
	this:SetOption("retunClass", "s");
	this:SetOption("retunCount", 1);

	this:writeToBuffer(inst, "\n%s.__tostring = function(this)\n", userclass.name);

	local error = string_format("Attempt to call user operator '%s.tostring()' using alien class of the same name.", userclass.name);
	this:writeToBuffer(inst, "if(not CheckHash(%q, this)) then CONTEXT:Throw(%q); end", userclass.hash, error);

	this:Compile(data.block);
	this:writeToBuffer(inst, data.block)
	this:PopScope();

	this:writeToBuffer(inst, "\nend\n");

	return nil, nil, EXPR_LOW;
end

--[[
]]

function COMPILER.StartInterface(this, name)
	local interfaces = this.__scope.interfaces;

	local newinterfaces = {name = name, methods = {}};

	interfaces[name] = newinterfaces;

	return newinterfaces;
end

function COMPILER.GetInterface(this, name, scope, nonDeep)
	if (not scope) then
		scope = this.__scopeID;
	end

	local v = this.__scopeData[scope].interfaces[name];

	if (v) then
		return v, v.scope;
	end

	if (not nonDeep) then
		for i = scope, 0, -1 do
			local v = this.__scopeData[i].interfaces[name];

			if (v) then
				return v, v.scope;
			end
		end
	end
end

function COMPILER.Compile_INTERFACE(this, inst, token, data)
	local extends;
	local interface = this:StartInterface(data.interface);

	interface.hash = this:CRC(inst.start, inst.final);

	this.__hashtable[interface.hash] = {[interface.hash] = true};

	this:PushScope();

		this:SetOption("interface", interface);

		for i = 1, #data.stmts do
			this:Compile(data.stmts[i]);
			this:addInstructionToBuffer(data.stmts[i])
		end

	this:PopScope();

	return "", 0, EXPR_LOW;
end

function COMPILER.Compile_INTERFACE_METHOD(this, inst, token, data)
	local interface = this:GetOption("interface");

	local meth = {};
	meth.name = data.name.data;
	meth.result = data.result.data;
	meth.params = table_concat(data.params, ",");
	meth.sig = string_format("@%s(%s)", data.name.data, meth.params);
	meth.token = token;

	local count = tonumber(data.count.data);

	if (count == -1) then
		count = 0;
	end

	meth.count = count;

	interface.methods[meth.sig] = meth;

	return nil, nil, EXPR_LOW;
end

function COMPILER.GetClassOrInterface(this, name, scope, nonDeep)
	if (not scope) then
		scope = this.__scopeID;
	end

	local v = this.__scopeData[scope].classes[name] or this.__scopeData[scope].interfaces[name];

	if (v) then
		return v, v.scope;
	end

	if (not nonDeep) then
		for i = scope, 0, -1 do
			local v = this.__scopeData[i].classes[name] or this.__scopeData[i].interfaces[name];

			if (v) then
				return v, v.scope;
			end
		end
	end
end

EXPR_COMPILER = COMPILER;
