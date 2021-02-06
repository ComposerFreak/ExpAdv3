--[[
		 ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
		F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Sound Extension::

			_____
		___ |[]|_n__n_I_c
		|___||__|###|____}
		O-O--O-O+++--O-O

		For the trains :D
]]

--[[=================================================================================================
	Limits
=================================================================================================]]--

local max = 20; -- Def Max Sounds
local cvar_max;

if SERVER then
	cvar_max = CreateConVar("wire_expression3_sound_max", max, FCVAR_ARCHIVE, "The maxamum sounds allowed per expression 3 entity.")
elseif CLIENT then
	cvar_max = CreateConVar("wire_expression3_sound_max_cl", max, FCVAR_ARCHIVE, "The maxamum sounds allowed per expression 3 entity.")
end

timer.Create("Expression3.Sounds", 1, 0, function()
	max = cvar_max:GetInt();
end);

--[[=================================================================================================
	Stop Sound
=================================================================================================]]--

local function stopAll(context)
	if context.sounds then
		for k, v in pairs(context.sounds) do 
			if v and v.Stop then v:Stop(); end
		end
	end
end

local function stopAllPlayer(player)
	for _, context in pairs(EXPR_LIB.GetAll()) do
		if (context.player == player) then
			stopAll(context);
		end
	end
end

--[[=================================================================================================
	Hooks
=================================================================================================]]--

hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Sound", function(entity, context, env)
	context.data.sounds = { };
	context.data.sounds_count = 0;
end);


hook.Add("Expression3.Entity.Stop", "Expression3.Sound", function(entity, context)
	stopAll(context);
end);

hook.Add("PlayerDisconnected", "Expression3.Sound", function(player)
	stopAllPlayer(player);
end);

--[[=================================================================================================
	Create Sound
=================================================================================================]]--

local type = type;
local match = string.match;
local gsub = string.gsub;
local trim = string.Trim;
local CreateSound = CreateSound;

local function createSound(context, entity, file)
	if context.data.sounds_count >= max then return; end
	
	if context:CanUseEntity(e) then return; end
	
	if match(file, "[\"?]") then return; end
	
	file = trim(gsub( file, "\\", "/"), nil);
	
	local sound = CreateSound(entity, file);

	if sound then
		context.data.sounds[sound] = sound;
		context.data.sounds_count = context.data.sounds_count + 1;
	end

	return sound;
end

--[[=================================================================================================
	Create an Extention and a Class
=================================================================================================]]--

local extension = EXPR_LIB.RegisterExtension("sound");

extension:SetSharedState();

extension:RegisterClass("snd", {"sound"}, function(sound)
	return type(sound) == "CSoundPatch";
end, function(sound)
	return type(sound) == "CSoundPatch";
end);

--[[=================================================================================================
	Constrcutors Create Sounds
=================================================================================================]]--

local _NIL = EXPR_LIB._NIL_;

extension:RegisterConstructor("snd", "s", function(context, file)
	return createSound(context, context.entity, file) or _NIL;
end, false, "Creates a new sound object using <str> as the file path.");

extension:RegisterConstructor("snd", "e,s", function(context, ent, file)
	return createSound(context, ent, file) or _NIL;
end, false, "Creates a new sound object parented to <ent> using <str> as the file path.");

---------------------------------------------------------------------------------------------

extension:RegisterConstructor("snd", "s,b", function(context, file, play)
	local sound = createSound(context, context.entity, file);
	if play and sound then sound:Play(); end
	return sound or _NIL;
end, false, "Creates a new sound object using <str> as the file path. Sound will auto play if <bool> is true.");

extension:RegisterConstructor("snd", "e,s,b", function(context, ent, file, play)
	local sound = createSound(context, ent, file);
	if play and sound then sound:Play(); end
	return sound or _NIL;
end, false, "Creates a new sound object parented to <ent> using <str> as the file path. Sound will auto play if <bool> is true.");

---------------------------------------------------------------------------------------------

extension:RegisterConstructor("snd", "s,b,n", function(context, file, play, pitch)
	local sound = createSound(context, context.entity, file);
	if sound then sound:ChangePitch(pitch); end
	if play and sound then sound:Play(); end
	return sound or _NIL;
end, false, "Creates a new sound object using <str> as the file path and <int> as pitch. Sound will auto play if <bool> is true.");

extension:RegisterConstructor("snd", "e,s,b,n", function(context, ent, file, play, pitch)
	local sound = createSound(context, ent, file);
	if sound then sound:ChangePitch(pitch); end
	if play and sound then sound:Play(); end
	return sound or _NIL;
end, false, "Creates a new sound object parented to <ent> using <str> as the file path and <int> as pitch. Sound will auto play if <bool> is true.");

---------------------------------------------------------------------------------------------

extension:RegisterConstructor("snd", "s,b,n,n", function(context, file, play, pitch, volume)
	local sound = createSound(context, context.entity, file);
	if sound then sound:ChangeVolume(volume); end
	if play and sound then sound:Play(); end
	return sound or _NIL;
end, false, "Creates a new sound object using <str> as the file path and <int1> as pitch and <int2> as volume. Sound will auto play if <bool> is true.");

extension:RegisterConstructor("snd", "e,s,b,n,n", function(context, ent, file, play, pitch, volume)
	local sound = createSound(context, ent, file);
	if sound then sound:ChangePitch(pitch); end
	if sound then sound:ChangeVolume(volume); end
	if play and sound then sound:Play(); end
	return sound or _NIL;
end, false, "Creates a new sound object parented to <ent> using <str> as the file path and <int1> as pitch and <int2> as volume. Sound will auto play if <bool> is true.");

--[[=================================================================================================
	Methods
=================================================================================================]]--

extension:RegisterMethod("snd", "setPitch", "n", "", 0, "ChangePitch", true, "Sets the pitch of the sound to <int>.");
extension:RegisterMethod("snd", "setPitch", "n,n", "", 0, "ChangePitch", true, "Sets the pitch of the sound to <int1>, over time <int2>.");
extension:RegisterMethod("snd", "getPitch", "", "n", 1, "GetPitch", true, "Returns the pitch of the sound.");


extension:RegisterMethod("snd", "setVolume", "n", "", 0, "ChangeVolume", true, "Sets the volume of the sound to <int>.");
extension:RegisterMethod("snd", "setVolume", "n,n", "", 0, "ChangeVolume", true, "Sets the volume of the sound to <int1>, over time <int2>.");
extension:RegisterMethod("snd", "getVolume", "", "n", 1, "GetVolume", true, "Returns the volume of the sound.");

extension:RegisterMethod("snd", "play", "", "", 0, "Play", true, "Plays the sound.");
extension:RegisterMethod("snd", "stop", "", "", 0, "Stop", true, "Stops the sound.");
extension:RegisterMethod("snd", "fadeOut", "n", "", 0, "FadeOut", true, "Fades a sound out over <int> seconds.");
extension:RegisterMethod("snd", "isPlaying", "", "b", 1, "IsPlaying", true, "Returns true if the sound is playing.");

---------------------------------------------------------------------------------------------

local naf = function() end;

local function remove(context, sound)
	if not sound then return; end
	if sound._nulled then return; end

	context.data.sounds[sound] = nil;
	context.data.sounds_count = context.data.sounds_count - 1;

	if sound.Stop then sound.Stop(); end
	sound._nulled = true;
	sound.Play = naf;
end

extension:RegisterMethod("snd", "remove", "", "", 0, remove, false, "Destroys the sound object.");

--[[
]]

extension:EnableExtension();
