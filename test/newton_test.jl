# Run tests on Newton methods

# Intended to be run from nep-pack/ directory or nep-pack/test directory
workspace()
push!(LOAD_PATH, string(@__DIR__, "/../src"))
using NEPSolver
using NEPCore
using NEPTypes
using Gallery
using LinSolvers

using Base.Test

nep=nep_gallery("dep0")
@testset "Newton iterations" begin

@testset "Newton and AugNewton" begin
# newton and augnewton are equivalent, therefore I expect them
# to generate identical results
λ1,x1 =newton(nep,displaylevel=0,v=ones(size(nep,1)),λ=0,tol=eps()*10);
λ2,x2 =augnewton(nep,displaylevel=0,v=ones(size(nep,1)),λ=0,tol=eps()*10);


@test λ1 ≈ λ2
@test x1 ≈ x2
r1=compute_resnorm(nep,λ1,x1)
r2=compute_resnorm(nep,λ2,x2)

@test r1 < eps()*100
@test r2 < eps()*100
end

@testset "Newton QR" begin

#Run derivative test for left and right eigenvectors returned by newtonqr
λ3,x3,y3 =  newtonqr(nep, λ=0, v=ones(size(nep,1)), displaylevel=0,tol=eps()*10);

#println("\nTesting formula for derivative (with left and right eigvecs)\n")
tau=1;
n=size(nep,1);
Mλ=-eye(n)-tau*nep.A[2]*exp(-tau*λ3)
Mtau= -λ3*nep.A[2]*exp(-tau*λ3);

# Formula for derivative
λp=-(y3'*(Mtau)*x3) / (y3'* Mλ*x3)

δ=0.0001;

nep.tauv[2]=nep.tauv[2]+δ

λ3δ,x3,y3 =newtonqr(nep, λ=0, v=ones(size(nep,1)), displaylevel=0,tol=eps()*10);

λp_approx=(λ3δ-λ3)/δ;

@test abs(λp-λp_approx)< (δ*10)
end

@testset "Resinv" begin
# basic functionality of resinv
λ4,x4 =  resinv(nep, λ=0, v=ones(size(nep,1)), displaylevel=0,tol=eps()*10);
r4=compute_resnorm(nep,λ4,x4)

@test r4 < eps()*100
end

end
