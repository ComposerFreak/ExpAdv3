--[[
	TOKEN PATTERNS
]]

function E3_PATTERN_CMT(self)
	if self:NextPattern("^/%*.-%*/") then
		return true,  self:CreateToken("CMT", "multi line comment");
	elseif self:NextPattern( "/*", true ) then
		self:Throw( 0, "Unterminated multi line comment (/*)", 0 );
	elseif self:NextPattern( "^//.-\n" ) then
		return true,  self:CreateToken( "CMT", "comment");
	end

	return false;
end

function E3_PATTERN_SPACE(self)
	if self:NextPattern("^[%s\n]*") then
		return self:CreateToken("SPACE", "");
	end
end

function E3_PATTERN_NUM(self)
	if self:NextPattern( "^0x[%x]+" ) then
		local n = tonumber( self.__data );

		if not n then
			self:Throw( 0, "Invalid number format (%s)", 0, self.__data );
		end

		return true,  self:CreateToken( "NUM", "hex", n );
	end

	if self:NextPattern( "^0b[01]+" ) then
		local n = tonumber( string.sub(self.__data, 3 ), 2);

		if not n then
			self:Throw( 0, "Invalid number format (%s)", 0, self.__data );
		end

		return true,  self:CreateToken( "NUM", "bin", n );
	end

	if self:NextPattern( "^%d+%.?%d*" ) then
		local n = tonumber( self.__data );

		if (not n) then
			self:Throw( 0, "Invalid number format (%s)", 0, self.__data );
		end

		return true,  self:CreateToken( "NUM", "real", n );
	end

	return false;
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
				return true,  self:CreateToken( "STR", "string" );
			else
				return true,  self:CreateToken( "PTR", "string pattern" );
			end
		end

		local str = self.__data;

		if string.len( str ) > 10 then
			str = string.sub( str, 0, 10 ) .. "...";
		end

		self:Throw( 0, "Unterminated string (\"%s)", str );
	end

	return false;
end

function E3_PATTERN_TYP(self)
	for k, v in pairs( EXPR3_CLASSES ) do
		if self:NextPattern( k, true ) then
			return true,  self:CreateToken( "TYP", "type", v.id, k );
		end
	end

	-- todo: user classes.

	return false;
end

function E3_PATTERN_CST(self)
	for k, v in pairs( EXPR3_CLASSES ) do
		if self:NextPattern("%( *" .. k .. " *%)") then
			return true,  self:CreateToken("CST", "cast", v.id, k); 
		end
	end

	-- todo: user classes.

	return false;
end

--[[
	PARSE FUNCS
]]

function E3_PARSE_INIT(self, token)
	self.classes = {};
	self.deph = 0;
end

function E3_PARSE_GETSTATE(self, state)
	state.deph = self.deph;
end

function E3_PARSE_SETSTATE(self, state)
	self.deph = state.deph;
end


function E3_PARSE_PUSH(self, token)
	self.deph = self.deph + 1;
end

function E3_PARSE_POP(self, token)
	self.deph = self.deph - 1;
end

function E3_PARSE_ADD_TYP(self, token)
	self.classes[token.data] = token.data;
end


--[[
	COMPILE FUNCS
]]

function E3_COMPILE_ROOT(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_BLOCK0(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMTS0(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMTS1(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT0(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT1(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT2(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT3(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT4(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT5(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT6(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT7(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT8(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT9(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT10(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT11(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT12(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT13(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT14(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT15(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT16(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT17(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT18(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT19(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT20(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_STMT21(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_DIR1(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_DIR2(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_DIR3(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_DIR4(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_DIR5(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR0(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR1(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR2(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR3(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR4(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR5(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR6(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR7(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR8(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR9(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR10(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR11(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR12(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR13(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR14(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR15(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR16(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_EXPR17(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_PRMS0(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_PRMS1(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_ARGS(compiler, root)
	-- TODO: this.
end

function E3_COMPILE_CND(compiler, root)
	-- TODO: this.
end
