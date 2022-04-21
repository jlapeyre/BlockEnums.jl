module MEnums

import Core.Intrinsics.bitcast

export MEnum, @menum, add!, @add

function namemap end
function getmodule end

"""
    MEnum{T<:Integer}

The abstract supertype of all enumerated types defined with [`@menum`](@ref).
"""
abstract type MEnum{T<:Integer} end

basetype(::Type{<:MEnum{T}}) where {T<:Integer} = T

(::Type{T})(x::MEnum{T2}) where {T<:Integer,T2<:Integer} = T(bitcast(T2, x))::T
Base.cconvert(::Type{T}, x::MEnum{T2}) where {T<:Integer,T2<:Integer} = T(x)
Base.write(io::IO, x::MEnum{T}) where {T<:Integer} = write(io, T(x))
Base.read(io::IO, ::Type{T}) where {T<:MEnum} = T(read(io, basetype(T)))

Base.isless(x::T, y::T) where {T<:MEnum} = isless(basetype(T)(x), basetype(T)(y))

Base.Symbol(x::MEnum)::Symbol = _symbol(x)

Base.length(t::Type{<:MEnum}) = length(namemap(t))
Base.typemin(t::Type{<:MEnum}) = minimum(keys(namemap(t)))
Base.typemax(t::Type{<:MEnum}) = maximum(keys(namemap(t)))
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

# generate code to test whether expr is in the given set of values
function membershiptest(expr, values)
    lo, hi = extrema(values)
    if length(values) == hi - lo + 1
        :($lo <= $expr <= $hi)
    elseif length(values) < 20
        foldl((x1,x2)->:($x1 || ($expr == $x2)), values[2:end]; init=:($expr == $(values[1])))
    else
        :($expr in $(Set(values)))
    end
end

# give MEnum types scalar behavior in broadcasting
Base.broadcastable(x::MEnum) = Ref(x)

@noinline enum_argument_error(typename, x) = throw(ArgumentError(string("invalid value for MEnum $(typename): $x")))


function _sym_and_number(typename, _module, basetype, s)
    s isa LineNumberNode && return (nothing, nothing)
    if isa(s, Symbol)
        i = nothing
    elseif isa(s, Expr) &&
        (s.head === :(=) || s.head === :kw) &&
        length(s.args) == 2 && isa(s.args[1], Symbol)
        i = Core.eval(_module, s.args[2]) # allow exprs, e.g. uint128"1"
        if !isa(i, Integer)
            throw(ArgumentError("invalid value for MEnum $typename, $s; values must be integers"))
        end
        i = convert(basetype, i)
        s = s.args[1]
    else
        throw(ArgumentError(string("invalid argument for MEnum ", typename, ": ", s)))
    end
    if !Base.isidentifier(s)
        throw(ArgumentError("invalid name for MEnum $typename; \"$s\" is not a valid identifier"))
    end
    return (s, i)
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
macro menum(T::Union{Symbol,Expr}, syms...)
    local modname
    if isa(T, Expr) && T.head === :tuple # (modulename, menumname)
        length(T.args) == 2 || throw(ArgumentError("If first argument is a Tuple, it must have two elements"))
        modname = T.args[1]
        T = T.args[2]
    else
        modname = :nothing
    end
    basetype = Int32 # default
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
    values = Vector{basetype}()
    seen = Set{Symbol}()
    namemap = Dict{basetype,Symbol}()
    lo = hi = 0
    i = zero(basetype)
    hasexpr = false

    if length(syms) == 1 && syms[1] isa Expr && syms[1].head === :block
        syms = syms[1].args
    end
    for s in syms
        (s, _i) = _sym_and_number(typename, __module__, basetype, s)
        s === nothing && continue
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
    end
    return na
end

macro add(a, syms...)
    qsyms = (QuoteNode(sym) for sym in syms)
    :(MEnums.add!($(esc(a)), $(qsyms...)))
end

end # module MEnums
