--[[
	*****************************************************************************************************************************************************
		Quick math access
	*****************************************************************************************************************************************************
]]--

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

	extension:RegisterClass("q", "quaternion", isQuaternion, EXPR_LIB.NOTNIL);

	extension:RegisterConstructor("q", "n,n,n,n", Quaternion, true);
	extension:RegisterConstructor("q", "n", function(n) return Quaternion(n,0,0,0) end);
	extension:RegisterConstructor("q", "", function() return Quaternion(1,0,0,0) end, true);

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
		
		local sq = sqrt((q.r * q.r) + (q.i * q.i) + (q.j * q.j) + (q.k +q.k))
		if sq == 0 then return Quaternion(-1e+100,0,0,0) end

		local x = { q.r/sq, q.i/sq, q.j/sq, q.k/sq }
		local y = acos(x[1])
		local z = sqrt((x[1] * x[1]) + (x[2] * x[2]) + (x[3] * x[3]) + (x[4] * x[4]))

		return abs(z) > 0 and Quaternion(log(sq), (y * x[2]/z), (y * x[3]/z), (y * x[4]/z)) or Quaternion(log(sq),0,0,0)

	end

	local function qexp(r,i,j,k)

		local sq = sqrt((i * i) + (j * j) + (k * k))
		local sine = sq == !0 and { (i * sin(sq)/sq), (j * sin(sq)/sq), (k * sin(sq)/sq) } or {0,0,0}
		local pow = exp(r)

		return Quaternion((pow * cos(sq)), (pow * sine[1]), (pow * sine[2]), (pow * sine[3]))

	end

	local function angToQuat(a)

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
		Quaternion Operations
	*****************************************************************************************************************************************************
]]--

	extension:RegisterOperator("add", "q,q", "q", 1, function(a,b)
		return Quaternion( (a.r + b.r), (a.i + b.i), (a.j + b.j), (a.k + b.k) )
	end, true)

	extension:RegisterOperator("sub", "q,q", "q", 1, function(a,b)
		return Quaternion( (a.r - b.r), (a.i - b.i), (a.j - b.j), (a.k - b.k) )
	end, true)

	extension:RegisterOperator("mul", "q,q", "q", 1, function(a,b)
		return qmul(a,b);
	end, true)

	extension:RegisterOperator("div", "q,q", "q", 1, function(a,b)
		
		local divisor = ((b.r * b.r) + (b.i * b.i) + (b.j * b.j) + (b.k * b.k))

		return Quaternion( 

			(a.r * b.r) - (a.i * b.i) - (a.j * b.j) - (a.k * b.k) / divisor,
			(a.r * b.i) + (a.i * b.r) + (a.j * b.k) - (a.k * b.j) / divisor, 
			(a.r * b.j) - (a.i * b.k) + (a.j * b.r) + (a.k * b.i) / divisor,
			(a.r * b.k) + (a.i * b.j) - (a.j * b.i) + (a.k * b.r) / divisor

			)
	end, true)

	// 	TODO:
	//	add number,vector to quaternion operations, vice versa

--[[
	*****************************************************************************************************************************************************
		Quaternion Functions
	*****************************************************************************************************************************************************
]]--

	extension:RegisterAttribute("q", "r", "n")
	extension:RegisterAttribute("q", "i", "n")
	extension:RegisterAttribute("q", "j", "n")
	extension:RegisterAttribute("q", "k", "n")

	--[[ Set Quaternion ]]--

	extension:RegisterFunction("quaternion", "quat", "", "q", 1, function()
		return Quaternion(1,0,0,0)
	end, true)

	extension:RegisterFunction("quaternion", "quat", "n", "q", 1, function(n)
		return Quaternion(n,0,0,0)
	end, true)

	extension:RegisterFunction("quaternion", "quat", "n,n,n,n", "q", 1, function(r,i,j,k)
		local r, i, j, k = r, i, j, k
		return Quaternion(r, i, j, k)
	end, true)

	extension:RegisterFunction("quaternion", "quat", "v", "q", 1, function(v) 

		return Quaternion(0, v.x, v.y, v.z);

	end, true)

	extension:RegisterFunction("quaternion", "quat", "a", "q", 1, function(a)

		return angToQuat( Angle(a.p, a.y, a.r) );

	end, true)

	extension:RegisterFunction("quaternion", "quat", "e", "q", 1, function(e)
		
		local ph = e:GetPhysicsObject();
		
		if IsValid(ph) then
			return angToQuat( ph:GetAngles() );
		end
	end, true)

	extension:RegisterFunction("quaternion", "quat", "v,v", "q", 1, function(a,b)

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

	end, true)

	//

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

		return qexp(q.r, q.i, q.j, q.k);

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

	//

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

		local dot = ((a.r * b.r) + (a.i + b.i) + (a.j * b.j) + (a.k + b.k))
		local len = dot < 0 and Quaternion(-b.r, -b.i, -b.j, -b.k) or b

		local sq = ((a.r * a.r) + (a.i * a.i) + (a.j * a.j) + (a.k * a.k))
		if sq == 0 then return Quaternion(0,0,0,0) end
		
		local inv = Quaternion((a.r / sq), (-a.i / sq), (-a.j / sq), (-a.k / sq))
		local log = qlog(qmul(inv,len))
		local d = qexp((log.r * c), (log.i * c), (log.j * c), (log.k *c))

		return qmul(a, d);

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
		local max = ((q.i * q.i) + (q.j * q.j) + (q.k * q.k))

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










	


