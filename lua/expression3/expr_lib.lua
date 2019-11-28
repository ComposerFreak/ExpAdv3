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
		Parameters should always be class id's separated by a comma (,); e.g "n,n,s".
		All documentation below is to be considered work in progress and this api will more then likely change.

	::HOOKS::
		Expression3.RegisterExtension					-> Called when extensions should be registered.
		Expression3.LoadClasses							-> None extended classes must be registered inside this hook.
		Expression3.LoadExtendedClasses		-> Extended classes must be registered inside this hook.
		Expression3.LoadConstructors					-> Constructors must be registered inside this hook.
		Expression3.LoadMethods							-> Methods must be registered inside this hook.
		Expression3.LoadMethods							-> Methods must be registered inside this hook.
		Expression3.LoadAttributes						-> Attributes must be registered inside this hook.
		Expression3.LoadLibraries						-> Libraries must be registered inside this hook.
		Expression3.LoadFunctions						-> Functions must be registered inside this hook.
		Expression3.PostRegisterExtensions				-> This is called once expadv3 has loaded its extensions.
		Expression3.PostCompile.System.<function>		-> This is called after compiling every function on the system library,		-> ressult class, result count = (comiler, instruction, token, expressions)
												  		   (replace <function> with the name of the function on the library..
		Expression3.Entity.BuildSandbox					-> This is called when building the sandboxed enviroment for an entity.		-> (entity, context, enviroment)
		Expression3.Start.Entity						-> This is called when an entity is about to run for the first time.		-> (entity, context)
		Expression3.Entity.Think						-> Called by all expression 3 entitys during the entitys think function 	-> (entity, context)
		Expression3.Entity.Update						-> This is called when an entity has sucessfuly executed.					-> (entity, context)
		Expression3.Entity.Stop							-> This is called when an entity has shutdown for any given reason.			-> (entity, context)
		Expression3.GolemInit							-> this is called when the editor is created.
		Expression3.OpenGolem							-> this is called when the editor opens.
		Expression3.CloseGolem							-> this is called when the editor closes.
		Expression3.AddGolemTabTypes					-> This is called when custom tab types should be registered on the editor. -> (Editor)
		Expression3.LoadWiki							-> This is called when its time to register the helpers to the wiki.
		Expression3.ExtendBaseEntity					-> Called during the creation of the base entity table, can be used to register new methods onto the base entity, -> (table entitytbl);
		Expression3.ExtendContext							-> Called during the creation of the base context table, can be used to register new methods onto the base context,, -> (table basse context);



	::IMPORTANT::
		You should use 'Extension = EXPR_LIB.RegisterExtension(string)' to create a new Extension object.
		You should then use the api methods on the new Extension to register everything.
		Doing it this way means you do not need to add the hooks yourself as the extension will load the contents at the correct time.
		Do not forget to call Extension:EnableExtension() once your done otherwise the extension will not load itself.
		It is possible to register an extension outside the extension folder by creating it inside Expression3.RegisterExtensions hook.

	::RULES::
		A constructor's function can be a string, if so the compiler will attempt to use a native lua function at the given string; e.g string.replace.
		The first parameter to a constructor's function will always be context unless exclude context is true;
		Some operator's and casting operator's function is optional, if not given the compiler will attempt to use lua's native method.
		The first parameter to an operator / casting operator function will always be context unless exclude context is true;
		A method's function can be a string, if so the compiler will attempt to use a native lua method on that object.
		The first parameter to a method's function will always be context unless exclude context is true;
		NO LONGER SUPPORTED: A function's function can be a string, if so the compiler will attempt to use a native lua function at the given string; e.g string.replace.
		The first parameter to a function's function will always be context unless exclude context is true;

	::Examples::
		Using a string as an operation.
		Operator: 	extension:RegisterConstructor("v", "n,n,n", "Vector", true);
		Input:		new vector(1,2,3);
		OutPut:		Vector(1,2,3);

		Using a function as operation with context.
		Operator: 	extension:RegisterConstructor("v", "n,n,n", function(c,x,y,z) end, false);
		Input:		new vector(1,2,3);
		OutPut:		_Ops["v(n,n,n)"](context, 1,2,3);

		using a function as operation without context.
		Operator: 	extension:RegisterConstructor("v", "n,n,n", function(x,y,z) end, true);
		Input:		new vector(1,2,3);
		OutPut:		_Ops["v(n,n,n)"](1,2,3);

	::EXPR_LIB::
		EXPR_LIB.SetPrice(int price)
			Sets the price of the methods / functions / constructors your defining, this is currently unused but will be used if we need to change the way e3 manages performance.

		EXPR_LIB.RegisterPermission(string name, string image, string desc)
			Registers a new permission node, this allows you to add player granted access for a gate.

		EXPR_LIB.RegisterClass(string short name, string class name, string class boolean = function(object) isType, boolean = function(object) isValid)
			Registers a new class with expression 3.

		EXPR_LIB.RegisterExtendedClass(string short name, string class name, string base class name, boolean = function(object) isType, boolean = function(object) isValid)
			Registers a new class based of an existing class.

		EXPR_LIB.RegisterConstructor(str class, str parameters, obj = function(ctx, ...) constructor, boolean exclude context)
			Registers a constructor for class with expression 3; new vector(1, 2, 3)

		EXPR_LIB.RegisterMethod(class, str name, str parameters, str type, number amount of values returned, (obj = function(ctx*, ...) method / string)*, boolean exclude context)
			Registers a method with expression 3 on class;
			if operator is a string then it will use the method str on object without context as a parameter.

		EXPR_LIB.RegisterAttribute(class, str name, str type, string native field)
			Adds an attribute to a class, this does not take an operator or a function.
				-> E3)Var.Attribute = Value :: Lua)Var.Field = Value

		EXPR_LIB.RegisterOperator(str operation, str parameters, str type, number amount of values returned, obj = function(ctx*, ...) operator*, boolean exclude context)
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
			neq		(type1, type2)			type1 != type2
			eq		(type1, type2)			type1 == type2
			lth		(type1, type2)			type1 < type2
			leg		(type1, type2)			type1 <= type2
			gth		(type1, type2)			type1 > type2
			geq		(type1, type2)			type1 >= type2
			bshl	(type1, type2)			type1 << type2
			bshr	(type1, type2)			type1 >> type2
			neg		(type1)					-type1
			not		(type1)					!type1
			len		(type1)					#type1
			call 	(type1, ...)			type(...)

		EXPR_LIB.RegisterCastingOperator(str type, str parameter, obj = function(ctx*, ...) operator, boolean exclude context)
			Registers a casting operator with expression 3 for casting from one class to another;
			type1(type2)					type1 = (type1) type2

		EXPR_LIB.RegisterLibrary(name)
			Registers a new library with expression 3.
			Every function must part of a library.

		EXPR_LIB.RegisterFunction(str library, str name, str parameters, str type, number amount of values returned, (obj = function(ctx, ...) / str) function, boolean exclude context)
			Registers a function with library, these functions are overloaded.
			NO LONGER SUPPORTED: If function is a string then expression 3 will use _G[str function]() without context as a parameter.

		REMOVED: EXPR_LIB.RegisterEvent(str name, str parameters, str type, number amount of values returned)
			Registers an event with expression 3.

		EXPR_LIB.GetClass(str class)

		EXPR_LIB.RegisterExtension(str name)
			Returns and registers a new extension with expression 3;
			This will allow you to add to the api without manually using the required events.

	::Extension::
		Extension:SetPrice(int price)
			Sets the price of the method, function, constructors your about to define. This works the same way as EXPR_LIB.SetPrice(int) and is also unused.

		Extension:RegisterClass(string short name, string class name, boolean = function(object) isType, boolean = function(object) isValid)
			Calls EXPR_LIB.RegisterClass(...) at the correct time with all given valid parameter.

		Extension:RegisterExtendedClass(string short name, string class name, string base class name, boolean = function(object) isType, boolean = function(object) isValid)
			Calls EXPR_LIB.RegisterExtendedClass(...) at the correct time with all given valid parameter.

		Extension.RegisterConstructorRegisterConstructor(str class, str parameters, obj = function(ctx*, ...) constructor, boolean exclude context)
			Calls EXPR_LIB.RegisterConstructorRegisterConstructor(...) at the correct time with all given valid parameters.

		Extension:RegisterMethod(class, str name, str parameters, str type, number amount of values returned, (obj = function(ctx*, ...) method) / string*, boolean exclude context)
			Calls EXPR_LIB.RegisterMethod(...) at the correct time with all given valid parameters.

		Extension:RegisterAttribute(class, str name, str type, string native field)
			Calls EXPR_LIB.RegisterAttribute(...) at the correct time with all given valid parameters.

		Extension:RegisterOperator(str operation, str parameters, str type, number amount of values returned, obj = function(ctx*, ...) operator*, boolean exclude context)
			Calls EXPR_LIB.RegisterOperator(...) at the correct time with all given valid parameters.

		Extension:RegisterCastingOperator(str type, str parameter, obj = function(ctx, ...) operator, boolean exclude context)
			Calls EXPR_LIB.RegisterCastingOperator(...) at the correct time with all given valid parameters.

		Extension:RegisterLibrary(name)
			Calls EXPR_LIB.RegisterLibrary(...) at the correct time with all given valid parameters.

		Extension:RegisterFunction(str library, str name, str parameters, str type, number amount of values returned, (obj = function(ctx*, ...)) function, boolean exclude context)
			Calls EXPR_LIB.RegisterFunction(...) at the correct time with all given valid parameters.

		Extension:RegisterEvent(str name, str parameters, str type, number amount of values returned)
			Calls EXPR_LIB.RegisterEvent(...) at the correct time with all given valid parameters.

		Extension:EnableExtension()
			Must be called to allow the extension to register its contents.

	::Editor Extension::
		Extension.RegisterEditorMenu(str name, str icon, panel function(panel editor), function(panel editor, panel tab, boolean save))
			CLIENTSIDE ONLY: Used to add a new tab to the lefthand menu with its own menu icon to open it.
			The first function (arg #3) is called when the tab is created for the first time. The panel returned is used as the tabs main panel.
			The second function (arg #4) is called when the tab is closed.

	::WIKI::
		EXPR_WIKI.RegisterConstructor(str class, str parameter, str html)
			Creates a wiki section for this constructor.

		EXPR_WIKI.RegisterMethod(str class, str name, str parameter, str html)
			Creates a wiki section for this method.

		EXPR_WIKI.RegisterFunction(str library, str name, str parameter, str html)
			Creates a wiki section for this function.

		EXPR_WIKI.RegisterPage(str title, str catagory, str html)
			Creates a new wiki page.

]]

