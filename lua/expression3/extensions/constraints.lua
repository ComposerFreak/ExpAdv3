local extension = EXPR_LIB.RegisterExtension("constraint")

extension:SetServerState();

--[[
	
]]

function isCon(con)
	return istable(con) and con.valid and IsValid(con.entity1) and IsValid(con.entity2);
end

function isValidCon(con)
	return istable(con) and con.valid;
end

extension:RegisterClass("con", {"constraint"}, isCon, isValidCon);

local zero = {
	isWeld = false,
	isNoCollide = false,
	isAdvBallsocket = false,
	isConstraint = false,
	isParent = false,
	isWire = false,
	valid = false,
	type = "invalid",
	entity1 = Entity(0),
	entity2 = Entity(0),
}
--[[
	
	Convert GMod table to E3 object
]]

local function toConstraint(con, ent)
	if not IsValid(con) and not con.Type then return zero; end

	local constraint = {valid = true};

	if (con.Type == "Weld") then
		constraint.isWeld = true;
		constraint.type = "Weld";

	elseif (con.Type == "NoCollide") then
		constraint.isNoCollide = true;
		constraint.type = "NoCollide";

	elseif (con.Type == "AdvBallsocket") then
		constraint.isAdvBallsocket = true;
		constraint.type = "AdvBallsocket";

	elseif (con.Type == "Constraints") then
		constraint.isConstraint = true;
		constraint.type = "Constraint";

	elseif (con.Type == "Parented") then
		constraint.isParent = true;
		constraint.type = "Parent";

	elseif (con.Type == "Wires") then
		constraint.isWire = true;
		constraint.type = "Wire";
	else
		constraint.type = con.Type;
	end

	if (ent and con.Ent1 == ent) then
		constraint.entity1 = con.Ent2;
		constraint.entity2 = con.Ent1;
	else
		constraint.entity1 = con.Ent1;
		constraint.entity2 = con.Ent2;
	end

	return constraint;
end

--[[
	Comparison Operators
]]

extension:RegisterOperator("eq", "con,con", "b", 1);
extension:RegisterOperator("neq", "con,con", "b", 1);

extension:RegisterOperator("is", "con", "b", 1, isValidCon);

--[[
	Atributes
]]

extension:RegisterAttribute("con", "entity1", "e");
extension:RegisterAttribute("con", "entity2", "e");
extension:RegisterAttribute("con", "isWeld", "b");
extension:RegisterAttribute("con", "isNoCollide", "b");
extension:RegisterAttribute("con", "isAdvBallsocket", "b");
extension:RegisterAttribute("con", "isConstraint", "b");
extension:RegisterAttribute("con", "isParent", "b");
extension:RegisterAttribute("con", "isWire", "b");

extension:RegisterMethod("con", "getType", "", "s", 1, function(con)
		return con.type or "";
end, true);


--[[
	get all contraints as a table or object
]]

