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
		Some operators, methods and functions can return more then one value of the same type at once.
		You need to tell the compiler how many results it returns even if that is 0.
		Peramaters should always be class id's seperated by a comma (,); e.g "n,n,s".
		All documentation below is to be considered work in progress and this api will more then likely change.
		
	::HOOKS::
		Expression3.RegisterExtensions			-> Called when extensions should be registered.
		Expression3.LoadClasses					-> Classes must be registered inside this hook.
		Expression3.LoadConstructors			-> Constructors must be registered inside this hook.
		Expression3.LoadMethods					-> Methods must be registered inside this hook.
		Expression3.LoadOperators				-> Operators must be registered inside this hook.
		Expression3.LoadLibraries				-> Libraries must be registered inside this hook.
		Expression3.LoadFunctions				-> Functions must be registered inside this hook.
		Expression3.LoadEvents					-> Events must be registered inside this hook.
		Expression3.PostRegisterExtensions		-> This is called once expadv3 has loaded its extensions.
	
	::IMPORTANT::
		You should use 'Extension = EXPR_LIB.RegisterExtension(string)' to create a new Extension object.
		You should then use the api methods on the new Extension to register everything.
		Doing it this way means you do not need to add the hooks yourself as the extention will load the contents at the correct time.
		Do not forget to call Extension:EnableExtension() once your done otherwise the extention will not load itself.
		It is possible to register an extention outside the extention folder by creating it inisde Expression3.RegisterExtensions hook.
		
	::RULES::
		A constructor must always be a function, the first peramater will always be context unless exclude contex is true;
		Some operator's and casting operator's function is optional, if not given the compiler will attempt to use lua's native method.
		The first peramater to an operator / casting operator function will always be context unless exclude contex is true;
		A method's function can be a string, if so the compiler will attempt to use a native lua method on that object.
		The first peramater to a method's function will always be context unless exclude contex is true;
		A function's function can be a string, if so the compiler will attempt to use a native lua function at the given string; e.g string.replace.
		The first peramater to a function's function will always be context unless exclude contex is true;
		
	::EXPR_LIB::
		EXPR_LIB.RegisterClass(string short name, string class name, boolean = function(object) isType, boolean = function(object) isValid)
			Registers a new class with expression 3.

		EXPR_LIB.RegisterConstructor(str class, str parameters, obj = function(ctx, ...) constructor, boolean exclude contex)
			Registers a constructor for class with expression 3; new vector(1, 2, 3)

		EXPR_LIB.RegisterMethod(class, str name, str parameters, str type, number amount of values returned, (obj = function(ctx*, ...) method / string)*, boolean exclude contex)
			Registers a method with expression 3 on class;
			if operator is a string then it will use the method str on object with out context as a parameter.


		EXPR_LIB.RegisterOperator(str operation, str parameters, str type, number amount of values returned, obj = function(ctx*, ...) operator*, boolean exclude contex)
			Registers an operator with expression 3;
			if operator is nil then it will use the native operator on object.
		
		::OPERATORS::
			This list will expand as time goes on and more are added.
			
			and		(type1, type2)			type1 && type2
			or		(type1, type2)			type1 || type2
			add		(type1, type2)			type1 + type2
			sub		(type1, type2)			type1 - type2
			div		(type1, type2)			type1 / type2
			mul		(type1, type2)			type1 * type2
			exp		(type1, type2)			type1 ^ type2
			mod		(type1, type2)			type1 % type2
			ten		(type1, type2, type3)	type1 ? type2 : type3
			or		(type1, type2)			type1 || type2
			and		(type1, type2)			type1 && type2
			bxor	(type1, type2)			type1 ^^ type2
			bor		(type1, type2)			type1 | type2
			band	(type1, type2) 			type1 & type2
			eq*		(type1, ...)			type1 == [...]
			neq		(type1, type2)			type1 != type2
			eq		(type1, type2)			type1 == type2
			neq*	(type1, ...)			type1 != [...]
			lth		(type1, type2)			type1 < type2
			leg		(type1, type2)			type1 <= type2
			gth		(type1, type2)			type1 > type2
			geq		(type1, type2)			type1 >= type2
			bshl	(type1, type2)			type1 << type2
			bshr	(type1, type2)			type1 >> type2
			neg		(type1)					-type1
			not		(type1)					!type1
			len		(type1)					#type1

		EXPR_LIB.RegisterCastingOperator(str type, str parameter, obj = function(ctx*, ...) operator, boolean exclude contex)
			Registers a casting operator with expression 3 for casting from one class to another;
			type1(type2)					type1 = (type1) type2

		EXPR_LIB.RegisterLibrary(name)
			Registers a new library with expression 3.
			Every function must part of a library.

		EXPR_LIB.RegisterFunction(str library, str name, str parameters, str type, number amount of values returned, (obj = function(ctx, ...) / str) function, boolean exclude contex)
			Registers a function with library, these functions are overloaded.
			If function is a string then expression 3 will use _G[str function]() with out context as a parameter.

		EXPR_LIB.RegisterEvent(str name, str parameters, str type, number amount of values returned)
			Registers an event with expression 3.

		EXPR_LIB.GetClass(str class)

		EXPR_LIB.RegisterExtension(str name)
			Returns and registers a new extension with expression 3;
			This will allow you to add to the api with out manually using the required events.
	
	::Extension::
		Extension:RegisterClass(string short name, string class name, boolean = function(object) isType, boolean = function(object) isValid)
			Calls EXPR_LIB.RegisterClass(...) at the correct time with all given valid parameter.
		
		Extension.RegisterConstructorRegisterConstructor(str class, str parameters, obj = function(ctx*, ...) constructor, boolean exclude contex)
			Calls EXPR_LIB.RegisterConstructorRegisterConstructor(...) at the correct time with all given valid parameters.

		Extension:RegisterMethod(class, str name, str parameters, str type, number amount of values returned, (obj = function(ctx*, ...) method / string)*, boolean exclude contex)
			Calls EXPR_LIB.RegisterMethod(...) at the correct time with all given valid parameters.

		Extension:RegisterOperator(str operation, str parameters, str type, number amount of values returned, obj = function(ctx*, ...) operator*, boolean exclude contex)
			Calls EXPR_LIB.RegisterOperator(...) at the correct time with all given valid parameters.

		Extension:RegisterCastingOperator(str type, str parameter, obj = function(ctx, ...) operator, boolean exclude contex)
			Calls EXPR_LIB.RegisterCastingOperator(...) at the correct time with all given valid parameters.

		Extension:RegisterLibrary(name)
			Calls EXPR_LIB.RegisterLibrary(...) at the correct time with all given valid parameters.

		Extension:RegisterFunction(str library, str name, str parameters, str type, number amount of values returned, (obj = function(ctx*, ...) / str) function, boolean exclude contex)
			Calls EXPR_LIB.RegisterFunction(...) at the correct time with all given valid parameters.

		Extension:RegisterEvent(str name, str parameters, str type, number amount of values returned)
			Calls EXPR_LIB.RegisterEvent(...) at the correct time with all given valid parameters.

		Extension:EnableExtension()
			Must be called to allow the extention to register its contents.
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

