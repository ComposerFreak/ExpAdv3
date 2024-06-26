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
local string_find = string.find
local string_upper = string.upper;
local string_format = string.format;

local table_concat = table.concat;
local table_insert = table.insert

local EXPR_CAST_OPERATORS = EXPR_CAST_OPERATORS
local EXPR_OPERATORS = EXPR_OPERATORS
local EXPR_LOW = EXPR_LOW
local EXPR_MIN = EXPR_MIN
local EXPR_SHARED = EXPR_SHARED
local EXPR_SERVER = EXPR_SERVER
local EXPR_CLIENT = EXPR_CLIENT


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

local function strrep(word, count, sep) 
	local a = {};

	for i = 1, count do 
		a[i] = word;
	end

	return table_concat(a, sep);
end

--[[

]]

local function copyInstruction(inst)
	return {
		type = inst.type,
		perfhandler = inst.perfhandler,
		rCount = inst.rCount,
		result = inst.result,
		token = inst.token,
		start = inst.start,
		char = inst.char,
		line = inst.line,
		parent = inst.parent,
		depth = inst.depth,
		scope = inst.scope,
		cur_instruction = inst.cur_instruction,
		__depth = inst.__depth,
		stmt_deph = inst.stmt_deph,
		buffer = inst.buffer,
	};
end

local function fakeInstruction(inst, lua, r, c)
	local new = copyInstruction(inst);

	new.buffer = { lua };
	new.result = r or new.result;
	new.rCount = c or new.rCount;

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

	this.__variables = { };
	this.__defined = {};

	this.__constructors = {};
	this.__operators = {};
	this.__functions = {};
	this.__methods = {};
	this.__enviroment = {};
	this.__hashtable = {};

	this.__files = files;
end

--[[

]]

function COMPILER.Yield(this)

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
	--result.script = this.__script;
	result.constructors = this.__constructors;
	result.operators = this.__operators;
	result.functions = this.__functions;
	result.methods = this.__methods;
	result.enviroment = this.__enviroment;
	result.directives = this.__directives;
	result.hashTable = this.__hashtable;
	result.variables = this.__variables;
	--result.rootInstruction = this.__root;
	
	result.build = function()
		local script, traceTbl = this:BuildScript(this.__root);
		result.compiled = script;
		result.traceTbl = traceTbl;
		return script, traceTbl;
	end
	
	return result;
end

local addNativeLua;

