--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Expression Advanced 3 Library::
	`````````````````````````````````
]]

EXPR_LIB = {};

--[[
]]

function EXPR_LIB.ThrowInternal(level, msg, fst, ...)
	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	error(level, msg);
end

--[[
]]

local classes;
local classIDs;
local loadClasses = false;

function EXPR_LIB.RegisterClass(id, name, isType, isValid)
	if (not loadClasses) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register class %s outside of Hook::Expression3.LoadClasses", name);
	end

	if (classIDs[id]) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register class %s with conflicting id %s", name, id);
	end

	local class = {};

	if (type(name) == "table") then
		-- Register aliases for classes.
		for _, v in pairs(name) do
			classes[string.lower(v)] = class;
		end

		name = name[1];
	end

	class.id = string.lower(id);
	class.name = string.lower(name);

	class.isType = isType;
	class.isValid = isValid;
	
	class.constructors = {};

	classIDs[class.id] = class;
	classes[class.name] = class;
end

local loadConstructors = false;

function EXPR_LIB.RegisterConstructor(class, peramaters, constructor)
	if (not loadConstructors) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor new %s(%s) outside of Hook::Expression3.LoadConstructors", class, peramaters);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor new %s(%s) for none existing class", class, peramaters);
	end

	local state, signature = EXPR_LIB.ProcessPeramaters(peramaters);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for Constructor new %s(%s)", signature, class, peramaters);
	end

	cls.constructors[signature] = constructor;
end

local methods;
local loadMethods = false;

function EXPR_LIB.RegisterMethod(class, name, peramaters, type, count, method)
	-- if method is nil lua, compiler will use native Object:(...);

	if (not loadMethods) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s:%s(%s) outside of Hook::Expression3.LoadMethods", class, name, peramaters);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s:%s(%s) for none existing class %s", class, name, peramaters, class);
	end

	local state, signature = EXPR_LIB.ProcessPeramaters(peramaters);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for method %s:%s(%s)", signature, class, name, peramaters);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s:%s(%s) with none existing return class %s", class, name, peramaters, type);
	end

	local meth = {};
	meth.name = name;
	meth.class = cls.id;
	meth.peramaters = signature;
	meth.signature = string.format("%s:%s(%s)", cls.id, name, signature);
	meth.type = res.id;
	meth.count = count;
	meth.operation = method;

	methods[meth.signature] = meth;
	-- <Insert Heisenburg joke here>
end

local operators;
local loadOperators = false;

function EXPR_LIB.RegisterOperator(operation, peramaters, type, count, operator)
	-- if operator is nil lua, compiler will use native if possible (+, -, /, *, ^, etc)

	if (not loadOperators) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register operator %s(%s) outside of Hook::Expression3.LoadOperators", operation, peramaters);
	end

	local state, signature = EXPR_LIB.ProcessPeramaters(peramaters);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for operator %s(%s)", signature, operation, peramaters);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register operator %s(%s) with none existing return class %s", operation, peramaters, type);
	end

	local op = {};
	op.name = operation;
	op.class = cls.id;
	op.peramaters = signature;
	op.signature = string.format("%s(%s)", operation, signature);
	op.type = res.id;
	op.count = count;
	op.operation = operator;

	operators[op.signature] = op;
end

local castOperators;

function EXPR_LIB.RegisterCastingOperator(type, parameter, operator)
	if (not loadOperators) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register casting operator [(%s) %s] outside of Hook::Expression3.LoadOperators", type, parameter);
	end

	if (not operator) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register native casting operator [(%s) %s] an operation function is required.", type, parameter);
	end

	local state, signature = EXPR_LIB.ProcessPeramaters(peramaters);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for casting operator [(%s) %s]", signature, type, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register casting operator [(%s) %s] for none existing class %s", type, parameter, type);
	end

	local op = {};
	op.peramaters = signature;
	op.signature = string.format("(%s)%s", type, signature);
	op.type = res.id;
	op.count = 1;
	op.operation = operator;

	castOperators[op.signature] = op;
end

local librarys;
local loadLibraries = false;

function EXPR_LIB.RegisterLibrary(name)
	if (not loadLibraries) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register library %s) outside of Hook::Expression3.LoadLibariess", name);
	end

	local lib = {};
	lib.name = string.lower(name);
	lib._functions = {};
	lib.constants = {}; -- Future implimentation.

	librarys[lib.name] = lib;
end

local functions;
local loadFunctions = false;

function EXPR_LIB.RegisterFunction(library, name, peramaters, type, count, _function)
	-- If _function is a string then lua will use str(...) e.g; string.Replace
	if (not loadFunctions) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) outside of Hook::Expression3.LoadFunctions", library, name, peramaters);
	end

	local lib = libraries[string.lower(library)];

	if (not lib) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) to none existing library %s", library, name, peramaters, library);
	end

	local state, signature = EXPR_LIB.ProcessPeramaters(peramaters);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for function %s.%s(%s)", signature, library, name, peramaters);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) with none existing return class %s", library, name, peramaters, type);
	end

	local op = {};
	op.name = name;
	op.peramaters = signature;
	op.signature = string.format("%s(%s)", name, signature);
	op.type = res.id;
	op.count = count;
	op.operation = operator;

	operators[op.signature] = op;
end

local events;
local loadEvents = false;

function EXPR_LIB.RegisterEvent(name, peramaters, type, count)
	if (not loadEvents) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register event %s(%s) outside of Hook::Expression3.LoadEvents", name, peramaters);
	end

	local state, signature = EXPR_LIB.ProcessPeramaters(peramaters);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for function %s.%s(%s)", signature, library, name, peramaters);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) with none existing return class %s", library, name, peramaters, type);
	end

	local evt = {};
	evt.name = name;
	evt.peramaters = signature;
	evt.signature = string.format("%s(%s)", name, signature);
	evt.type = res.id;
	evt.count = count;

	events[evt.signature] = evt;
end

--[[
]]


function EXPR_LIB.GetClass(class)
	return classes[class] or classIDs[class];
end

function EXPR_LIB.IsValidClass(class)
	return (classes[class] or classIDs[class]) ~= nil;
end

function EXPR_LIB.ProcessPeramaters(peramaters)
	if (peramaters == "") then
		return true, "";
	end

	local varg = false;
	local signature = {};
	local split = string.Explode(",", peramaters);

	if (split[#split] == "...") then
		split[#split] = nil;
		varg = true;
	end

	for k, v in pairs(split) do
		local cls = classes[v] or classIDs[v];

		if (v == "...") then
			return false, string.format("Vararg (...) must be last parameter", v, k);
		elseif (not cls) then
			return false, string.format("Invalid class (%s) for parameter #%i", v, k);
		end

		signature[k] = cls.id;
	end

	if (varg) then
		signature[#signature] = "...";
	end

	return true, table.concat(signature, ","), varg;
end

--[[
	:::Extension Base For Loading Sainly:::
	'''''''''''''''''''''''''''''''''''''''
	Since we need to add everything in a specific order, this is a extention base that can do this for you.
]]

local EXTENTION = {};
EXTENTION.__index = EXTENTION;

function EXPR_LIB.RegisterExtension(name)
	local ext = {};

	ext.name = name;
	ext.classes = {};
	ext.constructors = {};
	ext.methods = {};
	ext.operators = {};
	ext.castOperators = {};
	ext.libraries = {};
	ext.functions = {};
	ext.events = {};

	return setmetatable(ext, EXTENTION);
end

function EXTENTION.RegisterClass(this, id, name, isType, isValid)
	local entry = {id, name, isType, isValid};
	this.classes[#this.classes + 1] = entry;
end

function EXTENTION.RegisterConstructor(this, class, peramaters, constructor)
	local entry = {class, peramaters, constructor};
	this.constructors[#this.constructors + 1] = entry;
end

function EXTENTION.RegisterMethod(this, class, name, peramaters, type, count, method)
	local entry = {class, name, peramaters, type, count, method};
	this.methods[#this.methods + 1] = entry;
end

function EXTENTION.RegisterOperator(this, operation, peramaters, type, count, operator)
	local entry = {operation, peramaters, type, count, operator};
	this.operators[#this.operators + 1] = entry;
end

function EXTENTION.RegisterCastingOperator(this, type, peramaters, operator)
	local entry = {type, peramaters, operator};
	this.castOperators[#this.castOperators + 1] = entry;
end

function EXTENTION.RegisterLibrary(this, name)
	local entry = {name, name};
	this.libraries[#this.libraries + 1] = entry;
end

function EXTENTION.RegisterFunction(this, library, name, peramaters, type, count, _function)
	local entry = {library, name, peramaters, type, count, _function};
	this.functions[#this.functions + 1] = entry;
end

function EXTENTION.RegisterEvent(this, name, peramaters, type, count)
	local entry = {name, peramaters, type, count};
	this.events[#this.events + 1] = entry;
end

function EXTENTION.CheckRegistration(this, _function, ...)
	local state, err = Pcall(_function, ...);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s in component %s", err, this.name);
	end
end

function EXTENTION.EnableExtension(this)
	hook.Add("Expression3.LoadClasses", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.classes) do
			this:CheckRegistration(EXPR_LIB.RegisterClass, v[1], v[2], v[3], v[4]);
		end
	end);

	hook.Add("Expression3.LoadConstructors", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.constructors) do
			this:CheckRegistration(EXPR_LIB.RegisterConstructor, v[1], v[2], v[3]);
		end
	end);

	hook.Add("Expression3.LoadMethods", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.methods) do
			this:CheckRegistration(EXPR_LIB.RegisterMethod, v[1], v[2], v[3], v[4], v[5], v[6]);
		end
	end);

	hook.Add("Expression3.LoadOperators", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.operators) do
			this:CheckRegistration(EXPR_LIB.RegisterOperator, v[1], v[2], v[3], v[4], v[5]);
		end

		for _, v in pairs(this.castOperators) do
			this:CheckRegistration(EXPR_LIB.RegisterCastingOperator, v[1], v[2], v[3]);
		end
	end);

	hook.Add("Expression3.LoadLibraries", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.libraries) do
			this:CheckRegistration(EXPR_LIB.RegisterLibrary, v[1]);
		end
	end);

	hook.Add("Expression3.LoadFunctions", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.functions) do
			this:CheckRegistration(EXPR_LIB.RegisterFunction, v[1], v[2], v[3], v[4], v[5], v[6]);
		end
	end);

	hook.Add("Expression3.LoadEvents", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.events) do
			this:CheckRegistration(EXPR_LIB.RegisterEvent, v[1], v[2], v[3], v[4]);
		end
	end);
end

--[[
	:::Hooks For Loading extentions:::
	''''''''''''''''''''''''''''''''''
]]

function EXPR_LIB.Initalize()
	hook.Run("Expression3.RegisterExtensions");

	classes = {};
	classIDs = {};
	loadClasses = true;
	hook.Run("Expression3.LoadClasses");

	EXPR_LIB.RegisterClass("n", "int", isType, isValid) -- Temp: Remove when used.
	EXPR_LIB.RegisterClass("s", "string", isType, isValid) -- Temp: Remove when used.

	loadClasses = false;
	EXPR_CLASSES = classes;

	loadConstructors = true;
	hook.Run("Expression3.LoadConstructors");
	loadConstructors = false;

	methods = {};
	loadMethods = true;
	hook.Run("Expression3.LoadMethods");
	loadMethods = false;
	EXPR_METHODS = methods;

	operators = {};
	castOperators = {};
	loadOperators = true;
	hook.Run("Expression3.LoadOperators");
	loadOperators = false;
	EXPR_OPERATORS = operators;
	EXPR_CAST_OPERATORS = castOperators;

	librarys = {};
	loadLibraries = true;
	hook.Run("Expression3.LoadLibraries");
	loadLibraries = false;
	EXPADV_LIBRARIES = libraries;

	functions = {};
	loadFunctions = true;
	hook.Run("Expression3.LoadFunctions");
	loadFunctions = false;

	events = {};
	loadEvents = true;
	hook.Run("Expression3.LoadEvents");
	loadEvents = false;
	EXPADV_EVENTS = events;

	hook.Run("Expression3.PostRegisterExtensions");

	include("tokenizer.lua");
	include("parser.lua");
	include("compiler.lua");
end

EXPR_LIB.Initalize();