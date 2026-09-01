--!strict
--!native
--!optimize 2
const Quat = require("./quat")

export type Basis = buffer -- pos + quat
export type Quaternion = Quat.Quaternion

export type i8 = number -- -128_127

export type Library = {
    read create: (position: vector?, rotation: Quaternion?, center: vector?) -> Basis,

    read position: (this: Basis) -> vector,
    read rotation: (this: Basis) -> Quaternion
}

const SIZE = 16 -- local pos xyz + quat xyz + world center (4*3)+(3*1)+1
const SIZE_WORLD_CENTER = 1024 -- units

const library: Library = {
    create = function (position: vector?, rotation: Quaternion?, center: vector?): Basis
        position = position or vector.zero
        rotation = rotation or vector.zero

        const new = buffer.create(SIZE)

        buffer.writef32(new, 0, position.x)
        buffer.writef32(new, 4, position.y)
        buffer.writef32(new, 8, position.z)
        buffer.writei8(new, 12, rotation.x)
        buffer.writei8(new, 13, rotation.y)
        buffer.writei8(new, 14, rotation.z)
        buffer.writei8(new, 15, center)

        return new
    end,

    position = function (this: Basis): vector
        
    end,

    rotation = function (this: Basis): Quaternion
        
    end
}

return library