--[[

]]

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

function EXPR_LIB.RegisterConstructor(class, parameter, constructor, excludeContext)
	if (not loadConstructors) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor new %s(%s) outside of Hook::Expression3.LoadConstructors", class, parameter);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor new %s(%s) for none existing class", class, parameter);
	end

	local state, signature = EXPR_LIB.ProcessParameter(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for Constructor new %s(%s)", signature, class, parameter);
	end

	local op = {};
	op.name = name;
	op.class = cls.id;
	op.parameter = signature;
	op.signature = string.format("%s(%s)", cls.id, signature);
	op.type = res.id;
	op.count = count;
	op.operation = constructor;
	op.context = not excludeContext;

	cls.constructors[op.signature] = op;
end

local methods;
local loadMethods = false;

function EXPR_LIB.RegisterMethod(class, name, parameter, type, count, method, excludeContext)
	-- if method is nil lua, compiler will use native Object:(...);

	if (not loadMethods) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s:%s(%s) outside of Hook::Expression3.LoadMethods", class, name, parameter);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s:%s(%s) for none existing class %s", class, name, parameter, class);
	end

	local state, signature = EXPR_LIB.ProcessParameter(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for method %s:%s(%s)", signature, class, name, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s:%s(%s) with none existing return class %s", class, name, parameter, type);
	end

	local meth = {};
	meth.name = name;
	meth.class = cls.id;
	meth.parameter = signature;
	meth.signature = string.format("%s:%s(%s)", cls.id, name, signature);
	meth.type = res.id;
	meth.count = count;
	meth.operation = method;
	meth.context = not excludeContext;

	methods[meth.signature] = meth;
	-- <Insert Heisenburg joke here>
