/*=============================================================================
	Golem Editor
	Author: Oskar
	Credits: 
		Andreas "Syranide" Svensson for making the E2 editor
		Rusketh and Divran for all the help making this a reality
=============================================================================*/

local math_max 						= math.max 
local math_min 						= math.min 
local math_floor 					= math.floor 
local math_ceil 					= math.ceil 

local string_find 					= string.find 
local string_rep 					= string.rep 
local string_sub 					= string.sub 
local string_gsub 					= string.gsub 
local string_Explode 				= string.Explode 
local string_len 					= string.len 
local string_gmatch 				= string.gmatch 
local string_match 					= string.match 

local table_remove 					= table.remove 
local table_insert 					= table.insert 
local table_concat 					= table.concat
local table_Count 					= table.Count 
local table_KeysFromValue 			= table.KeysFromValue 

local surface_SetFont 				= surface.SetFont 
local surface_DrawRect 				= surface.DrawRect 
local surface_DrawOutlinedRect 		= surface.DrawOutlinedRect
local surface_DrawText 				= surface.DrawText 
local surface_GetTextSize 			= surface.GetTextSize 
local surface_SetDrawColor 			= surface.SetDrawColor 
local surface_SetTextColor 			= surface.SetTextColor 
local surface_SetTextPos 			= surface.SetTextPos 
local surface_SetMaterial 			= surface.SetMaterial
local surface_DrawTexturedRect 		= surface.DrawTexturedRect

local input_IsKeyDown 				= input.IsKeyDown
local input_IsMouseDown 			= input.IsMouseDown

local draw_SimpleText 				= draw.SimpleText
local draw_WordBox 					= draw.WordBox

local BookmarkMaterial 				= Material( "diagona-icons/152.png" )

local C_white = Color( 255, 255, 255 ) 
local C_gray = Color( 160, 160, 160 ) 

local Golem = Golem
local PANEL = { }

function PANEL:Init( )
	self:SetCursor( "beam" )
	
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
	
	self:SetFont( Golem.Font:GetFont( ) )
end

function PANEL:RequestFocus( )
	self.pTextEntry:RequestFocus( )
end

function PANEL:OnGetFocus( )
	self.pTextEntry:RequestFocus( )
end

/*---------------------------------------------------------------------------
Font
---------------------------------------------------------------------------*/
function PANEL:SetFont( sFont ) 
	self.Font = sFont 
	surface_SetFont( sFont )
	self.FontWidth, self.FontHeight = surface_GetTextSize( " " )
	
	self.FoldingWidth = self.FontHeight 
	for k, v in pairs( self.FoldButtons ) do
		if ValidPanel( v ) then 
			v:SetSize( self.FontHeight, self.FontHeight )
		end 
	end
	
	self:InvalidateLayout( true ) 
end 

/*---------------------------------------------------------------------------
TextEntry hooks
---------------------------------------------------------------------------*/

local AutoParam = {
	["{"] = { "}", true },
	["["] = { "]", true },
	["("] = { ")", true },
	['"'] = { '"', false },
	["'"] = { "'", false },
}

local SpecialCase = {
	["}"] = true, 
	["]"] = true, 
	[")"] = true, 
	['"'] = true, 
	["'"] = true, 
}

local SpecialKeys = { }

function PANEL:Think( )
	if not self.pTextEntry:HasFocus( ) then return end 
	for I = 1, 12 do
		local Enum = _G[ "KEY_F" .. I ]
		local State = input_IsKeyDown( Enum )
		
		if State ~= SpecialKeys[ Enum ] then
			SpecialKeys[ Enum ] = State
			if State then self:_OnKeyCodeTyped( Enum ) end
		end
	end
	
	local x, y = self:CursorPos( )
	if x < self.LinePadding then
		self:SetCursor( "arrow" )
		return
	end
	
	self:SetCursor( "beam" )
end

