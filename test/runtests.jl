using MEnums
using Test

module Wrap1
using MEnums: @menum

@menum A3 a3 b3 c3

@menum (A4mod, A4) a4 b4

end


@testset "MEnums.jl" begin
    @menum A1 a1 b1 c1
    @test Int.((a1, b1, c1)) == (0, 1, 2)

    @menum (A2mod, A2) a2 b2 c2
    @test Int.((A2mod.a2, A2mod.b2, A2mod.c2)) == (0, 1, 2)
    @test_throws UndefVarError a2 == 0

    @test Int(Wrap1.a3) == 0
    @test_throws UndefVarError a3 == 0

    @test Int(Wrap1.A4mod.b4) == 1
    @test_throws UndefVarError Wrap1.b4 == 0
    @test_throws UndefVarError b4 == 0

    @add A1 z1 y1
    @test Int(z1) == 3

    @add A2 z2 y2
    @test Int(A2mod.z2) == 3

    @add Wrap1.A3 z3
    @test Int(Wrap1.z3) == 3

    @add Wrap1.A4 z4
    @test Int(Wrap1.A4mod.z4) == 2

    @test_throws ArgumentError @add A1 z1

    @menum (A5mod, A5) a5=2 b5=3 c5
    @test Int(A5mod.c5) == 4

    @add A5 d5 e5=11 f5
    @test Int(A5mod.d5) == 5
    @test Int(A5mod.e5) == 11
    @test Int(A5mod.f5) == 12

    @test_throws ArgumentError add!(A5, Symbol("1q"))
end
