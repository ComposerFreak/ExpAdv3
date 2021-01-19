/*============================================================================================================================================
Name: GOLEM_IDE
Author: Oskar
============================================================================================================================================*/

local IsValid = IsValid
local surface = surface
local gui = gui
local math = math

local gradient_up = Material( "vgui/gradient-d" )
local gradient_down = Material( "vgui/gradient-u" )
local MakeFolders

local SetSize = debug.getregistry( ).Panel.SetSize

local PANEL = { }

local sDefaultGateTab = [[
@name "Generic Gate";

/*
	Generic Gate Code.
	
	Wiki:     https://github.com/Rusketh/ExpAdv3/wiki or [?].
	Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2001386268
*/

function void Main() {
	system.print("Hello World");
}

function void Loop() {
	//Same as RunOnTick;
}

event.add("Think", "Loop", Loop);
Main();
]]

local sDefaultScreenTab = [[
@name "Generic Screen";

/*
    Generic Screen Code.
    This code uses another E3-Gates Screen events,
    providing an additonal parameter for the screens entity.

    Wiki:     https://github.com/Rusketh/ExpAdv3/wiki or [?].
    Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2001386268
*/

entity gate = new entity(0);

server {
    event.add("Trigger", "E3", function(string port) {
        if (port == "E3") {
            @input entity E3;
            gate = E3;
            stream bf = net.start("E3");
            bf.writeShort(E3.id());
            net.sendToClients(bf);
        }
    });
}

client {
    net.receive("E3", function(stream bf) {
        gate = new entity(bf.readShort());
    });
    
    function void renderDefault(int w, int h) {
        render.setTexture("omicron/bulb.png");
        render.setColor(new color(255, 255, 255, 255));
        render.drawBox(new vector2(0, 0), new vector2(w, h));
    }
    
    event.add("RenderScreen", "Render", function(int w, int h) {
        renderDefault(w, h);
        event.call(gate, "RenderScreen", w, h, system.getEntity());
    });
}

event.add("UseScreen", "Interact", function(int x, int y, player who) {
    event.call(gate, "Interact", x, y, who, system.getEntity());
});

]]

local function sDefaultScript()
	local screen = GetConVar("gmod_toolmode"):GetString() == "wire_expression3_screen"
	print( "sDefaultScript", screen, GetConVar("gmod_toolmode"):GetString() )
	return screen and sDefaultScreenTab or sDefaultGateTab
end

AccessorFunc( PANEL, "m_sText", 		"Text", 		FORCE_STRING )
AccessorFunc( PANEL, "m_bSizable", 		"Sizable", 		FORCE_BOOL )
AccessorFunc( PANEL, "m_bCanMaximize", 	"CanMaximize", 	FORCE_BOOL )
AccessorFunc( PANEL, "m_bScreenLock", 	"ScreenLock", 	FORCE_BOOL )

AccessorFunc( PANEL, "m_iMinWidth", 	"MinWidth" )
AccessorFunc( PANEL, "m_iMinHeight", 	"MinHeight" )

