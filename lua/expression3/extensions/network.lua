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

local NET_MAX = 10;
local NET_LIMIT = 512;

local extension = EXPR_LIB.RegisterExtension("network");

--[[
	Extention class with methods
]]

extension:RegisterClass("usmg", "stream", istable, istable);

local function writeBool(ctx, msg, bool)
	if (#msg.buffer > NET_LIMIT) then
		ctx:Throw("Failed to write Boolean to stream, max stream size reached.");
	end

	msg.size = msg.size + 1;
	msg.buffer[msg.size] = bool and 1 or 0;
end

local function readBool(ctx, msg)
	msg.size = msg.size - 1;
	msg.read = msg.read + 1;

	if (msg.read > #msg.buffer) then
		ctx:Throw("Unable to read Boolean from empty stream.");
	end

	return msg.buffer[msg.read] == 1;
end

extension:RegisterMethod("usmg", "writeBool", "b", "", 0, writeBool, false);
extension:RegisterMethod("usmg", "readBool", "", "b", 1, readBool, false);

---------------------------------------------------------------------------------

local function writeChar(ctx, msg, char, type)
	if (#msg.buffer > NET_LIMIT) then
		ctx:Throw("Failed to write " .. (type or "Char") .. " to stream, max stream size reached.");
	end

	msg.size = msg.size + 1;
	msg.buffer[msg.size] = char;
end

local function readChar(ctx, msg, type)
	msg.size = msg.size - 1;
	msg.read = msg.read + 1;

	if (msg.read > #msg.buffer) then
		ctx:Throw("Unable to read " .. (type or "Char") .. " from empty stream.");
	end

	return msg.buffer[msg.read];
end

extension:RegisterMethod("usmg", "writeChar", "n", "", 0, writeChar, false);
extension:RegisterMethod("usmg", "readChar", "", "n", 1, readChar, false);

---------------------------------------------------------------------------------

local function writeShort(ctx, msg, short)
	short = short + 32768;

	local a = math.modf(short / 256);

	writeChar(ctx, msg, a - 128, "Short");
	writeChar(ctx, msg, short - a * 256 - 128, "Short");
end

local function readShort(ctx, msg)
	return (readChar(ctx, msg, "Short") + 128) * 256 + readChar(ctx, msg, "Short") + 128 - 32768;
end

extension:RegisterMethod("usmg", "writeShort", "n", "", 0, writeShort, false);
extension:RegisterMethod("usmg", "readShort", "", "n", 1, writeShort, false);

---------------------------------------------------------------------------------

local function writeLong(ctx, msg, long)
	long = long + 2147483648;

	local a = math.modf(long / 16777216);
	long = long - a * 16777216;

    local b = math.modf(long / 65536);
    long = long - b * 65536;

    local c = math.modf(long / 256);
    long = long - c * 256;
   
    writeChar(ctx, msg, a - 128, "Long");
    writeChar(ctx, msg, b - 128, "Long");
    writeChar(ctx, msg, c - 128, "Long");
    writeChar(ctx, msg, long - 128, "Long");
end

local function readLong(ctx, msg)
	local a = readChar(ctx, msg, "Long") + 128;
	local b = readChar(ctx, msg, "Long") + 128;
	local c = readChar(ctx, msg, "Long") + 128;
	local d = readChar(ctx, msg, "Long") + 128;
    return a * 16777216 + b * 65536 + c * 256 + d - 2147483648;
end

extension:RegisterMethod("usmg", "writeLong", "n", "", 0, writeLong, false);
extension:RegisterMethod("usmg", "readLong", "", "n", 1, writeLong, false);

---------------------------------------------------------------------------------

local function writeFloat(ctx, msg, float)
	local neg = float < 0;
	float = math.abs(float);

	local e = 0;
	if (float >= 1) then
		while (float >= 1) do
			float = float / 10;
			e = e + 1;
		end
	else
		while (f < 0.1) do
			float = float * 10;
			e = e - 1;
		end
	end

	local s = tonumber(string.sub(float,3,9));
	s = (neg and -s or s) + 8388608;

	local a = math.modf(s / 65536);
	s = s - a * 65536;

	local b = math.modf(s / 256);
	s = s - b * 256;

	writeChar(ctx, msg, a - 128, "Float");
	writeChar(ctx, msg, b - 128, "Float");
	writeChar(ctx, msg, s - 128, "Float");
	writeChar(ctx, msg, e, "Float");
end

local function readFloat(ctx, msg)
	local a = readChar(ctx, msg, "Float") + 128;
	local b = readChar(ctx, msg, "Float") + 128;
	local c = readChar(ctx, msg, "Float") + 128;
	local e = readChar(ctx, msg, "Float");

	local s = a * 65536 + b * 256 + c - 8388608;

	if (s > 0) then
		return tonumber( "0." .. s ) * 10 ^ e;
	else
		return tonumber( "-0." .. math.abs(s) ) * 10 ^ e;
	end
end

extension:RegisterMethod("usmg", "writeFloat", "n", "", 0, writeFloat, false);
extension:RegisterMethod("usmg", "readFloat", "", "n", 1, writeFloat, false);

---------------------------------------------------------------------------------

local function writeString(ctx, msg, string)
	for i = 1, #string do
		writeChar(ctx, msg, string[i]:byte() - 128, "String");
	end
	
	writeChar(ctx, msg, 0, "String");
end

local function readString(ctx, msg)
	local str = "";
	local char = readChar(ctx, msg, "String");
	
	while (b ~= 0) do
		str = str .. string.char(char + 128);
		char = readChar(ctx, msg, "String");
	end

	return string;
end

extension:RegisterMethod("usmg", "writeString", "s", "", 0, writeString, false);
extension:RegisterMethod("usmg", "readString", "", "s", 1, readString, false);

---------------------------------------------------------------------------------

extension:RegisterMethod("usmg", "size", "", "n", 1, function(msg)
	return msg.size;
end, false);

extension:RegisterMethod("usmg", "readPos", "", "n", 1, function(msg)
	return msg.read;
end, false);

extension:RegisterMethod("usmg", "remain", "", "n", 1, function(msg)
	return msg.size - msg.read;
end, false);

--[[
	Recipient Filter Class
]]

extension:RegisterClass("crf", "recipientfilter", istable, istable);

extension:RegisterConstructor("crf", "", RecipientFilter, true);

extension:RegisterMethod("crf", "addAllPlayers", "", "", 0);

extension:RegisterMethod("crf", "addPAS", "v", "", 0);

extension:RegisterMethod("crf", "addPlayer", "p", "", 0);

extension:RegisterMethod("crf", "addPVS", "v", "", 0);

extension:RegisterMethod("crf", "addRecipientsByTeam", "n", "", 0);

extension:RegisterMethod("crf", "getCount", "", "n", 1);

extension:RegisterMethod("crf", "removeAllPlayers", "", "", 0);

extension:RegisterMethod("crf", "removePAS", "v", "", 0);

extension:RegisterMethod("crf", "removePlayer", "p", "", 0);

extension:RegisterMethod("crf", "removePVS", "v", "", 0);

extension:RegisterMethod("crf", "removeRecipientsByTeam", "n", "", 0);

extension:RegisterMethod("crf", "removeRecipientsNotOnTeam", "n", "", 0);

extension:RegisterMethod("crf", "getPlayers", "", "t", 1, function(crf)
	local t = {};

	for i, player in pairs(crf.GetPlayers()) do
		t[i] = {"p", player};
	end

	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

--[[
	Send the data.
]]

if (SERVER) then
	util.AddNetworkString("Expression3.Network.Send");
end

local function queueMessage(ctx, msg, filter)
	local queue = ctx.data.net_queue or {};

	if (#queue >= NET_MAX) then
		this:Throw("Attempt to send net stream, too meany streams queued.")
	elseif (CLIENT) then
		queue[#queue + 1] = {msg = msg};
	else
		queue[#queue + 1] = {msg = msg, filter = filter};
	end

	ctx.data.net_queue = queue;
end

hook.Add("Expression3.Entity.Update", "Expression3.Network.SendMessages", function(entity, context)
	local queue = ctx.data.net_queue;

	if (queue and #queue > 0) then
		for _, data in pairs(queue) do
			local msg = data.msg;

			net.Start("Expression3.Network.Send");
				net.WriteEntity(entity);
				net.WriteString(msg.name);
				net.WriteUInt(#msg.buffer, 16);

				for i = 1, #msg.buffer do
					net.WriteUInt(msg.buffer, 8);
				end

			if (CLIENT) then
				net.SendToServer();
			elseif (msg.filter) then
				net.Send(msg.filter);
			else
				net.Broadcast();
			end
		end

		ctx.data.net_queue = nil;
	end
end);

net.Receive("Expression3.Network.Send", function(len, ply)
	local entity = net.ReadEntity();
	local name = net.ReadString();
	local count = net.ReadUInt(16);

	local buffer = {};

	for i = 1, count do
		buffer[i] = net.ReadUInt(8);
	end

	local msg = {name = name, buffer = buffer, size = #buffer, read = 0};

	if (IsValid(entity) and entity.IsRunning and entity:IsRunning()) then
		local callbacks = entity.context.data.net_callbacks;

		if (callbacks and callbacks[name]) then
			entity:Execute(callbacks[name], {"_usmg", msg}, ply and {"p", ply} or nil);
		end
	end
end);

--[[
	Extention Library
]]

extension:RegisterLibrary("net");

extension:RegisterFunction("net", "start", "s", "usmg", 1, function(name)
	return {name = name, buffer = {}, size = 0, read = 0};
end, true);

extension:SetClientState();

extension:RegisterFunction("net", "sendToServer", "usmg", "", 0, queueMessage, false);

extension:SetServerState();

extension:RegisterFunction("net", "sendToClients", "usmg", "", 0, queueMessage, false);

extension:RegisterFunction("net", "sendToClients", "usmg,crf", "", 0, queueMessage, false);

extension:SetSharedState();

extension:RegisterFunction("net", "receive", "s,f", "", 0, function(ctx, name, cb)
	ctx.data.net_callbacks = ctx.data.net_callbacks or {};
	ctx.data.net_callbacks[name] = cb;
end, false);

extension:EnableExtension();