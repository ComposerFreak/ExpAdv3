--[[
	   ____      _  _      ___    ___       ____      ___      ___     __     ____      _  _          _        ___     _  _       ____
	  F ___J    FJ  LJ    F _ ", F _ ",    F ___J    F __".   F __".   FJ    F __ ]    F L L]        /.\      F __".  FJ  L]     F___ J
	 J |___:    J \/ F   J `-' |J `-'(|   J |___:   J (___|  J (___|  J  L  J |--| L  J   \| L      //_\\    J |--\ LJ |  | L    `-__| L
	 | _____|   /    \   |  __/F|  _  L   | _____|  J\___ \  J\___ \  |  |  | |  | |  | |\   |     / ___ \   | |  J |J J  F L     |__  (
	 F L____:  /  /\  \  F |__/ F |_\  L  F L____: .--___) \.--___) \ F  J  F L__J J  F L\\  J    / L___J \  F L__J |J\ \/ /F  .-____] J
	J________LJ__//\\__LJ__|   J__| \\__LJ________LJ\______JJ\______JJ____LJ\______/FJ__L \\__L  J__L   J__LJ______/F \\__//   J\______/F
	|________||__/  \__||__L   |__|  J__||________| J______F J______F|____| J______F |__L  J__|  |__L   J__||______F   \__/     J______F

	::Time Extention::
]]


local extension = EXPR_LIB.RegisterExtension("time");

--[[
	Time Stamp Object
]]

local function timestamp(from, utc)
	return os.date(utc and "!*t" or "*t", from or os.time());
end

extension:RegisterClass("ts", {"date"}, istable, EXPR_LIB.NOTNIL);

extension:RegisterConstructor("ts", "", function()
	return {year = 0, month = 0, day = 0, hour = 0, min = 0, sec = 0, isdst = false};
end, true);

extension:RegisterConstructor("ts", "n", timestamp, true);
extension:RegisterConstructor("ts", "n,b", timestamp, true);

extension:RegisterConstructor("ts", "b", function(utc)
	return os.date(utc and "!*t" or "*t", os.time());
end, true);

--[[
	Attributes
]]

extension:RegisterAttribute("ts", "year", "n", "year");
extension:RegisterAttribute("ts", "month", "n", "month");
extension:RegisterAttribute("ts", "day", "n", "day");

extension:RegisterAttribute("ts", "hour", "n", "hour");
extension:RegisterAttribute("ts", "minute", "n", "min");
extension:RegisterAttribute("ts", "second", "n", "sec");

--[[
	Time Stamp Methods
]]

extension:RegisterMethod("ts", "getYear", "", "n", 1, function(ts, v) return ts.year; end, true);
extension:RegisterMethod("ts", "getMonth", "", "n", 1, function(ts, v) return ts.month; end, true);
extension:RegisterMethod("ts", "getDay", "", "n", 1, function(ts, v) return ts.day; end, true);

extension:RegisterMethod("ts", "getHour", "", "n", 1, function(ts, v) return ts.hour; end, true);
extension:RegisterMethod("ts", "getMinute", "", "n", 1, function(ts, v) return ts.min; end, true);
extension:RegisterMethod("ts", "getSecond", "", "n", 1, function(ts, v) return ts.sec; end, true);

extension:RegisterMethod("ts", "setYear", "n", "", 0, function(ts, v) ts.year = v; end, true);
extension:RegisterMethod("ts", "setMonth", "n", "", 0, function(ts, v) ts.month = v; end, true);
extension:RegisterMethod("ts", "setDay", "n", "", 0, function(ts, v) ts.day = v; end, true);

extension:RegisterMethod("ts", "setHour", "n", "", 0, function(ts, v) ts.hour = v; end, true);
extension:RegisterMethod("ts", "setMinute", "n", "", 0, function(ts, v) ts.min = v; end, true);
extension:RegisterMethod("ts", "setSecond", "n", "", 0, function(ts, v) ts.sec = v; end, true);

extension:RegisterMethod("ts", "setTime", "n,n,n", "", 0, function(ts, hour, min, sec)
	ts.hour = hour;
	ts.min = min;
	ts.sec = sec;
end, true);

extension:RegisterMethod("ts", "setDate", "n,n,n", "", 0, function(ts, day, month, year)
	obj.day = day;
	obj.month = month;
	obj.year = year;
end, true);

--[[
	Time Library
]]

extension:RegisterLibrary("time");

extension:RegisterFunction("time", "curtime", "", "n", 1, CurTime, true);

extension:RegisterFunction("time", "realtime", "", "n", 1, RealTime, true);

extension:RegisterFunction("time", "systime", "", "n", 1, SysTime, true);


extension:RegisterFunction("time", "now", "", "n", 1, os.time, true);

extension:RegisterFunction("time", "now", "ts", "n", 1, function(ts)
	return os.time(ts or {});
end, true);

--[[
]]

extension:EnableExtension();
