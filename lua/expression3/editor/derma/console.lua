local PANEL = {};

function PANEL:Init( )
	self.BaseClass.Init(self)

	self.pTextEntry.OnKeyCodeTyped = function( _, code ) end 
end
	--[[self:SetCursor( "beam" )
	
	self.Rows = { "" }
	self.FoldButtons = { }
	self.FoldData = { {0, false, false} }
	self.Undo = { } 
	self.Redo = { } 
	self.PaintRows = { }
	self.Bookmarks = { } 
	
	self.tCursors = { } 
	self.tSelections = { } 
	
	self.Blink = RealTime( ) 
	self.BookmarkWidth = 16
	self.LineNumberWidth = 2 
	self.FoldingWidth = 16 
	self.FontHeight = 0 
	self.FontWidth = 0
	self.CaretRow = 0
	self.LinePadding = 0 
	
	self.Insert = false 
	
	self.pTextEntry = self:Add( "TextEntry" ) 
	self.pTextEntry:SetMultiline( true )
	self.pTextEntry:SetSize( 0, 0 )
	
	self.pTextEntry.m_bDisableTabbing = true // OH GOD YES!!!!! NO MORE HACKS!!!
	self.pTextEntry.OnTextChanged = function( ) self:_OnTextChanged( ) end
	self.pTextEntry.OnKeyCodeTyped = function( _, code ) self:_OnKeyCodeTyped( code ) end 
		
	self.Caret = Vector2( 1, 1 )
	self.Start = Vector2( 1, 1 )
	self.Scroll = Vector2( 1, 1 )
	self.Size = Vector2( 1, 1 )
	
	self.pScrollBar = self:Add( "DVScrollBar" )
	self.pScrollBar:SetUp( 1, 1 ) 
	
	self.pScrollBar.btnUp.DoClick = function ( self ) self:GetParent( ):AddScroll( -4 ) end
	self.pScrollBar.btnDown.DoClick = function ( self ) self:GetParent( ):AddScroll( 4 ) end
	
	function self.pScrollBar:AddScroll( dlta )
		local OldScroll = self:GetScroll( )
		self:SetScroll( self:GetScroll( ) + dlta)
		return OldScroll == self:GetScroll( ) 
	end
	
	function self.pScrollBar:OnMouseWheeled( dlta )
		if not self:IsVisible( ) then return false end
		return self:AddScroll( dlta * -4 )
	end
	
	self.pHScrollBar = self:Add( "GOLEM_HScrollBar")
	self.pHScrollBar:SetUp( 1, 1 ) 
	
	self:SetFont( Golem.Font:GetFont( ) )]]
--end


function PANEL:PrintLine(...)
	local r = {};
	local l = "";
	local c = Color(255, 255, 255);
	
	for k, v in pairs({...}) do
		
		if (istable(v)) then
			c = v;
			continue;
		end
		
		l = l .. v;
		
		r[#r + 1] = {v, c};
	end
	
	self.Rows[#self.Rows + 1] = r
	
	self:SetCaret(Vector2( #self.Rows, 1 ));
	
	self:SetSelection(l .. "\n");
end

function PANEL:AddPrintOut(...)
	local r = {};
	local c = Color(255, 255, 255);
	
	for k, v in pairs({...}) do
		if (istable(v)) then
			c = v;
			r[#r + 1] = v;
			continue;
		end
		
		if (not isstring(v)) then
			v = tostring(v);
		end
		
		local lines = string.Explode("\n", v);
		
		if (#lines == 1) then
			r[#r + 1] = v;
			continue;
		end
		
		r[#r + 1] = lines[1];
		
		self:PrintLine(unpack(r));
		
		if (#lines > 2) then
			for i = 2, #lines - 1 do
				self:PrintLine(c, lines[i]);
			end
		end
		
		r = {c, lines[#lines]}
	end
	
	self:PrintLine(unpack(r));
end

vgui.Register( "GOLEM_Console", PANEL, "GOLEM_Editor" );