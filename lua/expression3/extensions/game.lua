local extension = EXPR_LIB.RegisterExtension("game");

--[[
	Game for all your game information.
]]

extension:RegisterLibrary("game");

extension:RegisterFunction("game", "map", "", "s", 1, game.GetMap);

extension:RegisterFunction("game", "hostname", "", "s", 1, function()
	return GetConVar("hostname"):GetString();
end, true);

extension:RegisterFunction("game", "isLan", "", "b", 1, function()
	return GetConVar("sv_lan"):GetBool()
end, true);

extension:RegisterFunction("game", "gamemode", "", "s", 1, function()
	return gmod.GetGamemode().Name;
end, true);

extension:RegisterFunction("game", "isSinglePlayer", "", "b", 1, game.SinglePlayer, true);

extension:RegisterFunction("game", "isSinglePlayer", "", "b", 1, game.IsDedicated, true);

extension:RegisterFunction("game", "numPlayers", "", "n", 1, function()
	return #player.GetAll();
end, true);

extension:RegisterFunction("game", "maxPlayers", "", "n", 1, game.MaxPlayers, true);

extension:RegisterFunction("game", "gravity", "", "n", 1, function()
	return GetConVar("sv_gravity"):GetFloat()
end, true);

extension:RegisterFunction("game", "propGravity", "", "v", 1, physenv.GetGravity, true);

extension:RegisterFunction("game", "airDensity", "", "n", 1, physenv.GetAirDensity, true);

extension:RegisterFunction("game", "maxFrictionMass", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxFrictionMass"];
end, true);

extension:RegisterFunction("game", "minFrictionMass", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MinFrictionMass"];
end, true);

extension:RegisterFunction("game", "speedLimit", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxVelocity"];
end, true);

extension:RegisterFunction("game", "angSpeedLimit", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxAngularVelocity"];
end, true);

extension:RegisterFunction("game", "tickInterval", "", "n", 1, engine.TickInterval, true);

extension:RegisterFunction("game", "tickRate", "", "n", 1, function()
	return 1 / engine.TickInterval();
end, true);

extension:EnableExtension();