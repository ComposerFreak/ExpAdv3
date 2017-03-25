--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::MISC::
	For things that need a home.
]]

local extenstion = EXPR_LIB.RegisterExtenstion("util");

extenstion:RegisterLibrary("game");

extenstion:RegisterFunction("game", "map", "", "s", 1, game.GetMap);

extenstion:RegisterFunction("game", "hostname", "", "s", 1, function()
	return GetConVar("hostname"):GetString();
end, true);

extenstion:RegisterFunction("game", "isLan", "", "b", 1, function()
	return GetConVar("sv_lan"):GetBool()
end, true);

extenstion:RegisterFunction("game", "gamemode", "", "s", 1, function()
	return gmod.GetGamemode().Name;
end, true);

extenstion:RegisterFunction("game", "isSinglePlayer", "", "b", 1, game.SinglePlayer, true);

extenstion:RegisterFunction("game", "isSinglePlayer", "", "b", 1, game.IsDedicated, true);

extenstion:RegisterFunction("game", "numPlayers", "", "n", 1, function()
	return #player.GetAll();
end, true);

extenstion:RegisterFunction("game", "maxPlayers", "", "n", 1, game.MaxPlayers, true);

extenstion:RegisterFunction("game", "gravity", "", "n", 1, function()
	return GetConVar("sv_gravity"):GetFloat()
end, true);

extenstion:RegisterFunction("game", "propGravity", "", "v", 1, physenv.GetGravity, true);

extenstion:RegisterFunction("game", "airDensity", "", "n", 1, physenv.GetAirDensity, true);

extenstion:RegisterFunction("game", "maxFrictionMass", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxFrictionMass"];
end, true);

extenstion:RegisterFunction("game", "minFrictionMass", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MinFrictionMass"];
end, true);

extenstion:RegisterFunction("game", "speedLimit", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxVelocity"];
end, true);

extenstion:RegisterFunction("game", "angSpeedLimit", "", "n", 1, function()
	return physenv.GetPerformanceSettings()["MaxAngularVelocity"];
end, true);

extenstion:RegisterFunction("game", "tickInterval", "", "n", 1, engine.TickInterval, true);

extenstion:RegisterFunction("game", "tickRate", "", "n", 1, function()
	return 1 / engine.TickInterval();
end, true);

extenstion:EnableExtenstion();