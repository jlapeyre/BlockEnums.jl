module MEnums

import Core.Intrinsics.bitcast

export MEnum, @menum, add!, @add, blocklength, setblocklength!, getmodule, namemap,
    numblocks, addblocks!, add_in_block!, maxvalind, @addinblock,
    blockindex, basetype

"""
    namemap(::Type{<:MEnum})

Return the `Dict` mapping all values to name symbols.
Perhaps this should not be advertized or exposed.
"""
function namemap end

namemap(arg::Any) = throw(MethodError(namemap, (arg,)))

"""
    getmodule(t::Type{<:MEnum})

Get the module in which `t` is defined.
"""
function getmodule end

"""
    blocklength(t::Type{<:MEnum})

Get the length of blocks that the range of values of
`t` is partitioned into.
"""
function blocklength end

"""
    blockindex(v::MEnum)

Get the index of the block of values `v` belongs to.
"""
function blockindex end

"""
    setblocklength!(t::Type{<:MEnum}, block_length)

Set the length of each block in the partition of the values of `t`. This
can only be called once.  In order to use the blocks you must first set up
bookkeeping by calling `addblocks!`.  These blocks are called "active".
"""
function setblocklength! end

"""
    numblocks(t::Type{<:MEnum{T}}) where T <: Integer

Return the number of blocks for which bookkeeping has been set up. The
set of values of `t` is the nonzero values of `T`, which is typically very large. Bookkeeping of
blocks requires storage. So you can only set up some of the blocks for use.
"""
function numblocks end

"""
    addblocks!(t::Type{<:MEnum}), nblocks::Integer)

Add and initialize `nblocks` blocks to the bookkeeping
for `t`. The number of active blocks for the type
is returned.
"""
function addblocks! end

"""
    compact_show(t::Type{<:MEnum})

Return `true` if compact show was set when `t` was defined. This omits printing
the corresponding integer when printing. To enable compact show, include the
key/val pair `compactshow=true` when defining `t`.
"""
function compact_show end

"""
    maxvalind(t::Type{<:MEnum}, block_num::Integer)

Return the largest index for which a name has been assigned in the
`block_num`th block `t`. This number is constrained to be within
the values in the block.
"""
function maxvalind end

function _incrmaxvalind! end

function blocklength1 end

"""
    MEnum{T<:Integer}

The abstract supertype of all enumerated types defined with [`@menum`](@ref).
"""
abstract type MEnum{T<:Integer} end

"""
    basetype(V::Type{<:MEnum{T}})

Return `T`, which is the bitstype whose values are bitcast to
the type `V`.
This is the type of the value returned by `Integer(x::V)`.
The type is in a sense the underlying type of `V`.
"""
basetype(::Type{<:MEnum{T}}) where {T<:Integer} = T

"""
    val(x::MEnum{T})

Return `x` bitcast to type `T`.
"""
val(x::MEnum{T}) where T = bitcast(T, x)

(::Type{T})(x::MEnum{T2}) where {T<:Integer,T2<:Integer} = T(bitcast(T2, x))::T
Base.cconvert(::Type{T}, x::MEnum{T2}) where {T<:Integer,T2<:Integer} = T(x)
Base.write(io::IO, x::MEnum{T}) where {T<:Integer} = write(io, T(x))
Base.read(io::IO, ::Type{T}) where {T<:MEnum} = T(read(io, basetype(T)))

Base.isless(x::T, y::T) where {T<:MEnum} = isless(basetype(T)(x), basetype(T)(y))

Base.Symbol(x::MEnum)::Symbol = _symbol(x)

Base.length(t::Type{<:MEnum}) = length(namemap(t))
Base.typemin(t::Type{<:MEnum}) = minimum(keys(namemap(t)))
Base.typemax(t::Type{<:MEnum}) = maximum(keys(namemap(t)))

"""
    instances(t::Type{<:MEnum})

Return a `Tuple` of all of the named values of `t`.
"""
Base.instances(t::Type{<:MEnum}) = (sort!(Any[t(v) for v in keys(namemap(t))])...,)

function _symbol(x::MEnum)
    names = namemap(typeof(x))
    x = Integer(x)
    get(() -> Symbol("<invalid #$x>"), names, x)::Symbol
end

Base.print(io::IO, x::MEnum) = print(io, _symbol(x))