function PANEL:_OnKeyCodeTyped( code ) 
	self.Blink = RealTime( )
	
	local alt = input_IsKeyDown( KEY_LALT ) or input_IsKeyDown( KEY_RALT )
	if alt then return end
	
	local shift = input_IsKeyDown( KEY_LSHIFT ) or input_IsKeyDown( KEY_RSHIFT )
	local control = input_IsKeyDown( KEY_LCONTROL ) or input_IsKeyDown( KEY_RCONTROL )
	
	-- allow ctrl-ins and shift-del ( shift-ins, like ctrl-v, is handled by vgui )
	if not shift and control and code == KEY_INSERT then
		shift, control, code = true, false, KEY_C
	elseif shift and not control and code == KEY_DELETE then
		shift, control, code = false, true, KEY_X
	end 
	
	local tFolds = self:ExpandAll( )
	
	if control then
		if code == KEY_A then
			self:SelectAll( ) 
		elseif code == KEY_Z then
			self:DoUndo( )
		elseif code == KEY_Y then
			self:DoRedo( )
		elseif code == KEY_X then
			if self:HasSelection( ) then
				local clipboard = self:GetSelection( )
				clipboard = string_gsub( clipboard, "\n", "\r\n" )
				SetClipboardText( clipboard )
				self:FoldAll( tFolds )
				self:SetSelection( "" )
				tFolds = self:ExpandAll( )
			end
		elseif code == KEY_C then
			if self:HasSelection( ) then
				local clipboard = self:GetSelection( )
				clipboard = string_gsub( clipboard, "\n", "\r\n" )
				SetClipboardText( clipboard )
			end
		elseif code == KEY_UP then
			if shift then 
				if self:HasSelection( ) then 
					local start, stop = self:MakeSelection( self:Selection( ) )
					if start.x > 1 then 
						local data = table_remove( self.Rows, start.x - 1 ) 
						table_insert( self.Rows, stop.x, data ) 
						self.Start:Add( -1, 0 )
						self.Caret:Add( -1, 0 )
						self.PaintRows = { }
						self:ScrollCaret( )
					end 
				elseif self.Caret.x > 1 then 
					local data = table_remove( self.Rows, self.Caret.x ) 
					self:SetCaret( self.Caret:Add( -1, 0 ) ) 
					table_insert( self.Rows, self.Caret.x, data )
					self.PaintRows = { }
				end 
			else 
				self.Scroll.x = self.Scroll.x - 1
				if self.Scroll.x < 1 then self.Scroll.x = 1 end
				self.pScrollBar:SetScroll( self.Scroll.x -1 )
			end 
		elseif code == KEY_DOWN then
			if shift then 
				if self:HasSelection( ) then 
					local start, stop = self:MakeSelection( self:Selection( ) )
					if stop.x < #self.Rows then 
						local data = table_remove( self.Rows, stop.x + 1 ) 
						table_insert( self.Rows, start.x, data ) 
						self.Start:Add( 1, 0 )
						self.Caret:Add( 1, 0 )
						self.PaintRows = { }
						self:ScrollCaret( )
					end 
				elseif self.Caret.x < #self.Rows then 
					local data = table_remove( self.Rows, self.Caret.x ) 
					self:SetCaret( self.Caret:Add( 1, 0 ) ) 
					table_insert( self.Rows, self.Caret.x, data )
					self.PaintRows = { }
				end 
			else 
				self.Scroll.x = self.Scroll.x + 1
				self.pScrollBar:SetScroll( self.Scroll.x -1 )
			end 
		elseif code == KEY_LEFT then
			if self:HasSelection( ) and not shift then
				self.Start = self.Caret:Clone( )
			else
				self.Caret = self:wordLeft( self.Caret )
			end
		
			self:ScrollCaret( )
		
			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection( ) and not shift then
				self.Start = self.Caret:Clone( )
			else
				self.Caret = self:wordRight( self.Caret )
			end
		
			self:ScrollCaret( )
		
			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_HOME then
			self.Caret = Vector2( 1, 1 )
			
			self:ScrollCaret( )
			
			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_END then
			self.Caret = Vector2( #self.Rows, 1 )
			
			self:ScrollCaret( )
			
			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_D then
			-- Save current selection
			local old_start = self.Start:Clone( )
			local old_end = self.Caret:Clone( )
			local old_scroll = self.Scroll:Clone( )

			local str = self:GetSelection( )
			if ( str != "" ) then -- If you have a selection
				self:SetSelection( str:rep( 2 ) ) -- Repeat it
			else -- If you don't
				-- Select the current line
				self.Start = Vector2( self.Start.x, 1 )
				self.Caret = Vector2( self.Start.x, #self.Rows[self.Start.x] + 1 )
				-- Get the text
				local str = self:GetSelection( )
				-- Repeat it
				self:SetSelection( str .. "\n" .. str )
			end

			-- Restore selection
			self.Caret = old_end
			self.Start = old_start
			self.Scroll = old_scroll
			self:ScrollCaret( )
		elseif code == KEY_F2 then
			self:Bookmark( )
		end 
	else
		if code == KEY_ENTER then 
			local Line = self.Rows[self.Caret.x] 
			local Count = string_len( string_match( string_sub( Line, 1, self.Caret.y - 1 ), "^%s*" ) ) 
			
			if string_match( "{" .. Line .. "}", "^%b{}.*$" ) then 
				if string_match( string_sub( Line, 1, self.Caret.y - 1 ), "{$" ) and string_match( string_sub( Line, self.Caret.y, -1 ), "^}" ) then 
					local Caret = self:SetArea( self:Selection( ), "\n" .. string_rep( "    ", math_floor( Count / 4 ) + 1 )  .. "\n" .. string_rep( "    ", math_floor( Count / 4 ) ) )  
					
					Caret.y = 1 
					Caret = self:MovePosition( Caret, -1 ) 
					self:SetCaret( Caret )
				-- elseif string_match( string_sub( Line, 1, self.Caret.y - 1 ), "{") then 
				elseif string_match( "{" .. string_sub( Line, 1, self.Caret.y - 1 ) .. "}", "^%b{}.*$" ) then 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  )
				else 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  .. "    " )
				end 
			else 
				if string_match( string_sub( Line, 1, self.Caret.y - 1 ), "{") then 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  .. "    " )
				else 
					self:SetSelection( "\n" .. string_rep( "    ", math_floor( Count / 4 ) )  )
				end 
			end 
			self:ScrollCaret()
		elseif code == KEY_UP then 
			if self.Caret.x > 1 then
				self.Caret.x = self.Caret.x - 1
				
				if istable( self.Rows[self.Caret.x] ) and self.Rows[self.Caret.x].Primary ~= self.Caret.x then 
					self.Caret.x = self.Rows[self.Caret.x].Primary 
				end
				
				if self.Caret.x < 1 then self.Caret.x = 1 end 
				
				local length = #self.Rows[self.Caret.x]
				if self.Caret.y > length + 1 then
					self.Caret.y = length + 1
				end
			end
			
			self:ScrollCaret( )
			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_DOWN then 
			if self.Caret.x < #self.Rows then
				self.Caret.x = self.Caret.x + 1
				
				if istable( self.Rows[self.Caret.x] ) and self.Rows[self.Caret.x].Primary ~= self.Caret.x then 
					self.Caret.x = #self.Rows[self.Caret.x] + self.Rows[self.Caret.x].Primary 
				end 
				
				if self.Caret.x > #self.Rows then self.Caret.x = #self.Rows end 
				
				local length = #self.Rows[self.Caret.x]
				if self.Caret.y > length + 1 then
					self.Caret.y = length + 1
				end
			end
			
			self:ScrollCaret( )
			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_LEFT then 
			self.Caret = self:MovePosition( self.Caret, -1 )
			self:ScrollCaret( )
			if not shift then
				self.Start = self.Caret:Clone( )
			end 
		elseif code == KEY_RIGHT then
			self.Caret = self:MovePosition( self.Caret, 1 )
			self:ScrollCaret( )
			if not shift then
				self.Start = self.Caret:Clone( )
			end 
		elseif code == KEY_INSERT then 
			self.Insert = not self.Insert
		elseif code == KEY_BACKSPACE then
			if self:HasSelection( ) then
				self:FoldAll( tFolds )
				self:SetSelection( "" )
				tFolds = self:ExpandAll( )
			else
				-- self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, -1 ) }, "" ) )
				local buffer = self:GetArea( { self.Caret, Vector2( self.Caret.x, 1 ) } ) 
				if self.Caret.y % 4 == 1 and #buffer > 0 and string_rep( " ", #buffer ) == buffer then
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, -4 ) }, "" ) )
				else 
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, -1 ) }, "" ) )
				end
			end
		elseif code == KEY_DELETE then
			if self:HasSelection( ) then
				self:FoldAll( tFolds )
				self:SetSelection( "" )
				tFolds = self:ExpandAll( )
			else
				-- self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, 1 ) }, "" ) )
				local buffer = self:GetArea( { Vector2( self.Caret.x, self.Caret.y + 4 ), Vector2( self.Caret.x, 1 ) } )
				if self.Caret.y % 4 == 1 and string_rep( " ", #( buffer ) ) == buffer and #( self.Rows[self.Caret.x] ) >= self.Caret.y + 4 - 1 then
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, 4 ) }, "" ) )
				else
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, 1 ) }, "" ) )
				end
			end
		elseif code == KEY_PAGEUP then 
			self.Caret.x = math_max( self.Caret.x - math_ceil( self.Size.x / 2 ), 1 )
			self.Caret.y = math_min( self.Caret.y, #self.Rows[self.Caret.x] + 1 )
			
			self.Scroll.x = math_max( self.Scroll.x - math_ceil( self.Size.x / 2 ), 1 )

			self:ScrollCaret( )

			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_PAGEDOWN then
			self.Caret.x = math_min( self.Caret.x + math_ceil( self.Size.x / 2 ), #self.Rows )
			self.Caret.y = self.Caret.x == #self.Rows and 1 or math_min( self.Caret.y, #self.Rows[self.Caret.x] + 1 )

			self.Scroll.x = self.Scroll.x + math_ceil( self.Size.x / 2 )

			self:ScrollCaret( )

			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_HOME then
			local row = self.Rows[self.Caret.x]
			local first_char = string_find( row, "%S" ) or #row + 1
			self.Caret.y = self.Caret.y == first_char and 1 or first_char

			self:ScrollCaret( )

			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_END then
			self.Caret.y = #self.Rows[self.Caret.x] + 1

			self:ScrollCaret( )

			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_F2 then
			self:NextBookmark( )
		end 
	end 
	
	if code == KEY_TAB or ( control and ( code == KEY_I or code == KEY_O ) ) then 
		if code == KEY_O then shift = not shift end 
		if code == KEY_TAB and control then shift = not shift end 
		if self:HasSelection( ) then 
			self:Indent( shift ) 
		else 
			if (shift and code ~= KEY_O) or code == KEY_I then 
				local newpos = self.Caret.y - 4
				if newpos < 1 then newpos = 1 end
				self.Start:Set( self.Caret.x, newpos ) 
				
				if string_find( self:GetSelection( ), "%S" ) then 
					local Caret = self.Caret:Clone( ) 
					
					self.Start:Set( self.Start.x, 1 ) 
					self.Caret:Set( Caret.x, #self.Rows[Caret.x] + 1 ) 
					
					local text = string_match( self.Rows[Caret.x], "^ ? ? ? ?(.*)$" ) 
					local oldLength = #self.Rows[Caret.x] 
					
					self:SetSelection( text ) 
					
					self.Caret = self:MovePosition( Caret, #text - oldLength ) 
					self.Start = self.Caret:Clone( ) 
				else 
					self:FoldAll( tFolds )
					self:SetSelection( "" )
					tFolds = self:ExpandAll( )
				end
			else 
				if code == KEY_O then 
					local Caret = self.Caret:Clone( ) 
					
					self.Start:Set( self.Start.x, 1 ) 
					self.Caret:Set( Caret.x, #self.Rows[Caret.x] + 1 ) 
					
					self:Indent( ) 
					
					self.Caret = Caret:Add( 0, 4 )
					self.Start = self.Caret:Clone( ) 
				else 
					self:SetSelection( string_rep( " ", ( self.Caret.y + 2 ) % 4 + 1 ) )
				end 
			end 
		end
	end
	
	self:FoldAll( tFolds ) 
end

-- TODO: Add options to turn on and off the different auto param functionality
function PANEL:_OnTextChanged( ) 
	local ctrlv = false
	local text = self.pTextEntry:GetValue( )
	self.pTextEntry:SetText( "" )
	
	if ( input_IsKeyDown( KEY_LCONTROL ) or input_IsKeyDown( KEY_RCONTROL ) ) and not ( input_IsKeyDown( KEY_LALT ) or input_IsKeyDown( KEY_RALT ) ) then
		-- ctrl+[shift+]key
		if input_IsKeyDown( KEY_V ) then
			-- ctrl+[shift+]V
			ctrlv = true
		else
			-- ctrl+[shift+]key with key ~= V
			return
		end
	end
	
	if text == "" then return end
	if not ctrlv then
		if text == "\n" then return end
	end
	
	local bSelection = self:HasSelection( ) 
	
	if bSelection then 
		local selection = self:Selection( ) 
		local selectionText = self:GetArea( selection )
		local bMultiline = selection[1].x ~= selection[2].x
		
		if text == 1 and AutoParam[text] then 
			if not AutoParam[text][2] and bMultiline then 
				self:SetSelection( text )
			else 
				self:SetSelection( text .. selectionText .. AutoParam[text][1] ) 
				self.Start = selection[1]:Add( 0, 1 ) 
				self.Caret = selection[2]:Add( 0, bMultiline and 0 or 1 ) 
			end 
		else 
			self:SetSelection( text )
		end  
	elseif text == 1 and AutoParam[text] then 
		if 
			self.Rows[self.Caret.x][self.Caret.y] == " " or 
			self.Rows[self.Caret.x][self.Caret.y] == "" or 
			self.Rows[self.Caret.x][self.Caret.y] == AutoParam[text][1] 
		then 
			self:SetSelection( text .. AutoParam[text][1] ) 
			self:SetCaret( self:MovePosition( self.Caret, -1 ) ) 
		/*elseif SpecialCase[text] and self.Rows[self.Caret.x][self.Caret.y] == text then 
			self:SetCaret( self:MovePosition( self.Caret, 1 ) ) */
		else 
			self:SetSelection( text )
		end
	/*elseif #text == 1 and SpecialCase[text] and self.Rows[self.Caret.x][self.Caret.y] == text then 
		self:SetCaret( self:MovePosition( self.Caret, 1 ) ) */
	else
		self:SetSelection( text )
	end 
	self:ScrollCaret( ) 
end

/*---------------------------------------------------------------------------
Mouse stuff
---------------------------------------------------------------------------*/

function PANEL:OnMousePressed( code )
	if self.MouseDown then return end 
	
	local x, y = self:CursorPos( )
	if x < self.LinePadding then return end 
	
	if code == MOUSE_LEFT then 
		local cursor = self:CursorToCaret( ) 
		if self.LastClick and CurTime( ) - self.LastClick < 0.3 and ( self.Caret == cursor or self.LastCursor == cursor ) then 
			if self.temp then 
				self.temp = nil 
				
				self.Start = Vector2( cursor.x, 1 )
				self.Caret = Vector2( cursor.x + 1, 1 ) 
			else 
				self.temp = true 
				
				self.Start = self:wordStart( cursor )
				self.Caret = self:wordEnd( cursor )
			end 
			
			self.LastClick = CurTime( )
			self.LastCursor = cursor
			self:RequestFocus( )
			self.Blink = RealTime( )
			return 
		end 
		
		self.temp = nil 
		self.LastClick = CurTime( )
		self.LastCursor = cursor
		
		self.Blink = RealTime( )
		self.MouseDown = MOUSE_LEFT 
		
		self.Caret = self:CursorToCaret( )
		if not input_IsKeyDown( KEY_LSHIFT ) and not input_IsKeyDown( KEY_RSHIFT ) then
			self.Start = self.Caret:Clone( )
		end
		
		self:RequestFocus( )
		self:MouseCapture( true ) 
	elseif code == MOUSE_RIGHT then 
		self.MouseDown = MOUSE_RIGHT 
		
		self:RequestFocus( )
		self:MouseCapture( true ) 
	end
end

function PANEL:OnMouseReleased( code )
	if code == MOUSE_LEFT and self.MouseDown == code then
		self.MouseDown = nil
		self.Caret = self:CursorToCaret( )
		self:MouseCapture( false )
	elseif code == MOUSE_RIGHT and self.MouseDown == code then 
		self.MouseDown = nil
		self:MouseCapture( false )
		
		if vgui.GetHoveredPanel( ) == self then 
			local Menu = DermaMenu( )
			
			if self:HasSelection( ) then 
				Menu:AddOption( "Copy", function( ) 
					local clipboard = self:GetSelection( ) 
					clipboard = string_gsub( clipboard, "\n", "\r\n" ) 
					SetClipboardText( clipboard ) 
				end ) 
				
				Menu:AddOption( "Cut", function( ) 
					local clipboard = self:GetSelection( ) 
					clipboard = string_gsub( clipboard, "\n", "\r\n" ) 
					SetClipboardText( clipboard ) 
					self:SetSelection( "" ) 
				end ) 
				
				Menu:AddOption( "Indent", function( ) 
					self:Indent( )
				end ) 
				
				Menu:AddOption( "Outdent", function( ) 
					self:Indent( true )
				end ) 
			end 
			
			Menu:AddOption( "Paste", function( ) self.pTextEntry:Paste( ) end ) 
			
			Menu:AddSpacer( ) 
			Menu:AddOption( "Select All", function( ) self:SelectAll( ) end )
			Menu:Open( )
		end 
	end
end

function PANEL:OnMouseWheeled( delta ) 
	if input_IsKeyDown( KEY_LSHIFT ) or input_IsKeyDown( KEY_RSHIFT ) then 
		self.Scroll:Add( 0, - 4 * delta )
		if self.Scroll.y < 1 then self.Scroll.y = 1 end
		if self.Scroll.y > self.LongestRow then self.Scroll.y = self.LongestRow end
		self.pHScrollBar:SetScroll( self.Scroll.y - 1 )
	else 
		self.Scroll:Add( - 4 * delta, 0 )
		if self.Scroll.x < 1 then self.Scroll.x = 1 end
		if self.Scroll.x > #self.Rows then self.Scroll.x = #self.Rows end
		self.pScrollBar:SetScroll( self.Scroll.x - 1 )
	end 
end

/*---------------------------------------------------------------------------
Cursor stuff
---------------------------------------------------------------------------*/

function PANEL:CursorToCaret( ) 
	local x, y = self:CursorPos( ) 
	
	x = x - self.LinePadding 
	if x < 0 then x = 0 end 
	if y < 0 then y = 0 end 
	
	local line = math_floor( y / self.FontHeight ) 
	local char = math_floor( x / self.FontWidth + 0.5 ) 
	
	line = line + self.Scroll.x 
	
	local last, runs = 0, 0
	while true do 
		local offset = self:GetFoldingOffset( line )
		line = line + (offset - last)
		if last == self:GetFoldingOffset( line ) then break end 
		last = offset
		runs = runs + 1
		if runs >= 1000 then 
			print( "InfLoop Prevented!!!" ) 
			debug.Trace( ) 
			break
		end 
	end 
	
	char = char + self.Scroll.y 
	
	if line > #self.Rows then line = #self.Rows end 
	local length = #( istable( self.Rows[line] ) and self.Rows[line][1] or self.Rows[line] )
	if char > length + 1 then char = length + 1 end 
	
	return Vector2( line, char )
end

function PANEL:SetCaret( caret )
	self.Caret = caret:Clone( )
	self.Start = caret:Clone( )
	self:ScrollCaret( )
end

function PANEL:MovePosition( caret, offset )
	local caret = caret:Clone( ) 
	
	if offset > 0 then
		if istable( self.Rows[caret.x] ) and self.Rows[caret.x].Primary ~= caret.x then 
			while istable( self.Rows[caret.x] ) do 
				caret.x = caret.x + 1 
			end 
			caret.y = 1
		else 
			while true do
				local length = #( istable( self.Rows[caret.x] ) and self.Rows[caret.x][1] or self.Rows[caret.x] ) - caret.y + 2
				
				if offset < length then
					caret.y = caret.y + offset
					break
				elseif caret.x == #self.Rows then
					caret.y = caret.y + length - 1
					break
				else 
					if istable( self.Rows[caret.x + 1] ) then 
						caret.x = caret.x + #self.Rows[caret.x + 1]
					else 
						caret.x = caret.x + 1
					end 
					offset = offset - length
					caret.y = 1 + offset
				end
			end
		end 
	elseif offset < 0 then
		offset = -offset
		
		if istable( self.Rows[caret.x] ) and self.Rows[caret.x].Primary ~= caret.x then 
			caret.x = self.Rows[caret.x].Primary
			caret.y = #self.Rows[caret.x][1] + 1
		else 
			while true do
				if offset < caret.y then
					caret.y = caret.y - offset
					break
				elseif caret.x == 1 then
					caret.y = 1
					break
				else
					if istable( self.Rows[caret.x - 1] ) then 
						caret.x = caret.x - #self.Rows[caret.x - 1]
					else 
						caret.x = caret.x - 1
					end 
					offset = offset - caret.y
					if istable( self.Rows[caret.x] ) then
						caret.y = #self.Rows[caret.x][1] + 1 - offset
					else 
						caret.y = #self.Rows[caret.x] + 1 - offset
					end 
				end
			end
		end 
	end
	
	return caret
end

function PANEL:ScrollCaret( )
	local Offset = self:GetFoldingOffset( self.Caret.x )
	
	if self.Caret.x - self.Scroll.x < 1 then
		self.Scroll.x = self.Caret.x - 1 - Offset
		if self.Scroll.x < 1 then self.Scroll.x = 1 end
	end

	if self.Caret.x - self.Scroll.x > self.Size.x - 1 then
		self.Scroll.x = self.Caret.x - self.Size.x + 1 - Offset
		if self.Scroll.x < 1 then self.Scroll.x = 1 end
	end

	if self.Caret.y - self.Scroll.y < 4 then
		self.Scroll.y = self.Caret.y - 4
		if self.Scroll.y < 1 then self.Scroll.y = 1 end
	end

	if self.Caret.y - 1 - self.Scroll.y > self.Size.y - 4 then
		self.Scroll.y = self.Caret.y - 1 - self.Size.y + 4
		if self.Scroll.y < 1 then self.Scroll.y = 1 end
	end

	self.pScrollBar:SetScroll( self.Scroll.x - 1 )
	self.pHScrollBar:SetScroll( self.Scroll.y - 1 )
end

/*---------------------------------------------------------------------------
Selection stuff
---------------------------------------------------------------------------*/

function PANEL:HasSelection( )
	return self.Caret != self.Start
end

function PANEL:Selection( )
	return { Vector2( self.Start( ) ), Vector2( self.Caret( ) ) }
end

function PANEL:GetSelection( )
	return self:GetArea( self:Selection( ) )
end

function PANEL:SetSelection( text )
	self:SetCaret( self:SetArea( self:Selection( ), text ) )
end

local function MakeSel( start, stop ) 
	if start.x > stop.x or ( start.x == stop.x and start.y > stop.y ) then 
		return stop, start 
	else 
		return start, stop
	end 
end

function PANEL:MakeSelection( selection )
	local start, stop = MakeSel( selection[1], selection[2] )
	
	-- Should i do this?
	/*
	if istable( self.Rows[start.x] ) then 
		start = Vector2( self.Rows[start.x].Primary, #self.Rows[self.Rows[start.x].Primary][1] )
	end 
	
	if istable( self.Rows[stop.x] ) then 
		local x = self.Rows[start.x].Primary
		stop = Vector2( self.Rows[x][#self.Rows[x]], 1 )
	end 
	*/
	
	return start, stop
end

function PANEL:SelectAll( )
	self.Caret = Vector2( #self.Rows, istable( self.Rows[#self.Rows] ) and #self.Rows[self.Rows[#self.Rows].Primary][1] or #self.Rows[#self.Rows] + 1 )
	self.Start = Vector2( 1, 1 )
	-- self:ScrollCaret( )
end

function PANEL:GetArea( selection )
	local start, stop = self:MakeSelection( selection ) 
	local text = "" 
	local LinesToFold = self:ExpandAll( )
	
	if start.x == stop.x then 
		if self.Insert and start.y == stop.y then 
			selection[2].y = selection[2].y + 1 
			
			text = string_sub( self.Rows[start.x], start.y, start.y )
		else 
			text = string_sub( self.Rows[start.x], start.y, stop.y - 1 )
		end 
	else
		text = string_sub( self.Rows[start.x], start.y )

		for i = start.x + 1, stop.x - 1 do
			text = text .. "\n" .. self.Rows[i]
		end
		
		text =  text .. "\n" .. string_sub( self.Rows[stop.x], 1, stop.y - 1 )
	end 
	
	self:FoldAll( LinesToFold )
	
	return text
end

function PANEL:SetArea( selection, text, isundo, isredo, before, after )
	local buffer = self:GetArea( selection )
	local start, stop = self:MakeSelection( selection )
	local LinesToFold = { } 
	
	for line = 1, #self.Rows do
		LinesToFold[line] = istable( self.Rows[line] )
		if istable( self.Rows[line] ) then 
			self:ExpandLine( line ) 
		end 
	end 
	
	if start != stop then
		// Merge first and last line
		self.Rows[start.x] = string_sub( self.Rows[start.x], 1, start.y - 1 ) .. string_sub( self.Rows[stop.x], stop.y )
		
		// Remove deleted lines
		for i = start.x + 1, stop.x do
			table_remove( self.Rows, start.x + 1 )
			table_remove( self.FoldData, start.x + 1 )
			table_remove( LinesToFold, start.x + 1 )
		end
	end
	
	if !text or text == "" then
		self.pScrollBar:SetUp( self.Size.x, #self.Rows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ) )
		self:CalculateScroll( )
		self.PaintRows = { }
		self:OnTextChanged( selection, text )
		self:MakeFoldData( )
		
		if isredo then
			self.Undo[#self.Undo + 1] = { { start:Clone( ), start:Clone( ) }, 
				buffer, after, before }
			for i = #LinesToFold, 1, -1 do if LinesToFold[i] then self:FoldLine( i ) end end 
			return before
		elseif isundo then
			self.Redo[#self.Redo + 1] = { { start:Clone( ), start:Clone( ) }, 
				buffer, after, before }
			for i = #LinesToFold, 1, -1 do if LinesToFold[i] then self:FoldLine( i ) end end 
			return before
		else
			self.Redo = { }
			self.Undo[#self.Undo + 1] = { { start:Clone( ), start:Clone( ) }, 
				buffer, selection[1]:Clone( ), start:Clone( ) }
			for i = #LinesToFold, 1, -1 do if LinesToFold[i] then self:FoldLine( i ) end end 
			return start
		end
	end
	
	// insert text
	local rows = string_Explode( "\n", text )
	
	local remainder = string_sub( self.Rows[start.x], start.y )
	self.Rows[start.x] = string_sub( self.Rows[start.x], 1, start.y - 1 ) .. rows[1]
	
	for i = 2, #rows do
		table_insert( self.Rows, start.x + i - 1, rows[i] )
		table_insert( LinesToFold, start.x + i - 1, false )
	end
	self.FoldData = { }
	
	local stop = Vector2( start.x + #rows - 1, #self.Rows[start.x + #rows - 1] + 1 )
	
	self.Rows[stop.x] = self.Rows[stop.x] .. remainder
	
	self.pScrollBar:SetUp( self.Size.x, #self.Rows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ))
	self:CalculateScroll( )
	self.PaintRows = { }
	self:OnTextChanged( selection, text )
	self:MakeFoldData( )
	
	if isredo then
		self.Undo[#self.Undo + 1] = { { start:Clone( ), stop:Clone( ) }, 
			buffer, after, before }
		for i = #LinesToFold, 1, -1 do if LinesToFold[i] then self:FoldLine( i ) end end 
		return before
	elseif isundo then
		self.Redo[#self.Redo + 1] = { { start:Clone( ), stop:Clone( ) }, 
			buffer, after, before }
		for i = #LinesToFold, 1, -1 do if LinesToFold[i] then self:FoldLine( i ) end end 
		return before
	else
		self.Redo = { }
		self.Undo[#self.Undo + 1] = { { start:Clone( ), stop:Clone( ) }, 
			buffer, selection[1]:Clone( ), stop:Clone( ) }
		for i = #LinesToFold, 1, -1 do if LinesToFold[i] then self:FoldLine( i ) end end 
		return stop
	end
end

// Might need fixing
function PANEL:Indent( Shift ) 
	local oldSelection = { self:MakeSelection( self:Selection( ) ) } 
	local Scroll = self.Scroll:Clone( ) 
	local Start, End = oldSelection[1]:Clone( ), oldSelection[2]:Clone( ) 
	local slen, elen = #self.Rows[Start.x], #self.Rows[End.x]
	
	Start.y = 1 
	if End.y ~= 1 then 
		End.x = End.x + 1 
		End.y = 1 
	end 
	
	self.Start = Start:Clone( ) 
	self.Caret = End:Clone( ) 
	
	if self.Caret.y == 1 then 
		self.Caret = self:MovePosition( self.Caret, -1 )
	end 
		
	if Shift then // Unindent 
		local Temp = string_gsub( self:GetSelection( ), "\n ? ? ? ?", "\n" ) 
		self:SetSelection( string_match( Temp, "^ ? ? ? ?(.*)$") )
	else // Indent 
		self:SetSelection( "    " .. string_gsub( self:GetSelection( ), "\n", "\n    " ) ) 
	end 
	
	self.Start = oldSelection[1]:Clone( ):Add( 0, #self.Rows[oldSelection[1].x] - slen )
	self.Caret = oldSelection[2]:Clone( ):Add( 0, #self.Rows[oldSelection[2].x] - elen )
	
	self.Scroll = Scroll:Clone( ) 
	
	self:ScrollCaret( ) 
end 

function PANEL:CanUndo( )
	return #self.Undo > 0 
end

function PANEL:DoUndo( )
	if #self.Undo > 0 then
		local undo = self.Undo[#self.Undo]
		self.Undo[#self.Undo] = nil
		
		self:SetCaret( self:SetArea( undo[1], undo[2], true, false, undo[3], undo[4] ) ) 
	end
end

function PANEL:CanRedo( )
	return #self.Redo > 0 
end

function PANEL:DoRedo( )
	if #self.Redo > 0 then
		local redo = self.Redo[#self.Redo]
		self.Redo[#self.Redo] = nil

		self:SetCaret( self:SetArea( redo[1], redo[2], false, true, redo[3], redo[4] ) ) 
	end
end

function PANEL:wordLeft( caret )
	local tFolds = self:ExpandAll( )
	local row = self.Rows[caret.x] 
	if caret.y == 1 then
		if caret.x == 1 then return caret end
		return Vector2( caret.x-1, #self.Rows[caret.x-1] )
	end
	local pos = string_match( string_sub( row, 1, caret.y - 2 ), "[^%w_]+()[%w_]+[^%w_]*$" )
	caret.y = pos or 1
	self:FoldAll( tFolds )
	return caret
end

function PANEL:wordRight( caret )
	local tFolds = self:ExpandAll( )
	local row = self.Rows[caret.x] 
	if caret.y > #row then
		if caret.x == #self.Rows then return caret end
		return Vector2( caret.x + 1, 1 )
	end
	local pos = string_match( row, "%f[%w_]()", caret.y+1 )
	caret.y = pos or ( #row + 1 )
	self:FoldAll( tFolds )
	return caret
end

function PANEL:wordStart( caret )
	local tFolds = self:ExpandAll( )
	local line = self.Rows[caret.x] 
	self:FoldAll( tFolds )
	
	for startpos, endpos in string_gmatch( line, "()[a-zA-Z0-9_]+()" ) do 
		if startpos <= caret.y and endpos >= caret.y then 
			return Vector2( caret.x, startpos )
		end 
	end 
	
	return Vector2( caret.x, 1 )
end

function PANEL:wordEnd( caret )
	local tFolds = self:ExpandAll( )
	local line = self.Rows[caret.x] 
	self:FoldAll( tFolds )
	
	for startpos, endpos in string_gmatch( line, "()[a-zA-Z0-9_]+()" ) do 
		if startpos <= caret.y and endpos >= caret.y then 
			return Vector2( caret.x, endpos )
		end 
	end 
	
	return Vector2( caret.x, caret.y )
end

/*---------------------------------------------------------------------------
Code folding
---------------------------------------------------------------------------*/
function PANEL:FindValidLines( ) 
	local ValidLines = { } 
	local bMultilineComment = false 
	local bMultilineString = false 
	local Row, Char = 1, 0 
	local LinesToFold = self:ExpandAll( )
	
	while Row <= #self.Rows do 
		local sStringType = false 
		local Line = self.Rows[Row]
		
		while Char < #Line do 
			Char = Char + 1
			local Text = Line[Char]
			
			if bMultilineComment then 
				if Text == "/" and Line[Char-1] == "*" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineComment = false 
				end 
				continue 
			end 
			
			if bMultilineString then 
				if Text == "'" and Line[Char-1] ~= "\\" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					bMultilineString = nil 
				end 
				continue 
			end 
			
			if sStringType then 
				if Text == sStringType and Line[Char-1] ~= "\\" then 
					ValidLines[#ValidLines][2] = { Row, Char }
					sStringType = nil 
				end 
				continue 
			end 
			
			if Text == "/" then 
				if Line[Char+1] == "/" then // SingleLine comment
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
					break 
				elseif Line[Char+1] == "*" then // MultiLine Comment
					bMultilineComment = true 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
					continue 
				end 
			end 
			
			if Text == "'" then 
				if Line[Char-1] ~= "\\" then 
					bMultilineString = true 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
				end 
				continue 
			end 
			
			if Text == '"' then 
				if Line[Char-1] ~= "\\" then 
					sStringType = Text 
					ValidLines[#ValidLines+1] = { { Row, Char }, { Row, #Line + 1 } }
				end 
			end 
		end 
		
		Char = 0 
		Row = Row + 1 
	end 
	
	self:FoldAll( LinesToFold )
	
	return function( nLine, nStart ) 
		for i = 1, #ValidLines do
			local tStart, tEnd = ValidLines[i][1], ValidLines[i][2]
			
			if tStart[1] < nLine and tEnd[1] > nLine then 
				return false 
			end 
			
			if tStart[1] == tEnd[1] then
				if tStart[1] == nLine then 
			 		if tStart[2] <= nStart and tEnd[2] >= nStart then 
			 			return false 
			 		end 
			 	end 
			else 
			 	if tStart[1] == nLine then 
			 		if tStart[2] <= nStart then 
			 			return false 
			 		end 
			 	elseif tEnd[1] == nLine then 
			 		if tEnd[2] >= nStart then 
			 			return false 
			 		end 
			 	end 
			end 
		end
		
		return true 
	end 
end 

local ParamPairs = {
	["{"] = { "{", "}", true }, 
	["["] = { "[", "]", true }, 
	["("] = { "(", ")", true }, 
	
	["}"] = { "}", "{", false }, 
	["]"] = { "]", "[", false }, 
	[")"] = { ")", "(", false }, 
}

function PANEL:FindMatchingParam( Row, Char ) 
	if not self.Rows[Row] then return false end 
	local LinesToFold = self:ExpandAll( )
	local Param, EnterParam, ExitParam = ParamPairs[self.Rows[Row][Char]] 
	
	if ParamPairs[self.Rows[Row][Char-1]] and not ParamPairs[self.Rows[Row][Char-1]][3] then 
		Char = Char - 1
		Param = ParamPairs[self.Rows[Row][Char]] 
	end 
	
	if not Param then 
		Char = Char - 1
		Param = ParamPairs[self.Rows[Row][Char]] 
	end 
	
	if not Param then
		self:FoldAll( LinesToFold ) 
		return false 
	end 
	
	EnterParam = Param[1]
	ExitParam = Param[2]
	
	local line, pos, level = Row, Char, 0 
	local ValidLines = self:FindValidLines( ) 
	
	if not ValidLines( line, pos ) then 
		self:FoldAll( LinesToFold )
		return false 
	end 
	
	if Param[3] then -- Look forward 
		while line <= #self.Rows do 
			local Line = self.Rows[line]
			while pos < #Line do 
				pos = pos + 1
				local Text = Line[pos]
				
				if not ValidLines( line, pos ) then continue end 
				
				if Text == EnterParam then 
					level = level + 1 
				elseif Text == ExitParam then 
					if level > 0 then 
						level = level - 1 
					else 
						self:FoldAll( LinesToFold )
						return { Vector2( Row, Char ), Vector2( line, pos ) }
					end 
				end 
			end 
			pos = 0 
			line = line + 1 
		end 
	else -- Look backwards 
		while line > 0 do 
			local Line = self.Rows[line]
			while pos > 0 do 
				pos = pos - 1 
				
				local Text = Line[pos] 
				
				if not ValidLines( line, pos ) then continue end 
				
				if Text == EnterParam then 
					level = level + 1 
				elseif Text == ExitParam then 
					if level > 0 then 
						level = level - 1 
					else 
						self:FoldAll( LinesToFold )
						return { Vector2( line, pos ), Vector2( Row, Char ) }
					end 
				end 
			end 
			line = line - 1 
			pos = #(self.Rows[line] or "") + 1
		end 
	end 
	
	self:FoldAll( LinesToFold )
	
	return false 
end 

// { FoldLevel, Folded, FoldOverride }
function PANEL:MakeFoldData( nExit ) 
	local LinesToFold = self:ExpandAll( )
	local ValidLines = self:FindValidLines( ) 
	local nLevel = 0
	
	for nLine = 1, #self.Rows do
		if nLine == nExit then break end 
		local text = self.Rows[nLine]
		local last
		self.FoldData[nLine] = self.FoldData[nLine] or { nLevel, false, false }
		
		for nStart, sType, nEnd in string.gmatch( text, "()([{}])()") do 
			if not ValidLines( nLine, nStart ) then continue end 
			nLevel = nLevel + ( sType == "{" and 1 or -1 ) 
			last = sType
		end 
		
		if last == "{" and self.FoldData[nLine][1] == nLevel then
			self.FoldData[nLine][3] = true 
		else 
			self.FoldData[nLine][3] = false 
		end
		
		if self.FoldData[nLine][1] > nLevel then 
			self.FoldData[nLine][1] = nLevel 
		end 
	end
	
	self.FoldData[#self.Rows+1] = { 0, false, false }
	
	self:FoldAll( LinesToFold )
end 

function PANEL:GetFoldingOffset( nLine ) 
	local offset = 0 
	local pos = 1
	local infloop = 0
	
	while pos < nLine and infloop < 10000 do 
		if istable( self.Rows[pos] ) then 
			offset = offset + #self.Rows[pos] - 1
			pos = pos + #self.Rows[pos] 
		else 
			pos = pos + 1
		end 
		infloop = infloop + 1
	end 
	
	return offset
end 

function PANEL:ExpandAll( tOld ) 
	if type( tOld ) == "table" then 
		for i = 1, #tOld do 
			self:ExpandLine( tOld[i] )
		end 
		return true 
	else  
		local ExpandedLines = { }
		
		for line = 1, #self.Rows do
			local Line = self.Rows[line]
			if type( Line ) == "table" and Line.Primary == line then 
				ExpandedLines[#ExpandedLines+1] = line 
				self:ExpandLine( line ) 
			end 
		end
		
		return ExpandedLines
	end 
end 

function PANEL:FoldAll( tOld )
	if type( tOld ) == "table" then 
		for i = #tOld, 1, -1 do 
			self:FoldLine( tOld[i] )
		end 
		return true 
	else 
		local FoldedLines = { }
		local last = 0
		
		if #self.FoldData < #self.Rows then self:MakeFoldData( ) end 
		
		for line = #self.Rows, 1, -1 do
			local Line = self.Rows[line]
			local Fold = self.FoldData[line]
			if Fold[1] < last or Fold[3] then 
				FoldedLines[#FoldedLines+1] = line 
				self:FoldLine( line ) 
			end 
		end
		
		return FoldedLines
	end 
end 

function PANEL:FoldLine( nLine )
	if istable( self.Rows[nLine] ) or not self.Rows[nLine] then return print( "Tried to fold already folded line!", nLine ) end 
	if self.FoldData[nLine][1] == self.FoldData[nLine+1][1] and not self.FoldData[nLine][3] then return end 
	if self.FoldData[nLine][1] > self.FoldData[nLine+1][1] then return end 
	local Data = { self.Rows[nLine] } 
	local FoldLevel = self.FoldData[nLine+1][1]
	self.FoldData[nLine][2] = true
	self.Rows[nLine] = Data 
	Data.Primary = nLine 
	
	for i = nLine + 1, #self.Rows do 
		if self.FoldData[i][1] >= FoldLevel or self.FoldData[nLine][3] then 
			if self.FoldData[nLine][3] and self.FoldData[i][3] then break end 
			if self.FoldData[i][3] and self.FoldData[i][1] == FoldLevel then break end 
			if self.FoldData[i][1] < FoldLevel then break end 
			Data[#Data+1] = self.Rows[i] 
			self.Rows[i] = Data 
		else 
			break 
		end 
	end 
end

function PANEL:ExpandLine( nLine )
	self.FoldData[nLine][2] = false
	local Data = self.Rows[nLine]
	if not istable( Data ) then return print( "Tried to unfold invalid line", nLine, type( Data ) ) end 
	
	if Data.Primary == nLine then 
		self.Rows[nLine] = Data[1]
		for i = 2, #Data do 
			self.Rows[nLine+i-1] = Data[i]
		end
	else 
		local subfolds = false 
		for i = 1, #Data do 
			self.Rows[Data.Primary+i-1] = Data[i]
			
			if istable( Data[i] ) then 
				if Data[i].Primary == Data.Primary+i-1 then 
					if Data.Primary+i-1 <= nLine and Data[i].Primary+#Data[i]-1 >= nLine then 
						subfolds = true 
					end 
				end 
			end 
		end 
		
		if subfolds then self:ExpandLine( nLine ) end 
	end 
end

/*---------------------------------------------------------------------------
Bookmarks
---------------------------------------------------------------------------*/
function PANEL:Bookmark( ) 
	local tStart, tEnd = self:MakeSelection( self:Selection( ) ) 
	
	if self.Bookmarks[tStart.x] then 
		self.Bookmarks[tStart.x] = nil
	else 
		self.Bookmarks[tStart.x] = { tStart, tEnd }
	end 
end 

function PANEL:NextBookmark( ) 
	local tStart, tEnd = self:MakeSelection( self:Selection( ) ) 
	local pos = tStart.x 
	
	while true do 
		pos = pos + 1 
		if pos > #self.Rows then pos = 1 end 
		if pos == tStart.x then break end 
		if self.Bookmarks[pos] then 
			self.Start = self.Bookmarks[pos][1] 
			self.Caret = self.Bookmarks[pos][2] 
			self:ScrollCaret( ) 
			break 
		end 
	end
end 

function PANEL:PreviousBookmark( ) 
	local tStart, tEnd = self:MakeSelection( self:Selection( ) ) 
	local pos = tStart.x 
	
	while true do 
		pos = pos - 1
		if pos <= 0 then pos = #self.Rows end 
		if pos == tStart.x then break end 
		if self.Bookmarks[pos] then 
			self.Start = self.Bookmarks[pos][1] 
			self.Caret = self.Bookmarks[pos][2] 
			self:ScrollCaret( ) 
			break 
		end 
	end
end 

/*---------------------------------------------------------------------------
Paint
---------------------------------------------------------------------------*/
function PANEL:Paint( w, h ) 
	if not self.Font then return end 
	surface_SetFont( self.Font ) 
	
	self.LineNumberWidth = 6 + self.FontWidth * string_len( tostring( math_min( self.Scroll.x, #self.Rows - self.Size.x + 1 ) + self.Size.x - 1 ) )
	self.LinePadding = self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth
	
	h = h - (self.pHScrollBar.Enabled and 16 or 0)
	w = w - (self.pScrollBar.Enabled and 16 or 0)
	
	surface_SetDrawColor( 0, 0, 0, 255 ) 
	surface_DrawRect( 0, 0, w, h )
	
	surface_SetDrawColor( 32, 32, 32, 255 )
	surface_DrawRect( 0, 0, self.LinePadding, h )
	
	self.Params = self:FindMatchingParam( self.Caret.x, self.Caret.y ) 
	
	if self.MouseDown and self.MouseDown == MOUSE_LEFT then
		self.Caret = self:CursorToCaret( )
	end
		
	self.Scroll.x = math_floor( self.pScrollBar:GetScroll( ) + 1 )
	self.Scroll.y = math_floor( self.pHScrollBar:GetScroll( ) + 1 )
	
	for k, v in pairs( self.FoldButtons ) do
		if ValidPanel(v) then 
			v:SetVisible( false )
		end 
	end
	
	self:DrawTextUnderlay( w, h ) 
	self:DrawText( w, h ) 
	self:DrawTextOverlay( w, h ) 
end

function PANEL:DrawTextUnderlay( w, h )
	self:PaintSelection( self:Selection( ) )
	
	for k, v in pairs( self.tSelections ) do
		self:PaintSelection( v[1], v[2], v[3] )
	end
	
	if self.Params and not self:HasSelection( ) then 
		surface_SetDrawColor( 160, 160, 160, 255 ) -- TODO: Allow users to configure color and if it is active
		surface_DrawRect( 
			( self.Params[1].y - self.Scroll.y ) * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
			( self.Params[1].x + 1 - self.Scroll.x - self:GetFoldingOffset( self.Params[1].x ) ) * self.FontHeight + 1, 
			self.FontWidth, 
			1 
		) 
		surface_DrawRect( 
			( self.Params[2].y - self.Scroll.y ) * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
			( self.Params[2].x + 1 - self.Scroll.x - self:GetFoldingOffset( self.Params[2].x ) ) * self.FontHeight + 1, 
			self.FontWidth, 
			1 
		) 
	end
end

function PANEL:DrawText( w, h )
	local line = self.Scroll.x - 1 
	do
		local last, runs = 0, 0
		while true do 
			local offset = self:GetFoldingOffset( line )
			line = line + (offset - last)
			if last == self:GetFoldingOffset( line ) then break end 
			last = offset
			runs = runs + 1
			if runs >= 1000 then 
				print( "InfLoop Prevented!!!" ) 
				debug.Trace( ) 
				break
			end 
		end 
	end 
	local painted = 0
	while painted < self.Size.x + 2 do 
		line = line + 1
		
		if istable( self.Rows[line] ) then 
			if self.Rows[line].Primary ~= line then 
				line = line + #self.Rows[line] - (line - self.Rows[line].Primary) - 1
				continue 
			end 
			local Data = self.Rows[line] 
			self.Rows[line] = Data[1] 
			self:DrawRow( line, painted, true )
			self.Rows[line] = Data 
			line = line + #self.Rows[line] - 1 
		else 
			self:DrawRow( line, painted )
		end 
		
		painted = painted + 1 
	end 
end

function PANEL:DrawTextOverlay( w, h )
	self:PaintCursor( ) 
	
	for k, v in pairs( self.tCursors ) do
		self:PaintCursor( v )
	end
	
	self:PaintStatus( )
end

local function MakeFoldButton( self ) 
	local btn = self:Add( "GOLEM_ImageButton" ) 
	btn:SetIconCentered( true )
	btn:SetIconFading( false ) 
	btn.Expanded = true 
	btn:SetAutoResize( false )
	btn:SetIconStretch( true )
	btn:SetSize( self.FontHeight, self.FontHeight )
	btn:SetMaterial( Material( "oskar/minus32.png" ) ) 
	
	local paint = btn.Paint 
	btn.Paint = function( _, w, h ) 
		surface.SetDrawColor = function( ) 
			surface_SetDrawColor( 150, 150, 150, 255 )
			if btn.Hovered then surface_SetDrawColor( 200, 200, 200, 255 ) end 
		end 
		paint( btn, w, h )
		surface.SetDrawColor = surface_SetDrawColor
	end 
	
	btn.DoClick = function( ) 
		if btn.Expanded then 
			btn:SetMaterial( Material( "oskar/plus32.png" ) )
			btn.Expanded = false 
			self:FoldLine( btn.Row )
		else 
			btn:SetMaterial( Material( "oskar/minus32.png" ) )
			btn.Expanded = true 
			self:ExpandLine( btn.Row )
		end 
	end
	
	btn.Think = function( ) 
		if not self.FoldData[btn.Row] then return end 
		if self.FoldData[btn.Row][2] then 
			btn:SetMaterial( Material( "oskar/plus32.png" ) )
			btn.Expanded = false 
		else 
			btn:SetMaterial( Material( "oskar/minus32.png" ) )
			btn.Expanded = true 
		end 
	end 
	
	return btn
end 

function PANEL:DrawRow( Row, LinePos, bForceRepaint )
	if Row > #self.Rows then return end
	
	draw_SimpleText( tostring( Row ), self.Font, self.BookmarkWidth + self.LineNumberWidth, self.FontHeight * ( LinePos ), C_white, TEXT_ALIGN_RIGHT ) 
	self.PaintRows[Row] = (bForceRepaint and self:SyntaxColorLine( Row )) or self.PaintRows[Row] or self:SyntaxColorLine( Row ) 
	
	if editor_debug_folding then 	
		surface_SetDrawColor( 0, 200, 255 ) 
		surface_DrawRect( self.LinePadding, self.FontHeight * LinePos, self.FontWidth * self.FoldData[Row][1], self.FontHeight )
		
		if Row < #self.Rows and self.FoldData[Row][1] < self.FoldData[Row+1][1] then 
			surface_SetDrawColor( 0, 160, 0 ) 
			surface_DrawRect( self.LinePadding + self.FontWidth * self.FoldData[Row][1], self.FontHeight * LinePos, self.FontWidth * (self.FoldData[Row+1][1]-self.FoldData[Row][1]), self.FontHeight )
		end 
		
		if Row > 1 and Row <= #self.Rows and self.FoldData[Row-1][1] > self.FoldData[Row][1] then 
			surface_SetDrawColor( 160, 0, 0 ) 
			surface_DrawRect( self.LinePadding + self.FontWidth * self.FoldData[Row][1], self.FontHeight * LinePos, self.FontWidth * (self.FoldData[Row-1][1]-self.FoldData[Row][1]), self.FontHeight )
		end 
		
		if Row > 1 and Row < #self.Rows and self.FoldData[Row][3] then 
			surface_SetDrawColor( 160, 160, 0 ) 
			surface_DrawRect( self.LinePadding + self.FontWidth * self.FoldData[Row][1], self.FontHeight * LinePos, self.FontWidth * 1, self.FontHeight )
		end 
	end 
	
	// Setup buttons for codefolding
	if Row < #self.Rows then 
		if self.FoldData[Row][1] < self.FoldData[Row+1][1] or self.FoldData[Row][3] then 
			if not ValidPanel( self.FoldButtons[Row] ) then 
				self.FoldButtons[Row] = MakeFoldButton( self ) 
			end 
			self.FoldButtons[Row].Row = Row
			self.FoldButtons[Row]:SetVisible( true )
			self.FoldButtons[Row]:SetPos( self.BookmarkWidth + self.LineNumberWidth, ( LinePos ) * self.FontHeight ) 
		end 
	end 
	
	if self.Bookmarks[Row] then 
		surface_SetDrawColor( 255, 255, 255, 255 ) 
		surface_SetMaterial( BookmarkMaterial ) 
		surface_DrawTexturedRect( 3, ( LinePos ) * self.FontHeight, 16, 16 )
	end 
	
	local offset = -self.Scroll.y + 1
	for i, cell in ipairs( self.PaintRows[Row] ) do
		local len = #cell[1]
		if offset < 0 then
			if len > -offset then
				line = cell[1]:sub( 1 - offset )
				offset = #line
				draw_SimpleText( line, self.Font, self.LinePadding, ( LinePos ) * self.FontHeight, cell[2] )
			else
				offset = offset + len 
			end
		else
			draw_SimpleText( cell[1], self.Font, offset * self.FontWidth + self.LinePadding, ( LinePos ) * self.FontHeight, cell[2] )
			offset = offset + len
		end
	end
end

function PANEL:PositionIsVisible( pos )
	local x, y = pos( -self:GetFoldingOffset( pos.x ), 0 )
	return 	x - self.Scroll.x >= 0 and x < self.Scroll.x + self.Size.x + 1 and
			y - self.Scroll.y >= 0 and y < self.Scroll.y + self.Size.y + 1
end

function PANEL:RowIsVisible( nRow )
	local offset = nRow - self:GetFoldingOffset( nRow )
	return offset - self.Scroll.x >= 0 and offset < self.Scroll.x + self.Size.x + 1  
end 

function PANEL:PaintSelection( selection, color, outline )
	local start, stop = self:MakeSelection( selection )
	local line, char = start.x, start.y 
	local endline, endchar = stop.x, stop.y 
	
	char = char - self.Scroll.y
	endchar = endchar - self.Scroll.y
	
	if char < 0 then char = 0 end
	if endchar < 0 then endchar = 0 end
	
	color = color or Color( 0, 0, 160, 255 ) 
	outline = outline or false 
	
	local LinePos = line - self.Scroll.x - 1 - self:GetFoldingOffset( line )
	
	for Row = line, endline do 
		if Row > #self.Rows then break end
		if istable( self.Rows[Row] ) and self.Rows[Row].Primary ~= Row then continue end 
		local length = istable( self.Rows[Row] ) and #self.Rows[Row][1] or #self.Rows[Row]
		length = length - self.Scroll.y + 1
		LinePos = LinePos + 1
		
		surface_SetDrawColor( color )
		if outline then 
			if Row == line and line == endline then -- Same line selection
				surface_DrawOutlinedRect( 
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * ( endchar - char ), 
					self.FontHeight 
				 )
			elseif Row == line then -- Selection starts on this line
				surface_DrawOutlinedRect( 
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * math_min( self.Size.y - char + 2, length - char + 1 ), 
					self.FontHeight 
				 )
			elseif Row == endline then -- Selection ends on this line
				surface_DrawOutlinedRect( 
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * endchar,  
					self.FontHeight 
				 ) 
			elseif Row > line and Row < endline then -- Selection covers this entire line
				surface_DrawOutlinedRect( 
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * math_min( self.Size.y + 2, length + 1 ),  
					self.FontHeight 
				 )
			end
		else 
			if Row == line and line == endline then -- Same line selection
				surface_DrawRect( 
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * ( endchar - char ), 
					self.FontHeight 
				 )
			elseif Row == line then -- Selection starts on this line
				surface_DrawRect( 
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * math_min( self.Size.y - char + 2, length - char + 1 ), 
					self.FontHeight 
				 )
			elseif Row == endline then -- Selection ends on this line
				surface_DrawRect( 
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * endchar,  
					self.FontHeight 
				 ) 
			elseif Row > line and Row < endline then -- Selection covers this entire line
				surface_DrawRect( 
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth, 
					( LinePos ) * self.FontHeight, 
					self.FontWidth * math_min( self.Size.y + 2, length + 1 ),  
					self.FontHeight 
				 )
			end
		end 
	end
end

function PANEL:PaintCursor( Caret ) 
	Caret = Caret or self.Caret 
	if self.pTextEntry:HasFocus( ) and self:PositionIsVisible( Caret ) then
		local width, height = self.FontWidth, self.FontHeight
		
		if ( RealTime( ) - self.Blink ) % 0.8 < 0.4 then
			surface_SetDrawColor( 240, 240, 240, 255 )
			local Offset = Caret.x - self.Scroll.x
			local Insert = Caret.Insert or self.Insert 
			Offset = Offset - self:GetFoldingOffset( Caret.x )
			
			if istable( self.Rows[Caret.x] ) and self.Rows[Caret.x].Primary ~= Caret.x then return end 
			 
			if self.Insert or Caret.Insert then 
				surface_DrawRect( ( Caret.y - self.Scroll.y ) * width + self.LinePadding, ( Offset + 1 ) * height, width, 1 )
			else 
				surface_DrawRect( ( Caret.y - self.Scroll.y ) * width + self.LinePadding, Offset * height, 1, height )
			end 
		end
	end
end 

function PANEL:PaintStatus( )
	surface_SetFont( "Trebuchet18" )
	
	local Line = "Length: " .. #self:GetCode( ) .. " Lines: " .. #self.Rows .. " Row: " .. self.Caret.x .. " Col: " .. self.Caret.y
	
	if self:HasSelection( ) then 
		Line = Line .. " Sel: " .. #self:GetSelection( ) 
	end 
	
	local Width, Height = surface_GetTextSize( Line )
	local Wide, Tall = self:GetSize( )
	draw_WordBox( 4, Wide - Width - 20 - ( self.pScrollBar.Enabled and 16 or 0 ) , Tall - Height - 20 - ( self.pHScrollBar.Enabled and 16 or 0 ), Line, "Trebuchet18", Color( 50, 50, 50, 100 ), Color( 235, 235, 235, 255 ) )
end

-- TODO: this 
function PANEL:AddCursor( sID, Caret )
	self.tCursors[sID] = { Caret } 
end

function PANEL:RemoveCursor( sID ) 
	self.tCursors[sID] = nil 
end 

function PANEL:AddSelection( sID, tSelection, cColor, bOutline )
	self.tSelections[sID] = { tSelection, cColor, bOutline } 
end

function PANEL:RemoveSelection( sID ) 
	self.tCursors[sID] = nil 
end 

function PANEL:SyntaxColorLine( Row ) 
	return { { self.Rows[Row], C_white } }
end

function PANEL:UpdateSyntaxColors( )
	self.PaintRows = { } 
end

/*---------------------------------------------------------------------------
Text setters / getters
---------------------------------------------------------------------------*/

function PANEL:SetCode( Text ) 
	self.pScrollBar:SetScroll( 0 ) 
	self.pHScrollBar:SetScroll( 0 ) 
	
	self.Rows = string_Explode( "\n", string.Replace( Text, "\t", "    ") ) 
	self:MakeFoldData( )
	
	self.PaintRows = { } 
	
	self.Caret = Vector2( 1, 1 ) 
	self.Start = Vector2( 1, 1 ) 
	self.Scroll = Vector2( 1, 1 ) 
	
	self:CalculateScroll( ) 
end 

function PANEL:GetCode( )
	local LinesToFold = { } 
	
	for line = 1, #self.Rows do
		if istable( self.Rows[line] ) then 
			LinesToFold[#LinesToFold+1] = line 
			self:ExpandLine( line ) 
		end 
	end
	
	local code = string_gsub( table_concat( self.Rows, "\n" ), "\r", "" )
	
	for i = #LinesToFold, 1, -1 do 
		self:FoldLine( LinesToFold[i] )
	end 
	
	return code
end

function PANEL:OnTextChanged( )
	// Override 
end

/*---------------------------------------------------------------------------
PerformLayout
---------------------------------------------------------------------------*/

function PANEL:CalculateScroll( )
	self.pScrollBar:SetUp( self.Size.x, #self.Rows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ) - self:GetFoldingOffset( #self.Rows ) ) 
	local LongestRow = 0 
	for i = 1, #self.Rows do
		LongestRow = math.max( LongestRow, #self.Rows[i] )
	end
	self.LongestRow = LongestRow
	self.pHScrollBar:SetUp( self.Size.y, LongestRow ) 
end 

function PANEL:PerformLayout( ) 
	local NumberPadding = self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth
	
	self.pScrollBar:SetSize( 16, self:GetTall( ) /*- 16*/ )
	self.pScrollBar:SetPos( self:GetWide( ) - self.pScrollBar:GetWide( ), 0 )
	
	self.pHScrollBar:SetSize( self:GetWide( ) /*- NumberPadding */- self.pScrollBar:GetWide( ), 16 )
	self.pHScrollBar:SetPos(/*NumberPadding*/0, self:GetTall( ) - 16 )
	
	self.Size.x = math_floor( self:GetTall( ) / self.FontHeight ) - 1
	self.Size.y = math_floor( ( self:GetWide( ) - NumberPadding - self.pScrollBar:GetWide( ) ) / self.FontWidth ) - 1
	
	self:CalculateScroll( )
end

vgui.Register( "GOLEM_Editor", PANEL, "EditablePanel" )