function PANEL:Init( )
	self.LastClick = 0

	self.FileList = { }
	self.GateTabs = { }

	self.tTabTypes = { }
	self.tMenuTypes = { }

	self.tMenuTabs = { }

	self.bVoice = false

	self:DockPadding( 0, 25, 0, 0 )
	self:ShowCloseButton( true )
	self:SetSizable( true )
	self:SetCanMaximize( false )
	self:SetMinWidth( 800 )
	self:SetMinHeight( 600 )
	self:SetScreenLock( true )
	self:SetKeyboardInputEnabled( true )
	self:SetMouseInputEnabled( true )

	self.pImage = vgui.Create( "DImage", self )
	self.pImage:SetVisible( false )
	self.pImage:SetSize( 0, 0 )

	self.tbRight = vgui.Create( "GOLEM_Toolbar", self )
	self.tbRight:Dock( RIGHT )
	self.tbRight:DockMargin( 0, 5, 5, 5 )
	self.tbRight:SetSize( 24, 24 )

	self.tbBottomHolder = vgui.Create( "DPanel", self )
	self.tbBottomHolder:Dock( BOTTOM )
	self.tbBottomHolder.Paint = function( pnl, w, h ) end
	self.tbBottomHolder:DockMargin( 5, 0, 5, 5 )
	self.tbBottomHolder:SetSize( 24, 24 )


	self.tbBottom = vgui.Create( "GOLEM_Toolbar", self.tbBottomHolder )
	self.tbBottom:Dock( RIGHT )
	self.tbBottom:SetWide( 78 )


	self.btnValidate = vgui.Create( "GOLEM_Button", self.tbBottomHolder )
	self.btnValidate:Dock( FILL )
	self.btnValidate:DockMargin( 0, 0, 5, 0 )
	self.btnValidate:SetTextCentered( true )
	self.btnValidate:SetFading( false )
	self.btnValidate:SetFlat( true )
	self.btnValidate:SetColor( Color( 0, 100, 255 ) )
	self.btnValidate:SetTextColor( Color( 0, 0, 0 ) )
	self.btnValidate:SetText( "Click to validate." )
	self.btnValidate:SetFont( "Trebuchet20" )


	self.btnValidate.DoClick = function( )
		self:DoValidate( true )
	end

	self.btnValidate.DoRightClick = function( )
		local Menu = DermaMenu( )

		Menu:AddOption( "Copy to clipboard", function( )
			SetClipboardText( self.btnValidate:GetText( ) )
		end )

		Menu:AddOption( "Validate Native Output.", function( )
			self:DoValidate(true, nil, true)
		end )

		Menu:Open( )
	end


	self.tbBottom:SetupButton( "Open", 	"fugue/blue-folder-horizontal-open.png", RIGHT, function( )
		local FileMenu = vgui.Create( "GOLEM_FileMenu" )
		FileMenu:SetLoadFile( )

		function FileMenu.DoLoadFile( _, Path, FileName )
			if not FileName:EndsWith( ".txt" ) then
				FileName = FileName .. ".txt"
			end

			self:LoadFile( Path .. "/" .. FileName )

			return true
		end

		FileMenu:MakePopup( )
	end )
	
	self.tbBottom:SetupButton( "Save As", "fugue/disks-black.png", RIGHT, function( ) self:SaveFile( true, true ) end )
	self.tbBottom:SetupButton( "Save", 	"fugue/disk-black.png", RIGHT, function( ) self:SaveFile( true ) end )
	
	self.pVoice = self.tbRight:SetupButton( "Toggle Microphone", "fugue/microphone.png", BOTTOM, function ( ) self:ToggleVoice() end )
	
	self.tbRight:SetupButton( "Increase font size.", "fugue/edit-size-up.png", BOTTOM, function( ) Golem.Font:ChangeFontSize( 1 ) end )
	self.tbRight:SetupButton( "Decrease font size.", "fugue/edit-size-down.png", BOTTOM, function( ) Golem.Font:ChangeFontSize( -1 ) end )
	
	self.tbRight:SetupButton( "Options", "fugue/gear.png", TOP, function( ) self:NewMenuTab( "options" ) end )
	self.tbRight:SetupButton( "Open find & replace", "fugue/magnifier.png", TOP, function( ) self.pnlSearch:Toggle() end )
	
	-- self.debugButton = self.tbRight:SetupStateButton( { 
	-- 	{ sTooltip = "A", sIcon = "fugue/ui-check-box.png" },
	-- 	{ sTooltip = "C", sIcon = "fugue/ui-check-box-mix.png", bNoCycle = false },
	-- 	{ sTooltip = "B", sIcon = "fugue/ui-check-box-uncheck.png" },
	-- }, TOP, function( ) end )
	
	self.searchOptRegex = self.tbRight:SetupCheckBox( "Allow regex.", "Disalow regex.", "fugue/regular-expression.png", "fugue/regular-expression-search-match.png", TOP, function( )  end );
	self.searchOpCase = self.tbRight:SetupCheckBox( "Match case.", "Do not match case.", "fugue/edit-lowercase.png", "fugue/edit-superscript.png", TOP, function( ) end );
	self.searchOptWhole = self.tbRight:SetupCheckBox( "Match whole word.", "No match whole world.", "fugue/selection-select.png", "fugue/selection-select-input.png", TOP, function( ) end );
	self.searchOptSelection = self.tbRight:SetupCheckBox( "Find in selection.", "Find in script.", "fugue/selection.png", "fugue/selection-input.png",  TOP, function( ) end );
	self.searchOptWrap = self.tbRight:SetupCheckBox( "Wrap around", "No wrap around", "fugue/arrow-circle.png", "fugue/arrow-return-000-left.png", TOP, function( ) end );
	self.searchOptions = { self.searchOptRegex, self.searchOpCase, self.searchOptWhole, self.searchOptSelection, self.searchOptWrap };

	-- self.tbRight:SetupButton( "Visit the wiki", 	"fugue/home.png", 		BOTTOM, function( ) end )

	self.pnlSideTabHolder = vgui.Create( "GOLEM_PropertySheet", self );
	self.pnlSideTabHolder:Dock( LEFT )
	self.pnlSideTabHolder:DockMargin( 5, 5, 0, 5 )
	self.pnlSideTabHolder:SetPadding( 0 )
	self.pnlSideTabHolder:SetWide( 265 )
	self.pnlSideTabHolder.btnNewTab:Remove( )

	self.btnHideSidebar = vgui.Create( "GOLEM_ImageButton", self )
	self.btnHideSidebar:Dock( LEFT )
	self.btnHideSidebar:DockMargin( 0, 5, 0, 5 )
	self.btnHideSidebar:DrawButton( false )
	self.btnHideSidebar:SetIconCentered( true )
	self.btnHideSidebar:SetIconFading( false )
	self.btnHideSidebar:SetOutlined( true )
	
	local nSidebar = cookie.GetNumber( "golem_sidebar_state", 1 )
	if nSidebar == 0 then
		self.btnHideSidebar:SetMaterial( Material( "diagona-icons/131.png" ) )
		self.btnHideSidebar.Expanded = false
		self.pnlSideTabHolder:SetWidth( 0 )
	else 
		self.btnHideSidebar:SetMaterial( Material( "diagona-icons/132.png" ) )
		self.btnHideSidebar.Expanded = true
	end
	
	self.btnHideSidebar.DoClick = function( btn )
		if btn.mov then return end
		if btn.Expanded then
			btn.mov = true
			self.pnlSideTabHolder:SizeTo( 0, -1, 0.5, nil, nil, function()
				btn:SetMaterial( Material( "diagona-icons/131.png" ) )
				btn.Expanded = false
				btn.mov = nil
				cookie.Set( "golem_sidebar_state", 0 )
			end )
		else
			btn.mov = true
			self.pnlSideTabHolder:SizeTo( 265, -1, 0.5, nil, nil, function()
				btn:SetMaterial( Material( "diagona-icons/132.png" ) )
				btn.Expanded = true
				btn.mov = nil
				cookie.Set( "golem_sidebar_state", 1 )
			end )
		end
	end
	

	self.pnlTabHolder = vgui.Create( "GOLEM_PropertySheet", self )
	self.pnlTabHolder:Dock( FILL )
	self.pnlTabHolder:DockMargin( 0, 0, 0, 5 )
	self.pnlTabHolder:SetPadding( 0 )

	self.pnlTabHolder.btnNewTab.DoClick = function( btn )
		self:NewTab( "editor", sDefaultScript(), nil, "generic" )
	end

	self.tbConsoleHolder = vgui.Create( "DPanel", self )
	self.tbConsoleHolder.Paint = function( pnl, w, h ) end

	self.tbConsoleEditor = vgui.Create( "GOLEM_Console", self.tbConsoleHolder )--vgui.Create( "GOLEM_Console", self.tbConsoleHolder )
	self.tbConsoleEditor:Dock( BOTTOM )
	self.tbConsoleEditor:SetTall( 125 )
	self.bConsoleVisible = true

	self.pnlConsoleDivider = vgui.Create( "DVerticalDivider", self )
	self.pnlConsoleDivider:SetTop( self.pnlTabHolder )
	self.pnlConsoleDivider:SetBottom( self.tbConsoleEditor )
	self.pnlConsoleDivider:Dock( FILL )
	self.pnlConsoleDivider:DockPadding( 0, 5, 5, 5 )
	self.pnlConsoleDivider:SetTopMin( 200 )
	self.pnlConsoleDivider:SetBottomMin( 50 )


	Golem.Syntax:Create( "console", self.tbConsoleEditor )

	hook.Run( "Expression3.AddGolemTabTypes", self )
	
	--self:AddCustomTab( bScope, sName, fCreate, fClose )
	
	self:AddCustomTab( false, "options", function( self )
		if self.Options then
			self.pnlSideTabHolder:SetActiveTab( self.Options.Tab )
			self.Options.Panel:RequestFocus( )
			return self.Options
		end
		
		local Panel = vgui.Create( "GOLEM_Options" )
		local Sheet = self.pnlSideTabHolder:AddSheet( "", Panel, "fugue/gear.png", function(pnl) self:CloseMenuTab( pnl:GetParent( ), true ) end )
		self.pnlSideTabHolder:SetActiveTab( Sheet.Tab )
		self.Options = Sheet
		Sheet.Panel:RequestFocus( )
		
		return Sheet
	end, function( self )
		self.Options = nil
	end )
	
	if not self:OpenOldTabs( ) then
		self:NewTab( "editor", sDefaultScript() )
	end
	
	self.pnlSearch = vgui.Create("GOLEM_SearchBox", self.pnlTabHolder);
	self.pnlSearch:SetEditor(self);
	self.pnlSearch:SetOptions(self.searchOptions);
	self.pnlSearch:InvalidateLayout( );
	self.pnlSearch:Close(true);
	
	--This was annoying.
	-- self:NewMenuTab( "options" )
	
	Golem.Font.OnFontChange = function( Font, sFontID )
		for i = 1, #self.pnlTabHolder.Items do
			if self.pnlTabHolder.Items[i].Tab.__type ~= "editor" then continue end
			self.pnlTabHolder.Items[i].Panel:SetFont( sFontID )
		end
		self.tbConsoleEditor:SetFont( sFontID )
	end

	local w, h, x, y = cookie.GetNumber( "golem_w", math.min( 1000, ScrW( ) * 0.8 ) ), cookie.GetNumber( "golem_h", math.min( 800, ScrH( ) * 0.8 ) ), cookie.GetNumber( "golem_x", ScrW( ) * 0.1 ), cookie.GetNumber( "golem_y", ScrH( ) * 0.1 )

	if x >= ScrW( ) - self.m_iMinWidth then x = 0 end
	if y >= ScrH( ) - self.m_iMinHeight then y = 0 end

	w = math.Clamp( w, self.m_iMinWidth, ScrW( ) - x )
	h = math.Clamp( h, self.m_iMinHeight, ScrH( ) - y )

	self:SetSize( w, h )
	self:SetPos( x, y )

	local c = cookie.GetNumber( "golem_c", h - 50);
	self.pnlConsoleDivider:SetTopHeight(c)
