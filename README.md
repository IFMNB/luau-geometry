# Luau Geometry

A collection of 3D geometry and spatial mathematics libraries for [Luau](https://luau.org/).

The project is designed around small, independent Wally packages that can be used separately or composed together as the geometry layer of a Luau application.

## Packages

| Package                                              | Description                              | Version     |
| ---------------------------------------------------- | ---------------------------------------- | ----------- |
| [`ifmnb/quat`](https://wally.run/package/ifmnb/quat) | Quaternion representation and operations | `2609.01.0` |

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

## License

See LICENSE.md