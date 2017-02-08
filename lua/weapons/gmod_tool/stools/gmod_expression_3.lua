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

TOOL.Name						= "Expression 3 - Gate";
TOOL.Category					= "Expression 3 - Tools";


cleanup.Register("expression3");

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

TOOL.GateModels = {
	"models/nezzkryptic/e3_chip.mdl",
	"models/lemongate/lemongate.mdl",
	"models/shadowscion/lemongate/gate.mdl",
	"models/mandrac/wire/e3.mdl",
};


if WireLib then
	table.insert( TOOL.GateModels, "models/bull/gates/processor.mdl" )
	table.insert( TOOL.GateModels, "models/expression 2/cpu_controller.mdl" )
	table.insert( TOOL.GateModels, "models/expression 2/cpu_expression.mdl" )
	table.insert( TOOL.GateModels, "models/expression 2/cpu_interface.mdl" )
	table.insert( TOOL.GateModels, "models/expression 2/cpu_microchip.mdl" )
	table.insert( TOOL.GateModels, "models/expression 2/cpu_processor.mdl" )
end

--[[
]]

TOOL.ClientConVar.name = "Generic";
TOOL.ClientConVar.author = "Wire User";
TOOL.ClientConVar.model = "models/nezzkryptic/e3_chip.mdl";

TOOL.ClientConVar.weld = "0"
TOOL.ClientConVar.parent = "1"
TOOL.ClientConVar.world = "0"
TOOL.ClientConVar.nocolide = "1"

--[[
	Welds or parents based on tool settings
]]

function TOOL:WeldOrParentEntity(ply, entity, trace, _undo)
	local world = (self:GetClientNumber( "world" ) == 1);

	if (!IsValid(trace.Entity) and !world) then
		return false;
	end

	if (self:GetClientNumber( "parent" ) == 1) then
		if (IsValid(trace.Entity) and (!trace.Entity:IsVehicle()) and (trace.Entity != entity)) then
			entity:SetParent(trace.Entity);
		end
	elseif (self:GetClientNumber( "weld" ) == 1) then
		local con = constraint.Weld( entity, trace.Entity, 0, trace.PhysicsBone, 0, 0, world );

		if (_undo) then
			undo.AddEntity(con);
		end
	end

	if (self:GetClientNumber( "nocolide" ) == 1) then
		local con = constraint.NoCollide( entity, trace.Entity, 0, trace.PhysicsBone, 0, 0, world );

		if (_undo) then
			undo.AddEntity(con);
		end
	end

end

--[[
]]

local function MakeExpression3(ply, pos, ang, model)
	local ent = ents.Create("wire_expression3_base");

	if (ent and IsValid(ent)) then
		ent:SetPos(pos);
		ent:SetAngles(ang);
		ent:SetModel(model);
		ent:Activate();
		ent:Spawn();
	end

	return ent;
end

duplicator.RegisterEntityClass( "wire_expression3_base", MakeExpression3, "pos", "ang", "model");

--[[
]]

function TOOL:RequestUpload(ply, ent)
	net.Start("Expression3.RequestUpload");
		net.WriteEntity(ent);
	net.Send(ply);
end

function TOOL:LeftClick(trace)
	local hit = trace.Entity;

	if (SERVER) then

		if (IsValid(hit) and hit.Expression3) then
			if (not hit:CPPICanTool(ply, "gmod_expression_3")) then
				return false;
			end

			self:RequestUpload(self:GetOwner(), hit);
		else
			local model = self:GetClientInfo("model");

			local ang = trace.HitNormal:Angle() + Angle(90, 0, 0);
			local ent = MakeExpression3(self:GetOwner(), trace.HitPos, ang, model);

			if (ent and IsValid(ent)) then
				ent.player = self:GetOwner();
				ent:SetCreator(ent.player);
				ent:SetPos(trace.HitPos - trace.HitNormal * ent:OBBMins().z);

				undo.Create("expression3");

				undo.AddEntity(ent);

				undo.SetPlayer(self:GetOwner());

				self:WeldOrParentEntity(self:GetOwner(), ent, trace, true);

				undo.Finish( );

				self:GetOwner():AddCleanup("expression3", ent);

				self:RequestUpload(self:GetOwner(), ent);
			end
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

/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Tool Panel
   --- */

if CLIENT then
	local TOOL = TOOL;

	function TOOL.BuildCPanel( CPanel )

		local PropList = vgui.Create( "PropSelect" )

		PropList:SetConVar( "gmod_expression_3_model" )

		for _, Model in pairs( TOOL.GateModels ) do
			PropList:AddModel( Model, false )
		end

		CPanel:AddItem( PropList )

		CPanel:CheckBox( "Weld to base", "gmod_expression_3_weld" )
		CPanel:CheckBox( "Parent to base", "gmod_expression_3_parent" )
		CPanel:CheckBox( "No-colide with base.", "gmod_expression_3_nocolide" )
		CPanel:CheckBox( "Constrain if base is world.", "gmod_expression_3_world" )
	end
end


/* --- ----------------------------------------------------------------------------------------------------------------------------------------------
	@: Ghost
   --- */

function TOOL:Think( )

	if !IsValid( self.GhostEntity ) or self.GhostEntity:GetModel( ) != self:GetClientInfo( "model" ) then
		return self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	local Trace = util.TraceLine( util.GetPlayerTrace( self:GetOwner( ) ) )
		
	if Trace.Hit then
		
		if IsValid( Trace.Entity ) and (Trace.Entity.ExpAdv or Trace.Entity:IsPlayer( ) ) then
			return self.GhostEntity:SetNoDraw( true )
		end
		
		local Ang = Trace.HitNormal:Angle( )
		Ang.pitch = Ang.pitch + 90
		
		self.GhostEntity:SetPos( Trace.HitPos - Trace.HitNormal * self.GhostEntity:OBBMins( ).z )
		self.GhostEntity:SetAngles( Ang )
		
		self.GhostEntity:SetNoDraw( false )
	end
end