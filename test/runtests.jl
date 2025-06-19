using HorseySet
using Test

@testset "HorseySet.jl" begin
    @testset "Basic Operations" begin
        s = StableSet{Int}()
        @test isempty(s)
        @test length(s) == 0
        
        push!(s, 1)
        @test !isempty(s)
        @test length(s) == 1
        @test 1 in s
        @test !(2 in s)
        
        push!(s, 2)
        push!(s, 3)
        @test length(s) == 3
        @test 2 in s
        @test 3 in s
        
        delete!(s, 2)
        @test length(s) == 2
        @test !(2 in s)
        @test 1 in s
        @test 3 in s
    end
    
    @testset "Insertion Order Preservation" begin
        s = StableSet{Int}()
        push!(s, 3)
        push!(s, 1)
        push!(s, 4)
        push!(s, 1)  # duplicate
        push!(s, 5)
        
        @test collect(s) == [3, 1, 4, 5]
        
        # Test with strings
        s_str = StableSet{String}()
        push!(s_str, "hello")
        push!(s_str, "world")
        push!(s_str, "foo")
        push!(s_str, "hello")  # duplicate
        
        @test collect(s_str) == ["hello", "world", "foo"]
    end
    
    @testset "Construction from Iterator" begin
        s = StableSet([1, 2, 3, 2, 4])
        @test collect(s) == [1, 2, 3, 4]
        
        s_empty = StableSet{Int}()
        @test collect(s_empty) == []
        
        s_any = StableSet()
        push!(s_any, "hello")
        push!(s_any, 42)
        @test length(s_any) == 2
    end
    
    @testset "Set Operations" begin
        s1 = StableSet([1, 2, 3])
        s2 = StableSet([3, 4, 5])
        
        # Union preserves order from first set, then second
        u = union(s1, s2)
        @test collect(u) == [1, 2, 3, 4, 5]
        
        # Intersection preserves order from first set
        i = intersect(s1, s2)
        @test collect(i) == [3]
        
        # Difference preserves order from first set
        d = setdiff(s1, s2)
        @test collect(d) == [1, 2]
    end
    
    @testset "Pop Operation" begin
        s = StableSet([1, 2, 3])
        
        # pop! should remove first element
        x = pop!(s)
        @test x == 1
        @test collect(s) == [2, 3]
        
        # Test error on empty set
        empty!(s)
        @test_throws ArgumentError pop!(s)
    end
    
    @testset "Equality and Hashing" begin
        s1 = StableSet([1, 2, 3])
        s2 = StableSet([3, 2, 1])
        s3 = StableSet([1, 2, 3])
        
        # Sets with same elements but different order should be equal
        @test s1 == s2
        @test s1 == s3
        @test hash(s1) == hash(s2)  # Same elements should hash equally
    end
    
    @testset "Filter Operation" begin
        s = StableSet([1, 2, 3, 4, 5])
        filter!(x -> x % 2 == 0, s)
        @test collect(s) == [2, 4]
    end
    
    @testset "Display" begin
        s = StableSet([1, 2, 3])
        str = string(s)
        @test occursin("StableSet{Int64}", str)
        @test occursin("1", str)
        @test occursin("2", str)
        @test occursin("3", str)
    end
end
