--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Expression 3 Tool::
]]

AddCSLuaFile();

TOOL.Name						= "Expression 3";
TOOL.Category					= "Expadv2";

--[[
]]

if CLIENT then
	language.Add("Tool.gmod_expression_3.name", "Expression 3 - Beta");
	language.Add("Tool.gmod_expression_3.desc", "Creates an ingame scripted entity.");
	language.Add("Tool.gmod_expression_3.0", "LMB: Create entity; RMB: Open editor.")

	language.Add("limit_expression3", "Expression 3 Entity limit reached.");
	language.Add("Undone_expression3", "Expression 3 - Removed.");
	language.Add("Cleanup_expression3", "Expression 3 - Removed.");
	language.Add("Cleaned_expression3s", "Expression 3 - Removed All Entities.");
end

--[[
]]

TOOL.ClientConVar.model = "";


--[[
]]

cleanup.Register("expression3");

--[[
]]

local function MakeExpression3(ply, pos, ang, model)
	local ent = ents.Create("wire_expression3_base");

	if (ent and ent.IsValid()) then
		ent:SetPos(pos);
		ent:SetAngles(ang);
		--ent:SetModel(model);
		ent:Activate();
		ent:Spawn();
	end

	return ent;
end

duplicator.RegisterEntityClass( "wire_expression3_base", MakeExpression3, "pos", "ang", "model");

--[[
]]

function TOOL:LeftClick(trace)

	local hit = trace.Entity;
		print("LEFT CLICK", hit);

	if (SERVER) then
		local model = self:GetClientInfo("model");

		local ang = trace.HitNormal:Angle() + Angle(90, 0, 0);
		print("hitPos::", trace.HitPos);
		local ent = MakeExpression3(self:GetOwner(), trace.HitPos, ang, model);

		print("ent::", ent)

		if (ent and IsValid(ent)) then
			ent.player = self:GetOwner();

			print("DrPrincessPony", ent.player);

			ent:SetPos(trace.HitPos + Vector(0, 0, 30));
			print("entPos::", ent:GetPos());
			undo.Create("expression3");

			undo.AddEntity(ent);

			undo.SetPlayer(self:GetOwner());

			undo.Finish( );

			self:GetOwner():AddCleanup("expression3", ent);
		end
	end

	return true;
end

--[[
]]

function TOOL:RightClick( Trace )
	if (SERVER) then
		self:GetOwner():SendLua( [[
		local editor = Golem.GetInstance();
		editor:SetVisible(true);
		editor:MakePopup();]]);
	end
end