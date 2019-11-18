/****************************************************************************************************************************
	E3 Permissions System
****************************************************************************************************************************/

EXPR_PERMS = {};

EXPR_DENY = 0;
EXPR_FRIEND = 1;
EXPR_GLOBAL = 1; --Yes this is deliberate.
EXPR_ALLOW = 2;

function EXPR_PERMS.getAll()
	return EXPR_LIB.PERMS;
end

/****************************************************************************************************************************
	Get Owner
****************************************************************************************************************************/

local Owner = function(entity)
	local owner;

	if not IsValid(entity) then
		return;
	end

	if entity.CPPIGetOwner then
		owner = entity:CPPIGetOwner();
	end

	if not IsValid(owner) and entity.GetPlayer then
		owner = entity:GetPlayer();
	end

	if not IsValid(owner) and IsValid(entity.player) then
		owner = entity.player;
	end

	return owner;
end

EXPR_PERMS.Owner = Owner;

/****************************************************************************************************************************
	Set Global Setting
****************************************************************************************************************************/
local ply_perms = {};

EXPR_PERMS.__PlayerPerms =  ply_perms;

local SetGlobal = function(player, perm, value)
	local id = player:UserID();

	local perms = ply_perms[id];

	if not perms then
		perms = { };
		ply_perms[id] = perms;
	end

	perms[perm] = value;
end

EXPR_PERMS.SetGlobal = SetGlobal;

/****************************************************************************************************************************
	Get Global Setting
****************************************************************************************************************************/

local GetGlobal = function(player, perm)
	local id = player:UserID();

	local perms = ply_perms[id];

	if not perms then return EXPR_DENY end

	return perms[perm] or EXPR_DENY;
end

EXPR_PERMS.GetGlobal = GetGlobal;

/****************************************************************************************************************************
	Set Perm Setting
****************************************************************************************************************************/

local Set = function(entity, target, perm, value)
	
	if not IsValid(entity) then return false; end
	if not IsValid(target) then return false; end

	local tid = target:UserID();
	local perms = entity.permissions[tid];

	if not perms then
		perms = { };
		entity.permissions[tid] = perms;
	end

	perms[perm] = value;

	return true;
end

EXPR_PERMS.Set = Set;

/****************************************************************************************************************************
	Get Perm Setting
****************************************************************************************************************************/

local Get = function(entity, target, perm, notGlobal)
	
	if IsValid(entity) and IsValid(target) then

		local owner = Owner(entity);
	
		if owner == target and not notGlobal then
			return EXPR_ALLOW;
		end

		local tid = target:UserID();
		local perms = entity.permissions[tid];

		if perms then
			local val = perms[perm];

			if not notGlobal and not val then return EXPR_DENY; end

			if val and value != EXPR_GLOBAL then return val; end
		end

		if owner and not notGlobal then
			return GetGlobal(owner, perm);
		end
	end

	return EXPR_GLOBAL;
end

EXPR_PERMS.Get = Get;

/****************************************************************************************************************************
	Friend Check
	Stolen from e2lib
****************************************************************************************************************************/
local FriendCheck = function(player, target)

	if not IsValid(player) then return false; end
	if not playerCPPIGetFriends then return false; end

	if not IsValid(target) then return false; end

	local friends = player:CPPIGetFriends();
	
	if not istable(friends) then return false; end

	for _, friend in pairs(friends) do
		if target == friend then return true; end
	end

	return false;
end

EXPR_PERMS.FriendCheck = FriendCheck;

/****************************************************************************************************************************
	Permission check
****************************************************************************************************************************/

local PPCheck = function(entity, object, perm)
	local owner = Owner(object);

	if not IsValid(owner) then return false; end

	local r = Get(entity, owner, perm or "Prop-Control");

	if r == EXPR_DENY then return false; end
	if r == EXPR_ALLOW then return true; end

	return FriendCheck(Owner(enity), owner);
end

EXPR_PERMS.PPCheck = PPCheck;

/****************************************************************************************************************************
	Inject methods ont entities and contex.
****************************************************************************************************************************/

hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Permissions", function(entity, context, env)
	entity.permissions = entity.permissions or {};
	entity.getPerm = Get;
	entity.setPerm = Set;
	entity.getOwner = Owner;
	entity.ppCheck = PPCheck;

	context.permissions = entity.permissions;
	context.getPerm = function(context, target, perm, nglb) return Get(context.entity, target, perm, nglb); end;
	context.setPerm = function(context, target, perm, value) return Set(context.entity, target, perm, value); end;
	context.getOwner = function(context, target) return Owner(context.entity, target); end;
	context.ppCheck = function(context, target, perm) return PPCheck(context.entity, target, perm); end;
