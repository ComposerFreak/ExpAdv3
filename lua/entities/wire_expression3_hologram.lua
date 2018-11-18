--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	Based on my EA2 Holograms, They are my EA2 holograms :P
]]

AddCSLuaFile();

ENT.Type = "anim";
ENT.Base = "base_anim";
ENT.IsHologram = true;
ENT.Animated = true;
ENT.AutomaticFrameAdvance  = true;
ENT.RenderGroup = RENDERGROUP_BOTH;

--[[
	Base Data Tables
]]

local function NewInfoTable( )
	return {
		FORCEFIRST = true,
		VISIBLE = true,
		SHADING = true,
		BLOCKED = false,
		SCALEX = 1,
		SCALEY = 1,
		SCALEZ = 1,
		CLIPS = { },
		BONES = { }
	};
end

local function NewClippingTable( )
	return {
		ENABLED = true,
		NORMALX = 0,
		NORMALY = 0,
		NORMALZ = 0,
		ORIGINX = 0,
		ORIGINY = 0,
		ORIGINZ = 0
	};
end

local function NewBoneTable( )
	return {
		JIGGLE = false,
		POSX = 0,
		POSY = 0,
		POSZ = 0,
		SCALEX = 0,
		SCALEY = 0,
		SCALEZ = 0,
		ANGLEP = 0,
		ANGLEY = 0,
		ANGLER = 0
	};
end

--[[
	Hologram Info Linking
]]

local INFOTABLE = { }

local function LinkHoloInfo( this )
	local Key = this:EntIndex( );

	INFOTABLE[ Key ] = INFOTABLE[ Key ] or NewInfoTable( );

	this.INFO = INFOTABLE[ Key ];

	this.CLIPS = this.INFO.CLIPS;
	this.BONES = this.INFO.BONES;

	if CLIENT then return end

	this.SYNC_CLIPS = { };
	this.SYNC_BONES = { };

	this.BLOCKED_IDS = { };
end

if CLIENT then
	hook.Add( "NetworkEntityCreated", "Expression3.Hologram.Reload", function(ent)
		if !IsValid(ent) then return end
		if ent:GetClass() ~= "lemon_holo" then return end

		LinkHoloInfo(ent);
		if ent.ApplyHoloInfo then ent:ApplyHoloInfo() end
	end);
end

--[[
	Values we need to define.
]]

local SyncQueue, ClipQueue, BoneQueue, RemoveQueue, BlockQueue, UnblockQueue;

--[[
	Entity Creation / Destroy
]]

function ENT:Initialize( )
	LinkHoloInfo( self );

	if CLIENT then return self:ApplyHoloInfo( ) end

	self.PlyID = IsValid( self.player ) and self.player:UniqueID( ) or "";

	self:SetSolid( SOLID_NONE );
	self:SetMoveType( MOVETYPE_NONE );
	self:DrawShadow( false );

	SyncQueue[ self ] = true;
end

function ENT:OnRemove( )
	if CLIENT then return end

	INFOTABLE[ self:EntIndex( ) ] = nil;
	RemoveQueue[ self:EntIndex( ) ] = true;

	self:LowerCount();
end

function ENT:LowerCount()

end

--[[
	Set up the syncing system between server and client.
	Hold onto your hats this is complicated.
]]

