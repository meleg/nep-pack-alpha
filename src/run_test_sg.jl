#  A Polynomial eigenvalue problem
workspace()
push!(LOAD_PATH, pwd())	# look for modules in the current directory
using NEPSolver
using NEPCore
using NEPTypes
using NEPSolver_SG_ITER
using Gallery
#using Winston # For plotting

nep=nep_gallery("real_quadratic");


# Four smallest eigenvalues of the problem "real_quadratic":
# 1.0e+03 *
# -2.051741417993845
# -0.182101627437811
# -0.039344930222838
# -0.004039879577113


λ_init = -100;
λ,x = sg_iteration(nep,tol_outer=1e-4,tol_inner=1e-6,λ_approx=λ_init,λ_nr=1,displaylevel=1)
println("Resnorm of computed solution: ",compute_resnorm(nep,λ,x))