end

/*---------------------------------------------------------------------------
Console
---------------------------------------------------------------------------*/
function PANEL:HideConsole()
	if (self.bConsoleVisible) then
		self.bConsoleVisible = false
	end
end

function PANEL:ShowConsole()
	if (not self.bConsoleVisible) then
		self.bConsoleVisible = true;
	end
end

function PANEL:PrintLine(...)
	self.tbConsoleEditor:WriteLine("", ...);
end

function PANEL:AddRow(left, ...)
	self.tbConsoleEditor:WriteLine(left, ...);
end

function PANEL:Warning(...)
	self.tbConsoleEditor:Warn(...);
end

function PANEL:Info(...)
	self.tbConsoleEditor:WriteLine({Color(255, 255, 255), "Info:"}, ...);
end

function PANEL:GetConsole(...)
	return self.tbConsoleEditor;
end



/*---------------------------------------------------------------------------
Syntax highlighter
---------------------------------------------------------------------------*/
/*function PANEL:SetSyntaxColorLine( func )
	self.SyntaxColorLine = func
	for i = 1, #self.pnlTabHolder.Items do
		if self.pnlTabHolder.Items[i].Tab.__type == "editor" then
			self.pnlTabHolder.Items[i].Panel.SyntaxColorLine = func
		end
	end
end

function PANEL:GetSyntaxColorLine( )
	return self.SyntaxColorLine
end*/

function PANEL:UpdateSyntaxColors( )
	for i = 1, #self.pnlTabHolder.Items do
		if self.pnlTabHolder.Items[i].Tab.__type == "editor" then
			self.pnlTabHolder.Items[i].Panel.tSyntax:Parse( )
		end
	end
end

/*---------------------------------------------------------------------------
Tab Management 2.0
---------------------------------------------------------------------------*/
function PANEL:AddCustomTab( bScope, sName, fCreate, fClose )
	if bScope then -- Main editor view
		self.tTabTypes[sName] = { Create = fCreate, Close = fClose }
	else -- Sidepanel
		self.tMenuTypes[sName] = { Create = fCreate, Close = fClose }
	end
end

