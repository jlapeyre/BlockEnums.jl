using Documenter, BlockEnums

makedocs(;
         modules=[BlockEnums],
         format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
#         pages=["Home" => "index.md", hide("internals.md")],
         pages=["index.md"],
         repo="https://github.com/jlapeyre/BlockEnums.jl/blob/{commit}{path}#L{line}",
         sitename="BlockEnums.jl",
         authors="John Lapeyre",
)

deploydocs(; repo="github.com/jlapeyre/BlockEnums.jl", push_preview=true)
