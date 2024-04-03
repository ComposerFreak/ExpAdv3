
if SERVER then 
	
	local Sessions = { }
	
	Golem.Share = { Sessions = Sessions }
	
	do 
		local meta = { }
		meta.__index = meta
		meta.__type = "session"
		
		function meta:Invite( pUser, pTarget, bEdit ) 
			if not self.Users[pUser] or self.Users[pUser].Rank ~= 3 then return end 
			if self.Users[pTarget] or self.Invites[pTarget] then return end 
			
			self.Invites[pTarget] = nRank or 1
			
			SendInvite( self, pTarget ) -- TODO
		end 
		
		function meta:Kick( pUser, pTarget ) 
			if not self.Users[pUser] or self.Users[pUser].Rank ~= 3 then return end 
			if not self.Users[pTarget] and not self.Invites[pTarget] then return end 
			
			self.Users[pTarget] = nil
			self.Invites[pTarget] = nil
			
			RemoveSession( self, pTarget ) -- TODO
		end
		
		function meta:Join( pUser ) 
			if self.Users[pUser] then return end 
			if self.Invites[pUser] then 
				self.Users[pUser] = { 
					User = pPlayer, 
					Rank = 1, 
					Connected = false,
				}
				self.Invites[pUser] = nil
			elseif self.Mode == 3 then 
				self.Users[pUser] = { 
					User = pPlayer, 
					Rank = 1, 
					Connected = false,
				}
			end 
		end
		
		function meta:Leave( pUser ) 
			if not self.Users[pUser] then return end 
			self.Users[pUser] = nil
		end 
		
		function meta:Connect( pUser ) 
			if not self.Users[pUser] then return end 
			self.Users[pUser].Connected = true 
			
			-- TODO Send Code
			net.Start( "golem.share.message" )
				net.WriteUInt( 4, 4 )
				net.WritePlayer( pUser ) 
			net.Send( self.Host )
		end 
		
		function meta:Disconnect( pUser ) 
			if not self.Users[pUser] then return end 
			self.Users[pUser].Connected = false 
		end 
		
		function meta:Access( pUser, nState ) 
			if not self.Users[pUser] or self.Users[pUser].Rank ~= 3 then return end 
			self.Access = math.Clamp( nState or self.Access, 1, 3 )
		end 
		
		function meta:Mode( pUser, nState ) 
			if not self.Users[pUser] or self.Users[pUser].Rank ~= 3 then return end 
			self.Mode = math.Clamp( nState or self.Mode, 1, 3 )
		end 
		
		function meta:Permission( pUser, pTarget, nRank ) 
			if not self.Users[pUser] or self.Users[pUser].Rank ~= 3 then return end 
			if not self.Users[pTarget] then return end
			nRank = math.Clamp( nRank, 1, 3 )
			if pUser ~= self.Host and ( nRank == 3 or self.Users[pTarget].Rank == 3 ) then return end -- Only host can change admin rank
			
			self.Users[pTarget].Rank = nRank
			
			-- TODO Update user
		end 
		
		function meta:Sync( )
			net.Start( "golem.share.session" )
				net.WriteUInt( 1, 4 )
				net.WriteUInt( self.ID, 16 ) 
				net.WriteString( self.Name )
				net.WriteUInt( self.Access, 2 )
				net.WriteUInt( self.Mode, 2 )
				net.WritePlayer( self.Host )
				net.WriteTable( self.Users )
				
			if self.Access == 3 then 
				net.Broadcast( )
			else
				local tFilter = RecipientFilter( )
				tFilter.AddPlayers( table.GetKeys( self.Users ) )
				tFilter.AddPlayers( table.GetKeys( self.Invites ) )
				net.Send( tFilter )
			end 
		end
		
		
		function Golem.Share.CreateSession( pPlayer, sName, nAccess, nMode )
			local nID = table.maxn( Sessions ) + 1
			if not sName or sName == "" then sName = "Shared Session #" .. nID end
			nAccess = nAccess or 1
			nMode = nMode or 1
			
			local sSession = setmetatable( {
				ID = nID,
				Name = sName,
				Host = pPlayer,
				Users = { [pPlayer] = { User = pPlayer, Rank = 3, Connected = true } },
				Invites = { },
				Access = 1, -- 1-Private, 2-Whitelist, 3-public
				Mode = 1, -- 1-View, 2-Mixed, 3-Edit
			}, meta )
		end 
	end 
	
	
	
	util.AddNetworkString( "golem.share.session" ) -- Host/Manage
	
	
	util.AddNetworkString( "golem.share.message" ) -- editor commands
	/*
		Server->Client
			1- Full code
			2- Cursors
			3- OnTextChanged
			4- Request Code
		
		Client->Server
			1- Full code
			2- Cursor
			3- OnTextChanged
	*/
	
	local function WriteSession( tSession )
		net.WriteUInt( 1, 4 )
		net.WriteUInt( tSession.ID, 16 ) 
		net.WriteString( tSession.Name )
		net.WriteUInt( tSession.Access, 2 )
		net.WriteUInt( tSession.Mode, 2 )
		net.WritePlayer( Session.Host )
		net.WriteTable( Session.Users )
	end 
	
	local function SessionSyncAll( )
		local tLookup = { }
		for _, pPlayer in ipairs( player.GetHumans( ) ) do
			tLookup[pPlayer] = { }
		end
		
		for _, tSession in pairs( Sessions ) do
			if tSession.Access == 1 then -- Only send private sessions to connected users
				for pPlayer, tData in pairs( tSession.Users ) do
					table.insert( tLookup[pPlayer], tSession )
				end
			else -- send whilelist and public sessions to all players
				for _, t in pairs( tLookup ) do
					table.insert( t, tSession )
				end
			end 
		end
		
		for pPlayer, tSessions in pairs( tLookup ) do
			net.Start( "golem.share.session" )
				net.WriteUInt( 15, 4 )
				for _, tSession in ipairs( tSessions ) do
					WriteSession( tSession )
				end
			net.Send( pPlayer )
		end
	end 
	
	
	
	net.Receive( "golem.share.session", function( nLength, pPlayer )
		local nState = net.ReadUInt( 4 )
		
		
		if nState == 1 then -- Create Session
			local sName = net.ReadString( )
			local nID = table.maxn( Sessions ) + 1
			
			local Session = { 
				ID = nID,
				Name = sName,
				Host = pPlayer,
				Users = { [pPlayer] = { User = pPlayer, Rank = 3, Accepted = true } },
				Access = 1, -- 1-Private, 2-Whitelist, 3-public
				Mode = 1, -- 1-View, 2-Mixed, 3-Edit
			}
			
			Sessions[nID] = Session
			
			net.Start( "golem.share.session" )
				WriteSession( Session )
			net.Send( pPlayer )
			
			return
		elseif nState == 2 then -- Settings
			local nID = net.ReadUInt( 16 )
			local Session = Sessions[nID]
			if not Session then return end 
			if Session.Host ~= pPlayer then return end 
			
			
			-- 1-Access, 2-Mode, 3-Invite, 4-Kick, 5-User Perms
			nState = net.ReadUInt( 4 )
			
			if nState == 1 then -- Edit Access
				local n = net.ReadUInt( 2 )
				
				if n ~= Session.Access then 
					-- TODO Send update
				end 
				
				Session.Access = n
			elseif nState == 2 then -- Edit Mode
				local n = net.ReadUInt( 2 )
				
				if n ~= Session.Access then 
					-- TODO Send update
				end 
				
				Session.Mode = n
			elseif nState == 3 then -- Invite Player
				local pClient = net.ReadPlayer( )
				if pClient ~= Entity(0) then 
					local nRank = 1
					
					if net.ReadBit( ) then 
						nRank = net.ReadUInt( 2 )
					end 
					
					Session.Users[pClient] = { 
						-- 1-View, 2-Edit, 3-Admin(TODO)
						Rank = nRank,
						User = pClient,
						Accepted = false,
					}
					
					-- TODO Send to player
					net.Start( "golem.share.session" )
						-- Send Session Data
						WriteSession( Session )
						
						-- Send invite notification
						net.WriteUInt( 3, 4 )
						net.WriteUInt( Session.ID, 16 )
						net.WritePlayer( pPlayer ) 
					net.Send( pClient )
				end 
			elseif nState == 4 then -- Kick Player
				local pClient = net.ReadPlayer( )
				Session.Users[pClient] = nil
				
				-- TODO Update Player
			elseif nState == 5 then -- User Permissions
				local pClient = net.ReadPlayer( )
				if pClient ~= Entity(0) and Session.Users[pClient] then 
					Session.Users[pClient].Rank = net.ReadUInt( 2 )
				end 
				
				-- TODO Update Players
			end
			
		elseif nState == 3 then -- Invite update
			local nID = net.ReadUInt( 16 )
			local Session = Sessions[nID]
			if not Session or not Session.Users[pPlayer] then return end 
			
			local bAccept = net.ReadBool( )
			
			Session.Users[pPlayer].Accepted = bAccept
			
			-- TODO Send code to player if accepted
			-- TODO Notify other users?
			
		elseif nState == 4 then -- Join Session (Public/Whitelist)
			local nID = net.ReadUInt( 16 )
			local Session = Sessions[nID]
			if not Session then return end 
			if Session.Access < 2 then return end 
			
			local tUser = Session.Users[pPlayer]
			
			if tUser then 
				tUser.Accepted = true 
			elseif Session.Access == 3 then -- Public
				Session.Users[pPlayer] = { 
					Rank = Session.Mode == 3 and 2 or 1,
					User = pPlayer,
					Accepted = true,
				}
			end 
			
			-- TODO Send code to player
			-- Notify other users?
			
		elseif nState == 5 then -- Leave Session
			local nID = net.ReadUInt( 16 )
			local Session = Sessions[nID]
			if not Session then return end 
			
			Session.Users[pPlayer] = nil
			
			-- Notify other users?
		end 
		
		
	end )
	
	hook.Add( "PlayerDisconect", "Golem.Share.Sessions", function( pPlayer )
		for _, tSession in pairs( Sessions ) do
			if tSession.Host == pPlayer then
				net.Start( "golem.share.session" )
					net.WriteUInt( 15, 4 )
					net.WriteUInt( tSession.ID, 16 )
				net.Broadcast( )
					
				Sessions[tSession.ID] = nil
			end
		end
	end )
	
	return 
