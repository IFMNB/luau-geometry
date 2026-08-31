--!strict
--!native
--!optimize 2
const Quat = require("../quat/Quat")



export type Basis = {
    read position: vector,
    read rotation: Quat.Quaternion,
}

