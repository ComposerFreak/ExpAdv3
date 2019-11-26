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

local function ow(pk, current, values)
	for i = 1, #current do
		local cur = current[i];
		local new = values[i];
		if new ~= "" or not cur then current[i] = new; end
	end

	return true;
end

function oCSV:insert(values)

	if not self.clk then self.clk = {}; end
	if not self.data then self.data = {}; end

	local i = #self.data + 1;

	if self.pk then

		local key = values[self.pk];

		if key and key ~= "" then

			i = self.lk[key] or i;

			local current = self.data[i];

			if current then

				local inserted;

				for j = 1, #current do
					local new = values[j];

					if new ~= "" and new ~= current[j] then
						inserted = true;
						current[j] = new;
					end
				end

				if not inserted then return false; end

				self.clk[i] = true;

				return true;
			end
			
			self.lk[key] = i;
		end
	end

	self.clk[i] = true;
	self.data[i] = values;

	--print("insert: ", i, key, " -> ", unpack(values));

	return true;
end

function oCSV:add(...)
	self:insert({...});
end

function oCSV:MergeBlankValues(with)
	if with and with.data then
		for i = 1, #with.data do
			oCSV:insert(with.data[i]);
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
function EXPR_DOCS.CSVFromString(str, pk, csv)
	local result = csv or EXPR_DOCS.CSV(pk);

	if str and str ~= "" then

		local rows = string.Explode("\n", str);
		local total = #rows;

		if rows[1] then
			if not csv then result.headers = string.Explode("\t", rows[1]); end

			for i = 2, total do
				result:insert(string.Explode("\t", rows[i]));
			end
		end

	end

	return result;
end

function EXPR_DOCS.loadCSV(filename, path, pk)
	local str = file.Read(filename, path or "DATA");
	return EXPR_DOCS.CSVFromString(str, pk);
end

function EXPR_DOCS.MergeCSV(filename, path, csv, pk)
	local str = file.Read(filename, path or "DATA");
	return EXPR_DOCS.CSVFromString(str, pk, csv);
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

function EXPR_DOCS.saveCSV(csv, filename)
	file.Write(filename, EXPR_DOCS.CSVToString(csv));
end

/*********************************************************************************
	Create data foler
*********************************************************************************/

file.CreateDir("e3docs");
file.CreateDir("e3docs/csv");
file.CreateDir("e3docs/saved");


/*********************************************************************************
	Events
*********************************************************************************/

