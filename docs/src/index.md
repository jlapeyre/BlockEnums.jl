# BlockEnums.jl

```@contents
```

## BlockEnums

```@docs
BlockEnums
BlockEnum
```

Create a new `BlockEnum` with the macro `@blockenum`.
```@docs
@blockenum
```

These functions retrieve information on `BlockEnum`s.
```@docs
namemap
basetype
BlockEnums.val
getmodule
BlockEnums.compact_show
instances(::Type{<:BlockEnum})
length(::Type{<:BlockEnum})
```

A few functions and macros pertain to the blocks feature.
```@docs
addblocks!
maxvalind
numblocks
blocklength
blockindex
blockrange
add!
@add
add_in_block!
@addinblock
inblock
gtblock
ltblock
```

## Index

```@index
```
