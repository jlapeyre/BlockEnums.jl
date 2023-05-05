# BlockEnums

[![Build Status](https://github.com/jlapeyre/BlockEnums.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/BlockEnums.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jlapeyre.github.io/BlockEnums.jl/dev/)
[![Coverage](https://codecov.io/gh/jlapeyre/BlockEnums.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/BlockEnums.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET QA](https://img.shields.io/badge/JET.jl-%E2%9C%88%EF%B8%8F-%23aa4444)](https://github.com/aviatesk/JET.jl)
<!-- [![deps](https://juliahub.com/docs/BlockEnums/deps.svg)](https://juliahub.com/ui/Packages/BlockEnums/2Dg1l?t=2) -->
<!-- [![version](https://juliahub.com/docs/BlockEnums/version.svg)](https://juliahub.com/ui/Packages/BlockEnums/2Dg1l) -->

BlockEnums is like the built-in Enums. The main differences are

* Enumerated types are mutable in the sense that instances may be added after the type is created.
* The type may be optionally enclosed in a module (a namespace).
* The enumeration may be partitioned into blocks of values. For example `@addinblock A 2 x` would add
the instance `x` to type `A` in the second block of indices.

These are supported by keyword arguments `blocklength`, `mod`, `numblocks`.
There is also a keyword `compactshow` that causes the integer associated with the enum value to be
omitted when displaying.

```julia
julia> using BlockEnums

julia> @blockenum Fruit apple banana

julia> Fruit
BlockEnum Fruit:
apple = 0
banana = 1

julia> @add Fruit pear
pear::Fruit = 2

julia> Fruit
BlockEnum Fruit:
apple = 0
pear = 2
banana = 1
```

Some block features

```julia
julia> using BlockEnums

julia> @blockenum (Myenum, mod=MyenumMod, blocklength=100, numblocks=10, compactshow=false)

julia> @addinblock Myenum 1 a b c
c::Myenum = 3

julia> @addinblock Myenum 3 x y z
z::Myenum = 203

julia> BlockEnums.blockindex(MyenumMod.y)
3
```

### Methods for functions in `Base`

Methods for the following functions in `Base` are defined and follow the established semantics.
* `cconvert`
* `write`, converts to the underlying bitstype before writing.
* `read` , reads a value from the bitstype and converts to the `BlockEnum`
* `isless`
* `Symbol`
* `length`
* `typemin`, `typemax` These are the min and max of values with names bound to them.
* `instances`
* `print`

### Testing

BlockEnums passes [JET.jl](https://github.com/aviatesk/JET.jl) and [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl) tests.

### Related packages

See [EnumsX](https://github.com/fredrikekre/EnumX.jl) and other packages listed at the bottom of that page.
