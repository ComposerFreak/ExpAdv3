/*============================================================================================================================================
	Expression-Advanced Derma
==============================================================================================================================================
	Name: EA_FileMenu
	Author: Rusketh
============================================================================================================================================*/
PANEL = { }

function PANEL:Init( )
	self:DockPadding( 0, 26, 0, 0 )
	
	self.CurrentPath = cookie.GetString( "eafilebrowser_cpath", "expadv2" )
	
	self.RightPanel = vgui.Create( "DPanel" )
	self:BuildPathBar( self.RightPanel )
	self:BuildFileList( self.RightPanel )
	self:BuildOpenSave( self.RightPanel )
	
	self.LeftPanel = vgui.Create( "DPanel" )
	self:BuildToolBar( self.LeftPanel )
	self:BuildBrowser( self.LeftPanel )
	
	self.Divider = vgui.Create( "DHorizontalDivider", self )
	self.Divider:Dock( FILL )
	self.Divider:DockMargin( 5, 5, 5, 5 )
	self.Divider:SetDividerWidth( 5 )
	self.Divider:SetLeftMin( 150 )
	self.Divider:SetRightMin( 250 )
	self.Divider:SetLeft( self.LeftPanel )
	self.Divider:SetRight( self.RightPanel )
	self.Divider:SetLeftWidth( cookie.GetNumber( "eafilebrowser_dwidth", 150 ) )
	
	self:SetSizable( true )
	self:SetMinWidth( 500 )
	self:SetMinHeight( 300 )
	
	self:SetSize( cookie.GetNumber( "eafilebrowser_w", 500 ), cookie.GetNumber( "eafilebrowser_h", 300 ) ) 
	self:SetPos( cookie.GetNumber( "eafilebrowser_x", ScrW( ) / 2 - self:GetWide( ) / 2 ), cookie.GetNumber( "eafilebrowser_y", ScrH( ) / 2 - self:GetTall( ) / 2 ) ) 
end

function PANEL:Close( )
	cookie.Set( "eafilebrowser_x", self.x ) 
	cookie.Set( "eafilebrowser_y", self.y ) 
	cookie.Set( "eafilebrowser_w", self:GetWide( ) ) 
	cookie.Set( "eafilebrowser_h", self:GetTall( ) ) 
	cookie.Set( "eafilebrowser_cpath", self.CurrentPath ) 
	cookie.Set( "eafilebrowser_dwidth", self.Divider:GetLeftWidth( ) ) 
	self:Remove( ) 
end

function PANEL:BuildBrowser( Parent )
	self.Browser = vgui.Create( "DTree", Parent )
	self.Browser:Dock( FILL )
	self:RefreshBrowser( )
	return self.Browser
end

function PANEL:RefreshBrowser( )
	self.Browser:Clear( )
	
	self.BrowserNode = self.Browser:AddNode( "Expression Advanced" )
	
	self:AddFolderToBrowser( self.BrowserNode, "expadv2" )
	
	self:SetUpBrowserNode( self.BrowserNode, "expadv2" )
	
	self:ExpandAll( true )
end

function PANEL:AddFolderToBrowser( RootNode, Path )
	local Files, Folders = file.Find( Path .. "/*", "DATA", "nameasc" )
	
	for _, Folder in pairs( Folders ) do
		local Node = RootNode:AddNode( Folder )
		local NewPath = Path .. "/" .. Folder
		
		self:SetUpBrowserNode( Node, NewPath, Path )
		
		self:AddFolderToBrowser( Node, NewPath )
	end
end

function PANEL:SetUpBrowserNode( Node, Path, UpDir )
	Node.Icon:SetImage( "fugue/blue-folder-horizontal.png" )
	
	Node.Expander.DoClick = function( )
		local Expanded = !Node.m_bExpanded
		
		Node:SetExpanded( Expanded )
		
		if !Expanded then
			Node.Icon:SetImage( "fugue/blue-folder-horizontal.png" )
		else
			Node.Icon:SetImage( "fugue/blue-folder-horizontal-open.png" )
		end
	end
	
	function Node.Label.DoDoubleClick( )
		self:OpenFolder( Path, UpDir )
	end
end