if SERVER then
	RemoveQueue = { }
	SyncQueue = { }

	util.AddNetworkString( "Expression3.Hologram" )

	function ENT:SyncInfo( Forced )
		if Forced then return self:SyncInfoForced( ) end

			net.WriteBit( self.INFO.VISIBLE )
			net.WriteBit( self.INFO.SHADING )

		net.WriteBit( self.SYNC_SCALEX )
		if self.SYNC_SCALEX then
			self.SYNC_SCALEX = nil
			net.WriteFloat( self.INFO.SCALEX )
		end

		net.WriteBit( self.SYNC_SCALEY )
		if self.SYNC_SCALEY then
			self.SYNC_SCALEY = nil
			net.WriteFloat( self.INFO.SCALEY )
		end

		net.WriteBit( self.SYNC_SCALEZ )
		if self.SYNC_SCALEZ then
			self.SYNC_SCALEZ = nil
			net.WriteFloat( self.INFO.SCALEZ )
		end
	end

	function ENT:SyncInfoForced( )

		net.WriteBit( self.INFO.VISIBLE )
		net.WriteBit( self.INFO.SHADING )

		net.WriteBit( true )
		net.WriteFloat( self.INFO.SCALEX )

		net.WriteBit( true )
		net.WriteFloat( self.INFO.SCALEY )

		net.WriteBit( true )
		net.WriteFloat( self.INFO.SCALEZ )

	end

	ClipQueue = { }

	function ENT:SyncClips( Forced )

		if Forced then return self:SyncClipsForced( ) end

		for ID, _ in pairs( self.SYNC_CLIPS ) do

			net.WriteUInt( ID, 16 )

			local Info = self.CLIPS[ID]

			if Info then
				net.WriteBit( true )

				net.WriteBit( Info.ENABLED )

				net.WriteBit( Info.Global )

				net.WriteBit( Info.SYNC_NORMALX )
				if Info.SYNC_NORMALX then
					Info.SYNC_NORMALX = nil
					net.WriteFloat( Info.NORMALX )
				end

				net.WriteBit( Info.SYNC_NORMALY )
				if Info.SYNC_NORMALY then
					Info.SYNC_NORMALY = nil
					net.WriteFloat( Info.NORMALY )
				end

				net.WriteBit( Info.SYNC_NORMALZ )
				if Info.SYNC_NORMALZ then
					Info.SYNC_NORMALZ = nil
					net.WriteFloat( Info.NORMALZ )
				end

				net.WriteBit( Info.SYNC_ORIGINX )
				if Info.SYNC_ORIGINX then
					Info.SYNC_ORIGINX = nil
					net.WriteFloat( Info.ORIGINX )
				end

				net.WriteBit( Info.SYNC_ORIGINY )
				if Info.SYNC_ORIGINY then
					Info.SYNC_ORIGINY = nil
					net.WriteFloat( Info.ORIGINY )
				end

				net.WriteBit( Info.SYNC_ORIGINZ )
				if Info.SYNC_ORIGINZ then
					Info.SYNC_ORIGINZ = nil
					net.WriteFloat( Info.ORIGINZ )
				end
			else
				net.WriteBit( false )
			end
		end

		self.SYNC_CLIPS = { }

		net.WriteUInt( 0, 16 )
	end

	function ENT:SyncClipsForced( Forced )

		for ID, Info in pairs( self.CLIPS ) do

			net.WriteUInt( ID, 16 )
			net.WriteBit( true )

			net.WriteBit( Info.ENABLED )

			net.WriteBit( Info.Global )

			net.WriteBit( true )
			net.WriteFloat( Info.NORMALX )

			net.WriteBit( true )
			net.WriteFloat( Info.NORMALY )

			net.WriteBit( true )
			net.WriteFloat( Info.NORMALZ )

			net.WriteBit( true )
			net.WriteFloat( Info.ORIGINX )

			net.WriteBit( true )
			net.WriteFloat( Info.ORIGINY )

			net.WriteBit( true )
			net.WriteFloat( Info.ORIGINZ )

		end

		net.WriteUInt( 0, 16 )
	end


	BoneQueue = { }

	function ENT:SyncBones( Forced )

		if Forced then return self:SyncBonesForced( ) end

		for ID, _ in pairs( self.SYNC_BONES ) do

			net.WriteUInt( ID, 16 )

			local Info = self.BONES[ID]

			net.WriteBit( Info.JIGGLE )

			net.WriteBit( Info.SYNC_POSX )
			if Info.SYNC_POSX then
				Info.SYNC_POSX = nil
				net.WriteFloat( Info.POSX )
			end

			net.WriteBit( Info.SYNC_POSY )
			if Info.SYNC_POSY then
				Info.SYNC_POSY = nil
				net.WriteFloat( Info.POSY )
			end

			net.WriteBit( Info.SYNC_POSZ )
			if Info.SYNC_POSZ then
				Info.SYNC_POSZ = nil
				net.WriteFloat( Info.POSZ )
			end

			net.WriteBit( Info.SYNC_SCALEX )
			if Info.SYNC_SCALEX then
				Info.SYNC_SCALEX = nil
				net.WriteFloat( Info.SCALEX )
			end

			net.WriteBit( Info.SYNC_SCALEY )
			if Info.SYNC_SCALEY then
				Info.SYNC_SCALEY = nil
				net.WriteFloat( Info.SCALEY )
			end

			net.WriteBit( Info.SYNC_SCALEZ )
			if Info.SYNC_SCALEZ then
				Info.SYNC_SCALEZ = nil
				net.WriteFloat( Info.SCALEZ )
			end

			net.WriteBit( Info.SYNC_ANGLEP )
			if Info.SYNC_ANGLEP then
				Info.SYNC_ANGLEP = nil
				net.WriteFloat( Info.ANGLEP )
			end

			net.WriteBit( Info.SYNC_ANGLEY )
			if Info.SYNC_ANGLEY then
				Info.SYNC_ANGLEY = nil
				net.WriteFloat( Info.ANGLEY )
			end

			net.WriteBit( Info.SYNC_ANGLER )
			if Info.SYNC_ANGLER then
				Info.SYNC_ANGLER = nil
				net.WriteFloat( Info.ANGLER )
			end

		end

		net.WriteUInt( 0, 16 )

	end

	function ENT:SyncBonesForced( Forced )

		for ID, Info in pairs( self.BONES ) do

			net.WriteBit( Info.JIGGLE )

			net.WriteBit( true )
			net.WriteFloat( Info.POSX )

			net.WriteBit( true )
			net.WriteFloat( Info.POSY )

			net.WriteBit( true )
			net.WriteFloat( Info.POSZ )

			net.WriteBit( true )
			net.WriteFloat( Info.SCALEX )

			net.WriteBit( true )
			net.WriteFloat( Info.SCALEY )

			net.WriteBit( true )
			net.WriteFloat( Info.SCALEZ )

			net.WriteBit( true )
			net.WriteFloat( Info.ANGLEP )

			net.WriteBit( true )
			net.WriteFloat( Info.ANGLEY )

			net.WriteBit( true )
			net.WriteFloat( Info.ANGLER )

		end

		net.WriteUInt( 0, 16 )

	end

	function ENT:SyncClient( Force )

		net.WriteUInt( self:EntIndex( ), 16 )

		if self.INFO.FORCEFIRST then
			Force = true
			self.INFO.FORCEFIRST = false
		end

		net.WriteBit( Force or false )
		if Force then
			net.WriteString( self.PlyID )
		end

		if SyncQueue[ self ] or Force then
			net.WriteBit( true )
			self:SyncInfo( Forced )
		else
			net.WriteBit( false )
		end

		if ClipQueue[ self ] or Force then
			net.WriteBit( true )
			self:SyncClips( Forced )
		else
			net.WriteBit( false )
		end

		if BoneQueue[ self ] or Force then
			net.WriteBit( true )
			self:SyncBones( Forced )
		else
			net.WriteBit( false )
		end

		if !Force then
			SyncQueue[ self ] = nil
			ClipQueue[ self ] = nil
			BoneQueue[ self ] = nil
		end
	end

	BlockQueue, UnblockQueue = { }, { }

	util.AddNetworkString( "Expression3.Hologram.Block" )

	local function SyncBlockedHolograms( Player )
		local PlyID = Player:UniqueID( )

		local Block = BlockQueue[ PlyID ]
		local UnBlock = UnblockQueue[ PlyID ]

		if !Block and !UnBlock then return end

		net.Start( "Expression3.Hologram.Block" )

			if Block then
				for ENT, _ in pairs( Block ) do
					if IsValid( ENT ) then
						net.WriteUInt( ENT:EntIndex( ), 16 )
					end
				end
			end

			net.WriteUInt( 0, 16 )

			if UnBlock then
				for ENT, _ in pairs( UnBlock ) do
					if IsValid( ENT ) then
						net.WriteUInt( ENT:EntIndex( ), 16 )
					end
				end
			end

			net.WriteUInt( 0, 16 )

		net.Send( Player )

		BlockQueue[ PlyID ] = nil
		UnblockQueue[ PlyID ] = nil
	end

	hook.Add( "PlayerInitialSpawn", "Expression3.Hologram", function( Player )
		net.Start( "Expression3.Hologram" )

			net.WriteUInt( 0, 16 )

			for _, ENT in pairs( ents.FindByClass( "lemon_hologram" ) ) do
				ENT:SyncClient( true )
			end

			net.WriteUInt( 0, 16 )

		net.Send( Player )

		SyncBlockedHolograms( Player )
	end )

	hook.Add( "Tick", "Expression3.Hologram", function( )
		local Queue = { }
		local NeedsUpdate = false

		for ENT, _ in pairs( SyncQueue ) do Queue[ENT] = true; NeedsUpdate = true end
		for ENT, _ in pairs( ClipQueue ) do Queue[ENT] = true; NeedsUpdate = true end
		for ENT, _ in pairs( BoneQueue ) do Queue[ENT] = true; NeedsUpdate = true end

		if NeedsUpdate then
			net.Start( "Expression3.Hologram" )

			for ID, _ in pairs( RemoveQueue ) do
				net.WriteUInt( ID, 16 )
			end

			net.WriteUInt( 0, 16 )

			RemoveQueue = { }

			for ENT, _ in pairs( Queue ) do
				if IsValid( ENT ) and ENT.SyncClient then
					ENT:SyncClient( false )
				end
			end

			net.WriteUInt( 0, 16 )

			net.Broadcast( )
		end

		for _, Player in pairs( player.GetAll( ) ) do
			SyncBlockedHolograms( Player )
		end
	end )

