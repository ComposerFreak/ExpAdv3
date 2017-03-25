--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Player Extension::
]]

local extension = EXPR_LIB.RegisterExtenstion("player")
local extensionTeam = EXPR_LIB.RegisterExtenstion("team")

extension:RegisterLibrary("ply");
extensionTeam:RegisterLibrary("team");

--[[
	CLASS
]]

local function isPlayer(p)
	return p:IsPlayer()
end

extension:RegisterClass("p", {"player"}, isPlayer, IsValid)

--extension:RegisterConstructor("p", "n", Player, true)

--[[
	Operators
]]

extension:RegisterOperator("eq", "p,p", "b", 1, function(a, b) return a == b end, true)
extension:RegisterOperator("neq", "p,p", "b", 1, function(a, b) return a != b end, true)

--[[
	Methods
]]

extension:RegisterMethod("p", "isValid", "", "b", 1, function(e)
	return IsValid(e)
end, true)

extension:RegisterMethod("p", "steamID", "", "s", 1, "SteamID")
extension:RegisterMethod("p", "steamID64", "", "s", 1, "SteamID64")

extension:RegisterMethod("p", "isTyping", "", "b", 1, "IsTyping")
extension:RegisterMethod("p", "isCrouching", "", "b", 1, "Crouching")
extension:RegisterMethod("p", "isFlashlightOn", "", "b", 1, "FlashlightIsOn")
extension:RegisterMethod("p", "isSuperAdmin", "", "b", 1, "IsSuperAdmin")
extension:RegisterMethod("p", "isAdmin", "", "b", 1, "IsAdmin")
extension:RegisterMethod("p", "isBot", "", "b", 1, "IsBot")
extension:RegisterMethod("p", "isInVehicle", "", "b", 1, "InVehicle")

extension:RegisterMethod("p", "getVehicle", "", "e", 1, "GetVehicle")
extension:RegisterMethod("p", "getTool", "", "s", 1, function(p) return p:GetTool().Mode end)
extension:RegisterMethod("p", "getToolName", "", "s", 1, function(p) return p:GetTool().Name end)

extension:RegisterMethod("p", "getAllWeapons", "", "t", 1, function(p)
	local tbl = {}
	
	for k, v in pairs(p:GetWeapons()) do
		tbl[v:GetClass()] = v:GetPrintName()
	end
	
	return tbl
end)

extension:RegisterMethod("p", "getAmmoPrimary", "", "s", 1, function(p)
	if p:GetActiveWeapon():IsValid() then return p:GetActiveWeapon():Ammo1() end
	return -1
end)

extension:RegisterMethod("p", "getAmmoSecondary", "", "s", 1, function(p)
	if p:GetActiveWeapon():IsValid() then return p:GetActiveWeapon():Ammo2() end
	return -1
end)

extension:RegisterMethod("p", "getClipPrimary", "", "s", 1, function(p)
	if p:GetActiveWeapon():IsValid() then return p:GetActiveWeapon():Clip1() end
	return -1
end)

extension:RegisterMethod("p", "getClipSecondary", "", "s", 1, function(p)
	if p:GetActiveWeapon():IsValid() then return p:GetActiveWeapon():Clip2() end
	return -1
end)

extension:RegisterMethod("p", "name", "", "s", 1, "Name")
extension:RegisterMethod("p", "ping", "", "n", 1, "Ping")
extension:RegisterMethod("p", "kills", "", "n", 1, "Frags")
extension:RegisterMethod("p", "deaths", "", "n", 1, "Deaths")
extension:RegisterMethod("p", "armor", "", "n", 1, "Armor")
extension:RegisterMethod("p", "health", "", "n", 1, "Health")
extension:RegisterMethod("p", "steamFriendStatus", "", "s", 1, "GetFriendStatus")

extension:RegisterMethod("p", "aimPos", "", "v", 1, function(p) return p:GetEyeTrace().HitPos end, true)
extension:RegisterMethod("p", "aimEntity", "", "e", 1, function(p) return p:GetEyeTrace().Entity end, true)
extension:RegisterMethod("p", "eyeTrace", "", "t", 1, function(p) return p:GetEyeTrace() end, true)
extension:RegisterMethod("p", "eyePos", "", "v", 1, "EyePos")
extension:RegisterMethod("p", "eyeAngles", "", "a", 1, "EyeAngles")
extension:RegisterMethod("p", "getPos", "", "v", 1, "GetPos")
extension:RegisterMethod("p", "getAngles", "", "v", 1, "GetAngles")

extension:RegisterMethod("p", "teamID", "", "n", 1, "Team")

--[[
	Functions
]]

extension:RegisterFunction("ply", "owner", "", "p", 1, function(context) return context.player end, false)

extension:RegisterFunction("ply", "localPlayer", "", "p", 1, LocalPlayer, true)

extension:RegisterFunction("ply", "getAll", "", "t", 1, player.GetAll, true)