EXPR_LIB = {};

--[[
]]

print("E3 Lib Loading.");

if (not CLIENT) then
	util.AddNetworkString("Expression3.InitializedClient");

	util.AddNetworkString("Expression3.OpenGolem");
end

--[[
]]

function EXPR_LIB.ThrowInternal(level, msg, fst, ...)
	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	error(msg, level);
end

--[[
]]

local classes;
local classIDs;
local loadClasses = false;

--[[
	Prices are currently not used for anything, they where a back up plan.
]]

EXPR_MIN = 1;
EXPR_LOW = 10;
EXPR_MED = 25;
EXPR_HIGH = 50;

local PRICE = EXPR_LOW;

function EXPR_LIB.SetPrice(price)
	PRICE = price;
end

--[[

]]

local STATE = 1;

EXPR_SERVER = 0;
EXPR_SHARED = 1;
EXPR_CLIENT = 2;

function EXPR_LIB.SetServerState()
	STATE = EXPR_SERVER;
end

function EXPR_LIB.SetSharedState()
	STATE = EXPR_SHARED;
end

function EXPR_LIB.SetClientState()
	STATE = EXPR_CLIENT;
end

--[[
]]

EXPR_LIB.PERMS = { };

function EXPR_LIB.RegisterPermission(name, image, desc)
	EXPR_LIB.PERMS[name] = {name, image, desc};
