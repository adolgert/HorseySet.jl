using Test
include("../src/PythonSetImmutable.jl")

@testset "PythonHashSetImmutable Basic Structure" begin
    @testset "HashTableEntryImmutable" begin
        # Test empty entry
        entry = HashTableEntryImmutable{Int}()
        @test entry.state == EMPTY_IMM
        
        # Test active entry
        entry2 = HashTableEntryImmutable{Int}(42, UInt(123))
        @test entry2.key == 42
        @test entry2.hash == UInt(123)
        @test entry2.state == ACTIVE_IMM
        
        # Test dummy entry
        entry3 = HashTableEntryImmutable{Int}(Val(:dummy))
        @test entry3.state == DUMMY_IMM
    end
    
    @testset "PythonHashSetImmutable Construction" begin
        phs = PythonHashSetImmutable{Int}()
        @test length(phs.table) == 8  # Default size
        @test phs.mask == 7  # 8 - 1
        @test phs.used == 0
        @test phs.fill == 0
        
        phs2 = PythonHashSetImmutable{Int}(16)
        @test length(phs2.table) == 16
        @test phs2.mask == 15
    end
    
    @testset "Insert Operations" begin
        phs = PythonHashSetImmutable{Int}()
        
        # Test adding new key
        @test set_add_key_imm(phs, 42) == true
        @test length(phs) == 1
        @test set_contains_key_imm(phs, 42) == true
        @test set_contains_key_imm(phs, 99) == false
        
        # Test adding duplicate key
        @test set_add_key_imm(phs, 42) == false
        @test length(phs) == 1
        
        # Test adding multiple keys
        @test set_add_key_imm(phs, 1) == true
        @test set_add_key_imm(phs, 2) == true
        @test set_add_key_imm(phs, 3) == true
        @test length(phs) == 4
        
        # Test all keys exist
        @test set_contains_key_imm(phs, 42) == true
        @test set_contains_key_imm(phs, 1) == true
        @test set_contains_key_imm(phs, 2) == true
        @test set_contains_key_imm(phs, 3) == true
    end
    
    @testset "Delete Operations" begin
        phs = PythonHashSetImmutable{Int}()
        
        # Add some keys
        for i in 1:5
            set_add_key_imm(phs, i)
        end
        @test length(phs) == 5
        
        # Test removing existing key
        @test set_discard_key_imm(phs, 3) == true
        @test length(phs) == 4
        @test set_contains_key_imm(phs, 3) == false
        @test set_contains_key_imm(phs, 1) == true  # Others still exist
        
        # Test removing non-existent key
        @test set_discard_key_imm(phs, 99) == false
        @test length(phs) == 4
        
        # Test remove with error
        @test_throws KeyError set_remove_key_imm(phs, 99)
        set_remove_key_imm(phs, 1)  # Should not throw
        @test length(phs) == 3
        @test set_contains_key_imm(phs, 1) == false
    end
    
    @testset "Iterator Operations" begin
        phs = PythonHashSetImmutable{Int}()
        
        # Empty set iteration
        @test collect(phs) == []
        
        # Add some elements
        elements = [1, 5, 3, 7, 2]
        for elem in elements
            set_add_key_imm(phs, elem)
        end
        
        # Test iteration
        collected = collect(phs)
        @test length(collected) == 5
        @test Set(collected) == Set(elements)  # Same elements, order may differ
        
        # Test Base interface
        @test 3 in phs
        @test !(99 in phs)
        
        push!(phs, 99)
        @test 99 in phs
        @test length(phs) == 6
        
        delete!(phs, 99)
        @test !(99 in phs)
        @test length(phs) == 5
    end
    
    @testset "Resize Operations" begin
        phs = PythonHashSetImmutable{Int}()
        
        # Add enough elements to trigger resize
        for i in 1:20
            set_add_key_imm(phs, i)
        end
        
        @test length(phs) == 20
        @test length(phs.table) > 8  # Should have resized
        
        # Test all elements still exist after resize
        for i in 1:20
            @test set_contains_key_imm(phs, i) == true
        end
    end
end