end);

/****************************************************************************************************************************
	Server side sync
****************************************************************************************************************************/

if SERVER then
	util.AddNetworkString( "e3_permission" )
	util.AddNetworkString( "e3_global_permission" )

	EXPR_PERMS.SetPermission = function(entity, target, perm, value)
		Set(entity, target, perm, value);

		net.Start( "e3_permission" );
			net.WriteEntity(entity);
			net.WriteEntity(target);
			net.WriteString(perm);
			net.WriteUInt(value, 3);
		net.Broadcast();
	end;

	EXPR_PERMS.SetGlobalPermission = function(player, perm, value)
		SetGlobal(player, perm, value);

		net.Start( "e3_global_permission" );
			net.WriteEntity(player);
			net.WriteString(perm);
			net.WriteUInt(value, 3);
		net.Broadcast();
	end;

	local cmd = function(target, cmd, args, line)
		if not args[3] then return; end
		if not IsValid(target) then return; end

		local entity = Entity(args[1]);
		if not IsValid(entity) then return; end

		Set(entity, target, args[2], tonumber(args[3]));
	end;

	concommand.Add("e3_permission", cmd);

	local cmd2 = function(player, cmd, args, line)
		if not args[3] then return; end
		if not IsValid(player) then return; end

		Set(entity, player, args[2], tonumber(args[3]));
	end;

	concommand.Add("e3_global_permission", cmd2);

end

/****************************************************************************************************************************
	Client side sync
****************************************************************************************************************************/

if CLIENT then

	EXPR_PERMS.SetPermission = function(entity, perm, value)
		if not IsValid(entity) then return; end
		Set(entity, LocalPlayer(), perm, value);
		RunConsoleCommand("e3_permission", entity:EntIndex(), perm, value);
	end;

	EXPR_PERMS.SetGlobalPermission = function(perm, value)
		SetGlobal(LocalPlayer(), perm, value);
		RunConsoleCommand("e3_global_permission", perm, value);
	end;

	net.Receive( "e3_permission", function(len)
		local entity = net.ReadEntity();
		local target = net.ReadEntity();
		local perm = net.ReadString();
		local value = net.ReadUInt(3);

		if not IsValid(entity) then return; end
		if not IsValid(target) then return; end

		Set(entity, target, perm, value);
	end);

	net.Receive( "e3_global_permission", function(len)
		local player = net.ReadEntity();
		local perm = net.ReadString();
		local value = net.ReadUInt(3);

		if not IsValid(player) then return; end

		SetGlobal(player, perm, value);
	end);

end

/****************************************************************************************************************************
	HTTP Filters
****************************************************************************************************************************/
if SERVER then return end;

EXPR_BLACK_LIST = 3;
EXPR_WHITE_LIST = 3;

/****************************************************************************************************************************
	Black List
****************************************************************************************************************************/

local black_list = {};

local IsBlackListed = function(url)

end

/****************************************************************************************************************************
	WhiteList
****************************************************************************************************************************/

local white_list = {};

local IsWhiteListed = function(url)

end

/****************************************************************************************************************************
	Can access URL
****************************************************************************************************************************/

local GetURLPerm = function(entity, noGlobal)
	local r = Get(entity, LocalPlayer(), "URL", noGlobal);

	if r == EXPR_GLOBAL and not noGlobal then
		r = GetGlobal(LocalPlayer(), "URL");
	end

	return r or EXPR_DENY;
end

EXPR_PERMS.GetURLPerm = GetURLPerm;

local CanGetURL = function(entity, url)
	
	local r = GetURLPerm(entity);

	if r == EXPR_GLOBAL then r = GetGlobal(LocalPlayer(), "URL"); end
	
	if r == EXPR_DENY then return false; end
	if r == EXPR_ALLOW then return true; end

	if r == EXPR_BLACK_LIST then return IsBlackListed(url); end
	if r == EXPR_WHITE_LIST then return IsWhiteListed(url); end

	if r == EXPR_FRIEND then return FriendCheck(Owner(enity), owner); end

	return false;
end;

EXPR_PERMS.CanGetURL = CanGetURL;
