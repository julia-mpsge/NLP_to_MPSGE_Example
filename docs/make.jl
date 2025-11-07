using NLP_to_MPSGE_Example
using Documenter
using Literate

DocMeta.setdocmeta!(NLP_to_MPSGE_Example, :DocTestSetup, :(using NLP_to_MPSGE_Example); recursive=true)


const _PAGES = [
    "Introduction" => ["index.md"],
    "API Reference" => ["docs.md"],
]


literate_files = Dict(
    "index" => ( 
        input = "../main.jl",
        output = "src/"
    ),
)


for (name, paths) in literate_files
    EXAMPLE = joinpath(@__DIR__, paths.input)
    OUTPUT = joinpath(@__DIR__, paths.output)
    Literate.markdown(EXAMPLE, 
                      OUTPUT;
                      name = name)
end



makedocs(;
    modules=[NLP_to_MPSGE_Example],
    authors="Mitch Phillipson",
    sitename="NLP_to_MPSGE_Example.jl",
    format=Documenter.HTML(;
        canonical="https://github.com/julia-mpsge/NLP_to_MPSGE_Example",
        edit_link="main",
        assets=String[],
    ),
    pages=_PAGES
)

deploydocs(;
    repo = "github.com/julia-mpsge/NLP_to_MPSGE_Example",
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true
)