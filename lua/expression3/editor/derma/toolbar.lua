/*============================================================================================================================================
	Name: GOLEM_Toolbar
	Author: Oskar
============================================================================================================================================*/

local PANEL = { }

function PANEL:Init( )
	-- self.btnSave = self:SetupButton( "Save", "fugue/disk-black.png", LEFT )
	-- self.btnSaveAs = self:SetupButton( "Save As", "fugue/disks-black.png", LEFT )
	-- self.btnOpen = self:SetupButton( "Open", "fugue/blue-folder-horizontal-open.png", LEFT )
	-- self.btnNewTab = self:SetupButton( "New tab", "fugue/script--plus.png", LEFT )
	-- self.btnCloseTab = self:SetupButton( "Close tab", "fugue/script--minus.png", LEFT )

	-- self.btnOptions = self:SetupButton( "Options", "fugue/gear.png", RIGHT )
	-- self.btnHelp = self:SetupButton( "Open user manual", "fugue/question.png", RIGHT )
	-- self.btnWiki = self:SetupButton( "Visit the wiki", "fugue/home.png", RIGHT )
end


function PANEL:SetupButton( sName, sMaterial, nDock, fDoClick )
	local btn = self:Add( "GOLEM_ImageButton" )
	btn:Dock( nDock )
	btn:SetPadding( 5 )
	btn:SetIconFading( false )
	btn:SetIconCentered( false )
	btn:SetTextCentered( false )
	btn:DrawButton( true )
	btn:SetTooltip( sName )
	btn:SetMaterial( Material( sMaterial ) )
	btn:SetFlat( true )
	btn:SetColor( Color( 70, 70, 70 ) )
	-- btn:SetColor( Color( 40, 80, 160 ) )

	if fDoClick then
		btn.DoClick = fDoClick
	end

	return btn
end

function PANEL:SetupCheckBox( sOn, sOff, sMaterialT, sMaterialC, nDock, fChangedValue )
	local btn = self:Add( "GOLEM_CheckBox" )
	btn:Dock( nDock )
	btn:SetPadding( 5 )
	btn:SetIconFading( false )
	btn:SetIconCentered( false )
	btn:SetTextCentered( false )
	btn:DrawButton( true )
	btn:SetTooltip( sOff )
	btn:SetTick( Material( sMaterialT ) )
	btn:SetCross( Material( sMaterialC ) )
	btn:SetFlat( true )
	btn:SetColor( Color( 70, 70, 70 ) )
	-- btn:SetColor( Color( 40, 80, 160 ) )

	function btn:ChangedValue(v)
		btn:SetTooltip( v and sOn or sOff );
		if fChangedValue then fChangedValue(btn, v); end
	end

	return btn
end


function PANEL:SetupTextBox( sName, sMaterial, nDock, fDoClick, fChangedValue )
	local txt = self:Add( "GOLEM_TextEntry" );

	txt:SetFlat( true )
	txt:SetTooltip( sName );
	txt:SetMaterial( Material( sMaterial ) );
	txt:Dock( nDock );

	if fChangedValue then txt.OnValueChange = fChangedValue; end

	if fDoClick then txt.DoClick = fDoClick; end

	return txt;
end

function PANEL:Paint( w, h )
	surface.SetDrawColor( 70, 70, 70, 255 )
	-- surface.SetDrawColor( 40, 80, 160, 255 )
	surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "GOLEM_Toolbar", PANEL, "Panel" )