function PANEL:NewTab( sType, ... )
	if sType == "editor" then
		local sCode, sPath, sName, sLanguage, bFormat = unpack{...}
		if sPath and not string.EndsWith( sPath, ".txt" ) then sPath = sPath .. ".txt" end
		if sPath and not string.StartWith( sPath, "golem/" ) then sPath = "golem/" .. sPath end
		if sPath and self.FileList[sPath] then
			self.pnlTabHolder:SetActiveTab( self.FileList[sPath] )
			self.FileList[sPath]:GetPanel( ):RequestFocus( )
			return self.FileList[sPath].Sheet
		end

		if not sName or sName == "" or sName == "generic" then
			sName = sPath and string.match( sPath, "/([^%./]+%.txt)$" ) or "generic"
		end

		sLanguage = sLanguage or "e3"

		local Editor = vgui.Create( "GOLEM_Editor" )
		local Sheet = self.pnlTabHolder:AddSheet( sName or "generic", Editor, "fugue/script.png", function(pnl) self:CloseTab( pnl:GetParent( ), true ) end )
		self.pnlTabHolder:SetActiveTab( Sheet.Tab )
		Sheet.Panel:RequestFocus( )
		Golem.Syntax:Create( sLanguage, Editor )


		Sheet.Tab.__type = "editor"
		Sheet.Tab.__lang = sLanguage
		Sheet.Tab.__shouldsave = sLanguage == "e3"

		Editor.Master = self

		if sPath then
			Sheet.Tab.FilePath = sPath
			self.FileList[sPath] = Sheet.Tab
			Sheet.Tab:SetTooltip( sPath )
		end

		if sCode and sCode ~= "" then
			Editor:SetCode( sCode, bFormat )
		end

		Sheet.Tab.DoRightClick = function( pnl )
			local Menu = DermaMenu( )

			Menu:AddOption( "Close", function( ) self:CloseTab( pnl, false ) end )
			Menu:AddOption( "Close others", function( ) self:CloseAllBut( pnl ) end )
			Menu:AddOption( "Close all tabs", function( ) self:CloseAll( )  end )

			Menu:AddSpacer( )

			if sLanguage == "e3" then
				Menu:AddOption( "Save", function( ) self:SaveFile( pnl.FilePath, false, pnl ) end )
				-- Menu:AddOption( "Save As", function( ) end )
			end

			-- Menu:AddSpacer( )

			-- Menu:AddOption( "New File", function( ) self:NewTab( "editor" ) end )

			Menu:Open( )
		end

		Editor.OnTextChanged = function( tSelection, sText )
			timer.Remove( "Golem_autosave" )
			timer.Create( "Golem_autosave", 0.5, 1, function( )
				local Tab = Sheet.Tab
				if not IsValid( Tab ) or not ispanel( Tab ) or Tab.__type ~= "editor" or not Tab.__shouldsave then return end
				local sCode = Tab:GetPanel( ):GetCode( )
				local sPath = "golem_temp/_autosave_.txt"

				MakeFolders( sPath )
				file.Write( sPath, sCode )
			end )
		end

		return Sheet
	elseif self.tTabTypes[sType] then
		local Sheet = self.tTabTypes[sType].Create( self, ... )
		Sheet.Tab.__type = sType
		return Sheet
	end

	return false
end

function PANEL:CloseTab( pTab, bSave )
	if pTab == true then pTab = self.pnlTabHolder:GetActiveTab( ) end
	if not IsValid( pTab ) or not ispanel( pTab ) then return end

	if pTab.__type == "editor" then
		local Editor = pTab:GetPanel( )

		if bSave and pTab.FilePath and pTab.FilePath ~= "" and pTab.__lang == "e3" then -- Ask about this?
			self:SaveFile( pTab.FilePath, false, pTab, true )
		end

		if pTab.FilePath and self.FileList[pTab.FilePath] then
			self.FileList[pTab.FilePath] = nil
		end

		if pTab.Entity and self.GateTabs[pTab.Entity] then
			self.GateTabs[pTab.Entity] = nil
		end

		if pTab.TempFile then file.Delete( pTab.TempFile ) end

		if Editor.OnTabClose then
			Editor:OnTabClose( bSave, pTab )
		end
	elseif self.tTabTypes[pTab.__type] then
		self.tTabTypes[pTab.__type].Close( self, pTab, bSave )
	end

	self.pnlTabHolder:CloseTab( pTab, true )
end

function PANEL:NewMenuTab( sType, ... )
	if self.tMenuTypes[sType] then
		local Sheet = self.tMenuTypes[sType].Create( self, ... )
		Sheet.Tab.__type = sType
		return Sheet
	end

	return false
end

function PANEL:CloseMenuTab( pTab )
	if pTab == true then pTab = self.pnlSideTabHolder:GetActiveTab( ) end
	if not IsValid(pTab) or not ispanel(pTab) then return end

	if self.tMenuTypes[pTab.__type] then
		self.tMenuTypes[pTab.__type].Close( self, pTab, bSave )
	end

	self.pnlSideTabHolder:CloseTab( pTab, true )
end

function PANEL:CloseAll( )
	for I = #self.pnlTabHolder.Items, 1, -1 do
		self:CloseTab( self.pnlTabHolder.Items[I].Tab, true )
	end
end

function PANEL:CloseAllBut( pTab )
	if not IsValid(pTab) or not ispanel(pTab) then return end
	local found = 0
	while #self.pnlTabHolder.Items > 0 + found do
		if self.pnlTabHolder.Items[found+1].Tab == pTab then
			found = 1
			continue
		end
		self:CloseTab( self.pnlTabHolder.Items[found+1].Tab, false )
	end
end

/*---------------------------------------------------------------------------
Code getting/setting
---------------------------------------------------------------------------*/
function PANEL:SetCode( sCode, pTab )
	pTab = pTab or self.pnlTabHolder:GetActiveTab( )
	pTab:GetPanel( ):SetCode( sCode )
end

function PANEL:GetCode( pTab )
	pTab = pTab or self.pnlTabHolder:GetActiveTab( )
	if not pTab then return end
	if not IsValid(pTab) or not ispanel(pTab) then return end
	if pTab.__type ~= "editor" then return end
	return pTab:GetPanel( ):GetCode( ), pTab.FilePath, pTab:GetName( )
end

function PANEL:SetName( sName, pTab )
	pTab = pTab or self.pnlTabHolder:GetActiveTab( )
	if not pTab then return end
	if not IsValid(pTab) or not ispanel(pTab) then return end
	pTab:SetName( sName )
