# Test for infinite Bi-Lanczos

workspace()
push!(LOAD_PATH, string(@__DIR__, "/../src"))
using NEPSolver
using NEPCore
using NEPTypes
using Gallery
using MAT
using Base.Test
using LinSolvers


nep=nep_gallery("qdep0");
nept=SPMF_NEP([nep.A[1]',nep.A[2]',nep.A[3]'],nep.fi)
n=size(nep,1);

@testset "Infbilanczos σ=0" begin
    m=40;
    λ,V,T = infbilanczos(Float64,nep,nept,maxit=m,Neig=7,σ=0,displaylevel=1,
                         v=ones(Float64,n),u=ones(Float64,n),check_error_every=3,
                         tol=1e-7);

    # Produced with a different implementation
    Tstar=[  -1.665117675679600   5.780562035399026                   0                   0
             5.780562035399026  11.562308485001218 -18.839546184493731                   0
             0  18.839546184493734 -15.213756300995186   9.788512505128466                                
             0                   0   9.788512505128464  -0.120825360586847                                ] 
    n0=size(Tstar,1);
    @test norm(Tstar-T[1:n0,1:n0])<1e-10

    thiserr=ones(m)*NaN
    for i=1:length(λ)
        thiserr[i]=norm(compute_Mlincomb(nep,λ[i],V[:,i]));
    end
    @test length(find(thiserr .< 1e-7)) == 7
end


@testset "Infbilanczos σ=$x" for x in (1.0, 1.0+0.1im)
    m=30;
    λ,V,T = infbilanczos(nep,nept,maxit=m,Neig=2,σ=x,tol=1e-7,
                         v=ones(n),u=ones(n));
    thiserr=ones(m)*NaN
    for i=1:length(λ)
        thiserr[i]=norm(compute_Mlincomb(nep,λ[i],V[:,i]));
    end
    @test length(find(thiserr .< 1e-7)) >= 2
end

    




#
##for i=1:m
## semilogy(1:m, err[1:m,i], color="red", linewidth=2.0, linestyle="--")
##end
##
#errormeasure=default_errmeasure(nep);
#for i=1:length(λ)
# println("Eigenvalue=",λ[i]," residual = ",errormeasure(λ[i],Q[:,i]))
#end
#