end



--[[
	
]]

local events = {};
local loadEvents = false;

function EXPR_LIB.RegisterEvent(name, parameter, type, count)
	if (not loadEvents) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Event %s(%s) outside of Hook::Expression3.LoadEvents", name, parameter);
	end

	local state, signature = EXPR_LIB.SortArgs(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for Event %s(%s)", signature, name, parameter);
	end

	if not type then type = "_nil"; end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Event %s(%s) with none existing return class %s", name, parameter, type);
	end

	local evt = {};
	evt.name = name;
	evt.state = STATE;
	evt.parameter = signature;
	evt.signature = string.format("%s(%s)", name, signature);
	evt.result = res.id;
	evt.rCount = count or 0;
	events[evt.signature] = evt;

	return evt;
end

--[[

]]

function EXPR_LIB.RegisterClass(id, name, isType, isValid)

	if (not loadClasses) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register class %s outside of Hook::Expression3.LoadClasses }}", name);
	end

	if (string.len(id) > 1) then
		id = "_" .. id;
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
	class.base = "o";
	class.state = STATE;
	class.price = PRICE;

	class.isType = isType;
	class.isValid = isValid;

	class.attributes = {};
	class.constructors = {};

	classIDs[class.id] = class;
	classes[class.name] = class;

	--MsgN("Registered Class: ", class.id, " - ", class.name);

	return class;
end

--[[
]]

function EXPR_LIB.RegisterExtendedClass(id, name, base, isType, isValid)

	if (not loadClasses) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register class %s outside of Hook::Expression3.LoadClasses", name);
	end

	local cls = EXPR_LIB.GetClass(base);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register extended class %s from none existing class %s", class, base);
	end

	local class = EXPR_LIB.RegisterClass(id, name, isType, isValid);

	class.base = cls.id;

	return class;
end

function EXPR_LIB.RegisterWiredInport(class, wiretype, func)
	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register wired inport for none existing class %s", class);
	end

	if (SERVER) then
		if (not WireLib.DT[wiretype]) then
			EXPR_LIB.ThrowInternal(0, "Attempt to register wired inport for class %s, with invalid wire type %s", class, wiretype);
		end
	end

	cls.wire_out_func = func;
	cls.wire_out_class = wiretype;
end

