/****************************************************************************************************************************
	E3 Permissions System
****************************************************************************************************************************/

EXPR_PERMS = {};

EXPR_DENY = 0;
EXPR_FRIEND = 1;
EXPR_GLOBAL = 1; --Yes this is deliberate.
EXPR_ALLOW = 2;

/****************************************************************************************************************************
	
****************************************************************************************************************************/
local FriendCheck;
local PPCheckPlayer;
local PPCheck;
local SetGlobal;
local GetGlobal;
local Owner;
local Set;
local Get;

/****************************************************************************************************************************
	
****************************************************************************************************************************/

function EXPR_PERMS.getAll()
	return EXPR_LIB.PERMS;
end

/****************************************************************************************************************************
	Get Owner
****************************************************************************************************************************/

Owner = function(entity)
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

SetGlobal = function(player, perm, value)
	if (not IsValid(player) or not player.UserID) then
		return;
	end

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

GetGlobal = function(player, perm)
	
	if (not IsValid(player) or not player.UserID) then
		return EXPR_DENY;
	end

	local id = player:UserID();

	local perms = ply_perms[id];

	if not perms then return EXPR_DENY end

	return perms[perm] or EXPR_DENY;
end

EXPR_PERMS.GetGlobal = GetGlobal;

/****************************************************************************************************************************
	Set Perm Setting
****************************************************************************************************************************/

Set = function(entity, target, perm, value)
	
	if not IsValid(entity) then return false; end
	if not IsValid(target) or not target.UserID then return false; end
	if not entity.Expression3 then return false; end

	local tid = target:UserID();
	local perms = entity.permissions[tid];

	if not perms then
		perms = { };
		entity.permissions[tid] = perms;
	end

	local old = perms[perm];

	if old ~= value then
		perms[perm] = value;

		if entity.CallEvent then
			entity:CallEvent("", 0, "PermissionChanged", {"p", target}, {"s", perm}, {"b", PPCheckPlayer(entity, target, perm)});
		end
	end

	return true;
end

EXPR_PERMS.Set = Set;

/****************************************************************************************************************************
	Get Perm Setting
****************************************************************************************************************************/

Get = function(entity, target, perm, notGlobal)
	
	if IsValid(entity) and IsValid(target) then

		local owner = Owner(entity);
	
		if owner == target and not notGlobal then
			return EXPR_ALLOW;
		end

		if (not target or not target.UserID) then
			return EXPR_DENY;
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
FriendCheck = function(player, target)

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

PPCheck = function(entity, object, perm)
	local owner = Owner(object);

	if not IsValid(owner) then return false; end

	local r = Get(entity, owner, perm or "PropControl");

	if r == EXPR_DENY then return false; end
	if r == EXPR_ALLOW then return true; end

	return FriendCheck(Owner(entity), owner);
end

EXPR_PERMS.PPCheck = PPCheck;

PPCheckPlayer = function(entity, target, perm)
	if not IsValid(target) then return false; end

	local r = Get(entity, target, perm or "PropControl");

	if r == EXPR_DENY then return false; end
	if r == EXPR_ALLOW then return true; end

	return FriendCheck(Owner(entity), target);
end

EXPR_PERMS.PPCheckPlayer = PPCheckPlayer;

/****************************************************************************************************************************
	Inject methods ont entities and contex.
****************************************************************************************************************************/

hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Permissions", function(entity, context, env)
	entity.permissions = entity.permissions or {};
	entity.getPerm = Get;
	entity.setPerm = Set;
	entity.getOwner = Owner;
	entity.ppCheck = PPCheck;
	entity.ppPlayer = PPCheckPlayer;

	context.permissions = entity.permissions;
	context.getPerm = function(context, target, perm, nglb) return Get(context.entity, target, perm, nglb); end;
	context.setPerm = function(context, target, perm, value) return Set(context.entity, target, perm, value); end;
	context.getOwner = function(context, target) return Owner(context.entity, target); end;
	context.ppCheck = function(context, target, perm) return PPCheck(context.entity, target, perm); end;
	context.ppPlayer = function(context, target, perm) return PPCheckPlayer(context.entity, target, perm); end;
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
	Create our filter pattern from our url
****************************************************************************************************************************/

local function CreateFilter(filter)
    return string.gsub(filter, "\\?.", {
        ["\\."]=".", 
        ["."]="%.", 
        ["\\%"]="%", 
        ["%"]="%%",
        ["*"]="([a-zA-Z0-9_]+)",
    });
end

/****************************************************************************************************************************
	Black List
****************************************************************************************************************************/

local black_list = { };

local GetBlackList = function()
	return black_list;
end

EXPR_PERMS.GetBlackList = GetBlackList;

local IsBlackListed = function(url)
	for _, filter in pairs(black_list) do
		
		if string.match(url, filter) then return false; end
	
	end

	return true;

end

EXPR_PERMS.IsBlackListed = IsBlackListed;