end

function PANEL:GetName( pTab )
	pTab = pTab or self.pnlTabHolder:GetActiveTab( )
	if not pTab then return end
	if not IsValid(pTab) or not ispanel(pTab) then return end
	return pTab:GetName( )
end

/*---------------------------------------------------------------------------
Save/Load
---------------------------------------------------------------------------*/
local invalid_filename_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["|"] = "",
	["\\"] = "",
	['"'] = "",
	[" "] = "_",
	[":"] = "",
	[","] = "",
}

function MakeFolders( Path )
	local folder, filename, ext = string.match( Path, "^(.+)/([^%.]+)%.(.+)$" )
	file.CreateDir( folder )
end

function PANEL:GetFileCode( sPath, bForce )
	if not string.EndsWith( sPath, ".txt" ) then sPath = sPath .. ".txt" end
	if not string.StartWith( sPath, "golem/" ) then sPath = "golem/" .. sPath end
	if self.FileList[sPath] and not bForce then
		return self:GetCode( self.FileList[sPath] )
	elseif not sPath or file.IsDir( sPath, "DATA" ) then
		return
	else
		local sData = file.Read( sPath ) or ""
		local sTitle, sCode = string.match( sData, "\1(.+)\2(.+)\3" )
		return sCode or sData, sPath, sTitle or string.match( sCode or sData, "@name +\"([^\"]*)\"" ) or "generic"
	end
end

function PANEL:SaveFile( sPath, bSaveAs, pTab, bNoSound )
	if sPath == true then
		pTab = self.pnlTabHolder:GetActiveTab( )
		sPath = pTab.FilePath
	end

	if pTab.__type ~= "editor" or not pTab.__shouldsave then return end

	if bSaveAs or not sPath then
		local FileMenu = vgui.Create( "GOLEM_FileMenu" )
		FileMenu:SetSaveFile( pTab:GetText( ) )

		function FileMenu.DoSaveFile( _, sPath, sFileName )
			if not string.EndsWith( sFileName, ".txt" ) then
				sFileName = sFileName .. ".txt"
			end

			sFileName = string.gsub( sFileName, ".", invalid_filename_chars )
			self:SaveFile( sPath .. "/" .. sFileName, nil, pTab, bNoSound )

			return true
		end

		FileMenu:Center( )
		FileMenu:MakePopup( )

		return true
	end

	if not IsValid(pTab) or not ispanel(pTab) then return end
	if not string.EndsWith( sPath, ".txt" ) then sPath = sPath .. ".txt" end
	if not string.StartWith( sPath, "golem/" ) then sPath = "golem/" .. sPath end

	MakeFolders( sPath )

	local sCode = self:GetCode( pTab )
	local sTitle = string.match( sCode, "@name +\"([^\"]*)\"" )
	if sTitle and sTitle ~= "" then
		pTab:SetName( sTitle )
	end

	file.Write( sPath, sCode)
	pTab.LastEdit = nil
	pTab.SaveTime = CurTime( ) + 0.01

	if not bNoSound then
		surface.PlaySound( "ambient/water/drip3.wav" )
		self.btnValidate:SetText( "Saved as " .. sPath )
	end

	if not pTab.FilePath or string.lower( pTab.FilePath ) ~= string.lower( sPath ) then
		if self.FileList[pTab.FilePath] then
			self.FileList[pTab.FilePath] = nil
		end
		pTab.FilePath = sPath
		self.FileList[pTab.FilePath] = pTab
	end
end

function PANEL:LoadFile( sFile )
	local sCode, sPath, sName = self:GetFileCode( sFile, true )

	if not sCode then return end

	return self:NewTab( "editor", sCode, sPath, sName )
end

local function TempID( )
	local id = { }
	for i = 1, 10 do
		id[i] = math.random( 0, 9 )
	end
	return table.concat( id )
end

function PANEL:SaveTempFile( Tab )
	if not IsValid( Tab ) or not ispanel( Tab ) or Tab.__type ~= "editor" or not Tab.__shouldsave then return end
	local sCode = Tab:GetPanel( ):GetCode( )
	local sPath = Tab.TempFile or "golem_temp/" .. TempID( ) .. ".txt"
	MakeFolders( sPath )
	file.Write( sPath, sCode )
	return sPath
end

function PANEL:LoadTempFile( sPath )
	if not file.Exists( sPath, "DATA" ) then return false end
	local Data = file.Read( sPath )
	local Name, Code = string.match( Data, "\1(.+)\2(.*)\3" )
	self:NewTab( "editor", Code or Data )
	file.Delete( sPath )
	return true
end

