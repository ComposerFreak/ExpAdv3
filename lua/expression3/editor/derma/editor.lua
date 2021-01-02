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
local string_match 					= string.match

local table_remove 					= table.remove
local table_insert 					= table.insert
local table_concat 					= table.concat

local surface_SetFont 				= surface.SetFont
local surface_DrawRect 				= surface.DrawRect
local surface_DrawOutlinedRect 		= surface.DrawOutlinedRect
local surface_GetTextSize 			= surface.GetTextSize
local surface_SetDrawColor 			= surface.SetDrawColor
local surface_SetMaterial 			= surface.SetMaterial
local surface_DrawTexturedRect 		= surface.DrawTexturedRect

local input_IsKeyDown 				= input.IsKeyDown

local draw_SimpleText 				= draw.SimpleText
local draw_WordBox 					= draw.WordBox

local BookmarkMaterial 				= Material( "diagona-icons/152.png" )

local C_white = Color( 255, 255, 255 )
local C_black = Color( 0, 0, 0 )

local Golem = Golem
local PANEL = { }

function PANEL:Init( )
	self:SetCursor( "beam" )
	
	self.tRows = { "" }
	self.FoldButtons = { }
	self.tFoldData = { {0, false, false} }
	self.Undo = { }
	self.Redo = { }
	self.Bookmarks = { }
	
	self.tCursors = { }
	self.tSelections = { }
	
	self.Blink = RealTime( )
	self.BookmarkWidth = 16
	self.LineNumberWidth = 2
	self.FoldingWidth = 16
	self.FontHeight = 0
	self.FontWidth = 0
	self.LinePadding = 0
	
	self.Insert = false
	self.bEditable = true
	
	self.pTextEntry = self:Add( "TextEntry" )
	self.pTextEntry:SetMultiline( true )
	self.pTextEntry:SetSize( 0, 0 )
	
	self.pTextEntry.m_bDisableTabbing = true -- OH GOD YES!!!!! NO MORE HACKS!!!
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
	
	-- self.Autocomplete = self:Add( "GOLEM_Autocomplete")
	-- self.Autocomplete.Editor = self
	-- -- self.Autocomplete:SetVisible( false ) 
	-- self.Autocomplete:SetPos( 100, 100 )
	-- self.Autocomplete:SetSize( 600, 200 )
	
	
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

	if self.bCodeFolding then
		self.FoldingWidth = self.FontHeight
		for k, v in pairs( self.FoldButtons ) do
			if IsValid( v ) and ispanel( v ) then
				v:SetSize( self.FontHeight, self.FontHeight )
			end
		end
	else
		self.FoldingWidth = 0
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

	local x, _ = self:CursorPos( )
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


	-- Watered down version for display only
	if not self.bEditable then
		if control then
			if code == KEY_C then
				if self:HasSelection( ) then
					local clipboard = self:GetSelection( )
					clipboard = string_gsub( clipboard, "\n", "\r\n" )
					SetClipboardText( clipboard )
				end
			elseif code == KEY_UP then
				self.Scroll.x = self.Scroll.x - 1
				if self.Scroll.x < 1 then self.Scroll.x = 1 end
				self.pScrollBar:SetScroll( self.Scroll.x -1 )
			elseif code == KEY_DOWN then
				self.Scroll.x = self.Scroll.x + 1
				self.pScrollBar:SetScroll( self.Scroll.x -1 )
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
				self.Caret = Vector2( #self.tRows, 1 )

				self:ScrollCaret( )

				if not shift then
					self.Start = self.Caret:Clone( )
				end
			end
		else -- control
			if code == KEY_UP then
				if self.Caret.x > 1 then
					self:FoldAll( tFolds )
					self.Caret.x = self.Caret.x - 1

					if istable( self.tRows[self.Caret.x] ) and self.tRows[self.Caret.x].Primary ~= self.Caret.x then
						self.Caret.x = self.tRows[self.Caret.x].Primary
					end

					if self.Caret.x < 1 then self.Caret.x = 1 end

					local length = #self.tRows[self.Caret.x]
					if self.Caret.y > length + 1 then
						self.Caret.y = length + 1
					end
					tFolds = self:ExpandAll( )
				end

				self:ScrollCaret( )
				if not shift then
					self.Start = self.Caret:Clone( )
				end
			elseif code == KEY_DOWN then
				if self.Caret.x < #self.tRows then
					self:FoldAll( tFolds )
					self.Caret.x = self.Caret.x + 1

					if istable( self.tRows[self.Caret.x] ) and self.tRows[self.Caret.x].Primary ~= self.Caret.x then
						self.Caret.x = #self.tRows[self.Caret.x] + self.tRows[self.Caret.x].Primary
					end

					if self.Caret.x > #self.tRows then self.Caret.x = #self.tRows end

					local length = #self.tRows[self.Caret.x]
					if self.Caret.y > length + 1 then
						self.Caret.y = length + 1
					end
					tFolds = self:ExpandAll( )
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
			elseif code == KEY_PAGEUP then
				self.Caret.x = math_max( self.Caret.x - math_ceil( self.Size.x / 2 ), 1 )
				self.Caret.y = math_min( self.Caret.y, #self.tRows[self.Caret.x] + 1 )

				self.Scroll.x = math_max( self.Scroll.x - math_ceil( self.Size.x / 2 ), 1 )

				self:ScrollCaret( )

				if not shift then
					self.Start = self.Caret:Clone( )
				end
			elseif code == KEY_PAGEDOWN then
				self.Caret.x = math_min( self.Caret.x + math_ceil( self.Size.x / 2 ), #self.tRows )
				self.Caret.y = self.Caret.x == #self.tRows and 1 or math_min( self.Caret.y, #self.tRows[self.Caret.x] + 1 )

				self.Scroll.x = self.Scroll.x + math_ceil( self.Size.x / 2 )

				self:ScrollCaret( )

				if not shift then
					self.Start = self.Caret:Clone( )
				end
			elseif code == KEY_HOME then
				local row = self.tRows[self.Caret.x]
				local first_char = string_find( row, "%S" ) or #row + 1
				self.Caret.y = self.Caret.y == first_char and 1 or first_char

				self:ScrollCaret( )

				if not shift then
					self.Start = self.Caret:Clone( )
				end
			elseif code == KEY_END then
				self.Caret.y = #self.tRows[self.Caret.x] + 1

				self:ScrollCaret( )

				if not shift then
					self.Start = self.Caret:Clone( )
				end
			end
		end

		self:FoldAll( tFolds )

		return
	end

	if control then
		if code == KEY_A then
			self:SelectAll( )
		elseif code == KEY_Z then
			self:DoUndo( )
		elseif code == KEY_Y then
			self:DoRedo( )
		elseif code == KEY_S then -- Save
			if shift then -- ctrl+shift+s
				self.Master:SaveFile( true, true )
			else -- ctrl+s
				self.Master:SaveFile( true )
			end
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
		elseif code == KEY_F or code == KEY_H then
			local query = self:GetSelection();
			local search = self.Master.pnlSearch;

			if (query ~= "") then
				search:SetQuery(query);
			end

			search:Open();

			if (code == KEY_H) then
				search:ShowReplace();
			end
		elseif code == KEY_UP then
			if shift then
				if self:HasSelection( ) then
					local start, stop = self:MakeSelection( self:Selection( ) )
					if start.x > 1 then
						local data = table_remove( self.tRows, start.x - 1 )
						table_insert( self.tRows, stop.x, data )
						self.Start:Add( -1, 0 )
						self.Caret:Add( -1, 0 )
						self.tSyntax:Parse( )
						self:ScrollCaret( )
					end
				elseif self.Caret.x > 1 then
					local data = table_remove( self.tRows, self.Caret.x )
					self:SetCaret( self.Caret:Add( -1, 0 ) )
					table_insert( self.tRows, self.Caret.x, data )
					self.tSyntax:Parse( )
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
					if stop.x < #self.tRows then
						local data = table_remove( self.tRows, stop.x + 1 )
						table_insert( self.tRows, start.x, data )
						self.Start:Add( 1, 0 )
						self.Caret:Add( 1, 0 )
						self.tSyntax:Parse( )
						self:ScrollCaret( )
					end
				elseif self.Caret.x < #self.tRows then
					local data = table_remove( self.tRows, self.Caret.x )
					self:SetCaret( self.Caret:Add( 1, 0 ) )
					table_insert( self.tRows, self.Caret.x, data )
					self.tSyntax:Parse( )
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
			self.Caret = Vector2( #self.tRows, 1 )

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
			if ( str ~= "" ) then -- If you have a selection
				self:SetSelection( str:rep( 2 ) ) -- Repeat it
			else -- If you don't
				-- Select the current line
				self.Start = Vector2( self.Start.x, 1 )
				self.Caret = Vector2( self.Start.x, #self.tRows[self.Start.x] + 1 )
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
		elseif code == KEY_SPACE then
			self.Master:DoValidate( true )
		elseif code == KEY_BACKSPACE then 
			if self:HasSelection() then 
				self:FoldAll( tFolds )
				self:SetSelection( "" )
				tFolds = self:ExpandAll( )
			else
				self.Start = self:wordLeft( self.Caret, true ) 
				if self.Start.y <= 0 then self.Start.y = 1 end 
				if self.Start.x <= 0 then self.Start.x = 1 end 
				self:SetSelection( "" )
				self:ScrollCaret( )
			end 
		end
	else
		if code == KEY_ENTER then
			local Line = self.tRows[self.Caret.x]
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
				self:FoldAll( tFolds )
				self.Caret.x = self.Caret.x - 1

				if istable( self.tRows[self.Caret.x] ) and self.tRows[self.Caret.x].Primary ~= self.Caret.x then
					self.Caret.x = self.tRows[self.Caret.x].Primary
				end

				if self.Caret.x < 1 then self.Caret.x = 1 end

				local length = #self.tRows[self.Caret.x]
				if self.Caret.y > length + 1 then
					self.Caret.y = length + 1
				end
				tFolds = self:ExpandAll( )
			end

			self:ScrollCaret( )
			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_DOWN then
			if self.Caret.x < #self.tRows then
				self:FoldAll( tFolds )
				self.Caret.x = self.Caret.x + 1

				if istable( self.tRows[self.Caret.x] ) and self.tRows[self.Caret.x].Primary ~= self.Caret.x then
					self.Caret.x = #self.tRows[self.Caret.x] + self.tRows[self.Caret.x].Primary
				end

				if self.Caret.x > #self.tRows then self.Caret.x = #self.tRows end

				local length = #self.tRows[self.Caret.x]
				if self.Caret.y > length + 1 then
					self.Caret.y = length + 1
				end
				tFolds = self:ExpandAll( )
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
				if self.Caret.y % 4 == 1 and string_rep( " ", #buffer ) == buffer and #self.tRows[self.Caret.x] >= self.Caret.y + 4 - 1 then
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, 4 ) }, "" ) )
				else
					self:SetCaret( self:SetArea( { self.Caret, self:MovePosition( self.Caret, 1 ) }, "" ) )
				end
			end
		elseif code == KEY_PAGEUP then
			self.Caret.x = math_max( self.Caret.x - math_ceil( self.Size.x / 2 ), 1 )
			self.Caret.y = math_min( self.Caret.y, #self.tRows[self.Caret.x] + 1 )

			self.Scroll.x = math_max( self.Scroll.x - math_ceil( self.Size.x / 2 ), 1 )

			self:ScrollCaret( )

			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_PAGEDOWN then
			self.Caret.x = math_min( self.Caret.x + math_ceil( self.Size.x / 2 ), #self.tRows )
			self.Caret.y = self.Caret.x == #self.tRows and 1 or math_min( self.Caret.y, #self.tRows[self.Caret.x] + 1 )

			self.Scroll.x = self.Scroll.x + math_ceil( self.Size.x / 2 )

			self:ScrollCaret( )

			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_HOME then
			local row = self.tRows[self.Caret.x]
			local first_char = string_find( row, "%S" ) or #row + 1
			self.Caret.y = self.Caret.y == first_char and 1 or first_char

			self:ScrollCaret( )

			if not shift then
				self.Start = self.Caret:Clone( )
			end
		elseif code == KEY_END then
			self.Caret.y = #self.tRows[self.Caret.x] + 1

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
					self.Caret:Set( Caret.x, #self.tRows[Caret.x] + 1 )

					local text = string_match( self.tRows[Caret.x], "^ ? ? ? ?(.*)$" )
					local oldLength = #self.tRows[Caret.x]

					self:SetSelection( text )

					self.Caret = self:MovePosition( Caret, #text - oldLength )
					self.Start = self.Caret:Clone( )
				else
					-- self:FoldAll( tFolds )
					self:SetSelection( "" )
					-- tFolds = self:ExpandAll( )
				end
			else
				if code == KEY_O then
					local Caret = self.Caret:Clone( )

					self.Start:Set( self.Start.x, 1 )
					self.Caret:Set( Caret.x, #self.tRows[Caret.x] + 1 )

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
	if not self.bEditable then return end
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
	if not ctrlv and text == "\n" then return end

	local bSelection = self:HasSelection( )
	local cChar = self.tRows[self.Caret.x][self.Caret.y]

	-- print( string.format("%q",text), string.format("%q",cChar) )
	
	if bSelection then
		local selection = self:Selection( )
		local selectionText = self:GetArea( selection )
		local bMultiline = selection[1].x ~= selection[2].x
		
		if #text == 1 and AutoParam[text] then
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
		
	elseif #text == 1 then 
		if AutoParam[text] then 
			if AutoParam[text][2] then -- ([{
				if cChar == "" or cChar == " " or (AutoParam[cChar] and AutoParam[cChar][2] ) then
					self:SetSelection( text .. AutoParam[text][1] )
					self:SetCaret( self:MovePosition( self.Caret, -1 ) )
				elseif AutoParam[cChar] or SpecialCase[cChar] then 
					self:SetSelection( text .. AutoParam[text][1] )
					self:SetCaret( self:MovePosition( self.Caret, -1 ) )
				else 
					self:SetSelection( text )
				end
			else -- "'
				if cChar == "" or cChar == " " or (AutoParam[cChar] and AutoParam[cChar][2] ) then
					self:SetSelection( text .. AutoParam[text][1] )
					self:SetCaret( self:MovePosition( self.Caret, -1 ) )
				elseif cChar == '"' or cChar == "'" then
					self:SetCaret( self:MovePosition( self.Caret, 1 ) )
				elseif SpecialCase[cChar] then 
					self:SetSelection( text .. AutoParam[text][1] )
					self:SetCaret( self:MovePosition( self.Caret, -1 ) )
				else 
					self:SetSelection( text )
				end
			end 
		elseif SpecialCase[text] and cChar == text then 
			self:SetCaret( self:MovePosition( self.Caret, 1 ) )
		else
			self:SetSelection( text )
		end 
	else
		self:SetSelection( text )
	end
	self:ScrollCaret( )
end

function PANEL:SetEditable( bValue )
	self.bEditable = bValue
end

/*---------------------------------------------------------------------------
Mouse stuff
---------------------------------------------------------------------------*/

function PANEL:ClickText( cursor )
	return false;
end

function PANEL:OnMousePressed( code )
	if self.MouseDown then return end

	local x, _ = self:CursorPos( )
	if x < self.LinePadding then return end

	if code == MOUSE_LEFT then
		local cursor = self:CursorToCaret( )
		if self.LastClick and CurTime( ) - self.LastClick < 0.3 and ( self.Caret == cursor or self.LastCursor == cursor ) then
			if self:ClickText( cursor ) then
				-- Do nothing.
			elseif self.temp then
				self.temp = nil

				self.Start = Vector2( cursor.x, 1 )
				local s = self:ExpandAll( )
				self.Caret = Vector2( cursor.x, #self.tRows[cursor.x]+1 )
				self:FoldAll( s )
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

				if self.bEditable then
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
			end

			if self.bEditable then
				Menu:AddOption( "Paste", function( ) self.pTextEntry:Paste( ) end )
			end

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
		if self.Scroll.x > #self.tRows then self.Scroll.x = #self.tRows end
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

	if line > #self.tRows then line = #self.tRows end
	local length = #( istable( self.tRows[line] ) and self.tRows[line][1] or self.tRows[line] )
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
		if istable( self.tRows[caret.x] ) and self.tRows[caret.x].Primary ~= caret.x then
			while istable( self.tRows[caret.x] ) do
				caret.x = caret.x + 1
			end
			caret.y = 1
		else
			while true do
				local length = #( istable( self.tRows[caret.x] ) and self.tRows[caret.x][1] or self.tRows[caret.x] ) - caret.y + 2

				if offset < length then
					caret.y = caret.y + offset
					break
				elseif caret.x == #self.tRows then
					caret.y = caret.y + length - 1
					break
				else
					if istable( self.tRows[caret.x + 1] ) then
						caret.x = caret.x + #self.tRows[caret.x + 1]
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

		if istable( self.tRows[caret.x] ) and self.tRows[caret.x].Primary ~= caret.x then
			caret.x = self.tRows[caret.x].Primary
			caret.y = #self.tRows[caret.x][1] + 1
		else
			while true do
				if offset < caret.y then
					caret.y = caret.y - offset
					break
				elseif caret.x == 1 then
					caret.y = 1
					break
				else
					if istable( self.tRows[caret.x - 1] ) then
						caret.x = caret.x - #self.tRows[caret.x - 1]
					else
						caret.x = caret.x - 1
					end
					offset = offset - caret.y
					if istable( self.tRows[caret.x] ) then
						caret.y = #self.tRows[caret.x][1] + 1 - offset
					else
						caret.y = #self.tRows[caret.x] + 1 - offset
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
	return self.Caret ~= self.Start
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
	if istable( self.tRows[start.x] ) then
		start = Vector2( self.tRows[start.x].Primary, #self.tRows[self.tRows[start.x].Primary][1] )
	end

	if istable( self.tRows[stop.x] ) then
		local x = self.tRows[start.x].Primary
		stop = Vector2( self.tRows[x][#self.tRows[x]], 1 )
	end
	*/

	return start, stop
end

function PANEL:SelectAll( )
	self.Caret = Vector2( #self.tRows, istable( self.tRows[#self.tRows] ) and #self.tRows[self.tRows[#self.tRows].Primary][1] or #self.tRows[#self.tRows] + 1 )
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

			text = string_sub( self.tRows[start.x], start.y, start.y )
		else
			text = string_sub( self.tRows[start.x], start.y, stop.y - 1 )
		end
	else
		text = string_sub( self.tRows[start.x], start.y )

		for i = start.x + 1, stop.x - 1 do
			text = text .. "\n" .. self.tRows[i]
		end

		text =  text .. "\n" .. string_sub( self.tRows[stop.x], 1, stop.y - 1 )
	end

	self:FoldAll( LinesToFold )

	return text
end

function PANEL:SetArea( selection, text, isundo, isredo, before, after )
	local buffer = self:GetArea( selection )
	local start, stop = self:MakeSelection( selection )
	local LinesToFold = { }

	for line = 1, #self.tRows do
		LinesToFold[line] = istable( self.tRows[line] )
		if istable( self.tRows[line] ) then
			self:ExpandLine( line )
		end
	end

	if start ~= stop then
		-- Merge first and last line
		self.tRows[start.x] = string_sub( self.tRows[start.x], 1, start.y - 1 ) .. string_sub( self.tRows[stop.x], stop.y )

		-- Remove deleted lines
		for i = start.x + 1, stop.x do
			table_remove( self.tRows, start.x + 1 )
			table_remove( self.tFoldData, start.x + 1 )
			table_remove( LinesToFold, start.x + 1 )
		end
	end

	if not text or text == "" then
		self.pScrollBar:SetUp( self.Size.x, #self.tRows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ) )
		self:CalculateScroll( )
		self.tSyntax:Parse( )
		self:TextChanged( selection, text )
		if self.bCodeFolding then self.tSyntax:MakeFoldData( ) end

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

	-- insert text
	local rows = string_Explode( "\n", text )

	local remainder = string_sub( self.tRows[start.x], start.y )
	self.tRows[start.x] = string_sub( self.tRows[start.x], 1, start.y - 1 ) .. rows[1]

	for i = 2, #rows do
		table_insert( self.tRows, start.x + i - 1, rows[i] )
		table_insert( LinesToFold, start.x + i - 1, false )
	end
	self.tFoldData = { }

	local stop = Vector2( start.x + #rows - 1, #self.tRows[start.x + #rows - 1] + 1 )

	self.tRows[stop.x] = self.tRows[stop.x] .. remainder

	self.pScrollBar:SetUp( self.Size.x, #self.tRows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ))
	self:CalculateScroll( )
	self.tSyntax:Parse( )
	self:TextChanged( selection, text )
	if self.bCodeFolding then self.tSyntax:MakeFoldData( ) end

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

function PANEL:TextChanged( tSelection, sText )
	self.tSyntax:Parse( )
	if self.OnTextChanged then self:OnTextChanged( tSelection, sText ) end
	-- if self.Autocomplete then self.Autocomplete:Update( tSelection, sText ) end 
end

-- Might need fixing
function PANEL:Indent( Shift )
	local oldSelection = { self:MakeSelection( self:Selection( ) ) }
	local Scroll = self.Scroll:Clone( )
	local Start, End = oldSelection[1]:Clone( ), oldSelection[2]:Clone( )
	local slen, elen = #self.tRows[Start.x], #self.tRows[End.x]

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

	if Shift then -- Unindent
		local Temp = string_gsub( self:GetSelection( ), "\n ? ? ? ?", "\n" )
		self:SetSelection( string_match( Temp, "^ ? ? ? ?(.*)$") )
	else -- Indent
		self:SetSelection( "    " .. string_gsub( self:GetSelection( ), "\n", "\n    " ) )
	end

	self.Start = oldSelection[1]:Clone( ):Add( 0, #self.tRows[oldSelection[1].x] - slen )
	self.Caret = oldSelection[2]:Clone( ):Add( 0, #self.tRows[oldSelection[2].x] - elen )

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

function PANEL:wordLeft( caret, bNoMove )
	local tFolds = self:ExpandAll( )
	local row = self.tRows[caret.x]
	if caret.y == 1 then
		if caret.x == 1 then return caret end
		return Vector2( caret.x-1, #self.tRows[caret.x-1] )
	end
	local pos = string_match( string_sub( row, 1, caret.y - 2 ), ".+()%f[%p ]" )
	if pos then pos = pos + 1 end
	if not bNoMove then caret.y = pos or 1 end
	self:FoldAll( tFolds )
	return Vector2( caret.x, pos or 1 )
end

function PANEL:wordRight( caret, bNoMove )
	local tFolds = self:ExpandAll( )
	local row = self.tRows[caret.x]
	if caret.y > #row then
		if caret.x == #self.tRows then return caret end
		return Vector2( caret.x + 1, 1 )
	end
	local pos = string_match( row, "%f[%p ]()", caret.y+1 )
	if not bNoMove then caret.y = pos or ( #row + 1 ) end
	self:FoldAll( tFolds )
	return Vector2( caret.x, pos or ( #row + 1 ) )
end

function PANEL:wordStart( caret )
	local tFolds = self:ExpandAll( )
	local line = self.tRows[caret.x]
	self:FoldAll( tFolds )

	if string_match( string_sub( line, caret.y-1, caret.y ), "[^%w][^%w]" ) then
		local pos = string_match( string_sub( line, 1, caret.y ), ".+()%f[^%w]" )
		pos = (pos or 1)
		return Vector2( caret.x, pos )
	else
		local pos = string_match( string_sub( line, 1, caret.y ), ".+()%f[%w]" )
		pos = (pos or 1)
		return Vector2( caret.x, pos )
	end
end

function PANEL:wordEnd( caret )
	local tFolds = self:ExpandAll( )
	local line = self.tRows[caret.x]
	self:FoldAll( tFolds )

	if string_match( string_sub( line, caret.y-1, caret.y ), "[^%w][^%w]" ) then
		local pos = string_match( line, "()%f[%w]", caret.y )
		pos = pos or (#line + 1)
		return Vector2( caret.x, pos )
	else
		local pos = string_match( line, "()%f[^%w]", caret.y )
		pos = pos or (#line + 1)
		return Vector2( caret.x, pos )
	end
end

/*---------------------------------------------------------------------------
Code folding
---------------------------------------------------------------------------*/
function PANEL:GetFoldingOffset( nLine )
	if not self.bCodeFolding then return 0 end
	local offset = 0
	local pos = 1
	local infloop = 0

	while pos < nLine and infloop < 10000 do
		if istable( self.tRows[pos] ) then
			offset = offset + #self.tRows[pos] - 1
			pos = pos + #self.tRows[pos]
		elseif self.tFoldData[pos] and self.tFoldData[pos][2] then
			local level = self.tFoldData[pos+1][1]
			pos = pos + 1
			while level <= self.tFoldData[pos][1] and infloop < 10000  do
				if self.tFoldData[pos][3] then break end
				pos = pos + 1
				offset = offset + 1
				infloop = infloop + 1
			end
		else
			pos = pos + 1
		end

		infloop = infloop + 1
	end

	return offset
end

function PANEL:ExpandAll( tOld )
	if not self.bCodeFolding then return end
	if type( tOld ) == "table" then
		for i = 1, #tOld do
			self:ExpandLine( tOld[i], true )
		end
		return true
	else
		local ExpandedLines = { }

		for line = 1, #self.tRows do
			local Line = self.tRows[line]
			if type( Line ) == "table" and Line.Primary == line then
				ExpandedLines[#ExpandedLines+1] = line
				self:ExpandLine( line, true )
			end
		end

		return ExpandedLines
	end
end

function PANEL:FoldAll( tOld )
	if not self.bCodeFolding then return end
	if type( tOld ) == "table" then
		for i = #tOld, 1, -1 do
			self:FoldLine( tOld[i], true )
		end
		return true
	else
		local FoldedLines = { }
		local last = 0

		if #self.tFoldData < #self.tRows then self.tSyntax:MakeFoldData( ) end

		for line = #self.tRows, 1, -1 do
			local Fold = self.tFoldData[line]
			if Fold[1] < last or Fold[3] then
				FoldedLines[#FoldedLines+1] = line
				self:FoldLine( line, true )
			end
		end

		return FoldedLines
	end
end

function PANEL:FoldLine( nLine, bInternal )
	if not self.bCodeFolding then return end
	if istable( self.tRows[nLine] ) or not self.tRows[nLine] then return print( "Tried to fold already folded line!", nLine ) end
	if self.tFoldData[nLine][1] == self.tFoldData[nLine+1][1] and not self.tFoldData[nLine][3] then return end
	if self.tFoldData[nLine][1] > self.tFoldData[nLine+1][1] then return end
	local Data = { self.tRows[nLine] }
	local FoldLevel = self.tFoldData[nLine+1][1]
	if not bInternal then self.tFoldData[nLine][2] = true end
	self.tRows[nLine] = Data
	Data.Primary = nLine

	for i = nLine + 1, #self.tRows do
		if self.tFoldData[i][1] >= FoldLevel or self.tFoldData[nLine][3] then
			if self.tFoldData[nLine][3] and self.tFoldData[i][3] then break end
			if self.tFoldData[i][3] and self.tFoldData[i][1] == FoldLevel then break end
			if self.tFoldData[i][1] < FoldLevel then break end
			Data[#Data+1] = self.tRows[i]
			self.tRows[i] = Data
		else
			break
		end
	end
end

function PANEL:ExpandLine( nLine, bInternal )
	if not self.bCodeFolding then return end
	if not bInternal then self.tFoldData[nLine][2] = false end
	local Data = self.tRows[nLine]
	if not istable( Data ) then return print( "Tried to unfold invalid line", nLine, type( Data ) ) end

	if Data.Primary == nLine then
		self.tRows[nLine] = Data[1]
		for i = 2, #Data do
			self.tRows[nLine+i-1] = Data[i]
		end
	else
		local subfolds = false
		for i = 1, #Data do
			self.tRows[Data.Primary+i-1] = Data[i]

			if istable( Data[i] ) and Data[i].Primary == Data.Primary+i-1 and (Data.Primary+i-1 <= nLine and Data[i].Primary+#Data[i]-1 >= nLine) then
				subfolds = true
			end
		end

		if subfolds then self:ExpandLine( nLine ) end
	end
end

/*---------------------------------------------------------------------------
Syntaxer functions
---------------------------------------------------------------------------*/

function PANEL:SetSyntax( tSyntaxer )
	self.tSyntax = tSyntaxer
end

function PANEL:SetCodeFolding( bActive )
	self.bCodeFolding = bActive
	if bActive then
		self.FoldingWidth = self.FontHeight
		for k, v in pairs( self.FoldButtons ) do
			if IsValid( v ) and ispanel( v ) then
				v:SetSize( self.FontHeight, self.FontHeight )
			end
		end
	else
		self.FoldingWidth = 0
	end
end

function PANEL:SetParamMatching( bActive )
	self.bParamMatching = bActive
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
	local tStart, _ = self:MakeSelection( self:Selection( ) )
	local pos = tStart.x

	while true do
		pos = pos + 1
		if pos > #self.tRows then pos = 1 end
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
	local tStart, _ = self:MakeSelection( self:Selection( ) )
	local pos = tStart.x

	while true do
		pos = pos - 1
		if pos <= 0 then pos = #self.tRows end
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

	self.LineNumberWidth = 6 + self.FontWidth * string_len( tostring( math_min( self.Scroll.x, #self.tRows - self.Size.x + 1 ) + self.Size.x - 1 ) )
	self.LinePadding = self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth

	h = h - (self.pHScrollBar.Enabled and 16 or 0)
	w = w - (self.pScrollBar.Enabled and 16 or 0)

	surface_SetDrawColor( 0, 0, 0, 255 )
	if GOLEM_LIGHT then surface_SetDrawColor( 255, 255, 255, 255 ) end 
	surface_DrawRect( 0, 0, w, h )

	surface_SetDrawColor( 32, 32, 32, 255 )
	if GOLEM_LIGHT then surface_SetDrawColor( 255, 255, 255, 255 ) end 
	surface_DrawRect( 0, 0, self.LinePadding, h )

	if self.bParamMatching then
		self.Params = self.tSyntax:FindMatchingParam( self.Caret.x, self.Caret.y )
	end

	if self.MouseDown and self.MouseDown == MOUSE_LEFT then
		self.Caret = self:CursorToCaret( )
	end

	self.Scroll.x = math_floor( self.pScrollBar:GetScroll( ) + 1 )
	self.Scroll.y = math_floor( self.pHScrollBar:GetScroll( ) + 1 )

	if self.bCodeFolding then
		for k, v in pairs( self.FoldButtons ) do
			if IsValid( v ) and ispanel( v ) then
				v:SetVisible( false )
			end
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

		if istable( self.tRows[line] ) then
			if self.tRows[line].Primary ~= line then
				line = line + #self.tRows[line] - (line - self.tRows[line].Primary) - 1
				continue
			end
			local Data = self.tRows[line]
			self.tRows[line] = Data[1]
			self:DrawRow( line, painted, true )
			self.tRows[line] = Data
			line = line + #self.tRows[line] - 1
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
		if not self.tFoldData[btn.Row] then return end
		if self.tFoldData[btn.Row][2] then
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
	if Row > #self.tRows then return end
	
	if GOLEM_LIGHT then
		draw_SimpleText( tostring( Row ), self.Font, self.BookmarkWidth + self.LineNumberWidth, self.FontHeight * LinePos, C_black, TEXT_ALIGN_RIGHT )
	else 
		draw_SimpleText( tostring( Row ), self.Font, self.BookmarkWidth + self.LineNumberWidth, self.FontHeight * LinePos, C_white, TEXT_ALIGN_RIGHT )
	end 

	if editor_debug_folding then
		surface_SetDrawColor( 0, 200, 255 )
		surface_DrawRect( self.LinePadding, self.FontHeight * LinePos, self.FontWidth * self.tFoldData[Row][1], self.FontHeight )

		if Row < #self.tRows and self.tFoldData[Row][1] < self.tFoldData[Row+1][1] then
			surface_SetDrawColor( 0, 160, 0 )
			surface_DrawRect( self.LinePadding + self.FontWidth * self.tFoldData[Row][1], self.FontHeight * LinePos, self.FontWidth * (self.tFoldData[Row+1][1]-self.tFoldData[Row][1]), self.FontHeight )
		end

		if Row > 1 and Row <= #self.tRows and self.tFoldData[Row-1][1] > self.tFoldData[Row][1] then
			surface_SetDrawColor( 160, 0, 0 )
			surface_DrawRect( self.LinePadding + self.FontWidth * self.tFoldData[Row][1], self.FontHeight * LinePos, self.FontWidth * (self.tFoldData[Row-1][1]-self.tFoldData[Row][1]), self.FontHeight )
		end

		if Row > 1 and Row < #self.tRows and self.tFoldData[Row][3] then
			surface_SetDrawColor( 160, 160, 0 )
			surface_DrawRect( self.LinePadding + self.FontWidth * self.tFoldData[Row][1], self.FontHeight * LinePos, self.FontWidth * 1, self.FontHeight )
		end
	end

	-- Setup buttons for codefolding
	if Row < #self.tRows and self.bCodeFolding and (self.tFoldData[Row][1] < self.tFoldData[Row+1][1] or self.tFoldData[Row][3]) then
		if not IsValid( self.FoldButtons[Row] ) or not ispanel( self.FoldButtons[Row]) then
			self.FoldButtons[Row] = MakeFoldButton( self )
		end
		self.FoldButtons[Row].Row = Row
		self.FoldButtons[Row]:SetVisible( true )
		self.FoldButtons[Row]:SetPos( self.BookmarkWidth + self.LineNumberWidth, LinePos * self.FontHeight )
	end

	if self.Bookmarks[Row] then
		surface_SetDrawColor( 255, 255, 255, 255 )
		surface_SetMaterial( BookmarkMaterial )
		surface_DrawTexturedRect( 3, LinePos * self.FontHeight, 16, 16 )
	end

	local offset = -self.Scroll.y + 1
	for i, cell in ipairs( self.tSyntax:GetSyntax( Row ) ) do
		if not cell[1] then
			cell[1] = ""
			cell[2] = C_white
		end

		if cell[3] then
			local mat = cell[4]
			if type( mat ) == "IMaterial" then
				local w, h = mat:Width( ), mat:Height( )
				local x, y = 0, (LinePos + 1) * self.FontHeight - self.FontHeight/2 - h/2

				if offset >= 0 then
					x = offset * self.FontWidth + self.LinePadding

					surface_SetDrawColor( 255, 255, 255, 255 )
					surface_SetMaterial( mat )
					surface_DrawTexturedRect( x, y, w, h )
				end
			end
		end

		local len = #cell[1]
		if offset < 0 then
			if len > -offset then
				local line = cell[1]:sub( 1 - offset )
				offset = #line
				draw_SimpleText( line, self.Font, self.LinePadding, LinePos * self.FontHeight, cell[2] )
			else
				offset = offset + len
			end
		else
			draw_SimpleText( cell[1], self.Font, offset * self.FontWidth + self.LinePadding, LinePos * self.FontHeight, cell[2] )
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
		if Row > #self.tRows then break end
		if istable( self.tRows[Row] ) and self.tRows[Row].Primary ~= Row then continue end
		local length = istable( self.tRows[Row] ) and #self.tRows[Row][1] or #self.tRows[Row]
		length = length - self.Scroll.y + 1
		LinePos = LinePos + 1

		surface_SetDrawColor( color )
		if outline then
			if Row == line and line == endline then -- Same line selection
				surface_DrawOutlinedRect(
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
					self.FontWidth * ( endchar - char ),
					self.FontHeight
				 )
			elseif Row == line then -- Selection starts on this line
				surface_DrawOutlinedRect(
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
					self.FontWidth * math_min( self.Size.y - char + 2, length - char + 1 ),
					self.FontHeight
				 )
			elseif Row == endline then -- Selection ends on this line
				surface_DrawOutlinedRect(
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
					self.FontWidth * endchar,
					self.FontHeight
				 )
			elseif Row > line and Row < endline then -- Selection covers this entire line
				surface_DrawOutlinedRect(
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
					self.FontWidth * math_min( self.Size.y + 2, length + 1 ),
					self.FontHeight
				 )
			end
		else
			if Row == line and line == endline then -- Same line selection
				surface_DrawRect(
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
					self.FontWidth * ( endchar - char ),
					self.FontHeight
				 )
			elseif Row == line then -- Selection starts on this line
				surface_DrawRect(
					char * self.FontWidth + self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
					self.FontWidth * math_min( self.Size.y - char + 2, length - char + 1 ),
					self.FontHeight
				 )
			elseif Row == endline then -- Selection ends on this line
				surface_DrawRect(
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
					self.FontWidth * endchar,
					self.FontHeight
				 )
			elseif Row > line and Row < endline then -- Selection covers this entire line
				surface_DrawRect(
					self.BookmarkWidth + self.LineNumberWidth + self.FoldingWidth,
					LinePos * self.FontHeight,
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
			if GOLEM_LIGHT then surface_SetDrawColor( 0, 0, 0, 255 ) end 
			
			local Offset = Caret.x - self.Scroll.x
			local Insert = Caret.Insert or self.Insert
			Offset = Offset - self:GetFoldingOffset( Caret.x )

			if istable( self.tRows[Caret.x] ) and self.tRows[Caret.x].Primary ~= Caret.x then return end

			if Insert then
				surface_DrawRect( ( Caret.y - self.Scroll.y ) * width + self.LinePadding, ( Offset + 1 ) * height, width, 1 )
			else
				surface_DrawRect( ( Caret.y - self.Scroll.y ) * width + self.LinePadding, Offset * height, 1, height )
			end
		end
	end
end

function PANEL:PaintStatus( )
	surface_SetFont( "Trebuchet18" )

	local Line = "Length: " .. #self:GetCode( ) .. " Lines: " .. #self.tRows .. " Row: " .. self.Caret.x .. " Col: " .. self.Caret.y

	if self:HasSelection( ) then
		Line = Line .. " Sel: " .. #self:GetSelection( )
	end

	local Width, Height = surface_GetTextSize( Line )
	local Wide, Tall = self:GetSize( )
	
	if GOLEM_LIGHT then 
		draw_WordBox( 4, Wide - Width - 20 - ( self.pScrollBar.Enabled and 16 or 0 ) , Tall - Height - 20 - ( self.pHScrollBar.Enabled and 16 or 0 ), Line, "Trebuchet18", Color( 50, 50, 50, 100 ), Color( 50, 50, 50, 255 ) )
	else 
		draw_WordBox( 4, Wide - Width - 20 - ( self.pScrollBar.Enabled and 16 or 0 ) , Tall - Height - 20 - ( self.pHScrollBar.Enabled and 16 or 0 ), Line, "Trebuchet18", Color( 50, 50, 50, 100 ), Color( 235, 235, 235, 255 ) )
	end
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

/*---------------------------------------------------------------------------
Text setters / getters
---------------------------------------------------------------------------*/

function PANEL:SetCode( Text, bFormat )
	self.pScrollBar:SetScroll( 0 )
	self.pHScrollBar:SetScroll( 0 )

	if bFormat and self.tSyntax.Format then Text = self.tSyntax:Format( Text ) end

	self.tRows = string_Explode( "\n", string_gsub( Text, "\t", "    ") )
	if self.bCodeFolding then self.tSyntax:MakeFoldData( ) end

	self.tSyntax:Parse( )

	self.Caret = Vector2( 1, 1 )
	self.Start = Vector2( 1, 1 )
	self.Scroll = Vector2( 1, 1 )

	self:CalculateScroll( )
end

function PANEL:GetCode( )
	local LinesToFold = { }

	for line = 1, #self.tRows do
		if istable( self.tRows[line] ) then
			LinesToFold[#LinesToFold+1] = line
			self:ExpandLine( line )
		end
	end

	local code = string_gsub( table_concat( self.tRows, "\n" ), "\r", "" )

	for i = #LinesToFold, 1, -1 do
		self:FoldLine( LinesToFold[i] )
	end

	return code
end

/*---------------------------------------------------------------------------
PerformLayout
---------------------------------------------------------------------------*/

function PANEL:CalculateScroll( )
	self.pScrollBar:SetUp( self.Size.x, #self.tRows + ( math_floor( self:GetTall( ) / self.FontHeight ) - 2 ) - self:GetFoldingOffset( #self.tRows ) )
	local LongestRow = 0
	for i = 1, #self.tRows do
		LongestRow = math.max( LongestRow, #self.tRows[i] )
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