function Base.show(io::IO, x::MEnum)
    sym = _symbol(x)
    if !(get(io, :compact, false)::Bool)
        from = get(io, :module, Main)
        def = typeof(x).name.module
        if from === nothing || !Base.isvisible(sym, def, from)
            show(io, def)
            print(io, ".")
        end
    end
    print(io, sym)
end

function Base.show(io::IO, ::MIME"text/plain", x::MEnum)
    print(io, x, "::")
    show(IOContext(io, :compact => true), typeof(x))
    compact_show(typeof(x)) && return
    print(io, " = ")
    show(io, Integer(x))
end

function Base.show(io::IO, m::MIME"text/plain", t::Type{<:MEnum})
    if isconcretetype(t)
        print(io, "MEnum ")
        Base.show_datatype(io, t)
        print(io, ":")
        for x in instances(t)
            print(io, "\n", Symbol(x), " = ")
            show(io, Integer(x))
        end
    else
        invoke(show, Tuple{IO, MIME"text/plain", Type}, io, m, t)
    end
end

# give MEnum types scalar behavior in broadcasting
Base.broadcastable(x::MEnum) = Ref(x)

@noinline enum_argument_error(typename, x) = throw(ArgumentError(string("invalid value for MEnum $(typename): $x")))

# Following values of `s` and what is returned
# `syname` returns (:syname, nothing)
# `syname = 3` returns `(:syname, 3)`
# `s` a LineNumberNode returns `(nothing, nothing)`
function _sym_and_number(typename, _module, basetype, s)
    s isa LineNumberNode && return (nothing, nothing)
    if isa(s, Symbol)
        i = nothing
    elseif isa(s, Expr) &&  # For example `a = 1`
        (s.head === :(=) || s.head === :kw) && # IIRC may be :(=) or :kw depending on Julia version
        length(s.args) == 2 && isa(s.args[1], Symbol)
        i = Core.eval(_module, s.args[2]) # allow exprs, e.g. uint128"1"
        if !isa(i, Integer)
            throw(ArgumentError("invalid value for MEnum $typename, $s; values must be integers"))
        end
        i = convert(basetype, i)
        s = s.args[1] # Set `s` to just the symbol
    else
        throw(ArgumentError(string("invalid argument for MEnum ", typename, ": ", s)))
    end
    if !Base.isidentifier(s)
        throw(ArgumentError("invalid name for MEnum $typename; \"$s\" is not a valid identifier"))
    end
    return (s, i)
end

function _check_begin_block(syms)
    if length(syms) == 1 && syms[1] isa Expr && syms[1].head === :block
        syms = syms[1].args
    end
    return syms
end

function _parse_block_length(blen)
    isa(blen, Integer) && return blen
    isa(blen, Expr) || throw(ArgumentError("blocklength must be an Integer or an expression."))
    args = blen.args
    if blen.head === :call && length(args) == 3 && args[1] === :(^) &&
        isa(args[2], Int) && isa(args[3], Int)
        return args[2] ^ args[3]
    else
        throw(ArgumentError("Invalid expression for blocklength $(blen)"))
    end
end

