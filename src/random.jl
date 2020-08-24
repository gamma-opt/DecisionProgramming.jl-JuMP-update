using Random, Parameters

"""Generates random information sets for chance and decision nodes."""
function information_set(rng::AbstractRNG, j::Int, n_I::Int)
    m = min(rand(rng, 0:n_I), j-1)
    return shuffle(rng, 1:(j-1))[1:m]
end

"""Generates random information sets for value nodes."""
function information_set(rng::AbstractRNG, leaf_nodes::Vector{Node}, n::Int)
    non_leaf_nodes = shuffle(rng, setdiff(1:n, leaf_nodes))
    m = rand(rng, 1:length(non_leaf_nodes))
    return [leaf_nodes; non_leaf_nodes[1:m]]
end

"""Generate random decision diagram with `n_C` chance nodes, `n_D` decision nodes, and `n_V` value nodes.
Parameter `n_I` is the upper bound on the size of the information set.

# Examples
```julia
rng = MersenneTwister(3)
random_diagram(rng, 5, 2, 3, 2)
```
"""
function random_diagram(rng::AbstractRNG, n_C::Int, n_D::Int, n_V::Int, n_I::Int)
    n = n_C + n_D
    n_C ≥ 0 || throw(DomainError("There should be ≥ 0 chance nodes."))
    n_D ≥ 0 || throw(DomainError("There should be ≥ 0 decision nodes"))
    n ≥ 1 || throw(DomainError("There should be at least one chance and decision node."))
    n_V ≥ 1 || throw(DomainError("There should be ≥ 1 value nodes."))
    n_I ≥ 1 || throw(DomainError("Information set should be size ≥ 1."))

    # Create node indices
    U = shuffle(rng, 1:n)
    C_j = sort(U[1:n_C])
    D_j = sort(U[(n_C+1):n])
    V_j = collect((n+1):(n+n_V))

    # Create chance and decision nodes
    C = [ChanceNode(j, information_set(rng, j, n_I)) for j in C_j]
    D = [DecisionNode(j, information_set(rng, j, n_I)) for j in D_j]

    # Assign each leaf node to a random value node
    leaf_nodes = setdiff(1:n, (c.I_j for c in C)..., (d.I_j for d in D)...)
    leaf_nodes_j = Dict(j=>Node[] for j in V_j)
    for i in leaf_nodes
        k = rand(rng, V_j)
        push!(leaf_nodes_j[k], i)
    end

    # Create values nodes
    V = [ValueNode(j, information_set(rng, leaf_nodes_j[j], n)) for j in V_j]

    return C, D, V
end

"""Generate `n` random states from `states`.

# Examples
```julia
rng = MersenneTwister(3)
S = States(rng, [2, 3], 10)
```
"""
function States(rng::AbstractRNG, states::Vector{State}, n::Int)
    States(rand(rng, states, n))
end

"""Generate random probabilities for chance node `c` with `S` states.

# Examples
```julia
rng = MersenneTwister(3)
c = ChanceNode(2, [1])
S = States([2, 2])
Probabilities(rng, c, S)
```
"""
function Probabilities(rng::AbstractRNG, c::ChanceNode, S::States; n_inactive::Int=0)
    states = S[c.I_j]
    state = S[c.j]
    if !(0 ≤ n_inactive ≤ prod([states...; (state - 1)]))
        throw(DomainError("Number of inactive states must be < prod([S[I_j]...;, S[j]-1])"))
    end

    # Create the random probabilities
    X = rand(rng, states..., state)

    # Create inactive chance states
    if n_inactive > 0
        # Count of inactive states per chance stage.
        c = zeros(Int, states...)
        # There can be maximum of (state - 1) inactive chance states per stage.
        b = repeat(vec(CartesianIndices(c)), state - 1)
        # Uniform random sample of n_inactive states.
        r = shuffle(rng, b)[1:n_inactive]
        for s in r
            c[s] += 1
        end
        for s in CartesianIndices(c)
            indices = CartesianIndices(X[s, :])
            i = shuffle(rng, indices)[1:c[s]]
            X[s, i] .= 0.0
        end
    end

    # Normalize the probabilities
    for s in CartesianIndices((states...,))
        X[s, :] /= sum(X[s, :])
    end

    Probabilities(X)
end

scale(x::Float64, low::Float64, high::Float64) = x * (high - low) + low

"""Generate random consequences between `low` and `high` for value node `v` with `S` states.

# Examples
```julia
rng = MersenneTwister(3)
v = ValueNode(3, [1])
S = States([2, 2])
Consequences(rng, v, S; low=-1.0, high=1.0)
```
"""
function Consequences(rng::AbstractRNG, v::ValueNode, S::States; low::Float64=-1.0, high::Float64=1.0)
    if !(high > low)
        throw(DomainError("high should be greater than low"))
    end
    Y = rand(rng, S[v.I_j]...)
    Y = scale.(Y, low, high)
    Consequences(Y)
end

"""Generate random decision strategy for decision node `d` with `S` states.

# Examples
```julia
rng = MersenneTwister(3)
d = DecisionNode(2, [1])
S = States([2, 2])
DecisionStrategy(rng, d, S)
```
"""
function LocalDecisionStrategy(rng::AbstractRNG, d::DecisionNode, S::States)
    states = S[d.I_j]
    state = S[d.j]
    Z = zeros(Int, states..., state)
    for s in CartesianIndices((states...,))
        s_j = rand(rng, 1:state)
        Z[s, s_j] = 1
    end
    LocalDecisionStrategy(Z)
end
