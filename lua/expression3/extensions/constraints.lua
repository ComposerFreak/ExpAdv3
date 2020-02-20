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
	entity1 = Entity(-1),
	entity2 = Entity(-1),
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
extension:RegisterAttribute("con", "type", "s");

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
	if (not con) then return Entity(-1); end
	return con.entity1;
end, true);

extension:RegisterMethod("e", "isWeldedTo", "n", "e", 1, function(e, i)
	local arr = getContraints(e, "Weld");
	if (#arr < i) then return Entity(-1); end
	return arr[i][2].entity1;
end, true);

--[[

]]

extension:RegisterMethod("e", "isConstrainedTo", "", "e", 1, function(e)
	local con = getContraints(e, nil, true);
	if (not con) then return Entity(-1); end
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
	End of extention.
]]

extension:EnableExtension();