elseif CLIENT then -- End of <if SERVER>

	local function UpdateInfo( Key )

		local Info = INFOTABLE[ Key ]

		Info.VISIBLE = net.ReadBit( ) == 1
		Info.SHADING = net.ReadBit( ) == 1

		if net.ReadBit( ) == 1 then Info.SCALEX = net.ReadFloat( ) end
		if net.ReadBit( ) == 1 then Info.SCALEY = net.ReadFloat( ) end
		if net.ReadBit( ) == 1 then Info.SCALEZ = net.ReadFloat( ) end
	end

	local function UpdateClips( Key )

		local Clips = INFOTABLE[ Key ].CLIPS

		local ID = net.ReadUInt( 16 )

		while ID ~= 0 do

			Clips[ID] = Clips[ID] or NewClippingTable( )

			local Info = Clips[ID]

			if net.ReadBit( ) == 1 then
				Info.ENABLED = net.ReadBit( ) == 1

				Info.Global = net.ReadBit( ) == 1

				if net.ReadBit( ) == 1 then Info.NORMALX = net.ReadFloat( ) end
				if net.ReadBit( ) == 1 then Info.NORMALY = net.ReadFloat( ) end
				if net.ReadBit( ) == 1 then Info.NORMALZ = net.ReadFloat( ) end

				if net.ReadBit( ) == 1 then Info.ORIGINX = net.ReadFloat( ) end
				if net.ReadBit( ) == 1 then Info.ORIGINY = net.ReadFloat( ) end
				if net.ReadBit( ) == 1 then Info.ORIGINZ = net.ReadFloat( ) end
			else
				Clips[ID] = nil
			end

			ID = net.ReadUInt( 16 )
		end
	end

	local function UpdateBones( Key )
		local Bones = INFOTABLE[ Key ].BONES

		local ID = net.ReadUInt( 16 )

		while ID ~= 0 do

			Bones[ID] = Bones[ID] or NewBoneTable( )

			local Info = Bones[ID]

			Info.JIGGLE = net.ReadBit( ) == 1

			if net.ReadBit( ) == 1 then Info.POSY = net.ReadFloat( ) end
			if net.ReadBit( ) == 1 then Info.POSX = net.ReadFloat( ) end
			if net.ReadBit( ) == 1 then Info.POSZ = net.ReadFloat( ) end

			if net.ReadBit( ) == 1 then Info.SCALEY = net.ReadFloat( ) end
			if net.ReadBit( ) == 1 then Info.SCALEX = net.ReadFloat( ) end
			if net.ReadBit( ) == 1 then Info.SCALEZ = net.ReadFloat( ) end

			if net.ReadBit( ) == 1 then Info.ANGLEP = net.ReadFloat( ) end
			if net.ReadBit( ) == 1 then Info.ANGLEY = net.ReadFloat( ) end
			if net.ReadBit( ) == 1 then Info.ANGLER = net.ReadFloat( ) end

			ID = net.ReadUInt( 16 )
		end
	end

	net.Receive( "Expression3.Hologram", function( Len )

		local RemoveID = net.ReadUInt( 16 )

		while RemoveID ~= 0 do
			INFOTABLE[ RemoveID ] = nil
			RemoveID = net.ReadUInt( 16 )
		end

		local Key = net.ReadUInt( 16 )

		while Key ~= 0 do

			local Info = INFOTABLE[ Key ] or NewInfoTable( )
			INFOTABLE[ Key ] = Info

			if net.ReadBit( ) == 1 then
				Info.PlyID = net.ReadString( )
			end

			if net.ReadBit( ) == 1 then  UpdateInfo( Key ) end
			if net.ReadBit( ) == 1 then  UpdateClips( Key ) end
			if net.ReadBit( ) == 1 then  UpdateBones( Key ) end

			local ENT = Entity( Key )
			if IsValid( ENT ) and ENT.ApplyHoloInfo then ENT:ApplyHoloInfo( ) end

			Key = net.ReadUInt( 16 )

		end

	end )

	net.Receive( "Expression3.Hologram.Block", function( Len )
		local BlockID = net.ReadUInt( 16 )

		while BlockID ~= 0 do
			local Info = INFOTABLE[ BlockID ]
			if Info then Info.BLOCKED = true end

			BlockID = net.ReadUInt( 16 )
		end

		local UnblockID = net.ReadUInt( 16 )

		while UnblockID ~= 0 do
			local Info = INFOTABLE[ UnblockID ]
			if Info then Info.BLOCKED = false end

			UnblockID = net.ReadUInt( 16 )
		end
	end )
