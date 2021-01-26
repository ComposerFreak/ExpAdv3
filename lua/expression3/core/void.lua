--[[
	*****************************************************************************************************************************************************
		create a new extention
	*****************************************************************************************************************************************************
]]--
	
	local extension = EXPR_LIB.RegisterExtension("void");

--[[
	*****************************************************************************************************************************************************
		Create a void meta object
	*****************************************************************************************************************************************************
]]--
	
	local Throw = function(void, msg, ...)
		local context = rawget(void, "context");

		if context then
			context:Throw("debug-nil:" .. msg, ...);
		else
			error("Debug: E3 Nil, I forgot to do a thing here?");
		end
	end

	local mt = {};

	mt.__index = function(this, key)
		Throw(this, "__index(" .. tostring(key) .. ")");
	end

	mt.__newindex = function(this, key)
		Throw(this, "__newindex(" .. tostring(key) .. ")");
	end

	mt.__mode = function(this)
		Throw(this, "__mode()");
	end

	mt.__call = function(this)
		Throw(this, "__call()");
	end

	mt.__metatable = function(this)
		Throw(this, "__call()");
	end

	mt.__tostring = function(this)
		Throw(this, "__tostring()");
	end

	mt.__len = function(this)
		Throw(this, "__len()");
	end

	mt.__pairs = function(this)
		Throw(this, "__pairs()");
	end

	mt.__ipairs = function(this)
		Throw(this, "__ipairs()");
	end

	mt.__unm = function(this)
		Throw(this, "__unm()");
	end

	mt.__add = function(this)
		Throw(this, "__add()");
	end

	mt.__sub = function(this)
		Throw(this, "__sub()");
	end

	mt.__mul = function(this)
		Throw(this, "__mul()");
	end

	mt.__div = function(this)
		Throw(this, "__div()");
	end

	mt.__idiv = function(this)
		Throw(this, "__idiv()");
	end

	mt.__mod = function(this)
		Throw(this, "__mod()");
	end

	mt.__pow = function(this)
		Throw(this, "__pow()");
	end

	mt.__concat = function(this)
		Throw(this, "__concat()");
	end

	mt.__band = function(this)
		Throw(this, "__band()");
	end

	mt.__bor = function(this )
		Throw(this, "__bor()");
	end

	mt.__bxor = function(this)
		Throw(this, "__bxor()");
	end

	mt.__bnot = function(this)
		Throw(this, "__bnot()");
	end

	mt.__shl = function(this)
		Throw(this, "__shl()");
	end

	mt.__shr = function(this)
		Throw(this, "__shr()");
	end

	mt.__tostring = function(this)
		return "void";
	end

	mt.__type = "void";

	-----------------------------------------------

	local setmetatable = setmetatable;
	
	EXPR_LIB.Void = function(context)
		return setmetatable({
			context = context,
			IsValid = function() return false; end,
		}, mt);
	end;

--[[
	*****************************************************************************************************************************************************
		When a context is created we need to set up void.
	*****************************************************************************************************************************************************
]]--

	hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Void", function(ent, context, env)
		local void = EXPR_LIB.Void(context);
		context.void = void;
		env.void = void;
	end);

--[[
	*****************************************************************************************************************************************************
		register void as a class
	*****************************************************************************************************************************************************
]]--

	local function isnil(obj)
		return obj == nil or getmetatable(obj) == mt;
	end;

	local function notnil(obj)
		return obj ~= nil and getmetatable(obj) ~= mt;
	end

	EXPR_LIB.ISVOID = isnil;
	EXPR_LIB.NOTVOID = notnil;

	local class_nil = extension:RegisterClass("nil", {"void"}, isnil, isnil);

--[[
	*****************************************************************************************************************************************************
		Nil needs to be compared
	*****************************************************************************************************************************************************
]]--

	function extension.PostLoadClasses(this, classes)
		for _, c in pairs(classes) do
			if (c.id ~= "") then
				extension:RegisterOperator("eq", "nil,"..c.id, "b", 1, isnil, true);
				extension:RegisterOperator("neq", "nil,"..c.id, "b", 1, notnil, true);
			end
		end
	end

--[[
	*****************************************************************************************************************************************************
		
	*****************************************************************************************************************************************************
]]--

extension:EnableExtension();
