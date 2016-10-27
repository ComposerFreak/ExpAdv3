/*============================================================================================================================================
Name: GOLEM_IDE
Author: Oskar 
============================================================================================================================================*/

local ValidPanel = ValidPanel 
local surface = surface 
local gui = gui 
local math = math 

local gradient_up = Material( "vgui/gradient-d" )
local gradient_down = Material( "vgui/gradient-u" )

local SetSize = debug.getregistry( ).Panel.SetSize 

local PANEL = { }

AccessorFunc( PANEL, "m_sText", 		"Text", FORCE_STRING ) 
AccessorFunc( PANEL, "m_bSizable", 		"Sizable", FORCE_BOOL ) 
AccessorFunc( PANEL, "m_bCanMaximize", 	"CanMaximize", FORCE_BOOL ) 
AccessorFunc( PANEL, "m_bScreenLock", 	"ScreenLock", FORCE_BOOL ) 

AccessorFunc( PANEL, "m_iMinWidth", 	"MinWidth" ) 
AccessorFunc( PANEL, "m_iMinHeight", 	"MinHeight" ) 

function PANEL:Init( )
	self.LastClick = 0
	
	self.FileList = { }
	self.GateTabs = { }
	
	self.tTabTypes = { } 
	
	self.bVoice = false 
	
	self:DockPadding( 0, 25, 0, 0 )
	self:ShowCloseButton( true )
	self:SetSizable( true )
	self:SetCanMaximize( false )
	self:SetMinWidth( 800 )
	self:SetMinHeight( 600 ) 
	self:SetScreenLock( true )
	self:SetKeyBoardInputEnabled( true )
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
		
		Menu:Open( ) 
	end
	
	
	self.tbBottom:SetupButton( "Open", 	"fugue/blue-folder-horizontal-open.png", RIGHT, function( ) end )
	self.tbBottom:SetupButton( "Save As", "fugue/disks-black.png", RIGHT, function( ) self:SaveFile( true, true ) end )
	self.tbBottom:SetupButton( "Save", 	"fugue/disk-black.png", RIGHT, function( ) self:SaveFile( true ) end )
	
	self.tbRight:SetupButton( "Options", "fugue/gear.png", BOTTOM, function( ) self:NewTab( "options" ) end )
	
	
	
	-- self.tbRight:SetupButton( "New tab", 	"fugue/script--plus.png", 		TOP, function( ) end )
	-- self.tbRight:SetupButton( "Close tab", 	"fugue/script--minus.png", 		TOP, function( ) end ) 
	-- self.tbRight:SetupButton( "Open user manual", 	"fugue/question.png", 	TOP, function( ) end )
	-- self.tbRight:SetupButton( "Visit the wiki", 	"fugue/home.png", 		BOTTOM, function( ) end )
	
	
	self.pnlTabHolder = vgui.Create( "GOLEM_PropertySheet", self )
	self.pnlTabHolder:Dock( FILL )
	self.pnlTabHolder:DockMargin( 5, 5, 5, 5 )
	self.pnlTabHolder:SetPadding( 0 )
	
	
	-- Default Tab Types init 
	-- self:AddTabType( sName, fCreate, fClose )
	
	self:AddTabType( "editor", function( self, sCode, sPath, sName) 
		if sPath and not string.EndsWith( sPath, ".txt" ) then sPath = sPath .. ".txt" end 
		if sPath and not string.StartWith( sPath, "golem/" ) then sPath = "golem/" .. sPath end
		if sPath and self.FileList[sPath] then 
			self.pnlTabHolder:SetActiveTab( self.FileList[Path] )
			self.FileList[Path]:GetPanel( ):RequestFocus( )
			return
		end 
		
		if not sName or sName == "" then
			sName = Path and string.match( Path, "/([^%./]+)%.txt$" ) or "generic"
		end
		
		local Editor = vgui.Create( "GOLEM_Editor" ) 
		local Sheet = self.pnlTabHolder:AddSheet( sName or "generic", Editor, "fugue/script.png" )
		self.pnlTabHolder:SetActiveTab( Sheet.Tab )
		Sheet.Panel:RequestFocus( )
		
		local func = self:GetSyntaxColorLine( )
		if func ~= nil then
			Sheet.Panel.SyntaxColorLine = func
		end
		
		if sPath then
			Sheet.Tab.FilePath = sPath
			self.FileList[sPath] = Sheet.Tab
		end
		
		if sCode and sCode ~= "" then
			Editor:SetCode( sCode )
		end
		
		return Editor, Sheet.Tab, Sheet
	end, function( self, pTab, bSave ) 
		local Editor = pTab:GetPanel( )
		
		if bSave and pTab.FilePath and pTab.FilePath ~= "" then // Ask about this?
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
	end )
	
	self:AddTabType( "options", function(self) 
		if self.Options then 
			self.pnlTabHolder:SetActiveTab( self.Options.Tab )
			self.Options.Panel:RequestFocus( )
			return 
		end 
		
		local Panel = vgui.Create( "GOLEM_Options" ) 
		local Sheet = self.pnlTabHolder:AddSheet( "options", Panel, "fugue/gear.png" )
		self.pnlTabHolder:SetActiveTab( Sheet.Tab )
		self.Options = Sheet
		Sheet.Panel:RequestFocus( )
		
		Panel.Paint = function( p, w, h )
			surface.SetDrawColor( 30, 30, 30, 255 )
			surface.DrawRect( 0, 0, w, h ) 
		end
		
		return Panel, Sheet.Tab, Sheet 
	end, function(self, pTab, bSave) 
		self.Options = nil
	end )
	
	
	
	
	
	
	-- self.pnlTabHolder:AddSheet( "Test 1", vgui.Create("GOLEM_Editor"), "fugue/script.png" )
	-- self.pnlTabHolder:AddSheet( "Test 2", vgui.Create("GOLEM_Editor"), "fugue/script.png" )
	-- self.pnlTabHolder:AddSheet( "Test 3", vgui.Create("GOLEM_Editor"), "fugue/script.png" )
	
	-- self:NewTab( "editor", self:GetFileCode( "example 1" ) )
	-- self:NewTab( "editor", self:GetFileCode( "example 1" ) )
	self:LoadFile( "example 1" ) 
	-- self:OpenOldTabs( )
	
	self:NewTab( "options" )
	
	-- for i = 1, 30 do
	-- 	self.pnlTabHolder:AddSheet( "Test " .. i, vgui.Create("GOLEM_Editor"), "fugue/script.png" )
	-- end
	
	//print( utf8.codepoint( "Мёнём", 1, -1 ) )
	
	Golem.Font.OnFontChange = function( Font, sFontID )
		for i = 1, #self.pnlTabHolder.Items do
			if not self.pnlTabHolder.Items[i].Tab.__type == "editor" then continue end 
			self.pnlTabHolder.Items[i].Panel:SetFont( sFontID )
		end
	end 
	
	local w, h, x, y = cookie.GetNumber( "golem_w", math.min( 1000, ScrW( ) * 0.8 ) ), cookie.GetNumber( "golem_h", math.min( 800, ScrH( ) * 0.8 ) ), cookie.GetNumber( "golem_x", ScrW( ) * 0.1 ), cookie.GetNumber( "golem_y", ScrH( ) * 0.1 ) 
	
	if x >= ScrW( ) - m_iMinWidth then x = 0 end 
	if y >= ScrH( ) - m_iMinHeight then y = 0 end 
	
	w = math.Clamp( w, m_iMinWidth, ScrW( ) - x )
	h = math.Clamp( h, m_iMinHeight, ScrH( ) - y )
	
	self:SetSize( w, h )
	self:SetPos( x, y )
