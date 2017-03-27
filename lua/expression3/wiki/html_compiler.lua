local w, h = 1000, 9999
local font = "Lucida Console"

EXPR_WIKI.COMPILER = {}

local types = {
	["_cls"]	=	"type",
	["_crf"]	=	"recipientfilter",
	["_e2t"]	=	"e2.table",
	["_er"]		=	"error",
	["_nil"]	=	"void",
	["_ptr"]	=	"patern",
	["_tr"]		=	"trace.ranger",
	["_trr"]	=	"trace.result",
	["_usmg"]	=	"stream",
	["_v2"]		=	"vector2",
	["_vr"]		=	"variant",
	["a"]		=	"angle",
	["b"]		=	"boolean",
	["c"]		=	"color",
	["e"]		=	"entity",
	["f"]		=	"function",
	["h"]		=	"hologram",
	["n"]		=	"number",
	["p"]		=	"player",
	["s"]		=	"string",
	["t"]		=	"table",
	["v"]		=	"vector",
	["..."]		=	"...",
}

--TODO: Fix this
--[[local types = {}

for k, v in pairs(EXPR_LIB.GetAllClasses()) do
	types[v.id] = v.name
end]]

local function getType(t)
	if types[t] then return types[t] end
	return "UnknownType"
end

function EXPR_WIKI.COMPILER.PrefabFunction(_side, _func, _args, _rtns, _lib)
	local data = {
		func = {
			side = _side,
			func = _func,
			lib = _lib
		}
	}
	
	_args = string.Replace(string.Replace(string.Replace(_args, "(", ""), ")", ""), " ", "")
	
	if _args != "" and _args != "_nil" then
		data.args = {}
		
		for k, v in pairs(string.Explode(",", _args)) do
			data.args[k] = {
				type = getType(v)
			}
		end
	end
	
	_rtns = string.Replace(string.Replace(string.Replace(_rtns, "(", ""), ")", ""), " ", "")
	
	if _rtns != "" and _rtns != "_nil" then
		data.rtns = {}
		
		for k, v in pairs(string.Explode(",", _rtns)) do
			data.rtns[k] = {
				type = getType(v)
			}
		end
	end
	
	return data
end

function EXPR_WIKI.COMPILER.PrefabOperator(_side, _func, _args, _rtns, _lib)
	local data = {
		func = {
			side = _side,
			lib = _lib
		}
	}
	
	_args = string.Replace(string.Replace(string.Replace(_args, "(", ""), ")", ""), " ", "")
	
	if _args != "" and _args != "_nil" then
		data.args = {}
		
		for k, v in pairs(string.Explode(",", _args)) do
			data.args[k] = {
				type = getType(v)
			}
		end
		
		if table.Count(data.args) == 3 then
			data.func.func = (data.args[1].type).." ? "..(data.args[2].type).." : "..(data.args[3].type)
		elseif table.Count(data.args) == 2 then
			data.func.func = (data.args[1].type).." ".._func.." "..(data.args[2].type)
		elseif table.Count(data.args) == 1 then
			data.func.func = _func..(data.args[1].type)
		end
	end
	
	_rtns = string.Replace(string.Replace(string.Replace(_rtns, "(", ""), ")", ""), " ", "")
	
	if _rtns != "" and _rtns != "_nil" then
		data.rtns = {}
		
		for k, v in pairs(string.Explode(",", _rtns)) do
			data.rtns[k] = {
				type = getType(v)
			}
		end
	end
	
	return data
end

------------------------------------------------------------------------------------------------
--------------------------------------------Function--------------------------------------------
------------------------------------------------------------------------------------------------

