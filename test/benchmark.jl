using Random
using BenchmarkTools
using HorseySet
using Printf

# Include the PythonHashSet implementation  
include("../src/PythonSet.jl")
include("../src/PythonSetImmutable.jl")

# Optional dependencies - load if available
const HAS_ORDERED_COLLECTIONS = try
    using OrderedCollections
    true
catch
    false
end

const HAS_DATA_STRUCTURES = try
    using DataStructures
    true
catch
    false
end

# Helper functions for setup
function setup_set!(set_obj, src_range, cnt, rng)
    while length(set_obj) < cnt
        push!(set_obj, rand(rng, src_range))
    end
    return set_obj
end

function create_test_data(size, coverage, rng)
    range = 1:size * coverage
    # Pre-generate data for consistent benchmarking
    insert_data = [rand(rng, range) for _ in 1:100]
    delete_data = [rand(rng, range) for _ in 1:100]
    return range, insert_data, delete_data
end

# Benchmark functions
function benchmark_insertion(set_type, size, coverage, rng)
    range, insert_data, _ = create_test_data(size, coverage, rng)
    
    return @benchmark begin
        set_obj = $set_type()
        setup_set!(set_obj, $range, $size, $rng)
        for val in $insert_data
            push!(set_obj, val)
        end
    end samples=10 evals=1
end

function benchmark_deletion(set_type, size, coverage, rng)
    range, _, delete_data = create_test_data(size, coverage, rng)
    
    return @benchmark begin
        set_obj = $set_type()
        setup_set!(set_obj, $range, $size, $rng)
        for val in $delete_data
            if val ∈ set_obj
                delete!(set_obj, val)
            end
        end
    end samples=10 evals=1
end

function benchmark_iteration(set_type, size, coverage, rng)
    range, _, _ = create_test_data(size, coverage, rng)
    
    return @benchmark begin
        set_obj = $set_type()
        setup_set!(set_obj, $range, $size, $rng)
        buffer = Vector{Int}(undef, length(set_obj))
        i = 1
        for val in set_obj
            buffer[i] = val
            i += 1
        end
        buffer
    end samples=10 evals=1
end

function benchmark_lookup(set_type, size, coverage, rng)
    range, _, lookup_data = create_test_data(size, coverage, rng)
    
    return @benchmark begin
        set_obj = $set_type()
        setup_set!(set_obj, $range, $size, $rng)
        count = 0
        for val in $lookup_data
            if val ∈ set_obj
                count += 1
            end
        end
        count
    end samples=10 evals=1
end

function format_benchmark_result(result)
    med_time = median(result.times) / 1e6  # Convert to milliseconds
    min_time = minimum(result.times) / 1e6
    allocs = result.allocs
    memory = result.memory
    return (med_time, min_time, allocs, memory)
end

function time_set_type(set_type)
    results = Dict{String, Any}()
    rng = Xoshiro(2934823)
    sizes = [100, 1000, 10000]
    coverages = [2, 10, 100]
    
    println("\n" * "="^60)
    println("Benchmarking: $(set_type)")
    println("="^60)
    
    for size in sizes
        for coverage in coverages
            println("\nSize: $size, Coverage: $coverage (range 1:$(size*coverage))")
            println("-"^40)
            
            # Benchmark insertion
            ins_result = benchmark_insertion(set_type, size, coverage, rng)
            ins_med, ins_min, ins_allocs, ins_mem = format_benchmark_result(ins_result)
            
            # Benchmark deletion  
            del_result = benchmark_deletion(set_type, size, coverage, rng)
            del_med, del_min, del_allocs, del_mem = format_benchmark_result(del_result)
            
            # Benchmark iteration
            iter_result = benchmark_iteration(set_type, size, coverage, rng)
            iter_med, iter_min, iter_allocs, iter_mem = format_benchmark_result(iter_result)
            
            # Benchmark lookup
            lookup_result = benchmark_lookup(set_type, size, coverage, rng)
            lookup_med, lookup_min, lookup_allocs, lookup_mem = format_benchmark_result(lookup_result)
            
            @printf "  Insertion:  %6.2f ms (min: %6.2f ms) | %6d allocs | %8d bytes\n" ins_med ins_min ins_allocs ins_mem
            @printf "  Deletion:   %6.2f ms (min: %6.2f ms) | %6d allocs | %8d bytes\n" del_med del_min del_allocs del_mem  
            @printf "  Iteration:  %6.2f ms (min: %6.2f ms) | %6d allocs | %8d bytes\n" iter_med iter_min iter_allocs iter_mem
            @printf "  Lookup:     %6.2f ms (min: %6.2f ms) | %6d allocs | %8d bytes\n" lookup_med lookup_min lookup_allocs lookup_mem
            
            # Store results for later analysis
            key = "$(size)_$(coverage)"
            results[key] = Dict(
                "insertion" => ins_result,
                "deletion" => del_result,
                "iteration" => iter_result,
                "lookup" => lookup_result
            )
        end
    end
    
    return results
