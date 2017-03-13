--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 
]]--

local Parser = EXPR3_PARSER;
local Compiler = EXPR3_COMPILER;

--[[
	Section: ROOT and SEQ
	Description: Root of code.
]]

-- Method:	Parser.Root( string, ... );
-- Description: Generates the entire code.

function Parser:Root( )
	local instruction = self:StartInstruction( "ROOT", self:GetToken( ) );

	local statments = self:GetStatments( false );

	return self:EndInstruction( instruction, statments );
end

-- Method:	Parser.Block_1( string, boolean )
-- Description: Gets a statment block.

function Parser:Block_1( startToken, endToken )
	self:ExcludeWhiteSpace( "Further input required at end of code, incomplete statement" );

	if self:AcceptToken( 0, "lcb" ) then
		
		local sequence = self:StartInstruction( "SEQ", self:GetToken( ) );

		if startToken then
			self.sceduler:ReplaceToken( sequence, self:GetToken( ) );
			self.sceduler:InjectPostfix( sequence, self:GetToken( ), startToken );
		end

		local statments = { };

		if not self:CheckToken( 0, "rcb" ) then
			self:PushScope( )

			statments = self:Statments( true );

			self:PopScope( );
		end

		if not self:AcceptToken( 0, "rcb" ) then
			self:Throw( self:GetToken( ), "Right curly bracket (}) missing, to close block" );
		end
		
		self.sceduler:ReplaceToken( sequence, self:GetToken( ), endToken and "end" or "" );

		return self:EndInstruction( sequence, statments );
	end

	do
		local sequence = self:StartInstruction( "SEQ", self:GetToken( ) );

		if startToken then
			self:InjectPostfix( sequence, self:GetToken( ), startToken );
		end

		self:PushScope()

		local statment = self:Statment_1();

		self:PopScope()

		if endToken then
			self.sceduler:InjectPostfix( sequence, statment.final, "end" );
		end

		return self:EndInstruction( sequence, { statment } );
	end
end


--[[
	Section: DIRECTIVES
	Description: Handles directives.
]]


