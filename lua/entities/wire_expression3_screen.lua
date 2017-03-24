--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Expression 3 Base::
]]

AddCSLuaFile();

ENT.Type 			= "anim";
ENT.Base 			= "wire_expression3_base";

ENT.PrintName       = "Expression 3 Screen";
ENT.Author          = "Rusketh";
ENT.Contact         = "";

ENT.Expression3 	= true;
ENT.Expression3_Screen 	= true;

EXPR3_DRAWSCREEN = false;

if (SERVER) then
	function ENT:Initialize()
		self.BaseClass.BaseClass.Initialize(self);
		self.Inputs = WireLib.CreateInputs( self, { } )
		self.Outputs = WireLib.CreateOutputs( self, { } )
	end
end

if (CLIENT) then
	function ENT:Initialize()
		self.GPU = GPULib.WireGPU(self, WIRE_GPU_HD);
		local res = self.GPU.Resolution or 512;
	end

	function ENT:DrawEntityOutline() end

	function ENT:Draw()
		self:DrawModel()
		
		Wire_Render(self)

		self.GPU:RenderToGPU( function()
			render.Clear( 0, 0, 0, 255 )
			EXPR3_DRAWSCREEN = true;
			self:CallEvent("", 0, "RenderScreen", {"n", res}, {"n", res}, {"e", self});
			EXPR3_DRAWSCREEN = false;
		end);

		self.GPU:Render()
	end

	function ENT:OnRemove()
		self.GPU:Finalize()
	end
end