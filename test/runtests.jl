using MEnums
using MEnums: blocklength, setblocklength!, numblocks, addblocks!, maxvalind, @addinblock,
    blockindex, blockrange, inblock, ltblock, gtblock, leblock, geblock
using Test

@static if Base.VERSION >= v"1.7"
    if get(ENV,"MENUMS_JET_TEST","")=="true"
        include("test_jet.jl")
    end
end
include("test_aqua.jl")
include("test_menums.jl")