function EXPR_LIB.RegisterWiredOutport(class, wiretype, func)
	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register wired outport for none existing class %s", class);
	end

	if (SERVER) then
		if (not WireLib.DT[wiretype]) then
			EXPR_LIB.ThrowInternal(0, "Attempt to register wired outport for class %s, with invalid wire type %s", class, wiretype);
		end
	end

	cls.wire_in_func = func;
	cls.wire_in_class = wiretype;
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

	local state, signature = EXPR_LIB.SortArgs(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for Constructor new %s(%s)", signature, class, parameter);
	end

	local op = {};
	op.name = name;
	op.class = cls.id;
	op.state = STATE;
	op.price = PRICE;
	op.parameter = signature;
	op.signature = string.format("%s(%s)", cls.id, signature);
	op.result = cls.id;
	op.rCount = count;
	op.operator = constructor;
	op.context = not excludeContext;

	cls.constructors[op.signature] = op;

	return op;
end

local methods;
local loadMethods = false;

function EXPR_LIB.RegisterMethod(class, name, parameter, type, count, method, excludeContext)
	-- if method is nil lua, compiler will use native Object:(...);

	if (not loadMethods) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s.%s(%s) outside of Hook::Expression3.LoadMethods", class, name, parameter);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s.%s(%s) for none existing class %s", class, name, parameter, class);
	end

	local state, signature = EXPR_LIB.SortArgs(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for method %s.%s(%s)", signature, class, name, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method %s.%s(%s) with none existing return class %s", class, name, parameter, type);
	end

	local meth = {};
	meth.name = name;
	meth.class = cls.id;
	meth.state = STATE;
	meth.price = PRICE;
	meth.parameter = signature;
	meth.signature = string.format("%s.%s(%s)", cls.id, name, signature);
	meth.result = res.id;
	meth.rCount = count;
	meth.operator = method;
	meth.context = not excludeContext;

	methods[meth.signature] = meth;
	-- <Insert Heisenburg joke here>

	return meth;
end

local loadAttributes;

function EXPR_LIB.RegisterAttribute(class, attribute, type, native)
	native = native or attribute;

	if (not loadAttributes) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register attribute %s.%s outside of Hook::Expression3.LoadAttributes", class, attribute);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register attribute %s.%s for none existing class %s", class, attribute, class);
	end

	local typ = EXPR_LIB.GetClass(type);

	if (not typ) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register attribute %s.%s of none existing class %s", class, attribute, type);
	end

	local atr = {};
	atr.field = native;
	atr.class = typ.id;
	atr.attribute = attribute;

	cls.attributes[attribute] = atr;

	--MsgN("Registered attribute: ", class .. "." .. attribute);

	return atr;
end

local operators;
local loadOperators = false;

function EXPR_LIB.RegisterOperator(operation, parameter, type, count, operator, excludeContext)
	-- if operator is nil lua, compiler will use native if possible (+, -, /, *, ^, etc)

	if (not loadOperators) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register operator %s(%s) outside of Hook::Expression3.LoadOperators", operation, parameter);
	end

	local state, signature = EXPR_LIB.SortArgs(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for operator %s(%s)", signature, operation, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register operator %s(%s) with none existing return class %s", operation, parameter, type);
	end

	local op = {};
	op.name = operation;
	op.state = STATE;
	op.price = PRICE;
	op.parameter = signature;
	op.signature = string.format("%s(%s)", operation, signature);
	op.result = res.id;
	op.rCount = count;
	op.operator = operator;
	op.context = not excludeContext;
	op.operation = operation;

	operators[op.signature] = op;

	return op;
end

local castOperators;

function EXPR_LIB.RegisterCastingOperator(type, parameter, operator, excludeContext)
	if (not loadOperators) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register casting operator [(%s) %s] outside of Hook::Expression3.LoadOperators", type, parameter);
	end

	if (not operator) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register native casting operator [(%s) %s] an operation function is required.", type, parameter);
	end

	local state, signature = EXPR_LIB.SortArgs(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for casting operator [(%s) %s]", signature, type, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register casting operator [(%s) %s] for none existing class %s", type, parameter, type);
	end

	local op = {};
	op.parameter = signature;
	op.state = STATE;
	op.price = PRICE;
	op.signature = string.format("(%s)%s", type, signature);
	op.result = res.id;
	op.rCount = 1;
	op.operator = operator;
	op.context = not excludeContext;

	castOperators[op.signature] = op;

	return op;
end

local libraries;
local loadLibraries = false;

function EXPR_LIB.RegisterLibrary(name)
	if (not loadLibraries) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register library %s) outside of Hook::Expression3.LoadLibariess", name);
	end

	local lib = {};
	lib.name = string.lower(name);
	lib._functions = {};
	lib._constants = {};

	libraries[lib.name] = lib;

	--MsgN("Registered library: ", lib.name);
end

local functions;
local loadFunctions = false;
local blank = function() end