end

/*---------------------------------------------------------------------------
Syntax highlighter
---------------------------------------------------------------------------*/
function PANEL:SetSyntaxColorLine( func )
	self.SyntaxColorLine = func
	for i = 1, #self.pnlTabHolder.Items do
		if self.pnlTabHolder.Items[i].Tab.__type == "editor" then 
			self.pnlTabHolder.Items[i].Panel.SyntaxColorLine = func
		end 
	end
end

function PANEL:GetSyntaxColorLine( ) 
	return self.SyntaxColorLine 
end

/*---------------------------------------------------------------------------
Tab Management
---------------------------------------------------------------------------*/
local function DoRightClick( self )
	local Menu = DermaMenu( )
	
	Menu:AddOption( "Close", function( ) self.Editor:CloseTab( self, false ) end )
	Menu:AddOption( "Close others", function( ) self.Editor:CloseAllBut( self ) end )
	Menu:AddOption( "Close all tabs", function( ) self.Editor:CloseAll( )  end )
	
	Menu:AddSpacer( )
	
	Menu:AddOption( "Save", function( ) self.Editor:SaveFile( self.FilePath, false, self ) end )
	-- Menu:AddOption( "Save As", function( ) end )
	
	Menu:AddSpacer( )
	
	Menu:AddOption( "New File", function( ) self.Editor:NewTab( "editor" ) end )
	
	Menu:Open( )
