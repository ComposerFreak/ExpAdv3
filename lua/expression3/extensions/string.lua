--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____   
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J  
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L 
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  ( 
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J 
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F 

	::Advanced String Extension::
]]

local extention = EXPR_LIB.RegisterExtension("string");

extention:RegisterMethod("s", "char", "s", "n", 1, "string.char", true);

extention:RegisterMethod("s", "comma", "n", "s", 1, "string.Comma", true);

extention:RegisterMethod("s", "endsWith", "s,s", "b", 1, "string.EndsWith", true);

extention:RegisterMethod("s", "find", "s,s", "n", 2, function(a, b)
	local s, e = string.find(a, b, 1, true); -- No patterns
end, true);

extention:RegisterMethod("s", "find", "s,s,n", "n", 2, function(a, b, c)
	local s, e = string.find(a, b, c, true); -- No patterns
end, true);

extention:RegisterMethod("s", "find", "s,ptr", "n", 2, function(a, b)
	local s, e = string.find(a, b, 1); -- No patterns
end, true);

extention:RegisterMethod("s", "find", "s,ptr,n", "n", 2, function(a, b, c)
	local s, e = string.find(a, b, c); -- No patterns
end, true);

-- GetChar
-- GetExtensionFromFilename
-- gfind
-- 
-- gmatch
-- gsub
-- Implode
-- JavascriptSafe
-- Left
-- len
-- lower
-- match
-- NiceSize
-- NiceTime
-- PatternSafe
-- rep
-- Replace
-- reverse
-- Right
-- 
-- SetChar
-- Split
-- StartWith
-- StripExtension
-- sub
-- ToColor
-- ToMinutesSeconds
-- ToMinutesSecondsMilliseconds
-- ToTable
-- Trim
-- TrimLeft
-- TrimRight
-- upper