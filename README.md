# Luau Geometry

A collection of 3D geometry and spatial mathematics libraries for [Luau](https://luau.org/).

The project is designed around small, independent Wally packages that can be used separately or composed together as the geometry layer of a Luau application.

## Packages

| Package                                              | Description                              | Version     |
| ---------------------------------------------------- | ---------------------------------------- | ----------- |
| [`ifmnb/quat`](https://wally.run/package/ifmnb/quat) | Quaternion representation and operations | `2609.01.0` |
| `ifmnb/basis`                                        | Basis / transform representation         | `2609.01.0` |

### Quaternion

`ifmnb/quat` provides quaternion operations implemented directly on Luau's built-in `vector` type.

The implementation does not allocate a dedicated quaternion object. A quaternion is represented as a Luau `vector`, with its scalar component reconstructed when required. This keeps the implementation independent of external types and avoids additional object allocations.

The package currently provides:

* quaternion construction
* Euler-angle conversion
* axis-angle construction
* look-direction construction
* dot product
* spherical linear interpolation (`slerp`)
* angular distance
* bounded rotation
* Euler-angle extraction
* axis-angle extraction
* inverse
* normalization
* magnitude
* scalar component extraction

The module is compiled with Luau's strict typing, native compilation and optimization directives:

```luau
--!strict
--!native
--!optimize 2
```

### Basis

`ifmnb/basis` is intended to provide a basis / spatial transform representation.

The current implementation defines:

```luau
export type Basis = {
    read position: vector,
    read rotation: vector,
}
```

The package depends on `ifmnb/quat@2609.01.0`, allowing the basis implementation to use a specific quaternion version independently of later quaternion releases.

## Installation

The packages are distributed through Wally.

For example, to use the quaternion package:

```toml
[dependencies]
Quat = "ifmnb/quat@2609.01.0"
```

Then require it from Luau:

```luau
local Quat = require(...)
```

For `Basis`:

```toml
[dependencies]
Basis = "ifmnb/basis@2609.01.0"
```

`Basis` brings its declared `Quat` dependency with it.

## Quaternion

A quaternion is exposed through the `Quaternion` type:

```luau
export type Quaternion = vector
```

Basic construction:

```luau
local quaternion = Quat.create()
```

Euler angles:

```luau
local quaternion = Quat.from_euler(x, y, z)
```

Axis-angle:

```luau
local quaternion = Quat.from_axis(axis, angle)
```

Look rotation:

```luau
local quaternion = Quat.from_looked(forward, upwards)
```

Interpolation:

```luau
local result = Quat.slerp(a, b, alpha)
```

Angular distance:

```luau
local angle = Quat.angle(a, b)
```

Bounded rotation:

```luau
local result = Quat.rotate(a, b, maxRadiansDelta)
```

Conversion back to Euler angles:

```luau
local euler = Quat.euler(quaternion)
```

Axis-angle extraction:

```luau
local axis, angle = Quat.axis(quaternion)
```

Normalization and inversion:

```luau
local normalized = Quat.normalize(quaternion)
local inverse = Quat.inverse(quaternion)
```

The complete public API is defined by the module's `Library` type.

## Design

The project favors small, specialized packages instead of a single monolithic geometry module.

For example:

```text
luau-geometry
└── packages
    ├── quat
    └── basis
```

A higher-level package can depend on a specific version of a lower-level package:

```text
Basis
  │
  └── Quat
```

This allows individual components to be versioned and distributed independently through Wally.

## Implementation

The quaternion implementation is based on the algorithmic material from EuclideanSpace and uses `sleitnick/quaternion` 0.2.3 as an implementation/build reference. The implementation has been substantially modified around Luau's native `vector` representation and optimization facilities.

The current quaternion representation assumes a three-component Luau vector. The scalar `w` component is reconstructed mathematically rather than stored as a fourth vector component. The implementation itself notes that a future Luau vector type with a native `.w` component would make this representation unnecessary.

## Status

The project is currently under active development.

`Quat` contains the first functional geometry component, while `Basis` currently defines its core data representation and package dependency structure. Additional 3D geometry types and operations may be added as the library evolves.

## License

GPL-3.0.

Copyright © Aftersky.