function PANEL:SaveTabs( )
	local strtabs = { }
	for i = 1, #self.pnlTabHolder.Items do
		local Tab = self.pnlTabHolder.Items[i].Tab
		if not IsValid( Tab.Panel ) or not Tab.Panel then continue end
		if Tab.Panel.Global then continue end
		if not Tab.__shouldsave then continue end
		local FilePath = self.pnlTabHolder.Items[i].Tab.FilePath
		if not FilePath or FilePath == "" then
			FilePath = self:SaveTempFile( self.pnlTabHolder.Items[i].Tab )
			self.pnlTabHolder.Items[i].Tab.TempFile = FilePath
		else
			if not string.StartWith( FilePath, "golem/" ) then FilePath = "golem/" .. FilePath end
		end
		strtabs[#strtabs+1] = FilePath
	end

	file.Write( "golem_temp/_tabs_.txt", table.concat( strtabs, ";" ) )
end

function PANEL:OpenOldTabs( )
	if not file.Exists( "golem_temp/_tabs_.txt", "DATA" ) then return false end
	-- if not file.Exists( "golem/_tabs_.txt", "DATA" ) then return false end

	local tabs = file.Read( "golem_temp/_tabs_.txt" )
	-- local tabs = file.Read( "golem/_tabs_.txt" )
	if not tabs or tabs == "" then return false end

	tabs = string.Explode( ";", tabs )
	if not tabs or #tabs == 0 then return false end

	local opentabs = false
	for k, v in pairs( tabs ) do
		if v and v ~= "" and  file.Exists( v, "DATA" ) then
			if string.StartWith( v, "golem_temp" ) then
				if self:LoadTempFile( v ) then opentabs = true end
			else
				self:LoadFile( v )
				opentabs = true
			end
		end
	end

	return opentabs
end

/*---------------------------------------------------------------------------
Auto Refresh
---------------------------------------------------------------------------*/
function PANEL:DoAutoRefresh( )
	for File, Tab in pairs( self.FileList ) do

		if file.Exists( File, "DATA" ) then
			local Panel = Tab:GetPanel( )

			if Tab.SaveTime and Tab.SaveTime > CurTime( ) then
				continue
			end

			if not Tab.LastEdit then
				Tab.LastEdit = file.Time( File, "DATA" )
				continue
			end

			if file.Time( File, "DATA" ) ~= Tab.LastEdit then
				Tab.LastEdit = file.Time( File, "DATA" )

				if not self:IsVisible( ) then
					self.ChangeQueue = self.ChangeQueue or { }
					self.ChangeQueue[File] = true
					continue
				end

				local Message = string.format( "File %q has been changed outside of the editor, would you like to refresh?", File )

				local function YesFunc( )
					if not IsValid( Panel ) then return end
					Panel:SetCode( self:GetFileCode( File, true ) )
				end

				local Window = Derma_Query( Message, "Update tab?", "Refresh", YesFunc, "Ignore", function( ) end )

				timer.Simple( 30, function( ) if IsValid( Window ) then Window:Close( ) end end )
			end
		end
	end
end

/*---------------------------------------------------------------------------
Code Validation
---------------------------------------------------------------------------*/
function PANEL:DoValidate( Goto, Code, Native )
	if (self.validator and not self.validator.finished) then
		self.validator.stop();
		self.validator = nil;
	end
	
	Code = Code or self:GetCode( )
	
	if not Code or Code == "" then
		self:OnValidateError( false, {msg = "No code submited, compiler exited.", line = 0, char = 0});
		return false
	end
	
	local cb = function(status, instance)
		if (status and Native) then
			self.btnValidate:SetColor( Color( 50, 255, 50 ) );
			self.btnValidate:SetText( "Generated debug file." );
			
			print( self.validator.state )
			
			local name = instance.directives.name;
			-- local nLua, traceTbl = instance.build();
			local nLua = instance.compiled
			
			self:NewTab( "editor", nLua, false, "DEBUG", "lua", true )
		elseif (status) then
			self.btnValidate:SetColor( Color( 50, 255, 50 ) );
			self.btnValidate:SetText( "Validation sucessful" );
		elseif (instance.state == "internal") then
			self:OnValidateError( false, "Internal error (see console)." )
			self:Warning(3, Color(255, 255, 255), "Internal error: ", instance.msg)
		else
			self:OnValidateError( Goto, instance )
		end
		
		self.validator = nil;
		
		timer.Remove("Golem_Validator");
	end
	
	self.validator = EXPR_LIB.Validate(cb, Code);
	
	self.btnValidate:SetColor( Color( 50, 50, 150 ) );
	self.btnValidate:SetText( "Validating..." );
	
	self.validator.start();
end

function PANEL:OnValidateError( Goto, Thrown )
	local line, char = 0, 0;
	local message = "";
	local File;
	local func;
	
	if ( istable(Thrown) ) then
		message = Thrown.msg;
		
		if (string.sub(message, -1) == ".") then
			message = string.sub(message, 1, -2);
		end
		
		if (Thrown.file) then
			File = Thrown.file;
		end
		
		line = Thrown.line or line;
		char = Thrown.char or char;
	end
	
	local location = "";
	
	if ( Goto ) then
		func = function()
			timer.Simple(0.1, function()
				local inst = self.pnlTabHolder:GetActiveTab( ):GetPanel( );
				inst:RequestFocus();
				inst:SetCaret( Vector2( line, char ) );
			end);
		end;
		
		if line and char then
			location = string.format("at line %i char %i", line, char);
		end
		
		if File then
			location = string.format("%s in %s.txt", location, Thrown.file);
		end
	end
	
	if func then func(); end
	self.btnValidate:SetColor( Color( 255, 50, 50 ) )
	self.btnValidate:SetText( string.format("%s %s", message, location) );
	-- self:Warning( 1, Color(255, 0, 0), "Compiler Error", Color(255, 255, 255), ":\n", message, " ", { func, location } );
	self:Warning(2, Color(255, 0, 0), "Compiler Error", Color(255, 255, 255), ": ", message, " ", { func, location } );
	
	self.validator = nil;
end

/*---------------------------------------------------------------------------
Voice stuff
---------------------------------------------------------------------------*/
local MicMaterialOff = Material( "fugue/microphone.png" )
local MicMaterialOn = Material( "fugue/microphone--plus.png" )

function PANEL:ToggleVoice( )
	self.bVoice = not self.bVoice
	
	if self.bVoice then
		self.pVoice:SetMaterial( MicMaterialOn )
		RunConsoleCommand( "+voicerecord" )
	else
		self.pVoice:SetMaterial( MicMaterialOff )
		RunConsoleCommand( "-voicerecord" )
	end
end

/*---------------------------------------------------------------------------
Misc panel functions
---------------------------------------------------------------------------*/
function PANEL:SetIcon( sIcon )
	self.pImage:SetImage( sIcon )
end

function PANEL:SetMaximized( Bool )
	if not self:GetSizable( ) then return end
	if not self:GetCanMaximize( ) then return end

	if Bool ~= nil then
		if Bool then
			self.LastPos = Vector2( self:GetPos( ) )
			self:SetPos( 0, 0 )
			self:SetSize( ScrW( ), ScrH( ), true )
			self.IsMaximized = true
		else
			self:SetSize( self.RealSize.x, self.RealSize.y, true )
			self:SetPos( self.LastPos( ) )
			self.IsMaximized = false
		end
	else
		if self.IsMaximized == true then
			self:SetSize( self.RealSize.x, self.RealSize.y, true )
			self:SetPos( self.LastPos( ) )
			self.IsMaximized = false
		else
			self.LastPos = Vector2( self:GetPos( ) )
			self:SetPos( 0, 0 )
			self:SetSize( ScrW( ), ScrH( ), true )
			self.IsMaximized = true
		end
	end
end

function PANEL:SetSize( w, h, bool )
	SetSize( self, w, h )

	if not bool then
		self.RealSize = Vector2( w, h )
	end
end

function PANEL:SetWide( n, bool )
	SetSize( self, n, self:GetTall( ) )

	if not bool then
		self.RealSize.x = n
	end
end

function PANEL:SetTall( n, bool )
	SetSize( self, self:GetWide( ), n )

	if not bool then
		self.RealSize.y = n
	end
end

function PANEL:Think( )
	if (input.IsKeyDown( KEY_LCONTROL ) or input.IsKeyDown( KEY_LCONTROL )) and input.IsKeyDown( KEY_B ) then 
		if not self.bVoice then 
			self:ToggleVoice( )
		end 
	elseif self.bVoice then
		self:ToggleVoice( )
	end 
	
	
	self:DoAutoRefresh( )

	if self.IsMoving then
		self:SetCursor( "blank" )
		return
	end

	if self.Sizing then
		if self.Sizing[1] and not self.Sizing[2] then
			self:SetCursor( "sizewe" )
		elseif self.Sizing[2] and not self.Sizing[1] then
			self:SetCursor( "sizens" )
		else
			if self.Sizing.inverted[1] then
				-- left
				if self.Sizing.inverted[2] then
					-- top
					self:SetCursor( "sizenwse" )
				else
					-- bottom
					self:SetCursor( "sizenesw" )
				end
			else
				-- right
				if self.Sizing.inverted[2] then
					-- top
					self:SetCursor( "sizenesw" )
				else
					-- bottom
					self:SetCursor( "sizenwse" )
				end
			end
		end

		return
	end

	if self.Hovered and not self.IsMaximized then
		local x, y = self:CursorPos( )
		if y < 25 and y > 5 and x < self:GetWide( ) - 5 and x > 5 then
			self:SetCursor( "sizeall" )
			return
		end

		if self.m_bSizable then
			-- bottom right
			if x > self:GetWide( ) - 10 and y > self:GetTall( ) - 10 then
				self:SetCursor( "sizenwse" )
				return
			end

			-- top left
			if x < 10 and y < 10 then
				self:SetCursor( "sizenwse" )
				return
			end

			-- bottom left
			if x < 10 and y > self:GetTall( ) - 10 then
				self:SetCursor( "sizenesw" )
				return
			end

			-- top right
			if x > self:GetWide( ) - 10 and y < 10 then
				self:SetCursor( "sizenesw" )
				return
			end

			-- left and right
			if x > self:GetWide( ) - 10 or x < 10 then
				self:SetCursor( "sizewe" )
				return
			end

			-- up and down
			if y > self:GetTall( ) - 10 or y < 10 then
				self:SetCursor( "sizens" )
				return
			end
		end
	end

	self:SetCursor( "arrow" )
end

function PANEL:OnCursorMoved( x, y )
	if self.IsMoving then
		local _x, _y = ( Vector2( gui.MousePos( ) ) - self.LocalPos )( )

		if self.m_bScreenLock then
			x = math.Clamp( _x, 0, ScrW( ) - self:GetWide( ) )
			y = math.Clamp( _y, 0, ScrH( ) - self:GetTall( ) )

			self.LocalPos:Sub( x - _x, y - _y )

			self:SetPos( x, y )
		else
			self:SetPos( _x, _y )
		end

		return true
	end

	if self.Sizing then
		local offset = self.Sizing.offset
		if self.Sizing[1] then
			if self.Sizing.inverted[1] then
				_x = self:LocalToScreen( x, 0 ) - offset.x
				x = -x + self:GetWide( ) + offset.x
				if x > ScrW( ) then
					self:SetWide( x )
					self.x = 0
				elseif x < self.m_iMinWidth then
					self:SetWide( self.m_iMinWidth )
					self.x = _x + ( x - self.m_iMinWidth )
				else
					self:SetWide( x )
					self.x = _x
				end
			else
				x = x - offset.x
				if x > ScrW( ) then
					self:SetWide( ScrW( ) - self.x )
				elseif x < self.m_iMinWidth then
					self:SetWide( self.m_iMinWidth )
				else
					self:SetWide( x )
				end
			end
		end

		if self.Sizing[2] then
			if self.Sizing.inverted[2] then
				_, _y = self:LocalToScreen( 0, y )
				_y = _y - offset.y
				y = -y + self:GetTall( ) + offset.y
				if _y < 0 then
					self:SetTall( y )
					self.y = 0
				elseif y < self.m_iMinHeight then
					self:SetTall( self.m_iMinHeight )
					self.y = _y + ( y - self.m_iMinHeight )
				else
					self:SetTall( y )
					self.y = _y
				end
			else
				y = y - offset.y
				if y > ScrH( ) then
					self:SetTall( ScrH( ) - self.y )
				elseif y < self.m_iMinHeight then
					self:SetTall( self.m_iMinHeight )
				else
					self:SetTall( y )
				end
			end
		end

		return true
	end
end

function PANEL:OnMousePressed( m )
	if m == MOUSE_LEFT then
		local x, y = self:CursorPos( )
		if y < 25 and y > 5 and x < self:GetWide( ) - 5 and x > 5 then
			if self.LastClick + 0.2 > CurTime( ) then
				self:SetMaximized( )
				self.LastClick = CurTime()
				return
			end
			self.LastClick = CurTime()

			if not self.IsMaximized then
				self.IsMoving = true
				self.LocalPos = Vector2( x, y )
				self.EndPos = Vector2( x, y )
				self:MouseCapture( true )
				return
			end
		end

		if self.m_bSizable and not self.IsMaximized then
			local offset = Vector2( self:CursorPos( ) )
			-- bottom right
			if x > self:GetWide( ) - 10 and y > self:GetTall( ) - 10 then
				self.Sizing = { true, true, inverted = { }, offset = offset:Sub( self:GetWide( ), self:GetTall( ) ) }
				self:MouseCapture( true )
				return
			end

			-- top left
			if x < 10 and y < 10 then
				self.Sizing = { true, true, inverted = { true, true }, offset = offset }
				self:MouseCapture( true )
				return
			end

			-- bottom left
			if x < 10 and y > self:GetTall( ) - 10 then
				self.Sizing = { true, true, inverted = { true, false }, offset = offset:Sub( 0, self:GetTall( ) ) }
				self:MouseCapture( true )
				return
			end

			-- top right
			if x > self:GetWide( ) - 10 and y < 10 then
				self.Sizing = { true, true, inverted = { false, true }, offset = offset:Sub( self:GetWide( ), 0 ) }
				self:MouseCapture( true )
				return
			end

			-- right
			if y < self:GetTall( ) and y > 0 and x < self:GetWide( ) and x > self:GetWide( ) - 10 then
				self.Sizing = { true, false, inverted = { false, false }, offset = offset:Sub( self:GetWide( ), 0 ) }
				self:MouseCapture( true )
				return
			end

			-- left
			if y < self:GetTall( ) and y > 0 and x < 10 and x > 0 then
				self.Sizing = { true, false, inverted = { true, false }, offset = offset }
				self:MouseCapture( true )
				return
			end

			-- down
			if y < self:GetTall( ) and y > self:GetTall( ) - 10 and x < self:GetWide( ) and x > 0 then
				self.Sizing = { false, true, inverted = { false, false }, offset = offset:Sub( 0, self:GetTall( ) ) }
				self:MouseCapture( true )
				return
			end

			-- up
			if y < 10 and y > 0 and x < self:GetWide( ) and x > 0 then
				self.Sizing = { false, true, inverted = { false, true }, offset = offset }
				self:MouseCapture( true )
				return
			end
		end
	end
end

function PANEL:OnMouseReleased( m )
	if m == MOUSE_LEFT then
		if self.IsMoving then
			self.IsMoving = false
			self:MouseCapture( false )
			local x,y = self:GetPos( )
			gui.SetMousePos( self.EndPos( x, y ) )
			self.LocalPos = Vector2( 0, 0 )
			self.EndPos = Vector2( 0, 0 )
			self:SetCursor( "sizeall" )
			return
		end

		if self.m_bSizable and self.Sizing then
			self.Sizing = false
			self:MouseCapture( false )
		end
	end
end

function PANEL:Paint( w, h )
	surface.SetDrawColor( 100, 100, 100, 255 )
	-- surface.SetDrawColor( 60, 100, 180, 255 )
	if GOLEM_LIGHT then surface.SetDrawColor(220, 220, 220, 255 ) end
	surface.DrawRect( 0, 0, w, h )

	surface.SetDrawColor( 80, 80, 80, 255 )
	-- surface.SetDrawColor( 40, 80, 160, 255 )
	if GOLEM_LIGHT then surface.SetDrawColor(200, 200, 200, 255 ) end
	surface.SetMaterial( gradient_up )
	surface.DrawTexturedRect( 0, 0, w, 25 )

	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, w, h )
	surface.DrawLine( 0, 25, w, 25 )

	self.pImage:PaintAt( 5, 26/2-self.pImage.ActualHeight/2, self.pImage.ActualWidth, self.pImage.ActualHeight )

	surface.SetFont( "Trebuchet22" )
	local Text = self:GetText( ) or ""
	local x, y = surface.GetTextSize( Text )

	surface.SetTextColor( 220, 220, 220, 255 )
	if GOLEM_LIGHT then surface.SetTextColor( 60, 60, 60, 255 ) end
	surface.SetTextPos( (self.pImage.m_Material and self.pImage.ActualWidth + 5 or 0) + 5, 12.5 - y / 2 )
	surface.DrawText( Text )
