

E3_TOKENS = { };
E3_KEYWORDS = {};
E3_PATTERNS = {};
E3_PARSERDATA = {};
E3_PARSEFUNCS = {};

function E3_RegisterToken(token, type, desc)
	E3_TOKENS[type] = {token, desc};
end

function E3_RegisterKeyWord(word, name, desc)
	E3_KEYWORDS[name] = {word, desc};
end

function E3_RegisterTokenFunction(name, func, desc)
	local raw = (type(func) == "string");
	E3_PATTERNS[name] = {func, desc, raw};
end

function E3_RegisterSyntax(instruction, ast, compileFunc, desc)
	local ok, res, p = E3_ASTSYNTAX(ast, desc);
	
	if not ok then
		print("invalid ast \"" .. instruction .. "\" " .. tostring(res))
		print("'" .. ast .. "'");
		return;
	end

	E3_PARSERDATA[instruction] = {res, compileFunc, desc};
end

function E3_RegisterSyntaxFunction(name, func)
	E3_PARSEFUNCS[name] = func;
end

function E3_COMPILESCRIPT(script)
	local compiler = E3_SCRIPTPARSER.New(E3_TOKENS, E3_KEYWORDS, E3_PATTERNS, E3_PARSEFUNCS, E3_PARSERDATA);

	compiler:Init(script);

	return compiler;
end

include("ast_parser.lua");

include("script_parser.lua");

include("e3_funcs.lua");

include("e3_lang.lua");


local script = [[string var = 22]]

local compiler = E3_COMPILESCRIPT(script);

local ok, status, result = compiler:Run();

print("----------------------------------------------------------");
print("LEXER Result: ", ok, status, result);
if istable(result) then print("result"); PrintTable(result or status); end
if istable(status) then print("status"); PrintTable(status); end
print("----------------------------------------------------------");