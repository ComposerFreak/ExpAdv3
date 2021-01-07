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

	local extension = EXPR_LIB.RegisterExtension("quaternion");

--[[
	*****************************************************************************************************************************************************
		Register quaternion class
	*****************************************************************************************************************************************************
]]--
	
	quaternion = {}
	quaternion.__index = quaternion

	local function Quaternion(r,i,j,k)

		return setmetatable({r = r, i = i, j = j, k = k}, quaternion)

	end

	local function isQuaternion(q)

		return istable(q) and #q == 4 and q.r and q.i and q.j and q.k

	end

	extension:RegisterClass("q", {"quaternion", "quat"}, isQuaternion, EXPR_LIB.NOTNIL);

	extension:RegisterConstructor("q", "n", function(n) return Quaternion(n,0,0,0) end, true);
	extension:RegisterConstructor("q", "", function() return Quaternion(1,0,0,0) end, true);
	extension:RegisterConstructor("q", "n,n,n,n", function(r,i,j,k) return Quaternion(r,i,j,k) end, true);
	extension:RegisterConstructor("q", "v", function(v) return Quaternion(0, v.x, v.y, v.z) end, true);
	extension:RegisterConstructor("q", "a", function(a) return angToQuat( Angle(a.p, a.y, a.r) ) end, true);
	extension:RegisterConstructor("q", "e", function(e)
		
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			return angToQuat( ph:GetAngles() );
		end
	end, true);

	extension:RegisterConstructor("q", "v,v", function(a,b)

		local x, z = a, b
		local y = z:Cross(x):GetNormalized()

		local ang = x:Angle()
		if ang.p > 180 then ang.p = ang.p - 360 end
		if ang.y > 180 then ang.y = ang.y - 360 end

		local yaw = Vector(0, 1, 0)
		yaw:Rotate(Angle(0, ang.y, 0))

		local roll = acos(clamp(y:Dot(yaw), -1, 1)) * rad2deg
		if y.z < 0 then roll = -roll end

		return angToQuat( Angle(ang.p, ang.y, roll) );

	end, true);



--[[
	*****************************************************************************************************************************************************
		Quaternion Global Funcs
	*****************************************************************************************************************************************************
]]--
	
	local function qmul(a,b)
		return Quaternion( 

			(a.r * b.r) - (a.i * b.i) - (a.j * b.j) - (a.k * b.k),
			(a.r * b.i) + (a.i * b.r) + (a.j * b.k) - (a.k * b.j),
			(a.r * b.j) - (a.i * b.k) + (a.j * b.r) + (a.k * b.i),
			(a.r * b.k) + (a.i * b.j) - (a.j * b.i) + (a.k * b.r)

			)
	end

	local function qlog(q)
		
		local sq = sqrt((q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k * q.k))
		if sq == 0 then return Quaternion(-1e+100,0,0,0) end

		local x = Quaternion( (q.r / sq), (q.i / sq), (q.j / sq), (q.k / sq) )
		local y = acos(x.r)
		local z = sqrt((x.r * x.r) + (x.i * x.i) + (x.j * x.j) + (x.k * x.k))

		return abs(z) > 0 and Quaternion(log(sq), (y * x.i / z), (y * x.j / z), (y * x.k / z)) or Quaternion(log(sq),0,0,0)

	end

	local function qexp(q)

		local sq = sqrt((q.i * q.i) + (q.j * q.j) + (q.k * q.k))
		local sine = sq == !0 and Quaternion( 0, (q.i * sin(sq) / sq), (q.j * sin(sq) / sq), (q.k * sin(sq) / sq) ) or Quaternion(0, 0, 0, 0)
		local pow = exp(q.r)

		return Quaternion((pow * cos(sq)), (pow * sine.i), (pow * sine.j), (pow * sine.k))

	end

	function angToQuat(a)
		
		local P = a.p * deg2rad * 0.5
		local Y = a.y * deg2rad * 0.5
		local R = a.r * deg2rad * 0.5

		local qP = Quaternion(cos(P), 0, sin(P), 0)
		local qY = Quaternion(cos(Y), 0, 0, sin(Y))
		local qR = Quaternion(cos(R), sin(R), 0, 0)
		
		return qmul(qY, qmul(qP, qR));

	end

