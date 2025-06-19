module HorseySet

export StableSet

mutable struct StableSetType{T}
    dict::Dict{T, Nothing}
    keys::Vector{T}
    
    StableSetType{T}() where T = new{T}(Dict{T, Nothing}(), T[])
    StableSetType{T}(dict::Dict{T, Nothing}, keys::Vector{T}) where T = new{T}(dict, keys)
end

const StableSet = StableSetType

StableSet() = StableSet{Any}()

function StableSet(itr)
    T = eltype(itr)
    d = Dict{T, Nothing}()
    k = T[]
    for x in itr
        if !haskey(d, x)
            d[x] = nothing
            push!(k, x)
        end
    end
    StableSet{T}(d, k)
end

Base.length(s::StableSet) = length(s.dict)
Base.isempty(s::StableSet) = isempty(s.dict)
Base.empty!(s::StableSet) = (empty!(s.dict); empty!(s.keys); s)

Base.in(x, s::StableSet) = haskey(s.dict, x)
function Base.push!(s::StableSet, x)
    if !haskey(s.dict, x)
        s.dict[x] = nothing
        push!(s.keys, x)
    end
    return s
end

function Base.delete!(s::StableSet, x)
    if haskey(s.dict, x)
        delete!(s.dict, x)
        idx = findfirst(==(x), s.keys)
        if idx !== nothing
            deleteat!(s.keys, idx)
        end
    end
    return s
end

function Base.pop!(s::StableSet)
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    key = s.keys[1]
    delete!(s.dict, key)
    popfirst!(s.keys)
    return key
end

Base.iterate(s::StableSet) = iterate(s.keys)
Base.iterate(s::StableSet, state) = iterate(s.keys, state)

Base.union(s1::StableSet, s2::StableSet) = StableSet(Iterators.flatten((s1, s2)))
Base.intersect(s1::StableSet, s2::StableSet) = StableSet(x for x in s1 if x in s2)
Base.setdiff(s1::StableSet, s2::StableSet) = StableSet(x for x in s1 if x ∉ s2)

function Base.filter!(f, s::StableSet)
    to_remove = [k for k in s.keys if !f(k)]
    for k in to_remove
        delete!(s, k)
    end
    return s
end

Base.:(==)(s1::StableSet, s2::StableSet) = s1.dict == s2.dict
Base.hash(s::StableSet, h::UInt) = hash(Set(s.keys), h)

Base.show(io::IO, s::StableSet{T}) where T = print(io, "StableSet{$T}([", join(s, ", "), "])")

end