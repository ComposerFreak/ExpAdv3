local extension = EXPR_LIB.RegisterExtension("keypress")

extension:SetSharedState();

--[[
	Permission
]]

extension:RegisterPermission("KeyPress", "fugue/controller-d-pad.png", "This E3 gate is allowed to sniff your keypresses.");

--[[
	Key press functions
]]

extension:RegisterMethod("p", "keyForward", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_FORWARD));
end, false);

extension:RegisterMethod("p", "keyLeft", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_MOVELEFT));
end, false);

extension:RegisterMethod("p", "keyBack", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_BACK));
end, false);

extension:RegisterMethod("p", "keyRight", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_MOVERIGHT));
end, false);

extension:RegisterMethod("p", "keyJump", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_JUMP));
end, false);

extension:RegisterMethod("p", "keyAttack1", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_ATTACK));
end, false);

extension:RegisterMethod("p", "keyAttack2", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_ATTACK2));
end, false);

extension:RegisterMethod("p", "keyUse", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_USE));
end, false);

extension:RegisterMethod("p", "keyReload", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_RELOAD));
end, false);

extension:RegisterMethod("p", "keyZoom", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_ZOOM));
end, false);

extension:RegisterMethod("p", "keyWalk", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_WALK));
end, false);

extension:RegisterMethod("p", "keySprint", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_SPEED));
end, false);

extension:RegisterMethod("p", "keyLeftTurn", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_LEFT));
end, false);

extension:RegisterMethod("p", "keyRightTurn", "", "b", 1, function(ctx, e)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(IN_RIGHT));
end, false);

extension:RegisterMethod("p", "keyDuck", "", "b", 1, function(ctx, e)
	if not IsValid(e) or not e:IsPlayer() then return false; end
	if not ctx:ppPlayer(e, "KeyPress") then return false; end
	return (e:KeyDown(IN_DUCK) or e:GetInfoNum("gmod_vehicle_viewmode", 0) >= 1);
end, false);

extension:RegisterMethod("p", "keyDown", "n", "b", 1, function(ctx, e, k)
	return (IsValid(e) and e:IsPlayer() and ctx:ppPlayer(e, "KeyPress") and e:KeyDown(k));
end, false);

--[[
	Remap keyboard -- taken from wire keyboard
]]

--TODO

--[[
	Key Press Events
]]

extension:RegisterEvent("PlayerButtonDown","p,n");
extension:RegisterEvent("PlayerButtonUp","p,n");

local call = function(ply, event, button)

	for _, context in pairs(EXPR_LIB.GetAll()) do

		if IsValid(context.entity) then
			local perm = context:ppPlayer(ply, "KeyPress");

			if perm then context.entity:CallEvent("*", 0, event, {"p", ply}, {"n", button}); end
		end
	end
end

hook.Add("PlayerButtonDown", "Expression3.Event", function(ply, button)
	call(ply, "PlayerButtonDown", button);
end);

hook.Add("PlayerButtonUp", "Expression3.Event", function(ply, button)
	call(ply, "PlayerButtonUp", button);
end);

--[[
	Constants - Keyboard
]]

extension:RegisterLibrary("key");

extension:RegisterConstant("key", "zero", "n", KEY_0);
extension:RegisterConstant("key", "one", "n", KEY_1);
extension:RegisterConstant("key", "two", "n", KEY_2);
extension:RegisterConstant("key", "three", "n", KEY_3);
extension:RegisterConstant("key", "four", "n", KEY_4);
extension:RegisterConstant("key", "five", "n", KEY_5);
extension:RegisterConstant("key", "six", "n", KEY_6);
extension:RegisterConstant("key", "seven", "n", KEY_7);
extension:RegisterConstant("key", "eight", "n", KEY_8);
extension:RegisterConstant("key", "nine", "n", KEY_9);

extension:RegisterConstant("key", "a", "n", KEY_A);
extension:RegisterConstant("key", "b", "n", KEY_B);
extension:RegisterConstant("key", "c", "n", KEY_C);
extension:RegisterConstant("key", "d", "n", KEY_D);
extension:RegisterConstant("key", "e", "n", KEY_E);
extension:RegisterConstant("key", "f", "n", KEY_F);
extension:RegisterConstant("key", "g", "n", KEY_G);
extension:RegisterConstant("key", "h", "n", KEY_H);
extension:RegisterConstant("key", "i", "n", KEY_I);
extension:RegisterConstant("key", "j", "n", KEY_J);
extension:RegisterConstant("key", "k", "n", KEY_K);
extension:RegisterConstant("key", "l", "n", KEY_L);
extension:RegisterConstant("key", "m", "n", KEY_M);
extension:RegisterConstant("key", "n", "n", KEY_N);
extension:RegisterConstant("key", "o", "n", KEY_O);
extension:RegisterConstant("key", "p", "n", KEY_P);
extension:RegisterConstant("key", "q", "n", KEY_Q);
extension:RegisterConstant("key", "r", "n", KEY_R);
extension:RegisterConstant("key", "s", "n", KEY_S);
extension:RegisterConstant("key", "t", "n", KEY_T);
extension:RegisterConstant("key", "u", "n", KEY_U);
extension:RegisterConstant("key", "v", "n", KEY_V);
extension:RegisterConstant("key", "w", "n", KEY_W);
extension:RegisterConstant("key", "x", "n", KEY_X);
extension:RegisterConstant("key", "y", "n", KEY_Y);
extension:RegisterConstant("key", "z", "n", KEY_Z);

