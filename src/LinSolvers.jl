module LinSolvers
    using NEPCore
    using IterativeSolvers
    using LinearMaps

    # Linear system of equation solvers
    export LinSolver
    export DefaultLinSolver
    export BackslashLinSolver
    export GMRESLinSolver
    export lin_solve

    export default_linsolvercreator
    export backslash_linsolvercreator
    export gmres_linsolvercreator

    # Eigenvalue solvers
    export EigSolver
    export NativeEigSolver
    export NativeEigSSolver

    export DefaultEigSolver
    export eig_solve

    import Base.eltype
    export eltype
    import Base.size
    export size
    import Base.*
    export *

##############################################################################
    abstract type LinSolver end
    abstract type EigSolver end

##############################################################################
    """
        The linear solver associated with julia factorize()
    """
    type DefaultLinSolver{T_num<:Number, T_mat<:AbstractMatrix} <: LinSolver
        A::T_mat
        Afact

    end
    DefaultLinSolver(A::AbstractMatrix,Afact) = new(A, Afact)

    function DefaultLinSolver(nep::NEP,λ)
        A=compute_Mder(nep,λ)
        Afact=factorize(A)
        return DefaultLinSolver{eltype(A),typeof(A)}(A, Afact)
    end

    function lin_solve{T_num}(solver::DefaultLinSolver{T_num}, x::Array; tol=eps(real(T_num)))
        return solver.Afact\x
    end

"""
   default_linsolvercreator(nep::NEP, λ)\n
      Creates a linear solver of type 'DefaultLinSolver'.
"""
    function default_linsolvercreator(nep::NEP, λ)
        return DefaultLinSolver(nep, λ)
    end


"""
      A linear solver which calls backslash directly (no pre-factorization)
"""
    type BackslashLinSolver{T_num<:Number, T_mat<:AbstractMatrix} <: LinSolver
        A::T_mat
    end
    BackslashLinSolver{T_num}(A::AbstractMatrix{T_num}) = new(A)

    function BackslashLinSolver(nep::NEP,λ)
        A=compute_Mder(nep,λ)
        return BackslashLinSolver{eltype(A), typeof(A)}(A)
    end

    function lin_solve{T_num}(solver::BackslashLinSolver{T_num}, x::Array; tol=eps(real(T_num)))
        return solver.A\x
    end

"""
   backslash_linsolvercreator(nep::NEP, λ)\n
      Creates a linear solver of type 'BackslashLinSolver'.
"""
    function backslash_linsolvercreator(nep::NEP, λ)
        return BackslashLinSolver(nep, λ)
    end


##############################################################################
"""
      A linear solver based on GMRES (built into Julia)
"""
    type GMRESLinSolver{T_num<:Number, T_nep<:NEP} <: LinSolver
        A::LinearMap{T_num}
        kwargs
        gmres_log::Bool

        function GMRESLinSolver{T_num, T_nep}(nep::T_nep, λ::T_num, kwargs) where {T_num<:Number, T_nep<:NEP}
            function f(v::AbstractVector)
              return compute_Mlincomb(nep, λ, v, a=[1])
            end
            A = LinearMap{T_num}(f, size(nep,1), ismutating=false)
            gmres_log = false
            for elem in kwargs
                gmres_log |= ((elem[1] == :log) && elem[2])
            end
            new{T_num, T_nep}(A, kwargs, gmres_log)
        end

    end


    function lin_solve{T_num, T_nep}(solver::GMRESLinSolver{T_num, T_nep}, x::Array; tol=eps(real(T_num)))
        if( solver.gmres_log )
            x, convhist = gmres(solver.A, x; tol=tol, solver.kwargs...)
        else
            x = gmres(solver.A, x; tol=tol, solver.kwargs...)
        end
        return x
    end

"""
   gmres_linsolvercreator(nep::NEP, λ, kwargs=())\n
      Creates a linear solver of type 'GMRESLinSolver'.
      Accepts kwargs which are passed to Julia-built-in-GMRES.
"""
    function gmres_linsolvercreator(nep::NEP, λ, kwargs=())
        return GMRESLinSolver{typeof(λ), typeof(nep)}(nep, λ, kwargs)
    end


##############################################################################
"""
    A linear EP solver that calls Julia's in-built eig()
"""
    type NativeEigSolver <: EigSolver
        A
        B

        function NativeEigSolver(A,B=zeros(eltype(A),0))
            this = new()
            this.A = A
            this.B = B

            return this
        end
    end

    function eig_solve(solver::NativeEigSolver;nev = 1, target = 0)
        if(solver.B != zeros(eltype(solver.A),0))
            D,V = eig(solver.A,solver.B);
        else
            D,V = eig(solver.A);
        end

        #Sort the eigenvalues wrt distance from target, and permute
        I = sortperm(abs.(target*ones(size(D,1))-D));
        D = D[I];V = V[:,I];

        #Return the nev closest values to target
        if(nev == 1)
            return D[1],V[:,1]
        end

        return D[1:nev],V[:,1:nev];
    end

"""
    A linear EP solve that calls Julia's in-built eigs()
"""
    type NativeEigSSolver <: EigSolver
        A
        B

        function NativeEigSSolver(A,B=spzeros(eltype(A),0))
            this = new()
            this.A = A
            this.B = B

            return this
        end

    end

    function eig_solve(solver::NativeEigSSolver;nev=6,target=0)
        if(solver.B != spzeros(eltype(solver.A),0))
            # Julia's eigs(A,B) is currently broken for
            # indefinite B 
            # https://github.com/JuliaLang/julia/issues/24668
            # This is what we want to do:
            # D,V = eigs(solver.A,solver.B;nev=nev,sigma=target)
            # We do a work-around by computing
            # largest eigenvalue of (target B -A)\B 
            C=target*solver.B-solver.A;
            Cfact=factorize(C);
            Atransformed=LinearMap(x->Cfact\(solver.B*x),
                                   size(solver.A,1),size(solver.A,1));
            D0,V =eigs(Atransformed;nev=nev,which=:LM);
            # And reverse transformation
            D=target-inv.(D0); # Reverse transformation 
        else
            D,V = eigs(solver.A;nev=nev,sigma=target)
        end

        if(nev == 1)
            return D[1],V[:,1]
        end

        return D,V
    end





"""
    Default linear EP solver which calls checks for sparsity and accordingly assigns an appropriate solver
"""
    type DefaultEigSolver <: EigSolver
        subsolver::EigSolver

        function DefaultEigSolver(A,B=zeros(eltype(A),0))
            this = new()
            if(issparse(A))
                this.subsolver = NativeEigSSolver(A,B);
            else
                this.subsolver = NativeEigSolver(A,B);
            end
            return this
        end
    end

    # Additional constructor that allows for calling the default linear eigensolver with a NEP rather than an explicit matrix
    function DefaultEigSolver(nep::NEP,λ::Number)
        return DefaultEigSolver(compute_Mder(nep,λ))
    end

    function eig_solve(solver::DefaultEigSolver;nev=size(solver.subsolver.A,1),target=0)

        return eig_solve(solver.subsolver,nev=nev,target=target)

    end
end
