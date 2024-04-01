
if SERVER then 
	
	local Sessions = { }
	
	Golem.Share = { Sessions = Sessions }
	
	util.AddNetworkString( "golem.share.session" ) -- Host/Manage
	util.AddNetworkString( "golem.share.message" ) -- editor commands
	
	
	
	
	
	net.Receive( "golem.share.session", function( nLength, pPlayer )
		local nState = net.ReadUInt( 4 )
		
		-- 1-Create Session, 2-Edit Session
		if nState == 1 then -- Create Session
			local sName = net.ReadString()
			local nID = table.maxn( Sessions ) + 1
			
			local Session = { 
				ID = nID,
				Name = sName,
				Host = pPlayer,
				Users = { [pPlayer] = { User = pPlayer, Rank = 3, Accepted = true } },
				Settings = {
					Access = 1, -- 1-Private, 2-Whitelist, 3-public
					Mode = 1, -- 1-View, 2-Mixed, 3-Edit
				}
			}
			
			Sessions[nID] = Session
			
			net.Start( "golem.share.session" )
				net.WriteUInt( 1, 4 )
				net.WriteUInt( nID, 16 ) 
				net.WriteString( sName )
				net.WriteUInt( 1, 2 )
				net.WriteUInt( 1, 2 )
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
					
					if net.ReadBit() then 
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
						net.WriteUInt( 1, 4 )
						net.WriteUInt( Session.ID, 16 ) 
						net.WriteString( Session.Name )
						net.WriteUInt( Session.Access, 2 )
						net.WriteUInt( Session.Mode, 2 )
						
						-- Send invite notification
						net.WriteUInt( 2, 4 )
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
			
		end 
		
		
	end )
	
	
	return 
end 


Golem.Sessions = { }

net.Receive( "golem.share.session", function( nLength )
	local nState = net.ReadUInt( 4 )
	
	while nState > 0 do
		
		if nState == 1 then -- New/Updated Session
			local nID = net.ReadUInt( 16 )
			local sName = net.ReadString( )
			local nAccess = net.ReadUInt( 2 )
			local nMode = net.ReadUInt( 2 )
			
			Golem.Sessions[nID] = Golem.Sessions[nID] or { }
			Golem.Sessions[nID].ID = nID
			Golem.Sessions[nID].Name = sName
			Golem.Sessions[nID].Access = nAccess
			Golem.Sessions[nID].Mode = nMode
		elseif nState == 2 then -- Session Invite
			local nID = net.ReadUInt( 16 )
			local Session = Golem.Sessions[nID]
			local pPlayer = net.ReadPlayer( )
			
			-- TODO Alert player
			-- TODO Update editor
		end 
		
		nState = net.ReadUInt( 4 ) 
	end 
		
	-- TODO Refresh Session List
	
	
end )
