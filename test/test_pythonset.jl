using ReTest

@testset "PythonHashSet Basic Structure" begin
    @testset "HashTableEntry" begin
        entry = HashTableEntry{Int}()
        @test entry.state == EMPTY
        
        entry2 = HashTableEntry{Int}(42, UInt(123))
        @test entry2.key == 42
        @test entry2.hash == UInt(123)
        @test entry2.state == ACTIVE
    end
    
    @testset "PythonHashSet Construction" begin
        set = PythonHashSet{Int}()
        @test length(set.table) == 8  # Default size
        @test set.mask == 7  # 8 - 1
        @test set.used == 0
        @test set.fill == 0
        
        set2 = PythonHashSet{Int}(16)
        @test length(set2.table) == 16
        @test set2.mask == 15
    end
    
    @testset "Lookup Function" begin
        set = PythonHashSet{Int}()
        
        # Test lookup in empty set
        key = 42
        key_hash = hash(key)
        idx = set_lookkey(set, key, key_hash)
        
        @test idx >= 1 && idx <= length(set.table)
        @test set.table[idx].state == EMPTY
        
        # Test lookup for insertion
        idx2 = set_lookkey_unicode(set, key, key_hash)
        @test idx2 >= 1 && idx2 <= length(set.table)
        @test set.table[idx2].state != ACTIVE
    end
    
    @testset "Insert Operations" begin
        set = PythonHashSet{Int}()
        
        # Test adding new key
        @test set_add_key(set, 42) == true
        @test length(set) == 1
        @test set_contains_key(set, 42) == true
        @test set_contains_key(set, 99) == false
        
        # Test adding duplicate key
        @test set_add_key(set, 42) == false
        @test length(set) == 1
        
        # Test adding multiple keys
        @test set_add_key(set, 1) == true
        @test set_add_key(set, 2) == true
        @test set_add_key(set, 3) == true
        @test length(set) == 4
        
        # Test all keys exist
        @test set_contains_key(set, 42) == true
        @test set_contains_key(set, 1) == true
        @test set_contains_key(set, 2) == true
        @test set_contains_key(set, 3) == true
    end
    
    @testset "Resize Operations" begin
        set = PythonHashSet{Int}()
        
        # Add enough elements to trigger resize
        for i in 1:20
            set_add_key(set, i)
        end
        
        @test length(set) == 20
        @test length(set.table) > 8  # Should have resized
        
        # Test all elements still exist after resize
        for i in 1:20
            @test set_contains_key(set, i) == true
        end
    end
    
    @testset "Delete Operations" begin
        set = PythonHashSet{Int}()
        
        # Add some keys
        for i in 1:5
            set_add_key(set, i)
        end
        @test length(set) == 5
        
        # Test removing existing key
        @test set_discard_key(set, 3) == true
        @test length(set) == 4
        @test set_contains_key(set, 3) == false
        @test set_contains_key(set, 1) == true  # Others still exist
        
        # Test removing non-existent key
        @test set_discard_key(set, 99) == false
        @test length(set) == 4
        
        # Test remove with error
        @test_throws KeyError set_remove_key(set, 99)
        set_remove_key(set, 1)  # Should not throw
        @test length(set) == 3
        @test set_contains_key(set, 1) == false
    end
    
    @testset "Iterator Operations" begin
        set = PythonHashSet{Int}()
        
        # Empty set iteration
        @test collect(set) == []
        
        # Add some elements
        elements = [1, 5, 3, 7, 2]
        for elem in elements
            set_add_key(set, elem)
        end
        
        # Test iteration
        collected = collect(set)
        @test length(collected) == 5
        @test Set(collected) == Set(elements)  # Same elements, order may differ
        
        # Test Base interface
        @test 3 in set
        @test !(99 in set)
        
        push!(set, 99)
        @test 99 in set
        @test length(set) == 6
        
        delete!(set, 99)
        @test !(99 in set)
        @test length(set) == 5
    end
    
    @testset "Deterministic Iteration" begin
        # Test that iteration order is deterministic (not random)
        set1 = PythonHashSet{Int}()
        set2 = PythonHashSet{Int}()
        
        elements = [1, 5, 3, 7, 2, 8, 4, 6]
        
        # Add same elements to both sets
        for elem in elements
            set_add_key(set1, elem)
            set_add_key(set2, elem)
        end
        
        # Should have same iteration order
        @test collect(set1) == collect(set2)
        
        # Multiple iterations should be consistent
        @test collect(set1) == collect(set1)
    end
end