function PANEL:BuildToolBar( Parent )
	self.ToolBar = vgui.Create( "DPanel", Parent )
	self.ToolBar:Dock( TOP )
	self.ToolBar:SetTall( 20 )
	
	local Refresh = vgui.Create( "EA_ImageButton", self.ToolBar )
	Refresh:Dock( RIGHT ) 
	Refresh:SetPadding( 5 )
	Refresh:SetTooltip( "Refresh" ) 
	Refresh:SetMaterial( Material( "fugue/arrow-retweet.png" ) )
	self.ToolBar.Refresh = Refresh
	
	local Expand = vgui.Create( "EA_ImageButton", self.ToolBar )
	Expand:Dock( LEFT ) 
	Expand:SetPadding( 5 )
	Expand:SetTooltip( "Expand Nodes" ) 
	Expand:SetMaterial( Material( "fugue/node-insert-child.png" ) )
	self.ToolBar.Expand = Expand
	self.ExpandedNodes = false
	
	function Expand.DoClick( )
		self:ExpandAll( !self.ExpandedNodes )
	end
	
	function Refresh.DoClick( )
		self.Browser:Remove( )
		self.BrowserNode:Remove( )
		self:BuildBrowser( Parent )
	end
	
	--TODO: Make refresh rebuild main element on Parent
	
	return self.ToolBar
end

local Expand

function Expand( Node, Bool )
	Node:SetExpanded( Bool )
	
	if IsValid( Node.ChildNodes ) then
		for _, NextNode in pairs( Node.ChildNodes:GetChildren( ) ) do
			Expand( NextNode, Bool )
		end
	end
end

function PANEL:ExpandAll( Bool )
	self.ExpandedNodes = Bool
	
	Expand( self.BrowserNode, Bool )
	
	local Panel = self.ToolBar.Expand
	
	if !Bool then
		Panel:SetTooltip( "Expand Nodes" ) 
		Panel:SetMaterial( Material( "fugue/node-insert-child.png" ) )
	else
		Panel:SetTooltip( "Colapse Nodes" ) 
		Panel:SetMaterial( Material( "fugue/node-insert-next.png" ) )
	end
end

function PANEL:BuildFileList( Parent )
	self.FileList = vgui.Create( "DListView", Parent )
	self.FileList:Dock( FILL )
	self.FileList:DockMargin( 5, 0, 5, 0 )
	
	self.FileList:SetMultiSelect( false )
	self.FileList:AddColumn( "" ):SetFixedWidth( 20 )
	self.FileList:AddColumn( "Name" ):SetMinWidth( 50 )
	self.FileList:AddColumn( "Size" ):SetFixedWidth( 40 )
	self.FileList:AddColumn( "Modified" ):SetFixedWidth( 80 )
	
	function self.FileList.OnClickLine( _, Line, Bool )
		if Bool then
			if Line.OnDoubleClick and Line.fLastClick and ( SysTime( ) - Line.fLastClick < 0.3 ) then
				Line:OnDoubleClick( )
			elseif Line.OnSingleClick then
				Line:OnSingleClick( )
			end
				
			Line.fLastClick = SysTime( )
		end
	end
	
	function self.FileList:SortByColumn( ColumnID, Desc )
		if ColumnID == 1 then return end 
		
		table.Copy( self.Sorted, self.Lines )
		
		table.sort( self.Sorted, function( a, b ) 
			if ( Desc ) then
				a, b = b, a
			end
			
			if ColumnID == 4 then 
				return a.FileTimeRaw < b.FileTimeRaw 
			end 
			
			if ColumnID == 3 then 
				if a.Isfolder then 
					return string.lower( a:GetColumnText( 2 ) ) < string.lower( b:GetColumnText( 2 ) )
				end 
				return a.FileSizeRaw < b.FileSizeRaw
			end 
			
			if a.IsFolder ~= b.IsFolder then 
				return a.IsFolder and !Desc
			end 
			
			return string.lower( a:GetColumnText( ColumnID ) ) < string.lower( b:GetColumnText( ColumnID ) )
		end )

		self:SetDirty( true )
		self:InvalidateLayout()
	end
	
	self:OpenFolder( "expadv2" )
	
	return self.FileList
end

function PANEL:OpenFolder( Path, UpDir )
	self.CurrentPath = Path
	self.PathEntry:SetText( Path .. "/" )
	
	self.FileList:Clear( )
	
	-- Parent Dir: 
	if UpDir then
		local Parent = self.FileList:AddLine( "", "..", "", "" ) 
		Parent.IsFolder = true 
		self:SetFileIcon( Parent, "fugue/blue-folder-horizontal-open.png" )
	
		function Parent.OnDoubleClick( )
			self:OpenFolder( UpDir, self:GetUpDir( UpDir ) )
		end
	end
	
	-- Files and folders: 
	local Files, Folders = file.Find( Path .. "/*", "DATA" ) 
	
	for _, Folder in pairs( Folders ) do
		local Line = self:AddFile( Folder, Path, "fugue/blue-folder-horizontal.png" )
		Line.IsFolder = true 
		
		function Line.OnDoubleClick( )
			self:OpenFolder( Path .. "/" .. Folder, Path )
		end
	end
	
	for _, File in pairs( Files ) do
		if File:Right( 4 ) == ".txt" then
			local Line = self:AddFile( File, Path, "fugue/script.png" )
			
			function Line.OnSingleClick( )
				self.SavePath:SetText( File )
			end
			
			function Line.OnDoubleClick( )
				local Close = false
				
				if self.IsSaveMenu then
					Close = self:DoSaveFile( Path, File )
				else
					Close = self:DoLoadFile( Path, File )
				end
				
				if Close then
					self:Remove( )
				end
			end
		end
	end
	
	self.FileList.Columns[2]:DoClick( )
