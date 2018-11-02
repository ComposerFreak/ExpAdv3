/*============================================================================================================================================
	Oskar meet JavaScript, Java Script meet Oskar :D
============================================================================================================================================*/

local code = [[
	<HMTL>

		<body>

			<div name = "E3_Left" style = "height:100%;width:100px;position:fixed;z-index:1;top:0;left:0;padding-top:20px;padding-left:5;background-color:rgb(50,50,50);">
			</div>

			<div name = "E3_Right" style = "height:100%;position:fixed;z-index:1;top:0;right:0;left:100;padding-top:20px;padding-left:5;background-color:rgb(25,25,25);">
			</div>

			<div name = "E3_Main" style = "height:100%;position:fixed;z-index:2;top:0;right:0;left:0;padding-top:20px;;">

				<table id = "E3table">
					<tr>
						<th style = "width:100px;"></th>
						<th></th>
					</tr>
				</table>

			</div>

		</body>

			<script>
				var E3Console = {};
				E3Console.table = document.getElementById("E3table");

				E3Console.WriteLine = function(left, right) {
					row = document.createElement('tr');
					
					col1 = document.createElement('td');
					col1.innerHTML = left;
					row.appendChild(col1);

					col2 = document.createElement('td');
					col2.innerHTML = right;
					row.appendChild(col2);

					E3Console.table.appendChild(row);
				};

			</script>

	</html>

]]

local CONSOLE = { }

function CONSOLE:Init()
	self.nFunc = 0;
	self.sLeft = {};
	self.sRight = {};
	self:Dock(FILL);
	self:SetHTML(code);
end

function CONSOLE:WriteLeft(line, fst, ...)
	if fst then line = string.format(line, fst, ...); end
	self.sLeft[#self.sLeft + 1] = line;
end

function CONSOLE:WriteRight(line, fst, ...)
	if fst then line = string.format(line, fst, ...); end
	self.sRight[#self.sRight + 1] = line;
end

function CONSOLE:Flush()
	local left = table.concat(self.sLeft, "");
	local right = table.concat(self.sRight, "");

	self.sLeft = {};
	self.sRight = {};

	self:Call( string.format("E3Console.WriteLine(%q, %q)", left, right) );
end

function CONSOLE:SetColorLeft(col)
	self:WriteLeft([[<font color = "rgb(%i,%i,%i);">]], col.r, col.g, col.b);
end

function CONSOLE:SetColorRight(col)
	self:WriteRight([[<font color = "rgb(%i,%i,%i);">]], col.r, col.g, col.b);
end

function CONSOLE:SetFontLeft(size, face, color)
	if size then self:WriteLeft([[<font size = "%i">]], size); end
	if face then self:WriteLeft([[<font size = "%s">]], face); end
	if color then self:SetColorLeft(color) end
end

function CONSOLE:SetFontRight(size, face, color)
	if size then self:WriteRight([[<font size = "%i">]], size); end
	if face then self:WriteRight([[<font size = "%s">]], face); end
	if color then self:SetColorRight(color) end
end

function CONSOLE:NewLineLeft()
	self:WriteLeft([[<p>]]);
end

function CONSOLE:NewLineRight()
	self:WriteLeft([[<p>]]);
end

function CONSOLE:WriteLine(left, ...)
	local right = {...};
	if not istable(left) then left = {left}; end

	for i = 1, #left do
		local v = left[i];
		if istable(v) then
			self:SetColorLeft(v);
			continue;
		end

		local lines = string.Explode("\n", tostring(v));
		local newlines = #lines;

		for j = 1, newlines do
			self:WriteLeft(lines[j])
			if newlines > 1 and j < newlines then self:NewLineLeft(); end
		end
	end

	for i = 1, #right do
		local v = right[i];
		if istable(v) then
			self:SetColorRight(v);
			continue;
		end

		local lines = string.Explode("\n", tostring(v));
		local newlines = #lines;

		for j = 1, newlines do
			self:WriteRight(lines[j])
			if newlines > 1 and j < newlines then self:NewLineRight(); end
		end
	end

	self:Flush();
end

vgui.Register("GOLEM_Console2", CONSOLE, "DHTML");