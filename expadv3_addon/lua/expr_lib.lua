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

function EXPR_LIB.RegisterConstructor(class, parameters, constructor)
	if (not loadConstructors) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor new %s(%s) outside of Hook::Expression3.LoadConstructors", class, parameters)
	end

	local cls = EXPR_LIB.GetClass(class);

	if (not cls) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor new %s(%s) for none existing class", class, parameters)
	end

	local state, signature = EXPR_LIB.ProcessPeramaters();

	if (not state) then
		EXPR_LIB.ThrowInternal(0, "%s for Constructor new %s(%s)", signature, class, parameters)
	end

	cls.constructors[signature] = constructor;
end

local methods;
local loadMethods = false;

function EXPR_LIB.RegisterMethod(class, name, parameters, type, count, method)

end

local operators;
local loadOperators = false;

function EXPR_LIB.RegisterOperator(operation, parameters, type, count, operator)

end

local castOperators;

function EXPR_LIB.RegisterCastingOperator(type, parameters, operator)

end

local librarys;
local loadLibraries = false;

function EXPR_LIB.RegisterLibrary(name)

end

local functions;
local loadFunctions = false;

function EXPR_LIB.RegisterFunction(library, name, parameters, type, count, _function)

end

local events;
local loadEvents = false;

function EXPR_LIB.RegisterEvent(name, parameters, type, count)

end

--[[
]]

function EXPR_LIB.IsValidClass(class)
end

function EXPR_LIB.GetClass(class)
end

function EXPR_LIB.ProcessPeramaters(peramaters)

end

--[[
	:::Extention Base For Loading Sainly:::
	'''''''''''''''''''''''''''''''''''''''
	Since we need to add everything in a specific order, this is a extention base that can do this for you.
]]

local EXTENTION = {};
EXTENTION.__index = EXTENTION;

function EXPR_LIB.RegisterExtention(this, name)
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

function EXTENTION.RegisterConstructor(this, class, parameters, constructor)
	local entry = {class, parameters, constructor};
	this.constructors[#this.constructors + 1] = entry;
end

function EXTENTION.RegisterMethod(this, class, name, parameters, type, count, method)
	local entry = {class, name, parameters, type, count, method};
	this.methods[#this.methods + 1] = entry;
end

function EXTENTION.RegisterOperator(this, operation, parameters, type, count, operator)
	local entry = {operation, parameters, type, count, operator};
	this.operators[#this.operators + 1] = entry;
end

function EXTENTION.RegisterCastingOperator(this, type, parameters, operator)
	local entry = {type, parameters, operator};
	this.castOperators[#this.castOperators + 1] = entry;
end

function EXTENTION.RegisterLibrary(this, name)
	local entry = {name, name};
	this.libraries[#this.libraries + 1] = entry;
end

function EXTENTION.RegisterFunction(this, library, name, parameters, type, count, _function)
	local entry = {library, name, parameters, type, count, _function};
	this.functions[#this.functions + 1] = entry;
end

function EXTENTION.RegisterEvent(this, name, parameters, type, count)
	local entry = {name, parameters, type, count};
	this.events[#this.events + 1] = entry;
end

function EXTENTION.CheckRegistration(this, _function, ...)
	local state, err = Pcall(_function, ...);
end

function EXTENTION.Registercomponent(this)
	hook.Add("Expression3.LoadClasses", "Expression3.Component." .. this.name, function()
		for _, v in pairs(this.classes) do
			this:CheckRegistration(EXPR_LIB.RegisterClass, v[1], v[2], v[3], v[4]);
		end
	end);

	hook.Add("Expression3.LoadConstructors", "Expression3.Component." .. this.name, function()
		for _, v in pairs(this.constructors) do
			this:CheckRegistration(EXPR_LIB.RegisterConstructor, v[1], v[2], v[3]);
		end
	end);

	hook.Add("Expression3.LoadMethods", "Expression3.Component." .. this.name, function()
		for _, v in pairs(this.methods) do
			this:CheckRegistration(EXPR_LIB.RegisterMethod, v[1], v[2], v[3], v[4], v[5], v[6]);
		end
	end);

	hook.Add("Expression3.LoadOperators", "Expression3.Component." .. this.name, function()
		for _, v in pairs(this.operators) do
			this:CheckRegistration(EXPR_LIB.RegisterOperator, v[1], v[2], v[3], v[4], v[5]);
		end

		for _, v in pairs(this.castOperators) do
			this:CheckRegistration(EXPR_LIB.RegisterCastingOperator, v[1], v[2], v[3]);
		end
	end);

	hook.Add("Expression3.LoadLibraries", "Expression3.Component." .. this.name, function()
		for _, v in pairs(this.libraries) do
			this:CheckRegistration(EXPR_LIB.RegisterLibrary, v[1]);
		end
	end);

	hook.Add("Expression3.LoadFunctions", "Expression3.Component." .. this.name, function()
		for _, v in pairs(this.functions) do
			this:CheckRegistration(EXPR_LIB.RegisterFunction, v[1], v[2], v[3], v[4], v[5], v[6]);
		end
	end);

	hook.Add("Expression3.LoadEvents", "Expression3.Component." .. this.name, function()
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
	classes = {};
	classIDs = {};
	loadClasses = true;
	hook.Run("Expression3.LoadClasses");
	loadClasses = false;

	loadConstructors = true;
	hook.Run("Expression3.LoadConstructors");
	loadConstructors = false;

	methods = {};
	loadMethods = true;
	hook.Run("Expression3.LoadMethods");
	loadMethods = false;

	operators = {};
	castOperators = {};
	loadOperators = true;
	hook.Run("Expression3.LoadOperators");
	loadOperators = false;

	librarys = {};
	loadLibraries = true;
	hook.Run("Expression3.LoadLibraries");
	loadLibraries = false;

	functions = {};
	loadFunctions = true;
	hook.Run("Expression3.LoadFunctions");
	loadFunctions = false;

	events = {};
	loadEvents = true;
	hook.Run("Expression3.LoadEvents");
	loadEvents = false;
end