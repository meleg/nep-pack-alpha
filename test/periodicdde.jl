# Run tests on Periodic DDE 

# Intended to be run from nep-pack/ directory or nep-pack/test directory
workspace()
push!(LOAD_PATH, string(@__DIR__, "/../src"))
push!(LOAD_PATH, string(@__DIR__, "/../src/gallery_extra"))

using NEPSolver
using GalleryPeriodicDDE

using Base.Test
@testset "PeriodicDDE" begin
    nep=nep_gallery(PeriodicDDE_NEP,name="mathieu")
    (λ,v)=quasinewton(Complex128,nep,λ=-0.2,v=[1;1])
    # Compare with a reference solution
    @test λ≈(-0.24470143590830754)
end