end

function PANEL:AddTabType( sName, fCreate, fClose )
	self.tTabTypes[sName] = { NewTab = fCreate, CloseTab = fClose } 
end

function PANEL:NewTab( sType, ... )
	if self.tTabTypes[sType] then 
		local pPanel, pTab, tSheet = self.tTabTypes[sType].NewTab( self, ... ) 
		pTab.__type = sType
		
		tSheet.Tab.DoRightClick = DoRightClick
		tSheet.Tab.Editor = self
		
		return pPanel, pTab, tSheet 
	else 
		error( 2, "No such tab type!" ) 
	end 
end

function PANEL:CloseTab( pTab, bSave ) 
	if pTab == true then pTab = self.pnlTabHolder:GetActiveTab( ) end
	if not ValidPanel( pTab ) then return end
	
	self.tTabTypes[pTab.__type].CloseTab( self, pTab, bSave )
	
	self.pnlTabHolder:CloseTab( pTab, true )
end 

function PANEL:CloseAll( )
	for I = #self.pnlTabHolder.Items, 1, -1 do
		self:CloseTab( self.pnlTabHolder.Items[I].Tab, true )
	end 
end

function PANEL:CloseAllBut( pTab )
	if not ValidPanel( pTab ) then return end
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
	return pTab:GetPanel( ):GetCode( ), pTab.FilePath, pTab:GetName( ) 
end

function PANEL:SetName( sName, pTab )
	pTab = pTab or self.pnlTabHolder:GetActiveTab( )
	if not pTab then return end
	pTab:SetName( sName )
end 

function PANEL:GetName( pTab )
	pTab = pTab or self.pnlTabHolder:GetActiveTab( )
	if not pTab then return end
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

local function MakeFolders( Path )
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
		return sCode or sData, sPath, sTitle or "generic" 
	end 
end

function PANEL:SaveFile( sPath, bSaveAs, pTab, bNoSound ) 
	if sPath == true then
		pTab = self.pnlTabHolder:GetActiveTab( )
		sPath = pTab.FilePath
	end
	
	if bSaveAs or not sPath then
		// TODO: Actually make this
		
		/*local FileMenu = vgui.Create( "EA_FileMenu" )
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
		FileMenu:MakePopup( )*/
		
		return true
	end
	
	if not ValidPanel( pTab ) then return end
	if not string.EndsWith( sPath, ".txt" ) then sPath = sPath .. ".txt" end 
	if not string.StartWith( sPath, "golem/" ) then sPath = "golem/" .. sPath end
	
	MakeFolders( sPath )
	
	file.Write( sPath, "\1".. (pTab:GetText( ) == "generic" and "generic" or pTab:GetText( )) .. "\2" .. self:GetCode( pTab ) .. "\3" )
	pTab.LastEdit = nil //file.Time( sPath, "DATA" ) 
	pTab.SaveTime = CurTime( ) + 0.01
	
	if not bNoSound then
		surface.PlaySound( "ambient/water/drip3.wav" )
		self.btnValidate:SetText( "Saved as " .. sPath ) 
	end
	if not pTab.FilePath or string.lower( pTab.FilePath ) ~= string.lower( sPath ) then
		if self.FileTabs[pTab.FilePath] then 
			self.FileTabs[pTab.FilePath] = nil 
		end 
		pTab.FilePath = sPath
		self.FileTabs[pTab.FilePath] = pTab
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
	if not ValidPanel( Tab ) or not Tab.__type == "editor" then return end
	local sCode = Tab:GetPanel( ):GetCode( )
	local sPath = Tab.TempFile or "golem_temp/" .. TempID( ) .. ".txt"
	MakeFolders( sPath )
	file.Write( sPath, "\1" .. Tab:GetText( ) .. "\2" .. sCode .. "\3" )
	return sPath