end

function PANEL:AddFile( Name, Path, Icon )
	local NewPath = Path .. "/" .. Name
	
	local Bytes = self:ToBytes( file.Size( NewPath, "DATA" ) )
	local Time = os.date( "%d-%m-%Y", file.Time( NewPath, "DATA" ) )
	
	local Line = self.FileList:AddLine( "", Name, Bytes, Time )
	Line.FileSizeRaw = file.Size( NewPath, "DATA" ) 
	Line.FileTimeRaw = file.Time( NewPath, "DATA" ) 
	
	self:SetFileIcon( Line, Icon )
	
	function Line.OnRightClick( )
		if !file.IsDir( NewPath, "DATA" ) then
			-- file.Delete can not delete folder?
			
			local Menu = DermaMenu( )
			
			if self.IsSaveMenu then
				Menu:AddSubMenu( "Over Write" ):AddOption( "Confirm", function( )
					if self:DoSaveFile( self.CurrentPath, Name ) then
						self:Remove( )
					end
				end )
			else
				Menu:AddOption( "Open", function( )
					if self:DoLoadFile( self.CurrentPath, Name ) then
						self:Remove( )
					end
				end )
			end
			
			Menu:AddSubMenu( "Delete" ):AddOption( "Confirm", function( )
				file.Delete( NewPath )
				self:OpenFolder( Path, self:GetUpDir( Path ) )
			end )
			
			Menu:Open( )
		end
		
	end
	
	return Line
end

function PANEL:ToBytes( Bytes )
	if !Bytes or Bytes == 0 then
		return ""
	elseif Bytes < 1024 then
		return Bytes .. "B"
	end
	
	local KBytes = math.ceil( Bytes / 1024 )
	if KBytes < 1024 then
		return KBytes .. "KB"
	end
	
	local MByte = math.ceil( KBytes / 1024 )
	if MBytes < 1024 then
		return MBytes .. "MB"
	end
	
	local GByte = math.ceil( MBytes / 1024 )
	if GBytes < 1024 then
		return GBytes .. "GB"
	end
	
	return "?TB"
end

function PANEL:SetFileIcon( Line, Icon )
	local Img = vgui.Create( "DImage", Line )
	Img:Dock( NODOCK )
	Img:SetImage( Icon )
	Img:SizeToContents( )
	
	Line.Columns[ 1 ] = Img
end