local function getContraints(ent, filter, first)
	if not IsValid(ent) or not ent.Constraints then return {}; end

	local arr = {};

	for _, con in pairs( ent.Constraints ) do
		if IsValid(con) then
			local constraint = toConstraint(con, ent);

			if constraint then
				if (not filter) or constraint.type == filter then
					if (first) then return constraint; end
					
					arr[#arr + 1] = {"_con", constraint};
				end
			end
		end
	end

	if not first then
		return arr;
	end
end

--[[
	Basic functions
]]

extension:RegisterMethod("e", "totalConstraints", "", "n", 1, function(e)
	local arr = getContraints(e);
	return #arr;
end, true);

extension:RegisterMethod("e", "isConstrained", "", "n", 1, function(e)
	return getContraints(e, nil, true) and true or false;
end, true);

--[[
	Get first constraint
]]

extension:RegisterMethod("e", "getWeld", "", "con", 1, function(e)
	local con = getContraints(e, "Weld", true);
	if (not con) then return zero; end
	return con;
end, true);

extension:RegisterMethod("e", "getWeld", "n", "con", 1, function(e, i)
	local arr = getContraints(e, "Weld");
	if (#arr < i) then return zero; end
	return arr[i][2];
end, true);


--[[
	Is welded To
]]

extension:RegisterMethod("e", "isWeldedTo", "", "e", 1, function(e)
	local con = getContraints(e, "Weld", true);
	if (not con) then return Entity(0); end
	return con.entity1;
end, true);

extension:RegisterMethod("e", "isWeldedTo", "n", "e", 1, function(e, i)
	local arr = getContraints(e, "Weld");
	if (#arr < i) then return Entity(0); end
	return arr[i][2].entity1;
end, true);

--[[

]]

extension:RegisterMethod("e", "isConstrainedTo", "", "e", 1, function(e)
	local con = getContraints(e, nil, true);
	if (not con) then return Entity(0); end
	return con.entity1;
end, true);

extension:RegisterMethod("e", "isConstrainedTo", "n", "e", 1, function(e, i)
	local arr = getContraints(e);
	if (#arr < i) then return zero; end
	return arr[i][2];
end, true);

extension:RegisterMethod("e", "isConstrainedTo", "n,s", "e", 1, function(e, i, f)
	local arr = getContraints(e, f);
	if (#arr < i) then return zero; end
	return arr[i][2];
end, true);


--[[
	tables
]]

local function asTable(e, f)
	local t = getContraints(e, f);
	return {tbl = t, children = {}, parents = {}, size = #t};
end

extension:RegisterMethod("e", "getConstraints", "", "t", 1, asTable, true);
extension:RegisterMethod("e", "getConstraintsByType", "s", "t", 1, asTable, true);

--[[
	Children
]]

local function getchildren(e)
	if not IsValid(e) or not e.GetChildren then return {}; end

	local arr = {};

	for _, child in pairs(e:GetChildren() or {}) do
		if IsValid(child) then arr[#arr + 1] = {"e", child}; end
	end

	return arr;
end

extension:RegisterMethod("e", "getChildren", "", "t", 1, function(e, f)
	local t = getchildren(e, f);
	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

--[[
	Lets create constrain core,
	I just ripped this from E2
]]

local Axis = constraint.Axis;
local Ballsocket = constraint.Ballsocket;
local AdvBallsocket = constraint.AdvBallsocket;
local NoCollide = constraint.NoCollide;
local Weld = constraint.Weld;
local NIL = EXPR_LIB._NIL_; --I will regret this one day.

local function addUndo(context, ent, message)
	context.player:AddCleanup( "constraints", prop );
	
	if context.data.constraintUndos then
		undo.Create("e3_"..message);
			undo.AddEntity( prop );
			undo.SetPlayer( context.player );
		undo.Finish();
	end

	return;
end



extension:RegisterMethod("e", "noCollide", "e", "", 0, function(context, ent1, ent2)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, NoCollide(ent1, ent2, 0, 0), "nocollide");
end, true, "Nocollides <ent1> to <ent2>");



extension:RegisterMethod("e", "noCollideAll", "b", "", 0, function(context, ent1, state)
	if not context:CanUseEntity(ent1) then return; end
	
	if state then
		ent1:SetCollisionGroup( COLLISION_GROUP_WORLD );
	else
		ent1:SetCollisionGroup( COLLISION_GROUP_NONE );
	end
end, true, "Nocollides <ent> to entities/players, just like Right Click of No-Collide Stool");



extension:RegisterMethod("e", "weld", "e", "", 0, function(context, ent1, ent2)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, Weld(ent1, ent2, 0, 0), "weld");
end, true, "Welds <ent1> to <ent2>");


extension:RegisterMethod("e", "axis", "v,e,v", "", 0, function(context, ent1, v1, ent2, v2)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, Axis(ent1, ent2, 0, 0, v1, v2, 0, 0, 0, 0), "axis");
end, true, "Creates an axis between <ent1> and <ent2> at vector positions local to each ent.");


extension:RegisterMethod("e", "axis", "v,e,v,n", "", 0, function(context, ent1, v1, ent2, v2, n)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, Axis(ent1, ent2, 0, 0, v1, v2, 0, 0, n, 0), "axis");
end, true, "Creates an axis between <ent1> and <ent2> at vector positions local to each ent, with <friction> friction.");


extension:RegisterMethod("e", "axis", "v,e,v,n,v", "", 0, function(context, ent1, v1, ent2, v2, n, v3)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, Axis(ent1, ent2, 0, 0, v1, v2, 0, 0, n, 0, c3), "axis");
end, true, "Creates an axis between <ent1> and <ent2> at vector positions local to each ent, with <friction> friction and <localaxis> rotation axis.");

extension:RegisterMethod("e", "ballsocket", "e,v", "", 0, function(context, ent1, ent2, v1)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, Ballsocket(ent1, ent2, 0, 0, v1, 0, 0, 0), "ballsocket");
end, true, "Creates a ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>");

extension:RegisterMethod("e", "ballsocket", "e,v,n", "", 0, function(context, ent1, ent2, v1, n)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, AdvBallsocket(ent1, ent2, 0, 0, Vector(), v1, 0, 0, -180, -180, -180, 180, 180, 180, n, n, n, 0, 0), "ballsocket");
end, true, "Creates a ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with friction <friction>");


extension:RegisterMethod("e", "ballsocket", "v,e,v,v,v,n", "", 0, function(context, ent1, v1, ent2, v2, v3, v4, n)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, AdvBallsocket(ent1, ent2, 0, 0, Vector(), v1, 0, 0, v2.x, v2.y, v2.z, v3.x, v3.y, v3.z, v4.x, v4.y, v4.z, n, 0), "ballsocket");
end, true, "Creates an adv ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with many settings");

extension:RegisterMethod("e", "weldAng", "v,e", "", 0, function(context, ent1, v1, ent2)
	if not context:CanUseEntity(ent1) then return; end
	if not context:CanUseEntity(ent2) then return; end
	addundo(context, AdvBallsocket(ent1, ent2, 0, 0, Vector(), vec, 0, 0, 0, -0, 0, 0, 0, 0, 0, 0, 0, 1, 0), "ballsocket");
end, true, "Creates an angular weld (angles are fixed, position isn't) between <ent1> and <ent2> at <v>, which is local to <ent1>");

extension:RegisterMethod("e", "constraintBreak", "", "", 0, function(context, ent1)
	if not context:CanUseEntity(ent1) then return; end
	constraint.RemoveAll(ent1)
end, true, "Breaks every constraint on <ent>");

local function caps(text) -- again this is copied from E2
	local capstext = text:sub(1,1):upper() .. text:sub(2):lower()
	if capstext == "Nocollide" then return "NoCollide" end
	if capstext == "Advballsocket" then return "AdvBallsocket" end
	return capstext
end

extension:RegisterMethod("e", "constraintBreak", "s", "", 0, function(context, ent1)
	if not context:CanUseEntity(ent1) then return; end
	constraint.RemoveConstraints(ent1, caps(type))
end, true, "Breaks all constraints of type <type> on <ent>");

--[[
	End of extention.
]]

extension:EnableExtension();