end

function PANEL:LoadTempFile( sPath )
	if not file.Exists( sPath, "DATA" ) then return false end 
	local Data = file.Read( sPath ) 
	local Name, Code = string.match( Data, "\1(.+)\2(.*)\3" )
	self:NewTab( "editor", Code or Data, nil, Name ) 
	file.Delete( sPath ) 
	return true 
end

function PANEL:SaveTabs( )
	local strtabs = { }
	for i = 1, #self.pnlTabHolder.Items do 
		if self.pnlTabHolder.Items[i].Tab.Panel.Global then continue end 
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
	-- if not file.Exists( "golem_temp/_tabs_.txt", "DATA" ) then return false end 
	if not file.Exists( "golem/_tabs_.txt", "DATA" ) then return false end 
	
	-- local tabs = file.Read( "golem_temp/_tabs_.txt" )
	local tabs = file.Read( "golem/_tabs_.txt" )
	if not tabs or tabs == "" then return false end
	
	tabs = string.Explode( ";", tabs )
	if not tabs or #tabs == 0 then return false end
	
	local opentabs = false
	for k, v in pairs( tabs ) do
		if v and v ~= "" then
			if file.Exists( v, "DATA" ) then
				if string.StartWith( v, "golem_temp" ) then
					if self:LoadTempFile( v ) then opentabs = true end 
				else 
					self:LoadFile( v )
					opentabs = true
				end
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
function PANEL:DoValidate( Goto, Code )
	--[[Code = Code or self:GetCode( )
	
	if not Code or Code == "" then
		self:OnValidateError( false,"No code submited, compiler exited.")
		return false
	end
	
	local Status, Instance, Instruction = EXPADV.SolidCompile(Code, {})
	
	if not Status then
		self:OnValidateError(Goto, Instance)
		return false
	end
	
	self.btnValidate:SetColor( Color( 50, 255, 50 ) )
	self.btnValidate:SetText( "Validation Successful!" )

	return true
	]]

	return EXPR_LIB.ValidateAndDebug(this, Goto, Code);
end

function PANEL:OnValidateError( Goto, Error )
	if Goto then
		local Row, Col = Error:match( "at line ([0-9]+), char ([0-9]+)$" )
		if not Row then Row, Col = Error:match( "at line ([0-9]+)$" ), 1 end
		
		if Row then
			Row, Col = tonumber( Row ), tonumber( Col )
			if Row < 1 or Col < 1 then 
				Error = string.match( Error, "^(.-)at line [0-9]+" ) .. "| Invalid trace"
			else 
				self.pnlTabHolder:GetActiveTab( ):GetPanel( ):SetCaret( Vector2( Row, Col ) )
			end 
		end
	end
	
	self.btnValidate:SetText( Error )
	self.btnValidate:SetColor( Color( 255, 50, 50 ) )
end

/*---------------------------------------------------------------------------
Voice stuff
---------------------------------------------------------------------------*/
local MicMaterial = Material( "fugue/microphone.png" )

function PANEL:ToggleVoice( )
	self.bVoice = not self.bVoice
	
	if self.bVoice then
		RunConsoleCommand( "+voicerecord" )
	else
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
	surface.DrawRect( 0, 0, w, h )
	
	surface.SetDrawColor( 80, 80, 80, 255 )
	-- surface.SetDrawColor( 40, 80, 160, 255 )
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
	surface.SetTextPos( (self.pImage.m_Material and self.pImage.ActualWidth + 5 or 0) + 5, 12.5 - y / 2 )
	surface.DrawText( Text )
end

function PANEL:SaveCoords( )
	cookie.Set( "golem_x", self.x )
	cookie.Set( "golem_y", self.y )
	cookie.Set( "golem_w", self:GetWide( ) )
	cookie.Set( "golem_h", self:GetTall( ) )
end

function PANEL:ShowCloseButton( Bool )
	if Bool and not ValidPanel( self.btnClose ) then 
		self.btnClose = vgui.Create( "GOLEM_CloseButton", self )
		self.btnClose:SetOffset( -5, 5 )
	elseif not Bool and ValidPanel( self.btnClose ) then 
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
	
	-- Temp
	-- self:Remove( )
end

vgui.Register( "GOLEM_IDE", PANEL, "EditablePanel" )