extension:RegisterConstant("key", "f1", "n", KEY_F1);
extension:RegisterConstant("key", "f2", "n", KEY_F2);
extension:RegisterConstant("key", "f3", "n", KEY_F3);
extension:RegisterConstant("key", "f4", "n", KEY_F4);
extension:RegisterConstant("key", "f5", "n", KEY_F5);
extension:RegisterConstant("key", "f6", "n", KEY_F6);
extension:RegisterConstant("key", "f7", "n", KEY_F7);
extension:RegisterConstant("key", "f8", "n", KEY_F8);
extension:RegisterConstant("key", "f9", "n", KEY_F9);
extension:RegisterConstant("key", "f10", "n", KEY_F10);
extension:RegisterConstant("key", "f11", "n", KEY_F11);
extension:RegisterConstant("key", "f12", "n", KEY_F12);

extension:RegisterConstant("key", "up", "n", KEY_UP);
extension:RegisterConstant("key", "left", "n", KEY_LEFT);
extension:RegisterConstant("key", "down", "n", KEY_DOWN);
extension:RegisterConstant("key", "right", "n", KEY_RIGHT);

extension:RegisterConstant("key", "left_control", "n", KEY_LCONTROL);
extension:RegisterConstant("key", "right_control", "n", KEY_RCONTROL);

extension:RegisterConstant("key", "left_alt", "n", KEY_LALT);
extension:RegisterConstant("key", "right_alt", "n", KEY_RALT);

extension:RegisterConstant("key", "left_shift", "n", KEY_LSHIFT);
extension:RegisterConstant("key", "right_shift", "n", KEY_RSHIFT);

extension:RegisterConstant("key", "left_bracket", "n", KEY_LBRACKET);
extension:RegisterConstant("key", "right_bracket", "n", KEY_RBRACKET);

extension:RegisterConstant("key", "semicolon", "n", KEY_SEMICOLON);
extension:RegisterConstant("key", "apostrophe", "n", KEY_APOSTROPHE);
extension:RegisterConstant("key", "backquote", "n", KEY_BACKQUOTE);
extension:RegisterConstant("key", "comma", "n", KEY_COMMA);
extension:RegisterConstant("key", "period", "n", KEY_PERIOD);
extension:RegisterConstant("key", "slash", "n", KEY_SLASH);
extension:RegisterConstant("key", "backslash", "n", KEY_BACKSLASH);
extension:RegisterConstant("key", "minus", "n", KEY_MINUS);
extension:RegisterConstant("key", "equal", "n", KEY_EQUAL);
extension:RegisterConstant("key", "enter", "n", KEY_ENTER);
extension:RegisterConstant("key", "space", "n", KEY_SPACE);
extension:RegisterConstant("key", "backspace", "n", KEY_BACKSPACE);
extension:RegisterConstant("key", "tab", "n", KEY_TAB);
extension:RegisterConstant("key", "capslock", "n", KEY_CAPSLOCK);
extension:RegisterConstant("key", "numlock", "n", KEY_NUMLOCK);
extension:RegisterConstant("key", "escape", "n", KEY_ESCAPE);
extension:RegisterConstant("key", "scrolllock", "n", KEY_SCROLLLOCK);
extension:RegisterConstant("key", "insert", "n", KEY_INSERT);
extension:RegisterConstant("key", "delete", "n", KEY_DELETE);
extension:RegisterConstant("key", "home", "n", KEY_HOME);
extension:RegisterConstant("key", "end", "n", KEY_END);
extension:RegisterConstant("key", "pageup", "n", KEY_PAGEUP);
extension:RegisterConstant("key", "pagedown", "n", KEY_PAGEDOWN);
extension:RegisterConstant("key", "break", "n", KEY_BREAK);

--[[
	Constants - numpad
]]

extension:RegisterLibrary("numpad");

extension:RegisterConstant("numpad", "zero", "n", KEY_PAD_0);
extension:RegisterConstant("numpad", "one", "n", KEY_PAD_1);
extension:RegisterConstant("numpad", "two", "n", KEY_PAD_2);
extension:RegisterConstant("numpad", "three", "n", KEY_PAD_3);
extension:RegisterConstant("numpad", "four", "n", KEY_PAD_4);
extension:RegisterConstant("numpad", "five", "n", KEY_PAD_5);
extension:RegisterConstant("numpad", "six", "n", KEY_PAD_6);
extension:RegisterConstant("numpad", "seven", "n", KEY_PAD_7);
extension:RegisterConstant("numpad", "eight", "n", KEY_PAD_8);
extension:RegisterConstant("numpad", "nine", "n", KEY_PAD_9);

extension:RegisterConstant("numpad", "divide", "n", KEY_PAD_DIVIDE);
extension:RegisterConstant("numpad", "multiply", "n", KEY_PAD_MULTIPLY);
extension:RegisterConstant("numpad", "minus", "n", KEY_PAD_MINUS);
extension:RegisterConstant("numpad", "plus", "n", KEY_PAD_PLUS);
extension:RegisterConstant("numpad", "enter", "n", KEY_PAD_ENTER);
extension:RegisterConstant("numpad", "decimal", "n", KEY_PAD_DECIMAL);

--[[

]]

extension:EnableExtension();