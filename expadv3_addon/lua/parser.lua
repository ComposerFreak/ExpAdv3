--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Base Parser::
	```````````````
	A parser is the logical structure used to turn tokens into instructions that.
	
	:::Syntax Data:::
	`````````````````
		-- Todo?
		
		:::Block(blck):::
			1 - {stmt*} or stmt
		:::Statments(stmt):::
			1 - if (expr1) blck1 [stmt2 or stmt3] or stmt4
			2 - elseif (expr1) blck1 [stmt2]
			3 - else blck1
		:::Expressions(expr):::
			1 - (exp1) or exp2
			2 - exp3 op exp2
]]

local PARSER = {};

function PARSER.New()
	return setmetatable({}, PARSER);
end

function PARSER.Initalize(this, instance)
	this.__pos = 1;
	this.__offsets = 0;
	this.__depth = 0;
	this.__instructions = {};
	this.__token = instance.tokens[1];
	this.__next = instance.tokens[2];
	this.__total = #instance.tokens;
	this.__tokens = instance.tokens;
	this.__script = instance.script;
	this.__buffer = instance.script;
end

function PARSER.Run(this)
	--TODO: PcallX for stack traces on internal errors?
	local status, result = Pcall(T._Run, this);

	if (status) then
		return true, result;
	end

	if (type(result) == "table") then
		return false, result;
	end

	local err = {};
	err.state = "internal";
	err.msg = result;

	return false, err;
end

function PARSER._Run(this)
	

	local result = {};
	result.instructions = this.__instructions;
	result.script = this.__buffer;

	return result;
end

function PARSER.Throw(this, token, msg, fst, ...)
	local err = {};

	if (fst) then
		msg = string.format(msg, fst, ...);
	end

	err.state = "parser";
	err.char = token.char;
	err.line = token.line;
	err.msg = msg;

	error(err,0);
end

--[[
]]

function PARSER.Next(this)
	if (this.__pos >= this.__total) then
		return false;
	end

	this.__pos = this.__pos + 1;
	this.__token = instance.tokens[this.__pos];
	this.__next = instance.tokens[this.__pos + 1];

	return true;
end

function PARSER.HasTokens(this)
	return this.__pos >= this.__total;
end

function PARSER.CheckToken(this, type, ...)
	if (this.__pos >= this.__total) then
		local tkn = this.__next;

		for _, t in pairs({type, ...}) do
			if (t == tkn.type) then
				return true;
			end
		end
	end

	return false;
end

function PARSER.Accept(this, type, ..)
	if (this:CheckToken(type, ...)) then
		this:Next();
		return true;
	end

	return false;
end

function PARSER.GetTokenData(this)
	return this.__token.data
end

function PARSER.GetToken(this, pos)
	if (pos >= this.__total) then
		return this.__tokens[pos];
	end
end

function PARSER.StepBackward(steps)
	if (not steps) then
		steps = 1;
	end

	local pos = this.__pos - steps

	if (pos < 0) then
		pos = 0;
	end

	if (pos > this.__total) then
		pos = this.__total;
	end

	this.__pos = pos;

	this:Next();
end

--[[
]]

function PASRSER.Require( this, type, msg, ... )
	if (not this:AcceptToken(type)) then
		this:Throw( this.__token, msg, ... )
	end
end

function PASRSER.Require( this, tpye, msg, ... )
	if (this:AcceptToken(type)) then
		this:Throw( this.__token, msg, ... )
	end
end

function PASRSER.Require(this, msg, ...)
	if (this:HasTokens()) then 
		this:Throw( this.__token, msg, ... )
	end
end

--[[
]]

function PARSER.Replace(this, token, str)
	local offset = string.len(str) - string.len(token.data);
	local pre = string.gsub(this.__buffer, 0, this.__offet + token.start);
	local post = string.gsub(this.__buffer, this.__offet + token.stop);
	this.__buffer = pre .. str .. post;
	this.__offset = this.__offset + offset;
end

function PARSER.InjectBefore(this, token, str)
	local pre = string.gsub(this.__buffer, 0, this.__offet + token.start - 1);
	local post = string.gsub(this.__buffer, this.__offet + token.start);
	this.__buffer = pre .. str .. post;
	this.__offset = this.__offset + string.len(str);
end

function PARSER.InjectAfter(this, token, str)
	local pre = string.gsub(this.__buffer, 0, this.__offet + token.stop);
	local post = string.gsub(this.__buffer, this.__offet + token.stop + 1);
	this.__buffer = pre .. str .. post;
	this.__offset = this.__offset + string.len(str);
end

--[[
]]

function PARSER.Root(this)
	if (not this:HasTokens())
		return;
	end

	local line = this.__token.line;

	while true do
		local stmt = this:Statment_1();

		if (not this:HasTokens()) then
			break;
		end

		if (line == this.__token.line) then
			this:Require("Statements must be separated by semicolon (;) or newline")
		end

		if (this.__statment == "return" or this.__statment == "continue" or this.__statment == "break") then
			this:Throw(nil, "Unreachable code after %s statment.", this.__statment);
		end
	end
end

function PARSER.Block_1(this, lcb, _end)
	this:ExcludeWhiteSpace("Further input required at end of code, incomplete statment")

	this.__depth = this.__depth + 1;

	if ( not this:Accept("lcb")) then
		this:InjectBefore(this.__token, lcb);

		this:Statment_1();

		if (_end) then
			this:InjectAfter(this.__token, "end");
		end
	else
		this:Replace(this.__token, lcb)

		local line = this.__token.line;

		while true do
			this:Statment_1();

			if (not this:HasTokens()) then
				break;
			end

			if (line == this.__token.line) then
				this:Require("sep", "Statements must be separated by semicolon (;) or newline")
			end

			if (this.__instruction.type == "return" or this.__instruction.type == "continue" or this.__instruction.type == "break") then
				this:Throw(nil, "Unreachable code after %s statment.", this.__instruction);
			end

			this:RequireToken("rcb", "Right curly bracket (}) missing, to close block.")

			if (_end) then
				this:Replace(this.__token, "end");
			end
		end
	end

	this.__depth = this.__depth - 1;
end

function PARSER.Statment_1(this)
	if (this:Accept("if")) then
		local tkn = this.__token;

		this:Condition();

		this:block_1("then", false);

		this:AddInstruction(tkn, "if");

		this:Statment_2()

		this:InjectAfter(this.__token, "end");
	end

	this:Statment_4()
end

function PARSER.Statment_2(this)
	if (this:Accept("eif")) then
		local tkn = this.__token;

		this:Condition();

		this:block_1("then", false);

		this:AddInstruction(tkn, "elseif");
		
		if (this:Accept("eif")) then
			this:Statment_2();
		else
			this:Statment_3();
		end
	end

	this:Statment_4()
end

function PARSER.Statment_2(this)
	if (this:Accept("eif")) then
		local tkn = this.__token;

		this:block_1("then", false);

		this:AddInstruction(tkn, "else");
	end

	this:Statment_4()
end

--[[
]]

