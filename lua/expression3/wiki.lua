--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Wiki::
	```````````
]]

EXPR_WIKI = {};

--[[
]]

local loadWiki = false;
local constructors;
local methods;
local functions;
local pages;
--[[
]]

function EXPR_WIKI.RegisterConstructor(class, parameter, html)
	if (not loadWiki) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor method new %s(%s) outside of Hook::Expression3.LoadWiki", class, parameter);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (cls) then
		local state, signature = EXPR_LIB.SortArgs(parameter);

		if (state) then
			local signature = string.format("%s(%s)", cls.id, signature);
			local constructor = cls.constructors[signature];

			if (constructor) then
				constructor.html = html;
				constructors[signature] = constructor;
			end
		end
	end
end

function EXPR_WIKI.RegisterMethod(class, name, parameter, html)
	if (not loadWiki) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register method helper for %s.%s(%s) outside of Hook::Expression3.LoadWiki", class, name, parameter);
	end

	local cls = EXPR_LIB.GetClass(class);

	if (cls) then
		local state, signature = EXPR_LIB.SortArgs(parameter);

		if (state) then
			local signature = string.format("%s.%s(%s)", cls.id, name, signature);
			local method = EXPR_METHODS[signature];

			if (method) then
				method.html = html;
				methods[signature] = method;
			end
		end
	end
end

function EXPR_WIKI.RegisterFunction(library, name, parameter, html)
	if (not loadWiki) then
		EXPR_LIB.ThrowInternal(0, "Attempt to register function helper %s.%s(%s) outside of Hook::Expression3.LoadWiki", library, name, parameter);
	end

	local lib = libraries[string.lower(library)];

	if (lib) then
		local state, signature = EXPR_LIB.SortArgs(parameter);

		if (state) then
			local signature = string.format("%s(%s)", name, signature);
			local _function = lib._functions[signature];

			if (_function) then
				method.html = html;
				functions[library .. "." .. signature] = method;
			end
		end
	end
end

function EXPR_WIKI.RegisterPage(title, catagory, html)
	local page = {};
	page.title = title;
	page.catagory = catagory;
	page.html = html;

	pages[title] = page;

	return page;
end

--[[
]]

hook.Add("Expression3.PostRegisterExtensions", "Expression3.Wiki", function()
	loadWiki = true;

	constructors = {};
	methods = {};
	functions = {};
	pages = {};

	hook.Run("Expression3.LoadWiki");

	--TODO: Load helpers.

	loadWiki = false;

	EXPR_WIKI.CONSTRUCTORS = constructors;
	EXPR_WIKI.METHODS = methods;
	EXPR_WIKI.FUNCTIONS = functions;
	EXPR_WIKI.PAGES = pages;
end);

