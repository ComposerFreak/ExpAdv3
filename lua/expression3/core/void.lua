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
	
	local setmetatable = setmetatable;

	local mtvoid = {};

	EXPR_LIB.Void = function(context)
		return setmetatable({context = context}, mtvoid);
	end;

	mtvoid.__type = "void";
	
	mtvoid.Throw = function(this, msg, ...)
		if (this.context) then this.context:Throw("debug-nil:" .. msg, ...); end
		error("Debug: E3 Nil, I forgot to do a thing here?");
	end

	mtvoid.__index = function(this, key)
		this:Throw("_index(%q)", key);
	end

	mtvoid.__newindex = function(this, key)
		this:Throw("__newindex(%q)", key);
	end

	mtvoid.__mode = function(this)
		this:Throw("__mode()");
	end

	mtvoid.__call = function(this)
		this:Throw("__call()");
	end

	mtvoid.__metatable = function(this)
		this:Throw("__call()");
	end

	mtvoid.__tostring = function(this)
		this:Throw("__tostring()");
	end

	mtvoid.__len = function(this)
		this:Throw("__len()");
	end

	mtvoid.__pairs = function(this)
		this:Throw("__pairs()");
	end

	mtvoid.__ipairs = function(this)
		this:Throw("__ipairs()");
	end

	mtvoid.__unm = function(this)
		this:Throw("__unm()");
	end

	mtvoid.__add = function(this)
		this:Throw("__add()");
	end

	mtvoid.__sub = function(this)
		this:Throw("__sub()");
	end

	mtvoid.__mul = function(this)
		this:Throw("__mul()");
	end

	mtvoid.__div = function(this)
		this:Throw("__div()");
	end

	mtvoid.__idiv = function(this)
		this:Throw("__idiv()");
	end

	mtvoid.__mod = function(this)
		this:Throw("__mod()");
	end

	mtvoid.__pow = function(this)
		this:Throw("__pow()");
	end

	mtvoid.__concat = function(this)
		this:Throw("__concat()");
	end

	mtvoid.__band = function(this)
		this:Throw("__band()");
	end

	mtvoid.__bor = function(this )
		this:Throw("__bor()");
	end

	mtvoid.__bxor = function(this)
		this:Throw("__bxor()");
	end

	mtvoid.__bnot = function(this)
		this:Throw("__bnot()");
	end

	mtvoid.__shl = function(this)
		this:Throw("__shl()");
	end

	mtvoid.__shr = function(this)
		this:Throw("__shr()");
	end

	mtvoid.__tostring = function(this)
		return "void";
	end

	mtvoid.IsValid = function(this)
		return false;
	end

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
		return obj == nil or getmetatable(obj) == mtvoid;
	end;

	local function notnil(obj)
		return obj ~= nil and getmetatable(obj) ~= mtvoid;
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