local BlackListURL = function(url)
	if url ~= "" and not black_list[url]then
		black_list[url] = CreateFilter(url);
	end
end

EXPR_PERMS.BlackListURL = BlackListURL;

local UnblackListURL = function(url)
	if black_list[url]then 
		black_list[url] = nil;
	end
end

EXPR_PERMS.UnblackListURL = UnblackListURL;

local LoadBlackList = function()
	
	black_list = {};

	local raw = file.Read("e3_url_blacklist", "DATA");
	local rows = string.Explode("\n", raw or "");
	
	for i = 1, #rows do
		BlackListURL(rows[i]);
	end

	hook.Run("Rexpression3.BlackList.URL");
end

EXPR_PERMS.LoadBlackList = LoadBlackList;

local SaveBlackList = function()
	
	local rows = {};

	for url, filter in pairs(black_list) do
		rows[#rows + 1] = url;
	end

	local raw = table.concat(rows, "\n");

	file.Write("e3_url_blacklist", raw, "DATA");
end

EXPR_PERMS.SaveBlackList = SaveBlackList;

/****************************************************************************************************************************
	WhiteList
****************************************************************************************************************************/

local white_list = {};

local GetWhiteList = function()
	return white_list;
end

EXPR_PERMS.GetWhiteList = GetWhiteList;

local IsWhiteListed = function(url)
	
	for _, filter in pairs(white_list) do
		
		if string.match(url, filter) then return false; end
	
	end

	return true;

end

EXPR_PERMS.IsWhiteListed = IsWhiteListed;

local WhiteListURL = function(url)
	if url ~= "" and not white_list[url]then
		white_list[url] = CreateFilter(url);
	end
end

EXPR_PERMS.WhiteListURL = WhiteListURL;

local UnwhiteListURL = function(url)
	if white_list[url]then 
		white_list[url] = nil;
	end
end

EXPR_PERMS.UnwhiteListURL = UnwhiteListURL;

local LoadWhiteList = function()
	
	white_list = {};

	local raw = file.Read("e3_url_whitelist", "DATA");
	local rows = string.Explode("\n", raw or "");
	
	for i = 1, #rows do
		WhiteListURL(rows[i]);
	end
end

EXPR_PERMS.LoadWhiteList = LoadWhiteList;

local SaveWhiteList = function()
	
	local rows = {};

	for url, filter in pairs(white_list) do
		rows[#rows + 1] = url;
	end

	local raw = table.concat(rows, "\n");

	file.Write("e3_url_whitelist", raw, "DATA");
end

EXPR_PERMS.SaveWhiteList = SaveWhiteList;

/****************************************************************************************************************************
	Access History
****************************************************************************************************************************/

local url_history = {};

local GetHistory = function()
	return url_history;
end

EXPR_PERMS.GetHistory = GetHistory;

local ClearHistory = function()
	url_history = {};
end

EXPR_PERMS.ClearHistory = ClearHistory;

local AddURLHistory = function(entity, url, result)
	local list = url_history[url];
	
	if not list then 
		list = {};
		url_history[url] = list
	end

	local id = entity:EntIndex();

	local sublist = list[id];

	if not sublist then 
		sublist = {c = 0};
		list[id] = sublist
	end

	sublist.r = result;
	sublist.c = sublist.c + 1;
end

EXPR_PERMS.ClearHistory = ClearHistory;

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

local CanGetURL = function(entity, url, perm)
	
	local r = GetURLPerm(entity);

	if perm and r ~= EXPR_DENY then

		local r2 = Get(entity, LocalPlayer(), perm);
		
		if r2 == EXPR_DENY then return false; end
	end

	if r == EXPR_GLOBAL then r = GetGlobal(LocalPlayer(), perm or "URL"); end

	AddURLHistory(entity, url, r);
	
	if r == EXPR_DENY then return false; end
	if r == EXPR_ALLOW then return true; end

	if r == EXPR_BLACK_LIST then return not IsBlackListed(url); end
	if r == EXPR_WHITE_LIST then return IsWhiteListed(url); end

	if r == EXPR_FRIEND then return FriendCheck(Owner(enity), owner); end

	return false;
end;

EXPR_PERMS.CanGetURL = CanGetURL;

/****************************************************************************************************************************
	Load Everything
****************************************************************************************************************************/

LoadWhiteList();

LoadBlackList();

hook.Add("Rexpression3.BlackList.URL", "BlackList.Defaults", function()
	BlackListURL("([0-9]+).([0-9]+).([0-9]+).([0-9]+)");
end);

/****************************************************************************************************************************
	Inject url methods
****************************************************************************************************************************/

hook.Add("Expression3.Entity.BuildSandbox", "Expression3.URLPermissions", function(entity, context, env)
	entity.getURLPerm = GetURLPerm;
	entity.canGetURL = CanGetURL;

	context.getURLPerm = function(context, ng) return GetURLPerm(context.entity, ng); end;
	context.canGetURL = function(context, url) return CanGetURL(context.entity, url); end;
end);