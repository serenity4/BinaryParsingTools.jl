using BinaryParsingTools
using Documenter

DocMeta.setdocmeta!(BinaryParsingTools, :DocTestSetup, :(using BinaryParsingTools); recursive=true)

makedocs(;
    modules=[BinaryParsingTools],
    authors="Cédric BELMANT",
    sitename="BinaryParsingTools.jl",
    format=Documenter.HTML(;
        canonical="https://serenity4.github.io/BinaryParsingTools.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/serenity4/BinaryParsingTools.jl",
    devbranch="main",
)
