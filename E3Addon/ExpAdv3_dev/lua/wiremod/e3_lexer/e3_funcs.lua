--[[
	TOKEN PATTERNS
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
	PARSE FUNCS
]]

function E3_PARSE_PUSH(tokeniser, token)
	-- TODO: this.
end

function E3_PARSE_POP(tokeniser, token)
	-- TODO: this.
end

function E3_PARSE_ADD_TYP(tokeniser, token)
	-- TODO: this.
end


--[[
	COMPILE FUNCS
]]

function COMPILE_ROOT(compiler, root)
	-- TODO: this.
end

function COMPILE_BLOCK0(compiler, root)
	-- TODO: this.
end

function COMPILE_STMTS0(compiler, root)
	-- TODO: this.
end

function COMPILE_STMTS1(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT0(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT1(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT2(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT3(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT4(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT5(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT6(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT7(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT8(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT9(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT10(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT11(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT12(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT13(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT14(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT15(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT16(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT17(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT18(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT19(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT20(compiler, root)
	-- TODO: this.
end

function COMPILE_STMT21(compiler, root)
	-- TODO: this.
end

function COMPILE_DIR1(compiler, root)
	-- TODO: this.
end

function COMPILE_DIR2(compiler, root)
	-- TODO: this.
end

function COMPILE_DIR3(compiler, root)
	-- TODO: this.
end

function COMPILE_DIR4(compiler, root)
	-- TODO: this.
end

function COMPILE_DIR5(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR0(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR1(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR2(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR3(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR4(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR5(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR6(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR7(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR8(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR9(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR10(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR11(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR12(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR13(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR14(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR15(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR16(compiler, root)
	-- TODO: this.
end

function COMPILE_EXPR17(compiler, root)
	-- TODO: this.
end

function COMPILE_PRMS0(compiler, root)
	-- TODO: this.
end

function COMPILE_PRMS1(compiler, root)
	-- TODO: this.
end

function COMPILE_ARGS(compiler, root)
	-- TODO: this.
end

function COMPILE_CND(compiler, root)
	-- TODO: this.
end
