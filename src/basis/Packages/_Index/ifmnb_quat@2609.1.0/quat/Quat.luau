--!strict
--!native
--!optimize 2

-- Algorithmic credit:
-- https://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/index.htm
--
-- Implementation/build reference:
-- https://github.com/Sleitnick/RbxUtil/blob/main/modules/quaternion/init.luau

--[=[
    Quaternion object based on the implementation of "sleitnick/quaternion" version 0.2.3

    Specially modified to be the fastest. Independent of any other types outside of Luau itself

    The library does not actually create quaternions, it uses the luau buildin type to represent rotation
    It is incomplete and implies that vector has a representation in the form of 3 components inside,
    not 4. 
    
    If available .w as component of vector (LuauVM special flag vector4), this library will be useless and
    even less profitable than implementing a suitable version.
]=]
export type Quaternion = vector

export type Library = {
	read create: (x: number?, y: number?, z: number?, w: number?) -> Quaternion,
	read from_euler: (x: number?, y: number?, z: number?) -> Quaternion,
	read from_axis: (axis: vector?, angle: number?) -> Quaternion,
	read from_looked: (forward: vector?, upwards: vector?) -> Quaternion,

	read dot: (this: Quaternion, at: Quaternion) -> number,
	read slerp: (this: Quaternion, towards: Quaternion, alpha: number) -> Quaternion,
	read angle: (this: Quaternion, towards: Quaternion) -> number,
	read rotate: (this: Quaternion, towards: Quaternion, maxRadiansDelta: number) -> Quaternion,

	read euler: (this: Quaternion, x: number?, y: number?, z: number?) -> vector,
	read axis: (this: Quaternion) -> (vector, number),
	read inverse: (this: Quaternion) -> Quaternion,
	read normalize: (this: Quaternion) -> Quaternion,
	read magnitude: (this: Quaternion, sqr: boolean?) -> number,
	read scalar: (this: Quaternion) -> number,
}

const EPSILON: number = 1e-5
const Y_AXIS: vector = vector.create(0, 1, 0)

