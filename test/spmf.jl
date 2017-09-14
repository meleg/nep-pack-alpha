# Tests for SPMF-code


# Intended to be run from nep-pack/ directory or nep-pack/test directory
workspace()
push!(LOAD_PATH, pwd()*"/src")	


using NEPSolver
using NEPCore
using NEPTypes
using Gallery

using Base.Test


# Create an SPMF
n=5;
srand(1)
A0=sparse(randn(n,n));
A1=sparse(randn(n,n));
t=3.0

minusop= S-> -S
oneop= S -> eye(S)
expmop= S -> sqrtm(full(-t*S)+10*eye(S))
fi=[minusop, oneop, expmop];


nep1=SPMF_NEP([speye(n),A0,A1],fi)
nep2=SPMF_NEP([speye(n),A0,A1],fi, true)

S=randn(3,3);
V=randn(n,3);

# Check if prefactorize with Schur gives the same result
@test norm(compute_MM(nep1,S,V)-compute_MM(nep2,S,V))<sqrt(eps())


# Check if compute_MM is correct (by comparing against diagonalization of S).
# This is done with the identity MM(V,S)=MM(V,W*D*inv(W))=MM(V*W,D)*inv(W)
# and MM(V1,D) for diagonal D can be computed with compute_Mlincomb

N1=compute_MM(nep1,S,V);
# Diagonalize S
(d,W)=eig(S);
D=diagm(d);
V1=V*W;
# 
N2=hcat(compute_Mlincomb(nep1,d[1],V1[:,1]),
        compute_Mlincomb(nep1,d[2],V1[:,2]),
        compute_Mlincomb(nep1,d[3],V1[:,3]))*inv(W)
@test norm(N1-N2)<sqrt(eps())


# Same nonlinearities as the GUN NLEVP problem
minusop= S-> -S
oneop= S -> eye(size(S,1),size(S,2))
sqrt1op= S -> 1im*sqrtm(full(S))
sqrt2op= S -> 1im*sqrtm(full(S)-108.8774^2*eye(S))

A0=sparse(randn(n,n))+1im*sparse(randn(n,n));
A1=sparse(randn(n,n))+1im*sparse(randn(n,n));
A2=sparse(randn(n,n))+1im*sparse(randn(n,n));
A3=sparse(randn(n,n))+1im*sparse(randn(n,n));
nep2=SPMF_NEP([A0,A1,A2,A3],[oneop,minusop,sqrt1op,sqrt2op]);

N1=compute_MM(nep2,S,V);
# Diagonalize S
(d,W)=eig(S);
D=diagm(d);
V1=V*W;
# 
N2=hcat(compute_Mlincomb(nep2,d[1],V1[:,1]),
        compute_Mlincomb(nep2,d[2],V1[:,2]),
        compute_Mlincomb(nep2,d[3],V1[:,3]))*inv(W)
@test norm(N1-N2)<sqrt(eps())


# Check consistency of MM and Mder

Z1=compute_Mlincomb_from_MM(nep2,d[1],V,[1.0 1.0 1.0])
Z2=compute_Mlincomb_from_Mder(nep2,d[1],V,[1.0 1.0 1.0])

@test norm(Z1-Z2)<sqrt(eps())
