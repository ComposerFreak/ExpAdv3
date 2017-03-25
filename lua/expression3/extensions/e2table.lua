--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F
	
	E2 Table Extension
	By Divran
]]

local eTable = {};
local throwif = EXPR_LIB.ThrowIF;

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0}

local convert_values_to_e2 = {
	v = function(v) return {v.x,v.y,v.z}, "v" end,
	a = function(a) return {a.p,a.y,a.r}, "a" end,
	v2 = function(v) return {v.x,v.y}, "xv2" end,
	s = function(s) return s, "s" end,
	n = function(n) return n, "n" end,
	e = function(e) return e, "e" end,
	p = function(p) return p, "e" end,
	c = function(c) return {c.r,c.g,c.b,c.a}, "xv4" end,
	e2t = function(t) return t, "t" end,
}

local convert_values_from_e2 = {
	xv4 = function(v) return Color(v[1],v[2],v[3],v[4]), "c" end,
	v = function(v) return Vector(v[1],v[2],v[3]), "v" end,
	a = function(a) return Angle(a[1],a[2],a[3]), "a" end,
	xv2 = function(v) return {x=v[1],y=v[2]}, "v2" end,
	s = function(s) return s, "s" end,
	n = function(n) return n, "n" end,
	e = function(e)
		local tp = type(e)
		if type(e) == "Player" then
			return e, "p"
		else
			return e, "e"
		end
	end,
	t = function(t) return t, "e2t" end
}

function eTable.get(ctx, tbl, key, tp)
	if not tbl then
		ctx:Throw("Attempted to index a nil value.")
	end

	tp = tp or "_vr";

	local tbl_val, tbl_tp

	if isnumber(key) then
		tbl_val = tbl.n
		tbl_tp = tbl.ntypes
	elseif isstring(key) then
		tbl_val = tbl.s
		tbl_tp = tbl.stypes
	else
		ctx:Throw( "Attempt to use a non-number/string key in E2 table." )
	end

	if not tbl_val then
		ctx:Throw("Attempted to index a nil value.")
	end

	if not tbl_val[key] then
		ctx:Throw( "Attempt to index field %s a nil value.", tostring(key) )
	end

	local valtp = tbl_tp[key]

	if not convert_values_from_e2[valtp] then
		ctx:Throw( "The value stored at index %s (of type '%s') cannot be converted.", tostring(key), valtp )
	end

	local val, new_valtp = convert_values_from_e2[valtp]( tbl_val[key] )

	if tp == "_vr" then
		return {new_valtp, val}
	end

	if new_valtp ~= tp then
		ctx:Throw( "Attempted to index field %s, %s expected got %s.", tostring(key), tp, new_valtp )
	end

	return val
end

function eTable.set(ctx, tbl, key, tp, value)
	tp = tp or "_vr";

	if not tbl then
		ctx:Throw("Attempted to index a nil value.")
	end

	local tbl_val, tbl_tp

	if isnumber(key) then
		tbl_val = tbl.n
		tbl_tp = tbl.ntypes
	elseif isstring(key) then
		tbl_val = tbl.s
		tbl_tp = tbl.stypes
	else
		ctx:Throw( "Attempt to use a non-number/string key in E2 table." )
	end

	if tp == "_vr" then
		tp = value[1]
		value = value[2]
	end

	if not convert_values_to_e2[tp] then
		ctx:Throw( "The specified value (of type '%s') cannot be converted.", tp )
	end

	if tbl_val[key] ~= nil and value == nil then
		tbl.size = tbl.size - 1
	elseif tbl_val[key] == nil and value ~= nil then
		tbl.size = tbl.size + 1
	elseif value == nil then
		return
	end
	
	local val, new_valtp = convert_values_to_e2[tp]( value )

	tbl_val[key] = val
	tbl_tp[key] = new_valtp
end


--[[
]]

local extension = EXPR_LIB.RegisterExtenstion("e2table");

local class_table = extension:RegisterClass("e2t", "e2.table", istable, notnil);

--[[
]]

extension:RegisterWiredInport("e2t", "TABLE");
extension:RegisterWiredOutport("e2t", "TABLE");

--[[
]]

extension:RegisterConstructor("e2t", "...", function(ctx,...)
	local t = table.Copy(DEFAULT)
	local n = 0
	for k,v in pairs( {...} ) do
		n = n + 1
		eTable.set( ctx, t, n, "_vr", v )
	end
	return t
end, false)

extension:RegisterConstructor("e2t", "", function(...)
	return table.Copy(DEFAULT)
end, true)

--[[
]]

extension:RegisterOperator("eq", "e2t,e2t", "b", 1);

extension:RegisterOperator("neq", "e2t,e2t", "b", 1);