const library: Library = table.freeze({
	create = function(x: number?, y: number?, z: number?, w: number?): Quaternion
		x = x or 0
		y = y or 0
		z = z or 0

		if w then
			w = math.clamp(w, -1, 1)
			return vector.normalize(vector.clamp(vector.create(x, y, z), -vector.one, vector.one))
				* math.sqrt(math.max(0, 1 - w * w))
		else
			return vector.clamp(vector.create(x, y, z), -vector.one, vector.one)
		end
	end,

	from_euler = function(x: number?, y: number?, z: number?): Quaternion
		x = x or 0
		y = y or 0
		z = z or 0

		const cx = math.cos(x * 0.5)
		const cy = math.cos(y * 0.5)
		const cz = math.cos(z * 0.5)

		const sx = math.sin(x * 0.5)
		const sy = math.sin(y * 0.5)
		const sz = math.sin(z * 0.5)

		return vector.create(cx * sy * sz + cy * cz * sx, cx * cz * sy - cy * sx * sz, cx * cy * sz - cz * sx * sy)
	end,

	from_axis = function(axis: vector?, angle: number?): Quaternion
		axis = axis and vector.normalize(axis) or vector.one
		angle = angle or 1

		const half = angle / 2
		const sin = math.sin(half)

		return vector.create(sin * axis.x, sin * axis.y, sin * axis.z)
	end,

	from_looked = function(forward: vector?, upwards: vector?): Quaternion
		forward = forward and vector.normalize(forward) or vector.zero

		const up = upwards and vector.normalize(upwards) or Y_AXIS
		const v1 = forward
		const v2 = vector.cross(up, v1)
		const v3 = vector.cross(v1, v2)

		const m00 = v2.x
		const m01 = v2.y
		const m02 = v2.z
		const m10 = v3.x
		const m11 = v3.y
		const m12 = v3.z
		const m20 = v1.x
		const m21 = v1.y
		const m22 = v1.z

		const n8 = m00 + m11 + m22

		if n8 > 0 then
			const n = math.sqrt(n8 + 1)

			return vector.create((m12 - m21) * n, (m20 - m02) * n, (m01 - m10) * n)
		end

		if m00 >= m11 and m00 >= m22 then
			const n7 = math.sqrt(((1 + m00) - m11) - m22)
			const n4 = 0.5 / n7

			return vector.create(0.5 * n7, (m01 + m10) * n4, (m02 + m20) * n4)
		end

		if m11 > m22 then
			const n6 = math.sqrt(((1 + m11) - m00) - m22)
			const n3 = 0.5 / n6

			return vector.create((m10 + m01) * n3, 0.5 * n6, (m21 + m12) * n3)
		end

		const n5 = math.sqrt(((1 + m22) - m00) - m11)
		const n2 = 0.5 / n5

		return vector.create((m20 + m02) * n2, (m21 + m12) * n2, 0.5 * n5)
	end,

	scalar = function(this: Quaternion): number
		return math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
	end,

	dot = function(this: Quaternion, at: Quaternion): number
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const at_w = math.sqrt(math.max(0, 1 - ((at.x * at.x) + (at.y * at.y) + (at.z * at.z))))

		return this.x * at.x + this.y * at.y + this.z * at.z + this_w * at_w
	end,

	slerp = function(this: Quaternion, towards: Quaternion, alpha: number): Quaternion
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const towards_w =
			math.sqrt(math.max(0, 1 - ((towards.x * towards.x) + (towards.y * towards.y) + (towards.z * towards.z))))

		local cosOmega = this.x * towards.x + this.y * towards.y + this.z * towards.z + this_w * towards_w
		local flip = false

		if cosOmega < 0 then
			flip = true
			cosOmega = -cosOmega
		end

		local s1, s2 = 0, 0

		if cosOmega > (1 - EPSILON) then
			s1 = 1 - alpha
			s2 = if flip then -alpha else alpha
		else
			const omega = math.acos(cosOmega)
			const invSinOmega = 1 / math.sin(omega)

			s1 = math.sin((1 - alpha) * omega) * invSinOmega
			s2 = if flip then -math.sin(alpha * omega) * invSinOmega else math.sin(alpha * omega) * invSinOmega
		end

		return vector.create(s1 * this.x + s2 * towards.x, s1 * this.y + s2 * towards.y, s1 * this.z + s2 * towards.z)
	end,

	angle = function(this: Quaternion, towards: Quaternion): number
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const at_w =
			math.sqrt(math.max(0, 1 - ((towards.x * towards.x) + (towards.y * towards.y) + (towards.z * towards.z))))
		const raw_dot = this.x * towards.x + this.y * towards.y + this.z * towards.z + this_w * at_w

		const dot = math.min(math.abs(raw_dot), 1)
		return if dot > (1 - EPSILON) then 0 else math.acos(dot) * 2
	end,

	rotate = function(this: Quaternion, towards: Quaternion, maxRadiansDelta: number): Quaternion
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const towards_w =
			math.sqrt(math.max(0, 1 - ((towards.x * towards.x) + (towards.y * towards.y) + (towards.z * towards.z))))
		const raw_dot = this.x * towards.x + this.y * towards.y + this.z * towards.z + this_w * towards_w

		const dot = math.min(math.abs(raw_dot), 1)
		const angle = if dot > (1 - EPSILON) then 0 else math.acos(dot) * 2

		if angle == 0 then
			return this
		else
			const alpha = math.min(maxRadiansDelta / angle, 1)
			local cosOmega = this.x * towards.x + this.y * towards.y + this.z * towards.z + this_w * towards_w
			local flip = false

			if cosOmega < 0 then
				flip = true
				cosOmega = -cosOmega
			end

			local s1, s2 = 0, 0

			if cosOmega > (1 - EPSILON) then
				s1 = 1 - alpha
				s2 = if flip then -alpha else alpha
			else
				const omega = math.acos(cosOmega)
				const invSinOmega = 1 / math.sin(omega)

				s1 = math.sin((1 - alpha) * omega) * invSinOmega
				s2 = if flip then -math.sin(alpha * omega) * invSinOmega else math.sin(alpha * omega) * invSinOmega
			end

			return vector.create(
				s1 * this.x + s2 * towards.x,
				s1 * this.y + s2 * towards.y,
				s1 * this.z + s2 * towards.z
			)
		end
	end,

	euler = function(this: Quaternion, x: number?, y: number?, z: number?): vector
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const test = this.x * this.y + this.z * this_w

		if test > 0.49999 then
			return vector.create(0, 2 * math.atan2(this.x, this_w), math.pi / 2)
		elseif test < -0.49999 then
			return vector.create(0, -2 * math.atan2(this.x, this_w), -math.pi / 2)
		end

		const sqx = this.x * this.x
		const sqy = this.y * this.y
		const sqz = this.z * this.z

		return vector.create(
			math.atan2(2 * this.x * this_w - 2 * this.y * this.z, 1 - 2 * sqx - 2 * sqz),
			math.atan2(2 * this.y * this_w - 2 * this.x * this.z, 1 - 2 * sqy - 2 * sqz),
			math.asin(2 * test)
		)
	end,

	axis = function(this: Quaternion): (vector, number)
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const scale = math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z)

		if math.abs(scale) < EPSILON or this_w > 1 or this_w < -1 then
			return Y_AXIS, 0
		end

		const inverted_scale = 1 / scale
		const axis = vector.create(this.x * inverted_scale, this.y * inverted_scale, this.z * inverted_scale)
		const angle = 2 * math.acos(this_w)

		return axis, angle
	end,

	inverse = function(this: Quaternion): Quaternion
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const dot = this.x * this.x + this.y * this.y + this.z * this.z + this_w * this_w
		const inverted_normal = 1 / dot

		return -this * inverted_normal
	end,

	normalize = function(this: Quaternion): Quaternion
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const dot = this.x * this.x + this.y * this.y + this.z * this.z + this_w * this_w

		if dot < EPSILON then
			return vector.zero
		else
			return vector.clamp(this / math.sqrt(dot), -vector.one, vector.one)
		end
	end,

	magnitude = function(this: Quaternion, sqr: boolean?): number
		const this_w = math.sqrt(math.max(0, 1 - ((this.x * this.x) + (this.y * this.y) + (this.z * this.z))))
		const dot = this.x * this.x + this.y * this.y + this.z * this.z + this_w * this_w

		return sqr and dot or math.sqrt(dot)
	end,
})

return library
