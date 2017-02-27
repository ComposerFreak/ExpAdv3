/*---------------------------------------------------------------------------
Vector2 class
Author: Oskar
Credits: RevouluPowered
---------------------------------------------------------------------------*/

local setmetatable = setmetatable 

local meta = { } 
meta.__index = meta 
meta.__type = "vector2"

function meta:__add( other ) // var+var
	if isnumber( other ) then 
		return Vector2( self.x + other, self.y + other ) 
	elseif istable( other ) and other.__type == "vector2" then 
		return Vector2( self.x + other.x, self.y + other.y ) 
	end 
end 

function meta:__sub( other ) // -var
	if isnumber( other ) then 
		return Vector2( self.x - other, self.y - other ) 
	elseif istable( other ) and other.__type == "vector2" then 
		return Vector2( self.x - other.x, self.y - other.y ) 
	end 
end 

function meta:__mul( other ) // var*var
	if isnumber( other ) then 
		return Vector2( self.x * other, self.y * other ) 
	elseif istable( other ) and other.__type == "vector2" then 
		return Vector2( self.x * other.x, self.y * other.y ) 
	end 
end 

function meta:__div( other ) // var/var
	if isnumber( other ) then 
		return Vector2( self.x / other, self.y / other ) 
	elseif istable( other ) and other.__type == "vector2" then 
		return Vector2( self.x / other.x, self.y / other.y ) 
	end 
end 

function meta:__mod( other ) // var%var
	return Vector2( self.x % other.x, self.y % other.y ) 
end 

function meta:__pow( other ) // var^var
	return Vector2( self.x ^ other.x, self.y ^ other.y ) 
end

function meta:__unm( ) // -var
	return Vector2( self.x * -1, self.y * -1 ) 
end 

// #var
function meta:__len( ) -- Garry has broken this =(
	return math.sqrt( self.x * self.x + self.y * self.y ) 
end 

function meta:__eq( other ) // var==var
	return self.x == other.x and self.y == other.y 
end 

function meta:__lt( other ) // var<var
	return self.x < other.x and self.y < other.y 
end 

function meta:__le( other ) // var<=var
	return self.x <= other.x and self.y <= other.y 
end 

function meta:__call( x, y ) // var()
	return self.x + (x or 0), self.y + (y or 0) 
end 

function meta:__tostring( ) 
	return "Vector2: " .. math.Round(self.x, 10) .. "\t" .. math.Round(self.y, 10) 
end 

function meta:Dot( other ) 
	return self.x * other.x + self.y * other.y 
end 

function meta:Normalize( ) 
	local Len = self:Length( ) or 1
	return Vector2( self.x / Len, self.y / Len ) 
end 

function meta:Round( dec ) 
	return Vector2( math.Round( self.x, dec or 0 ), math.Round( self.y, dec or 0 ) ) 
end 

function meta:Length( ) 
	return math.sqrt( self.x * self.x + self.y * self.y ) 
end 

function meta:Cross( other )
	return setmetatable( {
		x = ( self.y * other.z ) - ( other.y * self.z ),
		y = ( self.z * other.x ) - ( other.z * self.x )
	}, meta )
end -- RevouluPowered

function meta:Distance( other )
	return ( self - other ):Length()
end -- RevouluPowered

function meta:Set( x, y ) 
	self.x = x 
	self.y = y 
	return self 
end 

function meta:Add( x, y ) 
	self.x = self.x + x 
	self.y = self.y + y 
	return self 
end 

function meta:Sub( x, y )
	self.x = self.x - x 
	self.y = self.y - y 
	return self 
end 

function meta:Clone( )
	return Vector2( self.x, self.y )
end

local Vec2 = { Zero = setmetatable({ x = 0, y = 0 }, meta) } 
Vec2.__index = Vec2 

function Vec2:__call( a, b ) 
	return setmetatable({x = a or 0, y = b or 0}, meta) 
end 

Vector2 = setmetatable( { }, Vec2 ) 