function EXPR_WIKI.COMPILER.Function(data)
	local name = data.name or "NoName"
	local func = data.func or nil
	local desc = data.desc or nil
	local args = data.args or nil
	local rtns = data.rtns or nil
	local exms = data.exms or nil
	
	local offset = 50
	
	--============================--
	--==html setup start		==--
	--============================--
	local html = [[
	<!doctype html>
	<html>
		<head>
			<title>]]..name..[[ - E3 Wiki</title>
		</head>
		<body background="http://i.imgur.com/2RcWmro.png">
			
	]]
	
	--============================--
	--==function				==--
	--============================--
	if func then
		--Containter
		html = html..[[
			<p id="function" style="
				border-radius: 5px;
				background: #A6A6A6;
				position: absolute;
				width: ]]..(w-100)..[[px;
				height: ]]..offset..[[px;
				top: 50px;
				left: 50px;
			">
		]]
		
		--Side (client, server, shared, unknown)
		local side = func.side or ""
		
		if side != "client" and side != "server" and side != "shared" then
			side = "unknown"
		end
		
		if side == "shared" then
			html = html..[[
				<p id="side" style="
					border-radius: 5px 0px 0px 5px;
					background: #f80;
					position: absolute;
					width: 10px;
					height: 20px;
					top: 65px;
					left: 65px;"
				>
				
				<p id="side_2" style="
					border-radius: 0px 5px 5px 0px;
					background: #08f;
					position: absolute;
					width: 10px;
					height: 20px;
					top: 65px;
					left: 75px;"
				>
			]]
		else
			local color = "#000"
			
			if side == "client" then color = "#f80"
			elseif side == "server" then color = "#08f" end
			
			html = html..[[
				<p id="side" style="
					border-radius: 5px;
					background: ]]..color..[[;
					position: absolute;
					width: 20px;
					height: 20px;
					top: 65px;
					left: 65px;"
				>
			]]
		end
		
		--function
		local funcName = func.func or "NoFuncName"
		
		local lib = ""
		
		if data.func.lib then
			lib = data.func.lib.."."
		end
		
		html = html..[[
			<p id="function_text" style="
				position: absolute;
				top: 67px;
				left: 95px;
				color: #000;
				font-weight: 500;
				font-family: ]]..font..[[;"
			>]]..lib..funcName.."("
		
		local arg = ""
		
		if args then
			local i = 0
			
			for k, v in pairs(args) do
				i = i+1
				
				local type = v.type or "NoType"
				local name = v.name or "NoName"
				
				arg = arg..type.." "..name
				
				if i != table.Count(args) then
					arg = arg..", "
				end
			end
		end
		
		html = html..arg..")</p>"
		
		offset = offset + 40
	end
	
	--============================--
	--==description				==--
	--============================--
	if desc then
		html = html..[[
			<p id="desc_head" style="
				position: absolute;
				top: ]]..offset..[[px;
				left: 50px;
				font-size: 60px;
				color: #000;"
			>Description</p>	
		]]
		
		offset = offset + 120
		
		local descData = string.Explode("\n", desc)
		
		for k, v in pairs(descData) do
			offset = offset+25
			
			--[[local f = string.find(v, "img(")
			local v2 = ""
			
			if f then
				local f2 = string.find(v, ")", f)
				
				if f2 then
					if f2 < #v then
						v2 = string.sub(v, f2, #v)
					end
					
					v = string.sub(v, 1, f)
				end
			end]]
			
			html = html..[[
				<p id="desc" style="
					position: absolute;
					top: ]]..offset..[[px;
					left: 75px;
					font-size: 20px;
					color: #000;"
				>]]..v..[[</p>
			]]
		end
		
		offset = offset + 50
	end
	
	--============================--
	--==arguments				==--
	--============================--
	if args then
		local i = 0
		
		html = html..[[
			<p id="arg_head" style="
				position: absolute;
				top: ]]..offset..[[px;
				left: 50px;
				font-size: 60px;
				color: #000;"
			>Arguments</p>
		]]
		
		offset = offset + 50
		
		for k, v in pairs(args) do
			i = i+1
			offset = offset + 80
			
			local type = v.type or "NoType"
			local name = v.name or "NoName"
			local desc = v.desc or "NoDescription"
			
			html = html..[[
				<p id="arg_num" style="
					border-radius: 3px;
					background: #333;
					position: absolute;
					top: ]]..offset..[[px;
					left: 75px;
					font-size: 15px;
					color: #fff;
					padding: 1px 6px;"
				>]]..i..[[</p>
				
				<p id="arg_desk" style="
					position: absolute;
					top: ]]..(16 + offset)..[[px;
					left: 100px;
					font-size: 20px;
					color: #000;"
				>]]..desc..[[</p>
				
				<p id="arg_txt" style="
					position: absolute;
					top: ]]..(offset - 20)..[[px;
					left: 100px;
					font-size: 25px;
					color: #000;"
				>]]..type.." "..name..[[</p>
				
				<p id="arg_txt_varb" style="
					position: absolute;
					top: ]]..(offset - 20)..[[px;
					left: 100px;
					font-size: 25px;
					color: #DA3700;"
				>]]..type..[[</p>
			]]
		end
		
		offset = offset + 50
	end
	
	--============================--
	--==returns					==--
	--============================--
	if rtns then
		local i = 0
		
		html = html..[[
			<p id="rtn_head" style="
				position: absolute;
				top: ]]..offset..[[px;
				left: 50px;
				font-size: 60px;
				color: #000;"
			>Returns</p>
		]]
		
		offset = offset + 50
		
		for k, v in pairs(rtns) do
			i = i+1
			offset = offset + 80
			
			local type = v.type or "NoType"
			local desc = v.desc or "NoDescription"
			
			html = html..[[
				<p id="rtn_num" style="
					border-radius: 3px;
					background: #333;
					position: absolute;
					top: ]]..offset..[[px;
					left: 75px;
					font-size: 15px;
					color: #fff;
					padding: 1px 6px;"
				>]]..i..[[</p>
				
				<p id="rtn_desk" style="
					position: absolute;
					top: ]]..(16 + offset)..[[px;
					left: 100px;
					font-size: 20px;
					color: #000;"
				>]]..desc..[[</p>
				
				<p id="rtn_txt" style="
					position: absolute;
					top: ]]..(offset - 20)..[[px;
					left: 100px;
					font-size: 25px;
					color: #DA3700;"
				>]]..type..[[</p>
			]]
		end
	end
	
	--============================--
	--==html setup end			==--
	--============================--
	local html = html..[[
		</body>
	</html>
	]]
	
	return html
end

------------------------------------------------------------------------------------------------
--------------------------------------------Operator--------------------------------------------
------------------------------------------------------------------------------------------------

function EXPR_WIKI.COMPILER.Operator(data)
	local name = data.name or "NoName"
	local func = data.func or nil
	local desc = data.desc or nil
	local rtns = data.rtns or nil
	local exms = data.exms or nil
	local lib = data.lib or ""
	
	local offset = 50
	
	--============================--
	--==html setup start		==--
	--============================--
	local html = [[
	<!doctype html>
	<html>
		<head>
			<title>]]..name..[[ - E3 Wiki</title>
		</head>
		<body background="http://i.imgur.com/2RcWmro.png">
			
	]]
	
	--============================--
	--==function				==--
	--============================--
	if func then
		--Containter
		html = html..[[
			<p id="function" style="
				border-radius: 5px;
				background: #A6A6A6;
				position: absolute;
				width: ]]..(w-100)..[[px;
				height: ]]..offset..[[px;
				top: 50px;
				left: 50px;
			">
		]]
		
		--Side (client, server, shared, unknown)
		local side = func.side or ""
		
		if side != "client" and side != "server" and side != "shared" then
			side = "unknown"
		end
		
		if side == "shared" then
			html = html..[[
				<p id="side" style="
					border-radius: 5px 0px 0px 5px;
					background: #f80;
					position: absolute;
					width: 10px;
					height: 20px;
					top: 65px;
					left: 65px;"
				>
				
				<p id="side_2" style="
					border-radius: 0px 5px 5px 0px;
					background: #08f;
					position: absolute;
					width: 10px;
					height: 20px;
					top: 65px;
					left: 75px;"
				>
			]]
		else
			local color = "#000"
			
			if side == "client" then color = "#f80"
			elseif side == "server" then color = "#08f" end
			
			html = html..[[
				<p id="side" style="
					border-radius: 5px;
					background: ]]..color..[[;
					position: absolute;
					width: 20px;
					height: 20px;
					top: 65px;
					left: 65px;"
				>
			]]
		end
		
		--function
		local funcName = func.func or "NoFuncName"
		
		html = html..[[
			<p id="function_text" style="
				position: absolute;
				top: 65px;
				left: 95px;
				color: #000;
				font-weight: 500;
				font-family: ]]..font..[[;"
			>]]..lib.."."..funcName.."</p>"
		
		offset = offset + 40
	end
	
	--============================--
	--==description				==--
	--============================--
	if desc then
		html = html..[[
			<p id="desc_head" style="
				position: absolute;
				top: ]]..offset..[[px;
				left: 50px;
				font-size: 60px;
				color: #000;"
			>Description</p>	
		]]
		
		offset = offset + 120
		
		local descData = string.Explode("\n", desc)
		
		for k, v in pairs(descData) do
			offset = offset+25
			
			--[[local f = string.find(v, "img(")
			local v2 = ""
			
			if f then
				local f2 = string.find(v, ")", f)
				
				if f2 then
					if f2 < #v then
						v2 = string.sub(v, f2, #v)
					end
					
					v = string.sub(v, 1, f)
				end
			end]]
			
			html = html..[[
				<p id="desc" style="
					position: absolute;
					top: ]]..offset..[[px;
					left: 75px;
					font-size: 20px;
					color: #000;"
				>]]..v..[[</p>
			]]
		end
		
		offset = offset + 50
	end
	
	--============================--
	--==returns					==--
	--============================--
	if rtns then
		local i = 0
		
		html = html..[[
			<p id="rtn_head" style="
				position: absolute;
				top: ]]..offset..[[px;
				left: 50px;
				font-size: 60px;
				color: #000;"
			>Returns</p>
		]]
		
		offset = offset + 50
		
		for k, v in pairs(rtns) do
			i = i+1
			offset = offset + 80
			
			local type = v.type or "NoType"
			local desc = v.desc or "NoDescription"
			
			html = html..[[
				<p id="rtn_num" style="
					border-radius: 3px;
					background: #333;
					position: absolute;
					top: ]]..offset..[[px;
					left: 75px;
					font-size: 15px;
					color: #fff;
					padding: 1px 6px;"
				>]]..i..[[</p>
				
				<p id="rtn_desk" style="
					position: absolute;
					top: ]]..(16 + offset)..[[px;
					left: 100px;
					font-size: 20px;
					color: #000;"
				>]]..desc..[[</p>
				
				<p id="rtn_txt" style="
					position: absolute;
					top: ]]..(offset - 20)..[[px;
					left: 100px;
					font-size: 25px;
					color: #DA3700;"
				>]]..type..[[</p>
			]]
		end
	end
	
	--============================--
	--==html setup end			==--
	--============================--
	local html = html..[[
		</body>
	</html>
	]]
	
	return html
end