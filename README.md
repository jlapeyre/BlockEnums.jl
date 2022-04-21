# MEnums

[![Build Status](https://github.com/jlapeyre/MEnums.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/MEnums.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/MEnums.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/MEnums.jl)


MEnums is like the built-in Enums. The main difference is that enumerated types are mutable
in the sense that members may be added after the type is created.

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