end

local operators;
local loadOperators = false;

function EXPR_LIB.RegisterOperator(operation, parameter, type, count, operator, excludeContext)
	-- if operator is nil lua, compiler will use native if possible (+, -, /, *, ^, etc)

	if (not loadOperators) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register operator %s(%s) outside of Hook::Expression3.LoadOperators", operation, parameter);
	end

	local state, signature = EXPR_LIB.ProcessParameter(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for operator %s(%s)", signature, operation, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register operator %s(%s) with none existing return class %s", operation, parameter, type);
	end

	local op = {};
	op.name = operation;
	op.class = cls.id;
	op.parameter = signature;
	op.signature = string.format("%s(%s)", operation, signature);
	op.type = res.id;
	op.count = count;
	op.operation = operator;

	operators[op.signature] = op;
end

local castOperators;

function EXPR_LIB.RegisterCastingOperator(type, parameter, operator, excludeContext)
	if (not loadOperators) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register casting operator [(%s) %s] outside of Hook::Expression3.LoadOperators", type, parameter);
	end

	if (not operator) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register native casting operator [(%s) %s] an operation function is required.", type, parameter);
	end

	local state, signature = EXPR_LIB.ProcessParameter(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for casting operator [(%s) %s]", signature, type, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register casting operator [(%s) %s] for none existing class %s", type, parameter, type);
	end

	local op = {};
	op.parameter = signature;
	op.signature = string.format("(%s)%s", type, signature);
	op.type = res.id;
	op.count = 1;
	op.operation = operator;
	op.context = not excludeContext;

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
	lib.constants = {}; -- Future implementation.

	librarys[lib.name] = lib;
end

local functions;
local loadFunctions = false;

function EXPR_LIB.RegisterFunction(library, name, parameter, type, count, _function, excludeContext)
	-- If _function is a string then lua will use str(...) e.g; string.Replace
	if (not loadFunctions) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) outside of Hook::Expression3.LoadFunctions", library, name, parameter);
	end

	local lib = libraries[string.lower(library)];

	if (not lib) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) to none existing library %s", library, name, parameter, library);
	end

	local state, signature = EXPR_LIB.ProcessParameter(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for function %s.%s(%s)", signature, library, name, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) with none existing return class %s", library, name, parameter, type);
	end

	local op = {};
	op.name = name;
	op.parameter = signature;
	op.signature = string.format("%s(%s)", name, signature);
	op.type = res.id;
	op.count = count;
	op.operation = operator;
	op.context = not excludeContext;

	lib._functions[op.signature] = op;
end

local events;
local loadEvents = false;

function EXPR_LIB.RegisterEvent(name, parameter, type, count)
	if (not loadEvents) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register event %s(%s) outside of Hook::Expression3.LoadEvents", name, parameter);
	end

	local state, signature = EXPR_LIB.ProcessParameter(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for function %s.%s(%s)", signature, library, name, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) with none existing return class %s", library, name, parameter, type);
	end

	local evt = {};
	evt.name = name;
	evt.parameter = signature;
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

