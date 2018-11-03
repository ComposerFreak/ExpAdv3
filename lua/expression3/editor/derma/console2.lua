/*============================================================================================================================================
	Oskar meet JavaScript, Java Script meet Oskar :D
============================================================================================================================================*/

local code = [[
	<HMTL>

		<style>

			.defleft {
				width:100px;
			};

			.defright {
				position:fixed;
				left: 100;
			};

		</style>

		<body>
			<div name = "E3_Left" style = "height:100%;width:100px;position:fixed;z-index:1;top:0;left:0;padding-top:20px;padding-left:5;">
			</div>

			<div name = "E3_Right" style = "height:100%;position:fixed;z-index:1;top:0;right:0;left:100;padding-top:20px;padding-left:5;">
			</div>

			<div name = "E3_Main" style = "height:100%;position:fixed;z-index:2;top:0;right:0;left:0;padding-top:20px;">

				<table id = "E3table" >
					<tr>
						<th class = "defleft" name = "E3_TLeft" ></th>
						<th class = "defright" name = "E3_TRight" ></th>
					</tr>
				</table>

			</div>
		</body>

		<script>

			var E3Console = { bufl : "", bufr : "" };
			var colleft = document.createElement('td');
			var colright = document.createElement('td');
			var table = document.getElementById("E3table");

			E3Console.default = {
				bgcolor : {
					left : function(c) {
						document.getElementsByName("E3_Left")[0].style.backgroundColor = c;
					}, right : function(c) {
						document.getElementsByName("E3_Right")[0].style.backgroundColor = c;
					}
				}, color : {
					left : function(c) {
						document.querySelector(".defleft").style.color = c;
					}, right : function(c) {
						document.querySelector(".defright").style.color = c;
					}
				}
			};

			E3Console.set = {
				bgcolor : {
					left : function(c) {
						colleft.style.backgroundColor = c;
					}, right : function(c) {
						colright.style.backgroundColor = c;
					}
				}, color : {
					left : function(c) {
						E3Console.colleft.style.color = c;
					}, right : function(c) {
						E3Console.colright.style.color = c;
					}
				}
			};

			E3Console.write = {
				left : function(str) {
					E3Console.bufl += str;
				}, right : function(str) {
					E3Console.bufr += str;
				}
			};

			E3Console.newLine = {
				left : function() {
					E3Console.write.left("<p>");
				}, right : function() {
					E3Console.write.right("<p>");
				}
			};

			E3Console.setSize = {
				left : function(s) {
					E3Console.write.left("<font size = \"" + s + "\" >");
				}, right : function(s) {
					E3Console.write.right("<font size = \"" + s + "\" >");
				}
			};

			E3Console.setFace = {
				left : function(f) {
					E3Console.write.left("<font face = \"" + f + "\" >");
				}, right : function(f) {
					E3Console.write.right("<font face = \"" + f + "\" >");
				}
			};

			E3Console.setColor = {
				left : function(c) {
					E3Console.write.left("<font color = \"" + c + "\" >");
				}, right : function(c) {
					E3Console.write.right("<font color = \"" + c + "\" >");
				}
			};

			E3Console.writeText = {
				left : function(s) {
					E3Console.write.left("<a>" + s + "</a>");
				}, right : function(s) {
					E3Console.write.right("<a>" + s + "</a>");
				}
			};

			E3Console.writeImage = {
				left : function(p, s) {
					if (s == null) s = 16;
					E3Console.write.left("<img src = \"" + p + "\" style = \"width:" + s + ";height:" + s + ";\" >");
				}, right : function(s) {
					if (s == null) s = 16;
					E3Console.write.right("<img src = \"" + p + "\" style = \"width:" + s + ";height:" + s + ";\" >");
				}
			};

			E3Console.beginCB = {
				left : function(f) {
					E3Console.write.left("<div onclick = \"" + f + "\" >")
				}, right : function(f) {
					E3Console.write.right("<div onclick = \"" + f + "\" >")
				}
			}

			E3Console.endCB = {
				left : function() {
					E3Console.write.left("</div>")
				}, right : function() {
					E3Console.write.right("</div>")
				}
			}

			E3Console.flush = function() {
				row = document.createElement('tr');

				colleft.className = "defleft";
				colright.className = "defright";

				colleft.innerHTML = E3Console.bufl;
				colright.innerHTML = E3Console.bufr;

				row.appendChild(colleft);
				row.appendChild(colright);
				table.appendChild(row);

				colleft = document.createElement('td');
				colright = document.createElement('td');

				E3Console.bufl = "";
				E3Console.bufr = "";
			};

	</script>

</html>
]]

local CONSOLE = { }

function CONSOLE:Init()

	self.fid = 0;
	self.mcache = {};

	self:Dock(FILL);
	self:SetHTML(code);
	self:SetAllowLua(true);
	self:SetDefaultTextColorL(0, 0, 0);
	self:SetDefaultTextColorL(255, 255, 255);
	self:SetDefaultBackGroundColorL(169,169,169);
	self:SetDefaultBackGroundColorR(128,128,128);

	self:Warn(1, "Warning Level 1 ", "test");
	self:Warn(2, "Warning Level 2 ", "test");
	self:Warn(3, "Warning Level 3 ", "test");
end

function CONSOLE:Write(where, line)
	self:Call( string.format("E3Console.write.%s(%q);", where, line) );
end

function CONSOLE:WriteNewLine(where)
	self:Call( string.format("E3Console.newLine.%s();", where) );
end

function CONSOLE:setSize(where, line)
	self:Call( string.format("E3Console.setSize.%s(%i);", where, size) );
end

function CONSOLE:setFontFace(where, face)
	self:Call( string.format("E3Console.setFace.%s(%q);", where, face) );
end