end

function benchmark_all()
    println("🚀 Starting comprehensive set implementation benchmarks...")
    
    all_results = Dict{String, Any}()
    
    # Define core set types to benchmark
    set_types = [
        ("Julia Set", Set{Int}),
        ("HorseySet (StableSet)", StableSet{Int}),
        ("PythonHashSet (Mutable)", PythonHashSet{Int}),
        ("PythonHashSet (Immutable)", PythonHashSetImmutable{Int})
    ]
    
    # Add optional set types if packages are available
    if HAS_ORDERED_COLLECTIONS
        push!(set_types, ("OrderedSet", OrderedCollections.OrderedSet{Int}))
    end
    
    if HAS_DATA_STRUCTURES
        push!(set_types, ("SortedSet", DataStructures.OrderedSet{Int}))
    end
    
    for (name, set_type) in set_types
        try
            results = time_set_type(set_type)
            all_results[name] = results
        catch e
            println("❌ Error benchmarking $name: $e")
        end
    end
    
    println("\n" * "="^60)
    println("🎯 Benchmark Summary Complete!")
    println("="^60)
    println("Results stored in returned dictionary for further analysis.")
    
    return all_results
end

function benchmark_quick()
    """Quick benchmark with smaller dataset for testing"""
    println("🚀 Running quick benchmarks...")
    
    all_results = Dict{String, Any}()
    
    # Define core set types to benchmark
    set_types = [
        ("Julia Set", Set{Int}),
        ("HorseySet (StableSet)", StableSet{Int}),
        ("PythonHashSet (Mutable)", PythonHashSet{Int}),
        ("PythonHashSet (Immutable)", PythonHashSetImmutable{Int})
    ]
    
    # Add optional set types if packages are available
    if HAS_ORDERED_COLLECTIONS
        push!(set_types, ("OrderedSet", OrderedCollections.OrderedSet{Int}))
    end
    
    if HAS_DATA_STRUCTURES
        push!(set_types, ("SortedSet", DataStructures.OrderedSet{Int}))
    end
    
    rng = Xoshiro(2934823)
    sizes = [100, 1000]  # Smaller sizes for quick testing
    coverages = [10]     # Single coverage for speed
    
    for (name, set_type) in set_types
        println("\n" * "="^40)
        println("Benchmarking: $name")
        println("="^40)
        
        for size in sizes
            for coverage in coverages
                println("\nSize: $size, Coverage: $coverage")
                println("-"^20)
                
                # Quick benchmarks with fewer samples
                ins_result = @benchmark begin
                    set_obj = $set_type()
                    setup_set!(set_obj, 1:$(size*coverage), $size, $rng)
                    for i in 1:10
                        push!(set_obj, rand($rng, 1:$(size*coverage)))
                    end
                end samples=3 evals=1
                
                lookup_result = @benchmark begin
                    set_obj = $set_type()
                    setup_set!(set_obj, 1:$(size*coverage), $size, $rng)
                    count = 0
                    for i in 1:10
                        val = rand($rng, 1:$(size*coverage))
                        if val ∈ set_obj
                            count += 1
                        end
                    end
                    count
                end samples=3 evals=1
                
                ins_med = median(ins_result.times) / 1e6
                lookup_med = median(lookup_result.times) / 1e6
                
                @printf "  Insertion:  %6.3f ms | %6d allocs\n" ins_med ins_result.allocs
                @printf "  Lookup:     %6.3f ms | %6d allocs\n" lookup_med lookup_result.allocs
            end
        end
    end
    
    println("\n✅ Quick benchmark complete!")
end
