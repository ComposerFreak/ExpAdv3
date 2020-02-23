/****************************************************************************************************************************
	Create a permissions extention
****************************************************************************************************************************/

local extension = EXPR_LIB.RegisterExtension("permissions");

extension:RegisterPermission("PropControl", "fugue/controller-d-pad.png", "This gate is allowed to alter your props.");

extension:RegisterEvent("PermissionChanged", "p,s,b");

extension:RegisterLibrary("permissions");

extension:RegisterFunction("permissions", "getAll", "", "t", 1, function()
	local t = {};

	for k, _ in pairs( EXPR_LIB.PERMS ) do
		t[#t + 1] = {"s", k};
	end

	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

extension:RegisterFunction("permissions", "check", "e,s", "b", 1, function(ctx, ent, perm)
	if not IsValid(ent) then return false; end
	return ctx.getPerm(ent, perm);
end, false);

extension:RegisterFunction("permissions", "check", "e", "b", 1, function(ctx, ent)
	if not IsValid(ent) then return false; end
	return ctx.ppCheck(ent, perm);
end, false);

extension:RegisterFunction("permissions", "owner", "e", "p", 1, function(ctx, ent)
	if not IsValid(ent) then return nil; end
	return Owner(ent);
end, false);

extension:EnableExtension();