function EXPR_LIB.RegisterFunction(library, name, parameter, type, count, _function, excludeContext)
	if (not loadFunctions) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) outside of Hook::Expression3.LoadFunctions", library, name, parameter);
	end

	local lib = libraries[string.lower(library)];

	if (not lib) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) to none existing library %s", library, name, parameter, library);
	end

	local state, signature = EXPR_LIB.SortArgs(parameter);

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for function %s.%s(%s)", signature, library, name, parameter);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function %s.%s(%s) with none existing return class %s", library, name, parameter, type);
	end

	local op = {};
	op.name = name;
	op.state = STATE;
	op.price = PRICE;
	op.parameter = signature;
	op.signature = string.format("%s(%s)", name, signature);
	op.result = res.id;
	op.rCount = count;
	op.operator = _function or blank;
	op.context = not excludeContext;

	lib._functions[op.signature] = op;

	--MsgN("Registered function ", library, ".", op.signature);

	return op;
end

--[[
]]


--[[

]]

local constants;
local loadConstants = false;

function EXPR_LIB.RegisterConstant(library, name, type, value, native)
	if (not loadConstants) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register constant %s.%s outside of Hook::Expression3.LoadConstantss", library, name);
	end

	local lib = libraries[string.lower(library)];

	if (not lib) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register constant %s.%s to none existing library %s", library, name, library);
	end

	local res = EXPR_LIB.GetClass(type);

	if (not res) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register constant %s.%s of none existing class %s", library, name, type);
	end

	if native then
		if not isstring(value) then
			EXPR_LIB.ThrowInternal(0, "Attempt to register constant %s.%s using invalid native value %s", library, name, tostring(value));
		end
	elseif isstring(value) then
		native = true;
		value = string.format(" %q ", value);
	elseif isnumber(value) then
		native = true;
		value = string.format(" %i ", value);
	else
		EXPR_LIB.ThrowInternal(0, "Attempt to register constant %s.%s using invalid value %s", library, name, tostring(value));
	end

	local signature = string.format("%s.%s", library, name);

	local op = {};
	op.name = name;
	op.state = STATE;
	op.result = res.id;
	op.value = value;
	op.native = native;
	op.signature = signature;

	lib._constants[op.name] = op;

	--MsgN("Registered constant ", library, ".", op.name);

	return op;
end

function EXPR_LIB.GetAllClasses()
	local res = {};

	if ( EXPR_CLASSES ) then
		for _, v in pairs(EXPR_CLASSES) do
			res[v] = v;
		end
	end

	return res;
end

function EXPR_LIB.GetClass(class)
	if not isstring(class) then
		debug.Trace();
		EXPR_LIB.ThrowInternal(0, "EXPR_LIB.GetClass(s) was given %s.", type(class));
	end

	if (not class or class == "") then
		class = "void";
	end

	if (classes[class]) then
		return classes[class];
	end

	if (string.len(class) > 1 and string.sub(class, 1, 1) ~= "_") then
		class = "_" .. class;
	end

	return classIDs[class];
end

function EXPR_LIB.IsValidClass(class)
	return EXPR_LIB.GetClass(class) ~= nil;
end