"""
    @menum MEnumName[::BaseType] value1[=x] value2[=y]

Create an `MEnum{BaseType}` subtype with name `MEnumName` and enum member values of
`value1` and `value2` with optional assigned values of `x` and `y`, respectively.
`MEnumName` can be used just like other types and enum member values as regular values, such as

# Examples
```jldoctest fruitenum
julia> @menum Fruit apple=1 orange=2 kiwi=3

julia> f(x::Fruit) = "I'm a Fruit with value: \$(Int(x))"
f (generic function with 1 method)

julia> f(apple)
"I'm a Fruit with value: 1"

julia> Fruit(1)
apple::Fruit = 1
```

Values can also be specified inside a `begin` block, e.g.

```julia
@menum MEnumName begin
    value1
    value2
end
```

`BaseType`, which defaults to [`Int32`](@ref), must be a primitive subtype of `Integer`.
Member values can be converted between the enum type and `BaseType`. `read` and `write`
perform these conversions automatically. In case the enum is created with a non-default
`BaseType`, `Integer(value1)` will return the integer `value1` with the type `BaseType`.

To list all the instances of an enum use `instances`, e.g.

```jldoctest fruitenum
julia> instances(Fruit)
(apple, orange, kiwi)
```

It is possible to construct a symbol from an enum instance:

```jldoctest fruitenum
julia> Symbol(apple)
:apple
```
"""
macro menum(T0::Union{Symbol,Expr}, syms...)
    local modname = :nothing # Default, do not create a new module. Use module that is in scope.
    local typename
    local _blocklength::Int = 0
    local init_num_blocks::Int = 0
    _compact_show=false
    if isa(T0, Expr) && T0.head === :tuple # (modulename, menumname)
        length(T0.args) >= 1 || throw(ArgumentError("If first argument is a Tuple, it must have at least one element"))
        T = T0.args[1] # `T` is the name of the new subtype of MEnum
        for i in 2:lastindex(T0.args)
            expr = T0.args[i]
            (isa(expr, Expr) && expr.head === :(=)) || throw(ArgumentError(string("Expecting `=` expression as $(i)th item in init tuple.")))
            (keyw, val) = (expr.args[1], expr.args[2])
            if keyw === :blocklength
                _blocklength = _parse_block_length(val)
            elseif keyw === :mod # Symbols in this module. TODO, how to allow :module here? It is recognized as Julia reserved word
                modname = val
            elseif keyw === :numblocks
                init_num_blocks = val
            elseif keyw === :compactshow
                _compact_show = val
            else
                throw(ArgumentError(string("Unexpected keyword $(expr.args[1])")))
            end
        end
    else
        T = T0
    end
    if init_num_blocks > 0 && ! (_blocklength > 0)
        throw(ArgumentError(string("If numblocks is set then blocklength must be set.")))
    end
    basetype = Int32 # default. We may change this below.
    typename = T
    if isa(T, Expr) && T.head === :(::) && length(T.args) == 2 && isa(T.args[1], Symbol)
        typename = T.args[1]
        basetype = Core.eval(__module__, T.args[2])
        if !isa(basetype, DataType) || !(basetype <: Integer) || !isbitstype(basetype)
            throw(ArgumentError("invalid base type for MEnum $typename, $T=::$basetype; base type must be an integer primitive type"))
        end
    elseif !isa(T, Symbol)
        throw(ArgumentError("invalid type expression for enum $T"))
    end
    # The new subtype of MEnum is now `typename`. No longer use `T`.
    T = nothing # Do this to signal intent and uncover bugs
    values = Vector{basetype}()
    seen = Set{Symbol}()
    namemap = Dict{basetype,Symbol}()
    block_max_ind = Vector{Int}(undef, init_num_blocks)
    for i in 1:init_num_blocks
        block_max_ind[i] =  (i - 1) * _blocklength
    end
    lo = hi = 0
    i = zero(basetype)
    hasexpr = false

    # Symbols (and their values if present) may be wrapped in `begin`, `end`
    syms = _check_begin_block(syms)
    for s in syms
        (s, _i) = _sym_and_number(typename, __module__, basetype, s)
        s === nothing && continue # Got a LineNumberNode
        if _i === nothing && i == typemin(basetype) && !isempty(values)
            throw(ArgumentError("overflow in value \"$s\" of MEnum $typename"))
        end
        if _i !== nothing
            hasexpr = true
            i = _i
        end
        s = s::Symbol
        if hasexpr && haskey(namemap, i)
            throw(ArgumentError("both $s and $(namemap[i]) have value $i in MEnum $typename; values must be unique"))
        end
        namemap[i] = s
        push!(values, i)
        if s in seen
            throw(ArgumentError("name \"$s\" in MEnum $typename is not unique"))
        end
        push!(seen, s)
        if length(values) == 1
            lo = hi = i
        else
            lo = min(lo, i)
            hi = max(hi, i)
        end
        i += oneunit(i)
    end
    blk = quote
        # enum definition
        Base.@__doc__(primitive type $(esc(typename)) <: MEnum{$(basetype)} $(sizeof(basetype) * 8) end)
        function $(esc(typename))(x::Integer)
            if x > typemax($basetype) || x < typemin($basetype)
                enum_argument_error($(Expr(:quote, typename)), x)
            end
            return bitcast($(esc(typename)), convert($(basetype), x))
        end
        MEnums.namemap(::Type{$(esc(typename))}) = $(esc(namemap))
        MEnums.blocklength(::Type{$(esc(typename))}) = $(esc(_blocklength))
        MEnums.numblocks(::Type{$(esc(typename))}) = length($(esc(block_max_ind)))
        function MEnums.addblocks!(::Type{$(esc(typename))}, n::Integer)
            blklen = $(esc(_blocklength))
            if iszero(blklen)
                throw(ArgumentError("This MEnum was not initialized with blocks."))
            end
            bmaxind = $(esc(block_max_ind))
            curlen = length(bmaxind)
            resize!(bmaxind, curlen + n)
            for i in (curlen + 1):(curlen + n)
                bmaxind[i] = (i - 1) * blklen
            end
            return length(bmaxind)
        end
        function MEnums.maxvalind(::Type{$(esc(typename))}, block::Integer)
            return $(esc(block_max_ind))[block]
        end
        function MEnums._incrmaxvalind!(::Type{$(esc(typename))}, block::Integer)
            mbi = $(esc(block_max_ind))
            mbi[block] += 1
            return return mbi[block]
        end
        function MEnums.blockindex(x::$(esc(typename)))
            $(esc(_blocklength)) > 0 || return 0
            blknum = div(Int(x), $(esc(_blocklength)), RoundUp)
            return blknum
        end
        function MEnums.compact_show(::Type{$(esc(typename))})
            return $(esc(_compact_show))
        end
    end
    if isa(typename, Symbol)
        if modname !== :nothing
            push!(blk.args, :(module $(esc(modname)); end))
        else
            modname = __module__
        end
        push!(blk.args,
              :(MEnums.getmodule(::Type{$(esc(typename))}) = $(esc(modname))))
        push!(blk.args, :(MEnums._bind_vars($(esc(typename)))))
    end
    push!(blk.args, :nothing)
    blk.head = :toplevel
    return blk
