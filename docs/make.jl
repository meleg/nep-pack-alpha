push!(LOAD_PATH, string(@__DIR__, "/../src"))
using Documenter, NEPCore, NEPTypes


makedocs(
    clean = true,
    doctest = false,
)