end 

-- Clientside

Golem.Sessions = { }

net.Receive( "golem.share.session", function( nLength )
	local nState = net.ReadUInt( 4 )
	
	while nState > 0 do
		
		if nState == 1 then -- New/Updated Session
			local nID = net.ReadUInt( 16 ) 
			local sName = net.ReadString( ) 
			local nAccess = net.ReadUInt( 2 ) 
			local nMode = net.ReadUInt( 2 ) 
			local pHost = net.ReadEntity( ) 
			local tUsers = net.ReadTable( ) 
			
			Golem.Sessions[nID] = Golem.Sessions[nID] or { }
			Golem.Sessions[nID].ID = nID
			Golem.Sessions[nID].Name = sName
			Golem.Sessions[nID].Access = nAccess
			Golem.Sessions[nID].Mode = nMode
			Golem.Sessions[nID].Host = pHost
			Golem.Sessions[nID].Users = tUsers
		elseif nState == 2 then -- Remove Session
			local nID = net.ReadUInt( 16 ) 
			Golem.Sessions[nID] = nil
		elseif nState == 3 then -- Session Invite
			local nID = net.ReadUInt( 16 )
			local Session = Golem.Sessions[nID]
			local pPlayer = net.ReadPlayer( )
			
			-- TODO Alert player
			-- TODO Update editor
		elseif nState == 15 then -- Reset Session list
			Golem.Sessions = { }
		end 
		
		nState = net.ReadUInt( 4 ) 
	end 
		
	-- TODO Refresh Session List
	
	
end )
