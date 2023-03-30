using MEnums
using Aqua: Aqua

@testset "aqua unbound_args" begin
    Aqua.test_unbound_args(MEnums)
end

@testset "aqua undefined exports" begin
    Aqua.test_undefined_exports(MEnums)
end

@testset "aqua test ambiguities" begin
    Aqua.test_ambiguities([MEnums, Core, Base])
end

@testset "aqua piracy" begin
    Aqua.test_piracy(MEnums)
end

@testset "aqua project extras" begin
    Aqua.test_project_extras(MEnums)
end

@testset "aqua state deps" begin
    Aqua.test_stale_deps(MEnums)
end

@testset "aqua deps compat" begin
    Aqua.test_deps_compat(MEnums)
end

@testset "aqua project toml formatting" begin
    Aqua.test_project_toml_formatting(MEnums)
end
