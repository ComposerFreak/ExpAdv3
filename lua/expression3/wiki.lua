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

local loadWiki = false;
local constructors;
local methods;
local functions;
local pages;
local events;
local operators;

--------------------------------

function EXPR_WIKI.RegisterConstructor(library, html)
	if not loadWiki then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Constructor %s outside of Hook::Expression3.LoadWiki", library)
	end
	
	constructors[library] = html
end

function EXPR_WIKI.RegisterMethod(library, name, html)
	if not loadWiki then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Method for %s.%s outside of Hook::Expression3.LoadWiki", library, name)
	end

	methods[library] = methods[library] or {}
	
	methods[library][name] = html
end

function EXPR_WIKI.RegisterFunction(library, name, html)
	if not loadWiki then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Function %s.%s outside of Hook::Expression3.LoadWiki", library, name)
	end
	
	functions[library] = functions[library] or {}
	
	functions[library][name] = html
end

function EXPR_WIKI.RegisterPage(catagory, title, html)
	if not loadWiki then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Page %s.%s outside of Hook::Expression3.LoadWiki", catagory, title)
	end
	
	pages[catagory] = pages[catagory] or {}
	
	pages[catagory][title] = html
end

function EXPR_WIKI.RegisterEvent(library, name, html)
	if not loadWiki then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Event %s.%s outside of Hook::Expression3.LoadWiki", library, name)
	end
	
	events[library] = pages[library] or {}
	
	events[library][name] = html
end

function EXPR_WIKI.RegisterOperator(library, name, html)
	if not loadWiki then
		EXPR_LIB.ThrowInternal(0, "Attempt to register Operator %s.%s outside of Hook::Expression3.LoadWiki", library, name)
	end
	
	operators[library] = operators[library] or {}
	
	operators[library][name] = html
end


--------------------------------

hook.Add("Expression3.PostRegisterExtensions", "Expression3.Wiki", function()
	loadWiki = true;
	
	constructors = {}
	methods = {}
	functions = {}
	pages = {}
	events = {}
	operators = {}
	
	hook.Run("Expression3.LoadWiki")
	
	--TODO: Load helpers.
	
	loadWiki = false
	
	EXPR_WIKI.CONSTRUCTORS = constructors
	EXPR_WIKI.METHODS = methods
	EXPR_WIKI.FUNCTIONS = functions
	EXPR_WIKI.PAGES = pages
	EXPR_WIKI.EVENTS = events
	EXPR_WIKI.OPERATORS = operators
end)