function EXPR_LIB.Processparameter(parameter)
	if (parameter == "") then
		return true, "";
	end

	local varg = false;
	local signature = {};
	local split = string.Explode(",", parameter);

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
	Since we need to add everything in a specific order, this is a extension base that can do this for you.
]]

local Extension = {};
Extension.__index = Extension;

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

	return setmetatable(ext, Extension);
end

function Extension.RegisterClass(this, id, name, isType, isValid)
	local entry = {id, name, isType, isValid};
	this.classes[#this.classes + 1] = entry;
end

function Extension.RegisterConstructor(this, class, parameter, constructor, excludeContext)
	local entry = {class, parameter, constructor, excludeContext};
	this.constructors[#this.constructors + 1] = entry;
end

function Extension.RegisterMethod(this, class, name, parameter, type, count, method, excludeContext)
	local entry = {class, name, parameter, type, count, method, excludeContext};
	this.methods[#this.methods + 1] = entry;
end

function Extension.RegisterOperator(this, operation, parameter, type, count, operator, excludeContext)
	local entry = {operation, parameter, type, count, operator, excludeContext};
	this.operators[#this.operators + 1] = entry;
end

function Extension.RegisterCastingOperator(this, type, parameter, operator, excludeContext)
	local entry = {type, parameter, operator, excludeContext};
	this.castOperators[#this.castOperators + 1] = entry;
end

function Extension.RegisterLibrary(this, name)
	local entry = {name, name};
	this.libraries[#this.libraries + 1] = entry;
end

function Extension.RegisterFunction(this, library, name, parameter, type, count, _function, excludeContext)
	local entry = {library, name, parameter, type, count, _function, excludeContext};
	this.functions[#this.functions + 1] = entry;
end

function Extension.RegisterEvent(this, name, parameter, type, count)
	local entry = {name, parameter, type, count};
	this.events[#this.events + 1] = entry;
end

function Extension.CheckRegistration(this, _function, ...)
	local state, err = Pcall(_function, ...);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s in component %s", err, this.name);
	end
end

function Extension.EnableExtension(this)
	hook.Add("Expression3.LoadClasses", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.classes) do
			this:CheckRegistration(EXPR_LIB.RegisterClass, v[1], v[2], v[3], v[4]);
		end
	end);

	hook.Add("Expression3.LoadConstructors", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.constructors) do
			this:CheckRegistration(EXPR_LIB.RegisterConstructor, v[1], v[2], v[3], v[4]);
		end
	end);

	hook.Add("Expression3.LoadMethods", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.methods) do
			this:CheckRegistration(EXPR_LIB.RegisterMethod, v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
		end
	end);

	hook.Add("Expression3.LoadOperators", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.operators) do
			this:CheckRegistration(EXPR_LIB.RegisterOperator, v[1], v[2], v[3], v[4], v[5], v[6]);
		end

		for _, v in pairs(this.castOperators) do
			this:CheckRegistration(EXPR_LIB.RegisterCastingOperator, v[1], v[2], v[3], v[4]);
		end
	end);

	hook.Add("Expression3.LoadLibraries", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.libraries) do
			this:CheckRegistration(EXPR_LIB.RegisterLibrary, v[1]);
		end
	end);

	hook.Add("Expression3.LoadFunctions", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.functions) do
			this:CheckRegistration(EXPR_LIB.RegisterFunction, v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
		end
	end);

	hook.Add("Expression3.LoadEvents", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.events) do
			this:CheckRegistration(EXPR_LIB.RegisterEvent, v[1], v[2], v[3], v[4]);
		end
	end);
end

--[[
	:::Hooks For Loading extensions:::
	''''''''''''''''''''''''''''''''''
]]

function EXPR_LIB.Initalize()
	MsgN("Loading Expression 3");

	include("expression3\extentions\core.lua");

	hook.Run("Expression3.RegisterExtensions");

	classes = {};
	classIDs = {};
	loadClasses = true;
	hook.Run("Expression3.LoadClasses");

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

	MsgN("Expression 3 has loaded.");
end

EXPR_LIB.Initalize();