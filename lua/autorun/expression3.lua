--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::AutoRun::
]]

EXPR_ROOT = "";
local _, addons = file.Find("addons\\*", "GAME");
for _, addon in pairs( addons ) do
	if file.Exists( string.format("addons\\%s\\lua\\autorun\\expression3.lua", addon), "GAME" ) then
		EXPR_ROOT = string.format("addons\\%s\\", addon);
		break;
	end
end

print("E3 Root directory:", EXPR_ROOT);

if (SERVER) then
	AddCSLuaFile();
	
	AddCSLuaFile("expression3/expr_lib.lua");
	
	AddCSLuaFile("expression3/tokenizer.lua");
	AddCSLuaFile("expression3/parser.lua");
	AddCSLuaFile("expression3/compiler.lua");
	AddCSLuaFile("expression3/debuger.lua");
	
	AddCSLuaFile( "expression3/editor.lua" )
	
	AddCSLuaFile( "expression3/editor/vector2.lua" )
	AddCSLuaFile( "expression3/editor/font.lua" )
	AddCSLuaFile( "expression3/editor/expr_editor_lib.lua" )
	
	AddCSLuaFile( "expression3/editor/derma/tree.lua" )
	AddCSLuaFile( "expression3/editor/derma/toolbar.lua" )
	AddCSLuaFile( "expression3/editor/derma/textentry.lua" )
	AddCSLuaFile( "expression3/editor/derma/syntaxer.lua" ) 
	AddCSLuaFile( "expression3/editor/derma/syntax/syntax_lua.lua" )
	AddCSLuaFile( "expression3/editor/derma/syntax/syntax_e3.lua" )
	AddCSLuaFile( "expression3/editor/derma/syntax/syntax_console.lua" )
	AddCSLuaFile( "expression3/editor/derma/syntax.lua" ) 
	AddCSLuaFile( "expression3/editor/derma/statebutton.lua" )
	AddCSLuaFile( "expression3/editor/derma/simpletabs.lua" )
	AddCSLuaFile( "expression3/editor/derma/propertysheet.lua" )
	AddCSLuaFile( "expression3/editor/derma/options2.lua" )
	AddCSLuaFile( "expression3/editor/derma/options.lua" )
	AddCSLuaFile( "expression3/editor/derma/imagebutton.lua" )
	AddCSLuaFile( "expression3/editor/derma/ide.lua" )
	AddCSLuaFile( "expression3/editor/derma/hscrollbar.lua" )
	AddCSLuaFile( "expression3/editor/derma/frame.lua" )
	AddCSLuaFile( "expression3/editor/derma/findreplace.lua" )
	AddCSLuaFile( "expression3/editor/derma/filemenu.lua" )
	AddCSLuaFile( "expression3/editor/derma/filebrowser.lua" )
	AddCSLuaFile( "expression3/editor/derma/editor.lua" )
	AddCSLuaFile( "expression3/editor/derma/dhtml.lua" )
	AddCSLuaFile( "expression3/editor/derma/console2.lua" )
	AddCSLuaFile( "expression3/editor/derma/console.lua" )
	AddCSLuaFile( "expression3/editor/derma/colorselect.lua" )
	AddCSLuaFile( "expression3/editor/derma/closebutton.lua" )
	AddCSLuaFile( "expression3/editor/derma/checkbox.lua" )
	AddCSLuaFile( "expression3/editor/derma/button.lua" )
	AddCSLuaFile( "expression3/editor/derma/autocomplete.lua" )
	
	resource.AddFile("models/lemongate/gibsmodel_chipmesh001.mdl");
	resource.AddFile("models/lemongate/gibsmodel_fanmesh001.mdl");
	resource.AddFile("models/lemongate/lemongate.mdl");
	resource.AddFile("models/mandrac/wire/e3.mdl");
	resource.AddFile("models/nezzkryptic/e3_chip.mdl");
	resource.AddFile("models/shadowscion/lemongate/gate.mdl");
	resource.AddFile("models/tanknut/cylinder.mdl");
	
	local addAll;
	
	addAll = function(path, gamepath)
		
		local files, folders = file.Find(path, gamepath);
		
		for _, file in pairs(files) do
			resource.AddFile( string.format("%s/%s", path, file) );
		end
		
		for _, folder in pairs(folders) do
			addAll( string.format("%s/%s", path, folder), gamepath );
		end
	end;
	
	addAll(string.format("%s/materials", EXPR_ROOT), "GAME");
	addAll(string.format("%s/models", EXPR_ROOT), "GAME");
	
	addAll(string.format("%s/lua/expression3/helper/csv", EXPR_ROOT), "GAME");
	addAll(string.format("%s/lua/expression3/helper/custom", EXPR_ROOT), "GAME");
	addAll(string.format("%s/lua/expression3/helper/examples", EXPR_ROOT), "GAME");
	
	include("expression3/expr_lib.lua");
	
elseif (CLIENT) then
	include("expression3/expr_lib.lua");
end
