if SERVER then return; end

EXPR_DOCS = {};

/*********************************************************************************
	CSV Object
*********************************************************************************/

local oCSV = {};

oCSV.__index = oCSV;

function EXPR_DOCS.CSV(pk, ...)
	local csv = {headers = {...}, data = {}, lk = {}, clk = {}, pk = pk};
	
	setmetatable(csv, oCSV);

	return csv;
end

function oCSV:insert(ow, values)

	if not self.data then self.data = {}; end

	local i = #self.data + 1;

	if self.pk then

		local key = values[self.pk];

		if key and key ~= "" then

			i = self.lk[key] or i;

			local current = self.data[i];

			if current then

				if ow then

					if not ow(self.pk, current, values) then

						return false;

					end

				end
			end

			self.lk[key] = i;

			self.clk[key] = i;
		end

	end

	self.data[i] = values;
end

function oCSV:add(...)
	self:insert(nil, {...});
end

local function ow(pk, current, new)
	for i = 1, #current do
		local cur = current[i];
		if cur and cur ~= "" then new[i] = cur; end
	end

	return true;
end

function oCSV:MergeBlankValues(with)
	if with and with.data then
		for i = 1, #with.data do
			oCSV:insert(ow, with.data[i]);
		end
	end
end

function oCSV:FromKV(keyvalues)

	if self.headers then

		local res = {};

		for i = 1, #self.headers do

			local key = self.headers[i];

			local value = keyvalues[key] or "";

			res[i] = value;
		end

		return res;

	end

	return {};
end

function oCSV:ToKV(values)
	
	if self.headers then

		local res = {};

		for i = 1, #self.headers do

			local key = self.headers[i];

			local value = values[i] or "";

			res[key] = value;
		end

		return res;

	end

	return {};

end

function oCSV:ForEach(fun)
	if self.data then
		for i = 1, #self.data do
			fun(i, self:ToKV(self.data[i]));
		end
	end
end

/*********************************************************************************
	Load CSV
*********************************************************************************/
function EXPR_DOCS.CSVFromString(str, pk)
	local result = EXPR_DOCS.CSV(pk);

	if str and str ~= "" then

		local rows = string.Explode("\n", str);

		local total = #rows;

		pk = pk or 1;

		if total >= 1 then
			result.headers = string.Explode("\t", rows[1]);
		end

		if total >= 2 then

			for i = 2, total do
				local values = string.Explode("\t", rows[i]);

				if pk then
					local key = values[pk];

					if key and key ~= "" then 
						result.lk[key] = i - 1;
					end
				end

				result.data[i - 1] = values;
			end

		end
	end

	return result;
end

function EXPR_DOCS.loadCSV(filename, path, pk)
	local str = "";
	local fl = file.Open(filename, "r", path or "DATA");

	if fl then
		str = fl:Read(fl:Size());

		fl:Close();
	end

	return EXPR_DOCS.CSVFromString(str, pk);
end

/*********************************************************************************
	Write CSV
*********************************************************************************/
function EXPR_DOCS.CSVToString(csv)
	local lines = {""};

	if csv.headers then
		lines[1] = table.concat(csv.headers, "\t");
	end

	if csv.data then
		
		local total = #csv.data;

		for i = 1, total do
			lines[i + 1] = table.concat(csv.data[i], "\t");
		end
	end 

	return table.concat(lines, "\n");
end

function EXPR_DOCS.saveCSV(csv, filename, path)
	local fl = file.Open(filename, "w", path or "DATA");

	if fl then
		fl:Write( EXPR_DOCS.CSVToString(csv) );

		fl:Close();
	end
end

/*********************************************************************************
	Create data foler
*********************************************************************************/

file.CreateDir("e3docs");
file.CreateDir("e3docs/csv");