function CONSOLE:ColorToHext(col)
	return string.format("#%s%s%s", bit.tohex(col.r, 2), bit.tohex(col.g, 2), bit.tohex(col.b, 2));
end

function CONSOLE:SetColor(where, col)
	local color = self:ColorToHext(col)
	self:Call( string.format("E3Console.setColor.%s(%q);", where, color) );
end

function CONSOLE:WriteText(where, line)
	self:Call( string.format("E3Console.writeText.%s(%q);", where, line) );
end

function CONSOLE:ToBase64(path)
	if not file.Exists("materials\\" .. path, "GAME") then return path; end

	if self.mcache[path] then return self.mcache[path]; end

	local file = file.Open("materials\\" .. path, "rb", "GAME");

	local b64 = "data:image/jpeg;base64," .. util.Base64Encode( file:Read( file:Size() ) );

	file:Close();

	self.mcache[path] = b64;

	return b64;
end

function CONSOLE:WriteImage(where, path, size)
	self:Call( string.format("E3Console.writeImage.%s(%q, %i);", where, self:ToBase64(path), size or 16) );
end

function CONSOLE:BeginCB(where, func)
	if isfunction(func) then
		local id = self.fid + 1; self.fid = id;
		self:AddFunction("lua", "f" .. id, func);
		func = string.format("lua.f%i();", id);
	end

	self:Call( string.format("E3Console.beginCB.%s(%q);", where, func) );
end

function CONSOLE:EndCB(where)
	self:Call( string.format("E3Console.endCB.%s();", where) );
end

function CONSOLE:Flush(where)
	self:Call( "E3Console.flush()" );
end

function CONSOLE:WriteValues(where, values)
	local hascb = false;
	local tValues = #values;

	if (tValues > 1 and isfunction( values[1]) ) then
		hascb = true;	
		self:BeginCB(where, values[1] );
	end

	local start = (hascb and 2 or 1);

	for i = start, tValues do
		local value = values[i];

		if ( IsColor(value) ) then
			self:SetColor(where, value);
			continue;
		end

		if ( istable(value) ) then

			if (value.image) then
				self:WriteImage(where, value.image, value.size);
				continue;
			end

			if (value.font) then
				self:setFontFace(where, value.font);
			end

			if (value.size) then
				self:setSize(where, value.size);
			end

			if #value == 0 then continue; end

			self:WriteValues(where, value);
			continue;
		end

		value = tostring(value);

		local lines = string.Explode("\n", value);
		local tLines = #lines;

		for j = 1, tLines do
			self:Write(where, lines[j]);

			if tLines > 1 and j < tLines then
				self:WriteNewLine(where);
			end
		end
	end

	if (hascb) then
		self:EndCB(where);
	end
end

function CONSOLE:WriteLine(left, right, ...)
	local right = {right, ...};
	if not istable(left) then left = { left }; end

	self:WriteValues("left", left);
	self:WriteValues("right", right);

	self:Flush();
end

--[[

]]

function CONSOLE:SetBackGroundColorL(coloR, g, b)
	if g and b then coloR = Color(coloR, g, b); end
	if IsColor(coloR) then coloR = self:ColorToHext(coloR); end
	self:Call( string.format("E3Console.set.bgcolor.left(%q);", tostring(coloR)));
end

function CONSOLE:SetBackGroundColorR(coloR, g, b)
	if g and b then coloR = Color(coloR, g, b); end
	if IsColor(coloR) then coloR = self:ColorToHext(coloR); end
	self:Call( string.format("E3Console.set.bgcolor.right(%q);", tostring(coloR)));
end

--[[
	Utility Functions
]]

function CONSOLE:Warn(level, ...)
	local left = {};
	local right = {...};

	level = level or 0;
	
	if level == 1 then 
		left[1] = {image = "fugue/question.png", size = 16}
	elseif level == 2 then
		left[1] = {image = "fugue/exclamation-circle.png", size = 16}
	elseif level == 3 then 
		left[1] = {image = "fugue/exclamation-red.png", size = 16}
	end
	
	if level == 3 then
		self:SetBackGroundColorL(200, 50, 50);
		self:SetBackGroundColorR(200, 50, 50);
	end
	
	left[#left + 1] = Color(255, 255, 255);
	left[#left + 1] = "Warning";

	self:WriteLine(left, right)
end

--[[function CONSOLE:ConsoleMessage( msg )
	self:WriteLine("JavaScript", msg);
end]]

--[[
	Hi Oskar, have a little present :D
]]

function CONSOLE:SetDefaultBackGroundColorL(coloR, g, b)
	if g and b then coloR = Color(coloR, g, b); end
	if IsColor(coloR) then coloR = self:ColorToHext(coloR); end
	self:Call( string.format("E3Console.default.bgcolor.left(%q);", tostring(coloR)));
end

function CONSOLE:SetDefaultBackGroundColorR(coloR, g, b)
	if g and b then coloR = Color(coloR, g, b); end
	if IsColor(coloR) then coloR = self:ColorToHext(coloR); end
	self:Call( string.format("E3Console.default.bgcolor.right(%q);", tostring(coloR)));
end

function CONSOLE:SetDefaultTextColorL(coloR, g, b)
	if g and b then coloR = Color(coloR, g, b); end
	if IsColor(coloR) then coloR = self:ColorToHext(coloR); end
	self:Call( string.format("E3Console.default.color.left(%q);", tostring(coloR)));
end

function CONSOLE:SetDefaultTextColorR(coloR, g, b)
	if g and b then coloR = Color(coloR, g, b); end
	if IsColor(coloR) then coloR = self:ColorToHext(coloR); end
	self:Call( string.format("E3Console.default.color.right(%q);", tostring(coloR)));
end

vgui.Register("GOLEM_Console2", CONSOLE, "DHTML");