function addNativeLua(this, instruction, outBuffer, traceTable, char, line)
	-- print("\nadding instruction to buffer: ", instruction.type);

	this:Yield();

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
			char, line = addNativeLua(this, value, outBuffer, traceTable, char, line);
		else
			if _type ~= "string" then value = tostring(value); end

			outBuffer[#outBuffer + 1] = value;

			if string_find(value, "\n") then
				local lines = string_Explode("\n", value);

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

	-- print("\nfinished instruction: ", instruction.type);

	return char, line;
end

function COMPILER.BuildScript(this, instruction)
	-- This will probably become a separate stage (post compiler?).
	local outBuffer = {};
	local traceTable = {};
	
	addNativeLua(this, instruction, outBuffer, traceTable, 0, 1);
	
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
	return this.__scopeID;
end

function COMPILER.PopScope(this)
	this.__scopeData[this.__scopeID] = nil;
	this.__scopeID = this.__scopeID - 1;
	this.__scope = this.__scopeData[this.__scopeID];
	return this.__scopeID;
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

function COMPILER.SetVariable(this, token, name, class, scope, prefix, global)
	if (not scope) then
		scope = this.__scopeID;
	end

	local var = {
		used = false,
		name = name,
		token = token,
		class = class,
		scope = scope,
		prefix = prefix,
		global = global
	};

	if not name then debug.Trace(); end

	this.__scopeData[scope].memory[name] = var;
	this.__variables[#this.__variables + 1] = var;

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
	["DELTA"] = true,

	["_OPS"] = true,
	["_CONST"] = true,
	["_METH"] = true,
	["_FUN"] = true,

	["invoke"] = true,
	["assert"] = true,
	["in"] = true,
	["if"] = true,
	["then"] = true,
	["end"] = true,
	["pairs"] = true,
	["unpack"] = true,
	["getdebughook"] = true,
	["setdebughook"] = true,

	["bit"] = true,
	["eTable"] = true,
	["clsname"] = true,
	["CheckHash"] = true,

	["_internala"] = true,
	["_internalb"] = true,
	["_internalc"] = true,
	["_internald"] = true,
	["_internale"] = true,
	["_internalf"] = true,
	["_internalg"] = true,
	["_internalh"] = true,
	["_internali"] = true,
	["_internalj"] = true,
	["_internalk"] = true,
	["_internall"] = true,
	["_internalm"] = true,
	["_internaln"] = true,
	["_internalz"] = true,
};

function COMPILER.AssignVariable(this, token, declaired, varName, class, scope, prefix, global)
	if (not isstring(varName)) or varName == "" then
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
		if (c and (c == class or class ~= "")) then
			if (var.inport) then this:Throw(token, "Unable to declare variable %s, Variable already exists as Wired input.", varName); end
			if (var.outport) then this:Throw(token, "Unable to declare variable %s, Variable already exists as Wired output.", varName); end
			if (var.synced) then this:Throw(token, "Unable to declare variable %s, Variable already exists as Synced variable.", varName); end
			if (var.global) then this:Throw(token, "Unable to declare variable %s, Variable already exists in global space.", varName); end
			this:Throw(token, "Unable to declare variable %s, Variable already exists.", varName);
		else
			return this:SetVariable(token, varName, class, scope, prefix, global);
		end
	else
		if (not c) then
			this:Throw(token, "Unable to assign variable %s, Variable doesn't exist.", varName);
		elseif (c ~= class and class ~= "") then
			this:Throw(token, "Unable to assign variable %s, %s expected got %s.", varName, name(c), name(class));
		
		elseif (var.synced && this:GetOption("state") ~= EXPR_SERVER) then
			if (var.inport) then this:Throw(token, "Unable to assign Wired input %s, Assigment must be server side.", varName); end
			if (var.outport) then this:Throw(token, "Unable to assign Wired output %s, Assigment must be server side.", varName); end
			if (var.global) then this:Throw(token, "Unable to assign synced variable %s, Assigment must be server side.", varName); end
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
	
	local signature = operation .. "(" .. table_concat({fst, snd, ...},",") .. ")";
	
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
	
	this:Yield();
	
	if (not inst) then
		debug.Trace();
		error("Compiler was asked to compile a nil instruction.")
	end
	
	if (not istable(inst.token)) then
		debug.Trace();
		print("token is ", type(inst.token), inst.token);
	end
	
	if (not inst.compiled) then
		if (not inst.buffer) then inst.buffer = {}; end
		
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

function COMPILER.writeOperationCall(this, inst, op, expr1, ...)
	this.__operators[op.signature] = op.operator;

	inst.buffer[#inst.buffer + 1] = "_OPS[\"" .. op.signature .. "\"](";

	if (op.context) then
	    inst.buffer[#inst.buffer + 1] = "CONTEXT";

	    if (expr1) then
	    	inst.buffer[#inst.buffer + 1] = ",";
	    end
	end

	if (expr1) then
		local args = {expr1, ...};
		local tArgs = #args;

		for i = 1, tArgs do
			if (type(args[i]) == "table") then
				inst.buffer[#inst.buffer + 1] = args[i];
			else
				inst.buffer[#inst.buffer + 1] = tostring(args[i]);
			end

			if (i < tArgs) then
				inst.buffer[#inst.buffer + 1] =  ",";
			end
		end
	end

	inst.buffer[#inst.buffer + 1] = ")";
end

function COMPILER.writeArgsToBuffer(this, inst, vargs, ...)
	local args = {...};
	local tArgs = #args;

	for i = 1, tArgs do
		local arg = args[i];

		if istable(arg) then
			local vr = (vargs and i >= vargs) and arg.result ~= "_vr";

			if (vr) then
				inst.buffer[#inst.buffer + 1] = "{\"" .. arg.result .. "\",";
			end

			inst.buffer[#inst.buffer + 1] = arg;

			if (vr) then
				inst.buffer[#inst.buffer + 1] = "}";
			end
		else
			inst.buffer[#inst.buffer + 1] = tostring(arg);
		end

		if (i < tArgs) then
			inst.buffer[#inst.buffer + 1] = ",";
		end
	end
end

function COMPILER.writeMethodCall(this, inst, op, expr1, ...)
	this.__methods[op.signature] = op.operator;

	inst.buffer[#inst.buffer + 1] = "_METH[\"" .. op.signature .. "\"](";

	if (op.context) then
	    inst.buffer[#inst.buffer + 1] = "CONTEXT";

	    if (expr1) then
	    	inst.buffer[#inst.buffer + 1] = ",";
	    end
	end

	if (expr1) then
		this:writeArgsToBuffer(inst, nil, expr1, ...);
	end

	inst.buffer[#inst.buffer + 1] = ")";
end

function COMPILER.writeOperationCall2(this, tbl, inst, op, vargs, expr1, ...)
	local t = istable(op);
	local signature = t and op.signature or op;

	inst.buffer[#inst.buffer + 1] = tbl .. "[\"" .. signature .. "\"](";

	if (t and op.context) then
	    inst.buffer[#inst.buffer + 1] = "CONTEXT";

	    if (expr1) then
	    	inst.buffer[#inst.buffer + 1] = ",";
	    end
	end

	if (expr1) then
		this:writeArgsToBuffer(inst, vargs, expr1, ...);
	end

	inst.buffer[#inst.buffer + 1] = ")";
end

--[[
]]

--[[
]]

function COMPILER.Compile_ROOT(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "\nreturn function(env)\n";
	inst.buffer[#inst.buffer + 1] = "\nsetfenv(1,env)\n";

	if this.__directives.server then
		this:SetOption("state", EXPR_SERVER);
		inst.buffer[#inst.buffer + 1] = "if (SERVER) then\n";
	elseif this.__directives.client then
		this:SetOption("state", EXPR_CLIENT);
		inst.buffer[#inst.buffer + 1] = "if (CLIENT) then\n";
	end

	local stmts = data.stmts;

	if stmts then
		local price = 0;

		for i = 1, #stmts do
			local r, c, p = this:Compile(stmts[i]);
			price = price + p;
		end

		inst.buffer[#inst.buffer + 1] = "\n --PRICE: %i\n", price;
		inst.buffer[#inst.buffer + 1] = "\n CONTEXT:CheckPrice(" .. price .. ")\n";

		for i = 1, #stmts do
			inst.buffer[#inst.buffer + 1] = stmts[i];
		end
	end

	if (this.__directives.server or this.__directives.client) then
		inst.buffer[#inst.buffer + 1] = "\nend\n";
	end

	inst.buffer[#inst.buffer + 1] = "\nend\n";

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

		inst.buffer[#inst.buffer + 1] = "\n --PRICE: %i\n", price;
		inst.buffer[#inst.buffer + 1] = "\n CONTEXT:CheckPrice(" .. price .. ")\n";

		for i = 1, #stmts do
			inst.buffer[#inst.buffer + 1] = stmts[i];
		end

	end

	return "", 0, 0;
end

function COMPILER.Compile_IF(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "if (";

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

	inst.buffer[#inst.buffer + 1] = condition;

	inst.buffer[#inst.buffer + 1] = ") then\n";

	this:PushScope();

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

	this:PopScope();

	local eif = data.eif;

	if (eif and #eif > 0) then
		for i = 1, #eif do
			local stmt = eif[i];
			this:Compile(stmt);
			inst.buffer[#inst.buffer + 1] = stmt;
		end
	end

	inst.buffer[#inst.buffer + 1] = "\nend\n";

	return "", 0;
end

function COMPILER.Compile_ELSEIF(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "\nelseif (";

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

	inst.buffer[#inst.buffer + 1] = condition;

	inst.buffer[#inst.buffer + 1] = ") then\n";

	this:PushScope();

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

	this:PopScope();

	local eif = data.eif;

	if (eif) then
		local _, __, inst4 = this:Compile(eif);

		inst.buffer[#inst.buffer + 1] = inst4;
	end

	return "", 0;
end

function COMPILER.Compile_ELSE(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "\nelse\n";

	this:PushScope();

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

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
		elseif (state == EXPR_CLIENT) then
			this:Throw(token, "%s is client-side only.", msg);
		end
	end

	return false;
end

function COMPILER.Compile_SERVER(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "if (SERVER) then\n";

	if (this:GetOption("state") == EXPR_CLIENT) then
		this:Throw(token, "Server block must not appear inside a Client block.")
	end

	this:PushScope();

	this:SetOption("state", EXPR_SERVER);

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "end\n";

	return "", 0, 1;
end

function COMPILER.Compile_CLIENT(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "if (CLIENT) then\n";

	if (this:GetOption("state") == EXPR_SERVER) then
		this:Throw(token, "Client block must not appear inside a Server block.")
	end

	this:PushScope();

	this:SetOption("state", EXPR_CLIENT);

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "end\n";

	return "", 0, 1;
end

--[[
]]

function COMPILER.Compile_SYNCED(this, inst, token, data)
	if (this:GetOption("state") ~= EXPR_SHARED) then
		this:Throw(token, "Synced Variables must be defined in shared space (server & client side).");
	end

	local tVars = #data.variables;

	local price = 1;

	for i = 1, #data.variables do
		local token = data.variables[i];
		local var = token.data;
		local class, scope, info = this:AssignVariable(token, true, var, data.class, 0, "GLOBAL", true);


		info.global = true;
		info.synced = true;
	
		this.__directives.synced[var] = {class = data.class, synced = true, sync = SERVER and data.sync_sv or data.sync_cl};
	end

	return "", 0, price;
end

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

		inst.buffer[#inst.buffer + 1] = "GLOBAL." .. var;

		if (i < #data.variables) then
			inst.buffer[#inst.buffer + 1] = ",";
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

		info.global = true;
	end

	inst.buffer[#inst.buffer + 1] = "=";

	for i = 1, tArgs do
		inst.buffer[#inst.buffer + 1] = data.expressions[i];

		if (i < tArgs) then
			inst.buffer[#inst.buffer + 1] = ",";
		end
	end

	this.__defined = {};

	inst.buffer[#inst.buffer + 1] = ";\n";

	return "", 0, price;
end

function COMPILER.Compile_LOCAL(this, inst, token, data)
	local tVars = #data.variables;
	local tArgs = #data.expressions;

	local price = 1;
	local results = {};

	inst.buffer[#inst.buffer + 1] = "local";

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

		inst.buffer[#inst.buffer + 1] = var;

		if (i < #data.variables) then
			inst.buffer[#inst.buffer + 1] = ",";
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

	inst.buffer[#inst.buffer + 1] = "=";

	for i = 1, tArgs do
		inst.buffer[#inst.buffer + 1] = data.expressions[i];

		if (i < tArgs) then
			inst.buffer[#inst.buffer + 1] = ",";
		end
	end

	this.__defined = {};

	inst.buffer[#inst.buffer + 1] = "\n";

	return "", 0, price;
end

function COMPILER.Compile_INC(this, inst, token, data)
	
	local class, scope, info = this:GetVariable(data.variable);

	if not class then
		this:Throw(token, "Unable to assign variable %s, Variable doesn't exist.", data.variable);
	end

	info.used = true;

	if class ~= "n" then
		if data.first then
			this:Throw(token, "No such operator ++%s.", name(class));
		else
			this:Throw(token, "No such operator %s.++", name(class));
		end
	end

	inst.buffer[#inst.buffer + 1] = " (function() ";

	if data.first then
		inst.buffer[#inst.buffer + 1] = data.variable .. " = " .. data.variable .. " + 1; return " .. data.variable .. ";";
	else
		inst.buffer[#inst.buffer + 1] = "local _internala = " .. data.variable .. "; " .. data.variable .. " = " .. data.variable .. " + 1; return _internala;";
	end

	inst.buffer[#inst.buffer + 1] = " end)()";

	return "n", 1, EXPR_LOW * 5;
end

function COMPILER.Compile_IND(this, inst, token, data)
	
	local class, scope, info = this:GetVariable(data.variable);

	if not class then
		this:Throw(token, "Unable to assign variable %s, Variable doesn't exist.", data.variable);
	end

	info.used = true;

	if class ~= "n" then
		if data.first then
			this:Throw(token, "No such operator --%s.", name(class));
		else
			this:Throw(token, "No such operator %s--.", name(class));
		end
	end

	inst.buffer[#inst.buffer + 1] = " (function() ";

	if data.first then
		inst.buffer[#inst.buffer + 1] = data.variable .. " = " .. data.variable .. " - 1; return " .. data.variable .. ";";
	else
		inst.buffer[#inst.buffer + 1] = "local _internala = " .. data.variable .. "; " .. data.variable .. " = " .. data.variable .. " - 1; return _internala;";
	end

	inst.buffer[#inst.buffer + 1] = " end)()";

	return "n", 1, EXPR_LOW * 5;
end

function COMPILER.Compile_ASS(this, inst, token, data)
	local price = 1;
	local classes = {};

	inst.buffer[#inst.buffer + 1] = "\n";

	local vars = data.variables;
	local tVars = #vars;

	for i = 1, tVars do
		local var = vars[i].data;

		local class, scope, info = this:GetVariable(var);
		
		if (not class) then
			this:Throw(token, "Unable to assign variable %s, Variable doesn't exist.", var);
		end

		classes[var] = class;

		if info then
			if (info.attribute) then
				inst.buffer[#inst.buffer + 1] = "this.";
			end

			if (info.prefix) then
				inst.buffer[#inst.buffer + 1] = info.prefix .. ".";
			end
		end

		inst.buffer[#inst.buffer + 1] = var;

		if i < tVars then
			inst.buffer[#inst.buffer + 1] = ",";
		end
	end

	inst.buffer[#inst.buffer + 1] = "=";

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

		local class = classes[var.data];

		if (class ~= r and class ~= "") then
			local casted = this:CastExpression(class, arg);

			if (not casted) then
				this:AssignVariable(var, false, var.data, r);
			end

			this:AssignVariable(var, false, var.data, class);
		end

		inst.buffer[#inst.buffer + 1] = arg;

		if i < tVars then inst.buffer[#inst.buffer + 1] = ","; end

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

	inst.buffer[#inst.buffer + 1] = ";\n";

	for i = 1, tVars do
		local var = vars[i].data;

		local class, scope, info = this:GetVariable(var);

		if (data.class == "f") then
			if (info.signature) then
				local msg = "Failed to assign function to delegate " .. var .. "(" .. info.signature .. "), permater missmatch.";
					inst.buffer[#inst.buffer + 1] = "if (" .. var .. " and " .. var .. ".signature ~= \"" .. info.signature .. "\") then CONTEXT:Throw(\"" .. msg .. "\"); " .. var .. " = nil; end\n";
			end

			if (info.resultClass) then
				local msg = "Failed to assign function to delegate " .. var .. "(" .. name(info.resultClass) .. "), result type missmatch.";
				inst.buffer[#inst.buffer + 1] = "if (" .. var .. " and " .. var .. ".result ~= \"" .. name(info.resultClass) .. "\") then CONTEXT:Throw(\"" .. msg .. "\"); " .. var .. " = nil; end\n";
			end

			if (info.resultCount) then
				local msg = "Failed to assign function to delegate " .. var .. "(" .. info.resultCount .. "), result count missmatch.";
				inst.buffer[#inst.buffer + 1] = "if (" .. var .. " and " .. var .. ".count ~= " .. info.resultCount .. ") then CONTEXT:Throw(\"" .. msg .. "\"); " .. var .. " = nil; end\n";
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
			inst.buffer[#inst.buffer + 1] = "\nlocal ";

			for i = k, vt do
				inst.buffer[#inst.buffer + 1] = "__" .. data.variables[i].data;
				if (i < vt) then inst.buffer[#inst.buffer + 1] = ","; end
			end

			inst.buffer[#inst.buffer + 1] = "=";

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";

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

		if (not op and r ~= class) and (this:CastExpression(class, expr)) then
			op = this:GetOperator("add", class, class);
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (+=) does not support '%s += %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (+=)");

		if (not op.operator) then
			if (r == "s" or class == "s") then
				char = "..";
			end

			inst.buffer[#inst.buffer + 1] = var .. " = " .. var .. " " .. char;

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";
		else
			inst.buffer[#inst.buffer + 1] = var .. " = ";

			this:writeOperationCall(inst, op, "var", expr);

			inst.buffer[#inst.buffer + 1] = ";\n";
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
			inst.buffer[#inst.buffer + 1] = "\nlocal ";

			for i = k, vt do
				inst.buffer[#inst.buffer + 1] = "__" .. data.variables[i].data;
				if (i < vt) then inst.buffer[#inst.buffer + 1] = ","; end
			end

			inst.buffer[#inst.buffer + 1] = "=";

			expr.data.call_pred = call_pred;

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";

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

		if (not op and r ~= class) and (this:CastExpression(class, expr)) then
			op = this:GetOperator("sub", class, class);
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (-=) does not support '%s -= %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (-=)");

		if (not op.operator) then
			inst.buffer[#inst.buffer + 1] = var .. " = " .. var .. " -";

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";
		else
			inst.buffer[#inst.buffer + 1] = var .. " = ";

			this:writeOperationCall(inst, op, "var", expr);

			inst.buffer[#inst.buffer + 1] = ";\n";
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
			inst.buffer[#inst.buffer + 1] = "\nlocal ";

			for i = k, vt do
				inst.buffer[#inst.buffer + 1] = "__" .. data.variables[i].data;
				if (i < vt) then inst.buffer[#inst.buffer + 1] = ","; end
			end

			inst.buffer[#inst.buffer + 1] = "=";

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";

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

		if (not op and r ~= class) and (this:CastExpression(class, expr)) then
			op = this:GetOperator("div", class, class);
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (/=) does not support '%s /= %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (/=)");

		if (not op.operator) then
			inst.buffer[#inst.buffer + 1] = var .. " = " .. var .. " /";

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";
		else
			inst.buffer[#inst.buffer + 1] = var .. " = ";

			this:writeOperationCall(inst, op, "var", expr);

			inst.buffer[#inst.buffer + 1] = ";\n";
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
			inst.buffer[#inst.buffer + 1] = "\nlocal ";

			for i = k, vt do
				inst.buffer[#inst.buffer + 1] =  "__" .. data.variables[i].data;
				if (i < vt) then inst.buffer[#inst.buffer + 1] = ","; end
			end

			inst.buffer[#inst.buffer + 1] = "=";

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";

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

		if (not op and r ~= class) and (this:CastExpression(class, expr)) then
			op = this:GetOperator("mul", class, class);
		end

		if (not op) then
			this:Throw(expr.token, "Assignment operator (*=) does not support '%s *= %s'", name(class), name(r));
		end

		this:CheckState(op.state, token, "Assignment operator (*=)");

		if (not op.operator) then
			inst.buffer[#inst.buffer + 1] = var .. " = " .. var .. " *";

			inst.buffer[#inst.buffer + 1] = expr;

			inst.buffer[#inst.buffer + 1] = ";\n";
		else
			inst.buffer[#inst.buffer + 1] = var .. " = ";

			this:writeOperationCall(inst, op, "var", expr);

			inst.buffer[#inst.buffer + 1] = ";\n";
		end

		price = price + op.price;

		this:AssignVariable(token, false, token.data, op.result);
	end

	return nil, nil, price;
end

--[[
]]

function COMPILER.Compile_GROUP(this, inst, token, data)

	inst.buffer[#inst.buffer + 1] = "(";

	local r, c, p = this:Compile(data.expr);

	inst.buffer[#inst.buffer + 1] = data.expr;

	inst.buffer[#inst.buffer + 1] = ")";

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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "and";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = "or";

		inst.buffer[#inst.buffer + 1] = expr3;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "or";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] =  "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "and";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "bit.bxor(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "bit.bor(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "bit.band(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Binary xor operator (&) '%s & %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_EQ_MUL(this, inst, token, data)
	--(function(value) return operations; end)(value)

	inst.buffer[#inst.buffer + 1] = "((function(eq_val) return ";

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
			inst.buffer[#inst.buffer + 1] = "(";

			inst.buffer[#inst.buffer + 1] = "eq_val";

			inst.buffer[#inst.buffer + 1] = "==";

			inst.buffer[#inst.buffer + 1] = expr2;

			inst.buffer[#inst.buffer + 1] = ")";
		else
			this:writeOperationCall(inst, op, "eq_val", expr2);
		end

		price = price + p2 + op.price;

		this:CheckState(op.state, token, "Comparison operator (==) '%s == %s'", name(r1), name(r2));

		if (i < total) then
			inst.buffer[#inst.buffer + 1] = " or ";
		end
	end

	inst.buffer[#inst.buffer + 1] = "; end) (";

	inst.buffer[#inst.buffer + 1] = expr1;

	inst.buffer[#inst.buffer + 1] = "))";

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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "==";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
	else
		this:writeOperationCall(inst, op, expr1, expr2);
	end

	local price = p1 + p2 + op.price;

	this:CheckState(op.state, token, "Comparison operator (==) '%s == %s'", name(r1), name(r2));

	return op.result, op.rCount, price;
end

function COMPILER.Compile_NEQ_MUL(this, inst, token, data)
	--(function(value) return operations; end)(value)

	inst.buffer[#inst.buffer + 1] = "((function(eq_val) return ";

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
			inst.buffer[#inst.buffer + 1] = "(eq_val ~=";

			inst.buffer[#inst.buffer + 1] = expr2;

			inst.buffer[#inst.buffer + 1] = ")";
		else
			this:writeOperationCall(inst, op, "eq_val", expr2);
		end

		price = price + p2 + op.price;

		this:CheckState(op.state, token, "Comparison operator (!=) '%s != %s'", name(r1), name(r2));

		if (i < total) then
			inst.buffer[#inst.buffer + 1] = " and ";
		end
	end

	inst.buffer[#inst.buffer + 1] = "; end) (";

	inst.buffer[#inst.buffer + 1] = expr1;

	inst.buffer[#inst.buffer + 1] = "))";

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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "~=";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "<";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "<=";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = ">";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = ">=";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "bit.lshift(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "bit.rshift(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		if (r1 == "s" or r2 == "s") then
			inst.buffer[#inst.buffer + 1] = "..";
		else
			inst.buffer[#inst.buffer + 1] = "+";
		end

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "-";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "/";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "*";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "^";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "(";

		inst.buffer[#inst.buffer + 1] = expr1;

		inst.buffer[#inst.buffer + 1] = "%";

		inst.buffer[#inst.buffer + 1] = expr2;

		inst.buffer[#inst.buffer + 1] = ")";
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
		inst.buffer[#inst.buffer + 1] = "-";

		inst.buffer[#inst.buffer + 1] = expr1;
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
		inst.buffer[#inst.buffer + 1] = "not";

		inst.buffer[#inst.buffer + 1] = expr1;
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
		inst.buffer[#inst.buffer + 1] = "#";

		inst.buffer[#inst.buffer + 1] = expr1;
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

	info.used = true;

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

	info.used = true;

	if (not info.global) then
		this:Throw(token, "Changed operator (~) can not be used on none global variable %s.", var);
	end

	local op = this:GetOperator("neq", c, c);

	if (not op) then
		this:Throw(token, "Changed operator (~) does not support '~%s'", name(c));
	elseif (not op.operator) then
		
		if (info and info.prefix) then
			inst.buffer[#inst.buffer + 1] = "(DELTA." .. var .. " ~= " .. info.prefix .. "." .. var .. ")";
		else
			inst.buffer[#inst.buffer + 1] = "(DELTA." .. var .. " ~= " .. var .. ")";
		end

	else
		if (info and info.prefix) then
			this:writeOperationCall(inst, op, "DELTA." .. var, info.prefix .. "." .. var);
		else
			this:writeOperationCall(inst, op, "DELTA." .. var, var);
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
			-- local temp = table.Copy(expr); 
			local temp = copyInstruction(expr); -- This might be really bad

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

	inst.buffer[#inst.buffer + 1] = "CheckHash(\"" .. userclass.hash .. "\",";

	inst.buffer[#inst.buffer + 1] = data.expr;

	inst.buffer[#inst.buffer + 1] = ")";

	return "b", 1, EXPR_LOW;
end

function COMPILER.CastUserType(this, left, right)
	local to = this:GetClassOrInterface(left);
	local from = this:GetClassOrInterface(right);

	if left == "_vr" and from then -- To Variant

		return {
			signature = "(_vr)" .. from.hash,
			price = EXPR_LOW,
			context = true,
			result = right,
			rCount = 1,
			operator = function(ctx, obj)
				return { from.hash, obj };
			end,
		};

	end

	if right == "_vr" and to then -- From Varaint
		return {
			signature = "(" .. to.hash .. ")_vr",
			price = EXPR_LOW,
			context = true,
			result = left,
			rCount = 1,
			operator = function(ctx, obj)
				if (not obj or obj[1] ~= to.hash) then
					ctx:Throw("Failed to cast %s to %s, #class missmatched.", name(right), to.name);
				end
			end,
		};
	end

	if not to or not from then
		return;
	end

	if (not this.__hashtable[to.hash][from.hash]) then

		if (this.__hashtable[from.hash][to.hash]) then
			
			return {
				signature = "(" .. to.hash .. ")" .. from.hash,
				price = EXPR_LOW,
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
		local temp = copyInstruction(expr); --This might be bad

		expr.buffer = { temp };
	else
		local signature = "(" .. type .. ")" .. expr.result;

		op = EXPR_CAST_OPERATORS[signature];

		if (not op) then
			return false, expr;
		end

		if (not this:CheckState(op.state)) then
			return false, expr;
		end

		if (op.operator) then
			local temp = copyInstruction(expr); -- This might be bad
			
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

	inst.buffer[#inst.buffer + 1] = expr;

	return expr.result, expr.rCount, expr.price;
end

function COMPILER.Compile_VAR(this, inst, token, data)
	if (this.__defined[inst.variable]) then
		this:Throw(token, "Variable %s is defined here and can not be used as part of an expression.", data.variable);
	end

	local c, s, var = this:GetVariable(data.variable);

	var.used = true;

	if (var) then
		if (var.attribute) then
			inst.buffer[#inst.buffer + 1] = "this.";
		end

		if (var.prefix) then
			inst.buffer[#inst.buffer + 1] = var.prefix .. ".";
		end
	end

	inst.buffer[#inst.buffer + 1] = data.variable;

	if (not c) then
		this:Throw(token, "Variable %s does not exist.", data.variable);
	end

	return c, 1, EXPR_LOW;
end

function COMPILER.Compile_BOOL(this, inst, token, data)
	if data.value then
		inst.buffer[#inst.buffer + 1] = "true";
	else
		inst.buffer[#inst.buffer + 1] = "false";
	end

	return "b", 1, EXPR_MIN;
end

function COMPILER.Compile_NUM(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = data.value;
	return "n", 1, EXPR_MIN;
end

function COMPILER.Compile_STR(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = data.value;
	return "s", 1, EXPR_MIN;
end

function COMPILER.Compile_PTRN(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = data.value;
	return "_ptr", 1, EXPR_MIN;
end

function COMPILER.Compile_CLS(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "\"" .. data.value .. "\"";
	return "_cls", 1, EXPR_MIN;
end

function COMPILER.Compile_VOID(this, inst, token)
	inst.buffer[#inst.buffer + 1] =  "void";
	return "", 1, EXPR_MIN;
end

function COMPILER.Compile_COND(this, inst, token, data)
	local expr = data.expr;
	local r, c, p = this:Compile(expr);

	if (r == "b") then
		inst.buffer[#inst.buffer + 1] = expr;
		return r, c;
	end

	local op = this:GetOperator("is", r);

	if (not op and this:CastExpression("b", expr)) then
		inst.buffer[#inst.buffer + 1] = expr;
		return r, "b", expr.price;
	end

	if (not op) then
		this:Throw(token, "No such condition (%s).", name(r));
	elseif (not op.operator) then
		inst.buffer[#inst.buffer + 1] = expr;
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

	local vargs;
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

			if (k == total) and (c > 1) then
				for i = 2, c do
					ids[#ids + 1] = r;
				end
			end
		end

		for i = #ids, 1, -1 do
			local args = table_concat(ids,",", 1, i);

			if (i >= total) then
				op = constructors[classname .. "(" .. args .. ")"];
			end

			if (not op) then
				op = constructors[classname .. "(" .. args .. ",...)"];
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

	local signature = name(data.class) .. "(" .. names(ids) .. ")";

	if (op and userclass) then
		inst.buffer[#inst.buffer + 1] = cls.name .. "[\"" .. op .. "\"](";

		for k, expr in pairs(data.expressions) do
			inst.buffer[#inst.buffer + 1] = expr;

			if (k < #data.expressions) then
				inst.buffer[#inst.buffer + 1] = ",";
			end
		end

		inst.buffer[#inst.buffer + 1] = ")";

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
		inst.buffer[#inst.buffer + 1] = op.operator;
	else
		error("Attempt to inject " .. op.signature .. " but operator was incorrect " .. type(op.operator) .. ".");
	end

	return op.result, op.rCount, (price + op.price);
end

local function getMethod(mClass, userclass, method, ...)
	local prams = table_concat({...}, ",");

	if (userclass) then
		return userclass.methods["@" .. method .. "(" .. prams .. ")"];
	end

	local op = EXPR_METHODS[mClass .. "." .. method .. "(" .. prams .. ")"];

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
				
				if (k == total) and (c > 1) then
					for i = 2, c do
						ids[#ids + 1] = r;
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
		this:writeMethodCall(inst, op, expr, unpack(expressions, 2));
	elseif (type(op.operator) == "string") then
		inst.buffer[#inst.buffer + 1] =  expr;

		inst.buffer[#inst.buffer + 1] = ":";

		inst.buffer[#inst.buffer + 1] = op.operator .. "(";

		this:writeArgsToBuffer(inst, vargs, unpack(expressions, 2));

		inst.buffer[#inst.buffer + 1] = ")";
	else
		inst.buffer[#inst.buffer + 1] = expressions[1];

		inst.buffer[#inst.buffer + 1] = ":" .. method .. "(";

		this:writeArgsToBuffer(inst, vargs, unpack(expressions, 2));

		inst.buffer[#inst.buffer + 1] = ")";
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

	inst.buffer[#inst.buffer + 1] = op.value;

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

			if (k == total) and (c > 1) then
				for i = 2, c do
					ids[#ids + 1] = r;
				end
			end
		end

		for i = #ids, 1, -1 do
			local args = table_concat(ids,",", 1, i);

			if (i >= total) then
				op = lib._functions[data.name .. "(" .. args .. ")"];
			end

			if (not op) then
				op = lib._functions[data.name .. "(" .. args .. ",...)"];
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
			local signature = data.library.data .. "." .. op.signature;

			if op.context then
				if vargs then vargs = vargs + 1; end
				this:writeOperationCall2("_FUN", inst, signature, vargs, "CONTEXT", unpack(data.expressions));
			else
				this:writeOperationCall2("_FUN", inst, signature, vargs, unpack(data.expressions));
			end

			this.__functions[signature] = op.operator;
		elseif (type(op.operator) == "string") then

			inst.buffer[#inst.buffer + 1] = op.operator .. "(";

			this:writeArgsToBuffer(inst, false, unpack(data.expressions));

			inst.buffer[#inst.buffer + 1] = ")";

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

	inst.buffer[#inst.buffer + 1] = "{op = function(";

	local prf = EXPR_LOW;
	local args = data.params;
	local tArgs = #args;

	for k = 1, tArgs do
		local param = args[k];
		local var = param[2];
		local class = param[1];

		this:AssignVariable(token, true, var, class);

		if (not inst.inTable) then
			inst.buffer[#inst.buffer + 1] = var;

			if (k < tArgs) then
				inst.buffer[#inst.buffer + 1] = ",";
			end
		end
	end

	if (inst.inTable) then
		this:AssignVariable(inst.token, true, "input", "t");
		inst.buffer[#inst.buffer + 1] = "input";
	end

	inst.buffer[#inst.buffer + 1] = ")\n";

	if (inst.inTable) then
		inst.buffer[#inst.buffer + 1] = 
			   "if (input == nil or input[1] == nil) then CONTEXT:Throw(\"table expected for peramater, got void\"); end\n"
			.. "if (input[1] ~= \"t\") then CONTEXT:Throw(\"table expected for peramater, got \" .. clsname(input[1])); end\n"
			.. "input = input[2];\n"
		;
	end

	for k = 1, tArgs do
		local param = args[k];
		local class = param[1];
		local var = param[2];
		local expr = param[3];

		if (inst.inTable) then
			inst.buffer[#inst.buffer + 1] = "local " .. var .. " = input.tbl[\"" .. var .. "\"];\n";
		end

		if (expr) then
			local r, c, p = this:Compile(expr);

			if (r ~= class) then
				this:Throw(expr.token, "Can not default to %s here, %s expected.", name(r), name(class));
			end

			inst.buffer[#inst.buffer + 1] = "if (" .. var .. " == nil or " .. var .. "[1] == nil) then " .. var .. " = ";
			
			if (r ~= "_vr") then inst.buffer[#inst.buffer + 1] = "{\"" .. r .. "\", "; end

			inst.buffer[#inst.buffer + 1] = expr;

			if (r ~= "_vr") then inst.buffer[#inst.buffer + 1] = "}"; end

			inst.buffer[#inst.buffer + 1] = "end\n";

			prf = prf + p;
		end

		if (class ~= "_vr") then
			inst.buffer[#inst.buffer + 1] = 
				   "if (" .. var .. " == nil or " .. var .. "[1] == nil) then CONTEXT:Throw(\"" .. name(class) .. " expected for " .. var .. ", got void\"); end\n"
				.. "if (" .. var .. "[1] ~= \"" .. class .. "\") then CONTEXT:Throw(\"" .. name(class) .. " expected for " .. var .. ", got \" .. clsname(" .. var .. "[1])); end\n"
				.. var .." = " .. var .. "[2];\n"
			;
		end
	end

	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);

	this:SetOption("loop", false);
	this:SetOption("canReturn", true);
	this:SetOption("retunClass", "?"); -- Indicate we do not know this yet.
	this:SetOption("retunCount", -1); -- Indicate we do not know this yet.

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

	local result = this:GetOption("retunClass");
	local count = this:GetOption("retunCount");

	this:PopScope();

	if (result == "?" or count == -1) then
		result = "";
		count = 0;
	end

	inst.buffer[#inst.buffer + 1] = "\nend,\nresult = \"" .. result .. "\", count = " .. count .. ", scr = CONTEXT}";

	return "f", 1, prf;
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

	if (this:GetOption("try", false)) then
		inst.buffer[#inst.buffer + 1] = "\nerror({exit = 'return', values = {";
	else
		inst.buffer[#inst.buffer + 1] = "\nreturn";
	end

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

		inst.buffer[#inst.buffer + 1] = expr;

		if (i < #results) then
			inst.buffer[#inst.buffer + 1] = ",";
		end
	end

	if (this:GetOption("try", false)) then
		inst.buffer[#inst.buffer + 1] = "}, 0)";
	else
		inst.buffer[#inst.buffer + 1] = "\n";
	end

	inst.buffer[#inst.buffer + 1] = ";\n";

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

	if (this:GetOption("try", false)) then
		inst.buffer[#inst.buffer + 1] = "\nerror({exit = 'break'}, 0);\n";
	else
		inst.buffer[#inst.buffer + 1] = "\nbreak\n;";
	end

	return nil, nil, EXPR_MIN;
end

function COMPILER.Compile_CONTINUE(this, inst, token)
	if (not this:GetOption("loop", false)) then
		this:Throw(token, "Continue must not appear outside of a loop");
	end

	if (this:GetOption("try", false)) then
		inst.buffer[#inst.buffer + 1] = "\nerror({exit = 'continue'}, 0);\n";
	else
		inst.buffer[#inst.buffer + 1] = "\ncontinue\n;";
	end

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

	inst.buffer[#inst.buffer + 1] = "\nlocal " .. data.variable .. ";\n";

	return nil, nil, EXPR_MIN;
end

function COMPILER.Compile_FUNCT(this, inst, token, data)
	local variable = data.variable;

	local class, scope, info = this:AssignVariable(token, true, variable, "f");

	if (info and info.prefix) then
		inst.buffer[#inst.buffer + 1] = "local " .. info.prefix .. "." .. variable .. " = {op = function(";
	else
		inst.buffer[#inst.buffer + 1] = "local " .. variable .. " = {op = function(";
	end

	this:PushScope();

	local prf = EXPR_MIN;
	local args = data.params;
	local tArgs = #args;

	for k = 1, tArgs do
		local param = args[k];
		local var = param[2];
		local class = param[1];

		this:AssignVariable(token, true, var, class);
		
		if (not inst.inTable) then
			inst.buffer[#inst.buffer + 1] = var;

			if (k < tArgs) then
				inst.buffer[#inst.buffer + 1] = ",";
			end
		end
	end

	if (inst.inTable) then
		this:AssignVariable(inst.token, true, "input", "t");
		inst.buffer[#inst.buffer + 1] = "input";
	end

	inst.buffer[#inst.buffer + 1] = ")\n";

	if (inst.inTable) then
		inst.buffer[#inst.buffer + 1] = 
			   "if (input == nil or input[1] == nil) then CONTEXT:Throw(\"table expected for peramater, got void\"); end\n"
			.. "if (input[1] ~= \"t\") then CONTEXT:Throw(\"table expected for peramater, got \" .. clsname(input[1])); end\n"
			.. "input = input[2];\n"
		;
	end

	for k = 1, tArgs do
		local param = args[k];
		local class = param[1];
		local var = param[2];
		local expr = param[3];

		if (inst.inTable) then
			inst.buffer[#inst.buffer + 1] = "local " .. var .. " = input.tbl[\"" .. var .. "\"];\n";
		end

		if (expr) then
			local r, c, p = this:Compile(expr);

			if (r ~= class) then
				this:Throw(expr.token, "Can not default to %s here, %s expected.", name(r), name(class));
			end

			inst.buffer[#inst.buffer + 1] = "if (" .. var .. " == nil or " .. var .. "[1] == nil) then " .. var .. " = ";
			
			if (r ~= "_vr") then inst.buffer[#inst.buffer + 1] = "{\"" .. r .. "\", "; end

			inst.buffer[#inst.buffer + 1] = expr;

			if (r ~= "_vr") then inst.buffer[#inst.buffer + 1] = "}"; end

			inst.buffer[#inst.buffer + 1] = "end\n";

			prf = prf + p;
		end

		if (class ~= "_vr") then
			inst.buffer[#inst.buffer + 1] = 
				   "if (" .. var .. " == nil or " .. var .. "[1] == nil) then CONTEXT:Throw(\"" .. name(class) .. " expected for " .. var .. ", got void\"); end\n"
				.. "if (" .. var .. "[1] ~= \"" .. class .. "\") then CONTEXT:Throw(\"" .. name(class) .. " expected for " .. var .. ", got \" .. clsname(" .. var .. "[1])); end\n"
				.. var .. " = " .. var .. "[2];\n"
			;
		end
	end

	this:SetOption("loop", false);
	this:SetOption("udf", (this:GetOption("udf") or 0) + 1);
	this:SetOption("canReturn", true);
	this:SetOption("retunClass", data.resultClass or "");
	this:SetOption("retunCount", -1); -- Indicate we do not know this yet.

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

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

	inst.buffer[#inst.buffer + 1] = "\nend,\nresult = \"" .. data.resultClass .. "\", count = " .. count .. ", scr = CONTEXT};\n";

	return nil, nil, prf;
end

--[[
]]


function COMPILER.getAssigmentPrediction(this, inst, data)
	local parent = inst.parent;
	local resultClass, resultCount;
	
	if (parent and parent.data) and (parent.data.variables) then 
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
	
	return resultClass, resultCount;
end


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
	local resultClass, resultCount = this:getAssigmentPrediction(inst, data);
	
	if (res == "f") then

		local c, s, info;

		if (expr.type == "var") then
			c, s, info = this:GetVariable(expr.data.variable);
			-- The var instruction will have already validated this variable.

			info.used = true;
			
			if (info and info.signature) then
				resultClass = info.resultClass;
				resultCount = info.resultCount;
			end
		end

		if (resultClass and resultCount) then

			inst.buffer[#inst.buffer + 1] = "invoke(CONTEXT, \"" .. resultClass .. "\", " .. resultCount .. ",";

			if info and info.signature and info.signature ~= signature then
				this:Throw(token, "Invalid arguments to user function got %s(%s), %s(%s) expected.", expr.data.variable, names(signature), expr.data.variable, names(info.signature));
			end

			inst.buffer[#inst.buffer + 1] = expr;

			if (tArgs > 1) then

				inst.buffer[#inst.buffer + 1] = ",";

				for i = 2, tArgs do
					local arg = args[i];
					local vr = arg.result ~= "_vr";

					if (vr) then
						inst.buffer[#inst.buffer + 1] = "{\"" .. arg.result .. "\",";
					end

					inst.buffer[#inst.buffer + 1] = arg;

					if (vr) then
						inst.buffer[#inst.buffer + 1] = "}";
					end

					if (i < tArgs) then
						inst.buffer[#inst.buffer + 1] = ",";
					end
				end
			end

			inst.buffer[#inst.buffer + 1] = ")";
			
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

	local keepid = false;
	local class = data.class;

	local op;
	local op_result = "";
	local op_count = 0;

	if not class then
		class = this:getAssigmentPrediction(inst, data);
	end

	local userclass = this:GetClassOrInterface(class);

	if userclass then
		inst.buffer[#inst.buffer + 1] = "eTable.get(CONTEXT,";

		inst.buffer[#inst.buffer + 1] = value;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = index;

		inst.buffer[#inst.buffer + 1] = ",\"" .. userclass.hash .. "\")";

		return class, 1, EXPR_LOW;
	end

	if class then
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
	end

	if (not op) and not data.class then
		op = this:GetOperator("get", vType, iType);

		if (not op) then
			this:Throw(token, "No such get operation %s[%s]", name(vType), name(iType));
		end

		op_result = op.result;
		op_count = op.rCount;
	end

	if (not op) then
		if cls then
			this:Throw(token, "No such get operation %s[%s,%s]", name(vType), name(iType), name(class));
		else
			this:Throw(token, "No such get operation %s[%s]", name(vType), name(iType));
		end
	end

	this:CheckState(op.state);

	if (not op.operator) then
		inst.buffer[#inst.buffer + 1] = value;

		inst.buffer[#inst.buffer + 1] = "[";

		inst.buffer[#inst.buffer + 1] = index;

		inst.buffer[#inst.buffer + 1] = "]";

		return op_result, op_count, (op.price + vPrice + iPrice);
	end

	if (keepid) then
		this:writeOperationCall(inst, op, value, index, "\"" .. class .. "\"");
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

	local keepclass = false;
	local cls = data.class;

	if (cls and vExpr ~= cls) then
		this:Throw(token, "Can not assign %s onto %s, %s expected.", name(vExpr), name(vType), name(cls.data));
	end

	if (not cls) then
		cls = vExpr;
	end

	local userclass = this:GetClassOrInterface(cls);

	if userclass then
		inst.buffer[#inst.buffer + 1] = "eTable.set(CONTEXT,";

		inst.buffer[#inst.buffer + 1] = value;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = index;

		inst.buffer[#inst.buffer + 1] = ",\"" .. userclass.hash .. "\",";

		inst.buffer[#inst.buffer + 1] = vExpr;

		inst.buffer[#inst.buffer + 1] = ");\n";

		return nil, nil, EXPR_LOW;
	end

	local op = this:GetOperator("set", vType, iType, cls);

	if (not op) then
		keepclass = true;
		
		op = this:GetOperator("set", vType, iType, "_cls", vExpr)
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
		inst.buffer[#inst.buffer + 1] = value;

		inst.buffer[#inst.buffer + 1] = "[";

		inst.buffer[#inst.buffer + 1] = index;

		inst.buffer[#inst.buffer + 1] = "] = ";

		inst.buffer[#inst.buffer + 1] = expr;

		inst.buffer[#inst.buffer + 1] = ";\n";

		return op.result, op.rCount, (op.price + p1 + p2 + p3);
	end

	if (keepclass) then
		this:writeOperationCall(inst, op, value, index, "\"" .. cls .. "\"", expr);
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
	inst.buffer[#inst.buffer + 1] = "\nfor " .. var .. " = ";

	local start = expressions[1];
	local tStart, cStart, p1 = this:Compile(start);
	inst.buffer[#inst.buffer + 1] = start;

	inst.buffer[#inst.buffer + 1] = ",";

	local _end = expressions[2];
	local tEnd, cEnd, p2 = this:Compile(_end);
	inst.buffer[#inst.buffer + 1] = _end;

	local price = p1 + p2;
	local step = expressions[3];

	if (step) then
		local tStep, cStep, p3 = this:Compile(step);

		if (class ~= "n" or tStart  ~= "n" or tEnd ~= "n" or tEnd ~= "n" or tStep ~= "n") then
			this:Throw(token, "No such loop 'for(%s i = %s; %s; %s)'.", name(class), name(tStart), name(tEnd), name(tStep));
		end

		price = price + p3;

		inst.buffer[#inst.buffer + 1] = ",";

		inst.buffer[#inst.buffer + 1] = step;
	elseif (class ~= "n" or tStart  ~= "n" or tEnd ~= "n") then
		this:Throw(token, "No such loop 'for(%s i = %s; %s)'.", name(class), name(tStart), name(tEnd));
	end

	inst.buffer[#inst.buffer + 1] = " do\n";

	this:PushScope();
		this:SetOption("loop", true);
		this:AssignVariable(token, true, var, class, nil);

		this:Compile(data.block);
		inst.buffer[#inst.buffer + 1] = data.block;

	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "\nend\n";

	return nil, nil, price;
end

function COMPILER.Compile_WHILE(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "\nwhile ";

	local r, c, p = this:Compile(data.condition);

	inst.buffer[#inst.buffer + 1] = data.condition;

	inst.buffer[#inst.buffer + 1] = " do\n";

	this:PushScope();
		this:SetOption("loop", true);

		this:Compile(data.block);

		inst.buffer[#inst.buffer + 1] = data.block;
	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "\nend\n";

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

	local scope = this:PushScope();

	this:SetOption("loop", true);

	inst.buffer[#inst.buffer + 1] = "for _internale" .. scope .. ", _internalf" .. scope .. ", _internalg" .. scope .. ", _internali" .. scope .. " in ";

	this:writeOperationCall(inst, op, data.expr);

	inst.buffer[#inst.buffer + 1] = " do\n";

	this:AssignVariable(token, true, data.vValue, data.vType, nil);
	
	if data.kType then
		this:AssignVariable(token, true, data.kValue, data.kType,  nil);

		if (data.kType ~= "_vr") then
			inst.buffer[#inst.buffer + 1] = 
				   "if (_internale" .. scope .. " ~= \"" .. data.kType .. "\") then continue end\n"
				.. "local " .. data.kValue .. " = _internalf" .. scope .. "\n"
			;
		else
			inst.buffer[#inst.buffer + 1] = "local " .. data.kValue .. " = {_internale" .. scope .. ", _internalf" .. scope .. "}\n";
		end
	end

	if (data.vType) then
		if (data.vType ~= "_vr") then
			inst.buffer[#inst.buffer + 1] = 
				   "if (_internalg" .. scope .. " ~= \"" .. data.vType .. "\") then continue end\n"
				.. "local " .. data.vValue .. " = _internali" .. scope .. "\n"
			;
		else
			inst.buffer[#inst.buffer + 1] = "local " .. data.vValue .. " = {_internalg" .. scope .. ", _internali" .. scope .. "}\n";
		end
	end

	this:Compile(data.block);

	inst.buffer[#inst.buffer + 1] = data.block;

	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "\nend\n";

	return nil, nil, (op.price + p);
end

--[[

]]

function COMPILER.Compile_TRY(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = 
		   "\nlocal _internala, _internalb, _internalc, _internald = getdebughook();\n"
		.. "\nlocal _internalz, " .. data.var.data .. " = pcall(function()\n"
		.. "\nsetdebughook(_internala, _internalb, _internalc, _internald);\n"
	;

	this:PushScope();

		this:SetOption("try", true);

		this:Compile(data.block1);
		inst.buffer[#inst.buffer + 1] = data.block1;

	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "\nend\n);";

	inst.buffer[#inst.buffer + 1] = "if (not _internalz and " .. data.var.data .. ".exit) then\n";
		
		if this:GetOption("loop", false) then
			inst.buffer[#inst.buffer + 1] = 
				   "if (" .. data.var.data .. ".exit == \"break\") then break; end\n"
				.. "if (" .. data.var.data .. ".exit == \"continue\") then continue; end\n"
			;
		end

		if this:GetOption("canReturn", false) then
			inst.buffer[#inst.buffer + 1] = "if (" .. data.var.data .. ".exit == 'return') then return unpack(" .. data.var.data .. ".values); end\n";
		end

		inst.buffer[#inst.buffer + 1] = "error(" .. data.var.data .. ", 0);\n";

		inst.buffer[#inst.buffer + 1] = "elseif (not _internalz and " .. data.var.data .. ".state == 'runtime') then\n";

	this:PushScope();
		this:SetOption("catch", true);

		this:AssignVariable(token, true, data.var.data, "_er", nil);

		this:Compile(data.block2);
		inst.buffer[#inst.buffer + 1] = data.block2;

	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "\nelseif (not _internalz) then\nerror(" .. data.var.data .. ", 0);\nend\n";
end

--[[
]]

function COMPILER.Compile_INPORT(this, inst, token, data)
	local shared = this:GetOption("state") == EXPR_SHARED;
	
	if (this:GetOption("state") == EXPR_CLIENT) then
		this:Throw(token, "Wired input('s) can not be defined client side.");
	end

	if (this:GetOption("state") ~= EXPR_SERVER) then
		if (not data.sync_sv or not data.sync_cl) then
			this:Throw(token, "Wired input('s) of type %s must be defined server side.", name(data.class));
		end
	end

	for _, token in pairs(data.variables) do
		local var = token.data;

		if (var[1] ~= string_upper(var[1])) then
			this:Throw(token, "Invalid name for wired input %s, name must be cammel cased");
		end

		local class, scope, info = this:AssignVariable(token, true, var, data.class, 0, "INPUT");
		
		info.inport = true;
		info.synced = shared;

		this.__directives.inport[var] = {class = data.class, wire = data.wire_type, func = data.wire_func, synced = shared, sync = SERVER and data.sync_sv or data.sync_cl};
	end
end

function COMPILER.Compile_OUTPORT(this, inst, token, data)
	local shared = this:GetOption("state") == EXPR_SHARED;

	if (this:GetOption("state") == EXPR_CLIENT) then
		this:Throw(token, "Wired output('s) can not be defined client side.");
	end

	if (this:GetOption("state") ~= EXPR_SERVER) then
		if (not data.sync_sv or not data.sync_cl) then
			this:Throw(token, "Wired output('s) of type %s must be defined server side.", name(data.class));
		end
	end

	for _, token in pairs(data.variables) do
		local var = token.data;

		if (var[1] ~= string_upper(var[1])) then
			this:Throw(token, "Invalid name for wired output %s, name must be cammel cased");
		end

		local class, scope, info = this:AssignVariable(token, true, var, data.class, 0, "OUTPUT");

		info.outport = true;
		info.synced = shared;

		this.__directives.outport[var] = {class = data.class, wire = data.wire_type, func = data.wire_func, func_in = data.wire_func2, synced = shared, sync = SERVER and data.sync_sv or data.sync_cl};
	end
end

--[[
	Include support: Huge Work In Progress, I will not like this how ever it comes out.
]]

local function Inclucde_ROOT(this, inst, token, data)
	inst.buffer[#inst.buffer + 1] = "\ndo --START INCLUDE\n";

	local price = 0;

	local stmts = data.stmts;

	for i = 1, #stmts do
		local r, c, p = this:Compile(stmts[i]);

		price = price + p;

		inst.buffer[#inst.buffer + 1] = stmts[i];
	end

	inst.buffer[#inst.buffer + 1] = "\nend --END INCLUDE\n";
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
	
	Toker.__file = file_path;

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

	inst.buffer[#inst.buffer + 1] = "\n--START CLASS (" .. classname .. ", \"" .. class.hash .. "\")\n";

	inst.buffer[#inst.buffer + 1] = "\nlocal " .. classname .. " = {vars = {}; hash = \"" .. class.hash .. "\"};\n";

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

			inst.buffer[#inst.buffer + 1] = stmt;

			inst.buffer[#inst.buffer + 1] = "\n";
		end

		if (data.implements) then
			for _, imp in pairs(data.implements) do
				local interface = this:GetInterface(imp.data);

				if (not interface) then
					this:Throw(imp, "No such interface %s", imp.data);
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
		inst.buffer[#inst.buffer + 1] = 
			   "\nsetmetatable(" .. class.name .. ", {__index = " .. extends.name .. "});\n"
			.. "\nsetmetatable(" .. class.name ..".vars, {__index = " .. extends.name .. ".vars});\n"
		;
	end

	inst.buffer[#inst.buffer + 1] = 
		   "\n" .. class.name .. ".vars.__index = " .. class.name .. ".vars;\n"
		.. "\n--END CLASS (" .. class.name .. ", \"" .. class.hash .. "\")\n"
	;

	return "", 0;
end

--[[Notes:
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

	inst.buffer[#inst.buffer + 1] = expr;

	inst.buffer[#inst.buffer + 1] = ".";

	if (not userclass) then
		-- this:Throw(token, "Unable to reference field %s.%s here", name(type), inst.__field.data);

		local cls = E3Class(type);
		local info = cls.attributes[var];

		if (not info) then
			this:Throw(token, "No such attribute %s.%s", name(type), var);
		end

		inst.buffer[#inst.buffer + 1] = info.field or var;

		return info.class, 1;
	end

	local info = userclass.memory[var];

	if (not info) then
		this:Throw(token, "No such attribute %s.%s", type, var);
	end

	if (info) then
		inst.buffer[#inst.buffer + 1] = info.prefix .. ".";
	end

	inst.buffer[#inst.buffer + 1] = var;

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
				inst.buffer[#inst.buffer + 1] = "\n" .. userclass.name .. ".vars." .. var;
			end

			this.__defined[var] = true;

			local arg = result[2];

			this:AssToClass(arg.token, true, var, result[1]);

			inst.buffer[#inst.buffer + 1] = " = ";

			inst.buffer[#inst.buffer + 1] = arg;

			inst.buffer[#inst.buffer + 1] = ";\n";
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
		this:Throw(token, "No such attribute %s.%s", name(r1), attribute);
	end

	if (info.class ~= r2) then
		this:Throw( token, "Can not assign attribute %s.%s of type %s with %s", name(r1), attribute, name(info.class), name(r2));
	end

	inst.buffer[#inst.buffer + 1] = "\n";

	inst.buffer[#inst.buffer + 1] = expressions[1];

	if (not cls) then
		inst.buffer[#inst.buffer + 1] = ".vars." .. attribute .. " = ";
	elseif (info.field) then
		inst.buffer[#inst.buffer + 1] = "." .. info.field .. " = ";
	end

	inst.buffer[#inst.buffer + 1] = expressions[2];

	inst.buffer[#inst.buffer + 1] = ";\n";

	return info.class, 1, (p1 + p2);
end

--[[
]]

function COMPILER.Compile_CONSTCLASS(this, inst, token, data)
	this:PushScope();
	this:SetOption("loop", false);

	local userclass = this:GetOption("userclass");

	this:AssignVariable(token, true, "this", userclass.name);

	local signature = "constructor(" .. data.signature .. ")";

	inst.buffer[#inst.buffer + 1] = "\n" .. userclass.name .. "[\"" .. signature .. "\"] = function(";

	local args = data.args;
	local tArgs = #args;

	for i = 1, tArgs do
		local arg = args[i];
		inst.buffer[#inst.buffer + 1] = arg[2];

		this:AssignVariable(token, true, arg[2], arg[1]);

		if i < tArgs then inst.buffer[#inst.buffer + 1] = ","; end
	end

	inst.buffer[#inst.buffer + 1] = ")\n";

	userclass.valid = true;
	userclass.constructors[signature] = signature;

	inst.buffer[#inst.buffer + 1] = "\nlocal this = setmetatable({vars = setmetatable({}, {__index = " .. userclass.name .. ".vars}), hash = \"" .. userclass.hash .. "\"}, " .. userclass.name .. ")\n";

	if data.block then
		this:Compile(data.block);
		inst.buffer[#inst.buffer + 1] = data.block;
	end

	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "\nreturn this;\nend\n";

	return nil, nil, EXPR_LOW;
end

function COMPILER.Compile_SUPCONST(this, inst, token, data)
	local class = this:GetOption("userclass");
	
	if (not class.extends) then
		this:Throw(inst, "class %s does not extend a class", class.name)
	end

	data.class = class.extends.name;

	inst.buffer[#inst.buffer + 1] = "this = ";

	local new = COMPILER.Compile_NEW(this, inst, token, data);

	inst.buffer[#inst.buffer + 1] = "\nthis.hash = \"" .. class.hash .. "\";";

	return new;
end

function COMPILER.Compile_DEF_METHOD(this, inst, token, data)
	this:PushScope();

	local userclass = this:GetOption("userclass");

	local signature = "@" .. data.var.data .. "(" .. data.signature .. ")";

	inst.buffer[#inst.buffer + 1] = "\n" .. userclass.name .. "[\"" .. signature .. "\"] = function(this";


	this:AssignVariable(token, true, "this", userclass.name);

	local args = data.args;
	local tArgs = #args;

	if tArgs > 0 then inst.buffer[#inst.buffer + 1] = ","; end

	for i = 1, tArgs do
		local param = args[i];

		inst.buffer[#inst.buffer + 1] = param[2];

		this:AssignVariable(token, true, param[2], param[1]);

		if i < tArgs then inst.buffer[#inst.buffer + 1] = ","; end
	end

	inst.buffer[#inst.buffer + 1] = ")\n";

	local overrride = userclass.methods[signature];

	local error = "Attempt to call user method '" .. userclass.name .. "." .. data.var.data .. "(" .. data.signature .. ")' using alien class of the same name.";
	inst.buffer[#inst.buffer + 1] = "if(not CheckHash(\"" .. userclass.hash .. "\", this)) then CONTEXT:Throw(\"" .. error .. "\"); end";


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

	inst.buffer[#inst.buffer + 1] = data.block;

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

	inst.buffer[#inst.buffer + 1] = "\nend\n";

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

	inst.buffer[#inst.buffer + 1] = "\n" .. userclass.name .. ".__tostring = function(this)\n";

	local error = "Attempt to call user operator '" .. userclass.name .. ".tostring()' using alien class of the same name.";
	inst.buffer[#inst.buffer + 1] = "if(not CheckHash(\"" .. userclass.hash .. "\", this)) then CONTEXT:Throw(\"" .. error .. "\"); end";

	this:Compile(data.block);
	inst.buffer[#inst.buffer + 1] = data.block;
	this:PopScope();

	inst.buffer[#inst.buffer + 1] = "\nend\n";

	return nil, nil, EXPR_LOW;
end


--Zero = {tbl = {}, children = {}, parents = {}, size = 0};
function COMPILER.Compile_INTABLE(this, inst, token, data)

	this:PushScope();

	local size = 0;
	local price = EXPR_LOW;
	local values = data.values;

	inst.buffer[#inst.buffer + 1] = "{\ntbl = {\n";

	for i = 1, #values do
		local info = values[i];

		local kr, kc, kp = this:Compile(info.expr1);
		local vr, vc, vp = this:Compile(info.expr2);
		price = price + kp + vp;
		size = size + 1;

		inst.buffer[#inst.buffer + 1] = "[";
		inst.buffer[#inst.buffer + 1] = info.expr1;
		inst.buffer[#inst.buffer + 1] = "] = ";

		if vr == "_vr" then
			inst.buffer[#inst.buffer + 1] = info.expr2;
		else
			inst.buffer[#inst.buffer + 1] = "{\"" .. vr .. "\",";
			inst.buffer[#inst.buffer + 1] = info.expr2;
			inst.buffer[#inst.buffer + 1] = "},\n";
		end
	end
	
	inst.buffer[#inst.buffer + 1] = "},\nchildren = { },\nparents = { },\nsize = " .. size .. ",\n}\n";

	return "t", 1, price;
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
			inst.buffer[#inst.buffer + 1] = data.stmts[i];
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
	meth.sig = "@" .. data.name.data .. "(" .. meth.params .. ")";
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
