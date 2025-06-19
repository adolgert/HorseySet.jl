# HorseySet

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://adolgert.github.io/HorseySet.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://adolgert.github.io/HorseySet.jl/dev/)
[![Build Status](https://github.com/adolgert/HorseySet.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/adolgert/HorseySet.jl/actions/workflows/CI.yml?query=branch%3Amain)

HorseySet.jl provides a `StableSet` data structure that maintains insertion order while providing efficient set operations. Unlike Julia's built-in `Set`, `StableSet` preserves the order in which elements were first added.

This repository asks whether emulating the Python hash-based stable set is advantageous in Julia, and the answer seems to be no from the benchmarks in test/benchmark.jl. The fully-ordered sets are faster. Maybe the implementation needs to be tweaked because a stable set should be faster than a fully-ordered set.

## Usage

```julia
using HorseySet

# Create a stable set
s = StableSet{Int}()
push!(s, 3)
push!(s, 1) 
push!(s, 4)
push!(s, 1)  # duplicate ignored

collect(s)  # [3, 1, 4] - order preserved

# Set operations maintain order
s1 = StableSet([1, 2, 3])
s2 = StableSet([3, 4, 5])
union(s1, s2)  # StableSet with elements [1, 2, 3, 4, 5]
```
