/*============================================================================================================================================
	Name: GOLEM_Toolbar
	Author: Oskar
============================================================================================================================================*/

local PANEL = { }

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
	btn:SetStyleNames( { "toolbar-btn" } )
	
	if fDoClick then
		btn.DoClick = fDoClick
	end

	return btn
end

function PANEL:SetupStateButton( tStates, nDock, fStateChanged )
	local btn = self:Add( "GOLEM_StateButton" ) 
	btn:Dock( nDock )
	btn:SetPadding( 5 )
	btn:SetStyleNames( { "toolbar-btn" } )
	btn:SetFlat( true )
	btn:SetIconFading( false )
	btn:DrawButton( true )
	
	for k, v in pairs( tStates ) do 
		btn:AddState( v.sIcon, v.sText, v.sTooltip or v.sText, v.tValue, v.bNoCycle )
	end 
	
	btn:SetState( 1 )
	
	if fStateChanged then 
		btn.StateChanged = fStateChanged
	end 
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
	btn:SetStyleNames( { "toolbar-btn" } )
	btn:SetValue( true, true )
	btn:SetValue( false, true )
	
	function btn:ChangedValue(v)
		btn:SetTooltip( v and sOn or sOff );
		if fChangedValue then fChangedValue(btn, v); end
	end
	
	btn:ToggleForwards()
	
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
	surface.SetDrawColor( Golem.Style:GetColor( "toolbar-bg" ))
	surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "GOLEM_Toolbar", PANEL, "Panel" )