/*********************************************************************************
	Types
*********************************************************************************/
do
	local filename = "types.txt"

	local docs = EXPR_DOCS.CSV(1, "id", "name", "extends", "desc", "example");

	function EXPR_DOCS.GetTypeDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeType(keyvalues)
		docs:insert(ow, docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultTypeDocs()
		for _, data in pairs( EXPR_CLASSES ) do
			EXPR_DOCS.DescribeType({
				["id"] = data.id,
				["name"] = data.name,
				["extends"] = data.base,
				["desc"] = "",
			});
		end

		docs.clk = {};
	end

	function EXPR_DOCS.LoadDefaultTypeDocs()

		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("%s/lua/expression3/helper/csv/%s",EXPR_ROOT, filename), "GAME", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalTypeDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("e3docs/csv/%s", filename), "DATA", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalTypeDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs/csv/%s", filename), "DATA")
	end

end

/*********************************************************************************
	Constructors
*********************************************************************************/
do
	local filename = "constructors.txt"

	local docs = EXPR_DOCS.CSV(1, "signature", "id", "name", "parameter", "result type", "result count", "state", "desc", "example");

	function EXPR_DOCS.GetConstructorDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeConstructor(keyvalues)
		docs:insert(ow, docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultConstructorDocs()

		for _, cls in pairs( EXPR_CLASSES ) do
			
			if cls.constructors then

				for _, op in pairs(cls.constructors) do
					EXPR_DOCS.DescribeConstructor({
						["signature"] = op.signature,
						["id"] = cls.id,
						["name"] = cls.name,
						["parameter"] = op.parameter,
						["result type"] = op.result,
						["result count"] = op.rCount,
						["state"] = op.state,
						["desc"] = "",
					});
				end

			end

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultConstructorDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("%s\\docs\\%s",EXPR_ROOT, filename), "GAME", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalConstructorDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("e3docs\\csv\\%s", filename), "DATA", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalConstructorDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs\\csv\\%s", filename), "DATA")
	end

end

/*********************************************************************************
	Attributes
*********************************************************************************/
do
	local filename = "attributes.txt"

	local docs = EXPR_DOCS.CSV(1, "signature", "id", "name", "type", "desc");

	function EXPR_DOCS.GetAttributeDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeAttribute(keyvalues)
		local id, name = keyvalues.id, keyvalues.name;
		if id and name then keyvalues.signature = keyvalues.signature or (id .. "." .. name); end
		docs:insert(ow, docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultAttributeDocs()

		for _, cls in pairs( EXPR_CLASSES ) do
			
			if cls.atributes then

				for _, op in pairs(cls.atributes) do
					EXPR_DOCS.DescribeAttribute({
						["signature"] = cls.id .. "." .. op.atribute,
						["id"] = cls.id,
						["name"] = op.atribute,
						["type"] = op.class,
						["desc"] = "",
					});
				end

			end

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultAttributeDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("%s\\docs\\%s",EXPR_ROOT, filename), "GAME", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalAttributeDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("e3docs\\csv\\%s", filename), "DATA", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalAttributeDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs\\csv\\%s", filename), "DATA")
	end

end

/*********************************************************************************
	Methods
*********************************************************************************/

do
	local filename = "methods.txt"

	local docs = EXPR_DOCS.CSV(1, "signature", "id", "name", "parameter", "result type", "result count", "state", "desc", "example");

	function EXPR_DOCS.GetMethodDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeMethod(keyvalues)
		docs:insert(ow, docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultMethodDocs()

		for _, op in pairs( EXPR_METHODS ) do
				
			EXPR_DOCS.DescribeMethod({
				["signature"] = op.signature,
				["id"] = op.class,
				["name"] = op.name,
				["parameter"] = op.parameter,
				["result type"] = op.result,
				["result count"] = op.rCount,
				["state"] = op.state,
				["desc"] = "",
			});

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultMethodDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("%s\\docs\\%s",EXPR_ROOT, filename), "GAME", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalMethodDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("e3docs\\csv\\%s", filename), "DATA", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalMethodDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs\\csv\\%s", filename), "DATA")
	end

end

/*********************************************************************************
	Operators
*********************************************************************************/

do
	local filename = "operators.txt"

	local docs = EXPR_DOCS.CSV(1, "signature", "name", "parameter", "result type", "result count", "state", "desc", "example");

	function EXPR_DOCS.GetOperatorDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeOperator(keyvalues)
		docs:insert(ow, docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultOperatorDocs()

		for _, op in pairs( EXPR_OPERATORS ) do
				
			EXPR_DOCS.DescribeOperator({
				["signature"] = op.signature,
				["name"] = op.name,
				["parameter"] = op.parameter,
				["result type"] = op.result,
				["result count"] = op.rCount,
				["state"] = op.state,
				["desc"] = "",
			});

		end

		for _, op in pairs( EXPR_CAST_OPERATORS ) do

			EXPR_DOCS.DescribeOperator({
				["signature"] = op.signature,
				["name"] = op.name,
				["parameter"] = op.parameter,
				["result type"] = op.result,
				["result count"] = op.rCount,
				["state"] = op.state,
				["desc"] = "",
			});

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultOperatorDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("%s\\docs\\%s",EXPR_ROOT, filename), "GAME", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalOperatorDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("e3docs\\csv\\%s", filename), "DATA", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalOperatorDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs\\csv\\%s", filename), "DATA")
	end

end

/*********************************************************************************
	Libraries
*********************************************************************************/

do
	local filename = "librarys.txt"

	local docs = EXPR_DOCS.CSV(1, "name", "desc");

	function EXPR_DOCS.GetLibraryDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeLibrary(keyvalues)
		docs:insert(ow, docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultLibraryDocs()
		
		for _, op in pairs( EXPR_LIBRARIES ) do
				
			EXPR_DOCS.DescribeLibrary({
				["name"] = op.name,
				["desc"] = "",
			});

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultLibraryDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("%s\\docs\\%s",EXPR_ROOT, filename), "GAME", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalLibraryDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("e3docs\\csv\\%s", filename), "DATA", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalLibraryDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs\\csv\\%s", filename), "DATA")
	end

end


/*********************************************************************************
	Functions
*********************************************************************************/

do
	local filename = "functions.txt"

	local docs = EXPR_DOCS.CSV(1, "signature", "library", "name", "parameter", "result type", "result count", "state", "desc", "example");

	function EXPR_DOCS.GetFunctionDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeFunction(keyvalues)
		docs:insert(ow, docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultFunctionDocs()
		
		for _, lib in pairs( EXPR_LIBRARIES ) do
			
			for __, op in pairs(lib._functions)	do
				EXPR_DOCS.DescribeFunction({
					["signature"] = op.signature,
					["library"] = lib.name,
					["name"] = op.name,
					["parameter"] = op.parameter,
					["result type"] = op.result,
					["result count"] = op.rCount,
					["state"] = op.state,
					["desc"] = "",
				});
			end

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultFunctionDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("%s\\docs\\%s",EXPR_ROOT, filename), "GAME", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalFunctionDocs()
		docs:MergeBlankValues(
			EXPR_DOCS.loadCSV(string.format("e3docs\\csv\\%s", filename), "DATA", 1)
		);

		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalFunctionDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs\\csv\\%s", filename), "DATA")
	end

end

/*********************************************************************************
	Load custom docs files
*********************************************************************************/

do

	local LoadCustomDocFile = function(str)

		if str and str ~= "" then

			local lk = {
				TYPE = EXPR_DOCS.GetTypeDocs(),
				CONSTRUCTOR = EXPR_DOCS.GetConstructorDocs(),
				ATTRIBUTE = EXPR_DOCS.GetAttributeDocs(),
				METHOD = EXPR_DOCS.GetMethodDocs(),
				OPERATOR = EXPR_DOCS.GetOperatorDocs(),
				LIBRARY = EXPR_DOCS.GetLibraryDocs(),
				FUNCTION = EXPR_DOCS.GetFunctionDocs(),
			};

			local csv;

			local rows = string.Explode("\n", str);

			local total = #rows;

			if total >= 1 then

				for i = 1, total do
					local value = rows[i];

					local match = string.match(value, "^#([A-Za-z]+)$");

					if match then
						csv = lk[match:upper()];

						if not csv then
							return false, "Invalid refrence \"#" .. match .. "\"";
						end
					end

					if not csv then
						return false, "No refrence set \"#FUNCTION\"";
					end

					local values = string.Explode("\t", value);

					if csv.pk then
						local key = values[csv.pk];

						if key and key ~= "" then 
							csv.lk[key] = i - 1;
						end
					end

					csv.data[i - 1] = values;
				end

			end
		end

		return true;
	end;

	function EXPR_DOCS.LoadCustomDocFile(filename)
		local raw = file.Read(filename, "GAME");

		local ok, err = LoadCustomDocFile(raw);

		if not ok then
			MsgN("[E3] Error loading custom helper data:");
			MsgN("Error: ", err);
			MsgN("File: ", filename);
		end
	end

	local path = "lua/expression3/helper/custom/";

	function EXPR_DOCS.LoadCustomDocs()
		local files = file.Find(path .. "*.txt", "GAME");

		for i, filename in pairs( files ) do
			EXPR_DOCS.LoadCustomDocFile(path .. filename);
		end
	end

end

/*********************************************************************************
	Save custom docs files
*********************************************************************************/
do
	function EXPR_DOCS.ChangedDocs()

		local function write(csv)
			local a = {};

			for k, i in pairs(csv.clk) do
				table.insert(a, table.concat(csv.data[i], "\t"));
			end

			csv.clk = {};

			return table.concat(a, "\n");
		end

		return table.concat({
			"#Type", write(EXPR_DOCS.GetTypeDocs()),
			"#Constructor", write(EXPR_DOCS.GetConstructorDocs()),
			"#Attribute", write(EXPR_DOCS.GetAttributeDocs()),
			"#Method", write(EXPR_DOCS.GetMethodDocs()),
			"#Operator", write(EXPR_DOCS.GetOperatorDocs()),
			"#Library", write(EXPR_DOCS.GetLibraryDocs()),
			"#Function", write(EXPR_DOCS.GetFunctionDocs()),
		}, "\n");

	end

	function EXPR_DOCS.SaveChangedDocs(filename)

		local path = string.format("e3docs\\csv\\%s", filename);

		local fl = file.Open(path, "w", "DATA");

		if fl then
			fl:Write( EXPR_DOCS.ChangedDocs() );

			fl:Close();
		end
	end

end

/*********************************************************************************
	Generate default Docs
*********************************************************************************/
function EXPR_DOCS.GenerateDefaults()
	print("E3 - Generating Default Helper Data.");
	EXPR_DOCS.GenerateDefaultTypeDocs();
	EXPR_DOCS.GenerateDefaultConstructorDocs();
	EXPR_DOCS.GenerateDefaultAttributeDocs();
	EXPR_DOCS.GenerateDefaultMethodDocs();
	EXPR_DOCS.GenerateDefaultOperatorDocs();
	EXPR_DOCS.GenerateDefaultLibraryDocs();
	EXPR_DOCS.GenerateDefaultFunctionDocs();
end

/*********************************************************************************
	Load Local Docs
*********************************************************************************/
function EXPR_DOCS.LoadLocalDocs()
	print("E3 - Loading Local Helper Data.");
	EXPR_DOCS.LoadLocalTypeDocs();
	EXPR_DOCS.LoadLocalConstructorDocs();
	EXPR_DOCS.LoadLocalAttributeDocs();
	EXPR_DOCS.LoadLocalMethodDocs();
	EXPR_DOCS.LoadLocalOperatorDocs();
	EXPR_DOCS.LoadLocalLibraryDocs();
	EXPR_DOCS.LoadLocalFunctionDocs();
end

/*********************************************************************************
	Save Local Docs
*********************************************************************************/
function EXPR_DOCS.SaveLocalDocs()
	print("E3 - Saving Local Helper Data.");
	EXPR_DOCS.SaveLocalTypeDocs();
	EXPR_DOCS.SaveLocalConstructorDocs();
	EXPR_DOCS.SaveLocalAttributeDocs();
	EXPR_DOCS.SaveLocalMethodDocs();
	EXPR_DOCS.SaveLocalOperatorDocs();
	EXPR_DOCS.SaveLocalLibraryDocs();
	EXPR_DOCS.SaveLocalFunctionDocs();
end

/*********************************************************************************
	Hook thats called once E3 docs should be generated
*********************************************************************************/

hook.Add("Expression3.PostRegisterExtensions", "Expression3.CSVDocs", function()
	EXPR_DOCS.GenerateDefaults();
	EXPR_DOCS.LoadLocalDocs();
	EXPR_DOCS.LoadCustomDocs();
	EXPR_DOCS.SaveLocalDocs();
	print("E3 - Helper DataBase loaded.");
end);