end

--[[
	Here is our Setters / Getters
]]

if SERVER then
	ENT.ID = -1

	-- Rendering:

	function ENT:SetVisible( bVis )
		if self.INFO.VISIBLE == bVis then return end
		self.INFO.VISIBLE = bVis
		SyncQueue[ self ] = true
	end

	function ENT:SetShading( bShade )
		if self.INFO.SHADING == bShade then return end
		self.INFO.SHADING = bShade
		SyncQueue[ self ] = true
	end

	-- Scale:

	function ENT:SetScale( Scale )
		local ScaleLimit = 50;

		local X = math.Clamp( Scale.x, -ScaleLimit, ScaleLimit )
		local Y = math.Clamp( Scale.y, -ScaleLimit, ScaleLimit )
		local Z = math.Clamp( Scale.z, -ScaleLimit, ScaleLimit )

		if self.INFO.SCALEX ~= X then
			self.INFO.SCALEX = X
			self.SYNC_SCALEX = true
			SyncQueue[ self ] = true
		end

		if self.INFO.SCALEY ~= Y then
			self.INFO.SCALEY = Y
			self.SYNC_SCALEY = true
			SyncQueue[ self ] = true
		end

		if self.INFO.SCALEZ ~= Z then
			self.INFO.SCALEZ = Z
			self.SYNC_SCALEZ = true
			SyncQueue[ self ] = true
		end
	end

	function ENT:SetScaleUnits( Vec )
		local  OBBSize = self:OBBMaxs( ) - self:OBBMins( )
		self:SetScale( Vector( Vec.x / OBBSize.x, Vec.y / OBBSize.y, Vec.z / OBBSize.z ) )
	end

	function ENT:GetScaleUnits( )
		local  OBBSize = self:OBBMaxs( ) - self:OBBMins( )

		local X = self.INFO.SCALEX * OBBSize.x
		local Y = self.INFO.SCALEY * OBBSize.y
		local Z = self.INFO.SCALEZ * OBBSize.z

		return Vector( X, Y, Z )
	end

	function ENT:GetScale( )
		return Vector( self.INFO.SCALEX or 0, self.INFO.SCALEY or 0, self.INFO.SCALEZ or 0 )
	end

	-- Clipping:

	function ENT:PushClip( ID, Origin, Normal, Global )
		self:SetClipOrigin( ID, Origin )
		self:SetClipNormal( ID, Normal )
		if Global then self:SetClipGlobal( ID, Global ) end
	end

	function ENT:SetClipEnabled( ID, bEnable )
		if ID < 1 or ID > 5 then return end

		self.CLIPS[ ID ] = self.CLIPS[ ID ] or NewClippingTable( )

		self.CLIPS[ ID ].ENABLED = bEnable

		self.SYNC_CLIPS[ ID ] = true

		ClipQueue[ self ] = true
	end

	function ENT:SetClipOrigin( ID, Vector )
		if ID < 1 or ID > 5 then return end

		self.CLIPS[ ID ] = self.CLIPS[ ID ] or NewClippingTable( )

		local Clip = self.CLIPS[ ID ]

		if Clip.ORIGINX ~= Vector.x then
			Clip.ORIGINX = Vector.x
			Clip.SYNC_ORIGINX = true
			self.SYNC_CLIPS[ ID ] = true
			ClipQueue[ self ] = true
		end

		if Clip.ORIGINY ~= Vector.y then
			Clip.ORIGINY = Vector.y
			Clip.SYNC_ORIGINY = true
			self.SYNC_CLIPS[ ID ] = true
			ClipQueue[ self ] = true
		end

		if Clip.ORIGINZ ~= Vector.z then
			Clip.ORIGINZ = Vector.z
			Clip.SYNC_ORIGINZ = true
			self.SYNC_CLIPS[ ID ] = true
			ClipQueue[ self ] = true
		end
	end

	function ENT:SetClipGlobal( ID, Bool )
		if !self.CLIPS[ ID ] then return end

		self.SYNC_CLIPS[ ID ] = self.CLIPS[ ID ].Global ~= Bool

		self.CLIPS[ ID ].Global = Bool

		if self.SYNC_CLIPS[ ID ] == true then
			ClipQueue[ self ] = true
		end
	end

	function ENT:SetClipNormal( ID, Vector )
		if ID < 1 or ID > 5 then return end

		self.CLIPS[ ID ] = self.CLIPS[ ID ] or NewClippingTable( )

		local Clip = self.CLIPS[ ID ]

		if Clip.NORMALX ~= Vector.x then
			Clip.NORMALX = Vector.x
			Clip.SYNC_NORMALX = true
			self.SYNC_CLIPS[ ID ] = true
			ClipQueue[ self ] = true
		end

		if Clip.NORMALY ~= Vector.y then
			Clip.NORMALY = Vector.y
			Clip.SYNC_NORMALY = true
			self.SYNC_CLIPS[ ID ] = true
			ClipQueue[ self ] = true
		end

		if Clip.NORMALZ ~= Vector.z then
			Clip.NORMALZ = Vector.z
			Clip.SYNC_NORMALZ = true
			self.SYNC_CLIPS[ ID ] = true
			ClipQueue[ self ] = true
		end
	end

	function ENT:RemoveClip( ID )
		if !self.CLIPS[ ID ] then return end

		self.CLIPS[ ID ] = nil

		self.SYNC_CLIPS[ ID ] = true

		ClipQueue[ self ] = true
	end

	-- Bones:

	function ENT:SetBoneJiggle( ID, bJiggle )
		if ID < 1 or ID > self:GetBoneCount( ) then return end

		self:ManipulateBoneJiggle( ID - 1, bJiggle and 1 or 0 )

		self.BONES[ ID ] = self.BONES[ ID ] or NewBoneTable( )

		self.BONES[ ID ].JIGGLE = bJiggle

	end

	function ENT:GetBoneJiggle( ID )
		if ID < 1 or ID > self:GetBoneCount( ) then return false end

		return self:GetManipulateBoneJiggle( ID - 1 )
	end

	function ENT:SetBonePos( ID, Vector )
		if ID < 1 or ID > self:GetBoneCount( ) then return end

		self:ManipulateBonePosition( ID - 1, Vector )

		self.BONES[ ID ] = self.BONES[ ID ] or NewBoneTable( )

		local Clip = self.BONES[ ID ]

		if Clip.POSX ~= Vector.x then
			Clip.POSX = Vector.x
			Clip.SYNC_POSX = true
			self.SYNC_BONES[ ID ] = true
		end

		if Clip.POSY ~= Vector.y then
			Clip.POSY = Vector.y
			Clip.SYNC_POSY = true
			self.SYNC_BONES[ ID ] = true
		end

		if Clip.POSZ ~= Vector.z then
			Clip.POSZ = Vector.z
			Clip.SYNC_POSZ = true
			self.SYNC_BONES[ ID ] = true
		end
	end

	function ENT:GetBonePos( ID )
		if ID < 1 or ID > self:GetBoneCount( ) then return Vector( 0, 0, 0 ) end

		return self:GetManipulateBonePosition( ID - 1 )
	end

	function ENT:SetBoneScale( ID, Vector )
		if ID < 1 or ID > self:GetBoneCount( ) then return end

		self:ManipulateBoneScale( ID - 1, Vector )

		self.BONES[ ID ] = self.BONES[ ID ] or NewBoneTable( )

		local Clip = self.BONES[ ID ]

		if Clip.SCALEX ~= Vector.x then
			Clip.SCALEX = Vector.x
			Clip.SYNC_SCALEX = true
			self.SYNC_BONES[ ID ] = true
		end

		if Clip.SCALEY ~= Vector.y then
			Clip.SCALEY = Vector.y
			Clip.SYNC_SCALEY = true
			self.SYNC_BONES[ ID ] = true
		end

		if Clip.SCALEZ ~= Vector.z then
			Clip.SCALEZ = Vector.z
			Clip.SYNC_SCALEZ = true
			self.SYNC_BONES[ ID ] = true
		end
	end

	function ENT:GetBoneScale( ID )
		if ID < 1 or ID > self:GetBoneCount( ) then return Vector( 0, 0, 0 ) end

		return self:GetManipulateBoneScale( ID - 1 )
	end

	function ENT:SetBoneAngle( ID, Angle )
		if ID < 1 or ID > self:GetBoneCount( ) then return end

		self:ManipulateBoneAngles( ID - 1, Angle )

		self.BONES[ ID ] = self.BONES[ ID ] or NewBoneTable( )

		local Clip = self.BONES[ ID ]

		if Clip.ANGLEP ~= Angle.p then
			Clip.ANGLEP = Angle.p
			Clip.SYNC_ANGLEP = true
			self.SYNC_BONES[ ID ] = true
		end

		if Clip.ANGLEY ~= Angle.y then
			Clip.ANGLEY = Angle.y
			Clip.SYNC_ANGLEY = true
			self.SYNC_BONES[ ID ] = true
		end

		if Clip.ANGLER ~= Angle.r then
			Clip.ANGLER = Angle.r
			Clip.SYNC_ANGLER = true
			self.SYNC_BONES[ ID ] = true
		end
	end

	function ENT:GetBoneAngle( ID )
		if ID < 1 or ID > self:GetBoneCount( ) then return Angle( 0, 0, 0 ) end

		return self:GetManipulateBoneAngles( ID - 1 )
	end

	-- Animation:

	function ENT:SetHoloAnimation( Animation, Frame, Rate )
		self:ResetSequence( Animation )
		self:SetCycle( Frame or 0 )
		self:SetPlaybackRate( Rate or 1 )
	end

	-- Automation for spoofing animations:

	function ENT:MoveTo( Vector, Speed )
		self.MOVETO = Vector
		self.MOVEDIR = nil
		self.MOVESPEED = Speed
	end

	function ENT:StartMove( Dir )
		self.MOVETO = nil
		self.MOVESPEED = nil
		self.MOVEDIR = Dir
	end

	function ENT:StopMove( )
		self.MOVETO = nil
		self.MOVEDIR = nil
		self.MOVESPEED = nil
	end

	function ENT:RotateTo( Angle, Speed )
		self.ROTATETO = Angle
		self.ROTATEAXIS = nil
		self.ROTATESPEED = Speed
	end

	function ENT:StartRotate( Angle )
		self.ROTATETO = nil
		self.ROTATESPEED = nil
		self.ROTATEAXIS = Angle
	end

	function ENT:StopRotate( )
		self.ROTATETO = nil
		self.ROTATEAXIS = nil
		self.ROTATESPEED = nil
	end

	function ENT:ScaleTo( Scale, Speed )
		local ScaleLimit = 50;
		local NewScale = Vector( math.Clamp( Scale.x, -ScaleLimit, ScaleLimit ), math.Clamp( Scale.y, -ScaleLimit, ScaleLimit ), math.Clamp( Scale.z, -ScaleLimit, ScaleLimit ) )

		self.SCALETO = NewScale
		self.SCALESPEED = Speed * 0.01
	end

	function ENT:ScaleToUnits( Scale, Speed )
		local OBBSize = self:OBBMaxs( ) - self:OBBMins( )
		self:ScaleTo( Vector( Scale.x / OBBSize.x, Scale.y / OBBSize.y, Scale.z / OBBSize.z ), Speed )
	end

	function ENT:StopScale( )
		self.SCALETO = nil
		self.SCALESPEED = nil
	end

	function ENT:Think( )
		local TickRate =  engine.TickInterval()

		if self.MOVEDIR then
			self:SetPos(self:LocalToWorld(self.MOVEDIR * TickRate))
		elseif self.MOVESPEED and self.MOVETO then
			local Pos = self:GetPos( )

			Pos.x = Pos.x + math.Clamp( self.MOVETO.x - Pos.x, -self.MOVESPEED * TickRate, self.MOVESPEED * TickRate )
			Pos.y = Pos.y + math.Clamp( self.MOVETO.y - Pos.y, -self.MOVESPEED * TickRate, self.MOVESPEED * TickRate )
			Pos.z = Pos.z + math.Clamp( self.MOVETO.z - Pos.z, -self.MOVESPEED * TickRate, self.MOVESPEED * TickRate )

			self:SetPos( Pos )

			if Pos == self.MOVETO then
				self:StopMove( )
				if self.PostFinishMove then self:PostFinishMove() end
			end
		end

		if self.ROTATEAXIS then
			self:SetAngles(self:LocalToWorldAngles(self.ROTATEAXIS * TickRate))
		elseif self.ROTATESPEED and self.ROTATETO then
			local Ang = self:GetAngles( )

			Ang.p = Ang.p + math.Clamp( self.ROTATETO.p - Ang.p, -self.ROTATESPEED * TickRate, self.ROTATESPEED * TickRate )
			Ang.y = Ang.y + math.Clamp( self.ROTATETO.y - Ang.y, -self.ROTATESPEED * TickRate, self.ROTATESPEED * TickRate )
			Ang.r = Ang.r + math.Clamp( self.ROTATETO.r - Ang.r, -self.ROTATESPEED * TickRate, self.ROTATESPEED * TickRate )

			self:SetAngles( Ang )

			if Ang == self.ROTATETO then
				self:StopRotate( )
				if self.PostFinishRotate then self:PostFinishRotate() end
			end
		end

		if self.SCALETO and self.SCALESPEED then
			local Scale = self:GetScale( )

			Scale.x = Scale.x + math.Clamp( self.SCALETO.x - Scale.x, -self.SCALESPEED * TickRate, self.SCALESPEED * TickRate )
			Scale.y = Scale.y + math.Clamp( self.SCALETO.y - Scale.y, -self.SCALESPEED * TickRate, self.SCALESPEED * TickRate )
			Scale.z = Scale.z + math.Clamp( self.SCALETO.z - Scale.z, -self.SCALESPEED * TickRate, self.SCALESPEED * TickRate )

			self:SetScale( Scale )

			if Pos == self.SCALETO then
				self:StopScale( )
				if self.PostFinishScalethen then self:PostFinishScale() end
			end
		end
	end

	-- Block a player from seeing a hologram:

	function ENT:BlockPlayer( Player )
		local PlyID = Player:UniqueID( )

		if self.BLOCKED_IDS[ PlyID ] then return end

		self.BLOCKED_IDS[ PlyID ] = true

		BlockQueue[ PlyID ] = BlockQueue[ PlyID ] or { }

		BlockQueue[ PlyID ][self] = true
	end

	function ENT:UnblockPlayer( Player )
		local PlyID = Player:UniqueID( )

		if !self.BLOCKED_IDS[ PlyID ] then return end

		self.BLOCKED_IDS[ PlyID ] = nil

		UnblockQueue[ PlyID ] = UnblockQueue[ PlyID ] or { }

		UnblockQueue[ PlyID ][self] = true
	end

	function ENT:IsBlocked( Player )
		return self.BLOCKED_IDS[ Player:UniqueID( ) ] or false
	end

	return
