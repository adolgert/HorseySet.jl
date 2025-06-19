module HorseySet

export StableSet

# Include the Python-based implementation
include("PythonSet.jl")

# Wrapper struct to match the original API
mutable struct StableSetType{T}
    pythonset::PythonHashSet{T}
    
    StableSetType{T}() where T = new{T}(PythonHashSet{T}())
    StableSetType{T}(pythonset::PythonHashSet{T}) where T = new{T}(pythonset)
end

const StableSet = StableSetType

StableSet() = StableSet{Any}()

function StableSet(itr)
    T = eltype(itr)
    pythonset = PythonHashSet{T}()
    for x in itr
        set_add_key(pythonset, x)
    end
    StableSet{T}(pythonset)
end

Base.length(s::StableSet) = length(s.pythonset)
Base.isempty(s::StableSet) = isempty(s.pythonset)
function Base.empty!(s::StableSet{T}) where T
    s.pythonset = PythonHashSet{T}()
    return s
end

Base.in(x, s::StableSet) = x in s.pythonset
Base.push!(s::StableSet, x) = (push!(s.pythonset, x); s)
Base.delete!(s::StableSet, x) = (delete!(s.pythonset, x); s)

function Base.pop!(s::StableSet)
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    # Get first element and remove it
    first_elem = first(s.pythonset)
    delete!(s.pythonset, first_elem)
    return first_elem
end

Base.iterate(s::StableSet) = iterate(s.pythonset)
Base.iterate(s::StableSet, state) = iterate(s.pythonset, state)

Base.union(s1::StableSet, s2::StableSet) = StableSet(Iterators.flatten((s1, s2)))
Base.intersect(s1::StableSet, s2::StableSet) = StableSet(x for x in s1 if x in s2)
Base.setdiff(s1::StableSet, s2::StableSet) = StableSet(x for x in s1 if x ∉ s2)

function Base.filter!(f, s::StableSet)
    to_remove = [k for k in s if !f(k)]
    for k in to_remove
        delete!(s, k)
    end
    return s
end

function Base.:(==)(s1::StableSet, s2::StableSet)
    length(s1) == length(s2) && all(x in s2 for x in s1)
end

Base.hash(s::StableSet, h::UInt) = hash(Set(s), h)

Base.show(io::IO, s::StableSet{T}) where T = print(io, "StableSet{$T}([", join(s, ", "), "])")

end