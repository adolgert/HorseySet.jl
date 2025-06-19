using StableSet
using Documenter

DocMeta.setdocmeta!(StableSet, :DocTestSetup, :(using StableSet); recursive=true)

makedocs(;
    modules=[StableSet],
    authors="Andrew Dolgert <github@dolgert.com>",
    sitename="StableSet.jl",
    format=Documenter.HTML(;
        canonical="https://adolgert.github.io/StableSet.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/adolgert/StableSet.jl",
    devbranch="main",
)
