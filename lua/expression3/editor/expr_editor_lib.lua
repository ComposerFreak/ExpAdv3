--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Expression 3 Editor Lib::
	NOTE: This file is yet to be included anywhere.
]]

local Extension = EXPR_LIB.GetExtensionMetatable();

if (not Extension) then
	error("Unable to get extention meta table for editor upgrades.");
end

function Extension.RegisterEditorMenu(this, name, icon, open, close)
	hook.Add("Expression3.AddGolemTabTypes", "Expression3." .. this.name .. "." .. name, function(editor)
		if (this.enabled) then
			editor:AddTabType(name, function(self)
				local menu = self.tMenuTabs[name];

				if (menu) then
					self.pnlSideTabHolder:SetActiveTab(menu.Tab);
					
					menu.Panel:RequestFocus();
					
					return menu.Panel, menu.Tab, menu;
				end

				local panel = open(editor);

				local sheet = self.pnlSideTabHolder:AddSheet(name, panel, icon);

				self.pnlSideTabHolder:SetActiveTab(sheet.Tab);

				self.tMenuTabs[name] = sheet;

				panel:RequestFocus();

				return panel, sheet.Tab, sheet;
			end,

			function(self, pTab, bSave)
				if (close) then
					close(self, pTab, bSave);
				end

				self.tMenuTabs[name] = nil;
			end);

			editor.tbRight:SetupButton(name, icon, BOTTOM, function()
				editor:NewTab(name);
			end);
		end
	end);
end
