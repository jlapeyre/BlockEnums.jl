# MEnums

[![Build Status](https://github.com/jlapeyre/MEnums.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/MEnums.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/MEnums.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/MEnums.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET QA](https://img.shields.io/badge/JET.jl-%E2%9C%88%EF%B8%8F-%23aa4444)](https://github.com/aviatesk/JET.jl)
<!-- [![deps](https://juliahub.com/docs/MEnums/deps.svg)](https://juliahub.com/ui/Packages/MEnums/2Dg1l?t=2) -->
<!-- [![version](https://juliahub.com/docs/MEnums/version.svg)](https://juliahub.com/ui/Packages/MEnums/2Dg1l) -->

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

Some block features

```julia
julia> using MEnums

julia> @menum (Myenum, mod=MyenumMod, blocklength=100, numblocks=10, compactshow=false)

julia> @addinblock Myenum 1 a b c
c::Myenum = 3

julia> @addinblock Myenum 3 x y z
z::Myenum = 203

julia> MEnums.blockindex(MyenumMod.y)
3
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

### Testing

MEnums passes [JET.jl](https://github.com/aviatesk/JET.jl) and [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl) tests.