--[[
	*****************************************************************************************************************************************************
		Quaternion Mathematical Operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("add", "q,q", "q", 1, function(a,b)
		return Quaternion( (a.r + b.r), (a.i + b.i), (a.j + b.j), (a.k + b.k) )
	end, true)

	extension:RegisterOperator("add", "n,q", "q", 1, function(n,q)
		return Quaternion( (n + q.r), q.i, q.j, q.k )
	end, true)

	extension:RegisterOperator("add", "q,n", "q", 1, function(q,n)
		return Quaternion( (q.r + n), q.i, q.j, q.k )
	end, true)

	//

	extension:RegisterOperator("sub", "q,q", "q", 1, function(a,b)
		return Quaternion( (a.r - b.r), (a.i - b.i), (a.j - b.j), (a.k - b.k) )
	end, true)

	extension:RegisterOperator("sub", "n,q", "q", 1, function(n,q)
		return Quaternion( (n - q.r), -q.i, -q.j, -q.k )
	end, true)

	extension:RegisterOperator("sub", "q,n", "q", 1, function(q,n)
		return Quaternion( (q.r - n), q.i, q.j, q.k )
	end, true)

	//

	extension:RegisterOperator("mul", "n,q", "q", 1, function(n,q)
		return Quaternion( (n * q.r), (n * q.i), (n * q.j), (n * q.k) )
	end, true)

	extension:RegisterOperator("mul", "q,n", "q", 1, function(q,n)
		return Quaternion( (q.r * n), (q.i * n), (q.j * n), (q.k * n) )
	end, true)

	extension:RegisterOperator("mul", "v,q", "q", 1, function(v,q)

		return Quaternion( 
			(-v.x * q.i) - (v.y * q.j) - (v.z * q.k),
			 (v.x * q.r) + (v.y * q.k) - (v.z * q.j),
			 (v.y * q.r) + (v.z * q.i) - (v.x * q.k),
			 (v.z * q.r) + (v.x * q.j) - (v.y * q.i) )

	end, true)

	extension:RegisterOperator("mul", "q,v", "q", 1, function(q,v)

		return Quaternion( 
			(-q.i * v.x) - (q.j * v.y) - (q.k * v.z),
			 (q.r * v.x) + (q.j * v.z) - (q.k * v.y),
			 (q.r * v.y) + (q.k * v.x) - (q.i * v.z),
			 (q.r * v.z) + (q.i * v.y) - (q.j * v.x) )

	end, true)

	extension:RegisterOperator("mul", "q,q", "q", 1, function(a,b)
		return qmul(a,b);
	end, true)

	//

	extension:RegisterOperator("div", "n,q", "q", 1, function(n,q)
		
		local divisor = ((q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k * q.k))

		return Quaternion( 
			(n * q.r) / divisor,
			(-n * q.i) / divisor,
			(-n * q.j) / divisor,
			(-n * q.k) / divisor )

	end, true)

	extension:RegisterOperator("div", "q,n", "q", 1, function(q,n)

		return Quaternion( (q.r / n), (q.i / n), (q.j / n), (q.k / n) )
		
	end, true)

	extension:RegisterOperator("div", "q,q", "q", 1, function(a,b)
		
		local divisor = ((b.r * b.r) + (b.i * b.i) + (b.j * b.j) + (b.k * b.k))

		return Quaternion( 

			(a.r * b.r) + (a.i * b.i) + (a.j * b.j) + (a.k * b.k) / divisor,
			(-a.r * b.i) + (a.i * b.r) - (a.j * b.k) + (a.k * b.j) / divisor, 
			(-a.r * b.j) + (a.j * b.r) - (a.k * b.i) + (a.i * b.k) / divisor,
			(-a.r * b.k) + (a.k * b.r) - (a.i * b.j) + (a.j * b.i) / divisor

			)
	end, true)

	//

	extension:RegisterOperator("exp", "n,q", "q", 1, function(n,q)
		
		if n == 0 then return Quaternion(0, 0, 0, 0) end	
		local l = log(n)
		local a = Quaternion((l * q.r), (l * q.i), (l * q.j), (l * q.k))

		return qexp(a)
		
	end, true)

	extension:RegisterOperator("exp", "q,n", "q", 1, function(q,n)

		local lq = qlog(q)
		local a = Quaternion((lq.r * n), (lq.i * n), (lq.j * n), (lq.k * n))

		return qexp(a)
		
	end, true)

	// 	TODO:
	//	add number,vector to quaternion operations, vice versa

--[[
	*****************************************************************************************************************************************************
		Quaternion Logical Operations
	*****************************************************************************************************************************************************
]]--
	
	extension:RegisterOperator("eq", "q,q", "b", 1, function(a, b)

		if (a.r - b.r) <= 0 and (a.r - b.r) >= 0 and
		   (a.i - b.i) <= 0 and (a.i - b.i) >= 0 and
		   (a.j - b.j) <= 0 and (a.j - b.j) >= 0 and
		   (a.k - b.k) <= 0 and (a.k - b.k) >= 0
		   
		   then return 1 else return 0 end

	end, true)

	extension:RegisterOperator("neq", "q,q", "b", 1, function(a, b)

		if (a.r - b.r) > 0 || (a.r - b.r) < 0 ||
		   (a.i - b.i) > 0 || (a.i - b.i) < 0 ||
		   (a.j - b.j) > 0 || (a.j - b.j) < 0 ||
		   (a.k - b.k) > 0 || (a.k - b.k) < 0
		   
		   then return 1 else return 0 end

	end, true)

--[[
	*****************************************************************************************************************************************************
		Quaternion Attributes
	*****************************************************************************************************************************************************
]]--

	extension:RegisterAttribute("q", "r", "n")
	extension:RegisterAttribute("q", "i", "n")
	extension:RegisterAttribute("q", "j", "n")
	extension:RegisterAttribute("q", "k", "n")

--[[
	*****************************************************************************************************************************************************
		Quaternion Methods
	*****************************************************************************************************************************************************
]]--

	extension:RegisterMethod("q", "toString", "", "", 1, function(q)

		local quatString = table.ToString( q, "Quaternion", true )
		return quatString;

	end, true)


	//

	extension:RegisterMethod("q", "setR", "n", "", 0, function(q,n)
		q.r = n
	end, true)

	extension:RegisterMethod("q", "setI", "n", "", 0, function(q,n)
		q.i = n
	end, true)

	extension:RegisterMethod("q", "setJ", "n", "", 0, function(q,n)
		q.j = n
	end, true)

	extension:RegisterMethod("q", "setK", "n", "", 0, function(q,n)
		q.k = n
	end, true)

	//

	extension:RegisterMethod("q", "clone", "", "q", 1, function(q)
		return Quaternion(q.r, q.i, q.j, q.k);
	end, true)

	//

	extension:RegisterMethod("q", "withR", "", "q", 1, function(q,n)
		 return Quaternion(n, q.i, q.j, q.k);
	end, true)

	extension:RegisterMethod("q", "withI", "", "q", 1, function(q,n)
		 return Quaternion(q.r, n, q.j, q.k);
	end, true)

	extension:RegisterMethod("q", "withJ", "", "q", 1, function(q,n)
		 return Quaternion(q.r, q.i, n, q.k);
	end, true)

	extension:RegisterMethod("q", "withK", "", "q", 1, function(q,n)
		 return Quaternion(q.r, q.i, q.j, n);
	end, true)

	//

	--[[ Get Quaternion ]]--

	extension:RegisterMethod("q", "vec", "", "v", 1, function(q)
		return Vector(q.i, q.j, q.k);
	end, true)

	extension:RegisterMethod("q", "getR", "", "n", 1, function(q)
		 return q.r;
	end, true)

	extension:RegisterMethod("q", "getI", "", "n", 1, function(q)
		 return q.i;
	end, true)

	extension:RegisterMethod("q", "getJ", "", "n", 1, function(q)
		 return q.j;
	end, true)

	extension:RegisterMethod("q", "getK", "", "n", 1, function(q)
		 return q.k;
	end, true)

	//

	extension:RegisterMethod("q", "abs", "", "q", 1, function(q)

		return sqrt((q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k * q.k))

	end, true)

	extension:RegisterMethod("q", "inv", "", "q", 1, function(q)

		local divisor = (q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k * q.k)

		return Quaternion(q.r / divisor, -q.i / divisor, -q.j / divisor, -q.k / divisor)

	end, true)

	extension:RegisterMethod("q", "conj", "", "q", 1, function(q)
		return Quaternion(q.r, -q.i, -q.j, -q.k);
	end, true)

	extension:RegisterMethod("q", "exp", "", "q", 1, function(q)

		return qexp(q);

	end, true)

	extension:RegisterMethod("q", "log", "", "q", 1, function(q)

		return qlog(q);

	end, true)

	extension:RegisterMethod("q", "qMod", "", "q", 1, function(q)

		if q.i < 0 then 
			return Quaternion(-q.r, -q.i, -q.j, -q.k)
		else
			return Quaternion(q.r, q.i, q.j, q.k)
		end

	end, true)

	//

	extension:RegisterMethod("q", "forward", "", "v", 1, function(q)

		local qR, qI, qJ, qK = q.r, q.i, q.j, q.k
		local qI2, qJ2, qK2 = 2 * qI, 2 * qJ, 2 * qK

		return Vector( (qR * qR + qI * qI - qJ *qJ - qK * qK), (qJ2 * qI + qK2 * qR), (qK2 * qI - qJ2 * qR))

	end, true)

	extension:RegisterMethod("q", "right", "", "v", 1, function(q)

		local qR, qI, qJ, qK = q.r, q.i, q.j, q.k
		local qI2, qJ2, qK2 = qI * 2, qJ * 2, qK *2

		return Vector( (qK2 * qR - qI2 * qJ), (qI * qI - qR * qR + qK * qK - qJ * qJ), (-qI2 * qR - qJ2 * qK) )
		
	end, true)

	extension:RegisterMethod("q", "up", "", "v", 1, function(q)

		local qR, qI, qJ, qK = q.r, q.i, q.j, q.k
		local qI2, qJ2, qK2 = 2 * qI, 2 * qJ, 2 * qK

		return Vector( (qK2 * qR + qI2 * qK), (qJ2 * qK - qI2 * qR), (qR *qR - qI * qI - qJ *qJ + qK * qK) )
		
	end, true)

	extension:RegisterMethod("q", "dot", "q", "n", 1, function(a,b)

		return (a.r * b.r) + (a.i * b.i) + (a.j * b.j) + (a.k * b.k)

	end, true)

	extension:RegisterMethod("q", "normalized", "", "q", 1, function(q)

		local len = sqrt((q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k * q.k))

		return Quaternion((q.r / len), (q.i / len), (q.j / len), (q.k / len))

	end, true)

--[[
	*****************************************************************************************************************************************************
		Quaternion Functions
	*****************************************************************************************************************************************************
]]--

	extension:RegisterLibrary("quaternion");

	extension:RegisterFunction("quaternion", "qi", "", "q", 1, function()
		return Quaternion(0,1,0,0);
	end, true)

	extension:RegisterFunction("quaternion", "qi", "n", "q", 1, function(n)
		return Quaternion(0,n,0,0);
	end, true)

	extension:RegisterFunction("quaternion", "qj", "", "q", 1, function()
		return Quaternion(0,0,1,0);
	end, true)

	extension:RegisterFunction("quaternion", "qj", "n", "q", 1, function(n)
		return Quaternion(0,0,n,0);
	end, true)

	extension:RegisterFunction("quaternion", "qk", "", "q", 1, function()
		return Quaternion(0,0,0,1);
	end, true)

	extension:RegisterFunction("quaternion", "qk", "n", "q", 1, function(n)
		return Quaternion(0,0,0,n);
	end, true)

	//

	extension:RegisterFunction("quaternion", "slerp", "q,q,n", "q", 1, function(a,b,c)

		local dot = ((a.r * b.r) + (a.i * b.i) + (a.j * b.j) + (a.k * b.k))
		local len = dot < 0 and Quaternion(-b.r, -b.i, -b.j, -b.k) or b

		local sq = ((a.r * a.r) + (a.i * a.i) + (a.j * a.j) + (a.k * a.k))
		if sq == 0 then return Quaternion(0,0,0,0) end
		
		local inv = Quaternion((a.r / sq), (-a.i / sq), (-a.j / sq), (-a.k / sq))
		local log = qlog(qmul(inv,len))
		local d = Quaternion((log.r * c), (log.i * c), (log.j * c), (log.k *c))
		local e = qexp(d)

		return qmul(a, e);

	end, true)
	
	extension:RegisterFunction("quaternion", "nlerp", "q,q,n", "q", 1, function(a,b,t)

		local d
		local range = 1 - t
		local dot = ((a.r * b.r) + (a.i * b.i) + (a.j * b.j) + (a.k * b.k))

		if dot < 0 then 
			d = Quaternion( (a.r * range - b.r * t), (a.i * range - b.i * t), (a.j * range - b.j * t), (a.k * range - b.k * t) )
		else
			d = Quaternion( (a.r * range + b.r * t), (a.i * range + b.i * t), (a.j * range + b.j * t), (a.k * range + b.k * t) )
		end

		local len = sqrt((d.r * d.r) + (d.i * d.i) + (d.j * d.j) + (d.k * d.k))

		return Quaternion((d.r / len), (d.i / len), (d.j / len), (d.k / len))

	end, true)

	extension:RegisterFunction("quaternion", "qRotation", "v,n", "q", 1, function(a,b)

		local ang = b * deg2rad * 0.5
		local axis = a
		axis:Normalize()

		return Quaternion( (cos(ang)), (axis.x * sin(ang)), (axis.y * sin(ang)), (axis.z * sin(ang)) );

	end, true)

	extension:RegisterFunction("quaternion", "qRotation", "v", "q", 1, function(a)

		local axis = a
		local sq = ((axis.x * axis.x) + (axis.y + axis.y) + (axis.z * axis.z))
		if sq == 0 then return Quaternion(0,0,0,0) end
			
		local len = sqrt(sq)
		local ang = ((len + 180) % 360 - 180) * deg2rad * 0.5
		local sine = sin(ang)/len

		return Quaternion( (cos(ang)), (axis.x * sine), (axis.y * sine), (axis.z * sine) )

	end, true)

	extension:RegisterMethod("q", "toAngle", "", "a", 1, function(q)

		local sq = sqrt( (q.r * q.r), (q.i * q.i), (q.j * q.j), (q.k * q.k) )
		if sq == 0 then return Angle(0,0,0) end
		local qR, qI, qJ, qK = q.r / sq, q.i / sq, q.j / sq, q.k / sq 

		local x = Vector((qR * qR + qI * qI - qJ *qJ - qK * qK), (2 * qJ * qI + 2 * qK *qR), (2 * qK * qI - 2 * qJ *qR))
		local y = Vector((2 * qI * qJ - 2 * qK *qR), (qR * qR - qI * qI + qJ *qJ - qK * qK), (2 * qI * qR + 2 * qJ *qK))

		local ang = x:Angle()
		if ang.p > 180 then ang.p = ang.p - 360 end
		if ang.y > 180 then ang.y = ang.y - 360 end

		local yaw = Vector(0, 1, 0)
		yaw:Rotate(Angle(0, ang.y, 0))

		local roll = acos(clamp(y:Dot(yaw), -1, 1)) * rad2deg
		local dot = qI * qR + qJ * qK
		if dot < 0 then roll = -roll end
		
		return Angle(ang.p, ang.y, roll);

	end, true)

	extension:RegisterFunction("quaternion", "rotationAngle", "q", "a", 1, function(q)

		local sq = (q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k * q.k)
		if sq == 0 then return 0 end
		
		local qe = sqrt(sq)
		local ang = 2 * acos(clamp(q.r / qe, -1, 1)) * rad2deg

		if ang > 180 then ang = ang - 360 end
		
		return ang

	end, true)

	extension:RegisterFunction("quaternion", "rotationAxis", "q", "v", 1, function(q)

		local sq = (q.i * q.i) + (q.j * q.j) + (q.k * q.k)
		if sq == 0 then return Vector(0,0,1) end
		local root = sqrt(sq)

		return Vector( (q.i / root), (q.j / root), (q.k / root))

	end, true)

	extension:RegisterFunction("quaternion", "rotationVector", "q", "v", 1, function(q)

		local sq = (q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k * q.k)
		local max = math.max((q.i * q.i) + (q.j * q.j) + (q.k * q.k))

		if sq == 0 or max == 0 then return Vector(0,0,0) end
		
		local arc = 2 * acos(clamp(q.r / sqrt(sq), -1, 1)) * rad2deg
		if arc > 180 then arc = arc - 360 end
		arc = arc / sqrt(max)

		return Vector((q.i * arc), (q.j * arc), (q.k * arc))

	end, true)

--[[
	End of extention.
]]--

extension:EnableExtension();










	


