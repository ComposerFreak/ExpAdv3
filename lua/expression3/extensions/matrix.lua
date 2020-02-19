--[[
	*****************************************************************************************************************************************************
		Quick math access
	*****************************************************************************************************************************************************
]]--
																--[ Author: ComposerFreak ]--
	local math = math
	local deg2rad = math.pi / 180
	local rad2deg = 180 / math.pi
	local sqrt = math.sqrt
	local acos = math.acos
	local asin = math.asin
	local atan2 = math.atan2
	local abs = math.abs
	local cos = math.cos
	local sin = math.sin
	local exp = math.exp
	local log = math.log
	local clamp = math.Clamp

--[[
	*****************************************************************************************************************************************************
		Create a new extension
	*****************************************************************************************************************************************************
]]--

	local extension = EXPR_LIB.RegisterExtension("matrix");

--[[
	*****************************************************************************************************************************************************
		Register Matrix2 class
	*****************************************************************************************************************************************************
]]--

	--|  x , y  |--
	--|         |--
	--| x2 , y2 |--
	
	matrix2 = {}
	matrix2.__index = matrix2

	local function Matrix2(x,y,x2,y2)
		return setmetatable({x = x,  y = y, x2 = x2, y2 = y2}, matrix2)
																			
	end

	local function isMatrix2(m2)

		return istable(m2) and #m2 == 4 and m2.x and m2.y and m2.x2 and m2.y2

	end

	extension:RegisterClass("mx2", "matrix2", isMatrix2, EXPR_LIB.NOTNIL)

	extension:RegisterConstructor("mx2", "", Matrix2, true)
	extension:RegisterConstructor("mx2", "n,n,n,n", Matrix2, true)
	extension:RegisterConstructor("mx2", "v2,v2", function(a,b) return Matrix2(a.x, b.x, a.y, b.y) end, true)
	extension:RegisterConstructor("mx2", "v2,v2", function(a,b) return Matrix2(a.x, a.y, b.x, b.y) end, true)


--[[
	*****************************************************************************************************************************************************
	 	Matrix2 Global Funcs
	*****************************************************************************************************************************************************
]]--

	local function clone(m2)
		local temp = {}

		for k, v in ipairs(m2) do
			temp[k] = v
		end

		return temp
	end

	local function detm2(m2)
		return ( m2.x * m2.y2 - m2.x2 * m2.y )
	end
	
	local function inversem2(m2)
		local det = ( m2.x * m2.y2 - m2.x2 * m2.y )

		if det == 0 then return Matrix2(0,0,0,0) end
		
		return Matrix2( (m2.y2 / det), (-m2.y / det), (-m2.x2 / det), (m2.x /det) )
	end

	local function identitym2(m2)
		return Matrix2( 1, 0, 0, 1)
	end

