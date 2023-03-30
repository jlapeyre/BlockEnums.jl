using MEnums
using MEnums: blocklength, setblocklength!, numblocks, addblocks!, maxvalind, @addinblock,
    blockindex
using Test

module Wrap1
using MEnums: @menum

@menum A3 a3 b3 c3

@menum (A4, mod=A4mod) a4 b4

end

@static if Base.VERSION >= v"1.7"
    include("test_jet.jl")
end
include("test_aqua.jl")

@testset "blocks" begin
    @menum (Z, blocklength=3)
    @test numblocks(Z) == 0
    @test blocklength(Z) == 3
    addblocks!(Z, 10)
    @test numblocks(Z) == 10
    addblocks!(Z, 10)
    @test numblocks(Z) == 20
    @test maxvalind(Z, 1) == 0
    @test maxvalind(Z, 2) == 3
    @addinblock Z 1 a b c
    @test_throws ArgumentError @addinblock Z 1 d
    @addinblock Z 2 x y z
    @test maxvalind(Z, 1) == 3
    @test maxvalind(Z, 2) == 6
    @test blockindex(a) == 1
    @test blockindex(x) == 2

    @menum ZZ
    @test_throws ArgumentError addblocks!(ZZ, 5)
    @menum (YY, blocklength=10^6)
    @test blocklength(YY) == 1000000
end

@testset "MEnums.jl" begin
    @menum A1 a1 b1 c1
    @test Int.((a1, b1, c1)) == (0, 1, 2)
    @test MEnums.val.((a1, b1, c1)) == (0, 1, 2)
    @test A1(1) == b1
    @test length(A1) == 3
    @test Base.cconvert(Int, a1) === Int(a1)
    @test instances(A1) == (a1, b1, c1)
    @test MEnums.getmodule(A1) == Main
    # Base.Enum will throw an error with the following
    @test Integer(A1(111)) == 111
    @test isless(a1, b1)
    @test a1 < b1
    @test basetype(A1) == Int32
    @menum A1_64::Int64
    @test basetype(A1_64) == Int64

    @menum (A2, mod=A2mod) a2 b2 c2
    @test Int.((A2mod.a2, A2mod.b2, A2mod.c2)) == (0, 1, 2)
    @test_throws UndefVarError a2 == 0
    @test MEnums.getmodule(A2) == A2mod

    @test Int(Wrap1.a3) == 0
    @test_throws UndefVarError a3 == 0

    @test Int(Wrap1.A4mod.b4) == 1
    @test_throws UndefVarError Wrap1.b4 == 0
    @test_throws UndefVarError b4 == 0
    @test MEnums.getmodule(Wrap1.A4) == Wrap1.A4mod

    @add A1 z1 y1
    @test Int(z1) == 3

    @add A2 z2 y2
    @test Int(A2mod.z2) == 3

    @add Wrap1.A3 z3
    @test Int(Wrap1.z3) == 3
    @test Wrap1.A3(3) == Wrap1.z3

    @add Wrap1.A4 z4
    @test Int(Wrap1.A4mod.z4) == 2
    @test Wrap1.A4(2) == Wrap1.A4mod.z4 # This *is* how we want scoping to work.
    @test instances(Wrap1.A4) == (Wrap1.A4mod.a4, Wrap1.A4mod.b4, Wrap1.A4mod.z4)

    @test_throws ArgumentError @add A1 z1

    @menum (A5, mod=A5mod) a5=2 b5=3 c5
    @test Int(A5mod.c5) == 4

    @add A5 d5 e5=11 f5
    @test Int(A5mod.d5) == 5
    @test Int(A5mod.e5) == 11
    @test Int(A5mod.f5) == 12

    @test_throws ArgumentError add!(A5, Symbol("1q"))

    @menum A6 begin
        a6
        b6
        c6
    end
    @test Int(c6) == 2

    @menum A7 begin
        a7 = 10
        b7
        c7
    end
    @test Int(c7) == 12
end