do
	local filename = "events.txt"

	local docs = EXPR_DOCS.CSV(1, "signature", "name", "parameter", "result type", "result count", "state", "desc", "example");

	function EXPR_DOCS.GetEventDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeEvent(keyvalues)
		docs:insert(docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultEventDocs()

		for _, op in pairs( EXPR_EVENTS ) do
				
			EXPR_DOCS.DescribeEvent({
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

	function EXPR_DOCS.LoadDefaultEventDocs()
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalEventDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalEventDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs/csv/%s", filename), "DATA")
	end

end

/*********************************************************************************
	Types
*********************************************************************************/
do
	local filename = "types.txt"

	local docs = EXPR_DOCS.CSV(1, "id", "name", "extends", "desc", "example", "state");

	function EXPR_DOCS.GetTypeDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeType(keyvalues)
		docs:insert(docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultTypeDocs()
		for _, data in pairs( EXPR_CLASSES ) do
			EXPR_DOCS.DescribeType({
				["id"] = data.id,
				["name"] = data.name,
				["extends"] = data.base,
				["state"] = data.state,
				["desc"] = "",
			});
		end

		docs.clk = {};
	end

	function EXPR_DOCS.LoadDefaultTypeDocs()
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalTypeDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
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
		docs:insert(docs:FromKV(keyvalues));
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
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalConstructorDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalConstructorDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs/csv/%s", filename), "DATA")
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
		docs:insert(docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultAttributeDocs()

		for _, cls in pairs( EXPR_CLASSES ) do
			
			if cls.attributes then

				for _, op in pairs(cls.attributes) do
					EXPR_DOCS.DescribeAttribute({
						["signature"] = cls.id .. "." .. op.attribute,
						["id"] = cls.id,
						["name"] = op.attribute,
						["type"] = op.class,
						["desc"] = "",
					});
				end

			end

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultAttributeDocs()
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalAttributeDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalAttributeDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs/csv/%s", filename), "DATA")
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
		docs:insert(docs:FromKV(keyvalues));
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
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalMethodDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalMethodDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs/csv/%s", filename), "DATA")
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
		docs:insert(docs:FromKV(keyvalues));
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
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalOperatorDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalOperatorDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs/csv/%s", filename), "DATA")
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
		docs:insert(docs:FromKV(keyvalues));
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
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalLibraryDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalLibraryDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs/csv/%s", filename), "DATA")
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
		docs:insert(docs:FromKV(keyvalues));
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
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalFunctionDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalFunctionDocs()
		EXPR_DOCS.saveCSV(docs, string.format("e3docs\\csv\\%s", filename), "DATA")
	end

end

/*********************************************************************************
	Constants
*********************************************************************************/

do
	local filename = "constants.txt"

	local docs = EXPR_DOCS.CSV(1, "signature", "library", "name", "result type", "result count", "state", "desc", "example");

	function EXPR_DOCS.GetConstantDocs()
		return docs;
	end

	function EXPR_DOCS.DescribeConstant(keyvalues)
		docs:insert(docs:FromKV(keyvalues));
	end

	function EXPR_DOCS.GenerateDefaultConstantDocs()
		
		for _, lib in pairs( EXPR_LIBRARIES ) do
			
			for __, op in pairs(lib._constants)	do
				EXPR_DOCS.DescribeConstant({
					["signature"] = op.signature,
					["library"] = lib.name,
					["name"] = op.name,
					["result type"] = op.result,
					["result count"] = 1,
					["state"] = op.state,
					["desc"] = "",
				});
			end

		end

		docs.clk = {};
		
	end

	function EXPR_DOCS.LoadDefaultConstantDocs()
		EXPR_DOCS.MergeCSV(string.format("lua/expression3/helper/csv/%s", filename), "GAME", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.LoadLocalConstantDocs()
		EXPR_DOCS.MergeCSV(string.format("e3docs/csv/%s", filename), "DATA", docs, 1);
		docs.clk = {};
	end

	function EXPR_DOCS.SaveLocalConstantDocs()
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
				CONSTANT = EXPR_DOCS.GetConstantDocs(),
			};

			local csv;

			local rows = string.Explode("\n", str);

			local total = #rows;

			if total >= 1 then

				for i = 1, total do
					local value = rows[i];

					if value and value ~= "" then
						local match = string.match(value, "^#([A-Za-z]+)");

						if match then
							csv = lk[match:upper()];

							if not csv then
								return false, "Invalid refrence \"#" .. match .. "\"";
							end
						end

						if not csv then
							return false, "No refrence set";
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
		end

		return false, "file is empty.";
	end;

	function EXPR_DOCS.LoadCustomDocFile(filename, path)
		local raw = file.Read(filename, path or "GAME");

		local ok, err = LoadCustomDocFile(raw);

		if not ok then
			MsgN("[E3] Error loading custom helper data:");
			MsgN("Error: ", err);
			MsgN("File: ", filename);
		end

		return ok, err;
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

			for i, v in pairs(csv.clk) do
				if v and csv.data[i] then
					table.insert(a, table.concat(csv.data[i], "\t"));
				end
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
			"#Constant", write(EXPR_DOCS.GetConstantDocs()),
		}, "\n");

	end

	function EXPR_DOCS.SaveChangedDocs(filename)

		local path = string.format("e3docs/saved/%s", filename);

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
	EXPR_DOCS.GenerateDefaultEventDocs();
	EXPR_DOCS.GenerateDefaultTypeDocs();
	EXPR_DOCS.GenerateDefaultConstructorDocs();
	EXPR_DOCS.GenerateDefaultAttributeDocs();
	EXPR_DOCS.GenerateDefaultMethodDocs();
	EXPR_DOCS.GenerateDefaultOperatorDocs();
	EXPR_DOCS.GenerateDefaultLibraryDocs();
	EXPR_DOCS.GenerateDefaultFunctionDocs();
	EXPR_DOCS.GenerateDefaultConstantDocs();
	
	EXPR_DOCS.LoadDefaultEventDocs();
	EXPR_DOCS.LoadDefaultTypeDocs();
	EXPR_DOCS.LoadDefaultConstructorDocs();
	EXPR_DOCS.LoadDefaultAttributeDocs();
	EXPR_DOCS.LoadDefaultMethodDocs();
	EXPR_DOCS.LoadDefaultOperatorDocs();
	EXPR_DOCS.LoadDefaultLibraryDocs();
	EXPR_DOCS.LoadDefaultFunctionDocs();
	EXPR_DOCS.LoadDefaultConstantDocs();
end

/*********************************************************************************
	Load Local Docs
*********************************************************************************/
function EXPR_DOCS.LoadLocalDocs()
	print("E3 - Loading Local Helper Data.");
	EXPR_DOCS.LoadLocalEventDocs();
	EXPR_DOCS.LoadLocalTypeDocs();
	EXPR_DOCS.LoadLocalConstructorDocs();
	EXPR_DOCS.LoadLocalAttributeDocs();
	EXPR_DOCS.LoadLocalMethodDocs();
	EXPR_DOCS.LoadLocalOperatorDocs();
	EXPR_DOCS.LoadLocalLibraryDocs();
	EXPR_DOCS.LoadLocalFunctionDocs();
	EXPR_DOCS.LoadLocalConstantDocs();
end

/*********************************************************************************
	Save Local Docs
*********************************************************************************/
function EXPR_DOCS.SaveLocalDocs()
	print("E3 - Saving Local Helper Data.");
	EXPR_DOCS.SaveLocalEventDocs();
	EXPR_DOCS.SaveLocalTypeDocs();
	EXPR_DOCS.SaveLocalConstructorDocs();
	EXPR_DOCS.SaveLocalAttributeDocs();
	EXPR_DOCS.SaveLocalMethodDocs();
	EXPR_DOCS.SaveLocalOperatorDocs();
	EXPR_DOCS.SaveLocalLibraryDocs();
	EXPR_DOCS.SaveLocalFunctionDocs();
	EXPR_DOCS.SaveLocalConstantDocs();
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