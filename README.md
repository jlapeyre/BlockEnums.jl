# MEnums

[![Build Status](https://github.com/jlapeyre/MEnums.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/MEnums.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/MEnums.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/MEnums.jl)


MEnums is like the built-in Enums. The main differences are

* Enumerated types are mutable in the sense that instances may be added after the type is created.
* The enumeration may be partitioned into blocks of values. For example `@addinblock A 2 x` would add
the instance `x` to type `A` in the second block of indices.


```julia
julia> using MEnums

julia> @menum Fruit apple banana

julia> Fruit
MEnum Fruit:
apple = 0
banana = 1

julia> @add Fruit pear
pear::Fruit = 2

julia> Fruit
MEnum Fruit:
apple = 0
pear = 2
banana = 1
```

### Methods for functions in `Base`

Methods for the following functions in `Base` are defined and follow the established semantics.
* `cconvert`
* `write`, converts to the underlying bitstype before writing.
* `read` , reads a value from the bitstype and converts to the `MEnum`
* `isless`
* `Symbol`
* `length`
* `typemin`, `typemax` These are the min and max of values with names bound to them.
* `instances`
* `print`
