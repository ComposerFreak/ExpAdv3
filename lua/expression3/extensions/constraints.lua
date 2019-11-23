local extension = EXPR_LIB.RegisterExtension("constraints");

extension:SetServerState();

local getChildren;

getChildren = function(e, arr, lk, rec)
	arr = arr or {};
	lk = lk or {};

	if IsValid(e) and not lk[e] then
		lk[e] = true;
		arr[#arr + 1] = {"e", e};
		for _, se in pairs(e:GetChildren() or {}) do
			if rec then
				getChildren(se, arr, lk, rec);
			elseif not lk[se] then
				lk[se] = true;
				arr[#arr + 1] = {"e", se};
			end
		end
	end

	return arr;
end

extension:RegisterMethod( "e", "getChildren", "", "t", 1, function(entity)
	local t = getChildren(entity, {}, {}, false);
	PrintTable(t);
	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

extension:RegisterMethod( "e", "getAllChildren", "", "t", 1, function(entity)
	local t = getChildren(entity, {}, {}, true);
	PrintTable(t);
	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

local getConstraints;

getConstraints = function(e, arr, lk, rec)
	arr = arr or {};
	lk = lk or {};

	if IsValid(e) and not lk[e] then
		lk[e] = true;
		arr[#arr + 1] = {"e", e};
		for _, se in pairs(constraint.GetAllConstrainedEntities(e) or {}) do
			if rec then
				getConstraints(se, arr, lk, rec);
			elseif not lk[se] then
				lk[se] = true;
				arr[#arr + 1] = {"e", se};
			end
		end
	end

	return arr;

end

extension:RegisterMethod( "e", "getConstraints", "", "t", 1, function(entity)
	local t = getConstraints(entity, {}, {}, false);
	PrintTable(t);
	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

extension:RegisterMethod( "e", "getAllConstraints", "", "t", 1, function(entity)
	local t = getConstraints(entity, {}, {}, true);
	PrintTable(t);
	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

--[[
	End of extention.
]]

extension:EnableExtension();