end

function _bind_vars(etype)
    for (i, sym) in namemap(etype)
        _bind_var(getmodule(etype), sym, etype(i))
    end
end

_bind_var(mod, sym, instance) = mod.eval(:(const $sym = $instance; export $sym))

function add!(a, syms...)
    nmap = MEnums.namemap(a)
    nextnum = length(a) == 0 ? 0 : maximum(keys(nmap)) + 1
    local na
    _module = getmodule(a)
    count_assigned = 0
    for sym in syms
        (sym, _i) = _sym_and_number(Symbol(a), _module, basetype(a), sym)
        sym in values(nmap) && throw(ArgumentError("Key $sym already defined in $a."))
        if _i !== nothing
            nextnum = _i
        end
        na = a(nextnum)
        nmap[nextnum] = sym
        _bind_var(_module, sym, na)
        nextnum += 1
        count_assigned += 1
    end
    if iszero(count_assigned)
        throw(ArgumentError("No symbols defined in enum!"))
    end
    return na
end

function _get_qsyms(syms)
    syms = _check_begin_block(syms)
    return (QuoteNode(sym) for sym in syms if ! isa(sym, LineNumberNode))
end

macro add(a, syms...)
    qsyms = _get_qsyms(syms)
    :(MEnums.add!($(esc(a)), $(qsyms...)))
end

function add_in_block!(a, _block::Union{Integer, MEnum}, syms...)
    block = Int(_block)
    nmap = MEnums.namemap(a)
    nextnum = maxvalind(a, block) + 1
    local na
    _module = getmodule(a)
    for sym in syms
        blocklim = blocklength(a) * block
        if nextnum > blocklim
            throw(ArgumentError("Attempting to set enum value above block limit $blocklim"))
        end
        (sym, _i) = _sym_and_number(Symbol(a), _module, basetype(a), sym)
        sym in values(nmap) && throw(ArgumentError("Key $sym already defined in $a."))
        if _i !== nothing
            throw(ArgumentError("Setting number explicitly not allowed in block mode."))
        end
        na = a(nextnum)
        nmap[nextnum] = sym
        _bind_var(_module, sym, na)
        nextnum += 1
        _incrmaxvalind!(a, block)
    end
    return na
end

macro addinblock(a, block, syms...)
    qsyms = _get_qsyms(syms)
    :(MEnums.add_in_block!($(esc(a)), $(esc(block)), $(qsyms...)))
end

# Since we don't guarantee continguous values of instances, this does not work
# It is taken from the code for Enum
# generate code to test whether expr is in the given set of values
# function membershiptest(expr, values)
#     lo, hi = extrema(values)
#     if length(values) == hi - lo + 1
#         :($lo <= $expr <= $hi)
#     elseif length(values) < 20
#         foldl((x1,x2)->:($x1 || ($expr == $x2)), values[2:end]; init=:($expr == $(values[1])))
#     else
#         :($expr in $(Set(values)))
#     end
# end

end # module MEnums
