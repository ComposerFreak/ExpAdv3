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

	--[---------------------------- Functions -------------------------------------]--

	extension:RegisterLibrary("matrix")

	extension:RegisterFunction("matrix", "diagonal2", "mx2", "v2", 1, function(m2)
		return Vector2( m2.x, m2.y2 )
	end, true)

	extension:RegisterFunction("matrix", "trace2", "mx2", "n", 1, function(m2)
		return m2.x + m2.y2 
	end, true)

	extension:RegisterFunction("matrix", "det2", "mx2", "n", 1, function(m2)
		return detm2( m2 )
	end, true)

	extension:RegisterFunction("matrix", "transpose2", "mx2", "n", 1, function(m2)
		return Matrix2( m2.x, m2.x2, m2.y, m2.y2 )
	end, true)

	extension:RegisterFunction("matrix", "adj2", "mx2", "n", 1, function(m2)
		return Matrix2( m2.y2, -m2.y, -m2.x2, m2.x )
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

	extension:RegisterConstructor("mx3", "", Matrix3(0,0,0,0,0,0,0,0,0), true)
	extension:RegisterConstructor("mx3", "n,n,n,n,n,n,n,n,n", Matrix3, true)
	extension:RegisterConstructor("mx3", "v,v,v", function(a,b,c) return Matrix3(a.x, b.x, c.x, a.y, b.y, c.y, a.z, b.z, c.z) end, true)
	//extension:RegisterConstructor("mx3", "v,v,v", function(a,b,c) return Matrix3(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z) end)
	extension:RegisterConstructor("mx3", "mx2", function(m2) return Matrix3(m2.x, m2.y, 0, m2.x2, m2.y2, 0, 0, 0, 0) end, true)
	extension:RegisterConstructor("mx3", "a", function(a)

		ang = Angle(a.p, a.y, a.r)
		local x = ang:Forward()
		local y = ang:Right() * -1
		local z = ang:Up()

		return Matrix3( x.x, y.x, z.x,
			            x.y, y.y, z.y,
			            x.z, y.z, z.z )
	end, true)
	extension:RegisterConstructor("mx3", "e", function(e)

		if IsValid(e) then
			local ph = e:GetPhysicsObject()

			local div = 10000
			local pos = ph:GetPos()
			
			local x = ph:LocalToWorld(Vector(div, 0, 0)) - pos
			local y = ph:LocalToWorld(Vector(0, div, 0)) - pos
			local z = ph:LocalToWorld(Vector(0, 0, div)) - pos

			return Matrix3( x.x / div , y.x / div , z.x / div , 
				            x.y / div , y.y / div , z.y / div , 
				            x.z / div , y.z / div , z.z / div )
		
		else return Matrix3( 0, 0, 0,
			                 0, 0, 0,
			                 0, 0, 0 )

		
		end
	end, true)


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

	local function identitym3()
		return Matrix3( 1, 0, 0, 
						0, 1, 0, 
						0, 0, 1)
	end

	local function m3ToTable(m3)
		
		return { m3.x  , m3.y  , m3.z  , 
		         m3.x2 , m3.y2 , m3.z2 , 
		         m3.x3 , m3.y3 , m3.z3 }

	end

	local function tableToMatrix3(t)

		return Matrix3( t[1], t[2], t[3], 
			            t[4], t[5], t[6], 
			            t[7], t[8], t[9] )

	end

--[[
	*****************************************************************************************************************************************************
		Matrix Mathematical Operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("add", "mx3,mx3", "mx3", 1, function(a, b)

		return Matrix3( (a.x + b.x)   , (a.y + b.y)   , (a.z + b.z)   , 
			            (a.x2 + b.x2) , (a.y2 + b.y2) , (a.z2 + b.z2) , 
			            (a.x3 + b.x3) , (a.y3 + b.z3) , (a.z3 + b.z3) )

	end, true)

	extension:RegisterOperator("sub", "mx3,mx3", "mx3", 1, function(a, b)

		return Matrix3( (a.x - b.x)   , (a.y - b.y)   , (a.z - b.z)   , 
			            (a.x2 - b.x2) , (a.y2 - b.y2) , (a.z2 - b.z2) , 
			            (a.x3 - b.x3) , (a.y3 - b.z3) , (a.z3 - b.z3) )

	end, true)

	extension:RegisterOperator("mul", "n,mx3", "mx3", 1, function(n, m3)

		return Matrix3( (n * m3.x)  , (n * m3.y)  , (n * m3.z)  , 
		                (n * m3.x2) , (n * m3.y2) , (n * m3.z2) , 
		                (n * m3.x3) , (n * m3.y3) , (n * m3.z3) )

	end, true)

	extension:RegisterOperator("mul", "mx3,n", "mx3", 1, function(m3, n)

		return Matrix3( (m3.x * n)  , (m3.y * n)  , (m3.z * n)  , 
		                (m3.x2 * n) , (m3.y2 * n) , (m3.z2 * n) , 
		                (m3.x3 * n) , (m3.y3 * n) , (m3.z3 * n) )

	end, true)

	extension:RegisterOperator("mul", "mx3,v", "v", 1, function(m3, v)

		return Vector( (m3.x * v.x)  + (m3.y * v.y)  + (m3.z * v.z)  , 
		               (m3.x2 * v.x) + (m3.y2 * v.y) + (m3.z2 * v.z) , 
		               (m3.x3 * v.x) + (m3.y3 * v.y) + (m3.z3 * v.z) )

	end, true)

	extension:RegisterOperator("mul", "mx3,mx3", "mx3", 1, function(a, b)

		return Matrix3( (a.x * b.x)  + (a.y * b.x2)  + (a.z * b.x3)  ,
		                (a.x * b.y)  + (a.y * b.y2)  + (a.z * b.y3)  , 
		                (a.x * b.z)  + (a.y * b.z2)  + (a.z * b.z3)  , 
		                
		                (a.x2 * b.x) + (a.y2 * b.x2) + (a.z2 * b.x3) , 
		                (a.x2 * b.y) + (a.y2 * b.y2) + (a.z2 * b.y3) , 
		                (a.x2 * b.z) + (a.y2 * b.z2) + (a.z2 * b.z3) , 
		                
		                (a.x3 * b.x) + (a.y3 * b.x2) + (a.z3 * b.x3) , 
		                (a.x3 * b.y) + (a.y3 * b.y2) + (a.z3 * b.y3) , 
		                (a.x3 * b.z) + (a.y3 * b.z2) + (a.z3 * b.z3) )

	end, true)

	extension:RegisterOperator("div", "mx3,n", "mx3", 1, function(m3, n)

		return Matrix3( (m3.x / n)  , (m3.y / n)  , (m3.z / n)  ,
		                (m3.x2 / n) , (m3.y2 / n) , (m3.z2 / n) , 
		                (m3.x3 / n) , (m3.y3 / n) , (m3.z3 / n) )
	end, true)

	extension:RegisterOperator("exp", "mx3,n", "mx3", 1, function(m3, n)

		if n == -1 then return inversem3(m3)
		elseif n == 0 then return identitym3()
		elseif n == 1 then return m3
		elseif n == 2 then
			
			return Matrix3( (m3.x * m3.x)  + (m3.y * m3.x2)  + (m3.z * m3.x3)  ,
		                    (m3.x * m3.y)  + (m3.y * m3.y2)  + (m3.z * m3.y3)  , 
		                    (m3.x * m3.z)  + (m3.y * m3.z2)  + (m3.z * m3.z3)  , 
		                
		                    (m3.x2 * m3.x) + (m3.y2 * m3.x2) + (m3.z2 *m3.x3)  , 
		                    (m3.x2 * m3.y) + (m3.y2 * m3.y2) + (m3.z2 * m3.y3) , 
		                    (m3.x2 * m3.z) + (m3.y2 * m3.z2) + (m3.z2 * m3.z3) , 
		                
		                    (m3.x3 * m3.x) + (m3.y3 * m3.x2) + (m3.z3 * m3.x3) , 
		                    (m3.x3 * m3.y) + (m3.y3 * m3.y2) + (m3.z3 * m3.y3) , 
		                    (m3.x3 * m3.z) + (m3.y3 * m3.z2) + (m3.z3 * m3.z3) )
		
		else return Matrix3( 0, 0, 0,
			                 0, 0, 0,
			                 0, 0, 0 )
		end
		
	end, true)



--[[
	*****************************************************************************************************************************************************
		Matrix Logical Operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("eq", "mx3,mx3", "b", 1, function(a, b)

		if (a.x - b.x) <= 0 and (b.x - a.x) <= 0 and
		   (a.y - b.y) <= 0 and (b.y - a.y) <= 0 and
		   (a.z - b.z) <= 0 and (b.z - a.z) <= 0 and

		   (a.x2 - b.x2) <= 0 and (b.x2 - a.x2) <= 0 and
		   (a.y2 - b.y2) <= 0 and (b.y2 - a.y2) <= 0 and
		   (a.z2 - b.z2) <= 0 and (b.z2 - a.z2) <= 0 and

		   (a.x3 - b.x3) <= 0 and (b.x3 - a.x3) <= 0 and
		   (a.y3 - b.y3) <= 0 and (b.y3 - a.y3) <= 0 and
		   (a.z3 - b.z3) <= 0 and (b.z3 - a.z3) <= 0
		   
		   then return 1 else return 0 end

	end, true)

	extension:RegisterOperator("neq", "mx3,mx3", "b", 1, function(a, b)

		if (a.x - b.x) > 0 and (b.x - a.x) > 0 and
		   (a.y - b.y) > 0 and (b.y - a.y) > 0 and
		   (a.z - b.z) > 0 and (b.z - a.z) > 0 and

		   (a.x2 - b.x2) > 0 and (b.x2 - a.x2) > 0 and
		   (a.y2 - b.y2) > 0 and (b.y2 - a.y2) > 0 and
		   (a.z2 - b.z2) > 0 and (b.z2 - a.z2) > 0 and

		   (a.x3 - b.x3) > 0 and (b.x3 - a.x3) > 0 and
		   (a.y3 - b.y3) > 0 and (b.y3 - a.y3) > 0 and
		   (a.z3 - b.z3) > 0 and (b.z3 - a.z3) > 0
		   
		   then return 1 else return 0 end

	end, true)

	extension:RegisterOperator("neg", "mx3", "mx3", 1, function(m3)

		return Matrix3( -m3.x  , -m3.y  , -m3.z  ,
		                -m3.x2 , -m3.y2 , -m3.z2 ,
		                -m3.x3 , -m3.y2 , -m3.z3 )
	end, true)

	extension:RegisterOperator("is", "mx3", "b", 1, function(m3)

		if (m3.x > 0) or (-m3.x > 0) or
		   (m3.y > 0) or (-m3.y > 0) or
		   (m3.z > 0) or (-m3.z > 0) or

		   (m3.x2 > 0) or (-m3.x2 > 0) or
		   (m3.y2 > 0) or (-m3.y2 > 0) or
		   (m3.z2 > 0) or (-m3.z2 > 0) or

		   (m3.x3 > 0) or (-m3.x3 > 0) or
		   (m3.y3 > 0) or (-m3.y3 > 0) or
		   (m3.z3 > 0) or (-m3.z3 > 0)
		   
		   then return 1 else return 0 end

	end, true)



--[[
	*****************************************************************************************************************************************************
		Matrix Attributes
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterAttribute("mx3", "x", "n")
	extension:RegisterAttribute("mx3", "y", "n")
	extension:RegisterAttribute("mx3", "z", "n")
	extension:RegisterAttribute("mx3", "x2", "n")
	extension:RegisterAttribute("mx3", "y2", "n")
	extension:RegisterAttribute("mx3", "z2", "n")
	extension:RegisterAttribute("mx3", "x3", "n")
	extension:RegisterAttribute("mx3", "y3", "n")
	extension:RegisterAttribute("mx3", "z3", "n")

--[[
	*****************************************************************************************************************************************************
		Matrix Methods
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterMethod("mx3", "toString", "", "s", 1, function(m3)
		
		return table.ToString(m3, "Matrix3", true)

	end, true)
	
	extension:RegisterMethod("mx3", "row", "n", "v", 1, function(m3, n)

		local i
		local t = m3ToTable(m3)
		if n < 1 then i = 3
		elseif n > 3 then i = 9
		else i = (n - (n % 1)) * 3 end

		local x = t[i - 2]
		local y = t[i - 1]
		local z = t[i]

		return Vector( x, y, z )

	end, true)


	extension:RegisterMethod("mx3", "column", "n", "v", 1, function(m3, n)

		local i
		local t = m3ToTable(m3)
		if n < 1 then i = 1
		elseif n > 3 then i = 3
		else i = (n - (n % 1)) end

		local x = t[i]
		local y = t[i + 3]
		local z = t[i + 6]

		return Vector( x, y, z )

	end, true)

	extension:RegisterMethod("mx3", "setRow", "n,n,n,n", "mx3", 1, function(m3, n, x, y, z)

		local i
		local t = m3ToTable(m3)
		if n < 1 then i = 1
		elseif n > 3 then i = 3
		else i = (n - (n % 1)) end

		t[(i * 3) - 2] = x
		t[(i * 3) - 1] = y
		t[i * 3] = z

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "setRow", "n,v", "mx3", 1, function(m3, n, v)

		local i
		local t = m3ToTable(m3)
		if n < 1 then i = 1
		elseif n > 3 then i = 3
		else i = (n - (n % 1)) end

		t[(i * 3) - 2] = v.x
		t[(i * 3) - 1] = v.y
		t[i * 3] = v.z

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "setColumn", "n,n,n,n", "mx3", 1, function(m3, n, x, y, z)

		local i
		local t = m3ToTable(m3)
		if n < 1 then i = 1
		elseif n > 3 then i = 3
		else i = (n - (n % 1)) end

		t[i] = x
		t[i + 3] = y
		t[i + 6] = z

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "setColumn", "n,v", "mx3", 1, function(m3, n, v)

		local i
		local t = m3ToTable(m3)
		if n < 1 then i = 1
		elseif n > 3 then i = 3
		else i = (n - (n % 1)) end

		t[i] = v.x
		t[i + 3] = v.y
		t[i + 6] = v.z

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "swapRows", "n,n", "mx3", 1, function(m3, x, y)

		local i, j
		local t = {}
		
		if x < 1 then i = 1
		elseif x > 3 then i = 3
		else i = (x - (x % 1)) end
		
		if y < 1 then j = 1
		elseif y > 3 then j = 3
		else j = y - (y % 1) end

		if i == j then return m3

		elseif (i == 1 and j == 2) or (i == 2 and j == 1) then 
			t = { m3.x2 , m3.y2 , m3.z2 ,
			      m3.x  , m3.y  , m3.z  ,
			      m3.x3 , m3.y3 , m3.z3 }
		
		elseif (i == 2 and j == 3) or (i == 3 and j == 2) then
			t = { m3.x  , m3.y  , m3.z  ,
			      m3.x3 , m3.y3 , m3.z3 ,
			      m3.x2 , m3.y2 , m3.z2 }
		
		elseif (i == 1 and j == 3) or (i == 3 and j ==1) then
			t = { m3.x3 , m3.y3 , m3.z3 ,
			      m3.x2 , m3.y2 , m3.z2 ,
			      m3.x  , m3.y  , m3.z  }
		end

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "swapColumns", "n,n", "mx3", 1, function(m3, x, y)

		local i, j
		local t = {}
		
		if x < 1 then i = 1
		elseif x > 3 then i = 3
		else i = (x - (x % 1)) end
		
		if y < 1 then j = 1
		elseif y > 3 then j = 3
		else j = y - (y % 1) end

		if i == j then return m3

		elseif (i == 1 and j == 2) or (i == 2 and j == 1) then 
			t = { m3.y  , m3.x  , m3.z  ,
			      m3.y2 , m3.x2 , m3.z2 ,
			      m3.y3 , m3.x3 , m3.z3 }
		
		elseif (i == 2 and j == 3) or (i == 3 and j == 2) then
			t = { m3.x  , m3.z  , m3.y  ,
			      m3.x2 , m3.z2 , m3.y2 ,
			      m3.x3 , m3.z3 , m3.y3 }
		
		elseif (i == 1 and j == 3) or (i == 3 and j ==1) then
			t = { m3.z  , m3.y  , m3.x  ,
			      m3.z2 , m3.y2 , m3.x2 ,
			      m3.z3 , m3.y3 , m3.x3 }
		end

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "element", "n,n", "n", 1, function(m3, x, y)

		local i, j
		local t = m3ToTable(m3)
		
		if x < 1 then i = 1
		elseif x > 3 then i = 3
		else i = (x - (x % 1)) end
		
		if y < 1 then j = 1
		elseif y > 3 then j = 3
		else j = y - (y % 1) end

		local n = i + (j - 1) * 3

		return t[n]

	end, true)

	extension:RegisterMethod("mx3", "setElement", "n,n,n", "mx3", 1, function(m3, x, y, z)

		local i, j
		local t = m3ToTable(m3)
		
		if x < 1 then i = 1
		elseif x > 3 then i = 3
		else i = (x - (x % 1)) end
		
		if y < 1 then j = 1
		elseif y > 3 then j = 3
		else j = y - (y % 1) end

		t[i + (j - 1) * 3] = z

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "swapElement", "n,n,n,n", "mx3", 1, function(m3, w, x, y, z)

		local a, b, c, d
		local t = m3ToTable(m3)
		
		if w < 1 then a = 1
		elseif w > 3 then a = 3
		else a = (w - (w % 1)) end
		
		if x < 1 then b = 1
		elseif x > 3 then b = 3
		else b = x - (x % 1) end

		if y < 1 then c = 1
		elseif y > 3 then c = 3
		else c = (y - (y % 1)) end
		
		if z < 1 then d = 1
		elseif z > 3 then d = 3
		else d = z - (z % 1) end

		local i = a + (b - 1) * 3
		local j = c + (d - 1) * 3

		t[i], t[j] = t[j], t[i]

		return tableToMatrix3(t)

	end, true)

	extension:RegisterMethod("mx3", "setDiagonal", "n,n,n", "mx3", 1, function(m3, x, y, z)

		return Matrix3( x    , m3.x2 , m3.x3 ,
			            m3.y , y     , m3.y3 , 
			            m3.z , m3.z2 , z     )

	end, true)

	extension:RegisterMethod("mx3", "setDiagonal", "v", "mx3", 1, function(m3, v)

		return Matrix3( v.x  , m3.x2 , m3.x3 ,
		                m3.y , v.y   , m3.y3 ,
		                m3.z , m3.z2 , v.z   )

	end, true)

	extension:RegisterMethod("mx3", "getX", "", "v", 1, function(m3)

		return Vector( m3.x, m3.x2, m3.x3 )

	end, true)

	extension:RegisterMethod("mx3", "getY", "", "v", 1, function(m3)

		return Vector( m3.y, m3.y2, m3.y3 )

	end, true)

	extension:RegisterMethod("mx3", "getZ", "", "v", 1, function(m3)

		return Vector( m3.z, m3.z2, m3.z3 )

	end, true)

	extension:RegisterMethod("mx3", "toAngle", "", "a", 1, function(m3)

		local p = asin(-m3.x3) * rad2deg
		local y = atan2( m3.x2, m3.x ) * rad2deg
		local r = atan2( m3.y3, m3.z3) * rad2deg 

		return Angle( p, y, r )

	end, true)

	
	--[---------------------------- Functions -------------------------------------]--


	extension:RegisterFunction("matrix", "diagonal3", "mx3", "v", 1, function(m3)

		return Vector( m3.x, m3.y2, m3.z3 )

	end, true)

	extension:RegisterFunction("matrix", "trace3", "mx3", "n", 1, function(m3)

		return ( m3.x + m3.y2 + m3.z3 )

	end, true)

	extension:RegisterFunction("matrix", "det3", "mx3", "n", 1, function(m3)

		return detm3(m3)

	end, true)

	extension:RegisterFunction("matrix", "transpose3", "mx3", "mx3", 1, function(m3)

		return Matrix3( m3.x , m3.x2 , m3.x3 ,
			            m3.y , m3.y2 , m3.y3 ,
			            m3.z , m3.z2 , m3.z3 )

	end, true)

	extension:RegisterFunction("matrix", "adj3", "mx3", "mx3", 1, function(m3)

		return Matrix3( (m3.y2 * m3.z3) - (m3.y3 * m3.z2) , (m3.y3 * m3.z) - (m3.y * m3.z3) , (m3.y * m3.z2) - (m3.y2 * m3.z) , 
			            (m3.x3 * m3.z2) - (m3.x2 * m3.z3) , (m3.x * m3.z3) - (m3.x3 * m3.z) , (m3.x2 * m3.z) - (m3.x * m3.z2) , 
			            (m3.x2 * m3.y2) - (m3.x3 * m3.y2) , (m3.x3 * m3.y) - (m3.x * m3.y3) , (m3.x * m3.y2) - (m3.x2 * m3.y) )

	end, true)

	extension:RegisterFunction("matrix", "mRotation", "v,n", "mx3", 1, function(m3, v, n)

		local a
		local sq = (v.x * v.x + v.y * v.y + v.z * v.z) ^ 0.5
		if sq == 1 then a = v
		elseif sq > 0 then a = Vector(v.x / sq, v.y / sq, v.z / sq)
		else return Matrix3( 0, 0, 0,
			                 0, 0, 0,
			                 0, 0, 0 )
		end

		local b = Vector(a.x * a.x, a.y * a.y, a.z * a.z)
		local ang = n * deg2rad
		local cos = cos(ang)
		local sin = sin(ang)
		local cosmin = 1 - cos

		return Matrix3( b.x + (1 - b.x) * cos,
			            a.x * a.y * cosmin - a.z * sin,
			            a.x * a.z * cosmin + a.y * sin,
			            a.x * a.y * cosmin + a.z * sin,
			            b.y + (1 - b.y) * cos,
			            a.y * a.z * cosmin - a.x * sin,
			            a.x * a.z * cosmin - a.y * sin,
			            a.y * a.z * cosmin + a.x * sin,
			            b.z + (1 - b.z) * cos )
	end, true)



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

	matrix4 = {}
	matrix4.__index = matrix4

	local function Matrix4(w,x,y,z, w2,x2,y2,z2, w3,x3,y3,z3, w4,x4,y4,z4)
		return setmetatable({ w = w  ,  x = x  ,  y = y  ,  z = z  , 
			                 w2 = w2 , x2 = x2 , y2 = y2 , z2 = z2 , 
			                 w3 = w3 , x3 = x3 , y3 = y3 , z3 = z3 ,
			                 w4 = w4 , x4 = x4 , y4 = y4 , z4 = z4 }, matrix4)
																			
	end

	local function isMatrix4(m)

		return istable(m) and #m == 16 and m.w  and m.x  and m.y  and m.z
		                               and m.w2 and m.x2 and m.y2 and m.z2
		                               and m.w3 and m.x3 and m.y3 and m.z3
		                               and m.w4 and m.x4 and m.y4 and m.z4

	end

	extension:RegisterClass("mx4", "matrix4", isMatrix4, EXPR_LIB.NOTNIL)

	extension:RegisterConstructor("mx4", "", Matrix4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), true)
	extension:RegisterConstructor("mx4", "n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n", Matrix4, true)
	extension:RegisterConstructor("mx4", "mx2", function(m2)
		
		return Matrix4( m2.x  , m2.y  , 0 , 0 , 
			            m2.x2 , m2.y2 , 0 , 0 ,
			            0     , 0     , 0 , 0 , 
			            0     , 0     , 0 , 0 )
	
	end, true)
	
	extension:RegisterConstructor("mx4", "mx3", function(m3)
		
		return Matrix4( m3.x  , m3.y  , m3.z  , 0 , 
			            m3.x2 , m3.y2 , m3.z2 , 0 ,
			            m3.x3 , m2.y3 , m3.z3 , 0 , 
			            0     , 0     , 0     , 0 )
	
	end, true)
	
	extension:RegisterConstructor("mx4", "mx2,mx2,mx2,mx2", function(a,b,c,d)

		return Matrix4( a.x  , a.y  , b.x  , b.y  ,
			            a.x2 , a.y2 , b.x2 , b.y2 ,
			            c.x  , c.y  , d.x  , d.y  , 
			            c.x2 , c.y2 , d.x2 , d.y2 )

	end, true)
	
	extension:RegisterConstructor("mx4", "a", function(a)

		ang = Angle(a.p, a.y, a.r)
		local x = ang:Forward()
		local y = ang:Right() * -1
		local z = ang:Up()

		return Matrix4( x.x , y.x , z.x , 0 ,
			            x.y , y.y , z.y , 0 ,
			            x.z , y.z , z.z , 0 ,
			            0   , 0   , 0   , 1 )
	end, true)

	extension:RegisterConstructor("mx4", "a,v", function(a,v)

		ang = Angle(a.p, a.y, a.r)
		local x = ang:Forward()
		local y = ang:Right() * -1
		local z = ang:Up()

		return Matrix4( x.x , y.x , z.x , v.x ,
			            x.y , y.y , z.y , v.y ,
			            x.z , y.z , z.z , v.z ,
			            0   , 0   , 0   , 1   )
	end, true)

	extension:RegisterConstructor("mx4", "e", function(e)

		if IsValid(e) then
			local ph = e:GetPhysicsObject()

			local div = 10000
			local pos = ph:GetPos()
			
			local x = ph:LocalToWorld(Vector(div, 0, 0)) - pos
			local y = ph:LocalToWorld(Vector(0, div, 0)) - pos
			local z = ph:LocalToWorld(Vector(0, 0, div)) - pos

			return Matrix4( x.x / div , y.x / div , z.x / div , pos.x ,
				            x.y / div , y.y / div , z.y / div , pos.y ,
				            x.z / div , y.z / div , z.z / div , pos.z ,
				            0         , 0         , 0         , 1     )
		
		else return Matrix4( 0, 0, 0, 0 ,
			                 0, 0, 0, 0 ,
			                 0, 0, 0, 0 )

		
		end
	end, true)



--[[
	*****************************************************************************************************************************************************
	 	Matrix4 Global Funcs
	*****************************************************************************************************************************************************
]]--
	
	local function identitym4()

		return Matrix4( 1 , 0 , 0 , 0 ,
			            0 , 1 , 0 , 0 ,
			            0 , 0 , 1 , 0 ,
			            0 , 0 , 0 , 1 )
	end
	
	local function m4ToTable(m4)

		return { m4.w  , m4.x  , m4.y  , m4.z  ,
	             m4.w2 , m4.x2 , m4.y2 , m4.z2 ,
	             m4.w3 , m4.x3 , m4.y3 , m4.z3 ,
	             m4.w4 , m4.x4 , m4.y4 , m4.z4 }
	
	end

	local function tableToMatrix4(t)

		return Matrix4( t[1]  , t[2]  , t[3]  , t[4]  ,
			            t[5]  , t[6]  , t[7]  , t[8]  ,
			            t[9]  , t[10] , t[11] , t[12] ,
			            t[13] , t[14] , t[15] , t[16] )

	end


--[[
	*****************************************************************************************************************************************************
		Matrix4 Mathematical Operations
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterOperator("add", "mx4,mx4", "mx4", 1, function(a, b)
		
		return Matrix4( (a.w + b.w)   , (a.x + b.x)   , (a.y + b.y)   , (a.z + b.z)   ,
			            (a.w2 + b.w3) , (a.x2 + b.x2) , (a.y2 + b.y2) , (a.z2 + b.z2) ,
			            (a.w3 + b.w3) , (a.x3 + b.x3) , (a.y3 + b.y3) , (a.z3 + b.z3) ,
			            (a.w4 + b.w4) , (a.x4 + b.x4) , (a.y4 + b.y4) , (a.z4 + b.z4) )
	end, true)

	extension:RegisterOperator("sub", "mx4,mx4", "mx4", 1, function(a, b)
		
		return Matrix4( (a.w - b.w)   , (a.x - b.x)   , (a.y - b.y)   , (a.z - b.z)   ,
			            (a.w2 - b.w2) , (a.x2 - b.x2) , (a.y2 - b.y2) , (a.z2 - b.z2) ,
			            (a.w3 - b.w3) , (a.x3 - b.x3) , (a.y3 - b.y3) , (a.z3 - b.z3) ,
			            (a.w4 - b.w4) , (a.x4 - b.x4) , (a.y4 - b.y4) , (a.z4 - b.z4) )
	end, true)

	extension:RegisterOperator("mul", "n,mx4", "mx4", 1, function(n, m4)
		
		return Matrix4( (n * m4.w)  , (n * m4.x)  , (n * m4.y)  , (n * m4.z)  ,
			            (n * m4.w2) , (n * m4.x2) , (n * m4.y2) , (n * m4.z2) ,
			            (n * m4.w3) , (n * m4.x3) , (n * m4.y3) , (n * m4.z3) ,
			            (n * m4.w4) , (n * m4.x4) , (n * m4.y4) , (n * m4.z4) )
	end, true)

	extension:RegisterOperator("mul", "mx4,n", "mx4", 1, function(m4, n)
		
		return Matrix4( (m4.w * n)  , (m4.x * n)  , (m4.y * n)  , (m4.z * n)  ,
			            (m4.w2 * n) , (m4.x2 * n) , (m4.y2 * n) , (m4.z2 * n) ,
			            (m4.w3 * n) , (m4.x3 * n) , (m4.y3 * n) , (m4.z3 * n) ,
			            (m4.w4 * n) , (m4.x4 * n) , (m4.y4 * n) , (m4.z4 * n) )
	end, true)

	extension:RegisterOperator("mul", "mx4,mx4", "mx4", 1, function(a, b)
		
		return Matrix4( (m4.w * n)  , (m4.x * n)  , (m4.y * n)  , (m4.z * n)  ,
			            (m4.w2 * n) , (m4.x2 * n) , (m4.y2 * n) , (m4.z2 * n) ,
			            (m4.w3 * n) , (m4.x3 * n) , (m4.y3 * n) , (m4.z3 * n) ,
			            (m4.w4 * n) , (m4.x4 * n) , (m4.y4 * n) , (m4.z4 * n) )
	end, true)

	extension:RegisterOperator("mul", "mx4,mx4", "mx4", 1, function(a, b)
		
		return Matrix4( (a.w * b.w) + (a.x * b.w2) + (a.y * b.w3) + (a.z * b.w4) ,
			            (a.w * b.x) + (a.x * b.x2) + (a.y * b.x3) + (a.z * b.x4) ,
			            (a.w * b.y) + (a.x * b.y2) + (a.y * b.y3) + (a.z * b.y4) ,
			            (a.w * b.z) + (a.x * b.z2) + (a.y * b.z3) + (a.z * b.z4) ,

			            (a.w2 * b.w) + (a.x2 * b.w2) + (a.y2 * b.w3) + (a.z2 * b.w4) ,
			            (a.w2 * b.x) + (a.x2 * b.x2) + (a.y2 * b.x3) + (a.z2 * b.x4) ,
			            (a.w2 * b.y) + (a.x2 * b.y2) + (a.y2 * b.y3) + (a.z2 * b.y4) ,
			            (a.w2 * b.z) + (a.x2 * b.z2) + (a.y2 * b.z3) + (a.z2 * b.z4) ,

			            (a.w3 * b.w) + (a.x3 * b.w2) + (a.y3 * b.w3) + (a.z3 * b.w4) ,
			            (a.w3 * b.x) + (a.x3 * b.x2) + (a.y3 * b.x3) + (a.z3 * b.x4) ,
			            (a.w3 * b.y) + (a.x3 * b.y2) + (a.y3 * b.y3) + (a.z3 * b.y4) ,
			            (a.w3 * b.z) + (a.x3 * b.z2) + (a.y3 * b.z3) + (a.z3 * b.z4) ,

			            (a.w4 * b.w) + (a.x4 * b.w2) + (a.y4 * b.w3) + (a.z4 * b.w4) ,
			            (a.w4 * b.x) + (a.x4 * b.x2) + (a.y4 * b.x3) + (a.z4 * b.x4) ,
			            (a.w4 * b.y) + (a.x4 * b.y2) + (a.y4 * b.y3) + (a.z4 * b.y4) ,
			            (a.w4 * b.z) + (a.x4 * b.z2) + (a.y4 * b.z3) + (a.z4 * b.z4) )
	end, true)

	extension:RegisterOperator("div", "mx4,n", "mx4", 1, function(m4, n)
		
		return Matrix4( (m4.w / n)  , (m4.x / n)  , (m4.y / n)  , (m4.z / n)  ,
			            (m4.w2 / n) , (m4.x2 / n) , (m4.y2 / n) , (m4.z2 / n) ,
			            (m4.w3 / n) , (m4.x3 / n) , (m4.y3 / n) , (m4.z3 / n) ,
			            (m4.w4 / n) , (m4.x4 / n) , (m4.y4 / n) , (m4.z4 / n) )
	end, true)

	extension:RegisterOperator("exp", "mx4,n", "mx4", 1, function(m4, n)
		
		if n == 0 then return identitym4()
		elseif n == 1 then return m4
		elseif n == 2 then return Matrix4( (a.w * b.w) + (a.x * b.w2) + (a.y * b.w3) + (a.z * b.w4) ,
			                               (a.w * b.x) + (a.x * b.x2) + (a.y * b.x3) + (a.z * b.x4) ,
			                               (a.w * b.y) + (a.x * b.y2) + (a.y * b.y3) + (a.z * b.y4) ,
			                               (a.w * b.z) + (a.x * b.z2) + (a.y * b.z3) + (a.z * b.z4) ,

			                               (a.w2 * b.w) + (a.x2 * b.w2) + (a.y2 * b.w3) + (a.z2 * b.w4) ,
			                               (a.w2 * b.x) + (a.x2 * b.x2) + (a.y2 * b.x3) + (a.z2 * b.x4) ,
			                               (a.w2 * b.y) + (a.x2 * b.y2) + (a.y2 * b.y3) + (a.z2 * b.y4) ,
			                               (a.w2 * b.z) + (a.x2 * b.z2) + (a.y2 * b.z3) + (a.z2 * b.z4) ,

			                               (a.w3 * b.w) + (a.x3 * b.w2) + (a.y3 * b.w3) + (a.z3 * b.w4) ,
			                               (a.w3 * b.x) + (a.x3 * b.x2) + (a.y3 * b.x3) + (a.z3 * b.x4) ,
			                               (a.w3 * b.y) + (a.x3 * b.y2) + (a.y3 * b.y3) + (a.z3 * b.y4) ,
			                               (a.w3 * b.z) + (a.x3 * b.z2) + (a.y3 * b.z3) + (a.z3 * b.z4) ,

			                               (a.w4 * b.w) + (a.x4 * b.w2) + (a.y4 * b.w3) + (a.z4 * b.w4) ,
			                               (a.w4 * b.x) + (a.x4 * b.x2) + (a.y4 * b.x3) + (a.z4 * b.x4) ,
			                               (a.w4 * b.y) + (a.x4 * b.y2) + (a.y4 * b.y3) + (a.z4 * b.y4) ,
			                               (a.w4 * b.z) + (a.x4 * b.z2) + (a.y4 * b.z3) + (a.z4 * b.z4) )
	    else return Matrix4( 0, 0, 0, 0,
	    	                 0, 0, 0, 0,
	    	                 0, 0, 0, 0,
	    	                 0, 0, 0, 0 ) 
	    end
	end, true)


--[[
	*****************************************************************************************************************************************************
		Matrix4 Logical Operations
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterOperator("eq", "mx4,mx4", "b", 1, function(a, b)

		if (a.w - b.w) <= 0 and (b.w - a.w) <= 0 and
		   (a.x - b.x) <= 0 and (b.x - a.x) <= 0 and
		   (a.y - b.y) <= 0 and (b.y - a.y) <= 0 and
		   (a.z - b.z) <= 0 and (b.z - a.z) <= 0 and

		   (a.w2 - b.w2) <= 0 and (b.w2 - a.w2) <= 0 and
		   (a.x2 - b.x2) <= 0 and (b.x2 - a.x2) <= 0 and
		   (a.y2 - b.y2) <= 0 and (b.y2 - a.y2) <= 0 and
		   (a.z2 - b.z2) <= 0 and (b.z2 - a.z2) <= 0 and

		   (a.w3 - b.w3) <= 0 and (b.w3 - a.w3) <= 0 and
		   (a.x3 - b.x3) <= 0 and (b.x3 - a.x3) <= 0 and
		   (a.y3 - b.y3) <= 0 and (b.y3 - a.y3) <= 0 and
		   (a.z3 - b.z3) <= 0 and (b.z3 - a.z3) <= 0 and

		   (a.w4 - b.w4) <= 0 and (b.w4 - a.w4) <= 0 and
		   (a.x4 - b.x4) <= 0 and (b.x4 - a.x4) <= 0 and
		   (a.y4 - b.y4) <= 0 and (b.y4 - a.y4) <= 0 and
		   (a.z4 - b.z4) <= 0 and (b.z4 - a.z4) <= 0
		   
		   then return 1 else return 0 end

	end, true)

	extension:RegisterOperator("eq", "mx4,mx4", "b", 1, function(a, b)

		if (a.w - b.w) > 0 and (b.w - a.w) > 0 and
		   (a.x - b.x) > 0 and (b.x - a.x) > 0 and
		   (a.y - b.y) > 0 and (b.y - a.y) > 0 and
		   (a.z - b.z) > 0 and (b.z - a.z) > 0 and

		   (a.w2 - b.w2) > 0 and (b.w2 - a.w2) > 0 and
		   (a.x2 - b.x2) > 0 and (b.x2 - a.x2) > 0 and
		   (a.y2 - b.y2) > 0 and (b.y2 - a.y2) > 0 and
		   (a.z2 - b.z2) > 0 and (b.z2 - a.z2) > 0 and

		   (a.w3 - b.w3) > 0 and (b.w3 - a.w3) > 0 and
		   (a.x3 - b.x3) > 0 and (b.x3 - a.x3) > 0 and
		   (a.y3 - b.y3) > 0 and (b.y3 - a.y3) > 0 and
		   (a.z3 - b.z3) > 0 and (b.z3 - a.z3) > 0 and

		   (a.w4 - b.w4) > 0 and (b.w4 - a.w4) > 0 and
		   (a.x4 - b.x4) > 0 and (b.x4 - a.x4) > 0 and
		   (a.y4 - b.y4) > 0 and (b.y4 - a.y4) > 0 and
		   (a.z4 - b.z4) > 0 and (b.z4 - a.z4) > 0
		   
		   then return 1 else return 0 end

	end, true)

	extension:RegisterOperator("neg", "mx4", "mx4", 1, function(m4)

		return Matrix4( -m4.w  , -m4.x  , -m4.y  , -m4.z  ,
	                    -m4.w2 , -m4.x2 , -m4.y2 , -m4.z2 ,
	                    -m4.w3 , -m4.x3 , -m4.y3 , -m4.z3 ,
	                    -m4.w4 , -m4.x4 , -m4.y4 , -m4.z4 )
	end, true)

	extension:RegisterOperator("is", "mx4", "b", 1, function(m4)

		if a.w > 0 and -a.w  > 0 and
		   a.x > 0 and -a.x  > 0 and
		   a.y > 0 and -a.y > 0 and
		   a.z > 0 and -a.z > 0 and

		   a.w2 > 0 and -a.w2 > 0 and
		   a.x2 > 0 and -a.x2 > 0 and
		   a.y2 > 0 and -a.y2 > 0 and
		   a.z2 > 0 and -a.z2 > 0 and

		   a.w3 > 0 and -a.w3 > 0 and
		   a.x3 > 0 and -a.x3 > 0 and
		   a.y3 > 0 and -a.y3 > 0 and
		   a.z3 > 0 and -a.z3 > 0 and

		   a.w4 > 0 and -a.w4 > 0 and
		   a.x4 > 0 and -a.x4 > 0 and
		   a.y4 > 0 and -a.y4 > 0 and
		   a.z4 > 0 and -a.z4 > 0
		   
		   then return 1 else return 0 end

	end, true)


--[[
	*****************************************************************************************************************************************************
		Matrix4 Attributes
	*****************************************************************************************************************************************************
]]--
	extension:RegisterAttribute("mx4", "w", "n")
	extension:RegisterAttribute("mx4", "x", "n")
	extension:RegisterAttribute("mx4", "y", "n")
	extension:RegisterAttribute("mx4", "z", "n")

	extension:RegisterAttribute("mx4", "w2", "n")
	extension:RegisterAttribute("mx4", "x2", "n")
	extension:RegisterAttribute("mx4", "y2", "n")
	extension:RegisterAttribute("mx4", "z2", "n")

	extension:RegisterAttribute("mx4", "w3", "n")
	extension:RegisterAttribute("mx4", "x3", "n")
	extension:RegisterAttribute("mx4", "y3", "n")
	extension:RegisterAttribute("mx4", "z3", "n")

	extension:RegisterAttribute("mx4", "w4", "n")
	extension:RegisterAttribute("mx4", "x4", "n")
	extension:RegisterAttribute("mx4", "y4", "n")
	extension:RegisterAttribute("mx4", "z4", "n")
	

--[[
	*****************************************************************************************************************************************************
		Matrix4 Methods
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterMethod("mx4", "toString", "", "s", 1, function(m4)
		
		return table.ToString(m4, "Matrix4", true)

	end, true)

	extension:RegisterMethod("mx4", "setRow", "n,n,n,n,n", "mx4", 1, function(m4,n,a,b,c,d)

		local i
		local t = m4ToTable(m4)
		if n < 1 then i = 1
		elseif n > 4 then i = 4
		else i = n - (n % 1) end
		
		t[(i * 4) - 3] = a
		t[(i * 4) - 2] = b
		t[(i * 4) - 1] = c
		t[i * 4] = d

		return tableToMatrix4(t)

	end, true)

	extension:RegisterMethod("mx4", "setColumn", "n,n,n,n,n", "mx4", 1, function(m4,n,a,b,c,d)

		local i
		local t = m4ToTable(m4)
		if n < 1 then i = 1
		elseif n > 4 then i = 4
		else i = n - (n % 1) end
		
		t[i] = a
		t[i + 4] = b
		t[i + 8] = c
		t[i + 12] = d

		return tableToMatrix4(t)

	end, true)

	extension:RegisterMethod("mx4", "swapRows", "n,n", "mx4", 1, function(m4,a,b)

		local i, j
		local t = m4ToTable(m4)
		if a < 1 then i = 1
		elseif a > 4 then i = 4
		else i = a - (a % 1) end

		if b < 1 then j = 1
		elseif b > 4 then j = 4
		else j = b - (b % 1) end
		
		if i == j then return m4
		elseif (i == 1 and j == 2) or (i == 2 and j == 1) then
			t = { m4.w2 , m4.x2 , m4.y2 , m4.z2 ,
			      m4.w  , m4.x  , m4.y  , m4.z  ,
			      m4.w3 , m4.x3 , m4.y3 , m4.z3 ,
			      m4.w4 , m4.x4 , m4.y4 , m4.z4  }

		elseif (i == 2 and j == 3) or (i == 3 and j == 2) then
			t = { m4.w  , m4.x  , m4.y  , m4.z  ,
			      m4.w3 , m4.x3 , m4.y3 , m4.z3 ,
			      m4.w2 , m4.x2 , m4.y2 , m4.z2 ,
			      m4.w4 , m4.x4 , m4.y4 , m4.z4  }

	    elseif (i == 3 and j == 4) or (i == 4 and j == 3) then
			t = { m4.w  , m4.x  , m4.y  , m4.z  ,
			      m4.w2 , m4.x2 , m4.y2 , m4.z2 ,
			      m4.w4 , m4.x4 , m4.y4 , m4.z4 ,
			      m4.w3 , m4.x3 , m4.y3 , m4.z3  }

		elseif (i == 1 and j == 3) or (i == 3 and j == 1) then
			t = { m4.w3 , m4.x3 , m4.y3 , m4.z3 ,
			      m4.w2 , m4.x2 , m4.y2 , m4.z2 ,
			      m4.w  , m4.x  , m4.y  , m4.z  ,
			      m4.w4 , m4.x4 , m4.y4 , m4.z4  }

		elseif (i == 2 and j == 4) or (i == 4 and j == 2) then
			t = { m4.w  , m4.x  , m4.y  , m4.z  ,
			      m4.w4 , m4.x4 , m4.y4 , m4.z4 ,
			      m4.w3 , m4.x3 , m4.y3 , m4.z3 ,
			      m4.w2 , m4.x2 , m4.y2 , m4.z2  }

		elseif (i == 1 and j == 4) or (i == 4 and j == 1) then
			t = { m4.w4 , m4.x4 , m4.y4 , m4.z4 ,
			      m4.w2 , m4.x2 , m4.y2 , m4.z2 ,
			      m4.w3 , m4.x3 , m4.y3 , m4.z3 ,
			      m4.w  , m4.x  , m4.y  , m4.z   }

		end

		return tableToMatrix4(t)

	end, true)

	extension:RegisterMethod("mx4", "swapColumns", "n,n", "mx4", 1, function(m4,a,b)

		local i, j
		local t = m4ToTable(m4)
		if a < 1 then i = 1
		elseif a > 4 then i = 4
		else i = a - (a % 1) end

		if b < 1 then j = 1
		elseif b > 4 then j = 4
		else j = b - (b % 1) end
		
		if i == j then return m4
		elseif (i == 1 and j == 2) or (i == 2 and j == 1) then
			t = { m4.x  , m4.w  , m4.y  , m4.z  ,
			      m4.x2 , m4.w2 , m4.y2 , m4.z2 ,
			      m4.x3 , m4.w3 , m4.y3 , m4.z3 ,
			      m4.x4 , m4.w4 , m4.y4 , m4.z4  }

		elseif (i == 2 and j == 3) or (i == 3 and j == 2) then
			t = { m4.w  , m4.y , m4.x  , m4.z  ,
			      m4.w2 , m4.y2 , m4.x2 , m4.z2 ,
			      m4.w3 , m4.y3 , m4.y3 , m4.z3 ,
			      m4.w4 , m4.y4 , m4.x4 , m4.z4  }

	    elseif (i == 3 and j == 4) or (i == 4 and j == 3) then
			t = { m4.w  , m4.x  , m4.z  , m4.y  ,
			      m4.w2 , m4.x2 , m4.z2 , m4.y2 ,
			      m4.w3 , m4.x3 , m4.z3 , m4.y3 ,
			      m4.w4 , m4.x4 , m4.z4 , m4.y4  }

		elseif (i == 1 and j == 3) or (i == 3 and j == 1) then
			t = { m4.y  , m4.x  , m4.w  , m4.z  ,
			      m4.y2 , m4.x2 , m4.w2 , m4.z2 ,
			      m4.y3 , m4.x3 , m4.w3 , m4.z3 ,
			      m4.y4 , m4.x4 , m4.w4 , m4.z4  }

		elseif (i == 2 and j == 4) or (i == 4 and j == 2) then
			t = { m4.w  , m4.z  , m4.y  , m4.x  ,
			      m4.w2 , m4.z2 , m4.y2 , m4.x2 ,
			      m4.w3 , m4.z3 , m4.y3 , m4.x3 ,
			      m4.w4 , m4.z4 , m4.y4 , m4.x4  }

		elseif (i == 1 and j == 4) or (i == 4 and j == 1) then
			t = { m4.z , m4.y , m4.x , m4.w ,
			      m4.z2 , m4.y2 , m4.x2 , m4.w2 ,
			      m4.z3 , m4.y3 , m4.x3 , m4.w3 ,
			      m4.z4  , m4.y4  , m4.x4  , m4.w4   }

		end

		return tableToMatrix4(t)

	end, true)

	extension:RegisterMethod("mx4", "element", "n,n", "n", 1, function(m4,a,b)

		local i, j
		local t = m4ToTable(m4)
		if a < 1 then i = 1
		elseif a > 4 then i = 4
		else i = a - (a % 1) end

		if b < 1 then j = 1
		elseif b > 4 then j = 4
		else j = b - (b % 1) end
		
		local n = i + (j - 1) * 4

		return t[n]

	end, true)

	extension:RegisterMethod("mx4", "setElement", "n,n", "mx4", 1, function(m4,a,b,c)

		local i, j
		local t = m4ToTable(m4)
		if a < 1 then i = 1
		elseif a > 4 then i = 4
		else i = a - (a % 1) end

		if b < 1 then j = 1
		elseif b > 4 then j = 4
		else j = b - (b % 1) end
		
		t[i + (j - 1) * 4] = c

		return tableToMatrix4(t)

	end, true)

	extension:RegisterMethod("mx4", "swapElements", "n,n,n,n", "mx4", 1, function(m4,a,b,c,d)

		local i, j, k, l
		local t = m4ToTable(m4)
		if a < 1 then i = 1
		elseif a > 4 then i = 4
		else i = a - (a % 1) end

		if b < 1 then j = 1
		elseif b > 4 then j = 4
		else j = b - (b % 1) end

		if c < 1 then k = 1
		elseif c > 4 then k = 4
		else k = c - (c % 1) end

		if d < 1 then l = 1
		elseif d > 4 then l = 4
		else l = d - (d % 1) end
		
		local n = i + (j - 1) * 4
		local n2 = k + (l - 1) * 4

		t[n], t[n2] = t[n2], t[n]

		return tableToMatrix4(t)

	end, true)

	extension:RegisterMethod("mx4", "setDiagonal", "n,n,n,n", "mx4", 1, function(m4,a,b,c,d)

		return Matrix4( a     , m4.x  , m4.y  , m4.z   ,
		                m4.w2 , b     , m4.y2 , m4.z2  ,
		                m4.w3 , m4.x3 , c     , m4. z3 ,
		                m4.w4 , m4.x4 , m4.y4 , d      )

	end, true)

	extension:RegisterMethod("mx4", "getX", "", "v", 1, function(m4)

		return Vector( m4.w , m4.w2 , m4.w3 )

	end, true)

	extension:RegisterMethod("mx4", "getY", "", "v", 1, function(m4)

		return Vector( m4.x , m4.x2 , m4.x3 )

	end, true)

	extension:RegisterMethod("mx4", "getZ", "", "v", 1, function(m4)

		return Vector( m4.y , m4.y2 , m4.y3 )

	end, true)

	extension:RegisterMethod("mx4", "getPos", "", "v", 1, function(m4)

		return Vector( m4.z , m4.z2 , m4.z3 )

	end, true)

	--[---------------------------- Functions -------------------------------------]--

	extension:RegisterFunction("matrix", "trace4", "mx4", "n", 1, function(m4)

		return ( m4.w + m4.x2 + m4.y3 + m4.z4 )

	end, true)

	extension:RegisterFunction("matrix", "transpose4", "mx4", "mx4", 1, function(m4)

		return Matrix4( m4.w , m4.w2 , m4.w3 , m4.w4 ,
			            m4.x , m4.x2 , m4.x3 , m4.x4 ,
			            m4.y , m4.y2 , m4.y3 , m4.y4 ,
			            m4.z , m4.z2 , m4.z3 , m4.z4 )

	end, true)

	extension:RegisterFunction("matrix", "inverseA", "mx4", "mx4", 1, function(m4)

		local z = (m4.w * m4.z) + (m4.w2 * m4.z2) + (m4.w3 + m4.z3)
		local z2 = (m4.x * m4.z) + (m4.x2 * m4.z2) + (m4.x3 + m4.z3)
		local z3 = (m4.y * m4.z) + (m4.y2 * m4.z2) + (m4.y3 + m4.z3)

		return Matrix4( m4.w , m4.w2 , m4.w3 , -z  ,
			            m4.x , m4.x2 , m4.x3 , -z2 ,
			            m4.y , m4.y2 , m4.y3 , -z3 ,
			            0    , 0     , 0     , 1   )

	end, true)

--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--
--[[||||||||||||||||||||||||||||||||||||||||||	E  N  D     O  F    E  X  T  E  N  S  I  O  N  ||||||||||||||||||||||||||||||||||||||||||||||||||||||]]--
--[[-------------------------------------------------------------------------------------------------------------------------------------------------]]--

extension:EnableExtension();