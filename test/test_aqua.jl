using BlockEnums
using Aqua: Aqua

@testset "aqua unbound_args" begin
    Aqua.test_unbound_args(BlockEnums)
end

@testset "aqua undefined exports" begin
    Aqua.test_undefined_exports(BlockEnums)
end

@testset "aqua test ambiguities" begin
    Aqua.test_ambiguities([BlockEnums, Core, Base])
end

@testset "aqua piracy" begin
    Aqua.test_piracy(BlockEnums)
end

@testset "aqua project extras" begin
    Aqua.test_project_extras(BlockEnums)
end

@testset "aqua state deps" begin
    Aqua.test_stale_deps(BlockEnums)
end

@testset "aqua deps compat" begin
    Aqua.test_deps_compat(BlockEnums)
end

@testset "aqua project toml formatting" begin
    Aqua.test_project_toml_formatting(BlockEnums)
end
