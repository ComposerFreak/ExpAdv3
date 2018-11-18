--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Entity Finding Extension::

	A rip of E2's but with a twist :D
]]

EXPR_LIB.EntityBL = {
	["info_player_allies"] = true,
	["info_player_axis"] = true,
	["info_player_combine"] = true,
	["info_player_counterterrorist"] = true,
	["info_player_deathmatch"] = true,
	["info_player_logo"] = true,
	["info_player_rebel"] = true,
	["info_player_start"] = true,
	["info_player_terrorist"] = true,
	["info_player_blu"] = true,
	["info_player_red"] = true,
	["prop_dynamic"] = true,
	["physgun_beam"] = true,
	["player_manager"] = true,
	["predicted_viewmodel"] = true,
	["gmod_ghost"] = true,
};

hook.Call("Expression3.Extension.EntityBlackList", EXPR_LIB.EntityBL);

--[[

]]


local function filter(a, ff)

	local r = {};

	for i = 1, #ff do

		local e = ff[i];

		if a.wl and not a.wl[e] then continue; end

		if a.bl and a.bl[e] then continue; end;

		if IsValid(e) then

			local c = e:GetClass();

			if EXPR_LIB.EntityBL[c] then continue; end

			if a.ec and a.ec[c] then continue; end

			if a.ic and not a.ic[c] then continue; end

			local m = e:GetModel();

			if a.em and a.em[m] then continue; end

			if a.im and not a.im[m] then continue; end

			if a.ep or a.ip then

				local o = e:getOWner();

				if IsValid(o) then

					if a.ep and a.ep[o] then continue; end

					if a.ip and not a.ip[o] then continue; end

				end

			end
		end

		r[#r + 1] = e;

	end

	a.a = r;

end

--[[
	Extention and class.
]]

local extension = EXPR_LIB.RegisterExtension("find");

extension:RegisterLibrary("entlib");

extension:RegisterClass("ed", "find", istable, function(v) return v ~= nil; end);

extension:SetSharedState();

extension:RegisterConstructor("ed", "", function() return {a = {}}; end, true);

extension:RegisterMethod("ed", "clearWhiteList", "", "", 0, function(a)

	a.bl = nil;

	a.wl = nil;

end, true);

extension:RegisterMethod("ed", "removeFromWhiteList", "e", "", 0, function(a, e)

	a.bl = nil;

	a.wl = a.wl or { };

	a.wl[e] = nil;

end, true);

extension:RegisterMethod("ed", "addWhiteList", "e", "", 0, function(a, e)

	a.bl = nil;

	a.wl = a.wl or { };

	a.wl[e] = true;

end, true);

extension:RegisterMethod("ed", "addWhiteList", "t", "", 0, function(a, f)

	a.bl = nil;

	a.wl = a.wl or { };

	for i = 1, #f.tbl do
		local v = f.tbl[i];

		if IsEntity(v) then
			a.wl[v] = true;
		end
	end

end, true);

extension:RegisterMethod("ed", "clearBlackList", "", "", 0, function(a)

	a.wl = nil;

	a.bl = nil;

end, true);

extension:RegisterMethod("ed", "removeFromBlackList", "e", "", 0, function(a, e)

	a.wl = nil;

	a.bl = a.bl or { };

	a.bl[e] = nil;

end, true);

extension:RegisterMethod("ed", "addBlackList", "e", "", 0, function(a, e)

	a.wl = nil;

	a.bl = a.bl or { };

	a.bl[e] = true;

end, true);

extension:RegisterMethod("ed", "addBlackList", "t", "", 0, function(a, f)

	a.wl = nil;

	a.bl = a.bl or { };

	for i = 1, #f.tbl do
		local v = f.tbl[i];

		if IsEntity(v) then
			a.bl[v] = true;
		end
	end

end, true);

--[[
	Generic Filters
]]

extension:RegisterMethod("ed", "excludeClass", "s", "", 0, function(a, c)

	a.ic = nil;

	a.ec = a.ec or { };

	a.ec[c] = true;

end, true);

extension:RegisterMethod("ed", "includeClass", "s", "", 0, function(a, c)

	a.ec = nil;

	a.ic = a.ic or { };

	a.ic[c] = true;

end, true);

extension:RegisterMethod("ed", "clearClassFilters", "", "", 0, function(a)
	a.ec = nil;
	a.ic = nil;
end, true);

extension:RegisterMethod("ed", "excludeModel", "s", "", 0, function(a, m)

	a.im = nil;

	a.em = a.em or { };

	a.em[m] = true;

end, true);

extension:RegisterMethod("ed", "includeModel", "s", "", 0, function(a, m)

	a.em = nil;

	a.im = a.im or { };

	a.im[m] = true;

end, true);

extension:RegisterMethod("ed", "clearModelFilters", "", "", 0, function(a)
	a.em = nil;
	a.im = nil;
end, true);

--[[
	Player Filters
]]

extension:RegisterMethod("ed", "excludePlayerPpops", "p", "", 0, function(a, p)

	a.ip = nil;

	a.ep = a.ep or { };

	a.ep[p] = true;

end, true);

extension:RegisterMethod("ed", "includePlayerPpops", "p", "", 0, function(a, p)

	a.ep = nil;

	a.ip = a.ip or { };

	a.ip[p] = true;

end, true);

extension:RegisterMethod("ed", "clearPlayerFilters", "", "", 0, function(a)
	a.ep = nil;
	a.ip = nil;
end, true);

--[[
	Apply filters
]]

extension:RegisterMethod("ed", "clearFilters", "", "", 0, function(a)
	a.wl = nil;
	a.bl = nil;

	a.ec = nil;
	a.ic = nil;

	a.em = nil;
	a.im = nil;

	a.ep = nil;
	a.ip = nil;
end, false);

extension:RegisterMethod("ed", "copyFilters", "ed", "", 0, function(a, b)
	b.wl = table.Copy(a.wl);
	b.bl = table.Copy(a.bl);

	b.ec = table.Copy(a.ec);
	b.ic = table.Copy(a.ic);

	b.em = table.Copy(a.em);
	b.im = table.Copy(a.im);

	b.ep = table.Copy(a.ep);
	b.ip = table.Copy(a.ip);
end, false);

--[[
	Advanced find functions.
]]

extension:RegisterMethod("ed", "sortByDistance", "v", "", 0, function(a, v)

	local d = { };

	table.sort(a.a, function(a, b)
		local d1 = d[a];

		if not d1 then
			d1 = IsValid(a) and (v - a:GetPos()):LengthSqr() or math.huge;
			d[a] = d1;
		end

		if not d2 then
			d2 = IsValid(b) and (v - b:GetPos()):LengthSqr() or math.huge;
			d[b] = d2;
		end

		return d1 < d2;
	end)

	d = nil;

end, true);

--[[
	Clipping
]]

extension:RegisterMethod("ed", "clipToSphere", "v,n", "", 0, function(a, v, r)

	local t = { };

	for i = 1, #a.a do
		local e = a.a[i];

		if IsValid(e) and v:Distance( e:GetPos() ) <= r then
			t[#t + 1] = e;
		end

	end

	a.a = t;

end, true);

extension:RegisterMethod("ed", "clipFromSphere", "v,n", "", 0, function(a, v, r)

	local t = { };

	for i = 1, #a.a do
		local e = a.a[i];

		if IsValid(e) and v:Distance( e:GetPos() ) > r then
			t[#t + 1] = e;
		end

	end

	a.a = t;

end, true);

extension:RegisterMethod("ed", "clipToBox", "v,v", "", 0, function(a, mn, mx)

	local t = { };

	for i = 1, #a.a do
		local e = a.a[i];

		if IsValid(e) then
			local p = e:GetPos();

			if p.x <= mn.x then continue; end
			if p.y <= mn.y then continue; end
			if p.z <= mn.z then continue; end

			if p.x >= mx.x then continue; end
			if p.y >= mx.y then continue; end
			if p.z >= mx.z then continue; end

			t[#t + 1] = e;
		end

	end

	a.a = t;

end, true);

extension:RegisterMethod("ed", "clipFromBox", "v,v", "", 0, function(a, mn, mx)

	local t = { };

	for i = 1, #a.a do
		local e = a.a[i];

		if IsValid(e) then
			local p = e:GetPos();

			if p.x > mn.x then continue; end
			if p.y > mn.y then continue; end
			if p.z > mn.z then continue; end

			if p.x < mx.x then continue; end
			if p.y < mx.y then continue; end
			if p.z < mx.z then continue; end

			t[#t + 1] = e;
		end

	end

	a.a = t;

end, true);

extension:RegisterMethod("ed", "clipFromRegion", "v,v", "", 0, function(a, o, p)

	local d = p:Dot(o);

	local t = { };

	for i = 1, #a.a do
		local e = a.a[i];

		if IsValid(e) then

			if d <= p:Dot(e:GetPos()) then continue; end

			t[#t + 1] = e;
		end

	end

	a.a = t;

end, true);

--[[
	Search functions.
]]

extension:RegisterMethod("ed", "findByClass", "s", "n", 1, function(a, c)
	filter(a, ents.FindByClass(c));
	return #a.a;
end, true);

extension:RegisterMethod("ed", "findByModel", "s", "n", 1, function(a, m)
	filter(a, ents.FindByModel(m));
	return #a.a;
end, true);

extension:RegisterMethod("ed", "findInBox", "v,v", "n", 1, function(a, mn, mx)
	filter(a, ents.FindByModel(mn, mx));
	return #a.a;
end, true);

extension:RegisterMethod("ed", "findInCone", "v,v,n,a", "n", 1, function(a, v1, v2, n, g)
	filter(a, ents.FindInCone(v1, v2, n, g));
	return #a.a;
end, true);

extension:RegisterMethod("ed", "finInPVS", "v", "n", 1, function(a, v)
	filter(a, ents.FindInPVS(v));
	return #a.a;
end, true);

extension:RegisterMethod("ed", "finInPVS", "e", "n", 1, function(a, e)
	filter(a, ents.FindInPVS(e));
	return #a.a;
end, true);

extension:RegisterMethod("ed", "findInSphere", "v,n", "n", 1, function(a, v, n)
	filter(a, ents.FindInSphere(v, n));
	return #a.a;
end, true);

--[[
	Results
]]

extension:RegisterMethod("ed", "results", "", "n", 1, function(a)
	return #a.a;
end, true);

extension:RegisterMethod("ed", "first", "", "e", 1, function(a)
	return a[1].a;
end, true);

extension:RegisterMethod("ed", "toArray", "", "t", 1, function(a)
	local t = {};

	for k, v in pairs( a.a ) do
		t[k] = {"e", v};
	end

	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

--[[

]]

extension:EnableExtension()
