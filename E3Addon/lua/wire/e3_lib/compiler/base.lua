--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 
]]--

--[[
	Section: Keywords.
	Description: All keywords associated with E3.
]]

EXPR3_KEYWORDS = {
		["if"] = {"if", "if"},
		["elseif"] = {"eif", "elseif"},
		["else"] = {"els", "else"},
		["while"] = {"whl", "while"},
		["for"] = {"for", "for"},
		["foreach"] = {"each", "foreach"},
		["delegate"] = {"del", "delegate"},
		["true"] = {"tre", "true"},
		["false"] = {"fls", "false"},
		["void"] = {"void", "void"},
		["break"] = {"brk", "break"},
		["continue"] = {"cnt", "continue"},
		["return"] = {"ret", "return"},
		["global"] = {"glo", "global"},
		["server"] = {"sv", "server"},
		["client"] = {"cl", "client"},
		["new"] = {"new", "constructor"},
		["try"] = {"try", "try"},
		["catch"] = {"cth", "catch"},
		["class"] = {"cls", "class"},
		["method"] = {"meth", "method"},
}

--[[
	Section: Tokens.
	Description: All the token types used by E3.
]]

EXPR3_TOKENS = {
	{ "+", "add", "addition" },
	{ "-", "sub", "subtract" },
	{ "*", "mul", "multiplier" },
	{ "/", "div", "division" },
	{ "%", "mod", "modulus" },
	{ "^", "exp", "power" },
	{ "=", "ass", "assign" },
	{ "+=", "aadd", "increase" },
	{ "-=", "asub", "decrease" },
	{ "*=", "amul", "multiplier" },
	{ "/=", "adiv", "division" },
	{ "++", "inc", "increment" },
	{ "--", "dec", "decrement" },
	{ "==", "eq", "equal" },
	{ "!=", "neq", "unequal" },
	{ "<", "lth", "less" },
	{ "<=", "leq", "less or equal" },
	{ ">", "gth", "greater" },
	{ ">=", "geq", "greater or equal" },
	{ "&", "band", "and" },
	{ "|", "bor", "or" },
	{ "^^", "bxor", "or" },
	{ ">>", "bshr", ">>" },
	{ "<<", "bshl", "<<" },
	{ "!", "not", "not" },
	{ "&&", "and", "and" },
	{ "||", "or", "or" },
	{ "?", "qsm", "?" },
	{ ":", "col", "colon" },
	{ ";", "sep", "semicolon" },
	{ ",", "com", "comma" },
	{ "$", "dlt", "delta" },
	{ "#", "len", "length" },
	{ "~", "cng", "changed" },
	{ ".", "prd", "period" },
	{ "(", "lpa", "left parenthesis" },
	{ ")", "rpa", "right parenthesis" },
	{ "{", "lcb", "left curly bracket" },
	{ "}", "rcb", "right curly bracket" },
	{ "[", "lsb", "left square bracket" },
	{ "]", "rsb", "right square bracket" },
	{ '@', "dir", "directive operator" },
	{ "...", "varg", "varargs" },
}

table.sort( EXPR3_TOKENS, function( token1, token2 )
	return #token1[1] > #token2[1];
end )

--[[
	Section: Task Sceduler.
	Description: A base object for the tokenizer, parser and compiler.
]]

local Sceduler = { }; Sceduler.__index = Sceduler;

function Sceduler:New( )
	local new = setmetatable({}, Sceduler);

	new.remove = { };
	new.replace = { };
	new.prefix = { };
	new.postfix = { };
	new.prefixLine = { };
	new.posfixLine = { };

	return new;
end