function PANEL:GetUpDir( Path )
	local Split = string.Explode( "/", Path )
	
	if #Split > 1 then
		Split[ #Split ] = nil
		return string.Implode( "/", Split )
	end
end

function PANEL:BuildPathBar( Parent )
	self.PathPanel = vgui.Create( "DPanel", Parent )
	self.PathPanel:Dock( TOP )
	self.PathPanel:DockMargin( 5, 5, 5, 5 )
	
	self.PathEntry = vgui.Create( "DTextEntry", self.PathPanel )
	self.PathEntry:Dock( FILL )
	
	function self.PathEntry.OnEnter( Entry )
		local Path = Entry:GetValue( )
		
		if Path:Right( 1 ) == "/" then
			Path = Path:sub( 1, #Path - 1 )
		end
		
		if Path:Left( 9 ) == "expadv2" then
			if file.IsDir( Path, "DATA" ) then
				self:OpenFolder( Path )
			end
		end
	end
	
	self.Search = vgui.Create( "EA_ImageButton", self.PathPanel )
	self.Search:Dock( RIGHT ) 
	self.Search:SetPadding( 5 )
	self.Search:SetTooltip( "Search (wild:*)" ) 
	self.Search:SetMaterial( Material( "fugue/magnifier--plus.png" ) )
	
	function self.Search.DoClick( )
		local Query = self.PathEntry:GetValue( )
		
		if #Query > 0 then
			self:DoSearch( Query, self.CurrentPath )
		end
	end
	
	return self.PathPanel
end

function PANEL:DoSearch( Query, Path )
	self.FileList:Clear( )
	
	-- Return (/..)
	
	local Parent = self.FileList:AddLine( "", "..", "", "" )
	self:SetFileIcon( Parent, "fugue/blue-folder-horizontal-open.png" )

	function Parent.OnDoubleClick( )
		self:OpenFolder( self.CurrentPath, self:GetUpDir( self.CurrentPath ) )
	end
	
	-- Seach:
	
	local Split = string.Explode( "/", Query )
	if #Split > 1 then
		Query = table.remove( Split, #Split )
		Path = string.Implode( "/", Split )
	end
	
	self:SearchDir( Query, Path )	
end

function PANEL:SearchDir( Query, Path )
	local Files, Folders = file.Find( Path .. "/*" .. Query .. "*", "DATA", "nameasc" )
	
	for _, File in pairs( Files ) do
		local Line = self:AddFile( File, Path, "fugue/script.png" )
		
		function Line.OnSingleClick( )
			self.SavePath:SetText( File )
		end
		
		function Line.OnDoubleClick( )
			local Close = false
			
			if self.IsSaveMenu then
				Close = self:DoSaveFile( Path, File )
			else
				Close = self:DoLoadFile( Path, File )
			end
			
			if Close then
				self:Remove( )
			end
		end
	end
	
	for _, Folder in pairs( Folders ) do
		local Line = self:AddFile( Folder, Path, "fugue/blue-folder-horizontal.png" )
		
		function Line.Action( )
			self:OpenFolder( Path .. "/" .. Folder, Path )
		end
		
		self:SearchDir( Query, Path .. "/" .. Folder .. "/" .. Query )	
	end
end

function PANEL:BuildOpenSave( Parent )
	self.OpenSave = vgui.Create( "DPanel", Parent )
	self.OpenSave:SetTall( 22 )
	self.OpenSave:Dock( BOTTOM )
	self.OpenSave:DockMargin( 5, 5, 5, 5 )
	
	self.SavePath = vgui.Create( "DTextEntry", self.OpenSave )
	self.SavePath:Dock( FILL ) 
	
	self.NewDir = vgui.Create( "EA_ImageButton", self.OpenSave )
	self.NewDir:Dock( RIGHT ) 
	self.NewDir:SetPadding( 5 )
	self.NewDir:SetTooltip( "New Folder" ) 
	self.NewDir:SetMaterial( Material( "fugue/blue-folder--plus.png" ) )
	
	self.NewDir:SetIconFading( false )
	self.NewDir:SetIconCentered( false )
	self.NewDir:SetTextCentered( false )
	self.NewDir:DrawButton( false )
	
	self.SaveOrLoad = vgui.Create( "EA_ImageButton", self.OpenSave )
	self.SaveOrLoad:Dock( RIGHT ) 
	self.SaveOrLoad:SetPadding( 5 )
	
	self.SaveOrLoad:SetIconFading( false )
	self.SaveOrLoad:SetIconCentered( false )
	self.SaveOrLoad:SetTextCentered( false )
	self.SaveOrLoad:DrawButton( false )
	
	function self.NewDir.DoClick( )
		local Path = self.CurrentPath .. "/" .. self.SavePath:GetValue( )
		
		file.CreateDir( Path )
		
		if file.IsDir( Path, "DATA" ) then
			self:OpenFolder( Path, self.CurrentPath )
		end
	end
	
	function self.SavePath.OnEnter( )
		self.SaveOrLoad:DoClick( )
	end
	
	self:SetLoadFile( )
	
	return self.OpenSave
end

function PANEL:SetSaveFile( Default, Path )
	self.IsSaveMenu = true
	
	self:SetText( "Save File:" )
	self.SaveOrLoad:SetTooltip( "Save" ) 
	self.SaveOrLoad:SetMaterial( Material( "fugue/disk.png" ) )
	
	self.SavePath:SetText( Default or "" )
	
	if Path and file.IsDir( Path, "DATA" ) then
		self:OpenFolder( Path )
	end
	
	function self.SaveOrLoad.DoClick( )
		if self:DoSaveFile( self.CurrentPath, self.SavePath:GetValue( ) ) then
			self:Remove( )
		end
	end
end

function PANEL:SetLoadFile( )
	self.IsSaveMenu = false
	
	self:SetText( "Load" )
	self.SaveOrLoad:SetTooltip( "Open" )
	self.SaveOrLoad:SetMaterial( Material( "fugue/blue-folder-horizontal-open.png" ) ) 
	
	function self.SaveOrLoad.DoClick( )
		if self:DoLoadFile( self.CurrentPath, self.SavePath:GetValue( ) ) then
			self:Remove( )
		end
	end
end

function PANEL:DoSaveFile( Path, FileName )
	-- Return true to close!
end

function PANEL:DoLoadFile( Path, FileName )
	-- Return true to close!
end


vgui.Register( "GOLEM_FileMenu", PANEL, "DPanel" )