extension:RegisterFunction("ply", "getBySteamID", "s", "p", 1, player.GetBySteamID, true)

extension:RegisterFunction("ply", "getBySteamID64", "s", "p", 1, player.GetBySteamID64, true)

extension:RegisterFunction("ply", "getByName", "s", "t", 1, function(s)
	local list = {}
	
	for k, ply in pairs(player.GetAll()) do
		if string.find(string.lower(ply:Name()), string.lower(s)) then
			table.insert(list, ply)
		end
	end
	
	return list
end, true)

--[[
]]

extensionTeam:RegisterFunction("team", "bestAutoJoin", "", "n", 1, team.BestAutoJoinTeam, true)
extensionTeam:RegisterFunction("team", "getAll", "", "t", 1, team.GetAllTeams, true)
extensionTeam:RegisterFunction("team", "getClass", "n", "t", 1, team.GetClass, true)
extensionTeam:RegisterFunction("team", "getColor", "n", "c", 1, team.GetColor, true)
extensionTeam:RegisterFunction("team", "getName", "n", "s", 1, team.GetName, true)
extensionTeam:RegisterFunction("team", "getPlayers", "n", "t", 1, team.GetPlayers, true)
extensionTeam:RegisterFunction("team", "getScore", "n", "n", 1, team.GetScore, true)
extensionTeam:RegisterFunction("team", "getSpawnPoints", "n", "t", 1, team.GetSpawnPoints, true)
extensionTeam:RegisterFunction("team", "joinable", "n", "b", 1, team.Joinable, true)
extensionTeam:RegisterFunction("team", "playerCount", "n", "n", 1, team.NumPlayers, true)
extensionTeam:RegisterFunction("team", "totalDeaths", "n", "n", 1, team.TotalDeaths, true)
extensionTeam:RegisterFunction("team", "totalKills", "n", "n", 1, team.TotalFrags, true)
extensionTeam:RegisterFunction("team", "valid", "n", "b", 1, team.Valid, true)

--[[
	Events
]]

hook.Add("PlayerButtonDown", "Expression3.Event", function(ply, button)
	EXPR_LIB.CallEvent("", 0, "PlayerButtonDown", {"p", ply}, {"n", button})
end)

hook.Add("PlayerButtonUp", "Expression3.Event", function(ply, button)
	EXPR_LIB.CallEvent("", 0, "PlayerButtonUp", {"p", ply}, {"n", button})
end)

hook.Add("OnPlayerChat", "Expression3.Event", function(ply, text, team, dead)
	local status, c = EXPR_LIB.CallEvent("b", 1, "OnPlayerChat", {"p", ply}, {"s", text}, {"b", team}, {"b", dead})
	
	if status then
		return c
	end
end)

hook.Add("PlayerSay", "Expression3.Event", function(ply, text, team)
	EXPR_LIB.CallEvent("", 0, "PlayerSay", {"p", ply}, {"s", text}, {"b", team})
end)

hook.Add("PlayerSpawn", "Expression3.Event", function(ply)
	EXPR_LIB.CallEvent("", 0, "OnPlayerSpawn", {"p", ply})
end)

hook.Add("PlayerInitialSpawn", "Expression3.Event", function(ply)
	EXPR_LIB.CallEvent("", 0, "OnPlayerJoin", {"p", ply})
end)

hook.Add("PlayerDisconnected", "Expression3.Event", function(ply)
	EXPR_LIB.CallEvent("", 0, "OnPlayerDisconnect", {"p", ply})
end)

--Player would be returned as entity in ea3 so entity methods would be able to be used on the player
--[[hook.Add("PlayerDeath", "Expression3.Event", function(ply, wep, attacker)
	EXPR_LIB.CallEvent("", 0, "OnPlayerDeath", {"p", ply}, {"e", wep}, {"e", attacker})
end)]]

--Add events to EXPR_LIB player event table to be used in autogen wiki
EXPR_LIB.WikiEvents = EXPR_LIB.WikiEvents or {}

EXPR_LIB.WikiEvents["PlayerButtonDown"] = {
	parameter = "p,n",
	state = 1
}
EXPR_LIB.WikiEvents["PlayerButtonUp"] = {
	parameter = "p,n",
	state = 1
}
EXPR_LIB.WikiEvents["OnPlayerChat"] = {
	parameter = "p,s,b,d",
	result = "b",
	state = 2
}
EXPR_LIB.WikiEvents["PlayerSay"] = {
	parameter = "p,s,b",
	state = 0
}
EXPR_LIB.WikiEvents["OnPlayerSpawn"] = {
	parameter = "p",
	state = 0
}
EXPR_LIB.WikiEvents["OnPlayerJoin"] = {
	parameter = "p",
	state = 0
}
EXPR_LIB.WikiEvents["OnPlayerDisconnect"] = {
	parameter = "p",
	state = 0
}

--[[
]]

extension:EnableExtenstion()
extensionTeam:EnableExtenstion()