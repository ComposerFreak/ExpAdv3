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
    Yes Ripmax, this is your EA2 ext_sound.
]]

local ext_sound = EXPR_LIB.RegisterExtension("sound");

local max_sounds = 10; -- TODO: Make this convar!

--[[
  Utility functions
]]

EXPR_SOUNDS = EXPR_SOUNDS or { };

local function stopSound(context, index, fade)

  if isnumber(index) then
    index = math.floor( index );
  end

  local sound = context.data.sounds[index];

  if not sound then
    return;
  end

	if fade > 0 then
    sound:FadeOut( fade );
    timer.Simple( fade, function()
      stopSound(context, index, 0);
    end);
	else
		sound:Stop();
		context.data.sound[index] = nil;
	end

  context.data.sounds = context.data.sounds - 1;
end

local function playSound(context, entity, duration, index, fade, file)

  if not entity or not IsValid(entity) then
    entity = context.entity;
  end

  if string.match(file, "[\"?]") then
    return;
  end

  file = string.Trim( string.gsub( file, "\\", "/") );

  if isnumber(index) then
    index = math.floor( index );
  end

  if context.data.sound_count >= maxsounds then
    return;
  end

  if context.data.sounds[index] then
    stopSound(context, index, 0);
  end

	local newSound = CreateSound(entity, file);

	EXPR_SOUNDS[#EXPR_SOUNDS + 1] = newSound;

	context.data.sounds[index] = newSound;

	newSound:Play();

	context.data.sounds = context.data.sounds + 1;

  if duration > 0 and fade > 0 then
    timer.Create( "E3Gate-" .. entity:EntIndex() .. ";STOPSound_" .. index, duration, 0, function()
      stopSound(context, index, fade);
    end );
  end
end

local function volume(context, number, volume, fade)

  if isnumber(index) then
    index = math.floor( index );
  end

  local sound = context.data.sounds[index];

  if volume > 1 then
    volume = 1;
  elseif volume < 0 then
    volume = 0;
  end

  if sound then
    sound:ChangeVolume(volume, fade or 0);
  end
end

local function pitch(context, index, pitch, fade)
  if isnumber(index) then
    index = math.floor( index );
  end

  local sound = context.data.sounds[index];

  if pitch > 255 then
    pitch = 255;
  elseif pitch < 0 then
    pitch = 0;
  end

  if sound then
    sound:ChangePitch(pitch, fade or 0);
  end

end

local function duration(file)
  if string.match(file, "[\"?]") then
    return 0;
  end

  file = string.Trim( string.gsub( file, "\\", "/") );

  return SoundDuration(file) or 0;
end


-- Nothing to see here, just showing Ripmax how a true Jedi does thing!

--[[
  Hooks
]]

if SERVER then
  hook.Add("Expression3.Entity.BuildSandbox", "Expression3.Sounds", function(entity, ctx, env)
    ctx.data.sounds = {};
    ctx.data.sound_count = 0;
  end);

  hook.Add("Expression3.Entity.Stop", "Expression3.Sounds",function(entity, ctx)
    for _, sound in pairs( ctx.data.sounds ) do
      sound:Stop();
    end

    ctx.data.sounds = {}
    ctx.data.sound_count = 0;
  end);

  hook.Add("PlayerDisconnected", "Expression3.Sounds", function( ply )
    for _, ctx in pairs(EXPR_LIB.GetAll()) do
      if (ctx.player == ply) then

        for _, sound in pairs( ctx.data.sounds ) do
          sound:Stop();
        end

        ctx.data.sounds = {}
        ctx.data.sound_count = 0;
      end
    end
  end );
end

--[[
  Library
]]

ext_sound:SetServerState();

ext_sound:RegisterLibrary("sound");

--[[
  Sound creators
]]

local function playSound2(context, duration, index, fade, file) playSound(context, context.entity, duration, index, fade, file); end

ext_sound:RegisterFunction("sound", "play", "n,n,s", "", 0, playSound2, false);
ext_sound:RegisterFunction("sound", "play", "n,n,n,s", "", 0, playSound2, false);

ext_sound:RegisterFunction("sound", "play", "e,n,n,s", "", 0, playSound, false);
ext_sound:RegisterFunction("sound", "play", "e,n,n,n,s", "", 0, playSound, false);

ext_sound:RegisterFunction("sound", "stop", "n", "", 0, stopSound, false);
ext_sound:RegisterFunction("sound", "stop", "n,n", "", 0, stopSound, false);

ext_sound:RegisterFunction("sound", "volume", "n,n", "", 0, volume, false);
ext_sound:RegisterFunction("sound", "volume", "n,n,n", "", 0, volume, false);

ext_sound:RegisterFunction("sound", "pitch", "n,n", "", 0, pitch, false);
ext_sound:RegisterFunction("sound", "pitch", "n,n,n", "", 0, pitch, false);

ext_sound:RegisterFunction("sound", "duration", "s", "n", 1, duration, true);

ext_sound:RegisterFunction("sound", "stopAll", "", "", 0, function(context)
  for index, sound in pairs(context.data.sounds) do
    sound:Stop();
    timer.Remove( "E3Gate-" .. entity:EntIndex() .. ";STOPSound_" .. index );
  end

  context.data.sounds = {}
  context.data.sound_count = 0;
end, false);

--[[
]]

ext_sound:EnableExtension();