function Sceduler:InjectLineBefore( instruction, token, str, b, ...)
	if b ~= nil then str = string.format( str, b, ...) end;
	new.prefixLine[#prtoken.index] = {instruction = instruction; token = token; string = str};
end

function Sceduler:InjectLineAfter( instruction, token, str, b, ...)
	if b ~= nil then str = string.format( str, b, ...) end;
	new.posfixLine[#potoken.index] = {instruction = instruction; token = token; string = str};
end

function Sceduler:InjectPrefix( instruction, token, str, b, ...)
	if b ~= nil then str = string.format( str, b, ...) end;
	new.prefixtoken.index] = {instruction = instruction; token = token; string = str};
end

function Sceduler:InjectPostfix( instruction, token, str, b, ...)
	if b ~= nil then str = string.format( str, b, ...) end;
	new.postfix[token.index] = {instruction = instruction; token = token; string = str};
end

function Sceduler:ReplaceToken( instruction, token, str)
	new.replace[token.index] = {instruction = instruction; token = token; string = str};
end

function Sceduler:RemoveToken( instruction, token)
	new.remove[token.index] = {instruction = instruction; token = token};
end


--[[
	Section: Base stage.
	Description: A base object for the tokenizer, parser and compiler.
]]

local BaseStage = { name = "base" }; BaseStage.__index = BaseStage;

-- Method:	BaseStage.new();
-- Description: Returns a new instance of the base stage.

function BaseStage:New( )
	return setmetatable( { }, self );
end

-- Method:	BaseStage.Initalize();
-- Description: Sets up the scoping data for the instance.

function BaseStage:Initalize( instance )
	self.__pos = 0;
	self.__depth = 0;
	self.__scopeID = 0;
	self.__scope = {};
	self.__scopeData = self.__scope;

	self:Init( instance );
end

-- Method:	BaseStage.Init();
-- Description: A place holder function.

function BaseStage:Init( )
end

-- Method:	BaseStage.PushScope();
-- Description: Pushes the stack up by 1 level.

function BaseStage:PushScope ()
	self.__scope = { };
	self.__scope.classes = { };
	self.__scopeID = self.__scopeID + 1;
	self.__scopeData[self.__scopeID] = self.__scope;
end

-- Method:	BaseStage.PopScope();
-- Description: Pushes the stack down by 1 level.

function BaseStage:PopScope( )
	self.__scopeData[self.__scopeID] = nil;
	self.__scopeID = self.__scopeID - 1;
	self.__scope = self.__scopeData[self.__scopeID];
end

-- Method:	BaseStage.SetData(string, object, boolean);
-- Description: Sets data inside the scope.

function BaseStage:SetData( option, value, deep )
	if not deep then
		self.__scope[option] = value;
	else
		for i = self.__scopeID, 0, -1 do
			local v = self.__scopeData[i][option];

			if (v) then
				self.__scopeData[i][option] = value;
				break;
			end
		end
	end
end

-- Method:	BaseStage.GetData(string, boolean);
-- Description: gets the first isntance of data in the scope or upward.

function BaseStage:GetData( option, nonDeep )
	if self.__scope[option] then
		return self.__scope[option];
	end

	if not nonDeep then
		for i = self.__scopeID, 0, -1 do
			local v = self.__scopeData[i][option];

			if v then
				return v;
			end
		end
	end
end

-- Method:	BaseStage.Run();
-- Description: Will run the instances Execute function.

function BaseStage:Run( )
	local cb = function( msg )

	end

	local status, result = xpcall( self.Execute, cb, self );

	if status then
		return true, result;
	end

	if type( result ) == "table" then
		return false, result;
	end

	local err = { };
	err.state = "internal";
	err.msg = result;

	return false, err;
end

-- Method:	BaseStage.Execute();
-- Description: Place holder function.

function BaseStage:Execute()
end

-- Method:	BaseStage.Throw(token, string, ...);
-- Description: Throws an error from the stage with a built in string.format.

function BaseStage:Throw( token, msg, fst, ...)
	local err = {};

	if (fst) then
		msg = string.format( msg, fst, ...);
	end

	err.state = "parser";
	err.char = token.char;
	err.line = token.line;
	err.msg = msg;

	error( err, 0 );
end

--[[
	Section: Tokenizer.
	Description: Chews a string up into tokens.
]]

local Tokenizer = {name = "tokenizer"}; Tokenizer.__index = Tokenizer; setmetatable( Tokenizer, BaseStage );

-- Method:	Tokenizer.Init();
-- Description: Initalized the tokenizer instance.
function Tokenizer:Init( )
	self.__pos = 0;
	self.__offset = 0;
	self.__depth = 0;

	self.__char = "";
	self.__data = "";
	self.__dataStart = 1;
	self.__dataEnd = 1;

	self.__tokenPos = 0;
	self.__tokenLine = 0;
	self.__tokenChar = 0;

	self.__readChar = 1;
	self.__readLine = 1;

	self.__tokens = { };
	self.__script = script;
	self.__buffer = script;
	self.__lengh = string.len( script );

	self.tokens = EXPR3_TOKENS;
	self.keywords = EXPR3_KEYWORDS;

	self:NextChar( );
end

-- Method:	Tokenizer.Execute();
-- Description: Executes the tokenizers main loop.

function Tokenizer:Execute( )
	while self.__char ~= nil do
		self:Loop();
	end

	return {
		tokens = self.__tokens;
		script = self.__buffer;
	};
end

-- Method:	Tokenizer.NextChar();
-- Description: Moves onto the next char in the script, adding the char to the tokendata.
function Tokenizer:NextChar( )
	self.__dataEnd = self.__dataEnd + 1;
	self.__data = self.__data .. self.__char;
	self:SkipChar( );
end

-- Method:	Tokenizer.PrevChar();
-- Description: Moves backwards one char.
function Tokenizer:PrevChar( )
	self.__dataEnd = self.__dataEnd - 2;
	self.__pos = self.__pos - 2;
	self.__data = string.sub( self.__data, 0, #self.__data - 2 );
	self:SkipChar();
end

-- Method:	Tokenizer.SkipChar();
-- Description: Moves onto the next char but does not add the char to the tokendata.
function Tokenizer:SkipChar( )
	if self.__lengh < self.__pos then
		self.__char = nil;
	elseif self.__char == "\n" then
		self:PushLine( );
	else
		self:PushChar( );
	end
end

-- Method:	Tokenizer.PushLine();
-- Description: Pushes the line position along.
function Tokenizer:PushLine( )
	self.__readLine = self.__readLine + 1;
	self.__readChar = 1;

	self.__pos = self.__pos + 1;
	self.__char = string.sub( self.__script, self.__pos, self.__pos );
end

-- Method:	Tokenizer.PushChar();
-- Description: Pushes the char position along.
function Tokenizer:PushChar( )
	self.__readChar = self.__readChar + 1;

	self.__pos = self.__pos + 1;
	self.__char = string.sub( self.__script, self.__pos, self.__pos );
end

-- Method:	Tokenizer.Clear();
-- Description: Cleares the token data.
function Tokenizer:Clear( )
	self.__data = "";
	self.__match = "";
	self.__dataStart = self.__pos;
	self.__dataEnd = self.__pos;
end

-- Method:	Tokenizer.NextPattern(string, boolean);
-- Description: Checks for a pattern in the buffer and pushes to the token data.
function Tokenizer:NextPattern( pattern, exact )
	if self.__char == nil then
		return false;
	end

	local s, e, r = string.find( self.__script, pattern, self.__pos, exact );

	if s ~= self.__pos then
		return false;
	end

	if not r then
		r = string.sub( self.__script, s, e );
	end

	self.__pos = e + 1;
	self.__dataStart = s;
	self.__dataEnd = e;
	self.__data = self.__data .. r;

	self.__match = r;

	if self.__pos > self.__lengh then
		self.__char = nil;
	else
		self.__char = string.sub( self.__script, self.__pos, self.__pos );
	end

	local ls = string.Explode( "\n", r );

	if #ls > 1 then
		self.__readLine = self.__readLine + #ls - 1;
		self.__readChar = string.len( ls[#ls] ) + 1;
	else
		self.__readChar = self.__readChar + string.len(ls[#ls]);
	end

	return true;
end

-- Method:	Tokenizer.MatchPattern(string, boolean);
-- Description: Matches a pattern with out pushing to the tokendata.
function Tokenizer:MatchPattern( pattern, exact )
	local s, e, r = string.find( self.__script, pattern, self.__pos, exact );

	if s ~= self.__pos then
		return false;
	end

	return true, string.sub( self.__script. self.__pos, self.__pos );
end

-- Method:	Tokenizer.NextPatterns(boolean, string, string* ...);
-- Description: Checks a list of matches in the buffer.

function Tokenizer:NextPatterns( exact, pattern, pattern2, ... )
	if (self:NextPattern(pattern, exact)) then
		return true;
	end

	if (pattern2) then
		return self:NextPatterns(exact, pattern2, ...);
	end

	return false;
end

-- Method:	Tokenizer.CreateToken(string, string, string, string);
-- Description: Creates a token and adds it to the token array.

function Tokenizer:CreateToken( type, name, data, origonal )

	if not data then
		data = self.__data;
	end

	local tkn = { };
	tkn.type = type;
	tkn.name = name;
	tkn.data = data;

	tkn.start = self.__dataStart + self.__offset;
	tkn.stop = self.__dataEnd + self.__offset;
	tkn.pos = self.__pos;
	tkn.char = self.__readChar;
	tkn.line = self.__readLine;
	tkn.depth = self.__depth;
	tkn.orig = origonal;
	
	local prev = self.__tokens[#self.__tokens];

	if prev and prev.line < tkn.line then
		tkn.newLine = true;
	end

	tkn.index = #self.__tokens + 1;
	self.__tokens[tkn.index] = tkn;
end

-- Method:	Tokenizer.SkipSpaces();
-- Description: Skips any space or tab chars.

function Tokenizer:SkipSpaces( )
	self:NextPattern( "^[%s\n]*" );

	local r = self.__match;

	self:Clear( );

	return r;
end

-- Method:	Tokenizer.SkipComments();
-- Description: Skips any comments in the code.

function Tokenizer:SkipComments( )
	if self:NextPattern( "^/%*.-%*/" ) or self:NextPattern( "^//.-\n" ) then
		self.__data = "";
		self.__skip = true;
		return true;
	elseif self:NextPattern( "/*", true ) then
		self:Throw( 0, "Un-terminated multi line comment (/*)", 0 );
	else
		return false;
	end
end

-- Method:	Tokenizer.Replace( string );
-- Description: Repalces the current token data.

function Tokenizer:Replace( str )
	local len = string.len( self.__data ) - string.len(str);
	
	self.__data = str;

	self.__offset = self.__offset + len;
end

-- Method:	Tokenizer.Loop( );
-- Description: self si the main loop, it builds all the tokens.

function Tokenizer:Loop( )
	if self.__char == nil then
		return false;
	end

	self:SkipSpaces( );

	-- Comments need to be (--[[]] && --) not (/**/ & //)
	-- Comments also need to be ignored.

	local skip = false;

	if self:NextPattern("^/%*.-%*/") then
		skip = true;
		local cmnt = "--[[" .. string.sub( self.__data, 3, string.len( self.__data ) - 2 ) .. "]]";
		self:Replace( cmnt );
	elseif self:NextPattern( "/*", true ) then
		self:Throw( 0, "Un-terminated multi line comment (/*)", 0 );
	elseif self:NextPattern( "^//.-\n" ) then
		skip = true;
		local cmnt = "--" .. string.sub( self.__data, 3 );
		self:Replace( cmnt );
	end

	if skip then
		self:Clear( );
		return true;
	end

	-- Numbers

	if self:NextPattern( "^0x[%x]+" ) then
		local n = tonumber( self.__data );

		if not n then
			self:Throw( 0, "Invalid number format (%s)", 0, self.__data );
		end

		self:CreateToken( "num", "hex", n );

		return true;
	end

	if self:NextPattern( "^0b[01]+" ) then
		local n = tonumber( string.sub(self.__data, 3 ), 2);

		if not n then
			self:Throw( 0, "Invalid number format (%s)", 0, self.__data );
		end

		self:CreateToken( "num", "bin", n );

		return true;
	end

	if self:NextPattern( "^%d+%.?%d*" ) then
		local n = tonumber( self.__data );

		if (not n) then
			self:Throw( 0, "Invalid number format (%s)", 0, self.__data );
		end

		self:CreateToken( "num", "real", n );

		return true;
	end

	-- Strings
	
	local pattern = false;

	if self.__char == "@" then
		self:SkipChar( );

		if not self.__char == '"' or self.__char == "'" then
			self:PrevChar();
		else
			pattern = true;
		end
	end

	if self.__char == '"' or self.__char == "'" then
		local strChar = self.__char;

		local escp = false;

		self:SkipChar( );

		while self.__char do
			local c = self.__char;

			if c == "\n" then
				if strChar == "'" then
					self:NextChar( );
				else
					break;
				end
			elseif not escp then
				if c == strChar then
					break;
				elseif c == "\\" then
					escp = true;
					self:SkipChar( );
					-- Escape sequence.
				else
					self:NextChar( );
				end
			elseif c == "\\" then
				escp = false;
				self:NextChar( );
			elseif c == strChar then
				escp = false;
				self.__char = "\n";
				self:NextChar( );
			elseif c == "t" then
				escp = false;
				self.__char = "\t";
				self:NextChar( );
			elseif c == "r" then
				escp = false;
				self.__char = "\r";
				self:NextChar( );
			elseif self:NextPattern( "^([0-9]+)" ) then
				local n = tonumber( self.__match );

				if not n or n < 0 or n > 255 then
					self:Throw( 0, "Invalid char (%s)", n );
				end

				escp = false;
				self.__pos = self.__pos - 1;
				self.__data = self.__data .. string.char(n);
				self:SkipChar();
			else
				self:Throw( 0, "Unfinished escape sequence (\\%s)", self.__char );
			end
		end

		if self.__char and self.__char == strChar then
			self:SkipChar( );

			-- Multi line strings need to be converted to lua syntax.
			if strChar == "'" then
				local str = "[[" .. string.sub( self.__data, 1, string.len( self.__data ) ) .. "]]";
				self:Replace(str);
			else
				local str = "\"" .. string.sub( self.__data, 1, string.len( self.__data ) ) .. "\"";
				self:Replace( str );
			end

			if not pattern then
				self:CreateToken( "str", "string" );
			else
				self:CreateToken( "ptr", "string pattern" );
			end

			return true;
		end

		local str = self.__data;

		if string.len( str ) > 10 then
			str = string.sub( str, 0, 10 ) .. "...";
		end

		self:Throw( 0, "Unterminated string (\"%s)", str );
	end

	-- Classes
	
	for k, v in pairs( EXPR3_CLASSES ) do
		if self:NextPattern("%( *" .. k .. " *%)") then
			self:CreateToken("cst", "cast", v.id, k);
			return true;
		end

		if self:NextPattern( k, true ) then
			self:CreateToken( "typ", "type", v.id, k );
			return true;
		end
	end

	-- Keywords.

	if self:NextPattern("^[a-zA-Z][a-zA-Z0-9_]*") then
		local w = self.__data;
		local tkn = self.keywords[w];

		if tkn then
			self:CreateToken(tkn[1], tkn[2]);
		else
			self:CreateToken("var", "variable");
		end
		
		return true;
	end

	-- Ops

	for k = 1, #self.tokens, 1 do
		local v = self.tokens[k];
		local op = v[1];

		if (self:NextPattern(op, true)) then
			if (op == "}") then
				self.__depth = self.__depth - 1;
			end

			self:CreateToken(v[2], v[3]);

			if (op == "{") then
				self.__depth = self.__depth + 1;
			end

			return true;
		end
	end

	if not self.__char or self.__char == "" then
		self.__char = nil;
	else
		self:Throw( 0, "Unknown syntax found (%s)", tostring(self.__char) );
	end
end

--[[
	Section: Parser.
	Description: Chews a string up into tokens.
]]

local Parser = {name = "parser"}; Parser.__index = Parser; setmetatable( Parser, BaseStage );

-- Method:	Parser.Init();
-- Description: Sets up the parser.

function Parser:Init( instance )
	self.__scope.classes = {};

	self.__instructions = {};

	self.__token = instance.tokens[0];
	self.__next = instance.tokens[1];
	self.__total = #instance.tokens;
	self.__tokens = instance.tokens;
	self.__script = instance.script;

	self.__tasks = { };

	self.__directives = { };
	self.__directives.inport = { };
	self.__directives.outport = { };
	self.sceduler = instance.sceduler;
end

-- Method:	Parser.Execute();
-- Description: Starts by parsing the root of our code.

function Parser:Execute( )
	local result = { };
	result.instruction = self:Root( );
	result.script = self.__script;
	result.tasks = self.__tasks
	result.tokens = self.__tokens;
	result.directives = self.__directives;
	result.sceduler = self.sceduler;
	return result;
end


-- Method:	Parser.Next();
-- Description: Moves onto the next token.

function Parser:Next( )
	self.__pos = self.__pos + 1;

	if self.__pos > self.__total then
		return false;
	end

	return true;
end

-- Method:	Parser.StepBackward();
-- Description: Moves backwards a set amount of tokens.

function Parser:StepBackward(steps)
	
	if not steps then
		steps = 1;
	end

	local pos = self.__pos - (steps + 1);

	if pos == 0 then
		self.__pos = 0;
		return;
	end

	if pos > self.__total then
		pos = self.__total;
	end

	self.__pos = pos;

	self:Next( );
end

-- Method:	Parser.HasTokens();
-- Description: Checks to see if we have reached the end of the code.

function PARSER.HasTokens(self)
	return self.__tokens[self.__pos] ~= nil;
end

-- Method:	Parser.GetToken(integer);
-- Description: Returns the token relative to the curent token.

function Parser:GetToken( offset )
	offset = offset or 0;
	return self.__tokens[self.__pos + offset];
end

-- Method:	Parser.GetTokenType(integer);
-- Description: Gets the token type of the token relative to the curent token.

function Parser:GetTokenType( offset )
	offset = offset or 0;

	local token = self.__tokens[self.__pos + offset];

	if token then return token.type end
end

-- Method:	Parser.GetTokenData(integer);
-- Description: Gets the token data of the token relative to the curent token.

function Parser:GetTokenData( offset )
	offset = offset or 0;

	local token = self.__tokens[self.__pos + offset]

	if token then return token.data end
end

-- Method:	Parser.CheckToken(integer, table/string, string*);
-- Description: Gets the token data of the token relative to the curent token.

function Parser:CheckToken( offset, types, data )
	if not istable( types ) then
		types = {types};
	end

	local token = self:GetToken( offset );

	if token then
		local tkntyp = token.type;
		
		for i = 1, #types do
			if tkntyp == types[i] then
				if not data or data == token.data then
					return true;
				end
			end
		end
	end

	return false;
end

-- Method:	Parser.AcceptToken(integer, table/string, string*);
-- Description: Checks if the token matches a type and progress to the next token.

function Parser:AcceptToken( offset, types, data )
	if self:CheckToken( offset, types, data ) then
		self:Next( );
		return true;
	end

	return false;
end

-- Method:	Parser.CheckTokenSequence(integer, table/string, string*);
-- Description: Checks if a sequence of tokens matches the curent token sequence.

function Parser:CheckTokenSequence( offet, ... )
	offet = offet or 0;

	local types = {...};

	for i = 1, #types do
		if not self:CheckToken(offet + i, types[i]) then
			return false, i;
		end
	end

	return true;
end

-- Method:	Parser.FindInStatment(integer, string*);
-- Description: Finds the first token of type in the current statment.

function Parser:FindInStatment( offset, type )
	local first = self:GetToken( offset );

	while true do
		local token = self:GetToken( offset );

		if not token then return end

		if token.type == "sep" then return end

		if first.line ~= token.line then return end

		if token.type == type then return token end
	end
end

-- Method:	Parser.LastInStatment(integer, table/string, string*);
-- Description: Finds the last token of type in the current statment.

function Parser:LastInStatment( offset, type )
	local last;
	local first = self:GetToken( offset );

	while true do
		local token = self:GetToken( offset );

		if not token then return last end

		if token.type == "sep" then return last end

		if first.line ~= token.line then return last end

		if token.type == type then last = token end
	end

	return last;
end

-- Method:	Parser.Require( string, string, ... );
-- Description: Require a token or throw an error.

function Parser:Require( type, msg, ... )
	if not self:Accept(type) then
		self:Throw( self:GetToken( ), msg, ... )
	end
end

-- Method:	Parser.Exclude( string, string, ... );
-- Description: Excludes a token and throws and error.

function Parser:Exclude( tpye, msg, ... )
	if self:Accept(type) then
		self:Throw( self:GetToken( ), msg, ... )
	end
end

-- Method:	Parser.ExcludeWhiteSpace( string, ... );
-- Description: Excludes a white space and throws and error.

function Parser:ExcludeWhiteSpace( msg, ... )
	if not self:HasTokens() then 
		self:Throw( self:GetToken( ), msg, ... )
	end
end

-- Method:	Parser.ExcludeWhiteSpace( string, ... );
-- Description: Excludes a white space and throws and error.

function Parser:StartInstruction( type, token )
	
	if not istable(token) then
		error("PARSER: StartInstruction got bad token type " .. tostring(token));
	elseif not isstring( type ) then
		error("PARSER: StartInstruction got bad instruction type " .. tostring(type));
	elseif not istable(type) then
		error("PARSER: StartInstruction got bad instruction token " .. tostring(token));
	end

	local instruction = { };
	instruction.type = type;
	instruction.count = 0;
	instruction.result = "void";
	instruction.char = token.char;
	instruction.line = token.line;
	instruction.deph = this.__depth;
	instruction.scope = this.__scope;

	return instruction;
end

-- Method:	Parser.EndInstruction( string, ... );
-- Description: Ends and instruction.

function Parser:EndInstruction( instruction, ... )
	instruction.final = this:GetToken( );
	instruction.args = {...};
	return instruction;
end

--[[
	Section: Compiler.
	Description: Chews a string up into tokens.
]]

local Compiler = {name = "compiler"}; Compiler.__index = Compiler; setmetatable( Compiler, BaseStage );

function Compiler:Init()

end

--[[
	Section: Load all stages.
	Description: Loads the entire compiler.
]]

EXPR3_TOKENIZER = Tokenizer;
EXPR3_PARSER = Parser;
EXPR3_COMPILER = Compiler;