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

	AddCSLuaFile("expression3/extensions/core.lua");
	AddCSLuaFile("expression3/extensions/math.lua");
	AddCSLuaFile("expression3/extensions/string.lua");
	AddCSLuaFile("expression3/extensions/vector.lua");
	AddCSLuaFile("expression3/extensions/vector2.lua");
	AddCSLuaFile("expression3/extensions/angle.lua");
	AddCSLuaFile("expression3/extensions/entity.lua");
	AddCSLuaFile("expression3/extensions/holograms.lua");
	AddCSLuaFile("expression3/extensions/table.lua");
	AddCSLuaFile("expression3/extensions/network.lua");
	AddCSLuaFile("expression3/extensions/color.lua");
	AddCSLuaFile("expression3/extensions/render.lua");
	AddCSLuaFile("expression3/extensions/player.lua");
	AddCSLuaFile("expression3/extensions/timers.lua");
	AddCSLuaFile("expression3/extensions/misc.lua");
	AddCSLuaFile("expression3/extensions/e2table.lua");
	AddCSLuaFile("expression3/extensions/wirelink.lua");
	AddCSLuaFile("expression3/extensions/sound.lua");
	AddCSLuaFile("expression3/extensions/find.lua");

	AddCSLuaFile("expression3/editor.lua");
	AddCSLuaFile( "expression3/editor.lua");
	AddCSLuaFile( "expression3/editor/font.lua" );
	AddCSLuaFile( "expression3/editor/vector2.lua" );
	AddCSLuaFile( "expression3/editor/derma/button.lua" );
	AddCSLuaFile( "expression3/editor/derma/closebutton.lua" );
	AddCSLuaFile( "expression3/editor/derma/editor.lua" );
	AddCSLuaFile( "expression3/editor/derma/console.lua" );
	AddCSLuaFile( "expression3/editor/derma/dhtml.lua" );
	AddCSLuaFile( "expression3/editor/derma/filebrowser.lua" );
	AddCSLuaFile( "expression3/editor/derma/frame.lua" );
	AddCSLuaFile( "expression3/editor/derma/hscrollbar.lua" );
	AddCSLuaFile( "expression3/editor/derma/ide.lua" );
	AddCSLuaFile( "expression3/editor/derma/imagebutton.lua" );
	AddCSLuaFile( "expression3/editor/derma/options.lua" );
	AddCSLuaFile( "expression3/editor/derma/propertysheet.lua" );
	AddCSLuaFile( "expression3/editor/derma/toolbar.lua" );
	AddCSLuaFile( "expression3/editor/derma/filemenu.lua" );
	AddCSLuaFile( "expression3/editor/derma/syntaxer.lua" );
	AddCSLuaFile( "expression3/editor/derma/wiki.lua" );
	AddCSLuaFile("expression3/editor/derma/checkbox.lua");
	AddCSLuaFile("expression3/editor/derma/findreplace.lua");
	AddCSLuaFile("expression3/editor/derma/console2.lua");
	AddCSLuaFile("expression3/editor/expr_editor_lib.lua");

	AddCSLuaFile("expression3/wiki.lua");
	AddCSLuaFile("expression3/wiki_inc.lua");
	AddCSLuaFile("expression3/wiki/html_compiler.lua");
	AddCSLuaFile("expression3/wiki/inits/autogen.lua");

	include("expression3/expr_lib.lua");

elseif (CLIENT) then
	include("expression3/expr_lib.lua");
	include("expression3/wiki.lua");
	include("expression3/wiki_inc.lua");
end