extension:RegisterOperator("len", "e2t", "n", 1, function(tbl)
	return #tbl.n;
end, true);

--[[
	Methods
]]

extension:RegisterMethod("e2t", "keys", "", "t", 1, function(tbl)
	local t = {};

	for key, value in pairs(tbl.n) do
		if (value and value[2] ~= nil) then
			local typ;

			if (isnumber(key)) then
				typ = "n";
			elseif (isstring(key)) then
				typ = "s";
			end

			if (type) then
				t[#t + 1] = {t, key};
			end
		end
	end

	for key, value in pairs(tbl.s) do
		if (value and value[2] ~= nil) then
			local typ;

			if (isnumber(key)) then
				typ = "n";
			elseif (isstring(key)) then
				typ = "s";
			end

			if (type) then
				t[#t + 1] = {t, key};
			end
		end
	end

	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

--[[
Can't make this function because I don't have access to e3 table's eTable.set function

extension:RegisterMethod("e2t", "values", "", "t", 1, function(ctx, tbl)
	local values = {};

	for key, value in pairs(tbl.n) do
		if value ~= nil then
			values[value[2] ] = eTable.get(ctx,tbl,key)
		end
	end
	for key, value in pairs(tbl.s) do
		if value ~= nil then
			values[value[2] ] = eTable.get(ctx,tbl,key)
		end
	end

	local i = 0;
	local res = {tbl = {}, children = {}, parents = {}, size = #t};

	for _, value in pairs(values) do
		i = i + 1;
		eTable.set(ctx, res, i, value[1], value[2]) <- PROBLEM HERE
	end

	return res;
end, false);
]]

--[[
	Autogen methods and operators (type sepecific)
]]

local VALID_KEYS = {"n", "s"};

for _, k in pairs(VALID_KEYS) do
	if (k ~= "") then			
		extension:RegisterMethod("e2t", "exists", k, "b", 1, function(ctx, tbl, value)
			if isnumber(value) then
				return tbl.n[value] ~= nil
			elseif isstring(value) then
				return tbl.s[value] ~= nil
			end

			return false
		end, false);

		extension:RegisterMethod("e2t", "type", k, "cls", 1, function(ctx, tbl, key)
			local converted_variant = eTable.get( ctx, tbl, key, "_vr" )

			return converted_variant[1] or ""
		end, false);
	end
end

function extension.PostLoadClasses(this, classes)
	for _, c in pairs(classes) do
		local id = c.id;

		if convert_values_to_e2[id] then -- only add methods for supported types

			extension:RegisterOperator("get", "e2t," .. id, "vr", 1, eTable.get);

			extension:RegisterOperator("get", string.format("e2t,%s,cls", id), "", 1, eTable.get);
			
			extension:RegisterMethod("e2t", "push", id, "", 0, function(ctx, tbl, value)
				eTable.set(ctx, tbl, #tbl.n + 1, id, value);
			end, false);

			extension:RegisterMethod("e2t", "insert", "n,"..id, "", 0, function(ctx, tbl, key, value)
				table.insert(tbl.n, key, nil);
				eTable.set(ctx, tbl, key, id, value);
			end, false);

			extension:RegisterMethod("e2t", "pop" .. c.name, "", id, 1, function(ctx, tbl)
				local value = eTable.get( ctx, tbl, #tbl.n, id )

				if (not value or (value[1] ~= id and id ~= "_vr")) then
					ctx:Throw(string.format("table.pop%s() got result %s, %s expected.", c.name, value[1], c.name));
				end

				tbl.n[#tbl.n] = nil;

				return id ~= "_vr" and value[2] or value;
			end, false);

			extension:RegisterMethod("e2t", "shift" .. c.name, "", id, 1, function(ctx, tbl)
				local value = eTable.get( ctx, tbl, 1, id )

				if (not value or (value[1] ~= id and id ~= "_vr")) then
					ctx:Throw(string.format("table.shift%s() got result %s, %s expected.", c.name, value[1], c.name));
				end

				table.remove( tbl.n, 1 )
				
				return id ~= "_vr" and value[2] or value;
			end, false);

			extension:RegisterMethod("e2t", "unshift" .. c.name, id, "", 0, function(ctx, tbl, value)
				table.insert(tbl.n, 1, nil);
				eTable.set(ctx, tbl, 1, id, value);
			end, false);

			-- this is where e2t:contains(v) would've been. However, I believe it would be far too expensive
			-- to make this function, since you would need to convert every single value before comparing

			for _, k in pairs(VALID_KEYS) do
				if (k ~= "") then
					extension:RegisterOperator("set", string.format("e2t,%s,cls,%s", id, k), "", 1, eTable.set);
				end
			end
		end
	end
end

--[[
]]

extension:EnableExtenstion();