--[[
	*****************************************************************************************************************************************************
		Matrix2 Mathmatical Operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("add", "mx2,mx2", "mx2", 1, function(a, b)
		return Matrix2( (a.x + b.x), (a.y + b.y), (a.x2 + b.x2), (a.y2 + b.y2) )
	end, true)

	extension:RegisterOperator("sub", "mx2,mx2", "mx2", 1, function(a, b)
		return Matrix2( (a.x - b.x), (a.y - b.y), (a.x2 - b.x2), (a.y2 - b.y2) )
	end, true)

	extension:RegisterOperator("mul", "n,mx2", "mx2", 1, function(n, a)
		return Matrix2( (n * a.x), (n * a.y), (n * a.x2), (n * a.y2) )
	end, true)

	extension:RegisterOperator("mul", "mx2,n", "mx2", 1, function(a, n)
		return Matrix2( (a.x * n), (a.y * n), (a.x2 * n), (a.y2 * n) )
	end, true)

	extension:RegisterOperator("mul", "mx2,v2", "v2", 1, function(m2, v2)
		return Vector2( ((m2.x * v2.x) + (m2.y * v2.y)), ((m2.x2 * v2.x) + (m2.y2 * v2.y)) )
	end, true)

	extension:RegisterOperator("mul", "mx2,mx2", "mx2", 1, function(a, b)
		return Matrix2( ((a.x * b.x) + (a.y * b.x2)), ((a.x * b.y) + (a.y * b.y2)), ((a.x2 * b.x) + (a.y2 * b.x2)), ((a.x2 * b.y) + (a.y2 * b.y2)) )
	end, true)

	extension:RegisterOperator("div", "mx2,n", "mx2", 1, function(a, n)
		return Matrix2( (a.x / n), (a.y / n), (a.x2 / n), (a.y2 / n) )
	end, true)

	extension:RegisterOperator("exp", "mx2,n", "mx2", 1, function(a, n)
		
		if n == -1 then return inversem2(a)
		elseif n == 0 then return identitym2(a)
		elseif n == 1 then return a
		elseif n == 2 then return Matrix2( ((a.x * a.x) + (a.y * a.x2)), ((a.x * a.y) + (a.y * a.y2)), ((a.x2 * a.x) + (a.y2 * a.x2)), ((a.x2 * a.y) + (a.y2 * a.y2)) )
		else return Matrix2( 0,0,0,0 )
		
		end
	end, true)

--[[
	*****************************************************************************************************************************************************
		Matrix2 Logical Operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("eq", "mx2,mx2", "b", 1, function(a, b)

		if  a.x - b.x <= 0 and b.x - a.x <= 0 and
			a.y - b.y <= 0 and b.y - a.y <= 0 and
			a.x2 - b.x2 <= 0 and b.x2 - a.x2 <= 0 and
			a.y2 - b.y2 <= 0 and b.y2 - a.y2 <= 0
			then return 1 else return 0 end

	end, true)

	extension:RegisterOperator("neq", "mx2,mx2", "b", 1, function(a, b)
		return (a.x - b.x > 0 and b.x - a.x > 0 and a.y - b.y > 0 and b.y - a.y > 0 and a.x2 - b.x2 > 0 and b.x2 - a.x2 > 0 and a.y2 - b.y2 > 0 and b.y2 - a.y2 > 0)
	end, true)

	extension:RegisterOperator("neg", "mx2", "mx2", 1, function(a)
		return Matrix2( -a.x, -a.y, -a.x2, -a.y2)
	end, true)

	extension:RegisterOperator("is", "mx2", "b", 1, function(a)
		return (a.x > 0 or -a.x > 0 or a.y > 0 or -a.y > 0 or a.x2 > 0 or -a.x2 > 0 or a.y2 > 0 or -a.y2 > 0);
	end, true)

--[[
	*****************************************************************************************************************************************************
		Matrix2 Atributes
	*****************************************************************************************************************************************************
]]--
	extension:RegisterAttribute("mx2", "x", "n")
	extension:RegisterAttribute("mx2", "y", "n")
	extension:RegisterAttribute("mx2", "x2", "n")
	extension:RegisterAttribute("mx2", "y2", "n")

--[[
	*****************************************************************************************************************************************************
		Matrix2 Methods
	*****************************************************************************************************************************************************
]]--

	extension:RegisterMethod("mx2", "diagonal2", "mx2", "v2", 1, function(m2)
		return Vector2( m2.x, m2.y2 )
	end, true)

	extension:RegisterMethod("mx2", "trace2", "mx2", "n", 1, function(m2)
		return m2.x + m2.y2 
	end, true)

	extension:RegisterMethod("mx2", "det2", "mx2", "n", 1, function(m2)
		return detm2( m2 )
	end, true)

	extension:RegisterMethod("mx2", "transpose2", "mx2", "n", 1, function(m2)
		return Matrix2( m2.x, m2.x2, m2.y, m2.y2 )
	end, true)

	extension:RegisterMethod("mx2", "adj2", "mx2", "n", 1, function(m2)
		return Matrix2( m2.y2, -m2.y, -m2.x2, m2.x )
	end, true)

	extension:RegisterMethod("mx2", "toString", "", "s", 1, function(m2)
		return table.ToString(m2, "Matrix2", true)
	end, true)
	
	extension:RegisterMethod("mx2", "row", "n", "v2", 1, function(m2, n)

		local i
		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		if n < 1 then i = 1
		elseif n > 2 then i = 2
		else i = n - (n % 1) end
		
		local x = t[i * 2 - 1]
		local y = t[i * 2]

		return Vector2( x, y )

	end, true)

	extension:RegisterMethod("mx2", "column", "n", "v2", 1, function(m2, n)

		local i
		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		if n < 1 then i = 1
		elseif n > 2 then i = 2
		else i = (n - (n % 1)) end
		
		local x = t[i]
		local y = t[i + 2]

		return Vector2( x, y )

	end, true)

	extension:RegisterMethod("mx2", "setRow", "n,n,n", "mx2", 1, function(m2, x, y, z)

		local i
		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		if x < 1 then i = 2
		elseif x > 2 then i = 4
		else i = (x - (x % 1)) * 2 end
		
		t[i - 1] = y
		t[i] = z

		return Matrix2( t[1], t[2], t[3], t[4] )

	end, true)

	extension:RegisterMethod("mx2", "setRow", "n,v2", "mx2", 1, function(m2, x, v2)

		local i
		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		if x < 1 then i = 2
		elseif x > 2 then i = 4
		else i = (x - (x % 1)) * 2 end
		
		t[i - 1] = v2.x
		t[i] = v2.y

		return Matrix2( t[1], t[2], t[3], t[4] )

	end, true)

	extension:RegisterMethod("mx2", "setColumn", "n,n,n", "mx2", 1, function(m2, x, y, z)

		local i
		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		if x < 1 then i = 1
		elseif x > 2 then i = 2
		else i = (x - (x % 1)) end
		
		t[i] = y
		t[i + 2] = z

		return Matrix2( t[1], t[2], t[3], t[4] )

	end, true)

	extension:RegisterMethod("mx2", "setColumn", "n,v2", "mx2", 1, function(m2, x, v2)

		local i
		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		if x < 1 then i = 1
		elseif x > 2 then i = 2
		else i = (x - (x % 1)) end
		
		t[i] = v2.x
		t[i + 2] = v2.y

		return Matrix2( t[1], t[2], t[3], t[4] )

	end, true)

	extension:RegisterMethod("mx2", "swapRows", "", "mx2", 1, function(m2)

		local t = { m2.x, m2.y, m2.x2, m2.y2 }	

		return Matrix2(t[3], t[4], t[1], t[2])

	end, true)

	extension:RegisterMethod("mx2", "swapColumns", "", "mx2", 1, function(m2)

		local t = { m2.x, m2.y, m2.x2, m2.y2 }	

		return Matrix2(t[2], t[1], t[4], t[3])

	end, true)

	extension:RegisterMethod("mx2", "element", "n,n", "n", 1, function(m2, x, y)
		
		local a, b

		if x < 1 then a = 1
		elseif x > 2 then a = 2
		else a = (x - (x % 1)) end
		
		if y < 1 then b = 1
		elseif y > 2 then b = 2
		else b = (y - (y % 1)) end
		
		local i = a + (b - 1) * 2
		local t = { m2.x, m2.y, m2.x2, m2.y2 }

		return t[i]

	end, true)

	extension:RegisterMethod("mx2", "setElement", "n,n,n", "mx2", 1, function(m2, x, y, z)

		local a, b

		if x < 1 then a = 1
		elseif x > 2 then a = 2
		else a = (x - (x % 1)) end
		
		if y < 1 then b = 1
		elseif y > 2 then b = 2
		else b = (y - (y % 1)) end

		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		t[a + (b - 1) * 2] = z

		return Matrix2( t[1], t[2], t[3], t[4] )

	end, true)

	extension:RegisterMethod("mx2", "swapElement", "n,n,n,n", "mx2", 1, function(m2, w, x, y, z)

		local a, b, c, d

		if w < 1 then a = 1
		elseif w > 3 then a = 3
		else a = (w - (w % 1)) end
		
		if x < 1 then b = 1
		elseif x > 3 then b = 3
		else b = (x - (x % 1)) end

		if y < 1 then c = 1
		elseif y > 3 then c = 3
		else c = (y - (y % 1)) end

		if z < 1 then d = 1
		elseif z > 3 then d = 3
		else d = (z - (z % 1)) end

		local e = a + (b - 1) * 2
		local f = c + (d - 1) * 2

		local t = { m2.x, m2.y, m2.x2, m2.y2 }
		t[e], t[f] = t[f], t[e]

		return Matrix2( t[1], t[2], t[3], t[4] )

	end, true)


--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--
--[[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||]]--
--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--



--[[
	*****************************************************************************************************************************************************
		Register Matrix class
	*****************************************************************************************************************************************************
]]--

	--|  x ,  y ,  z |--
	--|              |--
	--| x2 , y2 , z2 |--
	--|              |--
	--| x3 , y3 , z3 |--

	matrix3 = {}
	matrix3.__index = matrix3

	local function Matrix3(x,y,z, x2,y2,z2, x3,y3,z3)
		return setmetatable({x = x,  y = y, z = z,	x2 = x2, y2 = y2, z2 = z2,	x3 = x3, y3 = y3, z3 = z3}, matrix3)
																			
	end

	local function isMatrix3(m)

		return istable(m) and #m == 9 and 	m.x and m.y and m.z 	and 	m.x2 and m.y2 and m.z2 		and 	m.x3 and m.y3 and m.z3

	end

	extension:RegisterClass("mx3", "matrix3", isMatrix3, EXPR_LIB.NOTNIL)

	extension:RegisterConstructor("mx3", "", Matrix3, true)
	extension:RegisterConstructor("mx3", "n,n,n,n,n,n,n,n,n", Matrix3, true)
	extension:RegisterConstructor("mx3", "v,v,v", function(a,b,c) return Matrix3(a.x, b.x, c.x, a.y, b.y, c.y, a.z, b.z, c.z) end)
	extension:RegisterConstructor("mx3", "v,v,v", function(a,b,c) return Matrix3(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z) end)
	extension:RegisterConstructor("mx3", "mx2", function(m2) return Matrix3(m2.x, m2.y, 0, m2.x2, m2.y2, 0, 0, 0, 0) end)

--[[
	*****************************************************************************************************************************************************
	 	Matrix Global Funcs
	*****************************************************************************************************************************************************
]]--
	
	local function detm3(m3)
		return ( m3.x * ( m3.y2 * m3.z3 - m3.y3 * m3.z2 ) - 
				 m3.y * ( m3.x2 * m3.z3 - m3.x3 * m3.z2 ) +
				 m3.z * ( m3.x2 * m3.y3 - m3.x3 * m3.y2) )
	end
	
	local function inversem3(m3)
		local det = detm3(m3)
		if det == 0 then return Matrix3( 0,0,0,
										 0,0,0,
										 0,0,0 )
		end

		return Matrix3( (m3.y2 * m3.z3 - m3.y3 * m3.z2) / det, (m3.y3 * m3.z - m3.y * m3.z3) / det, (m3.y * m3.z2 - m3.y2 * m3.z) / det,
						(m3.x3 * m3.z2 - m3.x2 * m3.z3) / det, (m3.x * m3.z3 - m3.x3 * m3.z) / det, (m3.x2 * m3.z - m3.x * m3.z2) / det,
						(m3.x2 * m3.y3 - m3.x3 * m3.y2) / det, (m3.x3 * m3.y - m3.x * m3.y3) / det, (m3.x * m3.y2 - m3.x2 * m3.y) / det )

	end

	local function identitym3(m3)
		return Matrix3( 1, 0, 0, 
						0, 1, 0, 
						0, 0, 1)
	end


--[[
	*****************************************************************************************************************************************************
		Matrix Mathematical Operations
	*****************************************************************************************************************************************************
]]--

	

--[[
	*****************************************************************************************************************************************************
		Matrix Logical Operations
	*****************************************************************************************************************************************************
]]--



--[[
	*****************************************************************************************************************************************************
		Matrix Attributes
	*****************************************************************************************************************************************************
]]--



--[[
	*****************************************************************************************************************************************************
		Matrix Methods
	*****************************************************************************************************************************************************
]]--



--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--
--[[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||]]--
--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--



--[[
	*****************************************************************************************************************************************************
		Register Matrix4 class
	*****************************************************************************************************************************************************
]]--

	--|  w ,  x ,  y ,  z |--
	--|                   |--
	--| w2 , x2 , y2 , z2 |--
	--|                   |--
	--| w3 , x3 , y3 , z3 |--
	--|                   |--
	--| w4 , x4 , y4 , z4 |--


--[[
	*****************************************************************************************************************************************************
	 	Matrix4 Global Funcs
	*****************************************************************************************************************************************************
]]--



--[[
	*****************************************************************************************************************************************************
		Matrix4 Mathematical Operations
	*****************************************************************************************************************************************************
]]--



--[[
	*****************************************************************************************************************************************************
		Matrix4 Logical Operations
	*****************************************************************************************************************************************************
]]--



--[[
	*****************************************************************************************************************************************************
		Matrix4 Attributes
	*****************************************************************************************************************************************************
]]--



--[[
	*****************************************************************************************************************************************************
		Matrix4 Methods
	*****************************************************************************************************************************************************
]]--



--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--
--[[||||||||||||||||||||||||||||||||||||||||||	E  N  D     O  F    E  X  T  E  N  S  I  O  N  ||||||||||||||||||||||||||||||||||||||||||||||||||||||]]--
--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--

extension:EnableExtension();