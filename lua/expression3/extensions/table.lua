--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F
	
	::Table Extension::
		There is no good way to do this.
]]

local eTable = {};
local throwif = EXPR_LIB.ThrowIF;

function eTable.get(ctx, tbl, key, type)
	type = type or "_vr";

	if(not tbl or not tbl.tbl) then
		ctx:Throw("Attempted to index a nil value.")
	end

	local vr = tbl.tbl[key];

	if(not vr) then
		ctx:Throw("Attempted to index field %s a nil value.", tostring(key));
	end

	if (type == "_vr") then
		return vr
	end

	if( vr[1] ~= type ) then
		ctx:Throw( "Attempted to index field %s, %s expected got %s.", tostring(key), type, vr[1]);
	end

	return vr[2];
end

function eTable.set(ctx, tbl, key, type, value)
	type = type or "_vr";

	if(not tbl or not tbl.tbl) then
		ctx:Throw("Attempted to index a nil value.")
	end

	local old = tbl.tbl[key];
	local oldweight = (old == nil and 0 or 1);
	if (old and old[1] == "t" and old[2] ~= nil) then
		oldweight = old.size;
		tbl.children[old[2]] = nil;
		old[2].parents[tbl] = nil;
	end

	local newweight = tbl.size - oldweight;
	newweight = newweight + (value == nil and 0 or 1);

	if (value ~= nil) then
		if (type == "_vr") then
			type = value[1];
			value = value[2];
		end

		if (type == "t") then
			newweight = newweight + value.size;
			tbl.children[value] = value;

			if (value ~= nil) then
				value.parents[tbl] = tbl;
			end
		end
	end

	if (newweight > 512) then
		ctx:Throw("Table size limit reached.");
	end

	if (type == "" or value == nil) then
		tbl.tbl[key] = nil;
	else
		tbl.tbl[key] = {type, value};
	end

	tbl.size = newweight;
	eTable.updateChildren(tbl, oldweight, newweight, {})
end

function eTable.updateChildren(tbl, oldweight, newweight, updated)
	for _, child in pairs(tbl.children) do
		if (not updated[child]) then 
			local weight = child.size;
			child.size = (child.size - oldweight) + newweight;
			eTable.updateChildren(tbl, weight, child.size);
			updated[child] = true;
		end
	end
end

local n = next;
local t = type;
local l = string.lower;

function eTable.itor(tbl) 
	local w = tbl.tbl;
	local a, b = n(tbl.tbl);

	return function()
		if not a then return end
		local tp, key, val = l(t(a))[1], a, b;
		a, b = n(w, a);
		return tp, key, val[1], val[2];
	end
end

--[[
]]


--[[
]]

local extension = EXPR_LIB.RegisterExtenstion("table");

local class_table = extension:RegisterClass("t", {"table", "array"}, istable, notnil);

--[[
]]

if (SERVER) then
	WireLib.DT.SMART_TABLE = {
		Zero = {tbl = {}, children = {}, parents = {}, size = 0};
	}
end

extension:RegisterWiredInport("t", "SMART_TABLE");
extension:RegisterWiredOutport("t", "SMART_TABLE");

--[[
]]