end

--[[
	CLIENT SIDE CODE:
]]

local LabeledPlayers, BlockedPlayers = { }, { }

function ENT:Draw( )

	local Info = INFOTABLE[ self:EntIndex( ) ]

	-- Don't render what doesn't exist.
	if !Info or !Info.VISIBLE or Info.BLOCKED then return end

	local PlyID = Info.PlyID

	if BlockedPlayers[PlyID] then return end

	if self:GetColor( ).a ~= 255 then
		self.RenderGroup = RENDERGROUP_BOTH
	else
		self.RenderGroup = RENDERGROUP_OPAQUE
	end

	local Pushed, State

	if Info.CLIPS then

		Pushed = 0
		State = render.EnableClipping( true )

		for _, Clip in pairs( Info.CLIPS ) do

			if !Clip.ENABLED then continue end

			local Normal = Vector( Clip.NORMALX, Clip.NORMALY, Clip.NORMALZ )

			local Origin = Vector( Clip.ORIGINX, Clip.ORIGINY, Clip.ORIGINZ )

			if !Clip.Global then
				Normal = self:LocalToWorld( Normal ) - self:GetPos( )

				Origin = self:LocalToWorld( Origin )
			end

			render.PushCustomClipPlane( Normal, Normal:Dot( Origin ) )

			Pushed = Pushed + 1

		end

	end

	render.SuppressEngineLighting( !Info.SHADING )

	self:DrawModel( )

	render.SuppressEngineLighting( false )

	if Info.CLIPS then

		for I = 1, Pushed do
			render.PopCustomClipPlane( )
		end

		render.EnableClipping( State )
	end

