export tiar
using IterativeSolvers

"""
    tiar(nep,[maxit=30,][σ=0,][γ=1,][linsolvecreator=default_linsolvecreator,][tolerance=eps()*10000,][Neig=6,][errmeasure=default_errmeasure,][v=rand(size(nep,1),1),][displaylevel=0,][check_error_every=1,][orthmethod=DGKS])
### Tensor Infinite Arnoldi method
Tensor Infinite Arnoldi method, as described in Algorithm 2 in  "The Waveguide Eigenvalue Problem and the Tensor Infinite Arnoldi Method",
by Jarlebring, Elias and Mele, Giampaolo and Runborg, Olof.
"""
tiar(nep::NEP;params...)=tiar(Complex128,nep;params...)
function tiar{T,T_orth<:IterativeSolvers.OrthogonalizationMethod}(
    ::Type{T},
    nep::NEP;
    orthmethod::Type{T_orth}=DGKS,
    maxit=30,
    linsolvercreator::Function=default_linsolvercreator,
    tol=eps(real(T))*10000,
    Neig=6,
    errmeasure::Function = default_errmeasure(nep::NEP),
    σ=zero(T),
    γ=one(T),
    v=randn(real(T),size(nep,1)),
    displaylevel=0,
    check_error_every=1
    )

    # initialization
    n = size(nep,1); m = maxit;

    if n<m
        msg="Loss of orthogonality in the matrix Z. The problem size is too small, use iar instead.";
        throw(LostOrthogonalityException(msg))
    end

    a  = zeros(T,m+1,m+1,m+1);
    Z  = zeros(T,n,m+1);
    t  = zeros(T,m+1);
    tt = zeros(T,m+1);
    g  = zeros(T,m+1,m+1);
    f  = zeros(T,m+1,m+1);
    ff = zeros(T,m+1,m+1);
    H  = zeros(T,m+1,m);
    h  = zeros(T,m+1);
    hh = zeros(T,m+1);
    y  = zeros(T,n,m+1);
    α=γ.^(0:m); α[1]=zero(T);
    local M0inv::LinSolver = linsolvercreator(nep,σ);
    err = ones(m+1,m+1);
    λ=zeros(T,m+1); Q=zeros(T,n,m+1);
    Z[:,1]=v; Z[:,1]=Z[:,1]/norm(Z[:,1]);
    a[1,1,1]=one(T);

    k=1; conv_eig=0;
    while (k <= m)&(conv_eig<Neig)
        if (displaylevel>0) && (rem(k,check_error_every)==0) || (k==m)
            println("Iteration:",k, " conveig:",conv_eig)
        end

        # computation of y[:,2], ..., y[:,k+1]
        y[:,2:k+1]=Z[:,1:k]*(a[1:k,k,1:k].');
        y[:,2:k+1]=y[:,2:k+1]/diagm(1:1:k);

        # computation of y[:,1]
        y[:,1] = compute_Mlincomb(nep,σ,y[:,1:k+1],a=α[1:k+1]);
        y[:,1] = -lin_solve(M0inv,y[:,1]);

        # Gram–Schmidt orthogonalization in Z
        Z[:,k+1]=y[:,1];
        t[k+1] = orthogonalize_and_normalize!(view(Z,:,1:k), view(Z,:,k+1), view(t,1:k), orthmethod)

        # compute the matrix G
        for l=1:k+1
            for i=2:k+1
                g[i,l]=a[i-1,k,l]/(i-1);
            end
         g[1,l]=t[l];
        end

        # compute h (orthogonalization with tensors factorization)
        h=zero(h);
        for l=1:k
            h[1:k]=h[1:k]+a[1:k,1:k,l]'*g[1:k,l];
        end

        # compute the matrix F
        for l=1:k
            f[1:k+1,l]=g[1:k+1,l]-a[1:k+1,1:k,l]*h[1:k];
        end

        for i=1:k+1
            f[i,k+1]=g[i,k+1];
        end

        # re-orthogonalization
        # compute hh (re-orthogonalization with tensors factorization)
        hh=zero(hh);
        for l=1:k
            hh[1:k]=hh[1:k]+a[1:k,1:k,l]'*f[1:k,l];
        end

        # compute the matrix FF
        for l=1:k
            ff[1:k+1,l]=f[1:k+1,l]-a[1:k+1,1:k,l]*hh[1:k];
        end

        for i=1:k+1
            ff[i,k+1]=f[i,k+1];
        end

        # update the orthogonalization coefficients
        h=h+hh; f=ff;

        β=vecnorm(view(f,1:k+1,1:k+1)); # equivalent to Frobenius norm

        # extend the matrix H
        H[1:k,k]=h[1:k]; H[k+1,k]=β;

        # extend the tensor
        for i=1:k+1
            for l=1:k+1
                a[i,k+1,l]=f[i,l]/β;
            end
        end

        # compute Ritz pairs (every p iterations)
        if (rem(k,check_error_every)==0)||(k==m)
            D,W=eig(H[1:k,1:k]);
            VV=Z[:,1:k]*(a[1,1:k,1:k].');	# extract proper subarray
            Q=VV*W; λ=σ+γ./D;

            conv_eig=0;
            for s=1:k
                err[k,s]=errmeasure(λ[s],Q[:,s]);
                if err[k,s]<tol; conv_eig=conv_eig+1; end
            end
            idx=sortperm(err[k,1:k]); # sort the error
            err[1:k,k]=err[idx,k];
            # extract the converged Ritzpairs
            if (k==m)||(conv_eig>=Neig)
                λ=λ[idx[1:min(length(λ),Neig)]]
                Q=Q[:,idx[1:length(λ)]]
            end
        end
        k=k+1;
    end

    # NoConvergenceException
    if conv_eig<Neig
       err=err[end,1:Neig];
       idx=sortperm(err); # sort the error
       λ=λ[idx];  Q=Q[:,idx]; err=err[idx];
        msg="Number of iterations exceeded. maxit=$(maxit)."
        if conv_eig<3
            msg=string(msg, " Check that σ is not an eigenvalue.")
        end
        throw(NoConvergenceException(λ,Q,err,msg))
    end


    # extract the converged Ritzpairs
    λ=λ[1:min(length(λ),conv_eig)];
    Q=Q[:,1:min(size(Q,2),conv_eig)];
    return λ,Q,err[1:k,:],Z[:,1:k]
end