extension:RegisterConstructor("t", "...", function(...)
	local t = {...};
	return {tbl = t, children = {}, parents = {}, size = #t};
end, true)

extension:RegisterConstructor("t", "", function(...)
	return {tbl = {}, children = {}, parents = {}, size = 0};
end, true)

--[[
]]

extension:RegisterOperator("eq", "t,t", "b", 1);

extension:RegisterOperator("neq", "t,t", "b", 1);

extension:RegisterOperator("len", "t", "n", 1, function(tbl)
	return #tbl.tbl;
end, true);

extension:RegisterOperator("itor", "t", "", 0, eTable.itor, true);

--[[
	Methods
]]

extension:RegisterMethod("t", "keys", "", "t", 1, function(tbl)
	local t = {};

	for key, value in pairs(tbl.tbl) do
		if (value and value[2] ~= nil) then
			local typ = l(t(key))

			if (type) then
				t[#t + 1] = {t, key};
			end
		end
	end

	return {tbl = t, children = {}, parents = {}, size = #t};
end, true);

extension:RegisterMethod("t", "values", "", "t", 1, function(ctx, tbl)
	local values = {};

	for key, value in pairs(tbl.tbl) do
		if (value and value[1] ~= "" and value[2] ~= nil) then
			values[value[2]] = value;
		end
	end

	local i = 0;
	local res = {tbl = {}, children = {}, parents = {}, size = #t};

	for _, value in pairs(values) do
		i = i + 1;
		eTable.set(ctx, res, i, value[1], value[2])
	end

	return res;
end, false);

--[[
	Autogen methods and operators (type sepecific)
]]

local VALID_KEYS = {"n", "s", "e", "p", "h"};

for _, k in pairs(VALID_KEYS) do
	if (k ~= "") then
		extension:RegisterOperator("get", "t," .. k, "vr", 1, eTable.get);

		extension:RegisterOperator("get", string.format("t,%s,cls", k), "", 1, eTable.get);

		extension:RegisterMethod("t", "exists", k, "b", 1, function(ctx, tbl, value)
			if (k == "_vr") then
				if (tbl.tbl[value[2]]) then
					return true;
				end
			end

			if (tbl.tbl[value]) then
				return true;
			end

			return false;
		end, false);

		extension:RegisterMethod("t", "type", k, "cls", 1, function(ctx, tbl, key)
			local value = tabl.tbl[key]
			return value and value[1] or "";
		end, false);
	end
end

function extension.PostLoadClasses(this, classes)
	for _, c in pairs(classes) do
		local id = c.id;

		if (id ~= "") then
			extension:RegisterMethod("t", "push", id, "", 0, function(ctx, tbl, value)
				eTable.set(ctx, tbl, #tbl.tbl + 1, id, value);
			end, false);

			extension:RegisterMethod("t", "insert", "n," .. id, "", 0, function(ctx, tbl, key, value)
				table.insert(tbl.tbl, key, nil);
				eTable.set(ctx, tbl, key, id, value);
			end, false);

			extension:RegisterMethod("t", "pop" .. c.name, "", id, 1, function(ctx, tbl)
				local value = tbl.tbl[#tbl.tbl];

				if (not value or (value[1] ~= id and id ~= "_vr")) then
					ctx:Throw(string.format("table.pop%s() got result %s, %s expected.", c.name, value[1], c.name));
				end

				tbl.tbl[#tbl.tbl] = nil;

				return id ~= "_vr" and value[2] or value;
			end, false);

			extension:RegisterMethod("t", "shift" .. c.name, "", id, 1, function(ctx, tbl)
				local value = tbl.tbl[1];

				if (not value or (value[1] ~= id and id ~= "_vr")) then
					ctx:Throw(string.format("table.shift%s() got result %s, %s expected.", c.name, value[1], c.name));
				end

				eTable.set(ctx, tbl, 1, "", nil);

				for i = 1, #tbl.tbl do
					tbl.tbl[i] = tbl.tbl[i + 1];
				end

				tbl.tbl[#tbl.tbl] = nil;
				
				return id ~= "_vr" and value[2] or value;
			end, false);

			extension:RegisterMethod("t", "unshift" .. c.name, id, "", 0, function(ctx, tbl, value)
				table.insert(tbl.tbl, 1, nil);
				eTable.set(ctx, tbl, 1, id, value);
			end, false);

			extension:RegisterMethod("t", "contains", id, "b", 1, function(ctx, tbl, value)
				if (id == "_vr") then
					for k, v in pairs(tbl.tbl) do
						if (v and k == value[2]) then
							return true;
						end
					end
				end

				for k, v in pairs(tbl.tbl) do
					if (v and v[1] == id and v[2] == value) then
						return true;
					end
				end

				return false;
			end, false);

			for _, k in pairs(VALID_KEYS) do
				if (k ~= "") then
					extension:RegisterOperator("set", string.format("t,%s,cls,%s", k, id), "", 1, eTable.set);
				end
			end
		end
	end
end

--[[
]]

extension:EnableExtenstion();