end

hook.Add("HUDPaint", "Expression3.Hologram", function( )

	for ID, Info in pairs( INFOTABLE ) do
		local ENT = Entity( ID )

		if IsValid( ENT ) then
			local PlyID = Info.PlyID
			local Owner = player.GetByUniqueID( PlyID )

			if LabeledPlayers[PlyID] and !BlockedPlayers[PlyID] then

				local ScreenData = ENT:GetPos( ):ToScreen( )

				if !ScreenData.visible then return end

				local Name = IsValid( Owner ) and Owner:Name( ) or ( "Player: " .. PlyID )

				draw.SimpleTextOutlined( Name , "defaultsmall", ScreenData.x, ScreenData.y, Color( 0, 0, 0, 255 ), 1, 1, 2, Color( 255, 255, 255, 255 ) )
			end
		end
	end
end )

/*==============================================================================================
    Scale Info
==============================================================================================*/

function ENT:ApplyHoloInfo( )
	local Info = INFOTABLE[ self:EntIndex( ) ]

	if !Info then return end

	local BoneCount = self:GetBoneCount( ) or -1
	local Scale = Vector( Info.SCALEX, Info.SCALEY, Info.SCALEZ )

	if BoneCount > 1 then

		for I = BoneCount, 0 do
			local BoneScale = Scale

			if self.BONES then

				local BoneData = self.BONES[I - 1]

				if BoneData and BoneData.SCALEX then
					BoneScale = Vector( Bone.SCALEY, Bone.SCALEX, Bone.SCALEZ )
				end
			end

			self:ManipulateBoneScale( I, BoneScale )
		end

	elseif self.EnableMatrix then

		local ScaleMatrix = Matrix( )

		ScaleMatrix:Scale( Scale )

		self:EnableMatrix( "RenderMultiply", ScaleMatrix )

	else
		self:SetModelScale( ( Info.SCALEX + Info.SCALEY + Info.SCALEZ ) / 3, 0)
	end

	self:SetRenderBounds( Scale * self:OBBMaxs( ), Scale * self:OBBMins( ) )

	if self.BONES then

		for I, BoneData in pairs( self.BONES ) do

			self:ManipulateBoneJiggle( I - 1, BoneData.JIGGLE and 1 or 0 )

			self:ManipulateBonePosition( I - 1, Vector( BoneData.POSX, BoneData.POSY, BoneData.POSZ ) )

			self:ManipulateBoneAngles( I - 1, Angle( BoneData.ANGLEP, BoneData.ANGLEY, BoneData.ANGLEY ) )
		end
	end
end
