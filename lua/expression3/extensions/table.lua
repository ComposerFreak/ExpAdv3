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
	neweight = neweight + (value == nil and 0 or 1);

	if (value ~= nil) then
		if (type == "_vr") then
			type = value[1];
			value = value[2];
		end

		if (type == "t") then
			neweight = neweight + value.size;
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

--[[
]]


--[[
]]

local extension = EXPR_LIB.RegisterExtension("table");

local class_table = extension:RegisterClass("t", {"table", "array"}, istable, notnil);

--[[
]]

if (SERVER) then
	WireLib.DT.SMART_TABLE = {
		Zero = {tbl = {}, children, parents, size = 0};
	}
end

extension:RegisterWiredInport("t", "SMART_TABLE");
extension:RegisterWiredOutport("t", "SMART_TABLE");

--[[
]]

extension:RegisterConstructor("t", "...", function(...)
	local t = {...};
	return {tbl = t, children, parents, size = #t};
end, true)

extension:RegisterConstructor("t", "", function(...)
	return {tbl = {}, children, parents, size = 0};
end, true)

--[[
]]

extension:RegisterOperator("==", "t,t", "b", 1);

extension:RegisterOperator("!=", "t,t", "b", 1);

--[[

]]

function extension.PostLoadClasses(this, classes)
	for _, c in pairs(classes) do
		local i = c.id;

		if (id ~= "") then
			extension:RegisterOperator("get", "t," .. i, "vr", 1, eTable.get);
			extension:RegisterOperator("get", string.format("t,%s,cls", i), "", 1, eTable.get);
			
			for _, _c in pairs(classes) do
				local v = _c.id;
				extension:RegisterOperator("set", string.format("t,%s,cls,%s", i, v), "", 1, eTable.set);
			end
		end
	end
end

--[[
]]

--[[ext_core:RegisterMethod("t", "insert", "", "s", 1, function(err)
	return err and err.msg or "n/a";
end, true)]]



extension:EnableExtension();

--GetOperator(get(t,n,n))
--GetOperator(get(t,n,_cls))
