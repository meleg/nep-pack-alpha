# Transforming NEPs

There are various ways to transform NEPs into other NEPs.
The simplest example is the function `shift_and_scale()`.


```@docs
shift_and_scale
```

Similarly `mobius_transform()` is more general
than `shift_and_scale` which transform
the problem using a Möbius transformation. The function `taylor_exp`
create new PEP by doing truncating a Taylor expansion.

# Projection

Several methods for NEPs are based on forming
a smaller NEP, which we will refer to as a projection:
```math
N(λ)=W^HM(λ)V,
```
where $V,W\in\mathbb{C}^{n\times p}$ 
and the corresponding projected problem
```math
N(λ)u=0.
```

NEPs which for which this projection can be computed
inherit from `ProjectableNEP`. The most important
type is the `SPMF_NEP`. 

You can create a projected NEP with `create_proj_NEP`:

```@docs
create_proj_NEP
```

```@docs
set_projectmatrices!(nep::Proj_SPMF_NEP,W,V)
```



# Deflation

Due to structure of the representation of NEPs in NEP-PACK
it is possible to do deflation, by transformation of the NEP-object.
The deflation is based on theory provided in Effenbergers thesis
and the main function consists of `effenberger_deflation`.

```@docs
effenberger_deflation
```