end

function PANEL:SaveCoords( )
	cookie.Set( "golem_x", self.x )
	cookie.Set( "golem_y", self.y )
	cookie.Set( "golem_w", self:GetWide( ) )
	cookie.Set( "golem_h", self:GetTall( ) )
	cookie.Set( "golem_c", self.pnlConsoleDivider:GetTopHeight() )
end

function PANEL:ShowCloseButton( Bool )
	if Bool and not IsValid( self.btnClose ) then
		self.btnClose = vgui.Create( "GOLEM_CloseButton", self )
		self.btnClose:SetOffset( -5, 5 )
	elseif not Bool and IsValid( self.btnClose ) then
		self.btnClose:Remove( )
	end
end

function PANEL:Close( )
	self:SaveTabs( )

	self:SaveCoords( )

	self:SetVisible( false )

	if self.bVoice then
		self:ToggleVoice( )
	end

	hook.Run( "Expression3.CloseGolem" )
end

function PANEL:Open( )
	self:SetVisible( true )
	self:MakePopup( )

	if self.ChangeQueue then
		for File, _ in pairs( self.ChangeQueue ) do
			local Message = string.format( "File %q has been changed outside of the editor, would you like to refresh?", File )

			local function YesFunc( )
				if not IsValid( Panel ) then return end
				Panel:SetCode( self:GetFileCode( File, true ) )
			end

			local Window = Derma_Query( Message, "Update tab?", "Refresh", YesFunc, "Ignore", function( ) end )

			timer.Simple( 30, function( ) if IsValid( Window ) then Window:Close( ) end end )
		end

		self.ChangeQueue = nil
	end

	hook.Run( "Expression3.OpenGolem" )
end

vgui.Register( "GOLEM_IDE", PANEL, "EditablePanel" )
