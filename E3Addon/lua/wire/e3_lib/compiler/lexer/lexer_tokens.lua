--[[
	PARSER KEYWORDS
]]

E3_KEYWORDS = {};

function E3_RegisterKeyWord(word, name, desc)
	E3_KEYWORDS[name] = {word, desc},
end

E3_RegisterKeyWord("IF", "if", "if");
E3_RegisterKeyWord("ELSEIF", "eif", "elseif");
E3_RegisterKeyWord("ELSE", "els", "else");
E3_RegisterKeyWord("WHILE", "whl", "while");
E3_RegisterKeyWord("FOR", "for", "for");
E3_RegisterKeyWord("FOREACH", "each", "foreach");
E3_RegisterKeyWord("DELEGATE", "del", "delegate");
E3_RegisterKeyWord("TRUE", "tre", "true");
E3_RegisterKeyWord("FALSE", "fls", "false");
E3_RegisterKeyWord("VOID", "void", "void");
E3_RegisterKeyWord("BREAK", "brk", "break");
E3_RegisterKeyWord("CONTINUE", "cnt", "continue");
E3_RegisterKeyWord("RETURN", "ret", "return");
E3_RegisterKeyWord("GLOBAL", "glo", "global");
E3_RegisterKeyWord("SERVER", "sv", "server");
E3_RegisterKeyWord("CLIENT", "cl", "client");
E3_RegisterKeyWord("NEW", "new", "constructor");
E3_RegisterKeyWord("TRY", "try", "try");
E3_RegisterKeyWord("CATCH", "cth", "catch");
E3_RegisterKeyWord("CLASS", "cls", "class");
E3_RegisterKeyWord("METHOD", "meth", "method");

--[[
	TOKENS
]]

E3_TOKENS = { };

function E3_RegisterToken(token, type, desc)
	E3_TOKENS[type] = {token, desc};
end

E3_RegisterToken("+",   "ADD", "addition");
E3_RegisterToken("-",   "SUB", "subtract");
E3_RegisterToken("*",   "MUL", "multiplier");
E3_RegisterToken("/",   "DIV", "division");
E3_RegisterToken("%",   "MOD", "modulus");
E3_RegisterToken("^",   "EXP", "power");
E3_RegisterToken("=",   "ASS", "assign");
E3_RegisterToken("+=",  "AADD", "increase");
E3_RegisterToken("-=",  "ASUB", "decrease");
E3_RegisterToken("*=",  "AMUL", "multiplier");
E3_RegisterToken("/=",  "ADIV", "division");
E3_RegisterToken("++",  "INC", "increment");
E3_RegisterToken("--",  "DEC", "decrement");
E3_RegisterToken("==",  "EQ", "equal");
E3_RegisterToken("!=",  "NEQ", "unequal");
E3_RegisterToken("<",   "LTH", "less");
E3_RegisterToken("<=",  "LEQ", "less or equal");
E3_RegisterToken(">",   "GTH", "greater");
E3_RegisterToken(">=",  "GEQ", "greater or equal");
E3_RegisterToken("&",   "BAND", "and");
E3_RegisterToken("|",   "BOR", "or");
E3_RegisterToken("^^",  "BXOR", "or");
E3_RegisterToken(">>",  "BSHR", ">>");
E3_RegisterToken("<<",  "BSHL", "<<");
E3_RegisterToken("!",   "NOT", "not");
E3_RegisterToken("&&",  "AND", "and");
E3_RegisterToken("||",  "OR", "or");
E3_RegisterToken("?",   "QSM", "?");
E3_RegisterToken(":",   "COL", "colon");
E3_RegisterToken(";",   "SEP", "semicolon");
E3_RegisterToken(",",   "COM", "comma");
E3_RegisterToken("$",   "DLT", "delta");
E3_RegisterToken("#",   "LEN", "length");
E3_RegisterToken("~",   "CNG", "changed");
E3_RegisterToken(".",   "PRD", "period");
E3_RegisterToken("(",   "LPA", "left parenthesis");
E3_RegisterToken(")",   "RPA", "right parenthesis");
E3_RegisterToken("{",   "LCB", "left curly bracket");
E3_RegisterToken("}",   "RCB", "right curly bracket");
E3_RegisterToken("[",   "LSB", "left square bracket");
E3_RegisterToken("]",   "RSB", "right square bracket");
E3_RegisterToken('@',   "DIR", "directive operator");
E3_RegisterToken("...", "VARG", "varargs");

--[[
	PATTENR FUNCS TO BE MOVED
]]

function E3_PATTERN_CMT(self)
	if self:NextPattern("^/%*.-%*/") then
		skip = true;
		local cmnt = "--[[" .. string.sub( self.__data, 3, string.len( self.__data ) - 2 ) .. "]]";
		self:Replace( cmnt );
	elseif self:NextPattern( "/*", true ) then
		self:Throw( 0, "Unterminated multi line comment (/*)", 0 );
	elseif self:NextPattern( "^//.-\n" ) then
		skip = true;
		local cmnt = "--" .. string.sub( self.__data, 3 );
		self:Replace( cmnt );
	end
end

function E3_PATTERN_NUM(self)
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
end

function E3_PATTERN_STR(self)
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
end

function E3_PATTERN_TYP(self)
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

	-- todo: user classes.
end

--[[
	PATERNS
]]

E3_PATTERNS = {};

function E3_RegisterPattern(name, paterns, func, desc)
	E3_PATTERNS[name] = {paterns, func};
end

E3_RegisterPattern("CMT", E3_PATTERN_CMT, nil, "Comment");
E3_RegisterPattern("NUM", E3_PATTERN_NUM, nil, "Number");
E3_RegisterPattern("STR", E3_PATTERN_STR, nil, "String");
E3_RegisterPattern("TYP", E3_PATTERN_TYP, nil, "Type");



