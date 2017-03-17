--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Network Extension::
]]
--TODO: add a byte send and a net.sends p/s limit

if SERVER then
	util.AddNetworkString("EXP3_NETWORK_EXTENSION")
end

local networkData = {}
local networkReceiveData = {}
local networkReceives = {}

net.Receive("EXP3_NETWORK_EXTENSION", function(len, ply)
	local data = net.ReadTable()
	
	--TODO: Make this trigger when other side has been loaded, timer is just a placeholder to test things
	timer.Simple(5, function()
		if networkReceiveData[data.entityChip] then
			if networkReceiveData[data.entityChip][data.messageName] then
				networkReceiveData[data.entityChip][data.messageName].data = data
				networkReceives[data.entityChip] = data.messageName
				
				PrintTable(data)
				
				networkReceiveData[data.entityChip][data.messageName].func.op()
			end
		end
	end)
end)


local extension = EXPR_LIB.RegisterExtension("network")

extension:RegisterLibrary("net");

--[[
	Functions
]]

---------------
-----write-----
---------------
extension:RegisterFunction("net", "writeAngle", "a", "", 0, function(context, val) table.insert(networkData[context.entity].angle, val) end, false)
extension:RegisterFunction("net", "writeVector", "v", "", 0, function(context, val) table.insert(networkData[context.entity].vector, val) end, false)
extension:RegisterFunction("net", "writeColor", "c", "", 0, function(context, val) table.insert(networkData[context.entity].color, val) end, false)
extension:RegisterFunction("net", "writeEntity", "e", "", 0, function(context, val) table.insert(networkData[context.entity].entity, val) end, false)
extension:RegisterFunction("net", "writePlayer", "p", "", 0, function(context, val) table.insert(networkData[context.entity].player, val) end, false)
extension:RegisterFunction("net", "writeInt", "n", "", 0, function(context, val) table.insert(networkData[context.entity].number, val) end, false)
extension:RegisterFunction("net", "writeNumber", "n", "", 0, function(context, val) table.insert(networkData[context.entity].number, val) end, false)
extension:RegisterFunction("net", "writeString", "s", "", 0, function(context, val) table.insert(networkData[context.entity].string, val) end, false)
extension:RegisterFunction("net", "writeTable", "t", "", 0, function(context, val) table.insert(networkData[context.entity].table, val) end, false)
extension:RegisterFunction("net", "writeBool", "b", "", 0, function(context, val) table.insert(networkData[context.entity].bool, val) end, false)
extension:RegisterFunction("net", "writeBoolean", "b", "", 0, function(context, val) table.insert(networkData[context.entity].bool, val) end, false)

--------------
-----read-----
--------------
extension:RegisterFunction("net", "readAngle", "", "a", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.angle[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.angle, 1)
	return val
end, false)
extension:RegisterFunction("net", "readVector", "", "v", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.vector[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.vector, 1)
	return val
end, false)
extension:RegisterFunction("net", "readColor", "", "c", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.color[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.color, 1)
	return val
end, false)
extension:RegisterFunction("net", "readEntity", "", "e", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.entity[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.entity, 1)
	return val
end, false)
extension:RegisterFunction("net", "readPlayer", "", "p", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.player[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.player, 1)
	return val
end, false)
extension:RegisterFunction("net", "readInt", "", "n", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.number[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.number, 1)
	return val
end, false)
extension:RegisterFunction("net", "readNumber", "", "n", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.number[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.number, 1)
	return val
end, false)
extension:RegisterFunction("net", "readString", "", "s", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.string[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.string, 1)
	return val
end, false)
extension:RegisterFunction("net", "readTable", "", "t", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.table[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.table, 1)
	return val
end, false)
extension:RegisterFunction("net", "readBool", "", "b", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.bool[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.bool, 1)
	return val
end, false)
extension:RegisterFunction("net", "readBoolean", "", "b", 1, function(context)
	local val = networkReceiveData[context.entity][networkReceives[context.entity]].data.bool[1]
	table.remove(networkReceiveData[context.entity][networkReceives[context.entity]].data.bool, 1)
	return val
end, false)

---------------
-----other-----
---------------
extension:RegisterFunction("net", "start", "s", "", 0, function(context, name)
	networkData[context.entity] = {
		angle = {},
		vector = {},
		color = {},
		entity = {},
		player = {},
		number = {},
		string = {},
		table = {},
		bool = {},
		messageName = name,
		entityChip = context.entity
	}
end, false)

extension:RegisterFunction("net", "send", "", "", 0, function(context)
	net.Start("EXP3_NETWORK_EXTENSION")
	net.WriteTable(networkData[context.entity])
	net.SendToServer()
	
	networkData[context.entity] = nil
end, false)

extension:RegisterFunction("net", "send", "p", "", 0, function(context, val)
	net.Start("EXP3_NETWORK_EXTENSION")
	net.WriteTable(networkData[context.entity])
	net.Send(val)
	
	networkData[context.entity] = nil
end, false)

extension:RegisterFunction("net", "send", "t", "", 0, function(context, val)
	net.Start("EXP3_NETWORK_EXTENSION")
	net.WriteTable(networkData[context.entity])
	net.Send(val)
	
	networkData[context.entity] = nil
end, false)

extension:RegisterFunction("net", "broadcast", "", "", 0, function(context)
	net.Start("EXP3_NETWORK_EXTENSION")
	net.WriteTable(networkData[context.entity])
	net.Broadcast()
	
	networkData[context.entity] = nil
end, false)

extension:RegisterFunction("net", "receive", "s,f", "", 0, function(context, name, func)
	networkReceiveData[context.entity] = networkReceiveData[context.entity] or {}
	
	networkReceiveData[context.entity][name] = {func = func, data = {}}
end, false)

--[[
]]

extension:EnableExtension()