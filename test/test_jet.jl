# Borrowed from QuantumOpticsBase
using Test
using BlockEnums
using JET

using JET: ReportPass, BasicPass, InferenceErrorReport, UncaughtExceptionReport

# Custom report pass that ignores `UncaughtExceptionReport`
# Too coarse currently, but it serves to ignore the various
# "may throw" messages for runtime errors we raise on purpose
# (mostly on malformed user input)
struct MayThrowIsOk <: ReportPass end

# ignores `UncaughtExceptionReport` analyzed by `JETAnalyzer`
(::MayThrowIsOk)(::Type{UncaughtExceptionReport}, @nospecialize(_...)) = return

# forward to `BasicPass` for everything else
function (::MayThrowIsOk)(report_type::Type{<:InferenceErrorReport}, @nospecialize(args...))
    BasicPass()(report_type, args...)
end

@testset "jet single calls" begin
    @blockenum XX xx1 xx2
    v = [xx1, xx2]
    result = @report_call reinterpret(BlockEnums.basetype(XX), v)
    @show result
    @test length(JET.get_reports(result)) == 0
end

@testset "jet on package" begin
    rep = report_package(
        "BlockEnums";
        report_pass=MayThrowIsOk(), # TODO have something more fine grained than a generic "do not care about thrown errors"
    )
    @show rep
    @test length(JET.get_reports(rep)) == 0
end # testset

