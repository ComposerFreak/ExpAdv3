--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Uploader::

	I know i will be proud of this.
]]

local UPLOADER = {};

EXPR_UPLOADER = UPLOADER;

--[[
	States
]]

local ST_IDLE = 0;
local ST_ERROR = 1;
local ST_REQUESTING = 2;
local CL_VALIDATING = 3;
local CL_UPLOADING = 4;
local CL_RECEIVING = 5;
local SL_UPLOADING = 6;
local SL_RECEIVING = 7;
local SL_VALIDATING = 8;

--[[
	Network Strings
]]

if SERVER then
	AddCSLuaFile(); --got to add it some where.
	
	util.AddNetworkString("Expression3.RequestFromClient");

	util.AddNetworkString("Expression3.SetState");

	util.AddNetworkString("Expression3.SendPacketToServer");

	util.AddNetworkString("Expression3.SendPacketToClient");

end

--[[
	SERVER STATE
]]

if SERVER then

	local cl_states = {};
	local cl_percent = {};

	UPLOADER.SetState = function(client, state, per, sync)
		per = per or 0;
		state = state or ST_IDLE;
		sync = ((cl_percent[client] ~= per) or (cl_states[client] ~= state)) and sync;

		cl_states[client] = state;

		if sync then
			net.Start("Expression3.SetState");
				net.WriteInt(state, 16);
				net.WriteInt(per, 32);
			net.Send(client);
		end
	end

	UPLOADER.GetState = function(client, state, sync)
		return cl_states[client] or ST_IDLE;
	end

end

--[[
	CLIENT STATE
]]

if CLIENT then

	local state = ST_IDLE;
	local percent = 0;

	UPLOADER.GetState = function()
		return state or ST_IDLE, percent or 0;
	end;

	UPLOADER.SetState = function(st, per)
		-- You should never call this, only I call this :D
		state = st or ST_IDLE;
		percent = per or 0;
	end;

	net.Receive("Expression3.SetState", function(len)
		state = net.ReadInt(16) or ST_IDLE;
		percent = net.ReadInt(32) or 0;
	end);

end

--[[
	SERVER - SEND REQUEST TO CLIENT
]]

if SERVER then

	local targets = {};

	UPLOADER.RequestFromClient = function(client, entity)
		UPLOADER.SetState(client, ST_REQUESTING, 0, false);

		net.Start("Expression3.RequestFromClient");
			net.WriteEntity(entity);
		net.Send(client);

		targets[client] = entity;
	end

end

--[[
	CLIENT RECEIVE REQUEST FROM SERVER
	CLIENT VALIDATES GOLEM TAB
]]

if CLIENT then

	local validator;

	UPLOADER.ValidateScript = function(script, target)
		if not script or script == "" then return; end

		if (validator and not validator.finished) then
			return chat.AddText("Failed: Another E3 is uploading.");
		end

		local cb = function(ok, res)
			if not ok then
				UPLOADER.SetState(ST_ERROR, 0);
				return;
			end

			local files = res.directives.includes or {};
			local name = res.directives.name or "generic";
			UPLOADER.SendToServer(target, name, script, files);
		end;

		validator = EXPR_LIB.Validate(cb, script);

		validator.start();

		UPLOADER.SetState(CL_VALIDATING, 0);
	end;

	timer.Create("Expression3.UploadValidator", 0.5, 0, function()
		if UPLOADER.GetState() ~= CL_VALIDATING then return; end
		if not validator or validator.finished then return; end
		UPLOADER.SetState(CL_VALIDATING, 0); -- TODO: Should be % of validation
	end)

	net.Receive("Expression3.RequestFromClient", function(len)
		local ent = net.ReadEntity();
		if IsValid(ent) then UPLOADER.ValidateScript(Golem.GetCode(), ent); end
	end);

end

--[[
	a Table of Packets
]]

local net_max = 64000000; --64000kb