function EXPR_LIB.SortArgs(parameter)
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
		local cls = EXPR_LIB.GetClass(v);

		if (v == "...") then
			return false, string.format("Vararg (...) must be last parameter", v, k);
		elseif (not cls) then
			return false, string.format("Invalid class (%s) for parameter #%i", v, k);
		end

		signature[k] = cls.id;
	end

	if (varg) then
		signature[#signature + 1] = "...";
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
	ext.perms = {};
	ext.classes = {};
	ext.state = EXPR_SHARED;
	ext.price = EXPR_LOW;
	ext.constructors = {};
	ext.methods = {};
	ext.attributes = {};
	ext.operators = {};
	ext.castOperators = {};
	ext.libraries = {};
	ext.functions = {};
	ext.constants = {};
	ext.events = {};

	return setmetatable(ext, Extension);
end

function EXPR_LIB.GetExtensionMetatable()
	return Extension;
end

function Extension.SetPrice(this, price)
	this.price = price;
end

function Extension.SetServerState(this)
	this.state = EXPR_SERVER;
end

function Extension.SetSharedState(this)
	this.state = EXPR_SHARED;
end

function Extension.SetClientState(this)
	this.state = EXPR_CLIENT;
end

function Extension.RegisterPermission(this, name, image, desc)
	this.perms[#this.perms+1] = {name, image, desc};
end

function Extension.RegisterEvent(this, name, parameter, type, count)
	this.events[#this.events+1] = {name, parameter, type, count, this.state};
end

function Extension.RegisterClass(this, id, name, isType, isValid)
	local entry = {id, name, isType, isValid, this.state};
	this.classes[#this.classes + 1] = entry;
end

function Extension.RegisterExtendedClass(this, id, name, base, isType, isValid)
	local entry = {[0] = base, id, name, isType, isValid, this.state};
	this.classes[#this.classes + 1] = entry;
end

function Extension.RegisterWiredInport(this, class, wiretype, func)
	hook.Add("Expression3.LoadConstructors", "Expression3.WireInput." .. class, function()
		if this.enabled then
			EXPR_LIB.RegisterWiredInport(class, wiretype, func);
		end
	end);
end

function Extension.RegisterWiredOutport(this, class, wiretype, func)
	hook.Add("Expression3.LoadConstructors", "Expression3.WireOutput." .. class, function()
		if (this.enabled) then
			EXPR_LIB.RegisterWiredOutport(class, wiretype, func);
		end
	end);
end

function Extension.RegisterConstructor(this, class, parameter, constructor, excludeContext)
	local entry = {class, parameter, constructor, excludeContext, this.state, this.price};
	this.constructors[#this.constructors + 1] = entry;
end

function Extension.RegisterMethod(this, class, name, parameter, type, count, method, excludeContext)
	local entry = {class, name, parameter, type, count, method, excludeContext, this.state, this.price};
	this.methods[#this.methods + 1] = entry;
end

function Extension.RegisterAttribute(this, class, attribute, type, native)
	local entry = {class, attribute, type, native, this.state, this.price};
	this.attributes[#this.attributes + 1] = entry;
end

function Extension.RegisterOperator(this, operation, parameter, type, count, operator, excludeContext)
	local entry = {operation, parameter, type, count, operator, excludeContext, this.state, this.price};
	this.operators[#this.operators + 1] = entry;
end

function Extension.RegisterCastingOperator(this, type, parameter, operator, excludeContext)
	local entry = {type, parameter, operator, excludeContext, this.state, this.price};
	this.castOperators[#this.castOperators + 1] = entry;
end

function Extension.RegisterLibrary(this, name)
	local entry = {name, name};
	this.libraries[#this.libraries + 1] = entry;
end

function Extension.RegisterFunction(this, library, name, parameter, type, count, _function, excludeContext)
	local entry = {library, name, parameter, type, count, _function, excludeContext, this.state, this.price};
	this.functions[#this.functions + 1] = entry;
end

function Extension.RegisterConstant(this, library, name, type, value, native)
	local entry = {library, name, type, value, native, this.state};
	this.constants[#this.constants + 1] = entry;
end

function Extension.CheckRegistration(this, _function, ...)
	local state, err = pcall(_function, ...);

	if (not state) then
		print("->", ...)
		EXPR_LIB.ThrowInternal(0, "%s in component %s", err, this.name);
	end

	return err;
end

function Extension.PostLoadClasses()
end

local enabledExtensions = {};

function Extension.EnableExtension(this)
	this.enabled = true;

	hook.Add("Expression3.LoadPerms", "Expression3.Extention." .. this.name, function()
		for _, v in pairs(this.perms) do
			EXPR_LIB.RegisterPermission(v[1], v[2], v[3]);
		end
	end);

	local events = {};

	hook.Add("Expression3.LoadEvents", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.events) do
			if (not v[0]) then
				STATE = v[5];

				local op = this:CheckRegistration(EXPR_LIB.RegisterEvent, v[1], v[2], v[3], v[4]);
				op.extension = this.name;
				events[op.name] = op;
			end
		end
	end);

	local classes = {};

	hook.Add("Expression3.LoadClasses", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.classes) do
			if (not v[0]) then
				STATE = v[5];
				PRICE = v[6];

				local op = this:CheckRegistration(EXPR_LIB.RegisterClass, v[1], v[2], v[3], v[4]);
				op.extension = this.name;
				classes[op.id] = op;
			end
		end
	end);

	hook.Add("Expression3.LoadExtendedClasses", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.classes) do
			if (v[0]) then
				STATE = v[5];
				PRICE = v[6];

				local op = this:CheckRegistration(EXPR_LIB.RegisterExtendedClass, v[1], v[2], v[0], v[3], v[4]);
				op.extension = this.name;
				classes[op.id] = op;
			end
		end
	end);

	local constructors = {};

	hook.Add("Expression3.LoadConstructors", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.constructors) do
			STATE = v[5];
			PRICE = v[6];

			local op = this:CheckRegistration(EXPR_LIB.RegisterConstructor, v[1], v[2], v[3], v[4]);
			op.extension = this.name;
			constructors[op.signature] = op;
		end

		this:PostLoadClasses(EXPR_LIB.GetAllClasses());
	end);

	local methods = {};

	hook.Add("Expression3.LoadMethods", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.methods) do
			STATE = v[8];
			PRICE = v[9];

			local op = this:CheckRegistration(EXPR_LIB.RegisterMethod, v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
			op.extension = this.name;
			methods[op.signature] = op;
		end
	end);

	local attributes = {};

	hook.Add("Expression3.LoadAttributes", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.attributes) do
			STATE = v[5];
			PRICE = v[6];

			local atr = this:CheckRegistration(EXPR_LIB.RegisterAttribute, v[1], v[2], v[3], v[4]);
			atr.extension = this.name;
			attributes[atr.attribute] = atr;
		end
	end);

	local operators = {};

	hook.Add("Expression3.LoadOperators", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.operators) do
			STATE = v[7];
			PRICE = v[8];

			local op = this:CheckRegistration(EXPR_LIB.RegisterOperator, v[1], v[2], v[3], v[4], v[5], v[6]);
			op.extension = this.name;
			operators[op.signature] = op;
		end

		for _, v in pairs(this.castOperators) do
			STATE = v[5];
			PRICE = v[6];

			local op = this:CheckRegistration(EXPR_LIB.RegisterCastingOperator, v[1], v[2], v[3], v[4]);
			op.extension = this.name;
			operators[op.signature] = op;
		end
	end);

	hook.Add("Expression3.LoadLibraries", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.libraries) do
			this:CheckRegistration(EXPR_LIB.RegisterLibrary, v[1]);
		end
	end);

	local functions = {};

	hook.Add("Expression3.LoadFunctions", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.functions) do
			STATE = v[8];
			PRICE = v[9];

			local op = this:CheckRegistration(EXPR_LIB.RegisterFunction, v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
			op.extension = this.name;
			functions[op.signature] = op;
		end
	end);

	local constants = {};

	hook.Add("Expression3.LoadConstants", "Expression3.Extension." .. this.name, function()
		for _, v in pairs(this.constants) do
			STATE = v[6];

			local op = this:CheckRegistration(EXPR_LIB.RegisterConstant, v[1], v[2], v[3], v[4], v[5]);
			op.extension = this.name;
			constants[op.signature] = op;
		end
	end);

	hook.Add("Expression3.BuildExtensionData", "Expression3.Extension." .. this.name, function()
		this.classes = classes;
		this.constructors = constructors;
		this.methods = methods;
		this.operators = operators;
		this.functions = functions;
		this.attributes = attributes;
		enabledExtensions[this.name] = this;

		MsgN("Registered E3 extension: ", this.name);
	end)
end

-- emtpty table before: Expression3.PostRegisterExtensions
function EXPR_LIB.GetEnabledExtensions()
	return enabledExtensions or {};
end
--[[
	:::Hooks For Loading extensions:::
	''''''''''''''''''''''''''''''''''
]]

local extendClass;

function extendClass(class, base)
	local c = EXPR_LIB.GetClass(class);
	local b = EXPR_LIB.GetClass(base);

	if (not c or not b) then
		return;
	end

	if (not c.extends) then
		c.extends = {};
	end

	if (c.extends[b.id]) then
		return;
	end

	if (c.id == b.id) then
		return;
	end

	if (b.base) then
		extendClass(base, b.base)
	end

	if (not c.isType) then
		c.isType = b.isType;
	end

	if (not c.isValid) then
		c.isValid = b.isValid;
	end

	local constructors = c.constructors;

	for _, op in pairs(b.constructors) do
		local signature = string.format("%s(%s)", class, op.parameter);

		if (not constructors[signature]) then
			constructors[signature] = {
				name = class,
				class = c.id,
				state = op.state,
				price = op.price,
				parameter = op.parameter,
				signature = signature,
				result = op.result,
				rCount = op.rCount,
				operator = op.operator,
				context = op.context,
			};
		end
	end

	for _, op in pairs(methods) do
		if (op.class == base) then
			local signature = string.format("%s.%s(%s)", class, op.name, op.parameter);

			if (not methods[signature]) then
				methods[signature] = {
					name = op.name,
					class = c.id,
					state = op.state,
					price = op.price,
					parameter = op.parameter,
					signature = signature,
					result = op.result,
					rCount = op.rCount,
					operator = op.operator,
					context = op.context,
				};
			end
		end
	end

	local attributes = c.attributes;

	for att, data in pairs(b.attributes or {}) do
		if (not attributes[att]) then
			attributes[att] = data;
		end
	end
	
	c.extends[b.id] = true;

	--MsgN("Extended Class: ", c.name, " from ", b.name);
end

function EXPR_LIB.ToString(context, type, value)
	local op = EXPR_CAST_OPERATORS["(s)" .. type];

	if (not op or not op.operator) then
		return tostring(value);
	elseif (not op.context) then
		return op.operator(value);
	else
		return op.operator(context, value);
	end
end

function EXPR_LIB.Initialize()
	--MsgN("Loading Expression 3");

	hook.Run("Expression3.RegisterExtensions");

	hook.Run("Expression3.LoadPerms");

	classes = {};
	classIDs = {};
	loadClasses = true;
	hook.Run("Expression3.LoadClasses");
	hook.Run("Expression3.LoadExtendedClasses");

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

	loadAttributes = true;
	hook.Run("Expression3.LoadAttributes");
	loadAttributes = false;

	events = {};
	loadEvents = true;
	hook.Run("Expression3.LoadEvents");
	
	loadEvents = false;
	EXPR_EVENTS = events;

	operators = {};
	castOperators = {};
	loadOperators = true;
	hook.Run("Expression3.LoadOperators");
	loadOperators = false;
	EXPR_OPERATORS = operators;
	EXPR_CAST_OPERATORS = castOperators;

	libraries = {};
	loadLibraries = true;
	hook.Run("Expression3.LoadLibraries");
	loadLibraries = false;
	EXPR_LIBRARIES = libraries;

	functions = {};
	loadFunctions = true;
	hook.Run("Expression3.LoadFunctions");
	loadFunctions = false;

	constants = {};
	loadConstants = true;
	hook.Run("Expression3.LoadConstants");
	loadConstants = false;

	for id, class in pairs(classes) do
		extendClass(id, class.base);
	end

	if (CLIENT) then
		include("expression3/editor/expr_editor_lib.lua");
	end

	hook.Run("Expression3.BuildExtensionData");

	hook.Run("Expression3.PostRegisterExtensions");

	include("expression3/tokenizer.lua");
	include("expression3/parser.lua");
	include("expression3/compiler.lua");

	if (CLIENT) then
		hook.Run("Expression3.LoadGolem");
	end

	include("expression3/debuger.lua");

	--MsgN("Expression 3 has loaded.");
end

--[[
	:::Hooks For Loading Golem Editor:::
	''''''''''''''''''''''''''''''''''''
]]

if (CLIENT) then
	hook.Add("Expression3.LoadGolem", "Expression3.Golem.Init", function()
		include("expression3/editor.lua");
		Golem.Reload();
	end);
end

--[[
	:::Context Registry:::
	''''''''''''''''''''''
]]

local AllRunning = {};

function EXPR_LIB.GetAll()
	return AllRunning;
end

function EXPR_LIB.RegisterContext(context)
	AllRunning[context] = context;
end

function EXPR_LIB.UnregisterContext(context)
	AllRunning[context] = nil;
end

--[[
]]

local SysTime, bench = SysTime;

function EXPR_LIB.Validate(cb, script, files)
	local vldr = {};
	local ok, res;
	vldr.timer = "Validator:" .. tostring(vldr);

	vldr.func = coroutine.create(function()
		local a, b = pcall(function()
			bench = SysTime();

			vldr.tokenizer = EXPR_TOKENIZER.New();

			vldr.tokenizerTime = 0;

			vldr.tokenizerCount = 0;

			vldr.tokenizer.vldr = vldr;

			vldr.tokenizer:Initialize("EXPADV", script);

			ok, res = vldr.tokenizer:Run();

			vldr.tokenizerTime = vldr.tokenizerTime + (SysTime() - bench);

			--print("Token Time -> ", SysTime() - bench);

			if ok then
				coroutine.yield();

				bench = SysTime();

				vldr.parser = EXPR_PARSER.New();

				vldr.parser:Initialize(res, files);

				ok, res = vldr.parser:Run();

				vldr.parserTime = SysTime() - bench;

				--print("Parser Time -> ", SysTime() - bench);

				if ok then
					coroutine.yield();

					bench = SysTime();

					vldr.compiler = EXPR_COMPILER.New();

					vldr.compiler:Initialize(res, files);

					ok, res = vldr.compiler:Run();

					vldr.compilerTime = SysTime() - bench;

					--print("Compiler Time -> ", SysTime() - bench);

					if ok then
						coroutine.yield();

						bench = SysTime();

						res.build();

						vldr.buildTime = SysTime() - bench;

						--print("Build Time -> ", SysTime() - bench);
					end
				end
			end
		end);

		if (not a) then
			ok = a;
			res = {msg = b, state == "internal", line = 0, char = 0};
		end

		vldr.finished = true;
	end);

	vldr.start = function()
		timer.Create(vldr.timer, 0.01, 0, vldr.resume);

		timer.Create(vldr.timer .. 2, 60, 1, function()
			if (not vldr.finished) then
				timer.Remove(vldr.timer);
				cb(false, "Validation took to long.");
			end
		end);

		return vldr.resume();
	end;

	vldr.stop = function()
		timer.Remove(vldr.timer);
	end;

	vldr.resume = function()
		if (not vldr.finished) then
			coroutine.resume(vldr.func);
		end

		if (vldr.finished) then
			vldr.stop();
			cb(ok, res);
			return true;
		end

		return false;
	end;

	return vldr;
end


--[[
	:::Load Expression 3:::
	'''''''''''''''''''''''
]]

include("expression3/uploader.lua");
include("expression3/core/init.lua");

timer.Simple(5, EXPR_LIB.Initialize);