local net_len = function(str)
	return 8 + (#str * 8);
end

--PLAYER32, ENTITY32, PACKETID32, PACKETTOTAL32, FILEPOS32, FILENAME?, DATA?

UPLOADER.BuildPackets = function(files)
	local packets = {};

	for filename, filedata in pairs(files) do
		
		local size = (32 * 5) + net_len(filename);
		local remain = net_max - size;
		local i = 0;

		for p = 1, #filedata, remain do
			i = i + 1;

			local id = #packets + 1;

			packets[id] = {
				id = id,
				pos = i;
				filename = filename;
				filedata = string.sub(filedata, p, p + remain - 1);
			};
		end
	end

	return packets;
end

--[[
	CLIENT SEND PACKETS TO SERVER
]]

if CLIENT then

	UPLOADER.SendPacketToServer = function(entity, packet, count)
		net.Start("Expression3.SendPacketToServer");
			net.WriteEntity(entity);
			net.WriteString(packet.filename);
			net.WriteString(packet.filedata);
			net.WriteInt(packet.pos, 32);
			net.WriteInt(packet.id, 32);
			net.WriteInt(count, 32);
		net.SendToServer();

		local per = math.ceil((packet.id / count) * 100);

		UPLOADER.SetState(CL_UPLOADING, per);
	end;

	UPLOADER.SendToServer = function(entity, name, script, includes)
		local files = {};

		files["root"] = script;

		for _, file_path in pairs(includes) do
			files[file_path] = file.Read("golem/" .. file_path .. ".txt", "DATA");
		end

		local packets = UPLOADER.BuildPackets(files);
		local count = #packets;
		local cur = 0;

		UPLOADER.SetState(CL_UPLOADING, 0);

		local expire = CurTime() + count + 5;
		
		timer.Create("Expression3.SendToServer", 0, 1, function()
			if UPLOADER.GetState() ~= CL_UPLOADING then return; end

			if not packets or not count or count == 0 or not cur then 
				UPLOADER.SetState(ST_IDLE, 0);
				return;
			end

			if expire and expire < CurTime() then
				UPLOADER.SetState(ST_ERROR, 0);
				return;
			end

			cur = cur + 1;

			if cur > count then
				UPLOADER.SetState(SL_RECEIVING, 0);
				return;
			end

			UPLOADER.SendPacketToServer(entity, packets[cur], count);
		end);
	end;
end

--[[
	SERVER RECIVE PACKET FROM CLIENT.
]]

if SERVER then
	
	local cl_packets = {};

	net.Receive("Expression3.SendPacketToServer", function(len, client)
		local packets = cl_packets[client];

		if not packets then
			packets = {};
			cl_packets[client] = packets;
		end

		local packet = {
			entity = net.ReadEntity(),
			filename = net.ReadString(),
			filedata = net.ReadString(),
			pos = net.ReadInt(32),
			id = net.ReadInt(32),
			count = net.ReadInt(32),
		};

		local total = #packets + 1;

		packets[total] = packet;

		if total < packet.count then
			local per = math.ceil((total / packet.count) * 100);
			
			UPLOADER.SetState(SL_RECEIVING, per, false);
			
			return;
		end

		local ok, files = UPLOADER.CompilePackets(packet.entity, packets, packet.count);

		cl_packets[client] = {};

		if not ok then
			UPLOADER.SetState(ST_ERROR, 0, true);
			return;
		end

		UPLOADER.ApplyToEntity(packet.entity, client, files);
	end);
			
end

--[[
	COMPILE PACKETS
]]

UPLOADER.CompilePackets = function(entity, packets, count, owner)
	local includes = {};

	for _, packet in pairs(packets) do
		if packet.count ~= count then return false; end
		if packet.entity ~= entity then return false; end
		if owner and packet.owner ~= owner then return false; end

		local include = includes[packet.filename];

		if not include then
			include = {};
			includes[packet.filename] = include;
		end

		include[packet.pos] = packet.filedata;
	end

	local files = {};

	for filename, parts in pairs(includes) do
		files[filename] = table.concat(parts);
	end

	return true, files;
end

--[[
	SERVER VALIDATES AND EXECUTES CODE
]]

if SERVER then

	local en_validators = {};
	local cl_validators = {};

	UPLOADER.ApplyToEntity = function(entity, client, files)

		--TODO: Perm Check!
		
		if IsValid(entity) and entity.SetCode and entity.ExecuteInstance then

			local ok, validator;

			local cb = function(ok, res)
				local active = (cl_validators[client] == validator);
				
				if ok and active then UPLOADER.SetState(client, ST_IDLE, 0, true); end
				if (not ok) and active then UPLOADER.SetState(client, ST_ERROR, 0, true); end
				
				if ok then
					UPLOADER.SendToClients(nil, entity, entity.player, entity.script, entity.files);
				end

				if active then cl_validators[client] = nil; end

				en_validators[entity] = nil;

			end;

			ok, validator = entity:SetCode(files.root, files, true, cb);

			en_validators[entity] = validator;

			cl_validators[client] = validator;

			UPLOADER.SetState(client, SL_VALIDATING, 0, true);

			return;
		end

		UPLOADER.SetState(client, ST_ERROR, 0, true);

	end;

	timer.Create("Expression3.ApplyToEntity", 0, 0.5, function()

		for client, validator in pairs(cl_validators) do
			
			if validator and not validator.finished and UPLOADER.GetState(client) == SL_VALIDATING then
				UPLOADER.SetState(client, SL_VALIDATING, 0, true); -- TODO: Should be % of validation
			end
		end

	end);
end

--[[
	SERVER SENDS PACKETS TO CLIENTS
]]

if SERVER then 

	UPLOADER.SendPacketToClient = function(client, entity, owner, packet, count)
		net.Start("Expression3.SendPacketToClient");
			net.WriteEntity(entity);
			net.WriteEntity(owner);
			net.WriteString(packet.filename);
			net.WriteString(packet.filedata);
			net.WriteInt(packet.pos, 32);
			net.WriteInt(packet.id, 32);
			net.WriteInt(count, 32);
		if client then net.Send(client); else net.Broadcast(); end
	end;

	UPLOADER.SendToClients = function(client, entity, owner, script, files)
		files["root"] = script;

		local packets = UPLOADER.BuildPackets(files, owner);
		local count = #packets;
		local cur = 0;

		timer.Create("Expression3.SendToClient." .. entity:EntIndex(), count + 2, 1, function()
			
			if not packets or not count or count == 0 or not cur then 
				return;
			end

			if expire and expire < CurTime() then
				return;
			end

			cur = cur + 1;

			if cur > count then
				return;
			end

			UPLOADER.SendPacketToClient(client, entity, owner, packets[cur], count);
		end);
	end;
end

--[[
	CLIENT RECIVES PACKETS
]]

if CLIENT then

	local en_packets = {};

	net.Receive("Expression3.SendPacketToClient", function(len)
		local entity = net.ReadEntity();
		local owner = net.ReadEntity();
		local packets = en_packets[entity];

		if not packets then
			packets = {};
			en_packets[entity] = packets;
		end

		local packet = {
			entity = entity,
			owner = owner,
			filename = net.ReadString(),
			filedata = net.ReadString(),
			pos = net.ReadInt(32),
			id = net.ReadInt(32),
			count = net.ReadInt(32),
		};

		local total = #packets + 1;

		packets[total] = packet;

		if total < packet.count then
			--local per = math.ceil((total / packet.) * 100);
			return;
		end

		local ok, files = UPLOADER.CompilePackets(entity, packets, packet.count, owner);

		if ok then
			UPLOADER.ApplyToEntity(entity, owner, files);
		end

		en_packets[entity] = nil;
	end);

end

--[[
	CLIENT APPLIES CODE TO ENTITY
]]

if CLIENT then

	local en_validators = {};

	UPLOADER.ApplyToEntity = function(entity, owner, files)
		if IsValid(entity) and entity.SetCode and entity.ExecuteInstance then

			local ok, validator;

			local cb = function(ok, res)
				en_validators[entity] = nil;
			end;

			entity.player = owner;

			ok, validator = entity:SetCode(files.root, files, true, cb);

			en_validators[entity] = validator;
		end
	end;

end

--[[
	PLAYER JOINS SERVER, SEND INFO
]]
	
if SERVER then

	hook.Add("PlayerInitialSpawn", "Expression3.Uploader", function(client)
		
		timer.Simple(0.2, function()
			for _, context in pairs(EXPR_LIB.GetAll()) do
				local entity = context.entity;

				if IsValid(entity) then
					UPLOADER.SendToClients(client, entity, entity.player, entity.script, entity.files);
				end
			end
		end);

	end);
end

--[[
	CLIENT HAS TOOL GUN
]]

if CLIENT then
	local font = "DermaLarge";
	local background = surface.GetTextureID("omicron/bulb");

	local drawBG = function(w, h)
		--Background color:
		surface.SetDrawColor(Color( 20, 20, 20 ));
		surface.DrawRect(0, 0, w, h);

		--Background image:
		surface.SetTexture(background);
		surface.SetDrawColor(Color(255, 255, 255, 255));
		surface.DrawTexturedRect(10, 10, w - 20, h - 20);
	end

	local drawState = function(w, h, text, icon, per)
		local rw, rh = 150, 30;
		local x, y = w * 0.5, h * 0.5;

		if icon then
			local size = 64;
			surface.SetMaterial(icon);
			surface.SetDrawColor(Color(255, 255, 255, 255));
			surface.DrawTexturedRect(x - (size * 0.5), y - (h * 0.25), size, size);
		end

		if per and per > 0 then
			local b = 3;
			surface.SetDrawColor(Color(0, 0, 0, 255));
			surface.DrawRect(x - (rw * 0.5) - b, h - rh - 90 - b, rw + (b * 2), rh + (b * 2));

			surface.SetDrawColor(Color(255, 0, 0, 255));
			surface.DrawRect(x - (rw * 0.5), h - rh - 90, rw, rh);

			surface.SetDrawColor(Color(0, 255, 0, 255));
			surface.DrawRect(x - (rw * 0.5), h - rh - 90, rw * (per * 0.01), rh);
		end

		if text and text ~= "" then
			draw.SimpleText(text, font, x, h - rh - 75, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);
		end
	end

	local icon_error = Material("fugue/exclamation-red.png");
	local icon_request = Material("fugue/monitor-network.png");
	local icon_validate = Material("fugue/eye--arrow.png");
	local icon_upload = Material("fugue/drive-upload.png");
	local icon_receive = Material("fugue/question.png");

	UPLOADER.DrawUploadScreen = function(w, h, tool)
		local state, per = UPLOADER.GetState();

		drawBG(w, h);

		if state == ST_ERROR then 
			return drawState(w, h, "Error", icon_error, nil);
		end

		if state == ST_REQUESTING then
			return drawState(w, h, "Requesting", icon_request, nil);
		end

		if state == CL_VALIDATING or state == SL_VALIDATING then
			return drawState(w, h, "Validating", icon_validate, per);
		end

		if state == CL_UPLOADING or state == SL_UPLOADING then
			return drawState(w, h, "Uploading", icon_upload, per);
		end

		if state == CL_RECEIVING or state == SL_RECEIVING then
			return drawState(w, h, "Recieving", icon_receive, per);
		end

		local x, y = w * 0.5, h * 0.5;
		local color = Color(10, 10, 10, 255);
		draw.SimpleText("Expression 3", font, x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
		draw.SimpleText(tool, font, x, y + 20, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );

	end;

end	

		
		
		